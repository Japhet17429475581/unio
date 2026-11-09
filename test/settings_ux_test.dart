import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unio_app/config/brand.dart';
import 'package:unio_app/app.dart';
import 'package:unio_app/services/legal_service.dart';
import 'package:unio_app/screens/home_screen.dart';
import 'package:unio_app/screens/settings_tab.dart';
import 'package:unio_app/services/api_service.dart';
import 'package:unio_app/services/app_version.dart';
import 'package:unio_app/services/secure_storage_service.dart';
import 'package:unio_app/widgets/unio_navigation_bar.dart';
import 'package:unio_app/widgets/group_selection_dialog.dart';
import 'package:unio_app/services/direct_portal_client.dart';
import 'support/portal_fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
  });
  tearDown(() => DirectPortalClient.testFactory = null);

  test('Viewed group persists independently; logout and next login reset it',
      () async {
    await saveSession(
        accountToken: 'test-token',
        groupCode: 'OWN',
        accountGroup: 'OWN',
        isPortalMode: true,
        portalLogin: 'test-login',
        portalPassword: 'test-password');
    await saveSelectedScheduleGroup('OTHER');
    final restored = (await loadSession())!;
    expect(restored.selectedScheduleGroup, 'OTHER');
    expect(restored.accountGroup, 'OWN');
    expect(restored.groupCode, 'OWN');
    expect(restored.portalLogin, 'test-login');
    expect(restored.portalPassword, 'test-password');
    expect(restored.accountToken, 'test-token');
    await clearSession();
    expect(await loadSession(), isNull);
    await saveSession(
        accountToken: 'new-test-token', groupCode: 'NEW', isPortalMode: false);
    expect((await loadSession())!.selectedScheduleGroup, 'NEW');
    expect((await loadSession())!.accountGroup, isNull);
  });

  test('Unknown portal group is not inferred from guest selection', () async {
    await saveSession(
        accountToken: 'test-token',
        groupCode: 'GUEST',
        isPortalMode: true,
        portalLogin: 'test',
        portalPassword: 'test');
    expect((await loadSession())!.accountGroup, isNull);
  });

  test('Empty cached week cannot disguise a failed current request', () async {
    var fail = false;
    await http.runWithClient(() async {
      expect(
          await fetchLessons('TEST', date: DateTime(2026, 10, 19), week: true),
          isEmpty);
      fail = true;
      await expectLater(
          fetchLessons('TEST', date: DateTime(2026, 10, 19), week: true),
          throwsA(isA<ApiException>()));
    },
        () => MockClient((_) async => fail
            ? http.Response('unavailable', 502)
            : http.Response('{"lessons":[]}', 200)));
  });

  for (final brightness in Brightness.values) {
    testWidgets('Settings structure and version in ${brightness.name}',
        (tester) async {
      final version = await tester.runAsync(loadAppVersion);
      await tester.pumpWidget(MaterialApp(
          theme: buildTheme(brightness),
          home: Scaffold(
              body: SettingsTab(
                  group: 'TEST',
                  isPortalMode: false,
                  onLogout: () {},
                  onUpgradeToPortal: (_, __) async {},
                  onChangeGroup: (_) async {},
                  darkMode: brightness == Brightness.dark,
                  onDarkModeChanged: (_) {}))));
      await tester.pumpAndSettle();
      expect(find.text('Аккаунт и параметры приложения'), findsOneWidget);
      expect(find.text('Сменить группу'), findsOneWidget);
      expect(find.text('Оформление'), findsNothing);
      expect(find.text('Уведомления'), findsNothing);
      await tester.scrollUntilVisible(
          find.text('Завершить гостевой сеанс'), 180);
      expect(find.text('Выйти из аккаунта'), findsNothing);
      await tester.drag(find.byType(ListView), const Offset(0, -400));
      await tester.pump();
      await tester.runAsync(() => tester
          .widget<FutureBuilder<String>>(find.byType(FutureBuilder<String>))
          .future!);
      await tester.pumpAndSettle();
      expect(find.text('UNIO · Версия $version'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
      'Group picker rejects unknown input, keeps failures editable and saves valid selection',
      (tester) async {
    var saved = 'OLD';
    var fail = true;
    var calls = 0;
    await http.runWithClient(() async {
      await tester.pumpWidget(MaterialApp(
          home: Builder(
              builder: (context) => Scaffold(
                  body: TextButton(
                      onPressed: () => showDialog<void>(
                          context: context,
                          builder: (_) => GroupSelectionDialog(
                              group: 'OLD',
                              onSave: (group) async {
                                calls++;
                                if (fail)
                                  throw ApiException(
                                      'Не удалось загрузить расписание');
                                saved = group;
                              })),
                      child: const Text('Open'))))));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'INVALID');
      await tester.tap(find.text('Сохранить'));
      await tester.pumpAndSettle();
      expect(calls, 0);
      await tester.enterText(find.byType(TextField), 'NEW');
      await tester.tap(find.text('Сохранить'));
      await tester.pumpAndSettle();
      expect(saved, 'OLD');
      expect(find.text('Не удалось загрузить расписание'), findsOneWidget);
      fail = false;
      await tester.tap(find.text('Сохранить'));
      await tester.pumpAndSettle();
      expect(saved, 'NEW');
      expect(find.byType(GroupSelectionDialog), findsNothing);
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'OLD');
      await tester.tap(find.text('Отмена'));
      await tester.pumpAndSettle();
      expect(saved, 'NEW');
      expect(calls, 2);
    },
        () => MockClient(
            (_) async => http.Response('{"groups":["OLD","NEW"]}', 200)));
  });

  testWidgets(
      'App restores selected group and upgrades without recreating Home',
      (tester) async {
    await tester.runAsync(() async {
      await legal.acceptCore();
      await saveSession(
          accountToken: 'test-token', groupCode: 'OLD', isPortalMode: false);
      await saveSelectedScheduleGroup('NEW');
    });
    DirectPortalClient.testFactory =
        () => fakePortal((request) => page(request.uri.path == '/login'
            ? request.method == 'POST'
                ? portalLoggedInHtml
                : portalLoginHtml
            : '<div class="AcademicProgress"></div>'));
    await http.runWithClient(() async {
      await tester.pumpWidget(const App());
      await tester.pumpAndSettle();
      expect(
          tester
              .widget<HomeScreen>(find.byType(HomeScreen, skipOffstage: false))
              .group,
          'NEW');
      await tester.tap(find.byTooltip('Настройки'));
      await tester.pumpAndSettle();
      final state = tester.state(find.byType(HomeScreen, skipOffstage: false));
      final upgrade = tester
          .widget<HomeScreen>(find.byType(HomeScreen, skipOffstage: false))
          .onUpgradeToPortal;
      await tester.runAsync(() => http.runWithClient(
          () => upgrade('test-login', 'test-password'),
          () => MockClient(
              (_) async => http.Response('{"groups":["OLD","NEW"]}', 200))));
      await tester.pumpAndSettle();
      expect(tester.state(find.byType(HomeScreen, skipOffstage: false)),
          same(state));
      expect(
          tester
              .widget<HomeScreen>(find.byType(HomeScreen, skipOffstage: false))
              .isPortalMode,
          isTrue);
      expect(
          tester
              .widget<UnioNavigationBar>(
                  find.byType(UnioNavigationBar, skipOffstage: false))
              .selectedIndex,
          0);
      expect((await loadSession())!.accountToken, 'test-token');
      expect((await loadSession())!.accountGroup, isNull);
      await tester.pumpWidget(const SizedBox());
    },
        () => MockClient((request) async => http.Response(
            jsonEncode(request.url.path.endsWith('/me')
                ? {'mode': 'guest', 'group_code': 'OLD'}
                : request.url.path.endsWith('/groups')
                    ? {
                        'groups': ['OLD', 'NEW']
                      }
                    : request.url.path.contains('news')
                        ? {'items': []}
                        : {'lessons': []}),
            200)));
  });

  for (var tab = 0; tab < 4; tab++) {
    testWidgets('Portal upgrade preserves selected tab $tab', (tester) async {
      DirectPortalClient.testFactory =
          () => fakePortal((request) => page(request.uri.path == '/login'
              ? request.method == 'POST'
                  ? portalLoggedInHtml
                  : portalLoginHtml
              : '<div class="AcademicProgress"></div>'));
      var portal = false;
      late StateSetter update;
      await http.runWithClient(() async {
        await tester.pumpWidget(
            MaterialApp(home: StatefulBuilder(builder: (context, setState) {
          update = setState;
          return HomeScreen(
              group: 'TEST',
              isPortalMode: portal,
              onLogout: () {},
              onUpgradeToPortal: (_, __) async {},
              darkMode: false,
              onDarkModeChanged: (_) {});
        })));
        await tester.pumpAndSettle();
        tester
            .widget<UnioNavigationBar>(
                find.byType(UnioNavigationBar, skipOffstage: false))
            .onDestinationSelected!(tab);
        await tester.pumpAndSettle();
        update(() => portal = true);
        await tester.pumpAndSettle();
        expect(
            tester
                .widget<UnioNavigationBar>(
                    find.byType(UnioNavigationBar, skipOffstage: false))
                .selectedIndex,
            tab);
        await tester.pumpWidget(const SizedBox());
      },
          () => MockClient((request) async => http.Response(
              jsonEncode(request.url.path.contains('news')
                  ? {'items': []}
                  : {'lessons': []}),
              200)));
    });
  }
}
