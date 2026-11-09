import 'package:flutter/foundation.dart';
import '../models/lesson.dart';
import '../utils/date_utils.dart';
import 'api_service.dart';
import 'teachers_service.dart';

/// A session-scoped view of the existing timetable API and on-device cache.
/// Timetable consumers reuse the same in-flight request for each week.
class ScheduleRepository extends ChangeNotifier {
  ScheduleRepository({required String group, String? teacherFio})
      : _group = group,
        _teacherFio = teacherFio;

  String _group;
  String? _teacherFio;
  final _weeks = <String, Future<List<Lesson>>>{};
  final _saved = <String>{};
  final _loading = <String>{};
  int _generation = 0;
  bool _disposed = false;

  bool isSaved(DateTime date) => _saved.contains(isoDate(mondayOf(date)));

  Future<List<Lesson>> week(DateTime date) {
    final start = mondayOf(date);
    return _weeks.putIfAbsent(isoDate(start), () => _request(start));
  }

  void prefetch(DateTime date) {
    week(date).ignore();
    week(date.add(const Duration(days: 7))).ignore();
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
        saved ? _saved.add(key) : _saved.remove(key);
        notifyListeners();
      }
      return lessons;
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
