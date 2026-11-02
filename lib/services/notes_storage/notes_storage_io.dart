import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

import 'notes_storage.dart';
import '../local_write_guard.dart';

Future<NotesStorage> openNotesStorage() async {
  final documents = await getApplicationDocumentsDirectory();
  return FileNotesStorage(Directory('${documents.path}/unio_lesson_notes'));
}

class FileNotesStorage implements NotesStorage {
  final Directory directory;

  FileNotesStorage(this.directory);

  File _file(String key) {
    if (!RegExp(r'^[a-z0-9_]+$').hasMatch(key)) {
      throw ArgumentError('Invalid local note key');
    }
    return File('${directory.path}/$key');
  }

  @override
  Future<Uint8List?> read(String key) async {
    final file = _file(key);
    if (!await file.exists()) return null;
    return file.readAsBytes();
  }

  @override
  Future<void> write(String key, Uint8List bytes) => privateWrite(() async {
    final target = _file(key);
    await directory.create(recursive: true);
    final temporary = File('${target.path}.tmp');
    try {
      await temporary.writeAsBytes(bytes, flush: true);
      await temporary.rename(target.path);
    } finally {
      if (await temporary.exists()) await temporary.delete();
    }
  });

  @override
  Future<void> delete(String key) async {
    final file = _file(key);
    if (await file.exists()) await file.delete();
  }
}
