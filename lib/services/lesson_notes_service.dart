import 'locale_service.dart';
import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:image_picker/image_picker.dart';

import '../models/lesson.dart';
import '../models/lesson_note.dart';
import '../utils/date_utils.dart';
import 'notes_storage/notes_storage.dart';
import 'notes_storage/notes_storage_io.dart'
    if (dart.library.js_interop) 'notes_storage/notes_storage_web.dart';
import 'secure_storage_service.dart';

class NotesException implements Exception {
  final String message;
  const NotesException(this.message);
  @override
  String toString() => message;
}

/// No HTTP or Redis: text and copied image bytes never leave the device.
class LessonNotesService {
  static const maxPhotoBytes = 10 * 1024 * 1024;
  static const maxTextLength = 20000;
  final NotesStorage storage;
  final String _owner;

  LessonNotesService({required this.storage, required String owner})
      : _owner = _hash(owner);

  static String _hash(String value) =>
      sha256.convert(utf8.encode(value)).toString();

  static Future<LessonNotesService> forCurrentStudent() async {
    final session = await loadSession();
    if (session == null) {
      throw NotesException(
          l10n.notesSignIn);
    }
    // A portal login survives token rotation. Guest notes belong to that guest
    // session, not to everyone who happens to select the same group.
    final owner = session.isPortalMode && session.portalLogin != null
        ? 'portal:${session.portalLogin!.trim().toLowerCase()}'
        : 'guest:${session.accountToken}';
    return LessonNotesService(storage: await openNotesStorage(), owner: owner);
  }

  String keyFor(String group, Lesson lesson) {
    if (lesson.date == null) {
      throw NotesException(
          l10n.notesNoDate);
    }
    String normalize(String value) =>
        value.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();
    return '${_owner}_${_hash(jsonEncode([
          normalize(group),
          isoDate(lesson.date!),
          lesson.start,
          normalize(lesson.subject),
          lesson.type ?? '',
        ]))}';
  }

  void _checkKey(String key) {
    if (!RegExp('^${_owner}_[a-f0-9]{64}\$').hasMatch(key)) {
      throw NotesException(l10n.notesWrongOwner);
    }
  }

  Future<Map<String, dynamic>?> _metadata(String key) async {
    _checkKey(key);
    final data = await storage.read(key);
    if (data == null) return null;
    final json = jsonDecode(utf8.decode(data)) as Map<String, dynamic>;
    if (json['version'] != 1 ||
        json['text'] is! String ||
        json['photos'] is! List) {
      throw NotesException(l10n.notesReadFailed);
    }
    for (final id in json['photos'] as List) {
      if (id is! String || !RegExp(r'^[a-f0-9]{64}$').hasMatch(id)) {
        throw NotesException(l10n.notesPhotosFailed);
      }
    }
    return json;
  }

  Future<LessonNote> load(String key) async {
    final json = await _metadata(key);
    if (json == null) return const LessonNote();
    final photos = <NotePhoto>[];
    for (final id in (json['photos'] as List).cast<String>()) {
      photos.add(
          NotePhoto(id: id, bytes: await storage.read('${key}_photo_$id')));
    }
    return LessonNote(text: json['text'] as String, photos: photos);
  }

  Future<NotePhoto> importPhoto(XFile file) async {
    if (await file.length() > maxPhotoBytes) {
      throw NotesException(
          l10n.photoTooLarge);
    }
    final bytes = await file.readAsBytes();
    if (bytes.isEmpty || bytes.length > maxPhotoBytes) {
      throw NotesException(
          l10n.photoAddFailed);
    }
    return NotePhoto(id: sha256.convert(bytes).toString(), bytes: bytes);
  }

  Future<void> save(String key, LessonNote note) async {
    _checkKey(key);
    if (note.text.length > maxTextLength) {
      throw NotesException(l10n.notesTextLimit);
    }
    final previous = await _metadata(key);
    final oldIds =
        ((previous?['photos'] as List?) ?? []).cast<String>().toSet();
    final ids = <String>{};
    final added = <String>[];
    try {
      for (final photo in note.photos) {
        if (!RegExp(r'^[a-f0-9]{64}$').hasMatch(photo.id)) {
          throw NotesException(l10n.photoReadFailed);
        }
        ids.add(photo.id);
        if (oldIds.contains(photo.id)) continue;
        final bytes = photo.bytes;
        if (bytes == null ||
            bytes.isEmpty ||
            bytes.length > maxPhotoBytes ||
            sha256.convert(bytes).toString() != photo.id) {
          throw NotesException(
              l10n.photoUnavailable);
        }
        final photoKey = '${key}_photo_${photo.id}';
        added.add(photoKey);
        await storage.write(photoKey, bytes);
      }
      // Publish metadata only after every new photograph is durable.
      if (note.isEmpty) {
        await storage.delete(key);
      } else {
        await storage.write(
            key,
            Uint8List.fromList(utf8.encode(jsonEncode({
              'version': 1,
              'text': note.text,
              'photos': ids.toList(),
            }))));
      }
    } catch (_) {
      for (final photoKey in added) {
        try {
          await storage.delete(photoKey);
        } catch (_) {}
      }
      rethrow;
    }
    // Cleanup cannot turn a successful commit into an apparent save failure.
    for (final id in oldIds.difference(ids)) {
      try {
        await storage.delete('${key}_photo_$id');
      } catch (_) {}
    }
  }

  Future<void> preparePicker(String key) async {
    _checkKey(key);
    await storage.write(
        '${_owner}_pending', Uint8List.fromList(utf8.encode(key)));
  }

  Future<void> finishPicker() => storage.delete('${_owner}_pending');

  /// Android can kill the activity while the system photo picker is open.
  Future<bool> recoverPhotos(ImagePicker picker) async {
    final pending = await storage.read('${_owner}_pending');
    if (pending == null) return false;
    final key = utf8.decode(pending);
    _checkKey(key);
    final result = await picker.retrieveLostData();
    if (result.exception != null) {
      await finishPicker();
      throw NotesException(
          l10n.photosRecoveryFailed);
    }
    final files = result.files ?? [];
    if (files.isEmpty) {
      await finishPicker();
      return false;
    }
    final note = await load(key);
    final photos = [...note.photos];
    for (final file in files) {
      final photo = await importPhoto(file);
      if (!photos.any((existing) => existing.id == photo.id)) photos.add(photo);
    }
    await save(key, LessonNote(text: note.text, photos: photos));
    await finishPicker();
    return true;
  }
}
