import 'retention_service.dart';
import '../utils/service_messages.dart';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';
import '../models/lesson.dart';
import '../utils/date_utils.dart';

class ApiException implements Exception {
  final String message;

  ApiException(this.message);

  @override
  String toString() => message;
}

/// Получает расписание.
///
/// Логика:
/// 1. Пытаемся получить свежее расписание с сервера.
/// 2. При успешном ответе сохраняем его локально.
/// 3. Если интернета нет или сервер недоступен —
///    возвращаем последнее сохранённое расписание.
///
/// [date] — день (или любой день нужной недели, если [week] = true).
/// [refresh] — принудительно запросить свежие данные с сервера.
Future<List<Lesson>> fetchLessons(
  String group, {
  required DateTime date,
  bool week = false,
  bool refresh = false,
  bool allowCacheFallback = true,
  void Function()? onCacheFallback,
}) async {
  final cacheKey = _cacheKey(
    group: group,
    date: date,
    week: week,
  );

  final uri = Uri.https(
    apiHost,
    '/api/v1/schedule',
    {
      'group': group,
      'date': isoDate(date),
      if (week) 'week': 'true',
      if (refresh) 'force_refresh': 'true',
    },
  );

  try {
    final response = await http.get(uri).timeout(const Duration(seconds: 10));

    final body = utf8.decode(response.bodyBytes);

    if (response.statusCode != 200) {
      throw ApiException(
        _serverErrorMessage(response, body),
      );
    }

    final data = jsonDecode(body) as Map<String, dynamic>;

    final lessonsJson = data['lessons'];

    if (lessonsJson is! List) {
      throw ApiException(
          'Не удалось загрузить расписание. Попробуйте чуть позже.');
    }

    final lessons = lessonsJson
        .map(
          (item) => Lesson.fromJson(
            item as Map<String, dynamic>,
          ),
        )
        .toList();

    // Сохраняем успешный ответ на телефоне.
    await _saveCache(
      cacheKey,
      body,
    );

    return lessons;
  } catch (e) {
    // Если запрос завершился нашей ApiException —
    // всё равно пробуем локальный кэш.
    final cached = allowCacheFallback ? await _loadCache(cacheKey) : null;

    if (cached != null) {
      final saved = _parseLessons(cached);
      // An old empty response cannot establish that the week has no lessons
      // while the current request is failing.
      if (saved.isNotEmpty) {
        onCacheFallback?.call();
        return saved;
      }
    }

    if (e is ApiException) {
      throw e;
    }

    throw ApiException(
      'Нет подключения к интернету, а сохранённого расписания ещё нет.',
    );
  }
}

/// Уникальный ключ для конкретной группы + даты + режима недели.
String _cacheKey({
  required String group,
  required DateTime date,
  required bool week,
}) {
  final mode = week ? 'week' : 'day';

  return 'schedule_cache_${group.trim().toUpperCase()}_${isoDate(date)}_$mode';
}

/// Сохраняет JSON расписания локально.
Future<void> _saveCache(
  String key,
  String json,
) async {
  try {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(key, json);
    await markCacheWritten(prefs, key);
  } catch (_) {
    // Ошибка локального кэша не должна ломать расписание,
    // если сервер успешно его отдал.
  }
}

/// Читает расписание из локального кэша.
Future<String?> _loadCache(
  String key,
) async {
  try {
    final prefs = await SharedPreferences.getInstance();

    await pruneLocalCaches();
    return prefs.getString(key);
  } catch (_) {
    return null;
  }
}

/// Преобразует сохранённый JSON обратно в список занятий.
List<Lesson> _parseLessons(String body) {
  try {
    final data = jsonDecode(body) as Map<String, dynamic>;
    final lessonsJson = data['lessons'];

    if (lessonsJson is! List) {
      throw const FormatException();
    }

    return lessonsJson
        .map(
          (item) => Lesson.fromJson(
            item as Map<String, dynamic>,
          ),
        )
        .toList();
  } catch (_) {
    throw ApiException(
      'Сохранённое расписание повреждено.',
    );
  }
}

/// Красивое сообщение об ошибке сервера.
String _serverErrorMessage(
  http.Response response,
  String body,
) {
  return responseMessage(response.statusCode);
}
