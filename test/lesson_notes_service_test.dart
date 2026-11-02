import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:unio_app/models/lesson_note.dart';
import 'package:unio_app/services/lesson_notes_service.dart';
import 'package:unio_app/services/notes_storage/notes_storage_io.dart';

import 'support/notes_fakes.dart';

void main() {
  test(
      'Text and copied photos survive a new service and deletion of the source',
      () async {
    final temp = await Directory.systemTemp.createTemp('unio_notes_test_');
    addTearDown(() => temp.delete(recursive: true));
    final directory = Directory('${temp.path}/notes');
    final source = File('${temp.path}/gallery.png');
    await source.writeAsBytes(photoBytes);
    var service = LessonNotesService(
        storage: FileNotesStorage(directory), owner: 'student');
    final key = service.keyFor('TEST-101', testLesson());
    final photo = await service.importPhoto(XFile(source.path));
    await service.save(
        key, LessonNote(text: 'Решить задачи 1–5', photos: [photo]));
    await source.delete();

    service = LessonNotesService(
        storage: FileNotesStorage(directory), owner: 'student');
    final loaded = await service.load(key);
    expect(loaded.text, 'Решить задачи 1–5');
    expect(loaded.photos.single.bytes, photoBytes);
    await service.save(
        key, LessonNote(text: 'Задачи 6–10', photos: loaded.photos));
    expect((await service.load(key)).text, 'Задачи 6–10');
    await service.save(key, const LessonNote());
    expect((await service.load(key)).isEmpty, isTrue);
    expect(await directory.list().toList(), isEmpty);
  });

  test('Different accounts, groups and occurrences do not share notes',
      () async {
    final storage = MemoryNotesStorage();
    final first = LessonNotesService(storage: storage, owner: 'student1');
    final second = LessonNotesService(storage: storage, owner: 'student2');
    final key = first.keyFor('TEST-101', testLesson());
    await first.save(key, const LessonNote(text: 'Личная заметка'));
    expect((await second.load(second.keyFor('TEST-101', testLesson()))).isEmpty,
        isTrue);
    expect((await first.load(first.keyFor('TEST-102', testLesson()))).isEmpty,
        isTrue);
    expect(
        (await first.load(first.keyFor('TEST-101', testLesson(day: 8))))
            .isEmpty,
        isTrue);
    expect(
        (await first.load(first.keyFor('TEST-101', testLesson(start: '11:00'))))
            .isEmpty,
        isTrue);
    expect(first.keyFor(' test-101 ', testLesson(room: '202')), key);
    await expectLater(second.load(key), throwsA(isA<NotesException>()));
  });

  test(
      'A failed metadata write preserves the old note and rolls back new photos',
      () async {
    final storage = MemoryNotesStorage();
    final service = LessonNotesService(storage: storage, owner: 'student');
    final key = service.keyFor('TEST-101', testLesson());
    await service.save(key, const LessonNote(text: 'Не потерять'));
    final photo = await service.importPhoto(XFile.fromData(photoBytes));
    storage.failOnWrite = key;
    await expectLater(
        service.save(key, LessonNote(text: 'Новое', photos: [photo])),
        throwsStateError);
    expect((await service.load(key)).text, 'Не потерять');
    expect(storage.files.keys, [key]);
  });

  test('More than eight photos survive saving and picker recovery', () async {
    final storage = MemoryNotesStorage();
    final service = LessonNotesService(storage: storage, owner: 'student');
    final key = service.keyFor('TEST-101', testLesson());
    final photos = <NotePhoto>[];
    for (var i = 0; i < 16; i++) {
      photos.add(await service
          .importPhoto(XFile.fromData(Uint8List.fromList([...photoBytes, i]))));
    }
    await service.save(key, LessonNote(text: 'Homework', photos: photos));
    expect((await service.load(key)).photos.length, 16);
    await service.preparePicker(key);
    final picker = FakeNotePicker()
      ..lostPhotos = [
        XFile.fromData(Uint8List.fromList([...photoBytes, 99]))
      ];
    expect(await service.recoverPhotos(picker), isTrue);
    expect((await service.load(key)).photos.length, 17);
  });

  test('Removing a photo deletes only its local copy', () async {
    final storage = MemoryNotesStorage();
    final service = LessonNotesService(storage: storage, owner: 'student');
    final key = service.keyFor('TEST-101', testLesson());
    final photo = await service.importPhoto(XFile.fromData(photoBytes));
    await service.save(key, LessonNote(text: 'ДЗ', photos: [photo]));
    await service.save(key, const LessonNote(text: 'ДЗ'));
    expect(storage.files.keys, [key]);
    expect((await service.load(key)).photos, isEmpty);
  });

  test('Missing photo does not hide the saved text', () async {
    final storage = MemoryNotesStorage();
    final service = LessonNotesService(storage: storage, owner: 'student');
    final key = service.keyFor('TEST-101', testLesson());
    final photo = await service.importPhoto(XFile.fromData(photoBytes));
    await service.save(key, LessonNote(text: 'ДЗ', photos: [photo]));
    await storage.delete('${key}_photo_${photo.id}');
    final loaded = await service.load(key);
    expect(loaded.text, 'ДЗ');
    expect(loaded.photos.single.bytes, isNull);
  });

  test('Oversized photos and notes are rejected before replacing saved data',
      () async {
    final storage = MemoryNotesStorage();
    final service = LessonNotesService(storage: storage, owner: 'student');
    final key = service.keyFor('TEST-101', testLesson());
    await expectLater(
        service.importPhoto(
            XFile.fromData(Uint8List(LessonNotesService.maxPhotoBytes + 1))),
        throwsA(isA<NotesException>()));
    await expectLater(service.save(key, LessonNote(text: 'a' * 20001)),
        throwsA(isA<NotesException>()));
    expect(storage.files, isEmpty);
  });

  test('Android picker recovery attaches photos to the original lesson once',
      () async {
    final storage = MemoryNotesStorage();
    final service = LessonNotesService(storage: storage, owner: 'student');
    final key = service.keyFor('TEST-101', testLesson());
    await service.save(
        key, const LessonNote(text: 'Текст перед открытием камеры'));
    await service.preparePicker(key);
    final picker = FakeNotePicker()..lostPhotos = [XFile.fromData(photoBytes)];
    expect(await service.recoverPhotos(picker), isTrue);
    expect((await service.load(key)).photos.single.bytes, photoBytes);
    expect((await service.load(key)).text, 'Текст перед открытием камеры');
    expect(await service.recoverPhotos(picker), isFalse);
  });
}
