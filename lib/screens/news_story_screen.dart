import '../services/locale_service.dart';
import '../services/analytics_service.dart';
import 'package:flutter/material.dart';
import 'package:html/parser.dart' as html;
import '../models/news_article.dart';
import '../services/news_service.dart';
import '../utils/user_messages.dart';
import '../widgets/unio_loader.dart';
import 'news_detail_screen.dart';

String newsExcerpt(NewsArticle article) {
  final source = article.description?.trim().isNotEmpty == true
      ? article.description!
      : article.content ?? '';
  final plain = (html.parseFragment(source).text ?? '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  if (plain.isEmpty) return l10n.uiOpenTheFullArticleToReadThisStory;
  if (plain.length <= 360) return plain;
  final cut = plain.lastIndexOf(' ', 360);
  return '${plain.substring(0, cut > 250 ? cut : 360).trimRight()}…';
}

class NewsStoryScreen extends StatefulWidget {
  final NewsListItem item;
  const NewsStoryScreen({super.key, required this.item});
  @override
  State<NewsStoryScreen> createState() => _NewsStoryScreenState();
}

class _NewsStoryScreenState extends State<NewsStoryScreen> {
  late Future<NewsArticle> _future;
  @override
  void initState() {
    super.initState();
    analytics.track(AnalyticsEvent.newsStoryOpened);
    _future = fetchNewsArticle(widget.item.id);
  }

  @override
  Widget build(BuildContext context) {
    Localizations.localeOf(context);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
          title: Text(l10n.uiVgspuNews),
          leading: IconButton(
              tooltip: l10n.uiCloseStory,
              icon: const Icon(Icons.close_rounded),
              onPressed: () => Navigator.pop(context))),
      body: SafeArea(
          child: FutureBuilder<NewsArticle>(
              future: _future,
              builder: (context, snapshot) {
                final article = snapshot.data;
                final url = article?.imageUrl ?? widget.item.imageUrl;
                return Column(children: [
                  Expanded(
                      child: SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Center(
                              child: ConstrainedBox(
                                  constraints:
                                      const BoxConstraints(maxWidth: 600),
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        if (url?.isNotEmpty == true) ...[
                                          ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              child: AspectRatio(
                                                  aspectRatio: 1.6,
                                                  child: Image.network(url!,
                                                      webHtmlElementStrategy:
                                                          WebHtmlElementStrategy
                                                              .fallback,
                                                      fit: BoxFit.cover,
                                                      cacheWidth: 1000,
                                                      errorBuilder: (_, __, ___) => ColoredBox(
                                                          color: theme
                                                              .colorScheme
                                                              .surfaceContainer,
                                                          child: Icon(
                                                              Icons
                                                                  .article_outlined,
                                                              color: theme
                                                                  .colorScheme
                                                                  .onSurfaceVariant,
                                                              size: 40))))),
                                          const SizedBox(height: 24),
                                        ],
                                        Text(
                                            formatNewsDate(
                                                article?.publishedAt ??
                                                    widget.item.publishedAt),
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                                    color: theme.colorScheme
                                                        .onSurfaceVariant)),
                                        const SizedBox(height: 8),
                                        Text(
                                            article?.title ?? widget.item.title,
                                            style:
                                                theme.textTheme.headlineSmall),
                                        const SizedBox(height: 16),
                                        if (article != null)
                                          Text(newsExcerpt(article),
                                              style: theme.textTheme.bodyLarge
                                                  ?.copyWith(height: 1.6))
                                        else if (snapshot.hasError) ...[
                                          Text(userMessage(snapshot.error),
                                              style:
                                                  theme.textTheme.bodyMedium),
                                          TextButton(
                                              onPressed: () => setState(() =>
                                                  _future = fetchNewsArticle(
                                                      widget.item.id)),
                                              child: Text(l10n.uiTryAgain)),
                                        ] else
                                          const Center(child: UnioLoader()),
                                      ]))))),
                  Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                              onPressed: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                      builder: (_) => NewsDetailScreen(
                                          newsId: widget.item.id,
                                          initialArticle: article))),
                              icon: const Icon(Icons.arrow_forward_rounded),
                              label: Text(l10n.uiReadFullArticle)))),
                ]);
              })),
    );
  }
}
