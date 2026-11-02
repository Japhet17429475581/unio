import 'retention_service.dart';
import '../utils/service_messages.dart';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';
import '../models/teacher_schedule.dart';
import '../models/teacher_directory.dart';
import '../models/lesson.dart';
import '../utils/date_utils.dart';
import 'api_service.dart';

const teacherFioPreferenceKey = 'teacher_fio';

/// Только клиент готового Teacher API: парсинг портала остаётся на сервере.
Future<Map<String, dynamic>> _teacherRequest(
  String path, {
  Map<String, String>? query,
  Map<String, String>? body,
}) async {
  final uri = Uri.https(apiHost, '/api/v1/teachers/$path', query);
  try {
    final response = await (body == null
            ? http.get(uri)
            : http.post(
                uri,
                headers: {'Content-Type': 'application/json; charset=utf-8'},
                body: jsonEncode(body),
              ))
        .timeout(const Duration(seconds: 15));
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (response.statusCode != 200) {
      throw ApiException(responseMessage(response.statusCode));
    }
    if (decoded is! Map<String, dynamic> || decoded['success'] != true) {
      throw ApiException(unavailableMessage);
    }
    return decoded;
  } on ApiException {
    rethrow;
  } on FormatException {
    throw ApiException(unavailableMessage);
  } catch (_) {
    throw ApiException(
        'Не удалось подключиться к серверу. Попробуйте ещё раз.');
  }
}

Future<TeacherSchedule> fetchTeacherSchedule(
  String fio, {
  required DateTime date,
  bool refresh = false,
}) async {
  final key = 'teacher_schedule_cache_${fio.trim()}_${isoDate(date)}_week';
  try {
    final data = await _teacherRequest('schedule', query: {
      'fio': fio,
      'date': isoDate(date),
      'week': 'true',
      if (refresh) 'force_refresh': 'true',
    });
    final schedule = TeacherSchedule.fromJson(data);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, jsonEncode(data));
      await markCacheWritten(prefs, key);
    } catch (_) {
      // Ошибка записи кэша не мешает показать полученное расписание.
    }
    return schedule;
  } catch (error) {
    try {
      final prefs = await SharedPreferences.getInstance();
      await pruneLocalCaches();
      final cached = prefs.getString(key);
      if (cached != null) {
        final saved = TeacherSchedule.fromJson(
            jsonDecode(cached) as Map<String, dynamic>,
            fromLocalCache: true);
        if (saved.lessons.isNotEmpty) return saved;
      }
    } catch (_) {
      // При повреждённом кэше показываем ошибку исходного запроса.
    }
    if (error is ApiException) rethrow;
    throw ApiException('Не удалось прочитать расписание преподавателя.');
  }
}

const _directoryCacheKey = 'teacher_directory_v1';
const _recentTeachersKey = 'recent_teacher_searches_v1';

Future<TeacherDirectory> fetchTeacherDirectory() async {
  try {
    final data = await _teacherRequest('directory');
    final directory = TeacherDirectory.fromJson(data);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_directoryCacheKey, jsonEncode(data));
      await markCacheWritten(prefs, _directoryCacheKey);
    } catch (_) {}
    return directory;
  } catch (error) {
    try {
      final prefs = await SharedPreferences.getInstance();
      await pruneLocalCaches();
      final cached = prefs.getString(_directoryCacheKey);
      if (cached != null)
        return TeacherDirectory.fromJson(
            jsonDecode(cached) as Map<String, dynamic>,
            isSaved: true);
    } catch (_) {}
    if (error is ApiException) rethrow;
    throw ApiException('Не удалось прочитать справочник преподавателей.');
  }
}

Future<List<TeacherEntry>> loadRecentTeachers() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await pruneLocalCaches();
    final raw = prefs.getString(_recentTeachersKey);
    if (raw == null) return [];
    return (jsonDecode(raw) as List)
        .map((item) => TeacherEntry.fromJson(item as Map<String, dynamic>))
        .take(6)
        .toList();
  } catch (_) {
    return [];
  }
}

Future<void> saveRecentTeachers(List<TeacherEntry> entries) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await markCacheWritten(prefs, _recentTeachersKey);
    await prefs.setString(_recentTeachersKey,
        jsonEncode(entries.take(6).map((entry) => entry.toJson()).toList()));
  } catch (_) {}
}

/// Joint portal entries are loaded alongside the teacher's individual schedule.
Future<TeacherLookupSchedule> fetchTeacherLookupSchedule(TeacherEntry teacher,
    {required DateTime date, bool refresh = false}) async {
  final results = await Future.wait(teacher.scheduleFios.map((fio) async {
    try {
      return await fetchTeacherSchedule(fio,
          date: mondayOf(date), refresh: refresh);
    } catch (_) {
      return null;
    }
  }));
  final loaded = results.whereType<TeacherSchedule>().toList();
  if (loaded.isEmpty)
    throw ApiException(
        'Не удалось загрузить расписание преподавателя. Проверьте соединение и повторите.');
  final unique = <String, Lesson>{};
  for (final result in loaded) {
    for (final lesson in result.lessons) {
      final key = jsonEncode([
        lesson.date == null ? null : isoDate(lesson.date!),
        lesson.start,
        lesson.end,
        lesson.subject,
        lesson.type,
        lesson.room,
        lesson.group
      ]);
      unique[key] = lesson;
    }
  }
  final lessons = unique.values.toList()..sort(compareLessons);
  return TeacherLookupSchedule(
      lessons: lessons,
      isSaved: loaded.any((s) => s.fromLocalCache),
      isPartial: loaded.length != results.length);
}

/// Результаты поиска аудиторий не подменяем локальным кэшем.
Future<FreeRooms> fetchFreeRooms({
  required DateTime date,
  required String start,
  required String end,
}) async {
  final data = await _teacherRequest('free-rooms', query: {
    'date': isoDate(date),
    'start': start,
    'end': end,
  });
  try {
    return FreeRooms.fromJson(data);
  } catch (_) {
    throw ApiException('Не удалось прочитать список аудиторий.');
  }
}
