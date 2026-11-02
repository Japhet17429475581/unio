import 'dart:io';
import 'package:path_provider/path_provider.dart';

Future<void> _queue = Future.value();

/// Foreground and Workmanager use one OS lock when comparing/saving statuses.
Future<void> withStatusLock(Future<void> Function() action) {
  final result = _queue.then((_) async {
    final directory = await getApplicationSupportDirectory();
    await directory.create(recursive: true);
    final file = await File('${directory.path}/request-status.lock')
        .open(mode: FileMode.append);
    try {
      await file.lock(FileLock.blockingExclusive);
      try {
        await action();
      } finally {
        await file.unlock();
      }
    } finally {
      await file.close();
    }
  });
  _queue = result.catchError((Object _) {});
  return result;
}
