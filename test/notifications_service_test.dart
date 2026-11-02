import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:workmanager/workmanager.dart';
import 'package:unio_app/models/notification_plan.dart';
import 'package:unio_app/services/local_notifications_service.dart';
import 'package:unio_app/services/push_service.dart';
import 'package:unio_app/utils/date_utils.dart';

class _WorkmanagerFake extends WorkmanagerPlatform {
  @override
  Future<void> cancelByUniqueName(String uniqueName) async {}
}

NotificationItem reminder(String date,
        {String time = '08:00', bool past = false}) =>
    NotificationItem.fromJson({
      'id': 'lesson-$date-0800-0-math',
      'date': date,
      'scheduled_at': '${date}T$time',
      'past': past,
      'title': 'Пара скоро начнётся',
      'body': 'Математика',
    });

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  AndroidFlutterLocalNotificationsPlugin.registerWith();
  WorkmanagerPlatform.instance = _WorkmanagerFake();
  const channel = MethodChannel('dexterous.com/flutter/local_notifications');
  final calls = <MethodCall>[];
  var pending = <Map<String, dynamic>>[];
  var exactAllowed = true;
  var notificationsAllowed = true;
  var failSchedule = false;
  var revokeExact = false;

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    SharedPreferences.setMockInitialValues({});
    calls.clear();
    pending = [];
    exactAllowed = true;
    notificationsAllowed = true;
    failSchedule = false;
    revokeExact = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      switch (call.method) {
        case 'initialize':
          return true;
        case 'requestNotificationsPermission':
          return notificationsAllowed;
        case 'requestExactAlarmsPermission':
          return exactAllowed;
        case 'canScheduleExactNotifications':
          return exactAllowed;
        case 'pendingNotificationRequests':
          return pending;
        case 'zonedSchedule':
          if (failSchedule) throw PlatformException(code: 'storage_error');
          if (revokeExact) {
            revokeExact = false;
            throw PlatformException(code: 'exact_alarms_not_permitted');
          }
          return null;
        default:
          return null;
      }
    });
  });
  tearDown(() => debugDefaultTargetPlatformOverride = null);

  List<MethodCall> scheduled() =>
      calls.where((c) => c.method == 'zonedSchedule').toList();
  String mode(MethodCall call) =>
      call.arguments['platformSpecifics']['scheduleMode'] as String;

  test(
      'Schedules without prior bootstrap, in university timezone, with stable IDs',
      () async {
    await scheduleNotifications([reminder('2099-10-09', past: true)]);
    final first = scheduled().single.arguments;
    expect(first['timeZoneName'], 'Europe/Moscow');
    expect(first['scheduledDateTime'], startsWith('2099-10-09T08:00:00'));
    expect(mode(scheduled().single), 'exactAllowWhileIdle');
    calls.clear();
    await scheduleNotifications([reminder('2099-10-09')]);
    expect(scheduled().single.arguments['id'], first['id']);
    expect(calls.any((c) => c.method == 'cancelAll'), isFalse);
  });

  test('Denied exact permission still schedules an inexact reminder', () async {
    exactAllowed = false;
    expect(await requestNotificationPermission(), isTrue);
    await scheduleNotifications([reminder('2099-10-09')]);
    expect(mode(scheduled().single), 'inexactAllowWhileIdle');
  });

  test('Reminder uses branded icons, useful compact text and expanded details',
      () async {
    final item = NotificationItem.fromJson({
      'id': 'lesson-2099-10-09-1010-language',
      'scheduled_at': '2099-10-09T10:00',
      'minutes_before': 10,
      'lesson': {
        'subject': 'Иностранный язык',
        'start': '10:10',
        'end': '11:40',
        'room': '314',
        'lesson_type': 'practice',
        'teacher': 'Иванова А. А.'
      },
    });
    await scheduleNotifications([item]);
    final args = scheduled().single.arguments as Map;
    expect(args['title'], 'Иностранный язык');
    expect(args['body'], '10:10–11:40 · Ауд. 314');
    expect(args['payload'], item.id);
    final style = args['platformSpecifics'] as Map;
    expect(style['icon'], 'ic_notification');
    expect(style['largeIcon'], 'ic_unio_large');
    expect(style['subText'], 'Через 10 мин');
    expect(style['category'], 'reminder');
    expect(style['colorRed'], 0x6B);
    expect(style['styleInformation']['bigText'],
        '10:10–11:40 · Ауд. 314\nПрактика · Иванова А. А.');
    expect(style['actions'].single['showsUserInterface'], isTrue);
  });

  test('Request notification uses expanded content and retains its destination',
      () async {
    await showRequestStatusNotification(
        owner: 'owner',
        requestId: '101',
        title: 'Документ готов',
        body: 'Справка о доходах',
        expandedBody: 'Справка о доходах\nЗаявление №101 · Готово');
    final args = calls.singleWhere((c) => c.method == 'show').arguments as Map;
    expect(args['title'], 'Документ готов');
    expect(args['body'], 'Справка о доходах');
    expect(args['payload'], 'request:owner:101');
    final style = args['platformSpecifics'] as Map;
    expect(style['channelId'], 'unio_requests');
    expect(style['icon'], 'ic_notification');
    expect(style['largeIcon'], 'ic_unio_large');
    expect(style['styleInformation']['bigText'], contains('№101'));
    expect(style['actions'].single['id'], 'open_request');
  });

  test('Permission revoked during scheduling falls back to inexact', () async {
    revokeExact = true;
    await scheduleNotifications([reminder('2099-10-09')]);
    expect(scheduled().map(mode),
        ['exactAllowWhileIdle', 'inexactAllowWhileIdle']);
  });

  test('Denied notifications do not enable the setting', () async {
    notificationsAllowed = false;
    await expectLater(
        enablePush(group: 'TEST'), throwsA(isA<PushApiException>()));
    expect(await loadPushEnabled(), isFalse);
    expect(scheduled(), isEmpty);
  });

  test('Failed scheduling does not delete the previous plan', () async {
    pending = [
      {'id': 12, 'payload': 'lesson-2099-10-09-old'}
    ];
    failSchedule = true;
    await expectLater(scheduleNotifications([reminder('2099-10-09')]),
        throwsA(isA<PlatformException>()));
    expect(calls.any((c) => c.method.startsWith('cancel')), isFalse);
  });

  test('Empty successful day clears only that day, preserving failed days',
      () async {
    pending = [
      {'id': 12, 'payload': 'lesson-2099-10-09-old'},
      {'id': 13, 'payload': 'lesson-2099-10-10-old'},
    ];
    await scheduleNotifications([], replaceDates: {'2099-10-09'});
    expect(calls.where((c) => c.method == 'cancel').single.arguments['id'], 12);
    expect(calls.any((c) => c.method == 'cancelAll'), isFalse);
  });

  test('Past events are skipped and explicit UTC offsets are respected',
      () async {
    await scheduleNotifications([
      reminder('2000-01-01'),
      reminder('2099-10-09', time: '08:00:00+05:00'),
    ]);
    expect(scheduled(), hasLength(1));
    expect(scheduled().single.arguments['scheduledDateTime'],
        startsWith('2099-10-09T06:00:00'));
  });

  test('Week refresh keeps failed days and uses client-side time filtering',
      () async {
    SharedPreferences.setMockInitialValues(
        {'push_enabled': true, 'push_group': 'TEST'});
    final today = tz.TZDateTime.now(notificationLocation);
    final failedDate =
        isoDate(DateTime(today.year, today.month, today.day + 1));
    final successDate =
        isoDate(DateTime(today.year, today.month, today.day + 2));
    pending = [
      {'id': 12, 'payload': 'lesson-$failedDate-old'},
      {'id': 13, 'payload': 'lesson-$successDate-old'},
    ];
    final requests = <Uri>[];
    await http.runWithClient(
        () => refreshPushIfEnabled('TEST'),
        () => MockClient((request) async {
              requests.add(request.url);
              if (request.url.queryParameters['date'] == failedDate)
                return http.Response('', 503);
              return http.Response(jsonEncode({'notifications': []}), 200);
            }));
    expect(requests, hasLength(notificationPlanDays));
    expect(
        requests.every((uri) => uri.queryParameters['include_past'] == 'true'),
        isTrue);
    expect(calls.where((c) => c.method == 'cancel').single.arguments['id'], 13);
  });

  test('Disabling during an HTTP refresh wins after the refresh completes',
      () async {
    SharedPreferences.setMockInitialValues(
        {'push_enabled': true, 'push_group': 'TEST'});
    final started = Completer<void>();
    final response = Completer<http.Response>();
    await http.runWithClient(() async {
      final refresh = refreshPushIfEnabled('TEST');
      await started.future;
      final disable = disablePush();
      response.complete(http.Response('{"notifications":[]}', 200));
      await Future.wait([refresh, disable]);
    },
        () => MockClient((_) {
              if (!started.isCompleted) started.complete();
              return response.future;
            }));
    expect(calls.last.method, 'cancelAll');
    expect(await loadPushEnabled(), isFalse);
  });
}
