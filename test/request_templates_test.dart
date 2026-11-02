import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unio_app/config/brand.dart';
import 'package:unio_app/screens/request_form_screen.dart';
import 'package:unio_app/services/direct_portal_client.dart';
import 'package:unio_app/services/request_templates_service.dart';
import 'package:unio_app/services/requests_service.dart';
import 'support/portal_fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final gssHtml = File('test/fixtures/gss_form.html').readAsStringSync();
  const channel = MethodChannel('unio/document_export');
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({
      'account_token': 'test',
      'is_portal_mode': 'true',
      'portal_login': 'test',
      'portal_password': 'secret',
    });
  });
  tearDown(() {
    DirectPortalClient.testFactory = null;
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test(
      'Supplied GSS form supports category, both attachments and bundled template',
      () {
    final form = parseRequestForm(gssHtml, '101');
    expect(form.hasUnsupportedFields, isFalse);
    expect(form.fields.single.name, 'field_36');
    expect(form.fields.single.options!.length, 11);
    expect(form.fields.single.options!.first.id, '');
    expect(form.attachments.map((a) => a.fieldId), ['1', '37']);
    expect(form.attachments.map((a) => a.required), [true, false]);
    expect(templateForForm(form), RequestTemplate.gss);
    expect(templateForForm(parseRequestForm(incomeFormHtml, '101')),
        RequestTemplate.income);
    expect(templateForForm(parseRequestForm(portalFormHtml, '101')), isNull);
  });

  for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
    for (final saved in [true, false]) {
      test('Bundled DOCX export on $platform returns saved=$saved', () async {
        debugDefaultTargetPlatformOverride = platform;
        final calls = <MethodCall>[];
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return saved;
        });
        for (final template in RequestTemplate.values) {
          expect(await saveRequestTemplate(template), saved);
          expect(calls.last.method, 'saveDocument');
          final args = calls.last.arguments as Map;
          expect(args['name'], template.fileName);
          expect((args['bytes'] as Uint8List).take(4), [80, 75, 3, 4]);
          expect((args['bytes'] as Uint8List).length, greaterThan(10000));
        }
      });
    }
  }

  for (final rejectSecondUpload in [false, true]) {
    test(
        'GSS uploads both documents before submit; rejected=$rejectSecondUpload',
        () async {
      var sent = false;
      final uploads = <String>[];
      DirectPortalClient.testFactory = () => fakePortal((o) {
            if (o.uri.path == '/login')
              return page(
                  o.method == 'GET' ? portalLoginHtml : portalLoggedInHtml);
            if (o.uri.path == '/request/index')
              return page(sent
                  ? portalListHtml.replaceAll(
                      'получение информации', 'На обработке')
                  : portalListHtml);
            if (o.uri.path.endsWith('/upload')) {
              final data = o.data as FormData;
              final id = Map.fromEntries(data.fields)['field_id']!;
              uploads.add(id);
              expect(data.files.single.key, 'attachment');
              expect(o.uri.host, 'portal.vspu.ru');
              return page(id == '37' && rejectSecondUpload
                  ? '{"error":"rejected"}'
                  : '{}');
            }
            if (o.method == 'POST') {
              expect(uploads, ['1', '37']);
              expect(o.data, containsPair('field_36', '10'));
              sent = true;
              return page('');
            }
            return page(gssHtml);
          });
      final result = await submitRequestForm(requestId: '101', values: {
        'field_36': '10'
      }, files: {
        '1': RequestFile(
            name: 'application.docx', bytes: Uint8List.fromList([1])),
        '37': RequestFile(
            name: 'confirmation.pdf', bytes: Uint8List.fromList([2])),
      });
      expect(result.success, !rejectSecondUpload);
      expect(sent, !rejectSecondUpload);
    });
  }

  testWidgets(
      'GSS has local download, readable long categories and required attachment',
      (tester) async {
    tester.view.physicalSize = const Size(360, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    DirectPortalClient.testFactory = () => fakePortal((o) {
          if (o.uri.path == '/login')
            return page(
                o.method == 'GET' ? portalLoginHtml : portalLoggedInHtml);
          if (o.uri.path == '/request/index') return page(portalListHtml);
          return page(gssHtml);
        });
    await tester.runAsync(() async {
      await tester.pumpWidget(MaterialApp(
          theme: buildTheme(Brightness.light),
          builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(1.3)),
              child: child!),
          home: const RequestFormScreen(requestId: '101')));
    });
    for (var attempt = 0;
        attempt < 100 && find.text('Скачать шаблон Word').evaluate().isEmpty;
        attempt++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump(const Duration(milliseconds: 50));
    }
    await tester.pumpAndSettle();
    expect(find.text('Скачать шаблон Word'), findsOneWidget);
    expect(find.text('Открыть шаблон на портале'), findsNothing);
    final dropdown =
        find.byWidgetPredicate((w) => w is DropdownButtonFormField);
    await tester.ensureVisible(dropdown);
    await tester.pumpAndSettle();
    await tester.tap(dropdown);
    await tester.pumpAndSettle();
    final option = find.text(
        'Лица, подвергшимся воздействию радиации вследствие катастрофы на Чернобыльской АЭС и иных радиационных катастроф');
    await tester.scrollUntilVisible(option, 200, scrollable: find.byType(Scrollable).last);
    await Scrollable.ensureVisible(tester.element(option), alignment: .5);
    await tester.pumpAndSettle();
    await tester.tap(option);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.scrollUntilVisible(find.text('Отправить на обработку'), 200,
      scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Отправить на обработку'));
    await tester.pumpAndSettle();
    expect(find.text('Прикрепите заявление'), findsOneWidget);
    expect(find.text('Отправить заявление?'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
