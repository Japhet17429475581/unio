import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unio_app/config/brand.dart';
import 'package:unio_app/widgets/system_bars.dart';
import 'package:unio_app/app.dart';
import 'package:unio_app/widgets/welcome_visuals.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('First bootstrap frame stays dark before saved settings load',
      (tester) async {
    SharedPreferences.setMockInitialValues({'dark_mode': true});
    FlutterSecureStorage.setMockInitialValues({});
    tester.view.padding = const FakeViewPadding(bottom: 48);
    addTearDown(tester.view.resetPadding);
    await tester.pumpWidget(const App());
    expect(
        SystemChrome.latestStyle?.systemNavigationBarColor, welcomeBackground);
    expect(SystemChrome.latestStyle?.systemNavigationBarIconBrightness,
        Brightness.light);
    expect(
        SystemChrome.latestStyle?.systemNavigationBarContrastEnforced, false);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  });
  testWidgets(
      'Navigation bar follows app theme on pushed routes with bottom inset',
      (tester) async {
    tester.view.physicalSize = const Size(432, 960);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(bottom: 48);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    final mode = ValueNotifier(ThemeMode.light);
    addTearDown(mode.dispose);
    final navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(ValueListenableBuilder<ThemeMode>(
      valueListenable: mode,
      builder: (context, value, child) => MaterialApp(
        navigatorKey: navigator,
        theme: buildTheme(Brightness.light),
        darkTheme: buildTheme(Brightness.dark),
        themeMode: value,
        builder: (context, child) => UnioSystemBars(child: child!),
        home: const Scaffold(body: SafeArea(child: Text('home'))),
      ),
    ));
    await tester.pumpAndSettle();
    expect(SystemChrome.latestStyle?.systemNavigationBarIconBrightness,
        Brightness.dark);
    mode.value = ThemeMode.dark;
    await tester.pumpAndSettle();
    navigator.currentState!.push(MaterialPageRoute<void>(
        builder: (context) => Scaffold(
            appBar: AppBar(title: const Text('search')),
            body: const SafeArea(child: Text('teacher')))));
    await tester.pumpAndSettle();
    final style = SystemChrome.latestStyle!;
    expect(style.systemNavigationBarColor,
        buildTheme(Brightness.dark).scaffoldBackgroundColor);
    expect(style.systemNavigationBarIconBrightness, Brightness.light);
    expect(style.systemNavigationBarContrastEnforced, isFalse);
    expect(find.text('teacher'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
