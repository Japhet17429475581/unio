import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unio_app/config/brand.dart';
import 'package:unio_app/models/teacher_directory.dart';
import 'package:unio_app/screens/teacher_search_screen.dart';
import 'package:unio_app/screens/teacher_lookup_screen.dart';
import 'package:unio_app/screens/university_tab.dart';
import 'package:unio_app/widgets/day_card.dart';
import 'teacher_search_test.dart'
    show directoryData, teacherScheduleData, teacherLesson;

void main() {
  for (final brightness in Brightness.values) {
    testWidgets(
        'University search selects exact teacher and remembers them in ${brightness.name}',
        (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({});
      final calls = <Uri>[];
      await http.runWithClient(() async {
        await tester.pumpWidget(MaterialApp(
            theme: buildTheme(brightness),
            home: Scaffold(
                body: UniversityTab(
              isPortalMode: false,
              onUpgradeToPortal: (_, __) async =>
                  throw StateError('Public search should not log in'),
            ))));
        await tester.tap(find.text('Преподаватели'));
        await tester.pumpAndSettle();
        expect(find.byType(TeacherSearchScreen), findsOneWidget);
        expect(find.text('Кого ищем?'), findsOneWidget);
        await tester.enterText(find.byType(TextField), 'ГУЛЯ');
        await tester.pumpAndSettle();
        expect(find.text('Гуляева Ирина Ивановна'), findsOneWidget);
        expect(find.text('Гуляева Марина Петровна'), findsOneWidget);
        expect(find.text('Ёршов Иван Иванович'), findsNothing);
        expect(calls, hasLength(1)); // Local filtering, no requests on typing.
        await tester.tap(find.text('Гуляева Ирина Ивановна'));
        await tester.pumpAndSettle();
        expect(find.byType(TeacherLookupScreen), findsOneWidget);
        expect(calls.last.queryParameters['fio'], 'Гуляева Ирина Ивановна');
        await tester.pageBack();
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('Очистить поиск'));
        await tester.pumpAndSettle();
        expect(find.text('Недавно смотрели'), findsOneWidget);
        expect(find.text('Гуляева Ирина Ивановна'), findsOneWidget);
        expect(find.text('Гуляева Марина Петровна'), findsNothing);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
          () => MockClient((request) async {
                calls.add(request.url);
                return http.Response(
                    jsonEncode(request.url.path.endsWith('/directory')
                        ? directoryData()
                        : teacherScheduleData([])),
                    200,
                    headers: {
                      'content-type': 'application/json; charset=utf-8'
                    });
              }));
    });
  }

  testWidgets(
      'Profile shows planned current and next lesson and changes days without refetching',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    const teacher = TeacherEntry(
        fio: 'Гуляева Ирина Ивановна',
        scheduleFios: ['Гуляева Ирина Ивановна']);
    final calls = <Uri>[];
    await http.runWithClient(() async {
      await tester.pumpWidget(MaterialApp(
          theme: buildTheme(Brightness.light),
          home: TeacherLookupScreen(
              teacher: teacher,
              clock: () => DateTime.utc(2026, 10, 9, 9, 30))));
      await tester.pumpAndSettle();
      expect(find.text('Сейчас · 09:00–10:30'), findsOneWidget);
      expect(find.text('Следующая · 11:00'), findsOneWidget);
      expect(find.text('Аудитория 314'), findsOneWidget);
      expect(find.textContaining('фактическое присутствие'), findsOneWidget);
      final nextDay = find.byTooltip('Следующий день');
      await tester.ensureVisible(nextDay);
      await tester.pumpAndSettle();
      await tester.tap(nextDay);
      await tester.pumpAndSettle();
      expect(find.text('Пар нет'), findsOneWidget);
      expect(find.text('Сейчас · 09:00–10:30'),
          findsOneWidget); // Summary remains about today.
      await tester.tap(find.text('Вернуться к сегодня'));
      await tester.pumpAndSettle();
      expect(find.byType(DayCard), findsOneWidget);
      expect(calls, hasLength(1));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
        () => MockClient((request) async {
              calls.add(request.url);
              return http.Response(
                  jsonEncode(teacherScheduleData([
                    teacherLesson('Языкознание'),
                    teacherLesson('История',
                        start: '11:00', end: '12:30', room: '208'),
                  ])),
                  200,
                  headers: {'content-type': 'application/json; charset=utf-8'});
            }));
  });

  testWidgets(
      'Offline directory still searches; unavailable profile does not claim an empty schedule',
      (tester) async {
    SharedPreferences.setMockInitialValues(
        {'teacher_directory_v1': jsonEncode(directoryData())});
    await http.runWithClient(() async {
      await tester.pumpWidget(const MaterialApp(home: TeacherSearchScreen()));
      await tester.pumpAndSettle();
      expect(find.text('Поиск по сохранённому справочнику'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'ЕРШ');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ёршов Иван Иванович'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Расписание на сегодня не загружено'),
          findsOneWidget);
      expect(find.text('Сейчас занятий по расписанию нет.'), findsNothing);
      expect(find.text('Пар нет'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    }, () => MockClient((_) async => http.Response('{}', 503)));
  });
}
