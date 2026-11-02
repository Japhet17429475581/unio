import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unio_app/config/brand.dart';
import 'package:unio_app/screens/requests_list_screen.dart';
import 'package:unio_app/screens/request_form_screen.dart';
import 'package:unio_app/services/direct_portal_client.dart';
import 'support/portal_fakes.dart';

void main() {
  testWidgets(
      'Income form shows period, postal address and required attachment',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    FlutterSecureStorage.setMockInitialValues({
      'account_token': 'test',
      'is_portal_mode': 'true',
      'portal_login': 'test',
      'portal_password': 'secret',
    });
    var posted = false;
    DirectPortalClient.testFactory = () => fakePortal((o) {
          if (o.uri.path == '/login')
            return page(
                o.method == 'GET' ? portalLoginHtml : portalLoggedInHtml);
          if (o.uri.path == '/request/index') return page(portalListHtml);
          if (o.method == 'POST') posted = true;
          return page(incomeFormHtml);
        });
    addTearDown(() => DirectPortalClient.testFactory = null);
    await tester.runAsync(() async {
      await tester.pumpWidget(MaterialApp(
          theme: buildTheme(Brightness.light),
          home: const RequestFormScreen(requestId: '101')));
    });
    // Wait for the async portal fixture, not a fixed 150 ms wall-clock delay.
    // Indeterminate loaders keep scheduling frames until that request finishes.
    for (var attempt = 0;
        attempt < 100 && find.text('Скачать шаблон Word').evaluate().isEmpty;
        attempt++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(find.text('Скачать шаблон Word'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('Начало периода *'), findsOneWidget);
    expect(find.text('Конец периода *'), findsOneWidget);
    expect(find.text('Почтовый адрес *'), findsNothing);
    Finder field(String name) => find.byWidgetPredicate(
        (w) => w is TextFormField && '${w.key}'.contains(name));
    await tester.enterText(field('field_144'), '01.01.2026');
    await tester.enterText(field('field_145'), '31.01.2026');
    await tester
        .tap(find.byWidgetPredicate((w) => w is DropdownButtonFormField));
    await tester.pumpAndSettle();
    await tester.tap(find.text('По почте России').last);
    await tester.pumpAndSettle();
    expect(find.text('Почтовый адрес *'), findsOneWidget);
    expect(find.text('Электронная почта *'), findsNothing);
    await tester.ensureVisible(field('field_146'));
    await tester.enterText(field('field_146'), 'Волгоград, ул. Тестовая, 1');
    await tester.ensureVisible(field('field_166'));
    await tester.enterText(field('field_166'), '2');
    await tester.ensureVisible(find.text('Выбрать файл'));
    expect(find.text('Заявление *'), findsOneWidget);
    await tester.ensureVisible(find.text('Отправить на обработку'));
    await tester.tap(find.text('Отправить на обработку'));
    await tester.pumpAndSettle();
    expect(find.text('Прикрепите заявление'), findsOneWidget);
    expect(find.text('Отправить заявление?'), findsNothing);
    expect(posted, isFalse);
    expect(tester.takeException(), isNull);
  });

  for (final brightness in Brightness.values) {
    testWidgets(
        'Request creation, address validation and submit confirmation in ${brightness.name}',
        (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({});
      FlutterSecureStorage.setMockInitialValues({
        'account_token': 'test',
        'is_portal_mode': 'true',
        'portal_login': 'test',
        'portal_password': 'secret'
      });
      var sent = 0;
      var status = 'Новое';
      var editReads = 0;
      DirectPortalClient.testFactory = () => fakePortal((o) {
            switch (o.uri.path) {
              case '/login':
                return page(
                    o.method == 'GET' ? portalLoginHtml : portalLoggedInHtml);
              case '/request/index':
                return page(
                    portalListHtml.replaceAll('получение информации', status));
              case '/request/get-types':
                return page(jsonEncode({
                  'result': 'ok',
                  'items': [
                    {'id': '10', 'text': 'Справка об обучении'},
                    {'id': '11', 'text': 'Справка COVID-19'},
                  ]
                }));
              case '/request/create':
                return page('', status: 302, headers: {
                  'location': ['/request/101/edit']
                });
              case '/request/101/edit':
                if (o.method == 'POST') {
                  sent++;
                } else {
                  editReads++;
                }
                return page(portalFormHtml);
              default:
                throw StateError('Unexpected URL');
            }
          });
      addTearDown(() => DirectPortalClient.testFactory = null);
      Future<void> settle() async {
        for (var i = 0; i < 40; i++) {
          await tester.pump(const Duration(milliseconds: 50));
          await tester.runAsync(
              () => Future<void>.delayed(const Duration(milliseconds: 10)));
        }
        await tester.pumpAndSettle();
      }

      Future<void> portalAction(Future<void> Function() action) async {
        await tester.runAsync(() async {
          await action();
          await Future<void>.delayed(const Duration(milliseconds: 150));
        });
        await settle();
      }

      final dropdowns =
          find.byWidgetPredicate((w) => w is DropdownButtonFormField);
      await portalAction(() => tester.pumpWidget(MaterialApp(
          theme: buildTheme(brightness), home: const RequestsListScreen())));
      await settle();
      expect(find.text('Новое'), findsOneWidget);
      await tester.tap(find.text('Новое'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Подождите ещё немного'), findsOneWidget);
      expect(editReads, 0);
      await tester.tap(find.text('Подать заявление'));
      await tester.pumpAndSettle();
      await tester.tap(dropdowns.first);
      await tester.pumpAndSettle();
      await portalAction(() => tester.tap(find.text('Обучение').last));
      await settle();
      await tester.tap(dropdowns.last);
      await tester.pumpAndSettle();
      expect(find.text('Справка COVID-19'), findsNothing);
      await tester.tap(find.text('Справка об обучении').last);
      await tester.pumpAndSettle();
      await portalAction(() => tester.tap(find.text('Создать заявление')));
      await settle();
      expect(find.text('Заполните данные'), findsNothing);
      expect(editReads, 0);
      status = 'получение информации';
      await portalAction(() => tester.tap(find.byTooltip('Обновить статусы')));
      await settle();
      expect(find.text('Перейти к заполнению'), findsOneWidget);
      expect(find.text('получение информации'), findsNothing);
      await portalAction(() => tester.tap(find.text('Перейти к заполнению')));
      await settle();
      expect(find.text('Заполните данные'), findsOneWidget);
      await tester.enterText(
          find.byType(TextFormField).first, 'Тестовая организация');
      await tester.pumpAndSettle();
      final delivery = dropdowns.last;
      await tester.ensureVisible(delivery);
      await tester.pumpAndSettle();
      await tester.tap(delivery);
      await tester.pumpAndSettle();
      await tester.tap(find.text('По электронной почте').last);
      await tester.pumpAndSettle();
      expect(find.text('Электронная почта *'), findsOneWidget);
      final send = find.text('Отправить на обработку');
      await tester.ensureVisible(send);
      await tester.pumpAndSettle();
      await tester.tap(send);
      await tester.pumpAndSettle();
      expect(find.text('Заполните это поле'), findsOneWidget);
      expect(sent, 0);
      final email = find.byWidgetPredicate((w) =>
          w is TextFormField &&
          w.key == const ValueKey('request-input-field_34'));
      await tester.ensureVisible(email);
      await tester.enterText(email, 'student@example.org');
      await tester.ensureVisible(send);
      await tester.pumpAndSettle();
      await tester.tap(send);
      await tester.pumpAndSettle();
      expect(find.text('Отправить заявление?'), findsOneWidget);
      await tester.tap(find.text('Проверить ещё раз'));
      await tester.pumpAndSettle();
      expect(sent, 0);
      expect(tester.takeException(), isNull);
    });
  }
}
