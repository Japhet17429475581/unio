import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unio_app/config/brand.dart';
import 'package:unio_app/screens/welcome_screen.dart';
import 'package:unio_app/services/auth_service.dart';
import 'package:unio_app/services/direct_portal_client.dart';
import 'package:unio_app/widgets/welcome_visuals.dart';

// Pump finite transitions explicitly: the decorative background keeps moving.
Future<void> transition(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 1000));
  await tester.pump();
}

Future<void> tap(WidgetTester tester, String label) async {
  await tester.ensureVisible(find.text(label));
  await tester.tap(find.text(label));
  await transition(tester);
}

Future<void> mount(
  WidgetTester tester, {
  Size size = const Size(390, 844),
  double scale = 1,
  bool reducedMotion = false,
  Brightness brightness = Brightness.dark,
  Future<void> Function(String)? guest,
  Future<void> Function(String, String, String)? teacher,
  Future<void> Function(String, String, String)? portal,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(MaterialApp(
      theme: buildTheme(brightness),
      builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(scale),
              disableAnimations: reducedMotion),
          child: child!),
      home: RepaintBoundary(
          key: const ValueKey('preview'),
          child: WelcomeScreen(
              loadGroups: () async =>
                  ['TEST', 'TEST-101', 'ИЯ-АВБ-111', 'ЕН-ФББ-111'],
              onGuestLogin: guest ?? (_) async {},
              onTeacherLogin: teacher ?? (_, __, ___) async {},
              onPortalLogin: portal ?? (_, __, ___) async {}))));
  await transition(tester);
  await transition(tester);
  await tester.runAsync(() => precacheImage(
      const AssetImage('assets/icon/icon.png'),
      tester.element(find.byType(WelcomeScreen))));
  await tester.pump();
}

Future<void> preview(WidgetTester tester, String name) async {
  if (!const bool.fromEnvironment('WELCOME_PREVIEWS')) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const ValueKey('preview')));
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    await Directory('build/welcome-previews').create(recursive: true);
    await File('build/welcome-previews/$name.png')
        .writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  setUpAll(() async {
    // Real brand typography also makes locally exported previews representative.
    final loader = FontLoader('Onest');
    for (final font in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
      loader.addFont(rootBundle.load('assets/fonts/Onest-$font.ttf'));
    }
    await loader.load();
    await (FontLoader('MaterialIcons')
          ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
        .load();
  });
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets(
      'Swipe, back, next and completion reach roles and persist across restart',
      (tester) async {
    await mount(tester);
    expect(find.text('Привет! Это UNIO.'), findsOneWidget);
    await preview(tester, '01-intro');
    await tester.drag(find.byType(PageView), const Offset(-320, 0));
    await transition(tester);
    expect(find.text('Расписание занятий.'), findsOneWidget);
    await preview(tester, '02-schedule');
    await tester.binding.handlePopRoute();
    await transition(tester);
    expect(find.text('Привет! Это UNIO.'), findsOneWidget);
    await tap(tester, 'Дальше');
    await tap(tester, 'Дальше');
    expect(find.text('Нужна справка?'), findsOneWidget);
    await preview(tester, '03-requests');
    await tap(tester, 'Дальше');
    expect(find.text('Новости и преподаватели.'), findsOneWidget);
    await tap(tester, 'Начать');
    expect(find.text('Я студент'), findsOneWidget);
    expect(find.text('Пропустить'), findsNothing);
    await preview(tester, '04-roles');
    expect(
        (await SharedPreferences.getInstance())
            .getBool(onboardingCompletedPreferenceKey),
        true);
    await tester.pumpWidget(const SizedBox());
    await mount(tester);
    expect(find.byType(PageView), findsNothing);
    expect(find.text('Я преподаватель'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Skip is immediate; student guest validates and passes the group',
      (tester) async {
    String? group;
    await mount(tester, guest: (value) async {
      group = value;
    });
    await tap(tester, 'Пропустить');
    await tap(tester, 'Я студент');
    await preview(tester, '05-student');
    await tap(tester, 'Продолжить как гость');
    await tap(tester, 'Продолжить');
    expect(find.text('Введите номер группы'), findsOneWidget);
    expect(group, isNull);
    await tester.enterText(find.byType(TextField), 'WRONG-999');
    await tap(tester, 'Продолжить');
    expect(group, isNull);
    expect(find.textContaining('Такой группы нет в каталоге'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '  TEST-101  ');
    await tap(tester, 'Продолжить');
    expect(group, 'TEST-101');
    await tester.binding.handlePopRoute();
    await transition(tester);
    expect(find.text('Как тебе удобнее?'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'Portal login masks password, handles failure and prevents duplicate submissions',
      (tester) async {
    SharedPreferences.setMockInitialValues(
        {onboardingCompletedPreferenceKey: true});
    var calls = 0;
    var pending = Completer<void>();
    List<String>? credentials;
    await mount(tester, portal: (login, password, group) {
      calls++;
      credentials = [login, password, group];
      return pending.future;
    });
    await tap(tester, 'Я студент');
    await tap(tester, 'Войти через портал ВГСПУ');
    await preview(tester, '06-portal');
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), ' TEST ');
    await tester.enterText(fields.at(1), ' student ');
    await tester.enterText(fields.at(2), ' secret ');
    await tester.enterText(fields.at(0), 'WRONG-999');
    await tap(tester, 'Войти');
    expect(calls, 0);
    expect(find.textContaining('Такой группы нет в каталоге'), findsOneWidget);
    await tester.enterText(fields.at(0), ' TEST ');
    expect(tester.widget<TextField>(fields.at(2)).obscureText, true);
    await tester.tap(find.byTooltip('Показать пароль'));
    await tester.pump();
    expect(tester.widget<TextField>(fields.at(2)).obscureText, false);
    await tap(tester, 'Войти');
    expect(calls, 1);
    expect(credentials, ['student', ' secret ', 'TEST']);
    expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull);
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(find.byType(TextField), findsNWidgets(3));
    pending.completeError(AuthApiException('Проверьте логин и пароль'));
    await transition(tester);
    expect(find.text('Проверьте логин и пароль'), findsOneWidget);
    pending = Completer<void>();
    await tap(tester, 'Войти');
    expect(calls, 2);
    pending.complete();
    await transition(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'Teacher login requires portal credentials, preserves password and reports rejection',
      (tester) async {
    String? fio;
    List<String>? credentials;
    var reject = true;
    await mount(tester, teacher: (login, password, value) async {
      if (reject) throw const DirectPortalException('Проверьте логин и пароль');
      fio = value;
      credentials = [login, password];
    });
    await tap(tester, 'Пропустить');
    await tap(tester, 'Я преподаватель');
    await preview(tester, '07-teacher');
    await tester.enterText(
        find.byType(TextField).at(0), '  Иванов   Иван Иванович  ');
    await tap(tester, 'Войти');
    expect(
        find.text('Введите логин и пароль от портала ВГСПУ'), findsOneWidget);
    expect(fio, isNull);
    await tester.enterText(find.byType(TextField).at(1), ' teacher ');
    await tester.enterText(find.byType(TextField).at(2), ' secret ');
    expect(tester.widget<TextField>(find.byType(TextField).at(2)).obscureText,
        isTrue);
    await tap(tester, 'Войти');
    expect(find.text('Проверьте логин и пароль'), findsOneWidget);
    expect(fio, isNull);
    reject = false;
    await tap(tester, 'Войти');
    expect(fio, 'Иванов Иван Иванович');
    expect(credentials, ['teacher', ' secret ']);
    await tester.binding.handlePopRoute();
    await transition(tester);
    expect(find.text('Я студент'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final brightness in Brightness.values) {
    testWidgets(
        'Small screen, enlarged text and keyboard remain usable in ${brightness.name}',
        (tester) async {
      await mount(tester,
          size: const Size(320, 568),
          scale: 1.5,
          brightness: brightness,
          reducedMotion: true);
      expect(tester.takeException(), isNull);
      await tap(tester, 'Пропустить');
      await tap(tester, 'Я студент');
      await tap(tester, 'Войти через портал ВГСПУ');
      tester.view.viewInsets = const FakeViewPadding(bottom: 240);
      addTearDown(tester.view.resetViewInsets);
      await tester.pump();
      await tester.ensureVisible(find.byType(TextField).last);
      await tester.enterText(find.byType(TextField).last, 'test');
      await tap(tester, 'Войти');
      expect(find.text('Заполните группу, логин и пароль'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
      'Wide layout and reduced motion reach entry without a running background ticker',
      (tester) async {
    await mount(tester, size: const Size(1280, 800), reducedMotion: true);
    await tester.pumpAndSettle();
    await preview(tester, '08-wide-intro');
    await tap(tester, 'Пропустить');
    await tap(tester, 'Я студент');
    await tap(tester, 'Войти через портал ВГСПУ');
    await tester.pumpAndSettle();
    await preview(tester, '09-wide-login');
    expect(tester.binding.hasScheduledFrame, false);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Background animation pauses when the app leaves the foreground',
      (tester) async {
    await mount(tester);
    expect(find.byType(WelcomeBackdrop), findsOneWidget);
    expect(tester.binding.hasScheduledFrame, true);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump(const Duration(seconds: 2));
    expect(tester.binding.hasScheduledFrame, false);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(tester.binding.hasScheduledFrame, true);
    await tester.pumpWidget(const SizedBox());
    expect(tester.takeException(), isNull);
  });
}
