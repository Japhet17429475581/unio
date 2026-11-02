import 'dart:js_interop';

@JS('unioPushSubscribe')
external JSPromise<JSString> _subscribe(JSString key);
@JS('unioPushUnsubscribe')
external JSPromise<JSAny?> _unsubscribe();
@JS('unioPushListen')
external void _listen(JSFunction callback);
@JS('unioPushSupported')
external JSBoolean _supported();
@JS('unioPushCurrent')
external JSPromise<JSString> _current();

Future<String> browserPushSubscribe(String key) async =>
    (await _subscribe(key.toJS).toDart).toDart;
Future<void> browserPushUnsubscribe() async {
  await _unsubscribe().toDart;
}

void browserPushListen(void Function(String) callback) =>
    _listen(((JSString screen) => callback(screen.toDart)).toJS);
bool browserPushSupported() => _supported().toDart;
Future<String> browserPushCurrent() async => (await _current().toDart).toDart;
