import '../models/portal_progress.dart';
import 'portal_service.dart';

/// Shared by grades and chat for one HomeScreen/account lifetime, in RAM only.
class PortalGradesRepository {
  final Future<PortalProgressResult> Function() _loader;
  final DateTime Function() _clock;
  PortalProgressResult? _value;
  Future<PortalProgressResult>? _pending;
  DateTime? _loadedAt;
  int _generation = 0;
  PortalGradesRepository(
      {Future<PortalProgressResult> Function()? loader,
      DateTime Function()? clock})
      : _loader = loader ?? fetchPortalGrades,
        _clock = clock ?? DateTime.now;

  Future<PortalProgressResult> load({bool refresh = false}) {
    if (refresh) {
      _value = null;
      _loadedAt = null;
    }
    if (_pending != null) return _pending!;
    if (!refresh &&
        _value != null &&
        _loadedAt != null &&
        _clock().difference(_loadedAt!) < const Duration(minutes: 2)) {
      return Future.value(_value);
    }
    final generation = _generation;
    final future = _loader().then((value) {
      if (generation == _generation && value.success) {
        _value = value;
        _loadedAt = _clock();
      }
      return value;
    });
    _pending = future;
    // Attach both branches so a failed request clears the in-flight reference
    // without creating an unhandled error in a discarded whenComplete future.
    future.then((_) {
      if (generation == _generation) _pending = null;
    }, onError: (Object _, StackTrace __) {
      if (generation == _generation) _pending = null;
    });
    return future;
  }

  void clear() {
    _generation++;
    _value = null;
    _loadedAt = null;
    _pending = null;
  }
}
