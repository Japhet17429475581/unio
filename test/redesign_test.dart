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
import 'package:unio_app/screens/university_tab.dart';
import 'package:unio_app/screens/settings_tab.dart';
import 'package:unio_app/screens/portal_upgrade_screen.dart';
import 'package:unio_app/screens/teacher_search_screen.dart';
import 'package:unio_app/screens/teacher_lesson_screen.dart';
import 'package:unio_app/screens/news_list_screen.dart';
import 'package:unio_app/screens/news_detail_screen.dart';
import 'package:unio_app/widgets/guide_stories.dart';
import 'support/notes_fakes.dart';
import 'teacher_search_test.dart' show directoryData;

Future<void> preview(WidgetTester tester, String name) async {
  if (!const bool.fromEnvironment('REDESIGN_PREVIEWS')) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const ValueKey('preview')));
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    await Directory('build/redesign-previews').create(recursive: true);
    await File('build/redesign-previews/$name.png')
        .writeAsBytes(data!.buffer.asUint8List());
    image.dispose();
  });
}

Future<void> mount(WidgetTester tester, Widget screen,
    {Brightness brightness = Brightness.dark,
    Size size = const Size(390, 844),
    double scale = 1,
    bool settle = true,
    bool reducedMotion = false}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  await tester.pumpWidget(RepaintBoundary(
      key: const ValueKey('preview'),
      child: MaterialApp(
        theme: buildTheme(brightness),
        debugShowCheckedModeBanner: false,
        builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(scale),
                disableAnimations: reducedMotion),
            child: child!),
        home: screen,
      )));
  if (settle) await tester.pumpAndSettle();
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
  setUp(() => SharedPreferences.setMockInitialValues({}));
  for (final brightness in Brightness.values) {
    testWidgets(
        'Stories swipe, go back, close, remember completion and reopen in ${brightness.name}',
        (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final semantics = tester.ensureSemantics();
      try {
        await mount(
            tester,
            Scaffold(
                body: SafeArea(
                    child: ListView(
                        padding: const EdgeInsets.all(20),
                        children: const [GuideStories()]))),
            brightness: brightness);
        expect(find.byKey(const ValueKey('guide-rooms')), findsNothing);
        await preview(tester, 'stories-${brightness.name}');
        await tester.tap(find.byKey(const ValueKey('guide-unio')));
        await tester.pumpAndSettle();
        expect(find.text('Как смотреть\nрасписание'), findsOneWidget);
        await preview(tester, 'guide-schedule');
        await tester.drag(find.byType(PageView), const Offset(-340, 0));
        await tester.pumpAndSettle();
        expect(find.text('Как сменить\nнеделю'), findsOneWidget);
        await tester.tap(find.byTooltip('Назад'));
        await tester.pumpAndSettle();
        expect(find.text('Как смотреть\nрасписание'), findsOneWidget);
        await tester.tap(find.byTooltip('Закрыть гайд'));
        await tester.pumpAndSettle();
        expect(
            (await SharedPreferences.getInstance())
                .getStringList(guideSeenPreference),
            isNull);
        await tester.tap(find.byKey(const ValueKey('guide-unio')));
        await tester.pumpAndSettle();
        for (var i = 0;
            i < guideStories(teacher: false).single.slides.length - 1;
            i++) {
          await tester.tap(find.text('Дальше'));
          await tester.pumpAndSettle();
        }
        await tester.tap(find.text('Понятно'));
        await tester.pumpAndSettle();
        expect(
            (await SharedPreferences.getInstance())
                .getStringList(guideSeenPreference),
            contains('unio-student-v2'));
        await tester.pumpWidget(const SizedBox());
        await mount(tester, const Scaffold(body: GuideStories()),
            brightness: brightness);
        expect(find.bySemanticsLabel('Первое знакомство. Просмотрено'),
            findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('guide-unio')));
        await tester.pumpAndSettle();
        expect(find.text('Как смотреть\nрасписание'), findsOneWidget);
        expect(tester.takeException(), isNull);
      } finally {
        semantics.dispose();
      }
    });

    testWidgets(
        'Services, settings, login, search, news and rooms in ${brightness.name}',
        (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final article = {
        'id': 1,
        'title': 'Новая неделя — новые возможности',
        'image_url': 'https://example.com/news-preview.png',
        'published_at': '2026-10-10T10:00:00',
        'source_url': 'https://vgspu.ru/',
        'content':
            'В университете начинается неделя студенческих инициатив.\n\nВыбирайте события по интересам и знакомьтесь с участниками.'
      };
      await http.runWithClient(() async {
        await mount(
            tester,
            Scaffold(
                body: UniversityTab(
                    isPortalMode: false, onUpgradeToPortal: (_, __) async {})),
            brightness: brightness);
        await preview(tester, 'university-${brightness.name}');
        expect(find.text('Подать заявление'), findsOneWidget);
        await mount(
            tester,
            Scaffold(
                body: SettingsTab.teacher(
                    fio: 'Иванов Иван Иванович',
                    onLogout: () {},
                    darkMode: brightness == Brightness.dark,
                    onDarkModeChanged: (_) {})),
            brightness: brightness);
        await preview(tester, 'settings-${brightness.name}');
        await mount(tester, PortalUpgradeScreen(onSubmit: (_, __) async {}),
            brightness: brightness);
        await preview(tester, 'login-${brightness.name}');
        await tester.ensureVisible(find.text('Войти'));
        await tester.tap(find.text('Войти'));
        await tester.pumpAndSettle();
        expect(find.textContaining('Введите логин и пароль'), findsOneWidget);
        await mount(tester, const TeacherSearchScreen(),
            brightness: brightness);
        await tester.enterText(find.byType(TextField), 'Гуля');
        await tester.pumpAndSettle();
        expect(
            tester
                .widget<EditableText>(find.byType(EditableText))
                .focusNode
                .hasFocus,
            isTrue);
        await preview(tester, 'search-${brightness.name}');
        await mount(tester, const NewsListScreen(), brightness: brightness);
        await preview(tester, 'news-${brightness.name}');
        await tester.ensureVisible(find.text(article['title'] as String));
        await tester.tap(find.text(article['title'] as String));
        await tester.pumpAndSettle();
        expect(find.byType(NewsDetailScreen), findsOneWidget);
        await preview(tester, 'article-${brightness.name}');
        await tester.pageBack();
        await tester.pumpAndSettle();
        await mount(tester, FreeRoomsScreen(lesson: testLesson()),
            brightness: brightness);
        expect(find.text('Ауд. 205'), findsOneWidget);
        await preview(tester, 'rooms-${brightness.name}');
        expect(tester.takeException(), isNull);
      },
          () => MockClient((request) async {
                final Object data = switch (request.url.path) {
                  '/api/v1/teachers/directory' => directoryData(),
                  '/api/v1/news' => {
                      'items': [article]
                    },
                  '/api/v1/news/1' => {'item': article},
                  '/api/v1/teachers/free-rooms' => {
                      'success': true,
                      'rooms': ['205', '314', '208'],
                      'note': 'По расписаниям, известным UNIO.'
                    },
                  _ => throw StateError('Unexpected request ${request.url}'),
                };
                return http.Response(jsonEncode(data), 200, headers: {
                  'content-type': 'application/json; charset=utf-8'
                });
              }));
    });
  }

  testWidgets(
      'Teacher-only story and enlarged text with reduced motion stay usable',
      (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await mount(
        tester,
        Scaffold(
            body: ListView(
                padding: const EdgeInsets.all(20),
                children: const [GuideStories(teacher: true)])),
        size: const Size(320, 568),
        scale: 1.5,
        reducedMotion: true);
    expect(find.byKey(const ValueKey('guide-notes')), findsNothing);
    expect(find.byKey(const ValueKey('guide-requests')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('guide-unio')));
    await tester.pumpAndSettle();
    await preview(tester, 'guide-large');
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.text('Дальше'));
      await tester.pumpAndSettle();
    }
    expect(find.text('Что показывает поиск'), findsOneWidget);
    expect(tester.binding.hasScheduledFrame, isFalse);
    while (find.text('Дальше').evaluate().isNotEmpty) {
      await tester.tap(find.text('Дальше'));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text('Понятно'));
    await tester.pumpAndSettle();
    expect(find.byType(GuideStoryScreen), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
