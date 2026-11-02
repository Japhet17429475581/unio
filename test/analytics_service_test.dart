import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unio_app/services/analytics_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('unio/analytics-test');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final calls = <MethodCall>[];

  setUp(() {
    calls.clear();
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return call.method == 'initialize' ||
              (call.method == 'setConsent' &&
                  call.arguments['accepted'] == true)
          ? true
          : null;
    });
  });
  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test('Concurrent first actions initialize once and send only category values',
      () async {
    final service = AnalyticsService(channel: channel, enabled: true);
    await service.setConsent(true, version: 'test');
    calls.clear();
    await Future.wait([
      service.track(AnalyticsEvent.loginResult,
          role: AnalyticsRole.teacher,
          method: AnalyticsMethod.portal,
          outcome: AnalyticsOutcome.success),
      service.track(AnalyticsEvent.noteSaved, hasPhotos: true),
    ]);
    expect(calls.where((c) => c.method == 'initialize'), hasLength(1));
    expect(calls[1].arguments, {
      'name': 'login_result',
      'params': {
        'role': 'teacher',
        'method': 'portal',
        'outcome': 'success',
      },
    });
    expect(calls[2].arguments, {
      'name': 'note_saved',
      'params': {'has_photos': 'true'},
    });
  });

  test('Disabled builds never call the native SDK', () async {
    final service = AnalyticsService(channel: channel, enabled: false);
    expect(await service.initialize(), isFalse);
    await service.track(AnalyticsEvent.onboardingStarted);
    expect(calls, isEmpty);
  });

  test('Unavailable native initialization does not queue or send user actions',
      () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return false;
    });
    final service = AnalyticsService(channel: channel, enabled: true);
    await service.setConsent(true, version: 'test');
    await service.track(AnalyticsEvent.requestSubmit);
    await service.track(AnalyticsEvent.requestSubmit,
        outcome: AnalyticsOutcome.success);
    expect(calls, hasLength(1));
    expect(calls.single.method, 'setConsent');
  });

  test('SDK failure does not replace a successful business action', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'initialize' || call.method == 'setConsent')
        return true;
      throw PlatformException(code: 'unavailable');
    });
    final service = AnalyticsService(channel: channel, enabled: true);
    await service.setConsent(true, version: 'test');
    await expectLater(
        service.track(AnalyticsEvent.noteSaved,
            outcome: AnalyticsOutcome.success),
        completes);
  });

  test('Missing bridge is harmless on unsupported platforms and old builds',
      () async {
    messenger.setMockMethodCallHandler(channel, null);
    final service = AnalyticsService(channel: channel, enabled: true);
    expect(await service.initialize(), isFalse);
    await expectLater(
        service.track(AnalyticsEvent.screenView,
            screen: AnalyticsScreen.schedule),
        completes);
  });
}
