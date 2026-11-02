import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'direct_portal_client.dart';
import 'secure_storage_service.dart';
import 'app_version.dart';

/// Operational error codes only: never HTML, URL, user input or exception text.
class PortalDiagnostics {
  final http.Client client;
  final _lastSent = <String, DateTime>{};
  PortalDiagnostics({http.Client? client}) : client = client ?? http.Client();

  static const codes = {
    'requests_empty_response',
    'requests_unrecognized_page',
    'portal_session_expired',
    'portal_network_error',
    'portal_http_error',
    'portal_csrf_rejected',
    'requests_access_challenge',
  };

  Future<void> report(DirectPortalException error) async {
    final code = error.code;
    if (code == null || !codes.contains(code)) return;
    final now = DateTime.now();
    if (now.difference(_lastSent[code] ?? DateTime(2000)).inSeconds < 60)
      return;
    _lastSent[code] = now;
    try {
      final session = await loadSession();
      if (session == null) return;
      final version = await loadAppVersion();
      await client
          .post(Uri.https(apiHost, '/api/v1/diagnostics/portal'),
              headers: {
                'Content-Type': 'application/json',
                'X-Unio-Token': session.accountToken
              },
              body: jsonEncode({
                'operation': 'requests_list',
                'version': version,
                'code': code,
                'platform': kIsWeb
                    ? 'web'
                    : defaultTargetPlatform == TargetPlatform.android
                        ? 'android'
                        : 'other',
                if (error.statusCode != null) 'status': error.statusCode,
              }))
          .timeout(const Duration(seconds: 3));
    } catch (_) {
      /* Diagnostics must never block the user's action or log a body. */
    }
  }
}

final portalDiagnostics = PortalDiagnostics();
