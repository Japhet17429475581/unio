const _months = [
  'января', 'февраля', 'марта', 'апреля', 'мая', 'июня',
  'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря',
];
 
String formatNewsDate(DateTime? date) {
  if (date == null) return '';
  final now = DateTime.now();
  final yearPart = date.year != now.year ? ' ${date.year}' : '';
  return '${date.day} ${_months[date.month - 1]}$yearPart';
}
 
class NewsListItem {
  final int id;
  final String title;
  final String? imageUrl;
  final String sourceUrl;
  final DateTime? publishedAt;
 
  const NewsListItem({
    required this.id,
    required this.title,
    this.imageUrl,
    required this.sourceUrl,
    this.publishedAt,
  });
 
  factory NewsListItem.fromJson(Map<String, dynamic> json) => NewsListItem(
        id: (json['id'] as num).toInt(),
        title: (json['title'] ?? '').toString(),
        imageUrl: json['image_url'] as String?,
        sourceUrl: (json['source_url'] ?? '').toString(),
        publishedAt: DateTime.tryParse((json['published_at'] ?? '').toString()),
      );
}
 
class NewsArticle {
  final int id;
  final String title;
  final String? description;
  final String? content;
  final String? imageUrl;
  final String sourceUrl;
  final DateTime? publishedAt;
 
  const NewsArticle({
    required this.id,
    required this.title,
    this.description,
    this.content,
    this.imageUrl,
    required this.sourceUrl,
    this.publishedAt,
  });
 
  factory NewsArticle.fromJson(Map<String, dynamic> json) => NewsArticle(
        id: (json['id'] as num).toInt(),
        title: (json['title'] ?? '').toString(),
        description: json['description'] as String?,
        content: json['content'] as String?,
        imageUrl: json['image_url'] as String?,
        sourceUrl: (json['source_url'] ?? '').toString(),
        publishedAt: DateTime.tryParse((json['published_at'] ?? '').toString()),
      );
}