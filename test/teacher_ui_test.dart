import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unio_app/config/brand.dart';
import 'package:unio_app/screens/news_list_screen.dart';
import 'package:unio_app/screens/schedule_tab.dart';
import 'package:unio_app/screens/teacher_home_screen.dart';
import 'package:unio_app/screens/teacher_lesson_screen.dart';
import 'package:unio_app/utils/date_utils.dart';
import 'package:unio_app/widgets/tap_feedback.dart';

void main() {
  testWidgets('Student schedule keeps its group API and refresh behavior',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final requests = <Uri>[];
    await http.runWithClient(() async {
      await tester.pumpWidget(MaterialApp(
        theme: buildTheme(Brightness.light),
        home: const Scaffold(body: ScheduleTab(group: 'TEST-101')),
      ));
      await tester.pumpAndSettle();
      expect(find.text('На выбранную неделю расписание не найдено'),
          findsOneWidget);
      expect(requests, hasLength(2));
      expect(requests.map((request) => request.path),
          everyElement('/api/v1/schedule'));
      expect(requests.map((request) => request.queryParameters['group']),
          everyElement('TEST-101'));
      await tester.tap(find.byType(PrimaryButton));
      await tester.pumpAndSettle();
      expect(find.text('На выбранную неделю расписание не найдено'),
          findsOneWidget);
      await tester.drag(find.byType(ListView), const Offset(0, 350));
      await tester.pumpAndSettle();
      expect(requests.last.queryParameters['force_refresh'], 'true');
      expect(tester.takeException(), isNull);
    },
        () => MockClient((request) async {
              if (request.url.path == '/api/v1/news')
                return http.Response('{"items":[]}', 200);
              requests.add(request.url);
              return http.Response('{"lessons":[]}', 200);
            }));
  });

  for (final brightness in Brightness.values) {
    testWidgets('Teacher schedule, news and settings in ${brightness.name}',
        (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({});
      final requests = <Uri>[];
      bool? selectedDarkMode;
      var logoutCount = 0;
      final client = MockClient((request) async {
        if (request.url.path == '/api/v1/news')
          return http.Response('{"items":[]}', 200);
        requests.add(request.url);
        Map<String, dynamic> data;
        switch (request.url.path) {
          case '/api/v1/teachers/schedule':
            data = {
              'success': true,
              'lessons': [
                {
                  'date': request.url.queryParameters['date'],
                  'start': '09:00',
                  'end': '10:30',
                  'subject': 'Математика',
                  'lesson_type': 'lecture',
                  'teacher': 'Иванов Иван Иванович',
                  'room': '101',
                  'group': 'Скрытая группа',
                },
              ],
              'groups': {
                'preview': List.generate(30, (i) => 'Скрытая группа $i'),
                'total': 30,
                'has_more': false,
              },
            };
          case '/api/v1/teachers/free-rooms':
            data = {
              'success': true,
              'rooms': ['205'],
              'note': 'По расписанию'
            };
          case '/api/v1/news':
            data = {'items': []};
          default:
            throw StateError('Unexpected request: ${request.url}');
        }
        return http.Response(jsonEncode(data), 200,
            headers: {'content-type': 'application/json; charset=utf-8'});
      });

      await http.runWithClient(() async {
        await tester.pumpWidget(MaterialApp(
          theme: buildTheme(brightness),
          home: TeacherHomeScreen(
            fio: 'Иванов Иван Иванович',
            darkMode: brightness == Brightness.dark,
            onDarkModeChanged: (value) => selectedDarkMode = value,
            onLogout: () async {
              logoutCount++;
            },
          ),
        ));
        await tester.pumpAndSettle();
        // The timetable opens today; this fixture has a lesson on Monday.
        await tester
            .ensureVisible(find.byKey(const ValueKey('schedule-day-0')));
        await tester.tap(find.byKey(const ValueKey('schedule-day-0')));
        await tester.pumpAndSettle();
        expect(find.text('Математика'), findsOneWidget);
        expect(find.textContaining('Скрытая группа'), findsNothing);
        expect(find.byType(Chip), findsNothing);
        expect(tester.takeException(), isNull);

        final monday = mondayOf(DateTime.now());
        await tester.tap(find.byType(PrimaryButton));
        await tester.pumpAndSettle();
        expect(requests.last.queryParameters['date'],
            isoDate(monday.add(const Duration(days: 7))));
        expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
        await tester.tap(find.byType(PrimaryButton));
        await tester.pumpAndSettle();
        expect(
            requests.length, 2); // Returning to the loaded week uses its cache.

        // The news/header now scroll with the timetable; return to the top first.
        final scrollable = tester.state<ScrollableState>(find
            .descendant(
                of: find.byType(ListView).first,
                matching: find.byType(Scrollable))
            .first);
        scrollable.position.jumpTo(0);
        await tester.pumpAndSettle();
        await tester.drag(find.byType(ListView).first, const Offset(0, 350));
        await tester.pumpAndSettle();
        expect(requests.last.queryParameters['force_refresh'], 'true');

        await tester.ensureVisible(find.text('Математика'));
        await tester.tap(find.text('Математика'));
        await tester.pumpAndSettle();
        expect(find.byType(TeacherLessonScreen), findsOneWidget);
        expect(find.textContaining('Скрытая группа'), findsNothing);
        await tester.tap(find.text('Найти свободную аудиторию'));
        await tester.pumpAndSettle();
        expect(find.text('Ауд. 205'), findsOneWidget);
        await tester.drag(find.byType(ListView).last, const Offset(0, 350));
        await tester.pumpAndSettle();
        expect(requests.where((uri) => uri.path.endsWith('/free-rooms')).length,
            2);
        await tester.pageBack();
        await tester.pumpAndSettle();
        await tester.pageBack();
        await tester.pumpAndSettle();

        await tester.tap(find.text('Университет'));
        await tester.pumpAndSettle();
        expect(find.byIcon(Icons.article_rounded), findsOneWidget);
        await tester.tap(find.text('Новости'));
        await tester.pumpAndSettle();
        expect(find.byType(NewsListScreen), findsOneWidget);
        expect(find.text('Пока нет новостей'), findsOneWidget);
        await tester.pageBack();
        await tester.pumpAndSettle();

        await tester.tap(find.text('Настройки'));
        await tester.pumpAndSettle();
        expect(find.text('Иванов Иван Иванович'), findsOneWidget);
        expect(find.text('Личный кабинет'), findsNothing);
        expect(find.text('Параметры'), findsOneWidget);
        await tester.tap(find.byType(Switch));
        await tester.pumpAndSettle();
        expect(selectedDarkMode, brightness != Brightness.dark);
        await tester.scrollUntilVisible(find.text('Выйти из аккаунта'), 150,
            scrollable: find.byType(Scrollable).last);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Выйти из аккаунта'));
        await tester.pumpAndSettle();
        expect(logoutCount, 0);
        await tester.tap(find.text('Отмена'));
        await tester.pumpAndSettle();
        expect(logoutCount, 0);
        await tester.tap(find.text('Выйти из аккаунта'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Выйти'));
        await tester.pumpAndSettle();
        expect(logoutCount, 1);
        expect(tester.takeException(), isNull);
      }, () => client);
    });
  }
}
