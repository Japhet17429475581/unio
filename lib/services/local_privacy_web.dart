import 'package:idb_shim/idb_browser.dart';
import 'notes_storage/notes_storage_web.dart';

Future<void> clearPrivateFiles() async {
  final storage = await openNotesStorage() as BrowserNotesStorage;
  final tx = storage.database.transaction('files', idbModeReadWrite);
  await tx.objectStore('files').clear();
  await tx.completed;
}
