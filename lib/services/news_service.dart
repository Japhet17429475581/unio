import '../utils/service_messages.dart';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/news_article.dart';

class NewsApiException implements Exception {
  final String message;

  NewsApiException(this.message);

  @override
  String toString() => message;
}

Future<List<NewsListItem>> fetchNewsList(
    {int limit = 20, int offset = 0}) async {
  final uri = Uri.https(apiHost, '/api/v1/news', {
    'limit': '$limit',
    'offset': '$offset',
  });

  final http.Response response;
  try {
    response = await http.get(uri).timeout(const Duration(seconds: 30));
  } catch (_) {
    throw NewsApiException(connectionMessage);
  }

  if (response.statusCode != 200) {
    throw NewsApiException(responseMessage(response.statusCode));
  }

  final data =
      jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
  return (data['items'] as List)
      .map((e) => NewsListItem.fromJson(e as Map<String, dynamic>))
      .toList();
}

Future<NewsArticle> fetchNewsArticle(int id) async {
  final uri = Uri.https(apiHost, '/api/v1/news/$id');

  final http.Response response;
  try {
    response = await http.get(uri).timeout(const Duration(seconds: 30));
  } catch (_) {
    throw NewsApiException(connectionMessage);
  }

  if (response.statusCode == 404) {
    throw NewsApiException('Новость не найдена.');
  }
  if (response.statusCode != 200) {
    throw NewsApiException(responseMessage(response.statusCode));
  }

  final data =
      jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
  return NewsArticle.fromJson(data['item'] as Map<String, dynamic>);
}
