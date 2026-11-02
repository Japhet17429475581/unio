import 'dart:typed_data';

import 'package:idb_shim/idb_browser.dart';

import 'notes_storage.dart';
import '../local_write_guard.dart';

Future<Database>? _database;

Future<NotesStorage> openNotesStorage() async {
  try {
    final db = await (_database ??= idbFactoryBrowser.open(
      'unio_lesson_notes',
      version: 1,
      onUpgradeNeeded: (event) => event.database.createObjectStore('files'),
    ));
    return BrowserNotesStorage(db);
  } catch (_) {
    _database = null;
    rethrow;
  }
}

class BrowserNotesStorage implements NotesStorage {
  final Database database;

  BrowserNotesStorage(this.database);

  @override
  Future<Uint8List?> read(String key) async {
    final transaction = database.transaction('files', idbModeReadOnly);
    final value = await transaction.objectStore('files').getObject(key);
    await transaction.completed;
    return value == null
        ? null
        : Uint8List.fromList((value as List).cast<int>());
  }

  @override
  Future<void> write(String key, Uint8List bytes) => privateWrite(() async {
    final transaction = database.transaction('files', idbModeReadWrite);
    await transaction.objectStore('files').put(bytes, key);
    await transaction.completed;
  });

  @override
  Future<void> delete(String key) async {
    final transaction = database.transaction('files', idbModeReadWrite);
    await transaction.objectStore('files').delete(key);
    await transaction.completed;
  }
}
