import 'package:shared_preferences/shared_preferences.dart';
import 'legal_service.dart';

const cacheLifetime = Duration(days: 7);
const statusLifetime = Duration(days: 90);
const cacheStampPrefix = 'retention_at_';

bool isRetainedCache(String key) =>
    key.startsWith('schedule_cache_') ||
    key.startsWith('teacher_schedule_cache_') ||
    key == 'teacher_directory_v1' ||
    key == 'recent_teacher_searches_v1' ||
    key == 'news_stories_cache_v1';

Future<void> markCacheWritten(SharedPreferences prefs, String key) => prefs
    .setInt('$cacheStampPrefix$key', DateTime.now().millisecondsSinceEpoch);

Future<void> pruneLocalCaches({DateTime? now}) async {
  final clock = now ?? DateTime.now();
  final prefs = await SharedPreferences.getInstance();
  for (final key in prefs.getKeys().where(isRetainedCache).toList()) {
    final stampKey = '$cacheStampPrefix$key';
    final stamp = prefs.getInt(stampKey);
    if (stamp == null) {
      // Legacy caches receive one migration grace period; never renew it on reads.
      await prefs.setInt(stampKey, clock.millisecondsSinceEpoch);
    } else if (clock.millisecondsSinceEpoch - stamp >=
        cacheLifetime.inMilliseconds) {
      await prefs.remove(key);
      await prefs.remove(stampKey);
    }
  }
}

Future<void> pruneLocalData({DateTime? now}) async {
  final clock = now ?? DateTime.now();
  await pruneLocalCaches(now: clock);
  final values = await legalStorage.readAll();
  for (final key in values.keys.where((key) =>
      key.startsWith('request_status_') && !key.endsWith('_saved_at') && !key.endsWith('_seen_at')).toList()) {
    final stampKey = '${key}_saved_at';
    final stamp = int.tryParse(values[stampKey] ?? '');
    if (stamp == null) {
      await legalStorage.write(
          key: stampKey, value: '${clock.millisecondsSinceEpoch}');
    } else if (clock.millisecondsSinceEpoch - stamp >=
        statusLifetime.inMilliseconds) {
      await legalStorage.delete(key: key);
      await legalStorage.delete(key: stampKey);
      await legalStorage.delete(key: '${key}_seen_at');
    }
  }
}
