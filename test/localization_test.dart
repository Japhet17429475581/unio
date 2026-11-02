import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unio_app/config/brand.dart';
import 'package:unio_app/l10n/app_localizations.dart';
import 'package:unio_app/models/portal_request.dart';
import 'package:unio_app/models/lesson.dart';
import 'package:unio_app/screens/lesson_notes_screen.dart';
import 'package:unio_app/screens/settings_tab.dart';
import 'package:unio_app/services/locale_service.dart';
import 'package:unio_app/services/lesson_notes_service.dart';
import 'package:unio_app/utils/date_utils.dart';
import 'package:unio_app/utils/lesson_type.dart';
import 'package:unio_app/utils/service_messages.dart';
import 'package:unio_app/widgets/guide_stories.dart';
import 'support/notes_fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    await appLocale.load();
  });
  tearDown(() async {
    await appLocale.select('ru');
  });

  test('Both catalogs contain every message and matching placeholders', () {
    final ru =
        jsonDecode(File('lib/l10n/app_ru.arb').readAsStringSync()) as Map;
    final en =
        jsonDecode(File('lib/l10n/app_en.arb').readAsStringSync()) as Map;
    final keys =
        ru.keys.where((key) => !(key as String).startsWith('@')).toSet();
    expect(
        en.keys.where((key) => !(key as String).startsWith('@')).toSet(), keys);
    for (final key in keys) {
      expect((en[key] as String).trim(), isNotEmpty, reason: '$key');
      final placeholders = RegExp(r'\{p\d+\}');
      expect(placeholders.allMatches(en[key]).map((m) => m[0]).toSet(),
          placeholders.allMatches(ru[key]).map((m) => m[0]).toSet(),
          reason: '$key');
      expect(RegExp('[А-Яа-яЁё]').hasMatch(en[key]), isFalse, reason: '$key');
    }
  });

  test('Language persists and unknown stored locales safely use Russian',
      () async {
    expect(appLocale.locale.languageCode, 'ru');
    await appLocale.select('en');
    final restored = LocaleService();
    await restored.load();
    expect(restored.locale.languageCode, 'en');
    expect(restored.strings.uiSettings, 'Settings');
    await expectLater(appLocale.select('xx'), throwsArgumentError);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(LocaleService.preferenceKey, 'xx');
    await restored.load();
    expect(restored.locale.languageCode, 'ru');
    restored.dispose();
  });

  test('Dates, guides and safe errors change without caching the old language',
      () async {
    final day = DateTime(2026, 10, 19);
    expect(weekdayName(day), 'Понедельник');
    expect(typeStyle('lecture').label, 'Лекция');
    await appLocale.select('en');
    expect(weekdayName(day), 'Monday');
    expect(dayMonthLabel(day), '19 October');
    expect(pairsLabel(1), 'class');
    expect(pairsLabel(21), 'classes');
    expect(typeStyle('lecture').label, 'Lecture');
    expect(responseMessage(401), 'Sign in again and retry this action.');
    expect(guideStories(teacher: false).single.label, 'Getting started');
    // Language changes must not alter the Russian protocol status or actions.
    const item = RequestListItem(
        id: 'test',
        title: 'Исходный документ',
        category: 'Исходная категория',
        status: 'получение информации',
        updated: '',
        editUrl: '');
    expect(item.canFill, isTrue);
    expect(item.displayStatus, 'Open form');
    expect(item.title, 'Исходный документ');
    await appLocale.select('ru');
    expect(weekdayName(day), 'Понедельник');
    expect(item.displayStatus, 'Перейти к заполнению');
  });

  for (final width in [320.0, 430.0]) {
    testWidgets('Language picker applies immediately at width $width',
        (tester) async {
      tester.view.physicalSize = Size(width, 1100);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(ListenableBuilder(
        listenable: appLocale,
        builder: (_, __) => MaterialApp(
          locale: appLocale.locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          theme: buildTheme(Brightness.dark),
          home: Scaffold(
              body: SettingsTab.teacher(
            fio: 'Test Teacher',
            onLogout: () {},
            darkMode: true,
            onDarkModeChanged: (_) {},
          )),
        ),
      ));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Язык'), 120);
      await tester.tap(find.text('Язык'));
      await tester.pumpAndSettle();
      expect(find.text('Русский'), findsWidgets);
      await tester.tap(find.text('English'));
      await tester.pumpAndSettle();
      expect(find.text('Language'), findsOneWidget);
      expect(find.text('Dark theme'), findsOneWidget);
      await tester.drag(find.byType(ListView), const Offset(0, 900));
      await tester.pumpAndSettle();
      expect(find.text('Settings'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.scrollUntilVisible(find.text('Language'), 120);
      await tester.tap(find.text('Language'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Русский'));
      await tester.pumpAndSettle();
      expect(find.text('Язык'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Changing language preserves an unsaved note and screen state',
      (tester) async {
    final service =
        LessonNotesService(storage: MemoryNotesStorage(), owner: 'test');
    final lesson = Lesson(
        date: DateTime(2026, 10, 24),
        start: '09:40',
        end: '11:10',
        subject: 'Исходный предмет',
        type: 'lecture',
        teacher: 'Test Teacher',
        room: '101');
    final screen =
        LessonNotesScreen(lesson: lesson, group: 'TEST', service: service);
    await tester.pumpWidget(ListenableBuilder(
      listenable: appLocale,
      builder: (_, __) => MaterialApp(
        locale: appLocale.locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        theme: buildTheme(Brightness.dark),
        home: screen,
      ),
    ));
    await tester.pumpAndSettle();
    final state = tester.state(find.byType(LessonNotesScreen));
    await tester.enterText(
        find.byType(TextField).first, 'Unsaved homework / несохранённое ДЗ');
    await appLocale.select('en');
    await tester.pumpAndSettle();
    expect(tester.state(find.byType(LessonNotesScreen)), same(state));
    expect(find.text('Unsaved homework / несохранённое ДЗ'), findsOneWidget);
    expect(find.text('Homework and notes'), findsOneWidget);
    expect(find.text('Исходный предмет'), findsOneWidget);
    await appLocale.select('ru');
    await tester.pumpAndSettle();
    expect(find.text('Unsaved homework / несохранённое ДЗ'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
