import 'retention_service.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/portal_request.dart';
import '../models/notification_content.dart';
import 'local_notifications_service.dart';
import 'requests_service.dart';
import 'secure_storage_service.dart';
import 'status_lock_stub.dart' if (dart.library.io) 'status_lock_io.dart';

String portalOwner(String login) =>
    sha256.convert(utf8.encode(login.trim().toLowerCase())).toString();

bool isRequestReady(String status) => {
      'готов',
      'готова',
      'готово',
      'готов к выдаче',
      'готова к выдаче',
      'готово к выдаче',
      'справка готова',
      'документ готов',
      'готов к получению',
    }.contains(status.trim().toLowerCase().replaceAll(RegExp(r'[.!]+$'), ''));

/// First read is a baseline, not a flood of historical notifications.
List<RequestListItem> changedRequestStatuses(
        Map<String, String>? previous, List<RequestListItem> current) =>
    previous == null
        ? []
        : [
            for (final item in current)
              if (previous.containsKey(item.id) &&
                  item.status.isNotEmpty &&
                  previous[item.id] != item.status)
                item,
          ];

const _statusStorage = FlutterSecureStorage(
  iOptions:
      IOSOptions(accessibility: KeychainAccessibility.first_unlock_this_device),
);

Future<void> rememberRequestStatuses(
        List<RequestListItem> requests, String owner,
        {bool notify = true}) =>
    withStatusLock(() async {
      await pruneLocalData();
      final session = await loadSession();
      if (session?.isPortalModeValid != true ||
          portalOwner(session!.portalLogin!) != owner) return;
      final key = 'request_status_$owner';
      final raw = await _statusStorage.read(key: key);
      Map<String, String>? previous;
      if (raw != null) {
        try {
          previous = Map<String, String>.from(jsonDecode(raw) as Map);
        } catch (_) {/* reset invalid snapshot */}
      }
      final now = DateTime.now().millisecondsSinceEpoch;
      Map<String, int> seen = {};
      try {
        seen = Map<String, int>.from(jsonDecode(
          await _statusStorage.read(key: '${key}_seen_at') ?? '{}') as Map);
      } catch (_) { /* migrate old snapshots once */ }
      final baseline = int.tryParse(await _statusStorage.read(key: '${key}_saved_at') ?? '') ?? now;
      for (final id in previous?.keys ?? <String>[]) { seen.putIfAbsent(id, () => baseline); }
      previous?.removeWhere((id, _) => now - (seen[id] ?? baseline) >= statusLifetime.inMilliseconds);
      seen.removeWhere((id, _) => previous?.containsKey(id) != true);
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      if (notify && prefs.getBool('push_enabled') == true) {
        for (final item in changedRequestStatuses(previous, requests)) {
          final content = NotificationContent.request(item,
              ready: isRequestReady(item.status));
          await showRequestStatusNotification(
              owner: owner,
              requestId: item.id,
              title: content.title,
              body: content.body,
              expandedBody: content.expandedBody,
              subtitle: content.subtitle);
        }
      }
      // Preserve pagination baselines, but expire IDs not seen for 90 days.
      await _statusStorage.write(
          key: key,
          value: jsonEncode({
            ...?previous,
            for (final request in requests) request.id: request.status,
          }));
      await _statusStorage.write(
          key: '${key}_saved_at',
          value: '$now');
      await _statusStorage.write(key: '${key}_seen_at', value: jsonEncode({
        ...seen, for (final request in requests) request.id: now,
      }));
    });

Future<void> checkRequestStatuses({bool notify = true}) async {
  final session = await loadSession();
  if (session?.isPortalModeValid != true) return;
  final owner = portalOwner(session!.portalLogin!);
  final result = await fetchRequestsList();
  await rememberRequestStatuses(result.requests, owner, notify: notify);
}
