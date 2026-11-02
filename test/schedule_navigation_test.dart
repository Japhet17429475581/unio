import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unio_app/config/brand.dart';
import 'package:unio_app/models/lesson.dart';
import 'package:unio_app/screens/schedule_tab.dart';
import 'package:unio_app/widgets/lesson_row.dart';
import 'package:unio_app/widgets/campus_stories.dart';
import 'package:unio_app/widgets/next_lesson_card.dart';
import 'package:unio_app/widgets/tap_feedback.dart';

Map<String, dynamic> item(String subject, String start, String date) => {
      'date': date,
      'start': start,
      'end': '12:30',
      'subject': subject,
      'room': '314',
      'lesson_type': 'lecture',
      'teacher': 'Преподаватель',
    };

void main() {
  for (final teacher in [false, true]) {
    testWidgets(
        'Prefetches both weeks in parallel and caches them: teacher=$teacher',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final current = Completer<http.Response>();
      const emptySchedule =
          '{"success":true,"lessons":[],"groups":{"preview":[],"total":0,"has_more":false}}';
      final requestedDates = <String>[];
      await http.runWithClient(() async {
        await tester.pumpWidget(MaterialApp(
            home: Scaffold(
                body: teacher
                    ? ScheduleTab.teacher(
                        fio: 'Test Teacher', clock: () => DateTime(2026, 10, 7))
                    : ScheduleTab(
                        group: 'TEST', clock: () => DateTime(2026, 10, 7)))));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        expect(current.isCompleted, isFalse);
        expect(requestedDates, ['2026-10-05', '2026-10-12']);
        final prefs = await SharedPreferences.getInstance();
        final prefix = teacher
            ? 'teacher_schedule_cache_Test Teacher'
            : 'schedule_cache_TEST';
        expect(prefs.getString('${prefix}_2026-10-12_week'), isNotNull);
        current.complete(http.Response(emptySchedule, 200));
        await tester.pumpAndSettle();
        await tester.tap(find.byType(PrimaryButton));
        await tester.pumpAndSettle();
        expect(requestedDates, hasLength(2));
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
          () => MockClient((request) async {
                if (request.url.path == '/api/v1/news') {
                  return http.Response('{"items":[]}', 200);
                }
                final date = request.url.queryParameters['date']!;
                requestedDates.add(date);
                if (date == '2026-10-05') return current.future;
                return http.Response(emptySchedule, 200);
              }));
    });
  }

  testWidgets('A failed background week does not break the visible schedule',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await http.runWithClient(() async {
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(
              body: ScheduleTab(
                  group: 'TEST', clock: () => DateTime(2026, 10, 7)))));
      await tester.pumpAndSettle();
      expect(find.byType(PrimaryButton), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
        () => MockClient((request) async {
              if (request.url.queryParameters['date'] == '2026-10-12') {
                throw http.ClientException('Offline');
              }
              return http.Response('{"lessons":[],"items":[]}', 200);
            }));
  });

  for (final brightness in Brightness.values) {
    testWidgets(
        'Swipes without overlays, buttons, caching and next-lesson focus in ${brightness.name}',
        (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({});
      final requests = <Uri>[];
      await http.runWithClient(() async {
        await tester.pumpWidget(MaterialApp(
            theme: buildTheme(brightness),
            home: Scaffold(
                body: ScheduleTab(
                    group: 'TEST',
                    clock: () => DateTime.utc(2026, 10, 9, 9, 30)))));
        await tester.pumpAndSettle();
        expect(find.text('Следующая пара · сегодня'), findsOneWidget);
        expect(find.text('01:30:00'), findsOneWidget);
        expect(find.text('Нынешняя пара'),
            findsOneWidget); // Only in the weekly timetable.
        expect(requests, hasLength(2));

        final pages = find.byKey(const ValueKey('weeks-TEST'));
        final stories = find.byType(CampusStories);
        final storiesRect = tester.getRect(stories);
        expect(find.text('Новости и гайд'), findsNothing);
        expect(find.text('Обновить новости'), findsNothing);
        expect(find.text('Первое знакомство'), findsOneWidget);
        // A horizontal drag on the shelf must never change the week.
        await tester.drag(stories, const Offset(-300, 0));
        await tester.pumpAndSettle();
        expect(tester.widget<PageView>(pages).controller!.page, 0);
        final hint = find.byKey(const ValueKey('week-swipe-hint'));
        final cancelled = await tester.startGesture(tester.getCenter(pages));
        await cancelled.moveBy(const Offset(-30, 0));
        await tester.pump();
        await cancelled.moveBy(const Offset(-20, 0));
        await tester.pump(const Duration(milliseconds: 250));
        await cancelled.up();
        await tester.pumpAndSettle();
        expect(tester.widget<PrimaryButton>(find.byType(PrimaryButton)).label,
            'Следующая неделя');
        expect(hint, findsNothing);
        final swipe = await tester.startGesture(tester.getCenter(pages));
        await swipe.moveBy(const Offset(-30, 0));
        await tester.pump();
        await swipe.moveBy(const Offset(-60, 0));
        await tester.pump(const Duration(milliseconds: 150));
        expect(tester.getRect(stories), storiesRect);
        expect(hint, findsNothing);
        expect(
            find.descendant(of: hint, matching: find.text('Следующая неделя')),
            findsNothing);
        await swipe.moveBy(const Offset(-240, 0));
        await swipe.up();
        await tester.pumpAndSettle();
        expect(hint, findsNothing);
        expect(tester.widget<PrimaryButton>(find.byType(PrimaryButton)).label,
            'Эта неделя');
        expect(requests, hasLength(2));
        expect(requests.last.queryParameters['date'], '2026-10-12');
        expect(find.widgetWithText(NextLessonCard, 'История'), findsOneWidget);
        expect(find.widgetWithText(NextLessonCard, 'Следующая неделя: предмет'),
            findsNothing);

        // Swipe the week content, not the independently scrolling day strip.
        final back = await tester.startGesture(
            tester.getCenter(find.byType(NextLessonCard).hitTestable()));
        await back.moveBy(const Offset(30, 0));
        await tester.pump();
        await back.moveBy(const Offset(60, 0));
        await tester.pump(const Duration(milliseconds: 150));
        expect(
            find.descendant(of: hint, matching: find.text('Предыдущая неделя')),
            findsNothing);
        await back.moveBy(const Offset(240, 0));
        await back.up();
        await tester.pumpAndSettle();
        expect(tester.widget<PrimaryButton>(find.byType(PrimaryButton)).label,
            'Следующая неделя');
        expect(requests, hasLength(2));

        await tester.tap(find.byType(PrimaryButton));
        await tester.pumpAndSettle();
        expect(tester.widget<PrimaryButton>(find.byType(PrimaryButton)).label,
            'Эта неделя');
        await tester.tap(find.widgetWithText(NextLessonCard, 'История'));
        await tester.pumpAndSettle();
        final row = find.byWidgetPredicate(
            (w) => w is LessonRow && w.lesson.subject == 'История');
        expect(row.hitTestable(), findsOneWidget);
        expect(tester.widget<LessonRow>(row).highlighted, isTrue);
        // The target stays mounted while its border and fill fade away.
        final targetElement = tester.element(row);
        await tester.pump(const Duration(milliseconds: 1800));
        expect(tester.widget<LessonRow>(row).highlighted, isFalse);
        await tester.pump(const Duration(milliseconds: 1000));
        expect(tester.element(row), same(targetElement));
        expect(tester.widget<PrimaryButton>(find.byType(PrimaryButton)).label,
            'Следующая неделя');
        expect(requests, hasLength(2));
        // Vertical scrolling doesn't change the selected week.
        await tester.drag(find.byType(ListView).first, const Offset(0, -150));
        await tester.pumpAndSettle();
        expect(tester.widget<PrimaryButton>(find.byType(PrimaryButton)).label,
            'Следующая неделя');
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
          () => MockClient((request) async {
                if (request.url.path == '/api/v1/news')
                  return http.Response('{"items":[]}', 200);
                requests.add(request.url);
                final nextWeek =
                    request.url.queryParameters['date'] == '2026-10-12';
                return http.Response(
                    jsonEncode({
                      'lessons': nextWeek
                          ? [
                              item('Следующая неделя: предмет', '09:00',
                                  '2026-10-12'),
                            ]
                          : [
                              for (var day = 5; day < 9; day++)
                                item('Прошедший день $day', '09:00',
                                    '2026-10-0$day'),
                              item('Нынешняя пара', '09:00', '2026-10-09'),
                              item('История', '11:00', '2026-10-09'),
                            ]
                    }),
                    200,
                    headers: {
                      'content-type': 'application/json; charset=utf-8'
                    });
              }));
    });
  }

  testWidgets(
      'Counter ticks, skips a started lesson and resumes after background',
      (tester) async {
    var now = DateTime.utc(2026, 10, 9, 10, 59, 58);
    final lessons = [
      Lesson.fromJson(item('Первый старт', '11:00', '2026-10-09')),
      Lesson.fromJson(item('Второй старт', '12:00', '2026-10-09')),
    ];
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: NextLessonCard(
      schedule: Future.value(lessons),
      clock: () => now,
      onLessonTap: (_) {},
      onRetry: () {},
    ))));
    await tester.pumpAndSettle();
    expect(find.text('00:02'), findsOneWidget);
    now = now.add(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('00:01'), findsOneWidget);
    now = now.add(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Первый старт'), findsNothing);
    expect(find.text('Второй старт'), findsOneWidget);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    now = DateTime.utc(2026, 10, 9, 12, 5);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(find.text('Следующих пар сегодня нет'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Failed request is not shown as a free day, and can be retried',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    var failed = true;
    await http.runWithClient(() async {
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(
              body: ScheduleTab(
                  group: 'TEST', clock: () => DateTime.utc(2026, 10, 9, 9)))));
      await tester.pumpAndSettle();
      expect(find.text('Расписание на сегодня не загружено'), findsOneWidget);
      expect(find.text('Сегодня без пар — отдыхай ☕'), findsNothing);
      failed = false;
      await tester.tap(find.text('Нажмите, чтобы повторить'));
      await tester.pumpAndSettle();
      expect(find.text('Расписание на эту неделю не найдено'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
        () => MockClient((_) async => http.Response(
            failed ? '{}' : '{"lessons":[]}', failed ? 503 : 200)));
  });

  testWidgets('Midnight loads the new week and replaces yesterday\'s summary',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    var now = DateTime.utc(2026, 10, 11, 23, 59, 59);
    final requests = <Uri>[];
    await http.runWithClient(() async {
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(body: ScheduleTab(group: 'TEST', clock: () => now))));
      await tester.pumpAndSettle();
      expect(find.text('Расписание на эту неделю не найдено'), findsOneWidget);
      now = DateTime.utc(2026, 10, 12);
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(requests.map((r) => r.queryParameters['date']),
          ['2026-10-05', '2026-10-12', '2026-10-19']);
      expect(find.text('Сегодня без пар — отдыхай ☕'), findsNothing);
      expect(
          find.widgetWithText(NextLessonCard, 'Утренняя пара'), findsOneWidget);
      expect(find.text('08:00:00'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
        () => MockClient((request) async {
              if (request.url.path == '/api/v1/news')
                return http.Response('{"items":[]}', 200);
              requests.add(request.url);
              return http.Response(
                  jsonEncode({
                    'lessons':
                        request.url.queryParameters['date'] == '2026-10-12'
                            ? [item('Утренняя пара', '08:00', '2026-10-12')]
                            : []
                  }),
                  200,
                  headers: {'content-type': 'application/json; charset=utf-8'});
            }));
  });

  testWidgets('Compact summary fits a narrow screen with enlarged text',
      (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
        theme: buildTheme(Brightness.dark),
        home: MediaQuery(
            data: const MediaQueryData(
                size: Size(320, 568), textScaler: TextScaler.linear(1.6)),
            child: Scaffold(
                body: ListView(padding: const EdgeInsets.all(20), children: [
              NextLessonCard(
                schedule: Future.value([
                  Lesson.fromJson(item(
                      'Длинное название дисциплины для проверки переноса текста',
                      '11:00',
                      '2026-10-09'))
                ]),
                clock: () => DateTime.utc(2026, 10, 9, 9, 30),
                onLessonTap: (_) {},
                onRetry: () {},
              )
            ])))));
    await tester.pumpAndSettle();
    expect(find.text('До начала'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
