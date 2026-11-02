import 'retention_service.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/news_article.dart';
import 'news_service.dart';

/// One feed per schedule screen, shared by both week pages. Never blocks classes.
class NewsStoriesController extends ChangeNotifier {
  final Future<List<NewsListItem>> Function(int offset) _fetch;
  NewsStoriesController(
      {Future<List<NewsListItem>> Function(int offset)? fetch})
      : _fetch =
            fetch ?? ((offset) => fetchNewsList(limit: 20, offset: offset));
  static const _cacheKey = 'news_stories_cache_v1';
  List<NewsListItem> items = [];
  bool loading = false,
      hasMore = true,
      saved = false,
      _started = false,
      _disposed = false;
  Object? error;

  void start() {
    if (!_started) {
      _started = true;
      load(refresh: true);
    }
  }

  Future<void> load({bool refresh = false}) async {
    if (_disposed || loading || (!refresh && !hasMore)) return;
    loading = true;
    error = null;
    notifyListeners();
    try {
      final page = await _fetch(refresh ? 0 : items.length);
      if (_disposed) return;
      final combined = <int, NewsListItem>{
        if (!refresh)
          for (final item in items) item.id: item
      };
      final previousCount = combined.length;
      for (final item in page) {
        combined[item.id] = item;
      }
      items = combined.values.toList();
      hasMore = page.length >= 20 && items.length > previousCount;
      saved = false;
      try {
        final prefs = await SharedPreferences.getInstance();
        await markCacheWritten(prefs, _cacheKey);
        await prefs.setString(
            _cacheKey,
            jsonEncode(items
                .take(20)
                .map((item) => {
                      'id': item.id,
                      'title': item.title,
                      'image_url': item.imageUrl,
                      'source_url': item.sourceUrl,
                      'published_at': item.publishedAt?.toIso8601String(),
                    })
                .toList()));
      } catch (_) {/* A failed optional cache write does not hide news. */}
    } catch (failure) {
      if (_disposed) return;
      error = failure;
      if (items.isEmpty) {
        try {
          final prefs = await SharedPreferences.getInstance();
          await pruneLocalCaches();
          final raw = prefs.getString(_cacheKey);
          if (raw != null && !_disposed) {
            items = (jsonDecode(raw) as List)
                .map((item) =>
                    NewsListItem.fromJson(item as Map<String, dynamic>))
                .toList();
            saved = items.isNotEmpty;
          }
        } catch (_) {/* No usable cached news; the guide still works. */}
      }
    } finally {
      loading = false;
      if (!_disposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
