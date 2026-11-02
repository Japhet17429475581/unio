import '../services/locale_service.dart';
import '../services/analytics_service.dart';
import '../utils/user_messages.dart';
import 'package:flutter/material.dart';

import '../widgets/unio_loader.dart';

import '../models/news_article.dart';
import '../services/news_service.dart';
import '../widgets/message.dart';
import '../widgets/feature_header.dart';

class NewsDetailScreen extends StatefulWidget {
  final int newsId;
  final NewsArticle? initialArticle;

  const NewsDetailScreen({
    super.key,
    required this.newsId,
    this.initialArticle,
  });

  @override
  State<NewsDetailScreen> createState() => _NewsDetailScreenState();
}

class _NewsDetailScreenState extends State<NewsDetailScreen> {
  late Future<NewsArticle> _future;

  @override
  void initState() {
    super.initState();
    analytics.screen(AnalyticsScreen.newsArticle);
    analytics.track(AnalyticsEvent.newsFullOpened);
    _future = widget.initialArticle?.id == widget.newsId
        ? Future.value(widget.initialArticle!)
        : fetchNewsArticle(widget.newsId);
  }

  void _retry() {
    setState(() {
      _future = fetchNewsArticle(widget.newsId);
    });
  }

  @override
  Widget build(BuildContext context) {
    Localizations.localeOf(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.uiUniversityNews)),
      body: FutureBuilder<NewsArticle>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(
              child: UnioLoader(),
            );
          }

          if (snapshot.hasError) {
            final error = snapshot.error;

            return Message(
              icon: Icons.cloud_off_rounded,
              title: l10n.uiCouldNotLoadThisArticle,
              text: userMessage(error),
              actionLabel: l10n.uiTryAgain,
              onAction: _retry,
            );
          }

          final article = snapshot.data;

          if (article == null) {
            return Message(
              icon: Icons.article_outlined,
              title: l10n.uiArticleNotFound,
              text: l10n.uiThisArticleIsNoLongerAvailable,
            );
          }

          final content = article.content?.trim() ?? '';

          final paragraphs = content
              .split(RegExp(r'\n\s*\n'))
              .map((p) => p.trim())
              .where((p) => p.isNotEmpty)
              .toList();

          final description = article.description?.trim() ?? '';

          final hasImage =
              article.imageUrl != null && article.imageUrl!.trim().isNotEmpty;

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              if (hasImage)
                SliverToBoxAdapter(
                  child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: _DetailImage(url: article.imageUrl!))),
                ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  20,
                  22,
                  20,
                  40,
                ),
                sliver: SliverToBoxAdapter(
                  child: FeatureReveal(
                      child: Align(
                          alignment: Alignment.topCenter,
                          child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 680),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (article.publishedAt != null)
                                    _ArticleMeta(
                                      date: article.publishedAt!,
                                    ),
                                  const SizedBox(height: 12),
                                  Text(
                                    article.title,
                                    style:
                                        theme.textTheme.headlineSmall?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      height: 1.25,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 22),
                                  if (paragraphs.isEmpty)
                                    Text(
                                      description,
                                      style:
                                          theme.textTheme.bodyLarge?.copyWith(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w400,
                                        height: 1.65,
                                      ),
                                    )
                                  else
                                    ...paragraphs.map(
                                      (paragraph) => Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 16,
                                        ),
                                        child: Text(
                                          paragraph,
                                          style: theme.textTheme.bodyLarge
                                              ?.copyWith(
                                            fontSize: 17,
                                            fontWeight: FontWeight.w400,
                                            height: 1.65,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              )))),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ArticleMeta extends StatelessWidget {
  final DateTime date;

  const _ArticleMeta({
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    Localizations.localeOf(context);
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(
          Icons.schedule_rounded,
          size: 17,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(width: 7),
        Expanded(
            child: Text(
          _formatDateTime(date),
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        )),
      ],
    );
  }

  String _formatDateTime(DateTime date) {
    final months = [
      l10n.uiJanuary,
      l10n.uiFebruary,
      l10n.uiMarch,
      l10n.uiApril,
      l10n.uiMay,
      l10n.uiJune,
      l10n.uiJuly,
      l10n.uiAugust,
      l10n.uiSeptember,
      l10n.uiOctober,
      l10n.uiNovember,
      l10n.uiDecember,
    ];

    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '${date.day} ${months[date.month - 1]} '
        '${date.year} · $hour:$minute';
  }
}

class _DetailImage extends StatelessWidget {
  final String url;

  const _DetailImage({
    required this.url,
  });

  @override
  Widget build(BuildContext context) {
    Localizations.localeOf(context);
    return Image.network(
      url,
      webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
      cacheWidth: 1400,
      fit: BoxFit.cover,
      filterQuality: FilterQuality.medium,
      loadingBuilder: (
        context,
        child,
        loadingProgress,
      ) {
        if (loadingProgress == null) {
          return child;
        }

        return const AspectRatio(
          aspectRatio: 16 / 9,
          child: Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: UnioLoader(),
            ),
          ),
        );
      },
      errorBuilder: (_, __, ___) {
        return const SizedBox.shrink();
      },
    );
  }
}
