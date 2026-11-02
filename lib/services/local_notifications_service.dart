import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../models/notification_plan.dart';
import '../models/notification_content.dart';

const _channel = AndroidNotificationChannel(
  'unio_lessons',
  'Напоминания о парах',
  description: 'Уведомления о начале пар по расписанию',
  importance: Importance.high,
);
const _requestsChannel = AndroidNotificationChannel(
  'unio_requests',
  'Статусы заявлений',
  description: 'Готовность справок и изменения статусов на портале',
  importance: Importance.high,
);
const _notificationAccent = Color(0xFF6B2FF5);
const _brandIcon = DrawableResourceAndroidBitmap('ic_unio_large');

NotificationDetails _lessonDetails(NotificationContent content) =>
    NotificationDetails(
      android: AndroidNotificationDetails(
        _channel.id,
        _channel.name,
        channelDescription: _channel.description,
        importance: Importance.high,
        priority: Priority.high,
        icon: 'ic_notification',
        largeIcon: _brandIcon,
        color: _notificationAccent,
        subText: content.subtitle,
        category: AndroidNotificationCategory.reminder,
        styleInformation: BigTextStyleInformation(content.expandedBody),
        actions: const [
          AndroidNotificationAction('open_schedule', 'Расписание',
              showsUserInterface: true, cancelNotification: true)
        ],
      ),
      iOS: DarwinNotificationDetails(
          subtitle: content.subtitle, threadIdentifier: 'unio_lessons'),
    );

NotificationDetails _requestDetails(String body, String subtitle) =>
    NotificationDetails(
      android: AndroidNotificationDetails(
        _requestsChannel.id,
        _requestsChannel.name,
        channelDescription: _requestsChannel.description,
        importance: Importance.high,
        priority: Priority.high,
        icon: 'ic_notification',
        largeIcon: _brandIcon,
        color: _notificationAccent,
        subText: subtitle,
        category: AndroidNotificationCategory.status,
        visibility: NotificationVisibility.private,
        styleInformation: BigTextStyleInformation(body),
        actions: const [
          AndroidNotificationAction('open_request', 'Заявление',
              showsUserInterface: true, cancelNotification: true)
        ],
      ),
      iOS: DarwinNotificationDetails(
          subtitle: subtitle, threadIdentifier: 'unio_requests'),
    );

final _plugin = FlutterLocalNotificationsPlugin();
final notificationTapCount = ValueNotifier<int>(0);
final requestNotificationTap = ValueNotifier<String?>(null);
Future<void>? _initialization;
VoidCallback? _onNotificationTap;
tz.Location? _location;

// Наивные даты API относятся к расписанию ВГСПУ, даже если телефон
// находится в другом часовом поясе. Не зависим от timezone плагина.
tz.Location get notificationLocation {
  if (_location == null) {
    tz_data.initializeTimeZones();
    _location = tz.getLocation('Europe/Moscow');
  }
  return _location!;
}

Future<void> initLocalNotifications({VoidCallback? onNotificationTap}) {
  if (onNotificationTap != null) _onNotificationTap = onNotificationTap;
  return _initialization ??= _initialize().catchError((Object error) {
    _initialization = null;
    throw error;
  });
}

Future<void> _initialize() async {
  if (kIsWeb ||
      (defaultTargetPlatform != TargetPlatform.android &&
          defaultTargetPlatform != TargetPlatform.iOS)) {
    throw UnsupportedError('Уведомления доступны на Android и iOS.');
  }
  await _plugin.initialize(
    const InitializationSettings(
      android: AndroidInitializationSettings('ic_notification'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    ),
    onDidReceiveNotificationResponse: (response) {
      _onNotificationTap?.call();
      if (response.payload?.startsWith('request:') == true) {
        requestNotificationTap.value = response.payload;
      } else {
        notificationTapCount.value++;
      }
    },
  );
  final android = _plugin.resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>();
  await android?.createNotificationChannel(_channel);
  await android?.createNotificationChannel(_requestsChannel);
  debugPrint('[NOTIFICATIONS] initialized');
  final launch = await _plugin.getNotificationAppLaunchDetails();
  if (launch?.didNotificationLaunchApp == true &&
      launch?.notificationResponse?.payload?.startsWith('request:') == true) {
    requestNotificationTap.value = launch!.notificationResponse!.payload;
  }
}

Future<bool> requestNotificationPermission() async {
  await initLocalNotifications();
  final android = _plugin.resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>();
  if (android != null) {
    if (await android.requestNotificationsPermission() != true) return false;
    if (await android.canScheduleExactNotifications() != true) {
      // Отказ в точных будильниках не запрещает обычные напоминания.
      await android.requestExactAlarmsPermission();
    }
    return true;
  }
  return await _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
      false;
}

// String.hashCode не гарантирует одинаковые значения между запусками.
int _stableId(String value) {
  var hash = 0x811c9dc5;
  for (final unit in value.codeUnits) {
    hash = ((hash ^ unit) * 0x01000193) & 0xffffffff;
  }
  return hash & 0x3fffffff;
}

String? _payloadDate(String? payload) =>
    RegExp(r'^lesson-(\d{4}-\d{2}-\d{2})-').firstMatch(payload ?? '')?.group(1);

/// Обновляет только успешно полученные дни. При сетевой ошибке старые
/// напоминания остаются в ОС; новые ставятся до удаления устаревших.
Future<void> scheduleNotifications(
  List<NotificationItem> items, {
  Set<String>? replaceDates,
}) async {
  await initLocalNotifications();
  final location = notificationLocation;
  final now = tz.TZDateTime.now(location);
  final pending = await _plugin.pendingNotificationRequests();
  final android = _plugin.resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>();
  var mode =
      android == null || await android.canScheduleExactNotifications() == true
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle;
  final candidates = <({NotificationItem item, tz.TZDateTime at})>[];
  for (final item in items) {
    final at = item.scheduledAt;
    if (at == null) continue;
    final scheduled = at.isUtc
        ? tz.TZDateTime.from(at, location)
        : tz.TZDateTime(
            location, at.year, at.month, at.day, at.hour, at.minute, at.second);
    // Серверный past зависит от часов/зоны сервера. Проверяем сами.
    if (scheduled.isAfter(now)) candidates.add((item: item, at: scheduled));
  }
  candidates.sort((a, b) => a.at.compareTo(b.at));
  bool shouldReplace(PendingNotificationRequest request) =>
      _payloadDate(request.payload) != null &&
      (replaceDates == null ||
          replaceDates.contains(_payloadDate(request.payload)));
  // iOS хранит максимум 64 запроса; оставляем запас и учитываем дни,
  // которые не удалось обновить. Android использует тот же горизонт.
  final preserved = pending.where((p) => !shouldReplace(p)).length;
  final capacity = (60 - preserved).clamp(0, 60);
  final scheduledIds = <int>{};
  for (final candidate in candidates.take(capacity)) {
    final item = candidate.item;
    final content = NotificationContent.lesson(item);
    final id = _stableId(item.id);
    Future<void> schedule() => _plugin.zonedSchedule(
          id,
          content.title,
          content.body,
          candidate.at,
          _lessonDetails(content),
          androidScheduleMode: mode,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: item.id,
        );
    try {
      await schedule();
    } on PlatformException catch (error) {
      if (error.code != 'exact_alarms_not_permitted') rethrow;
      mode = AndroidScheduleMode.inexactAllowWhileIdle;
      await schedule();
    }
    scheduledIds.add(id);
  }
  for (final request in pending) {
    if (shouldReplace(request) && !scheduledIds.contains(request.id)) {
      await _plugin.cancel(request.id);
    }
  }
  debugPrint('[NOTIFICATIONS] scheduled=${scheduledIds.length}, '
      'preserved=$preserved, mode=${mode.name}');
}

Future<void> cancelAllNotifications() async {
  // No native notification plugin exists in the browser. Logout must complete.
  if (kIsWeb) return;
  await initLocalNotifications();
  await _plugin.cancelAll();
}

Future<void> showRequestStatusNotification(
    {required String owner,
    required String requestId,
    required String title,
    required String body,
    String? expandedBody,
    String subtitle = 'Заявления'}) async {
  if (kIsWeb) return;
  await initLocalNotifications();
  await _plugin.show(
      0x40000000 | (_stableId('request:$owner:$requestId') & 0x3fffffff),
      title,
      body,
      _requestDetails(expandedBody ?? body, subtitle),
      payload: 'request:$owner:$requestId');
}
