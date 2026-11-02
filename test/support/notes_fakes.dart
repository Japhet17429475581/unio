import 'dart:convert';
import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';
import 'package:unio_app/models/lesson.dart';
import 'package:unio_app/services/notes_storage/notes_storage.dart';

final photoBytes = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+aP1sAAAAASUVORK5CYII=');

Lesson testLesson({int day = 7, String start = '09:00', String room = '101'}) =>
    Lesson(
      date: DateTime(2026, 10, day),
      start: start,
      end: '10:30',
      subject: 'Математика',
      type: 'lecture',
      teacher: 'Иванов И. И.',
      room: room,
    );

class MemoryNotesStorage implements NotesStorage {
  final files = <String, Uint8List>{};
  String? failOnWrite;

  @override
  Future<Uint8List?> read(String key) async => files[key];
  @override
  Future<void> write(String key, Uint8List bytes) async {
    if (key == failOnWrite) throw StateError('Disk full');
    files[key] = Uint8List.fromList(bytes);
  }

  @override
  Future<void> delete(String key) async {
    files.remove(key);
  }
}

class FakeNotePicker extends ImagePicker {
  List<XFile> photos = [];
  List<XFile> lostPhotos = [];

  @override
  Future<List<XFile>> pickMultiImage({
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    int? limit,
    bool requestFullMetadata = true,
  }) async =>
      photos;

  @override
  Future<LostDataResponse> retrieveLostData() async =>
      LostDataResponse(files: lostPhotos);
}
