import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unio_app/config/brand.dart';
import 'package:unio_app/screens/portal_upgrade_screen.dart';
import 'package:unio_app/screens/university_tab.dart';
import 'package:unio_app/widgets/portal_gate.dart';
import 'package:unio_app/screens/requests_list_screen.dart';
import 'package:unio_app/services/direct_portal_client.dart';
import 'support/portal_fakes.dart';

void main() {
  testWidgets(
      'Successful portal upgrade opens requests on the existing route; cancellation and failure keep the gate',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({
      'account_token': 'test',
      'is_portal_mode': 'true',
      'portal_login': 'test',
      'portal_password': 'secret'
    });
    DirectPortalClient.testFactory =
        () => fakePortal((o) => page(o.uri.path == '/login'
            ? o.method == 'GET'
                ? portalLoginHtml
                : portalLoggedInHtml
            : portalListHtml));
    addTearDown(() => DirectPortalClient.testFactory = null);
    var fail = true;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: UniversityTab(
      isPortalMode: false,
      onUpgradeToPortal: (_, __) async {
        if (fail) throw const DirectPortalException('Проверьте пароль');
      },
    ))));
    await tester.tap(find.text('Подать заявление'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Войти через портал ВГСПУ'));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(PortalGate), findsOneWidget);
    await tester.tap(find.text('Войти через портал ВГСПУ'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'student');
    await tester.enterText(find.byType(TextField).last, 'test-password');
    await tester.ensureVisible(find.text('Войти'));
    await tester.tap(find.text('Войти'));
    await tester.pumpAndSettle();
    expect(find.text('Проверьте пароль'), findsOneWidget);
    expect(find.byType(RequestsListScreen), findsNothing);
    fail = false;
    await tester.tap(find.text('Войти'));
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 50));
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 10)));
    }
    await tester.pumpAndSettle();
    expect(find.byType(RequestsListScreen), findsOneWidget);
    expect(find.byType(PortalGate), findsNothing);
    expect(find.byType(PortalUpgradeScreen), findsNothing);
    expect(find.text('Перейти к заполнению'), findsOneWidget);
    expect(find.byType(Scaffold), findsOneWidget); // No nested guest scaffold.
    expect(tester.takeException(), isNull);
  });
  for (final brightness in Brightness.values) {
    testWidgets(
        'Requests guest route paints its background in ${brightness.name}',
        (tester) async {
      final theme = buildTheme(brightness);
      await tester.pumpWidget(MaterialApp(
        theme: theme,
        home: Scaffold(
          body: UniversityTab(
            isPortalMode: false,
            onUpgradeToPortal: (_, __) async {},
          ),
        ),
      ));
      for (var attempt = 0; attempt < 2; attempt++) {
        await tester.tap(find.text('Подать заявление'));
        await tester.pump();
        // Проверяем первый кадр, середину и конец анимации маршрута.
        for (final elapsed in [0, 100, 250]) {
          await tester.pump(Duration(milliseconds: elapsed));
          final gate = find.byType(PortalGate);
          final context = tester.element(gate);
          expect(Scaffold.maybeOf(context), isNotNull);
          final canvas = find.ancestor(
            of: gate,
            matching: find.byWidgetPredicate((widget) =>
                widget is Material &&
                widget.type == MaterialType.canvas &&
                widget.color == theme.scaffoldBackgroundColor),
          );
          expect(canvas, findsOneWidget);
          expect(tester.takeException(), isNull);
        }
        await tester.pumpAndSettle();
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();
        expect(find.text('Подать заявление'), findsOneWidget);
      }
      await tester.tap(find.text('Подать заявление'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Войти через портал ВГСПУ'));
      await tester.pumpAndSettle();
      expect(find.byType(PortalUpgradeScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
