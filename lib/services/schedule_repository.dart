import 'package:flutter/foundation.dart';
import '../models/lesson.dart';
import '../utils/date_utils.dart';
import 'api_service.dart';
import 'teachers_service.dart';

/// A session-scoped view of the existing timetable API and on-device cache.
/// Timetable consumers reuse the same in-flight request for each week.
class ScheduleRepository extends ChangeNotifier {
  ScheduleRepository(
      {required String group, String? teacherFio, DateTime Function()? clock})
      : _clock = clock ?? DateTime.now,
        _group = group,
        _teacherFio = teacherFio;

  final DateTime Function() _clock;
  String _group;
  String? _teacherFio;
  final _weeks = <String, Future<List<Lesson>>>{};
  final _saved = <String>{};
  final _loadedAt = <String, DateTime>{};
  static const freshness = Duration(minutes: 5);
  final _loading = <String>{};
  int _generation = 0;
  bool _disposed = false;

  bool isSaved(DateTime date) => _saved.contains(isoDate(mondayOf(date)));

  Future<List<Lesson>> week(DateTime date) {
    final start = mondayOf(date);
    final key = isoDate(start);
    final previous = _weeks[key];
    if (previous != null &&
        !_loading.contains(key) &&
        _clock().difference(_loadedAt[key] ?? DateTime(1970)) >= freshness) {
      _reload(start);
      return previous;
    }
    return _weeks.putIfAbsent(key, () => _request(start));
  }

  void prefetch(DateTime date) {
    week(date).ignore();
    week(date.add(const Duration(days: 7))).ignore();
  }

  void revalidate(DateTime date) {
    for (final day in [date, date.add(const Duration(days: 7))]) {
      final start = mondayOf(day);
      final key = isoDate(start);
      if (!_loading.contains(key) &&
          _clock().difference(_loadedAt[key] ?? DateTime(1970)) >= freshness) {
        _reload(start);
      }
    }
  }

  void _reload(DateTime start) {
    final key = isoDate(start);
    final previous = _weeks[key];
    final generation = _generation;
    final request = _request(start);
    if (previous == null) _weeks[key] = request;
    request.then((lessons) {
      if (_disposed || generation != _generation) return;
      _weeks[key] = Future.value(lessons);
      notifyListeners();
    }, onError: (Object _, StackTrace __) {
      if (!_disposed && generation == _generation && previous != null) {
        _weeks[key] = previous;
        // Back off after failure while preserving the last usable timetable.
        _loadedAt[key] = _clock();
      }
    });
  }

  Future<List<Lesson>> refresh(DateTime date) {
    final start = mondayOf(date);
    // Pull-to-refresh during initial loading joins that request. Apart from
    // saving traffic, this prevents an older response overwriting the cache.
    if (_loading.contains(isoDate(start))) return week(start);
    final result = _request(start, refresh: true);
    _weeks[isoDate(start)] = result;
    // A hidden consumer must never turn a failed prefetch into an unhandled error.
    result.ignore();
    notifyListeners();
    return result;
  }

  void select({required String group, String? teacherFio}) {
    if (_group == group && _teacherFio == teacherFio) return;
    _group = group;
    _teacherFio = teacherFio;
    _generation++;
    _weeks.clear();
    _loadedAt.clear();
    _saved.clear();
    _loading.clear();
    notifyListeners();
  }

  Future<List<Lesson>> _request(DateTime start, {bool refresh = false}) async {
    final generation = _generation;
    final key = isoDate(start);
    _loading.add(key);
    try {
      bool saved = false;
      final fio = _teacherFio;
      final List<Lesson> lessons;
      if (fio == null) {
        lessons = await fetchLessons(_group,
            date: start,
            week: true,
            refresh: refresh,
            onCacheFallback: () => saved = true);
      } else {
        final result =
            await fetchTeacherSchedule(fio, date: start, refresh: refresh);
        lessons = result.lessons;
        saved = result.fromLocalCache;
      }
      if (!_disposed && generation == _generation) {
        _loadedAt[key] = _clock();
        saved ? _saved.add(key) : _saved.remove(key);
        notifyListeners();
      }
      return lessons;
    } catch (_) {
      if (generation == _generation) {
        _weeks.remove(key);
        _loadedAt[key] = _clock();
      }
      rethrow;
    } finally {
      if (generation == _generation) _loading.remove(key);
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
