import 'package:unio_app/screens/gradebook_tab.dart';
import 'package:unio_app/screens/assistant_screen.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unio_app/config/brand.dart';
import 'package:unio_app/l10n/app_localizations.dart';
import 'package:unio_app/screens/home_screen.dart';
import 'package:unio_app/screens/schedule_tab.dart';
import 'package:unio_app/screens/settings_tab.dart';
import 'package:unio_app/screens/university_tab.dart';
import 'package:unio_app/widgets/campus_stories.dart';
import 'package:unio_app/widgets/next_lesson_card.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:unio_app/services/locale_service.dart';
import 'package:unio_app/services/schedule_repository.dart';

http.Response weekResponse(Uri uri) => http.Response(
    jsonEncode({
      'lessons': [
        {
          'date': uri.queryParameters['date'],
          'start': '23:00',
          'end': '23:50',
          'subject': 'A long university subject title',
          'teacher': 'Demo teacher',
          'room': '314',
          'group': uri.queryParameters['group'],
          'lesson_type': 'lecture',
        }
      ],
    }),
    200);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    await appLocale.load();
  });

  test('Both prefetched weeks and refresh reuse pending requests', () async {
    final calls = <Uri>[];
    final repository = ScheduleRepository(group: 'TEST');
    final monday = DateTime(2026, 11, 9);
    await http.runWithClient(() async {
      repository.prefetch(monday);
      final home = repository.week(monday);
      expect(identical(repository.refresh(monday), home), isTrue);
      final schedule = repository.week(monday.add(const Duration(days: 2)));
      expect(identical(home, schedule), isTrue);
      await Future.wait(
          [home, repository.week(monday.add(const Duration(days: 7)))]);
      expect(calls, hasLength(2));
      final updated = repository.refresh(monday);
      expect(identical(repository.week(monday), updated), isTrue);
      await updated;
      expect(calls, hasLength(3));
      expect(calls.last.queryParameters['force_refresh'], 'true');
      repository.dispose();
    },
        () => MockClient((request) async {
              calls.add(request.url);
              return weekResponse(request.url);
            }));
  });

  test('Changing group during a request cannot replace the new group result',
      () async {
    final old = Completer<http.Response>();
    final repository = ScheduleRepository(group: 'OLD');
    final day = DateTime(2026, 11, 9);
    await http.runWithClient(() async {
      final first = repository.week(day);
      repository.select(group: 'NEW');
      final second = repository.week(day);
      final result = await second;
      expect(result.single.group, 'NEW');
      old.complete(weekResponse(
          Uri.parse('https://example.test/?date=2026-11-09&group=OLD')));
      await first;
      expect(identical(repository.week(day), second), isTrue);
      expect((await repository.week(day)).single.group, 'NEW');
      repository.dispose();
    },
        () => MockClient((request) async =>
            request.url.queryParameters['group'] == 'OLD'
                ? await old.future
                : weekResponse(request.url)));
  });

  test('Offline refresh reports saved data instead of pretending it is live',
      () async {
    var offline = false;
    final repository = ScheduleRepository(group: 'TEST');
    final day = DateTime(2026, 11, 9);
    await http.runWithClient(() async {
      await repository.week(day);
      expect(repository.isSaved(day), isFalse);
      offline = true;
      expect(await repository.refresh(day), isNotEmpty);
      expect(repository.isSaved(day), isTrue);
      offline = false;
      await repository.refresh(day);
      expect(repository.isSaved(day), isFalse);
      repository.dispose();
    },
        () => MockClient((request) async => offline
            ? http.Response('unavailable', 503)
            : weekResponse(request.url)));
  });

  testWidgets('AI grade action selects the restored tab and keeps the chat',
      (tester) async {
    await http.runWithClient(() async {
      await tester.pumpWidget(MaterialApp(
        theme: buildTheme(Brightness.dark),
        locale: const Locale('ru'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: HomeScreen(
            group: 'TEST',
            isPortalMode: false,
            onLogout: () {},
            onUpgradeToPortal: (_, __) async {},
            darkMode: true,
            onDarkModeChanged: (_) {}),
      ));
      await tester.pumpAndSettle();
      expect(find.byType(GradebookTab, skipOffstage: false), findsNothing);
      await tester.tap(find.text(l10n.aiTitle));
      await tester.pumpAndSettle();
      final chatScreen =
          tester.widget<AssistantScreen>(find.byType(AssistantScreen));
      chatScreen.conversation.setDraft('Keep this draft');
      chatScreen.onOpenGrades!();
      await tester.pumpAndSettle();
      expect(
          tester
              .widget<NavigationBar>(find.byType(NavigationBar))
              .selectedIndex,
          1);
      expect(find.byType(GradebookTab), findsOneWidget);
      expect(find.byType(BackButton), findsNothing);
      await tester.tap(find.text(l10n.aiTitle));
      await tester.pumpAndSettle();
      final restored =
          tester.widget<AssistantScreen>(find.byType(AssistantScreen));
      expect(identical(restored.conversation, chatScreen.conversation), isTrue);
      expect(restored.conversation.draft, 'Keep this draft');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
        () => MockClient((request) async => http.Response(
            request.url.path.contains('news')
                ? '{"items":[]}'
                : '{"lessons":[]}',
            200)));
  });

  for (final brightness in Brightness.values) {
    for (final width in [320.0, 430.0, 1100.0]) {
      testWidgets(
          'Original schedule opens first at $width / $brightness / large text',
          (tester) async {
        tester.view.physicalSize = Size(width, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final calls = <Uri>[];
        await http.runWithClient(() async {
          await tester.pumpWidget(MaterialApp(
            theme: buildTheme(brightness),
            locale: const Locale('ru'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                    textScaler: const TextScaler.linear(1.6),
                    disableAnimations: true),
                child: child!),
            home: HomeScreen(
                group: 'TEST',
                isPortalMode: true,
                onLogout: () {},
                onUpgradeToPortal: (_, __) async {},
                darkMode: brightness == Brightness.dark,
                onDarkModeChanged: (_) {}),
          ));
          await tester.pumpAndSettle();
          final navigation =
              tester.widget<NavigationBar>(find.byType(NavigationBar));
          expect(navigation.selectedIndex, 0);
          expect(navigation.destinations, hasLength(4));
          expect(find.byType(ScheduleTab), findsOneWidget);
          expect(find.byType(NextLessonCard), findsWidgets);
          expect(find.byType(CampusStories), findsOneWidget);
          final storiesTop = tester.getTopLeft(find.byType(CampusStories)).dy;
          final nextTop =
              tester.getTopLeft(find.byType(NextLessonCard).first).dy;
          expect(storiesTop, lessThan(nextTop));
          expect(
              calls.where((u) => u.path.endsWith('/schedule')), hasLength(2));
          expect(calls.any((u) => u.path.contains('grades')), isFalse);
          expect(tester.takeException(), isNull);

          await tester.tap(find.byTooltip(l10n.uiSettings));
          await tester.pumpAndSettle();
          expect(find.byType(SettingsTab), findsOneWidget);
          expect(find.text(l10n.uiAccountAndAppPreferences), findsOneWidget);
          await tester.tap(find.byType(BackButton));
          await tester.pumpAndSettle();
          await tester.tap(find.text(l10n.uiUniversity).last);
          await tester.pumpAndSettle();
          expect(find.byType(UniversityTab), findsOneWidget);
          expect(
              find.descendant(
                  of: find.byType(UniversityTab),
                  matching: find.text(l10n.uiAcademicProgress)),
              findsNothing);
          expect(calls.any((u) => u.path.contains('grades')), isFalse);
          expect(tester.takeException(), isNull);
          // Returning to the schedule keeps the same shelf and cached weeks.
          await tester.tap(find.text(l10n.uiSchedule).last);
          await tester.pumpAndSettle();
          expect(find.byType(CampusStories), findsOneWidget);
          expect(
              calls.where((u) => u.path.endsWith('/schedule')), hasLength(2));
          await tester.pumpWidget(const SizedBox());
        },
            () => MockClient((request) async {
                  calls.add(request.url);
                  if (request.url.path.endsWith('/news'))
                    return http.Response('{"items":[]}', 200);
                  return weekResponse(request.url);
                }));
      });
    }
  }
}
