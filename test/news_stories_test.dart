import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unio_app/models/news_article.dart';
import 'package:unio_app/services/news_stories_controller.dart';
import 'package:unio_app/screens/news_detail_screen.dart';
import 'package:unio_app/screens/news_story_screen.dart';
import 'package:unio_app/widgets/campus_stories.dart';
import 'package:unio_app/widgets/story_circle.dart';
import 'package:unio_app/widgets/story_entrance.dart';
import 'redesign_test.dart' show mount, preview;

NewsListItem item(int id) => NewsListItem(
    id: id,
    title: id == 1
        ? 'В университете открылась выставка'
        : 'Новость университета №$id',
    imageUrl: 'https://example.com/news-$id.jpg',
    sourceUrl: 'https://vgspu.ru/news/$id',
    publishedAt: DateTime(2026, 10, 13));

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

  test(
      'Shared feed loads once, paginates, deduplicates and restores cached news',
      () async {
    final offsets = <int>[];
    final firstPage = Completer<List<NewsListItem>>();
    final feed = NewsStoriesController(fetch: (offset) async {
      offsets.add(offset);
      if (offset == 0) return await firstPage.future;
      return [item(20), item(21)];
    });
    feed.start();
    feed.start();
    expect(offsets, [0]);
    firstPage.complete(List.generate(20, (i) => item(i + 1)));
    while (feed.loading) {
      await Future<void>.delayed(Duration.zero);
    }
    await feed.load();
    expect(offsets, [0, 20]);
    expect(feed.items.map((i) => i.id).toSet(), hasLength(21));
    expect(feed.hasMore, isFalse);
    await feed.load();
    expect(offsets, [0, 20]);
    feed.dispose();
    final offline =
        NewsStoriesController(fetch: (_) async => throw StateError('offline'));
    await offline.load(refresh: true);
    expect(offline.items, hasLength(20));
    expect(offline.saved, isTrue);
    offline.dispose();
  });

  test('Late network completion after leaving schedule is harmless', () async {
    final pending = Completer<List<NewsListItem>>();
    final feed = NewsStoriesController(fetch: (_) => pending.future);
    final result = feed.load(refresh: true);
    feed.dispose();
    pending.complete([item(1)]);
    await result;
  });

  test('Excerpt uses supplied article text, strips markup and bounds length',
      () {
    expect(
        newsExcerpt(const NewsArticle(
            id: 1,
            title: 'Title',
            sourceUrl: '',
            description: '<p>Новость &amp; событие</p>')),
        'Новость & событие');
    final summary = newsExcerpt(NewsArticle(
        id: 1,
        title: 'Title',
        sourceUrl: '',
        content: List.filled(100, 'Учебный год').join(' ')));
    expect(summary.length, lessThanOrEqualTo(361));
    expect(summary.endsWith('…'), isTrue);
  });

  testWidgets('Late news stories enter from the right in a staggered order',
      (tester) async {
    final pending = Completer<List<NewsListItem>>();
    final feed = NewsStoriesController(fetch: (_) => pending.future);
    await mount(tester,
        Scaffold(body: SafeArea(child: CampusStories(controller: feed))));
    expect(find.byKey(const ValueKey('guide-unio')), findsOneWidget);
    expect(find.byKey(const ValueKey('news-story-1')), findsNothing);
    pending.complete(List.generate(3, (index) => item(index + 1)));
    await tester.pump();
    await tester.pump();
    FadeTransition fade(int id) => tester.widget(find
        .descendant(
            of: find.byKey(ValueKey('story-entrance-$id')),
            matching: find.byType(FadeTransition))
        .first);
    expect(fade(1).opacity.value, 0);
    expect(fade(3).opacity.value, 0);
    await tester.pump(const Duration(milliseconds: 180));
    expect(fade(3).opacity.value, greaterThan(fade(1).opacity.value));
    final slide = tester.widget<SlideTransition>(find
        .descendant(
            of: find.byKey(const ValueKey('story-entrance-3')),
            matching: find.byType(SlideTransition))
        .first);
    expect(slide.position.value.dx, greaterThan(0));
    await tester.pumpAndSettle();
    expect(find.byType(StoryCircle).hitTestable(), findsNWidgets(4));
    expect(fade(1).opacity.value, 1);
    expect(find.byType(StoryEntrance), findsNWidgets(4));
    await tester.pumpWidget(const SizedBox());
    feed.dispose();
  });

  for (final brightness in Brightness.values) {
    testWidgets(
        'Four circles per page, real article preview and full article: ${brightness.name}',
        (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final feed = NewsStoriesController(
          fetch: (_) async => List.generate(7, (i) => item(i + 1)));
      var articleCalls = 0;
      await http.runWithClient(() async {
        await mount(
            tester,
            Scaffold(
                body: SafeArea(
                    child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [CampusStories(controller: feed)]))),
            brightness: brightness);
        await tester.pumpAndSettle();
        expect(find.byType(StoryCircle).hitTestable(), findsNWidgets(4));
        expect(find.byKey(const ValueKey('guide-unio')).hitTestable(),
            findsOneWidget);
        await preview(tester, 'news-stories-${brightness.name}');
        await tester.tap(find.byKey(const ValueKey('news-story-1')));
        await tester.pumpAndSettle();
        expect(find.byType(NewsStoryScreen), findsOneWidget);
        expect(find.text('Описание выставки из настоящего поля статьи.'),
            findsOneWidget);
        await preview(tester, 'news-story-${brightness.name}');
        await tester.tap(find.text('Читать полностью'));
        await tester.pumpAndSettle();
        expect(find.byType(NewsDetailScreen), findsOneWidget);
        expect(find.text('Полный текст новости.'), findsOneWidget);
        expect(articleCalls, 1); // Reuse the loaded article, no extra request.
        await tester.pageBack();
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('Закрыть новость'));
        await tester.pumpAndSettle();
        expect(
            tester
                .widget<StoryCircle>(find.byKey(const ValueKey('news-story-1')))
                .seen,
            isTrue);
        await tester.drag(find.byType(PageView), const Offset(-350, 0));
        await tester.pumpAndSettle();
        expect(find.byType(StoryCircle).hitTestable(), findsNWidgets(4));
        expect(find.byKey(const ValueKey('news-story-7')).hitTestable(),
            findsOneWidget);
        expect(find.byKey(const ValueKey('guide-unio')).hitTestable(),
            findsNothing);
        await mount(
            tester,
            Scaffold(
                body: ListView(children: [CampusStories(controller: feed)])),
            brightness: brightness,
            size: const Size(320, 568),
            scale: 1.6,
            reducedMotion: true);
        expect(find.byType(StoryCircle).hitTestable(), findsNWidgets(2));
        for (final entrance
            in tester.widgetList<StoryEntrance>(find.byType(StoryEntrance))) {
          final fade = tester.widget<FadeTransition>(find.descendant(
              of: find.byWidget(entrance),
              matching: find.byType(FadeTransition)));
          expect(fade.opacity.value, 1);
        }
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
          () => MockClient((request) async {
                articleCalls++;
                expect(request.url.path, '/api/v1/news/1');
                return http.Response(
                    jsonEncode({
                      'item': {
                        'id': 1,
                        'title': item(1).title,
                        'description':
                            'Описание выставки из настоящего поля статьи.',
                        'content': 'Полный текст новости.',
                        'image_url': item(1).imageUrl,
                        'source_url': item(1).sourceUrl,
                        'published_at': '2026-10-13T10:00:00'
                      }
                    }),
                    200,
                    headers: {
                      'content-type': 'application/json; charset=utf-8'
                    });
              }));
      feed.dispose();
    });
  }
}
