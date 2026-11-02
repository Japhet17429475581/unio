import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unio_app/config/brand.dart';
import 'package:unio_app/config/calm_depth.dart';
import 'package:unio_app/screens/schedule_tab.dart';
import 'package:unio_app/widgets/lesson_row.dart';
import 'package:unio_app/widgets/next_lesson_card.dart';
import 'package:unio_app/widgets/tap_feedback.dart';
import 'package:unio_app/widgets/unio_loader.dart';

import 'schedule_design_test.dart' show preview;

double contrast(Color a, Color b) {
  final first = a.computeLuminance();
  final second = b.computeLuminance();
  return (math.max(first, second) + .05) / (math.min(first, second) + .05);
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
    test('Small schedule text meets AA contrast in ${brightness.name}', () {
      final theme = CalmDepth.theme(buildTheme(brightness));
      final colors = theme.colorScheme;
      for (final surface in [
        theme.scaffoldBackgroundColor,
        colors.surface,
        colors.surfaceContainer
      ]) {
        expect(contrast(colors.onSurface, surface), greaterThanOrEqualTo(4.5));
        expect(contrast(colors.onSurfaceVariant, surface),
            greaterThanOrEqualTo(4.5));
      }
      expect(contrast(colors.onPrimaryContainer, colors.primaryContainer),
          greaterThanOrEqualTo(4.5));
      final signature = theme.extension<UnioSignature>()!;
      for (var i = 0; i <= 10; i++) {
        final background = Color.lerp(signature.start, signature.end, i / 10)!;
        final counterBackground = Color.alphaBlend(
            signature.foreground.withValues(alpha: .08), background);
        for (final foreground in [signature.foreground, signature.secondary]) {
          expect(contrast(foreground, background), greaterThanOrEqualTo(4.5));
          expect(contrast(foreground, counterBackground),
              greaterThanOrEqualTo(4.5));
        }
      }
    });

    testWidgets(
        'Teacher signature preserves navigation with large text and reduced motion: ${brightness.name}',
        (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({});
      final requests = <Uri>[];
      String? opened;
      await http.runWithClient(() async {
        await tester.pumpWidget(MaterialApp(
          theme: buildTheme(brightness),
          home: RepaintBoundary(
              key: const ValueKey('preview'),
              child: MediaQuery(
                  data: const MediaQueryData(
                      size: Size(320, 568),
                      textScaler: TextScaler.linear(1.6),
                      disableAnimations: true),
                  child: Scaffold(
                      body: ScheduleTab.teacher(
                    fio: 'Иванов Иван Иванович',
                    clock: () => DateTime(2026, 10, 7, 9, 30),
                    onLessonTap: (lesson) => opened = lesson.subject,
                  )))),
        ));
        await tester.pumpAndSettle();
        expect(requests, hasLength(2));
        expect(requests.map((request) => request.path),
            everyElement('/api/v1/teachers/schedule'));
        expect(find.text('30:00'), findsOneWidget);
        await preview(tester, 'schedule-teacher-large-${brightness.name}');
        final semantics = tester.ensureSemantics();
        expect(
            find.bySemanticsLabel(
                RegExp('Следующая пара сегодня: Математика.*аудитория 101')),
            findsOneWidget);
        semantics.dispose();
        await tester.tap(find.byType(PrimaryButton));
        await tester.pumpAndSettle();
        expect(requests, hasLength(2));
        await tester.ensureVisible(find.byType(NextLessonCard));
        await tester.pumpAndSettle();
        await tester.tap(find.byType(NextLessonCard));
        await tester.pumpAndSettle();
        final lesson = find.byType(LessonRow).hitTestable();
        expect(lesson, findsOneWidget);
        expect(tester.widget<LessonRow>(lesson).highlighted, isTrue);
        await tester.tap(lesson);
        expect(opened, 'Математика');
        expect(requests, hasLength(2));
        // Countdown ticks must not start a new entrance transition.
        await tester.pump(const Duration(seconds: 1));
        final entrance = find.descendant(
            of: find.byType(NextLessonCard), matching: find.byType(Opacity));
        expect(tester.widget<Opacity>(entrance.first).opacity, 1);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
          () => MockClient((request) async {
                if (request.url.path == '/api/v1/news')
                  return http.Response('{"items":[]}', 200);
                requests.add(request.url);
                return http.Response(
                    jsonEncode({
                      'success': true,
                      'groups': {
                        'preview': <String>[],
                        'total': 0,
                        'has_more': false
                      },
                      'lessons': [
                        {
                          'date': request.url.queryParameters['date'] ==
                                  '2026-10-12'
                              ? '2026-10-12'
                              : '2026-10-07',
                          'start': '10:00',
                          'end': '11:00',
                          'subject': 'Математика',
                          'room': '101',
                          'lesson_type': 'lecture',
                        }
                      ]
                    }),
                    200,
                    headers: {
                      'content-type': 'application/json; charset=utf-8'
                    });
              }));
    });

    testWidgets(
        'Loading and recoverable error retain their real states: ${brightness.name}',
        (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({});
      await http.runWithClient(() async {
        await tester.pumpWidget(MaterialApp(
            theme: buildTheme(brightness),
            home: RepaintBoundary(
                key: const ValueKey('preview'),
                child: Scaffold(
                    body: ScheduleTab(
                        group: 'ИЯ-201',
                        clock: () => DateTime(2026, 10, 7, 9, 30))))));
        await tester.pump(const Duration(milliseconds: 100));
        expect(find.byType(UnioLoader), findsOneWidget);
        await preview(tester, 'schedule-loading-${brightness.name}');
        await tester.pump(const Duration(seconds: 2));
        await tester.pumpAndSettle();
        expect(find.text('Не удалось загрузить расписание'), findsOneWidget);
        expect(find.text('На этой неделе пар нет'), findsNothing);
        await preview(tester, 'schedule-error-${brightness.name}');
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
          () => MockClient((_) async {
                await Future<void>.delayed(const Duration(seconds: 1));
                return http.Response('{}', 503);
              }));
    });
  }
}
