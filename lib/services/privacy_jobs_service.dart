import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'legal_service.dart';

const privacyJobsKey = 'privacy_jobs_v1';

/// Only a UNIO token is retained, encrypted, until the server confirms the job.
/// Portal credentials are never placed in this queue.
class PrivacyJobs {
  final http.Client? client;
  Future<void> _serial = Future.value();
  PrivacyJobs({this.client});

  Future<bool> hasPending() => _locked(() async => (await _read()).isNotEmpty);

  Future<T> _locked<T>(Future<T> Function() action) {
    final next = _serial.then((_) => action());
    _serial = next.then<void>((_) {}, onError: (Object _) {});
    return next;
  }

  Future<List<Map<String, dynamic>>> _read() async {
    final raw = await legalStorage.read(key: privacyJobsKey);
    if (raw == null) return [];
    return (jsonDecode(raw) as List)
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Future<void> enqueue(String token, {required bool deleteAccount}) =>
      _locked(() async {
        final jobs = await _read();
        final existing = jobs.where((e) => e['token'] == token).firstOrNull;
        if (existing == null) {
          jobs.add({
            'token': token,
            'operation': deleteAccount ? 'delete' : 'logout'
          });
        } else if (deleteAccount) {
          existing['operation'] = 'delete';
        }
        await legalStorage.write(key: privacyJobsKey, value: jsonEncode(jobs));
      });

  Future<bool> retry() => _locked(() async {
        final jobs = await _read();
        final transport = client ?? http.Client();
        try {
          for (final job in List.of(jobs)) {
            try {
              final deleting = job['operation'] == 'delete';
              final uri = Uri.https(
                  apiHost, '/api/v1/auth/${deleting ? 'account' : 'logout'}');
              final headers = {'X-Unio-Token': job['token'] as String};
              final response = await (deleting
                      ? transport.delete(uri, headers: headers)
                      : transport.post(uri, headers: headers))
                  .timeout(const Duration(seconds: 8));
              if (response.statusCode == (deleting ? 204 : 200)) {
                jobs.remove(job);
                await legalStorage.write(
                    key: privacyJobsKey, value: jsonEncode(jobs));
              }
            } catch (_) {
              break;
            }
          }
        } finally {
          if (client == null) transport.close();
        }
        return jobs.isEmpty;
      });
}

final privacyJobs = PrivacyJobs();
