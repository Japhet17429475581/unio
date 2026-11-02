Future<String> browserPushSubscribe(String key) async => '';
Future<void> browserPushUnsubscribe() async {}
void browserPushListen(void Function(String) callback) {}
bool browserPushSupported() => false;
Future<String> browserPushCurrent() async => '';
