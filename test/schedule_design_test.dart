import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unio_app/config/brand.dart';
import 'package:unio_app/screens/schedule_tab.dart';
import 'package:unio_app/screens/lesson_notes_screen.dart';
import 'package:unio_app/screens/teacher_lesson_screen.dart';
import 'package:unio_app/services/lesson_notes_service.dart';
import 'package:unio_app/widgets/lesson_actions.dart';
import 'package:unio_app/widgets/lesson_row.dart';
import 'package:unio_app/widgets/next_lesson_card.dart';
import 'package:unio_app/widgets/tap_feedback.dart';
import 'package:unio_app/widgets/unio_navigation_bar.dart';
import 'support/notes_fakes.dart';

Future<void> preview(WidgetTester tester, String name) async {
  if (!const bool.fromEnvironment('SCHEDULE_PREVIEWS')) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const ValueKey('preview')));
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    await Directory('build/schedule-previews').create(recursive: true);
    await File('build/schedule-previews/$name.png')
        .writeAsBytes(data!.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  setUpAll(() async {
    final fonts = FontLoader('Onest');
    for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
      fonts.addFont(rootBundle.load('assets/fonts/Onest-$weight.ttf'));
    }
    await fonts.load();
    await (FontLoader('MaterialIcons')
          ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
        .load();
  });
  for (final brightness in Brightness.values) {
    testWidgets(
        'Day selection, independent weeks and repeated next-lesson focus: ${brightness.name}',
        (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({});
      Map<String, Object> item(
              String subject, String date, String start, String room) =>
          {
            'subject': subject,
            'date': date,
            'start': start,
            'end': start == '10:10' ? '11:40' : '13:20',
            'room': room,
            'teacher': 'Гуляева Н. В.',
            'lesson_type': 'lecture',
          };
      await http.runWithClient(() async {
        await tester.pumpWidget(MaterialApp(
          theme: buildTheme(brightness),
          home: RepaintBoundary(
              key: const ValueKey('preview'),
              child: Scaffold(
                body: SafeArea(
                    child: ScheduleTab(
                        group: 'ИЯ-201',
                        clock: () => DateTime(2026, 10, 7, 9, 30))),
                bottomNavigationBar: UnioNavigationBar(destinations: const [
                  NavigationDestination(
                      icon: Icon(Icons.calendar_month_rounded),
                      label: 'Расписание'),
                  NavigationDestination(
                      icon: Icon(Icons.school_outlined), label: 'Успеваемость'),
                  NavigationDestination(
                      icon: Icon(Icons.account_balance_outlined),
                      label: 'Университет'),
                  NavigationDestination(
                      icon: Icon(Icons.settings_outlined), label: 'Настройки'),
                ]),
              )),
        ));
        await tester.pumpAndSettle();
        await preview(tester, 'schedule-${brightness.name}');
        final next = find.byType(NextLessonCard);
        expect(find.text('Иностранный язык'), findsNWidgets(2));
        await tester
            .ensureVisible(find.byKey(const ValueKey('schedule-day-0')));
        await tester.tap(find.byKey(const ValueKey('schedule-day-0')));
        await tester.pumpAndSettle();
        expect(find.text('История'), findsOneWidget);
        await tester.tap(find.byType(PrimaryButton));
        await tester.pumpAndSettle();
        expect(find.text('Следующий понедельник'), findsOneWidget);
        await tester.tap(find.byType(PrimaryButton));
        await tester.pumpAndSettle();
        expect(find.text('История'), findsOneWidget);
        for (var i = 0; i < 2; i++) {
          // A stored selection must not override a focus request from another week.
          if (i == 0) {
            await tester.tap(find.byType(PrimaryButton));
            await tester.pumpAndSettle();
          }
          await tester.ensureVisible(next);
          await tester.tap(next);
          await tester.pumpAndSettle();
          expect(
              find
                  .byWidgetPredicate((w) =>
                      w is LessonRow && w.lesson.subject == 'Иностранный язык')
                  .hitTestable(),
              findsOneWidget);
          await tester
              .ensureVisible(find.byKey(const ValueKey('schedule-day-3')));
          await tester.tap(find.byKey(const ValueKey('schedule-day-3')));
          await tester.pumpAndSettle();
          expect(find.text('Пар нет — можно выдохнуть'), findsOneWidget);
          if (i == 0)
            await preview(tester, 'schedule-empty-${brightness.name}');
        }
        expect(tester.takeException(), isNull);
        tester.view.physicalSize = const Size(320, 568);
        tester.platformDispatcher.textScaleFactorTestValue = 1.5;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await tester.pumpAndSettle();
        await preview(tester, 'schedule-large-${brightness.name}');
        final navigation = find.byType(UnioNavigationBar);
        final barRect = tester.getRect(navigation);
        for (final label in [
          'Расписание',
          'Успеваемость',
          'Университет',
          'Настройки'
        ]) {
          final labelRect = tester.getRect(
              find.descendant(of: navigation, matching: find.text(label)));
          expect(labelRect.bottom, lessThanOrEqualTo(barRect.bottom));
          expect(labelRect.top, greaterThanOrEqualTo(barRect.top));
        }
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
          () => MockClient((request) async => http.Response(
              jsonEncode({
                'lessons': request.url.queryParameters['date'] == '2026-10-12'
                    ? [
                        item('Следующий понедельник', '2026-10-12', '10:10',
                            '314')
                      ]
                    : [
                        item('История', '2026-10-05', '10:10', '314'),
                        item('Иностранный язык', '2026-10-07', '10:10', '314'),
                        item('Педагогика', '2026-10-07', '11:50', '208')
                      ]
              }),
              200,
              headers: {'content-type': 'application/json; charset=utf-8'})));
    });

    testWidgets(
        'Student tools and teacher-only rooms fit small screens: ${brightness.name}',
        (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      Widget app(Widget screen) => MaterialApp(
          theme: buildTheme(brightness),
          builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(1.5)),
              child: child!),
          home: RepaintBoundary(key: const ValueKey('preview'), child: screen));
      await tester.pumpWidget(app(LessonNotesScreen(
          lesson: testLesson(),
          group: 'TEST',
          service: LessonNotesService(
              storage: MemoryNotesStorage(), owner: 'student'))));
      await tester.pumpAndSettle();
      expect(find.text('Найти свободную аудиторию'), findsNothing);
      await tester.ensureVisible(find.byType(LessonActions));
      await tester.pumpAndSettle();
      await preview(tester, 'notes-large-${brightness.name}');
      await tester.drag(find.byType(LessonActions), const Offset(-280, 0));
      await tester.pumpAndSettle();
      expect(find.text('Из галереи').hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(app(TeacherLessonScreen(lesson: testLesson())));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byType(LessonActions));
      await tester.pumpAndSettle();
      expect(find.text('Записать ДЗ'), findsNothing);
      expect(find.text('Найти свободную аудиторию'), findsOneWidget);
      await preview(tester, 'teacher-large-${brightness.name}');
      expect(tester.takeException(), isNull);
    });
  }
}
