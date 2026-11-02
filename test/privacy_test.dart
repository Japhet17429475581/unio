import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:unio_app/services/analytics_service.dart';
import 'package:unio_app/services/legal_service.dart';
import 'package:unio_app/services/privacy_jobs_service.dart';
import 'package:unio_app/services/privacy_service.dart';
import 'package:unio_app/services/secure_storage_service.dart';
import 'package:unio_app/services/retention_service.dart';
import 'package:unio_app/screens/legal_documents_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('privacy-test-analytics');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final calls = <MethodCall>[];
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
    calls.clear();
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      if (call.method == 'setConsent') return call.arguments['accepted'];
      return true;
    });
  });
  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test('No native init/events before voluntary consent or after revocation',
      () async {
    final service = AnalyticsService(enabled: true, channel: channel);
    await service.track(AnalyticsEvent.onboardingStarted);
    expect(calls, isEmpty);
    await service.setConsent(true, version: 'test');
    await service.track(AnalyticsEvent.screenView);
    expect(calls.where((e) => e.method == 'trackEvent'), hasLength(1));
    await service.setConsent(false);
    await service.track(AnalyticsEvent.screenView);
    expect(calls.where((e) => e.method == 'trackEvent'), hasLength(1));
  });

  test('Revocation invalidates events waiting for native initialization',
      () async {
    final ready = Completer<bool>();
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      if (call.method == 'initialize') return ready.future;
      return call.arguments['accepted'];
    });
    final service = AnalyticsService(enabled: true, channel: channel);
    await service.setConsent(true, version: 'test');
    final event = service.track(AnalyticsEvent.noteSaved);
    await Future<void>.delayed(Duration.zero);
    await service.setConsent(false);
    ready.complete(true);
    await event;
    expect(calls.where((e) => e.method == 'trackEvent'), isEmpty);
  });

  test(
      'Separate evidence includes exact document hashes, versions and UTC time',
      () async {
    final service = LegalService();
    expect(await service.coreAccepted(), false);
    await service.acceptCore();
    expect(await service.coreAccepted(), true);
    expect(await service.latest('analytics'), null);
    final docs = await service.documents();
    final receipts = await service.receipts();
    expect(receipts.map((r) => r['document']), ['terms', 'personal_data']);
    for (final receipt in receipts) {
      expect(receipt['sha256'], docs[receipt['document']]!.sha256);
      expect(receipt['version'], docs[receipt['document']]!.version);
      expect(DateTime.parse(receipt['occurred_at']).isUtc, true);
    }
    receipts.last['version'] = 'old';
    await legalStorage.write(key: legalJournalKey, value: jsonEncode(receipts));
    expect(await service.coreAccepted(), false);
  });

  test(
      'Deletion retries survive restart and never confuse server failure with success',
      () async {
    final first =
        PrivacyJobs(client: MockClient((_) async => http.Response('', 503)));
    await first.enqueue('unio_test', deleteAccount: false);
    await first.enqueue('unio_test', deleteAccount: true);
    expect(await first.retry(), false);
    expect(await legalStorage.read(key: privacyJobsKey), contains('unio_test'));
    final second = PrivacyJobs(client: MockClient((request) async {
      expect(request.method, 'DELETE');
      expect(request.url.path, '/api/v1/auth/account');
      expect(request.headers['X-Unio-Token'], 'unio_test');
      expect(request.body, isEmpty);
      return http.Response('', 204);
    }));
    expect(await second.retry(), true);
    expect(
        jsonDecode((await legalStorage.read(key: privacyJobsKey))!), isEmpty);
  });

  test('Logout removes credentials despite notification plugin failures',
      () async {
    await saveSession(
        accountToken: 'unio_test',
        groupCode: 'TEST',
        isPortalMode: true,
        portalLogin: 'synthetic',
        portalPassword: 'synthetic');
    await saveTeacherSession(const TeacherPortalSession(
        fio: 'Test Teacher', login: 'synthetic', password: 'synthetic'));
    // Notifications intentionally have no native implementation in this test.
    try {
      await endPrivateSession(token: 'unio_test');
    } catch (_) {}
    expect(await loadSession(), null);
    expect(await loadTeacherSession(), null);
    final stored = await legalStorage.readAll();
    expect(stored.containsKey('portal_password'), false);
    expect(stored.containsKey('portal_login'), false);
    expect(stored.containsKey('teacher_portal_session_v1'), false);
    expect(stored[privacyJobsKey], contains('unio_test'));
  });

  test('Recovery tombstone prevents session restoration before cleanup',
      () async {
    await saveSession(
        accountToken: 'unio_test', groupCode: 'TEST', isPortalMode: false);
    await legalStorage.write(
        key: cleanupPendingKey,
        value: jsonEncode({'token': 'unio_test', 'delete': true}));
    expect(await loadSession(), null);
  });

  test('Deletion clears private files, caches and secure data while retaining the retry job', () async {
    final root = await Directory('build').createTemp('privacy-cleanup-');
    final documents = await Directory('${root.path}/documents').create();
    final temporary = await Directory('${root.path}/temporary').create();
    final notes = await Directory('${documents.path}/unio_lesson_notes').create();
    await File('${notes.path}/synthetic_note').writeAsString('synthetic');
    await File('${temporary.path}/synthetic_attachment').writeAsString('synthetic');
    const paths = MethodChannel('plugins.flutter.io/path_provider');
    messenger.setMockMethodCallHandler(paths, (call) async => call.method == 'getTemporaryDirectory' ? temporary.absolute.path : documents.absolute.path);
    addTearDown(() async {
      messenger.setMockMethodCallHandler(paths, null);
      await root.delete(recursive: true);
    });
    SharedPreferences.setMockInitialValues({'schedule_cache_TEST': '{}', 'dark_mode': true});
    await saveSession(accountToken: 'unio_test', groupCode: 'TEST', isPortalMode: true,
      portalLogin: 'synthetic', portalPassword: 'synthetic');
    await legalStorage.write(key: 'request_status_synthetic', value: '{}');
    await legalStorage.write(key: 'assistant_history_v1_synthetic_index', value: '{"version":1}');
    await legalStorage.write(key: 'assistant_history_v1_synthetic_chat_message', value: '{"content":"private grade"}');
    await legal.acceptCore();
    // Notification failures still must not block file/storage destruction.
    try { await endPrivateSession(token: 'unio_test', deleteData: true); } catch (_) {}
    expect(await notes.exists(), false);
    expect(await temporary.list().isEmpty, true);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getKeys(), {'dark_mode'});
    final secure = await legalStorage.readAll();
    expect(secure.keys.toSet().difference({privacyJobsKey, cleanupPendingKey, 'session_closed_v1'}), isEmpty);
    expect(secure[privacyJobsKey], contains('delete'));
  });

  test('Cache retention expires old entries but preserves notes and theme',
      () async {
    final now = DateTime.utc(2026, 10, 16);
    SharedPreferences.setMockInitialValues({
      'schedule_cache_TEST': '{}',
      '${cacheStampPrefix}schedule_cache_TEST':
          now.subtract(const Duration(days: 8)).millisecondsSinceEpoch,
      'dark_mode': true,
    });
    await pruneLocalData(now: now);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.containsKey('schedule_cache_TEST'), false);
    expect(prefs.getBool('dark_mode'), true);
  });

  testWidgets(
      'Acceptance screen has distinct unchecked choices; analytics is optional',
      (tester) async {
    await tester.runAsync(() => legal.documents());
    await tester.pumpWidget(
        const MaterialApp(home: LegalDocumentsScreen(requireAcceptance: true)));
    await tester
        .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.byKey(const Key('accept-terms')), 200,
        scrollable: find.byType(Scrollable).first);
    expect(
        tester
            .widget<CheckboxListTile>(find.byType(CheckboxListTile).first)
            .value,
        false);
    expect(
        tester
            .widget<CheckboxListTile>(find.byType(CheckboxListTile).last)
            .value,
        false);
    await tester.scrollUntilVisible(find.byType(SwitchListTile), 200,
        scrollable: find.byType(Scrollable).first);
    expect(tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
        false);
    expect(tester.takeException(), null);
  });
}
