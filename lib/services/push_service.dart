import 'package:flutter/foundation.dart';
import 'web_push_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

import '../models/notification_plan.dart';
import '../utils/date_utils.dart';
import 'local_notifications_service.dart';
import 'notifications_service.dart';
import 'background_notifications_service.dart';
import 'request_status_service.dart';

class PushApiException implements Exception {
  final String message;
  PushApiException(this.message);
  @override
  String toString() => message;
}

const _enabledKey = 'push_enabled';
const _groupKey = 'push_group';
const notificationPlanDays = 7;
Future<void> _operations = Future<void>.value();

// Включение, обновление и выключение не должны пересекаться: завершение
// старого HTTP-запроса не должно включать напоминания после выключения.
Future<void> _serialize(Future<void> Function() action) {
  final result = _operations.then((_) => action());
  _operations = result.catchError((Object error) {
    debugPrint('notification_operation');
  });
  return result;
}

Future<bool> loadPushEnabled() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(_enabledKey) ?? false;
}

Future<void> enablePush({required String group}) {
  if (kIsWeb)
    return enableWebPush(group).catchError((Object _) {
      throw PushApiException(
          'Не удалось включить уведомления. Добавьте UNIO на главный экран и разрешите уведомления в настройках браузера.');
    });
  return _enableNativePush(group: group);
}

Future<void> _enableNativePush({required String group}) => _serialize(() async {
      if (!await requestNotificationPermission()) {
        throw PushApiException(
          'Уведомления выключены в настройках телефона. Разрешите их для Unio.',
        );
      }
      await _rescheduleFor(group);
      await startBackgroundNotifications();
      try {
        await checkRequestStatuses(notify: false);
      } catch (_) {
        debugPrint('notification_operation');
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_enabledKey, true);
    });

Future<void> disablePush() {
  if (kIsWeb) return disableWebPush();
  return _disableNativePush();
}

Future<void> _disableNativePush() => _serialize(() async {
      final prefs = await SharedPreferences.getInstance();
      final wasEnabled = await loadPushEnabled();
      await prefs.setBool(_enabledKey, false);
      try {
        await stopBackgroundNotifications();
      } catch (_) {
        // The worker also checks the persisted switch before any network/show.
        debugPrint('notification_operation');
      }
      // На неподдерживаемых платформах нечего отменять.
      if (wasEnabled) await cancelAllNotifications();
      await prefs.remove(_groupKey);
    });

Future<void> _rescheduleFor(String group) async {
  final now = tz.TZDateTime.now(notificationLocation);
  final items = <NotificationItem>[];
  final refreshedDates = <String>{};
  await Future.wait(List.generate(notificationPlanDays, (offset) async {
    final date = DateTime(now.year, now.month, now.day + offset);
    try {
      items.addAll(await fetchNotificationPlan(group: group, date: date));
      refreshedDates.add(isoDate(date));
    } catch (error) {
      debugPrint('notification_operation');
    }
  }));
  if (refreshedDates.isEmpty) {
    throw PushApiException('Не удалось получить план уведомлений.');
  }
  final prefs = await SharedPreferences.getInstance();
  final previousGroup = prefs.getString(_groupKey);
  if (previousGroup != null && previousGroup != group) {
    await cancelAllNotifications();
  }
  await scheduleNotifications(items, replaceDates: refreshedDates);
  await prefs.setString(_groupKey, group);
}

Future<void> refreshPushIfEnabled(String group) async {
  if (kIsWeb) {
    try {
      await refreshWebPush(group);
    } catch (_) {}
    return;
  }
  try {
    await _serialize(() async {
      if (await loadPushEnabled()) await _rescheduleFor(group);
    });
  } catch (error) {
    debugPrint('notification_operation');
  }
}
