import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../config/api_config.dart';

/// The launcher receives only the selected public timetable, never credentials.
class HomeWidgetService {
  final MethodChannel channel;
  final bool? enabled;
  HomeWidgetService(
      {this.channel = const MethodChannel('unio/home_widget'), this.enabled});

  bool get supported =>
      enabled ?? (!kIsWeb && defaultTargetPlatform == TargetPlatform.android);
  final openSchedule = ValueNotifier<int>(0);
  int _generation = 0;
  Future<void> _operations = Future.value();

  void initialize({VoidCallback? onOpenSchedule}) {
    if (!supported) return;
    channel.setMethodCallHandler((call) async {
      if (call.method == 'openSchedule') {
        onOpenSchedule?.call();
        openSchedule.value++;
      }
    });
  }

  Future<void> _enqueue(Future<void> Function() action) {
    final next = _operations.then((_) async {
      if (!supported) return;
      try {
        await action();
      } on MissingPluginException {/* older builds/tests */}
    });
    _operations = next.catchError((Object _) {});
    return next;
  }

  Future<void> select({required String value, bool teacher = false}) {
    final generation = ++_generation;
    return _enqueue(() async {
      if (generation != _generation) return;
      await channel.invokeMethod<void>('select', {
        'kind': teacher ? 'teacher' : 'group',
        'value': value,
        'host': apiHost,
      });
    });
  }

  Future<void> clear() {
    _generation++;
    return _enqueue(() => channel.invokeMethod<void>('clear'));
  }

  Future<bool> canPin() async {
    if (!supported) return false;
    try {
      final data =
          await channel.invokeMapMethod<String, dynamic>('capabilities');
      return data?['pinSupported'] == true;
    } on MissingPluginException {
      return false;
    }
  }

  Future<bool> pin() async {
    if (!supported) return false;
    return await channel.invokeMethod<bool>('pin') ?? false;
  }
}

final homeWidget = HomeWidgetService();
