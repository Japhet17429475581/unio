import 'dart:typed_data';

/// Device-local bytes. Writes replace one record atomically.
abstract class NotesStorage {
  Future<Uint8List?> read(String key);
  Future<void> write(String key, Uint8List bytes);
  Future<void> delete(String key);
}
