import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:unio_app/config/brand.dart';
import 'package:unio_app/screens/lesson_notes_screen.dart';
import 'package:unio_app/services/lesson_notes_service.dart';
import 'package:unio_app/widgets/tap_feedback.dart';
import 'package:unio_app/widgets/note_photo_gallery.dart';
import 'package:unio_app/models/lesson_note.dart';

import 'support/notes_fakes.dart';

void main() {
  testWidgets('Photo viewer opens selected photo and pages both ways',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
        home: NotePhotoViewer(
            initialIndex: 1,
            photos: List.generate(
                3, (index) => NotePhoto(id: '$index', bytes: photoBytes)))));
    await tester.pumpAndSettle();
    expect(find.text('2/3'), findsOneWidget);
    await tester.drag(
        find.byKey(const ValueKey('note-photo-pages')), const Offset(-600, 0));
    await tester.pumpAndSettle();
    expect(find.text('3/3'), findsOneWidget);
    expect(
        tester
            .widget<IconButton>(find.byWidgetPredicate((widget) =>
                widget is IconButton && widget.tooltip == 'Следующее фото'))
            .onPressed,
        isNull);
    await tester.tap(find.byTooltip('Предыдущее фото'));
    await tester.pumpAndSettle();
    expect(find.text('2/3'), findsOneWidget);
    await tester.drag(
        find.byKey(const ValueKey('note-photo-pages')), const Offset(600, 0));
    await tester.pumpAndSettle();
    expect(find.text('1/3'), findsOneWidget);
    expect(
        tester
            .widget<IconButton>(find.byWidgetPredicate((widget) =>
                widget is IconButton && widget.tooltip == 'Предыдущее фото'))
            .onPressed,
        isNull);
    await tester.pumpWidget(const SizedBox());
    expect(tester.takeException(), isNull);
  });

  for (final brightness in Brightness.values) {
    testWidgets('Edit, reopen and delete a note in ${brightness.name}',
        (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final service =
          LessonNotesService(storage: MemoryNotesStorage(), owner: 'student');
      await tester.pumpWidget(MaterialApp(
        theme: buildTheme(brightness),
        home: Builder(
            builder: (context) => Scaffold(
                    body: TextButton(
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => LessonNotesScreen(
                            lesson: testLesson(),
                            group: 'TEST-101',
                            service: service,
                          ))),
                  child: const Text('Открыть пару'),
                ))),
      ));
      await tester.tap(find.text('Открыть пару'));
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsOneWidget,
          reason: tester
              .widgetList<Text>(find.byType(Text))
              .map((text) => text.data)
              .join(' | '));
      await tester.enterText(find.byType(TextField), 'Прочитать главу 3');
      await tester.pump();
      await tester.tap(find.byType(PrimaryButton));
      await tester.pumpAndSettle();
      expect(find.text('Сохранено на устройстве'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Открыть пару'));
      await tester.pumpAndSettle();
      expect(find.text('Прочитать главу 3'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'Несохранённое');
      await tester.pump();
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Сохранить изменения?'), findsOneWidget);
      await tester.tap(find.text('Не сохранять'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Открыть пару'));
      await tester.pumpAndSettle();
      expect(find.text('Прочитать главу 3'), findsOneWidget);
      await tester.tap(find.byTooltip('Удалить заметку'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Удалить'));
      await tester.pumpAndSettle();
      expect(
          (await service.load(service.keyFor('TEST-101', testLesson())))
              .isEmpty,
          isTrue);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Attach, view and remove a photograph', (tester) async {
    final service =
        LessonNotesService(storage: MemoryNotesStorage(), owner: 'student');
    final picker = FakeNotePicker()..photos = [XFile.fromData(photoBytes)];
    await tester.pumpWidget(MaterialApp(
      theme: buildTheme(Brightness.light),
      home: LessonNotesScreen(
          lesson: testLesson(),
          group: 'TEST-101',
          service: service,
          picker: picker),
    ));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Из галереи'));
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      await tester.tap(find.text('Из галереи'));
      await Future<void>.delayed(const Duration(milliseconds: 150));
    });
    await tester.pumpAndSettle();
    expect(
        (await service.load(service.keyFor('TEST-101', testLesson()))).photos,
        hasLength(1));
    await tester.ensureVisible(find.byType(Image).last);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Image).last);
    await tester.pumpAndSettle();
    expect(find.byType(InteractiveViewer), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Убрать фото'));
    await tester.pump();
    await tester.tap(find.byType(PrimaryButton));
    await tester.pumpAndSettle();
    expect(
        (await service.load(service.keyFor('TEST-101', testLesson()))).photos,
        isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Failed save keeps the draft editable', (tester) async {
    final storage = MemoryNotesStorage();
    final service = LessonNotesService(storage: storage, owner: 'student');
    storage.failOnWrite = service.keyFor('TEST-101', testLesson());
    await tester.pumpWidget(MaterialApp(
      theme: buildTheme(Brightness.light),
      home: LessonNotesScreen(
          lesson: testLesson(), group: 'TEST-101', service: service),
    ));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Не потерять');
    await tester.pump();
    await tester.tap(find.byType(PrimaryButton));
    await tester.pumpAndSettle();
    expect(find.text('Не потерять'), findsOneWidget);
    expect(find.textContaining('Не удалось сохранить'), findsOneWidget);
    storage.failOnWrite = null;
    await tester.tap(find.byType(PrimaryButton));
    await tester.pumpAndSettle();
    expect((await service.load(service.keyFor('TEST-101', testLesson()))).text,
        'Не потерять');
  });
}
