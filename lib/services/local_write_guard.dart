bool _blocked = false;
Future<void> _writes = Future.value();

/// Logout/deletion drains an in-flight note write and rejects subsequent writes
/// from a disposed editor or a file picker returning late.
Future<void> privateWrite(Future<void> Function() action) {
  final next = _writes.then((_) async {
    if (_blocked) throw StateError('session_closed');
    await action();
  });
  _writes = next.catchError((Object _) {});
  return next;
}

Future<void> blockPrivateWrites() {
  _blocked = true;
  return _writes;
}

void allowPrivateWrites() => _blocked = false;
