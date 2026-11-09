import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unio_app/config/brand.dart';
import 'package:unio_app/widgets/unio_ai_brand.dart';
import 'package:unio_app/widgets/unio_ai_motion.dart';
import 'package:unio_app/screens/assistant_screen.dart';
import 'package:unio_app/services/assistant_service.dart';
import 'package:unio_app/services/locale_service.dart';
import 'package:unio_app/l10n/app_localizations.dart';

void main() {
  for (final brightness in Brightness.values) {
    testWidgets(
        'Pending state and stop fit a small keyboard viewport: $brightness',
        (tester) async {
      tester.view.physicalSize = const Size(320, 600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final chat = AssistantConversation(owner: () async => null);
      await chat.initializeHistory();
      chat.messages.add(AssistantMessage.question('Show my grades'));
      chat.busy = true;
      chat.stage = 'grades_loading';
      await tester.pumpWidget(MaterialApp(
        theme: buildTheme(brightness),
        locale: const Locale('ru'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
                viewInsets: const EdgeInsets.only(bottom: 260),
                textScaler: const TextScaler.linear(2)),
            child: child!),
        home: AssistantScreen(conversation: chat, group: 'TEST'),
      ));
      await tester.pump(const Duration(milliseconds: 500));
      // The initial scroll-to-end callback schedules the next layout frame.
      await tester.pump(const Duration(milliseconds: 16));
      expect(find.text(l10n.aiLoadingGrades), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.byTooltip(l10n.aiStop));
      await tester.pumpAndSettle();
      expect(chat.busy, isFalse);
      expect(tester.binding.hasScheduledFrame, isFalse);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      chat.dispose();
    });
  }

  testWidgets(
      'Entrance settles; live motion repaints without rebuilding content',
      (tester) async {
    var busy = false, visible = true;
    var contentBuilds = 0;
    late StateSetter update;
    await tester.pumpWidget(MaterialApp(
      theme: buildTheme(Brightness.dark),
      home: StatefulBuilder(builder: (context, setState) {
        update = setState;
        return TickerMode(
            enabled: visible,
            child: UnioAiMotion(
              busy: busy,
              child: Builder(builder: (context) {
                contentBuilds++;
                return const UnioAiAtmosphere(
                    empty: true, child: Center(child: UnioAiMark(size: 64)));
              }),
            ));
      }),
    ));
    await tester.pumpAndSettle();
    expect(tester.binding.hasScheduledFrame, isFalse);
    update(() => busy = true);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    final builds = contentBuilds;
    final motion = tester.widget<AiMotionScope>(find.byType(AiMotionScope));
    final before = motion.progress;
    await tester.pump(const Duration(milliseconds: 500));
    expect(motion.progress, isNot(before));
    expect(contentBuilds, builds);
    expect(tester.binding.hasScheduledFrame, isTrue);

    update(() => visible = false);
    await tester.pumpAndSettle();
    expect(tester.binding.hasScheduledFrame, isFalse);
    update(() => visible = true);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.binding.hasScheduledFrame, isTrue);
    update(() => busy = false);
    await tester.pumpAndSettle();
    expect(tester.binding.hasScheduledFrame, isFalse);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Reduced motion stays static during a real pending request',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child:
            const UnioAiMotion(busy: true, child: Center(child: UnioAiMark())),
      ),
    ));
    await tester.pumpAndSettle();
    final motion = tester.widget<AiMotionScope>(find.byType(AiMotionScope));
    expect(motion.enabled, isFalse);
    expect(motion.progress, 0);
    expect(tester.binding.hasScheduledFrame, isFalse);
    await tester.pump(const Duration(seconds: 3));
    expect(motion.progress, 0);
    expect(tester.binding.hasScheduledFrame, isFalse);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Backgrounding pauses thinking; foregrounding resumes it',
      (tester) async {
    addTearDown(() => tester.binding
        .handleAppLifecycleStateChanged(AppLifecycleState.resumed));
    await tester.pumpWidget(const MaterialApp(
      home: UnioAiMotion(busy: true, child: Center(child: UnioAiMark())),
    ));
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.binding.hasScheduledFrame, isTrue);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pumpAndSettle();
    expect(tester.binding.hasScheduledFrame, isFalse);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.binding.hasScheduledFrame, isTrue);
    await tester.pumpWidget(const SizedBox());
    expect(tester.takeException(), isNull);
  });
}
