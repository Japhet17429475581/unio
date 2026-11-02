import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unio_app/config/brand.dart';
import 'package:unio_app/l10n/app_localizations.dart';
import 'package:unio_app/screens/assistant_screen.dart';
import 'package:unio_app/screens/home_screen.dart';
import 'package:unio_app/screens/university_tab.dart';
import 'package:unio_app/services/assistant_history.dart';
import 'package:unio_app/services/assistant_service.dart';
import 'package:unio_app/services/locale_service.dart';
import 'package:unio_app/services/local_write_guard.dart';
import 'package:unio_app/services/secure_storage_service.dart';

class MemoryChatStorage implements ChatStorage {
  final values = <String, String>{};
  bool fail = false;
  bool failReads = false;
  @override
  Future<String?> read(String key) async {
    if (failReads) throw StateError('storage_unavailable');
    return values[key];
  }

  @override
  Future<void> write(String key, String value) async {
    if (fail) throw StateError('quota');
    values[key] = value;
  }

  @override
  Future<void> delete(String key) async => values.remove(key);
  @override
  Future<List<String>> keys(String prefix) async =>
      values.keys.where((key) => key.startsWith(prefix)).toList();
}

class ControlledChatClient extends http.BaseClient {
  final requests = <http.BaseRequest>[];
  final replies = <Completer<http.StreamedResponse>>[];
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    requests.add(request);
    final reply = Completer<http.StreamedResponse>();
    replies.add(reply);
    return reply.future;
  }
}

Map<String, dynamic> answer(String text) => {
      'status': 'answered',
      'claims': [
        {
          'text': text,
          'evidence': [
            {'source_id': 'S1', 'quote': 'Synthetic university source text.'}
          ]
        }
      ],
      'sources': [
        {
          'source_id': 'S1',
          'title': 'University document',
          'document_id': 'a' * 64,
          'source_url': 'https://www.vspu.ru/document/3816'
        }
      ],
    };

AssistantConversation conversation(MemoryChatStorage storage,
        {String owner = 'owner-a', http.Client? client}) =>
    AssistantConversation(
        history: AssistantHistory(owner, storage: storage),
        token: () async => 'unio_synthetic',
        client: client ??
            MockClient((r) async => http.Response(
                jsonEncode(answer('Answer ${jsonDecode(r.body)['question']}')),
                200,
                headers: {'content-type': 'application/json; charset=utf-8'})))
      ..allowExternal = true;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
    allowPrivateWrites();
    await appLocale.load();
  });

  test('Messages, sources, feedback, draft and bounded context survive restart',
      () async {
    final storage = MemoryChatStorage();
    final first = conversation(storage);
    await first.initializeHistory();
    await first.send('Условия социальной стипендии', 'TEST');
    first.rate(first.messages.last, 1);
    first.setDraft('Продолжить вопрос');
    await first.flushHistory();
    final id = first.session.id;
    first.dispose();
    final requests = <Map>[];
    final second = conversation(storage, client: MockClient((r) async {
      requests.add(jsonDecode(r.body) as Map);
      return http.Response(jsonEncode(answer('Reply')), 200);
    }));
    await second.initializeHistory();
    expect(second.session.id, id);
    expect(second.messages.length, 2);
    expect(second.messages.last.feedback, 1);
    expect(second.messages.last.response!['sources'][0]['source_url'],
        contains('vspu.ru'));
    expect(second.draft, 'Продолжить вопрос');
    await second.send('А какие документы нужны?', 'TEST');
    expect(requests.single['context_question'], 'Условия социальной стипендии');
    second.dispose();
  });

  test('Chat switching isolates contexts, metadata and drafts', () async {
    final storage = MemoryChatStorage();
    final requests = <Map>[];
    final chat = conversation(storage, client: MockClient((r) async {
      requests.add(jsonDecode(r.body) as Map);
      return http.Response(jsonEncode(answer('Reply')), 200);
    }));
    await chat.initializeHistory();
    await chat.send('Общежитие университета', 'TEST');
    chat.setDraft('Draft A');
    await chat.flushHistory();
    final a = chat.sessions.first;
    await chat.newChat();
    await chat.send('Дополнительное образование', 'TEST');
    expect(requests.last['context_question'], '');
    chat.setDraft('Draft B');
    await chat.flushHistory();
    await chat.selectChat(a);
    expect(chat.draft, 'Draft A');
    expect(chat.messages.first.question, 'Общежитие университета');
    await chat.send('А какие документы нужны?', 'TEST');
    expect(requests.last['context_question'], 'Общежитие университета');
    expect(chat.sessions.length, 2);
    chat.dispose();
  });

  test(
      'Late network result cannot enter another chat or resurrect a deleted chat',
      () async {
    final storage = MemoryChatStorage();
    final result = Completer<http.Response>();
    final chat =
        conversation(storage, client: MockClient((_) => result.future));
    await chat.initializeHistory();
    final pending = chat.send('Первый вопрос', 'TEST');
    await Future<void>.delayed(Duration.zero);
    await chat.flushHistory();
    final old = chat.sessions.first;
    await chat.newChat();
    await chat.deleteChat(old);
    result.complete(http.Response(jsonEncode(answer('Late answer')), 200));
    await pending;
    expect(chat.messages, isEmpty);
    expect(chat.sessions, isEmpty);
    expect(storage.values.keys.where((k) => k.contains(old.id)), isEmpty);
    chat.dispose();
  });

  test('A late timeout in the old chat cannot abort a new chat request',
      () async {
    final client = ControlledChatClient();
    final chat = conversation(MemoryChatStorage(), client: client);
    await chat.initializeHistory();
    final oldSend = chat.send('Old question', 'TEST');
    await Future<void>.delayed(Duration.zero);
    await chat.newChat();
    final newSend = chat.send('New question', 'TEST');
    await Future<void>.delayed(Duration.zero);
    var newAborted = false;
    (client.requests.last as http.Abortable)
        .abortTrigger!
        .then((_) => newAborted = true);
    client.replies.first
        .completeError(TimeoutException('Old transport timeout'));
    await oldSend;
    await Future<void>.delayed(Duration.zero);
    expect(newAborted, false);
    client.replies.last.complete(http.StreamedResponse(
        Stream.value(utf8.encode(jsonEncode(answer('New reply')))), 200,
        headers: {'content-type': 'application/json'}));
    await newSend;
    expect(chat.messages.first.question, 'New question');
    expect(chat.messages.last.text, 'New reply');
    chat.dispose();
  });

  test('Interrupted persisted streaming response is never marked complete',
      () async {
    final storage = MemoryChatStorage();
    final history = AssistantHistory('a', storage: storage);
    final session = ChatSession(title: 'Streaming');
    final message = AssistantMessage.response(answer('Verified partial block'))
      ..delivery = 'streaming';
    await history.save(
        session, [AssistantMessage.question('Question'), message],
        draft: '', context: '', gradesContext: false);
    final restored = AssistantHistory('a', storage: storage);
    await restored.open();
    final messages = await restored.messages(restored.sessions.single);
    expect(messages.last.delivery, 'interrupted');
    expect(messages.last.text, 'Verified partial block');
  });

  test(
      'Closing before the first answer block restores an interruption with retry',
      () {
    final waiting = AssistantMessage.response({'status': 'pending'})
      ..delivery = 'streaming';
    final restored = AssistantMessage.fromJson(waiting.toJson());
    expect(restored.delivery, 'interrupted');
    expect(restored.response!['status'], 'interrupted');
  });

  test('Per-owner history, rename, deep search and complete deletion',
      () async {
    final storage = MemoryChatStorage();
    final a = conversation(storage);
    await a.initializeHistory();
    await a.send('Вопрос', 'TEST');
    await a.renameChat(a.session, 'Renamed');
    await a.flushHistory();
    expect((await a.history!.search('Answer')).length, 1);
    expect((await a.history!.search('Renamed')).length, 1);
    expect(await a.history!.search('absent'), isEmpty);
    final b = conversation(storage, owner: 'owner-b');
    await b.initializeHistory();
    expect(b.messages, isEmpty);
    expect(b.sessions, isEmpty);
    await a.clearHistory();
    final restored = AssistantHistory('owner-a', storage: storage);
    await restored.open();
    expect(restored.sessions, isEmpty);
    expect(storage.values.keys.where((k) => !k.endsWith('_index')), isEmpty);
    a.dispose();
    b.dispose();
  });

  test(
      'Structured payloads and future-version text fallback survive serialization',
      () {
    for (final data in [
      {
        'status': 'schedule',
        'date': '2026-10-28',
        'lessons': [
          {'subject': 'Math', 'start': '09:40'}
        ]
      },
      {
        'status': 'grades',
        'subjects': [
          {
            'subject': 'Math',
            'first_cut': {'score': 0, 'hours': 2},
            'exam': {'points': 91}
          }
        ]
      },
      {
        'status': 'news',
        'items': [
          {
            'id': 3,
            'title': 'News',
            'content': 'Body',
            'image_url': 'https://www.vspu.ru/photo.jpg'
          }
        ]
      },
      {'status': 'requests_help', 'action': 'open_requests'},
    ]) {
      final message = AssistantMessage.response(data);
      final stored = message.toJson();
      expect(AssistantMessage.fromJson(stored).response, data);
      stored['payloadVersion'] = 99;
      final fallback = AssistantMessage.fromJson(stored);
      expect(fallback.response!['status'], 'legacy');
      expect(fallback.response!['fallback_text'], message.text);
    }
    final malformed =
        AssistantMessage.response(answer('Safe fallback')).toJson();
    malformed['payload'] = {'status': 'schedule', 'lessons': 'bad'};
    expect(AssistantMessage.fromJson(malformed).response!['status'], 'legacy');
  });

  test('Credentials are removed from text, drafts, titles and nested payloads',
      () async {
    final storage = MemoryChatStorage();
    final history = AssistantHistory('a', storage: storage);
    final session = ChatSession(title: 'unio_secretvalue');
    await history.save(
        session,
        [
          AssistantMessage.question('password: secretvalue'),
          AssistantMessage.response({
            'status': 'answered',
            'claims': [
              {'text': 'sk-secretvalue', 'token': 'secretvalue'}
            ],
            'password': 'secretvalue'
          })
        ],
        draft: 'Bearer secretvalue',
        context: 'token=secretvalue',
        gradesContext: false);
    expect(storage.values.values.join(), isNot(contains('secretvalue')));
  });

  test(
      'Retry replaces answer without changing original question or message IDs',
      () async {
    final chat = conversation(MemoryChatStorage());
    await chat.initializeHistory();
    await chat.send('Вопрос', 'TEST');
    final ids = chat.messages.map((m) => m.id).toList();
    await chat.retry(chat.messages.last, 'TEST');
    expect(chat.messages.map((m) => m.id).toList(), ids);
    expect(chat.messages.first.question, 'Вопрос');
    chat.dispose();
  });

  test(
      'Quota failure keeps readable RAM messages and signals persistence failure',
      () async {
    final storage = MemoryChatStorage()..fail = true;
    final chat = conversation(storage);
    await chat.initializeHistory();
    await chat.send('Вопрос', 'TEST');
    await chat.flushHistory();
    expect(chat.historyFailed, true);
    expect(chat.messages.last.response!['status'], 'answered');
    chat.dispose();
  });

  test('Storage failure cannot discard unsaved messages through chat switching',
      () async {
    final storage = MemoryChatStorage();
    final chat = conversation(storage);
    await chat.initializeHistory();
    await chat.send('Saved question', 'TEST');
    await chat.flushHistory();
    final saved = chat.sessions.first;
    await chat.newChat();
    final unsavedId = chat.session.id;
    storage.fail = true;
    await chat.send('Unsaved question', 'TEST');
    await chat.flushHistory();
    expect(chat.historyFailed, true);
    await chat.selectChat(saved);
    await chat.newChat();
    chat.clear();
    expect(chat.session.id, unsavedId);
    expect(chat.messages.first.question, 'Unsaved question');
    storage.fail = false;
    await chat.retryPersistence();
    expect(chat.historyFailed, false);
    await chat.selectChat(saved);
    await chat.selectChat(chat.sessions.firstWhere((s) => s.id == unsavedId));
    expect(chat.messages.first.question, 'Unsaved question');
    chat.dispose();
  });

  test('Pagination preserves older messages when appending new data', () async {
    final storage = MemoryChatStorage();
    final history = AssistantHistory('owner-a', storage: storage);
    final session = ChatSession(title: 'Long chat');
    final messages =
        List.generate(140, (i) => AssistantMessage.question('Message $i'));
    await history.save(session, messages,
        draft: '', context: '', gradesContext: false);
    final chat = conversation(storage);
    await chat.initializeHistory();
    expect(chat.messages.length, 60);
    expect(chat.olderMessages, 80);
    await chat.send('New question', 'TEST');
    await chat.flushHistory();
    await chat.loadOlder();
    await chat.loadOlder();
    expect(chat.messages.length, 142);
    expect(chat.messages.first.question, 'Message 0');
    chat.dispose();
  });

  test(
      'Failed history pagination notifies the UI without losing loaded messages',
      () async {
    final storage = MemoryChatStorage();
    final history = AssistantHistory('owner-a', storage: storage);
    final session = ChatSession(title: 'Long chat');
    await history.save(session,
        List.generate(65, (i) => AssistantMessage.question('Message $i')),
        draft: '', context: '', gradesContext: false);
    final chat = conversation(storage);
    await chat.initializeHistory();
    var notifications = 0;
    chat.addListener(() => notifications++);
    storage.failReads = true;
    await chat.loadOlder();
    expect(chat.historyFailed, true);
    expect(chat.messages, hasLength(60));
    expect(chat.olderMessages, 5);
    expect(notifications, 1);
    chat.dispose();
  });

  test('Unknown index is not overwritten even when saving is retried',
      () async {
    final storage = MemoryChatStorage();
    const key = 'assistant_history_v1_owner-a_index';
    storage.values[key] = '{"version":99,"sessions":[]}';
    final chat = conversation(storage);
    await chat.initializeHistory();
    expect(chat.historyFailed, true);
    await chat.send('Question', 'TEST');
    await chat.retryPersistence();
    expect(chat.historyFailed, true);
    expect(storage.values[key], '{"version":99,"sessions":[]}');
    chat.dispose();
  });

  test('Full clear removes unindexed records without affecting another owner',
      () async {
    final storage = MemoryChatStorage();
    final history = AssistantHistory('a', storage: storage);
    storage.values['${history.prefix}_unindexed_chat_message'] = 'orphan';
    storage.values['assistant_history_v1_other_index'] = 'other account';
    await history.clearAll();
    expect(
        storage.values.keys
            .where((key) => key.startsWith('${history.prefix}_')),
        ['${history.prefix}_index']);
    expect(storage.values['assistant_history_v1_other_index'], 'other account');
    expect(history.sessions, isEmpty);
  });

  test('Deletion includes orphan records from interrupted writes', () async {
    final storage = MemoryChatStorage();
    final history = AssistantHistory('a', storage: storage);
    final session = ChatSession(title: 'Chat');
    await history.save(session, [AssistantMessage.question('Question')],
        draft: '', context: '', gradesContext: false);
    storage.values['${history.prefix}_${session.id}_orphan'] = 'orphan';
    await history.delete(session);
    expect(
        storage.values.keys.where((key) => key.contains(session.id)), isEmpty);
  });

  test(
      'Contextual contact and eligibility suggestions retain the original topic',
      () async {
    final calls = <Map>[];
    final chat =
        conversation(MemoryChatStorage(), client: MockClient((r) async {
      calls.add(jsonDecode(r.body) as Map);
      return http.Response(jsonEncode(answer('Answer')), 200);
    }));
    await chat.initializeHistory();
    await chat.send('Условия стипендии', 'TEST');
    await chat.send('Куда обращаться?', 'TEST');
    expect(calls.last['context_question'], 'Условия стипендии');
    await chat.send('Кто имеет право на получение?', 'TEST');
    expect(calls.last['context_question'], 'Условия стипендии');
    chat.dispose();
  });

  test(
      'Portal and guest namespaces never store raw credentials and guests differ',
      () async {
    await saveSession(
        accountToken: 'unio_guest_a', groupCode: 'A', isPortalMode: false);
    final a = await currentChatOwner();
    await saveSession(
        accountToken: 'unio_guest_b', groupCode: 'A', isPortalMode: false);
    expect(await currentChatOwner(), isNot(a));
    await saveSession(
        accountToken: 'unio_portal_a',
        groupCode: 'A',
        isPortalMode: true,
        portalLogin: 'student',
        portalPassword: 'secret');
    final p = await currentChatOwner();
    await saveSession(
        accountToken: 'unio_portal_b',
        groupCode: 'B',
        isPortalMode: true,
        portalLogin: 'student',
        portalPassword: 'changed');
    expect(await currentChatOwner(), p);
    expect(p, matches(RegExp(r'^[a-f0-9]{64}$')));
  });

  test(
      'Ending session cancels generation, closes history and drops private RAM data',
      () async {
    final storage = MemoryChatStorage();
    final pending = Completer<http.Response>();
    final chat =
        conversation(storage, client: MockClient((_) => pending.future));
    await chat.initializeHistory();
    final work = chat.send('Вопрос', 'TEST');
    await Future<void>.delayed(Duration.zero);
    await AssistantConversation.endSessions();
    pending.complete(http.Response(jsonEncode(answer('Late')), 200));
    await work;
    expect(chat.messages, isEmpty);
    expect(chat.allowExternal, false);
    expect(chat.history!.closed, true);
    chat.dispose();
  });

  for (final brightness in [Brightness.light, Brightness.dark]) {
    for (final width in [320.0, 1100.0]) {
      testWidgets(
          'History, source titles and chat actions fit $brightness $width at large text',
          (tester) async {
        tester.view.physicalSize = Size(width, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final chat = conversation(MemoryChatStorage());
        await chat.initializeHistory();
        await chat.send('Стипендия', 'TEST');
        await tester.pumpWidget(MaterialApp(
            theme: buildTheme(brightness),
            locale: const Locale('ru'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            builder: (c, child) => MediaQuery(
                data: MediaQuery.of(c).copyWith(
                    textScaler: const TextScaler.linear(1.5),
                    disableAnimations: true),
                child: child!),
            home: AssistantScreen(conversation: chat, group: 'TEST')));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.tap(find.byTooltip(l10n.aiHistory));
        await tester.pumpAndSettle();
        expect(find.text(l10n.aiHistoryLocal), findsWidgets);
        expect(find.text('Стипендия'), findsWidgets);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        chat.dispose();
      });
    }
  }

  testWidgets(
      'Requests navigation removes the guest chat before a portal upgrade',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
        theme: buildTheme(Brightness.dark),
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: HomeScreen(
            group: 'TEST',
            isPortalMode: false,
            onLogout: () {},
            onUpgradeToPortal: (_, __) async {},
            darkMode: true,
            onDarkModeChanged: (_) {})));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('UNIO AI').first);
    await tester.pumpAndSettle();
    final screen = tester.widget<AssistantScreen>(find.byType(AssistantScreen));
    screen.conversation.messages.add(AssistantMessage.response(
        {'status': 'requests_help', 'action': 'open_requests'}));
    screen.conversation.notifyListeners();
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.uiCertificatesAndApplications));
    await tester.pumpAndSettle();
    expect(find.byType(RequestsEntryScreen), findsOneWidget);
    expect(find.byType(AssistantScreen, skipOffstage: false), findsNothing);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(AssistantScreen, skipOffstage: false), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
      'Multiline composer fits a short screen with keyboard and 200 percent text',
      (tester) async {
    tester.view.physicalSize = const Size(320, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final chat = conversation(MemoryChatStorage());
    await chat.initializeHistory();
    await tester.pumpWidget(MaterialApp(
        theme: buildTheme(Brightness.dark),
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (c, child) => MediaQuery(
            data: MediaQuery.of(c).copyWith(
                textScaler: const TextScaler.linear(2),
                viewInsets: const EdgeInsets.only(bottom: 300)),
            child: child!),
        home: AssistantScreen(conversation: chat, group: 'TEST')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField),
        'First line\nSecond line\nThird line\nFourth line\nFifth line');
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(tester.widget<TextField>(find.byType(TextField)).maxLines, 1);
    chat.historyFailed = true;
    chat.notifyListeners();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    chat.dispose();
  });

  testWidgets(
      'Copy and feedback stay local; retry preserves the original message pair',
      (tester) async {
    String? copied;
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData')
        copied = call.arguments['text'] as String;
      return null;
    });
    addTearDown(() =>
        messenger.setMockMethodCallHandler(SystemChannels.platform, null));
    var calls = 0;
    final chat =
        conversation(MemoryChatStorage(), client: MockClient((_) async {
      calls++;
      return http.Response(jsonEncode(answer('Verified answer. [S1]')), 200);
    }));
    await chat.initializeHistory();
    await chat.send('Question', 'TEST');
    final ids = chat.messages.map((m) => m.id).toList();
    await tester.pumpWidget(MaterialApp(
        theme: buildTheme(Brightness.light),
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: AssistantScreen(conversation: chat, group: 'TEST')));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip(l10n.aiCopy));
    await tester.pumpAndSettle();
    expect(copied, 'Verified answer.');
    await tester.tap(find.byTooltip(l10n.aiHelpful));
    await tester.pumpAndSettle();
    expect(chat.messages.last.feedback, 1);
    expect(calls, 1);
    await tester.tap(find.byTooltip(l10n.aiRetry));
    await tester.pumpAndSettle();
    expect(calls, 2);
    expect(chat.messages.map((m) => m.id).toList(), ids);
    await tester.pumpWidget(const SizedBox());
    chat.dispose();
  });
}
