import 'dart:convert';
import 'assistant_service.dart';
import 'locale_service.dart';
import 'home_widget_service.dart';
import 'package:flutter/foundation.dart';
import 'web_portal_service.dart';
import 'package:flutter/painting.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'legal_service.dart';
import 'privacy_jobs_service.dart';
import 'secure_storage_service.dart';
import 'push_service.dart';
import 'background_notifications_service.dart';
import 'local_notifications_service.dart';
import 'direct_portal_client.dart';
import 'local_write_guard.dart';
import 'status_lock_stub.dart' if (dart.library.io) 'status_lock_io.dart';
import 'local_privacy_io.dart' if (dart.library.html) 'local_privacy_web.dart';

const cleanupPendingKey = 'privacy_cleanup_pending_v1';

/// All independent cleanup operations run even when one subsystem fails.
Future<void> finishLocalCleanup({bool deleteData = false}) async {
  var failed = false;
  Future<void> attempt(Future<void> Function() action) async {
    try {
      await action();
    } catch (_) {
      failed = true;
    }
  }

  await attempt(() => legalStorage.write(key: legalActiveKey, value: 'false'));
  if (kIsWeb) {
    // Local logout works offline; durable UNIO token revocation also removes
    // linked web sessions when connectivity returns.
    try {
      await webPortal.logout();
    } catch (_) {}
  }
  await attempt(AssistantConversation.endSessions);
  await attempt(clearSession);
  await attempt(homeWidget.clear);
  await attempt(clearTeacherSession);
  await attempt(blockPrivateWrites);
  await attempt(closeActivePortalClients);
  await attempt(() => legal.setAnalytics(false, origin: 'session_end'));
  await attempt(disablePush);
  await attempt(stopBackgroundNotifications);
  await attempt(cancelAllNotifications);
  await attempt(() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('teacher_fio');
    if (deleteData) {
      for (final key in prefs.getKeys().toList()) {
        if (key != 'dark_mode' &&
            key != 'onboarding_completed_v1' &&
            key != LocaleService.preferenceKey)
          await attempt(() async {
            await prefs.remove(key);
          });
      }
    }
  });
  if (deleteData) {
    await attempt(clearPrivateFiles);
    await attempt(() => withStatusLock(() async {
          final keys = (await legalStorage.readAll()).keys.toList();
          for (final key in keys) {
            if (key == privacyJobsKey ||
                key == cleanupPendingKey ||
                key == 'session_closed_v1') continue;
            await attempt(() => legalStorage.delete(key: key));
          }
        }));
    // A worker that held the lock before logout may have posted a notification.
    await attempt(cancelAllNotifications);
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
  }
  if (failed) throw StateError('local_cleanup_pending');
}

Future<void> endPrivateSession({String? token, bool deleteData = false}) async {
  // Persist recovery intent before destructive operations. Failure still clears credentials.
  Object? failure;
  try {
    await legalStorage.write(
        key: cleanupPendingKey,
        value: jsonEncode({'delete': deleteData, 'token': token}));
    if (token != null)
      await privacyJobs.enqueue(token, deleteAccount: deleteData);
  } catch (error) {
    failure = error;
  }
  try {
    await finishLocalCleanup(deleteData: deleteData);
  } catch (error) {
    failure ??= error;
  }
  if (failure != null) throw StateError('privacy_action_pending');
  await legalStorage.delete(key: cleanupPendingKey);
}

Future<void> recoverPrivateCleanup() async {
  final pending = await legalStorage.read(key: cleanupPendingKey);
  if (pending == null) return;
  final job = jsonDecode(pending) as Map;
  if (job['token'] != null)
    await privacyJobs.enqueue(job['token'],
        deleteAccount: job['delete'] == true);
  await finishLocalCleanup(deleteData: job['delete'] == true);
  await legalStorage.delete(key: cleanupPendingKey);
}
