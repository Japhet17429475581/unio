import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unio_app/config/brand.dart';
import 'package:unio_app/screens/settings_tab.dart';
import 'package:unio_app/widgets/guide_stories.dart';
import 'package:unio_app/widgets/unio_card.dart';

void main() {
  testWidgets(
      'Setting labels are inert, switches work and logout requires confirmation',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    var dark = false;
    var changes = 0;
    var logouts = 0;
    await tester.pumpWidget(MaterialApp(
        home: StatefulBuilder(
            builder: (context, setState) => Scaffold(
                  body: SettingsTab(
                      group: 'test',
                      isPortalMode: false,
                      onLogout: () => logouts++,
                      onUpgradeToPortal: (_, __) async {},
                      darkMode: dark,
                      onDarkModeChanged: (v) {
                        changes++;
                        setState(() => dark = v);
                      }),
                ))));
    await tester.pumpAndSettle();
    expect(find.byType(GuideStories), findsNothing);
    expect(find.text('Включена'), findsNothing);
    expect(find.text('Выключена'), findsNothing);
    await tester.scrollUntilVisible(find.text('Тёмная тема'), 200,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('Тёмная тема'));
    await tester.pumpAndSettle();
    expect(changes, 0);
    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();
    expect(changes, 1);
    expect(dark, isTrue);
    await tester.scrollUntilVisible(find.text('Пуш-уведомления'), 200,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('Пуш-уведомления'));
    await tester.pumpAndSettle();
    expect(tester.widget<Switch>(find.byType(Switch).last).value, isFalse);
    await tester.scrollUntilVisible(find.text('Завершить гостевой сеанс'), 200,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('Завершить гостевой сеанс'));
    await tester.pumpAndSettle();
    expect(logouts, 0);
    await tester.tap(find.text('Отмена'));
    await tester.pumpAndSettle();
    expect(logouts, 0);
    await tester.tap(find.text('Завершить гостевой сеанс'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Завершить'));
    await tester.pumpAndSettle();
    expect(logouts, 1);
  });

  testWidgets('Card colors interpolate across theme brightness boundary',
      (tester) async {
    final light = buildTheme(Brightness.light);
    final dark = buildTheme(Brightness.dark);
    Future<Color> cardColor(double t) async {
      late Color color;
      await tester.pumpWidget(MaterialApp(
          home: Theme(
        data: ThemeData.lerp(light, dark, t),
        child: Builder(builder: (context) {
          color = unioCardDecoration(context).color!;
          return const SizedBox();
        }),
      )));
      return color;
    }

    final before = await cardColor(.499);
    final after = await cardColor(.501);
    expect((after.r - before.r).abs(), lessThan(.02));
    expect((after.g - before.g).abs(), lessThan(.02));
    expect((after.b - before.b).abs(), lessThan(.02));
  });
}
