import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unio_app/models/portal_request.dart';
import 'package:unio_app/screens/lesson_notes_screen.dart';
import 'package:unio_app/services/lesson_notes_service.dart';
import 'package:unio_app/widgets/lesson_actions.dart';
import 'package:unio_app/widgets/request_card.dart';
import 'package:unio_app/widgets/tap_feedback.dart';
import 'redesign_test.dart' show mount, preview;
import 'support/notes_fakes.dart';

void main() {
  setUpAll(() async {
    final fonts = FontLoader('Onest');
    for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
      fonts.addFont(rootBundle.load('assets/fonts/Onest-$weight.ttf'));
    }
    await fonts.load();
    await (FontLoader('MaterialIcons')
          ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
        .load();
  });
  for (final brightness in Brightness.values) {
    testWidgets(
        'Note actions and saving remain above the keyboard: ${brightness.name}',
        (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);
      final service =
          LessonNotesService(storage: MemoryNotesStorage(), owner: 'student');
      await mount(
          tester,
          LessonNotesScreen(
              lesson: testLesson(), group: 'TEST', service: service),
          brightness: brightness);
      await preview(tester, 'notes-${brightness.name}');
      await tester.enterText(
          find.byType(TextField), 'Прочитать главу 3 и решить задачи 1–5.');
      tester.view.viewInsets = const FakeViewPadding(bottom: 260);
      await tester.pumpAndSettle();
      expect(find.byType(LessonActions), findsOneWidget);
      final save = find.byType(PrimaryButton);
      expect(tester.getRect(save).bottom, lessThanOrEqualTo(584));
      expect(tester.getRect(find.byType(LessonActions)).bottom,
          lessThan(tester.getRect(save).top));
      await preview(tester, 'notes-keyboard-${brightness.name}');
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect((await service.load(service.keyFor('TEST', testLesson()))).text,
          contains('Прочитать главу 3'));
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'Request states stay distinct and preserve portal labels: ${brightness.name}',
        (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      const states = [
        'Новое',
        'получение информации',
        'Справка готова',
        'Отклонено',
        'Неизвестный статус'
      ];
      var taps = 0;
      await mount(
          tester,
          Scaffold(
              appBar: AppBar(title: const Text('Справки и заявления')),
              body: ListView(padding: const EdgeInsets.all(20), children: [
                for (var i = 0; i < states.length; i++)
                  Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: RequestCard(
                          item: RequestListItem(
                              id: '${101 + i}',
                              title: i == 1
                                  ? 'Справка о доходах'
                                  : 'Справка об обучении',
                              category: 'Справки',
                              status: states[i],
                              updated: '',
                              editUrl: ''),
                          onTap: () => taps++)),
              ])),
          brightness: brightness);
      await preview(tester, 'requests-${brightness.name}');
      expect(find.text('Портал готовит форму для заполнения'), findsOneWidget);
      await tester.ensureVisible(find.text('Перейти к заполнению'));
      await tester.tap(find.text('Перейти к заполнению'));
      expect(taps, 1);
      await tester.scrollUntilVisible(find.text('Неизвестный статус'), 200);
      expect(find.text('Неизвестный статус'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
