import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:unio_app/widgets/unio_ai_brand.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unio_app/config/brand.dart';
import 'package:unio_app/l10n/app_localizations.dart';
import 'package:unio_app/screens/assistant_screen.dart';
import 'package:unio_app/services/assistant_service.dart';
import 'package:unio_app/services/locale_service.dart';
import 'package:unio_app/widgets/assistant_entry_button.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
    await appLocale.load();
  });
  testWidgets(
      'Sources without URLs retain titles; only official links are actionable',
      (tester) async {
    for (final linked in [false, true]) {
      final chat = AssistantConversation();
      chat.messages.add(AssistantMessage.response({
        'status': 'answered',
        'claims': [
          {
            'text': 'Сведения из документа.',
            'evidence': [
              {'source_id': 'S1', 'quote': 'Синтетическая цитата.'}
            ]
          }
        ],
        'sources': [
          {
            'source_id': 'S1',
            'document_id': 'a' * 64,
            'title': 'Документ со ссылкой',
            'page': 1,
            if (linked) 'source_url': 'https://www.vspu.ru/document/3816'
          },
          {
            'source_id': 'S2',
            'document_id': 'b' * 64,
            'title': 'Документ без ссылки',
            'page': 2
          },
          {
            'source_id': 'S3',
            'document_id': 'c' * 64,
            'title': 'Недоверенная ссылка',
            'page': 3,
            'source_url': 'https://evil.test/'
          },
        ]
      }));
      await tester.pumpWidget(MaterialApp(
          theme: buildTheme(Brightness.dark),
          locale: const Locale('ru'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: AssistantScreen(conversation: chat, group: 'TEST-101')));
      await tester.pumpAndSettle();
      expect(find.text('${l10n.aiSources} · 3'), findsOneWidget);
      await tester.tap(find.text('${l10n.aiSources} · 3'));
      await tester.pumpAndSettle();
      expect(find.text('Документ без ссылки'), findsOneWidget);
      expect(find.text('Недоверенная ссылка'), findsOneWidget);
      expect(
          find.text(l10n.aiOpenSource), linked ? findsOneWidget : findsNothing);
      await tester.pumpWidget(const SizedBox());
      chat.dispose();
    }
  });
  test('Display text hides citation identifiers while evidence stays internal',
      () {
    expect(assistantDisplayText('Условия обучения. [S1] [S2]'),
        'Условия обучения.');
    expect(assistantDisplayText('Стоимость [S1, S3] указана в документе.'),
        'Стоимость указана в документе.');
    expect(assistantDisplayText('Группа ИЯ-АВБ-111, аудитория 101.'),
        'Группа ИЯ-АВБ-111, аудитория 101.');
    expect(isAssistantAppRequest('Покажи последнюю новость'), true);
    expect(isAssistantAppRequest('Новости за 21 октября 2026'), true);
    expect(isAssistantAppRequest('Где можно заказать справку?'), true);
    expect(isAssistantAppRequest('Как получить социальную стипендию?'), false);
    expect(isAssistantAppRequest('Какие справки нужны для стипендии?'), false);
  });
  testWidgets(
      'News and request actions work without external consent and open on tap',
      (tester) async {
    var opened = false;
    final chat = AssistantConversation(
        token: () async => 'unio_synthetic',
        client: MockClient((request) async {
          final body = jsonDecode(request.body) as Map;
          expect(body['allow_external'], false);
          final news = (body['question'] as String).contains('новост');
          return http.Response(
              jsonEncode(news
                  ? {
                      'status': 'news',
                      'items': [
                        {
                          'id': 42,
                          'title': 'Новость университета',
                          'content': 'Текст из базы новостей.',
                          'description': 'Описание',
                          'image_url': '',
                          'source_url': '',
                          'published_at': '2026-10-26T12:00:00+03:00'
                        }
                      ],
                      'has_more': false
                    }
                  : {'status': 'requests_help', 'action': 'open_requests'}),
              200,
              headers: {'content-type': 'application/json; charset=utf-8'});
        }));
    await tester.pumpWidget(MaterialApp(
        theme: buildTheme(Brightness.dark),
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: AssistantScreen(
            conversation: chat,
            group: 'TEST-101',
            onOpenRequests: () => opened = true)));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Покажи последнюю новость');
    await tester.pump();
    await tester.tap(find.byTooltip(l10n.aiSend));
    await tester.pumpAndSettle();
    expect(find.text(l10n.aiPrivacyTitle), findsNothing);
    expect(find.text('Новость университета'), findsOneWidget);
    expect(find.text('Текст из базы новостей.'), findsOneWidget);
    await tester.tap(find.text(l10n.aiReadNews));
    await tester.pumpAndSettle();
    expect(find.text('Новость университета'), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byType(TextField), 'Где можно заказать справку?');
    await tester.pump();
    await tester.tap(find.byTooltip(l10n.aiSend));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text(l10n.uiCertificatesAndApplications));
    await tester.tap(find.text(l10n.uiCertificatesAndApplications));
    expect(opened, true);
    expect(find.text(l10n.aiPrivacyTitle), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    chat.dispose();
  });
  testWidgets('Compact AI icon has an accessible 48px target and settles',
      (tester) async {
    var opened = false;
    await tester.pumpWidget(MaterialApp(
        theme: buildTheme(Brightness.dark),
        home: Scaffold(
            body: AssistantEntryButton(onPressed: () => opened = true))));
    await tester.pumpAndSettle();
    expect(find.text('UNIO AI'), findsNothing);
    final size = tester.getSize(find.byType(IconButton));
    expect(size.width, greaterThanOrEqualTo(48));
    expect(size.height, greaterThanOrEqualTo(48));
    expect(find.byType(UnioAiMark), findsOneWidget);
    expect(tester.getSize(find.byType(UnioAiMark)), const Size(24, 24));
    expect(
        tester
            .widget<IconButton>(find.byType(IconButton))
            .style!
            .backgroundColor!
            .resolve({}),
        Colors.transparent);
    await tester.tap(find.byTooltip('UNIO AI'));
    expect(opened, true);
    expect(tester.takeException(), isNull);
  });
  test('Short follow-up keeps the document question as bounded context',
      () async {
    final payloads = <Map>[];
    final chat = AssistantConversation(
        token: () async => 'unio_synthetic',
        client: MockClient((request) async {
          payloads.add(jsonDecode(request.body) as Map);
          return http.Response(
              '{"status":"answered","claims":[],"sources":[]}', 200);
        }));
    await chat.send('доп образование', 'TEST-101');
    await chat.send('расскажи подробнее', 'TEST-101');
    expect(payloads.last['context_question'], 'доп образование');
    await chat.send('а сколько стоит?', 'TEST-101');
    expect(payloads.last['context_question'], 'доп образование');
    chat.dispose();
  });
  test(
      'SSE preserves verified blocks and marks incomplete replies as interrupted',
      () async {
    final events = StreamController<List<int>>();
    final chat = AssistantConversation(
        token: () async => 'unio_synthetic',
        client: _StreamClient(events.stream));
    final future = chat.send('Как получить стипендию?', 'TEST-101');
    await Future<void>.delayed(Duration.zero);
    events.add(utf8.encode('event: status\ndata: {"status":"writing"}\n\n'));
    events.add(utf8.encode(
        'event: partial\ndata: {"status":"answered","claims":[{"text":"Проверенный блок","evidence":[]}],"sources":[]}\n\n'));
    await Future<void>.delayed(Duration.zero);
    expect(chat.stage, 'writing');
    expect(chat.busy, true);
    expect(chat.messages.last.response?['status'], 'answered');
    events
        .add(utf8.encode('event: result\ndata: {"status":"unavailable"}\n\n'));
    await future;
    expect(chat.messages.length, 2);
    expect(chat.messages.last.response?['status'], 'answered');
    expect(chat.messages.last.delivery, 'interrupted');
    await events.close();
    chat.dispose();
  });
  test('Only the bounded question and selected public group leave the client',
      () async {
    final requests = <Map>[];
    final chat = AssistantConversation(
        token: () async => 'unio_synthetic',
        client: MockClient((request) async {
          expect(request.headers['X-Unio-Token'], 'unio_synthetic');
          requests.add(jsonDecode(request.body) as Map);
          return http.Response('{"status":"insufficient"}', 200);
        }));
    await chat.send('Как получить стипендию?', 'TEST-101');
    expect(requests.single.keys.toSet(), {
      'question',
      'group',
      'language',
      'allow_external',
      'context_question',
      'stream'
    });
    expect(requests.single['allow_external'], false);
    expect(requests.single['context_question'], '');
    expect(chat.messages.length, 2);
    chat.clear();
    expect(chat.messages, isEmpty);
    expect(chat.allowExternal, false);
    chat.dispose();
  });
  test('Duplicate send is blocked and logout disposal ignores late response',
      () async {
    final pending = Completer<http.Response>();
    var count = 0;
    final chat = AssistantConversation(
        token: () async => 'unio_synthetic',
        client: MockClient((_) {
          count++;
          return pending.future;
        }));
    final first = chat.send('Расписание завтра', 'TEST-101');
    await Future<void>.delayed(Duration.zero);
    await chat.send('Расписание завтра', 'TEST-101');
    expect(count, 1);
    chat.dispose();
    pending.complete(http.Response('{"status":"insufficient"}', 200));
    await first;
    expect(chat.messages, isEmpty);
  });
  test('Invalid network payload maps to a safe error', () async {
    final chat = AssistantConversation(
        token: () async => 'unio_synthetic',
        client:
            MockClient((_) async => http.Response('<html>error</html>', 502)));
    await chat.send('Расписание завтра', 'TEST-101');
    expect(chat.messages.last.response?['status'], 'unavailable');
    chat.dispose();
  });
  for (final width in [320.0, 430.0]) {
    testWidgets('Chat, permission sheet and reply fit at width $width',
        (tester) async {
      tester.view.physicalSize = Size(width, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var calls = 0;
      final chat = AssistantConversation(
          token: () async => 'unio_synthetic',
          client: MockClient((request) async {
            calls++;
            expect(jsonDecode(request.body)['allow_external'], true);
            return http.Response(
                jsonEncode({
                  'status': 'answered',
                  'claims': [
                    {
                      'text': 'Проверь условия в документе.',
                      'evidence': [
                        {
                          'source_id': 'S1',
                          'quote': 'Синтетическая цитата из документа.'
                        }
                      ]
                    }
                  ],
                  'sources': [
                    {
                      'source_id': 'S1',
                      'document_id': 'a' * 64,
                      'title':
                          'Положение о стипендиальном обеспечении и материальной поддержке',
                      'page': 13,
                      'locator': 'PDF page 13'
                    }
                  ]
                }),
                200,
                headers: {'content-type': 'application/json; charset=utf-8'});
          }));
      await tester.pumpWidget(MaterialApp(
          theme: buildTheme(Brightness.dark),
          locale: const Locale('ru'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: AssistantScreen(conversation: chat, group: 'TEST-101')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.enterText(find.byType(TextField), 'Как получить стипендию?');
      await tester.pump();
      await tester.tap(find.byTooltip(l10n.aiSend));
      await tester.pumpAndSettle();
      expect(calls, 0);
      expect(find.text(l10n.aiPrivacyTitle), findsOneWidget);
      expect(find.textContaining('DeepSeek'), findsNothing);
      expect(find.text(l10n.aiReferenceNotice), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text(l10n.aiAllow));
      await tester.pumpAndSettle();
      expect(calls, 1);
      expect(
          find.textContaining('Проверь условия в документе.'), findsOneWidget);
      expect(find.textContaining('[S1]'), findsNothing);
      expect(find.text(l10n.aiReferenceNotice), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      chat.dispose();
    });
  }
}

class _StreamClient extends http.BaseClient {
  final Stream<List<int>> events;
  _StreamClient(this.events);
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async =>
      http.StreamedResponse(events, 200,
          headers: {'content-type': 'text/event-stream'});
}
