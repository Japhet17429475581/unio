import 'dart:io';
import 'package:path_provider/path_provider.dart';

Future<void> clearPrivateFiles() async {
  final documents = await getApplicationDocumentsDirectory();
  final notes = Directory('${documents.path}/unio_lesson_notes');
  if (await notes.exists()) await notes.delete(recursive: true);
  // The app's temporary directory may contain file-picker/photo copies.
  final temporary = await getTemporaryDirectory();
  if (await temporary.exists()) {
    await for (final entry in temporary.list(followLinks: false)) {
      await entry.delete(recursive: true);
    }
  }
}
