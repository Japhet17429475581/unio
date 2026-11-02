import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:unio_app/config/brand.dart';
import 'package:unio_app/screens/news_list_screen.dart';
import 'package:unio_app/widgets/unio_loader.dart';

Future<void> capture(WidgetTester tester, String name) async {
  if (!const bool.fromEnvironment('UNIO_LOADER_PREVIEWS')) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const ValueKey('preview')));
  await tester.runAsync(() async {
    final image = await boundary.toImage();
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    await Directory('build/loader-previews').create(recursive: true);
    await File('build/loader-previews/$name.png')
        .writeAsBytes(data!.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  for (final brightness in Brightness.values) {
    testWidgets('Liquid mark renders large and compact in ${brightness.name}',
        (tester) async {
      tester.view.physicalSize = const Size(390, 600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(MaterialApp(
          theme: buildTheme(brightness),
          home: RepaintBoundary(
              key: const ValueKey('preview'),
              child: Scaffold(
                body: Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const UnioLoader(),
                  const SizedBox(height: 40),
                  FilledButton(
                      onPressed: null,
                      child: const SizedBox.square(
                          dimension: 24,
                          child: UnioLoader(color: Colors.white))),
                ])),
              ))));
      for (var phase = 0; phase < 4; phase++) {
        await tester.pump(const Duration(milliseconds: 900));
        await capture(tester, '${brightness.name}-$phase');
        expect(tester.takeException(), isNull);
      }
      expect(tester.getSize(find.byType(UnioLoader).last), const Size(24, 24));
      expect(tester.binding.hasScheduledFrame, true);
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      expect(tester.binding.hasScheduledFrame, false);
    });
  }

  testWidgets(
      'Loader respects app lifecycle, ticker visibility and reduced motion',
      (tester) async {
    Future<void> mount({bool reduced = false, bool visible = true}) async {
      await tester.pumpWidget(MaterialApp(
          home: MediaQuery(
              data: MediaQueryData(disableAnimations: reduced),
              child: TickerMode(
                  enabled: visible,
                  child: const Center(child: UnioLoader())))));
      await tester.pump();
    }

    await mount();
    expect(tester.binding.hasScheduledFrame, true);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    expect(tester.binding.hasScheduledFrame, false);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(tester.binding.hasScheduledFrame, true);
    await mount(visible: false);
    expect(tester.binding.hasScheduledFrame, false);
    await mount(reduced: true);
    await tester.pumpAndSettle();
    expect(tester.binding.hasScheduledFrame, false);
    expect(find.bySemanticsLabel('Загрузка'), findsOneWidget);
  });

  testWidgets('News removes the logo when the request completes, mid-cycle',
      (tester) async {
    final response = Completer<http.Response>();
    await http.runWithClient(() async {
      await tester.pumpWidget(MaterialApp(
          theme: buildTheme(Brightness.light), home: const NewsListScreen()));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(UnioLoader), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      response.complete(http.Response('{"items":[]}', 200));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1));
      expect(find.byType(UnioLoader), findsNothing);
      expect(find.text('Пока нет новостей'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }, () => MockClient((_) => response.future));
  });

  testWidgets(
      'Pull-to-refresh keeps its gesture and hides the logo on completion',
      (tester) async {
    final pending = Completer<void>();
    var calls = 0;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: UnioRefreshIndicator(
      onRefresh: () {
        calls++;
        return pending.future;
      },
      child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [SizedBox(height: 80, child: Text('Content'))]),
    ))));
    await tester.drag(find.byType(ListView), const Offset(0, 15));
    await tester.pumpAndSettle();
    expect(calls, 0);
    expect(find.byType(UnioLoader), findsNothing);
    await tester.drag(find.byType(ListView), const Offset(0, 400));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(calls, 1);
    expect(find.byType(UnioLoader), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    pending.complete();
    await tester.pumpAndSettle();
    expect(find.byType(UnioLoader), findsNothing);
    expect(find.text('Content'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
