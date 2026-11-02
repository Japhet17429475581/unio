import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unio_app/config/brand.dart';
import 'package:unio_app/services/home_widget_service.dart';
import 'package:unio_app/widgets/home_widget_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('unio/home_widget');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final calls = <MethodCall>[];
  setUp(() => calls.clear());
  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test('Bridge sends only public selection and requests launcher confirmation',
      () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      if (call.method == 'capabilities') return {'pinSupported': true};
      if (call.method == 'pin') return true;
      return null;
    });
    final service = HomeWidgetService(enabled: true);
    await service.select(value: 'TEST');
    expect(calls.single.arguments.keys.toSet(), {'kind', 'value', 'host'});
    expect(calls.single.arguments['kind'], 'group');
    await service.select(value: 'Test Teacher', teacher: true);
    expect(calls.last.arguments['kind'], 'teacher');
    expect(await service.canPin(), isTrue);
    expect(await service.pin(), isTrue);
    await service.clear();
    expect(calls.last.method, 'clear');
  });

  test(
      'Logout invalidates queued selections; subsequent account is independent',
      () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return null;
    });
    final service = HomeWidgetService(enabled: true);
    final old = service.select(value: 'OLD');
    final logout = service.clear();
    final next = service.select(value: 'NEW');
    await Future.wait([old, logout, next]);
    expect(calls.map((call) => call.method), ['clear', 'select']);
    expect(calls.last.arguments['value'], 'NEW');
  });

  test('Native widget tap opens schedule; unsupported platforms stay inert',
      () async {
    final service = HomeWidgetService(enabled: true);
    var opened = false;
    service.initialize(onOpenSchedule: () => opened = true);
    final reply = Completer<void>();
    await messenger.handlePlatformMessage(
        channel.name,
        const StandardMethodCodec()
            .encodeMethodCall(const MethodCall('openSchedule')),
        (ByteData? _) => reply.complete());
    await reply.future;
    expect(opened, isTrue);
    expect(service.openSchedule.value, 1);
    final disabled = HomeWidgetService(enabled: false);
    await disabled.select(value: 'TEST');
    expect(await disabled.canPin(), isFalse);
    expect(await disabled.pin(), isFalse);
    expect(calls, isEmpty);
    messenger.setMockMethodCallHandler(channel, null);
  });

  for (final supported in [true, false]) {
    testWidgets('Widget preview and pin fallback: $supported', (tester) async {
      messenger.setMockMethodCallHandler(channel, (call) async {
        calls.add(call);
        if (call.method == 'capabilities') return {'pinSupported': supported};
        if (call.method == 'pin') return true;
        return null;
      });
      await tester.pumpWidget(MaterialApp(
          theme: buildTheme(Brightness.dark),
          home: Builder(
              builder: (context) => Scaffold(
                  body: TextButton(
                      onPressed: () =>
                          showHomeWidgetSheet(context, label: 'TEST'),
                      child: const Text('Open'))))));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.text('Расписание под рукой'), findsOneWidget);
      expect(find.text('11:30–13:00'), findsOneWidget);
      if (supported) {
        await tester.ensureVisible(find.text('Добавить на рабочий стол'));
        await tester.tap(find.text('Добавить на рабочий стол'));
        await tester.pumpAndSettle();
        expect(calls.where((call) => call.method == 'pin'), hasLength(1));
        expect(find.textContaining('Подтверди добавление'), findsOneWidget);
      } else {
        expect(find.textContaining('Зажми пустое место'), findsOneWidget);
        expect(calls.where((call) => call.method == 'pin'), isEmpty);
      }
      expect(tester.takeException(), isNull);
    });
  }
}
