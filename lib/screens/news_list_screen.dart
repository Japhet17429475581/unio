import '../services/locale_service.dart';
import '../widgets/feature_header.dart';
import '../widgets/launch_list_entrance.dart';
import '../widgets/unio_card.dart';
import '../services/analytics_service.dart';
import '../utils/user_messages.dart';
import 'package:flutter/material.dart';

import '../widgets/unio_loader.dart';

import '../models/news_article.dart';
import '../services/news_service.dart';
import '../widgets/message.dart';
import '../widgets/tap_feedback.dart';
import 'news_detail_screen.dart';

const _newsLimit = 20;

class NewsListScreen extends StatefulWidget {
  const NewsListScreen({super.key});

  @override
  State<NewsListScreen> createState() => _NewsListScreenState();
}

class _NewsListScreenState extends State<NewsListScreen> {
  List<NewsListItem> _items = [];

  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    analytics.screen(AnalyticsScreen.news);
    _loadNews();
  }

  Future<void> _loadNews() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final items = await fetchNewsList(
        limit: _newsLimit,
        offset: 0,
      );

      if (!mounted) return;

      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = userMessage(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Localizations.localeOf(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.uiNews,
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Builder(
        builder: (context) {
          if (_loading) {
            return const Center(
              child: UnioLoader(),
            );
          }

          if (_error != null) {
            return Message(
              icon: Icons.cloud_off_rounded,
              title: l10n.uiCouldNotLoadNews,
              text: _error!,
              actionLabel: l10n.uiTryAgain,
              onAction: _loadNews,
            );
          }

          if (_items.isEmpty) {
            return Message(
              icon: Icons.article_outlined,
              title: l10n.uiNoNewsYet,
              text: l10n.uiCheckBackALittleLater,
            );
          }

          return UnioRefreshIndicator(
            onRefresh: _loadNews,
            child: LaunchListEntrance(
                child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.fromLTRB(
                20,
                8,
                20,
                32,
              ),
              itemCount: _items.length + 1,
              itemBuilder: (context, position) {
                if (position == 0)
                  return Padding(
                      padding: EdgeInsets.only(top: 8, bottom: 24),
                      child: FeatureHeader(
                          compact: true,
                          eyebrow: l10n.uiUnioNews,
                          title: l10n.uiOnCampus,
                          description: l10n.uiUniversityEventsAndAnnouncements,
                          icon: Icons.article_outlined));
                final index = position - 1;
                final item = _items[index];

                final previous = index > 0 ? _items[index - 1] : null;

                final isNewDay = _isDifferentDay(
                  previous?.publishedAt,
                  item.publishedAt,
                );

                return LaunchListItem(
                    key: ValueKey('news-entrance-${item.id}'),
                    index: index,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isNewDay)
                          _DateHeader(
                            date: item.publishedAt,
                            isFirst: index == 0,
                          ),
                        _NewsCard(
                          key: ValueKey(item.id),
                          item: item,
                          isLatest: index == 0,
                        ),
                        const SizedBox(height: 12),
                      ],
                    ));
              },
            )),
          );
        },
      ),
    );
  }

  bool _isDifferentDay(
    DateTime? previous,
    DateTime? current,
  ) {
    if (current == null) {
      return previous != null;
    }

    if (previous == null) {
      return true;
    }

    return previous.year != current.year ||
        previous.month != current.month ||
        previous.day != current.day;
  }
}

class _DateHeader extends StatelessWidget {
  final DateTime? date;
  final bool isFirst;

  const _DateHeader({
    required this.date,
    required this.isFirst,
  });

  @override
  Widget build(BuildContext context) {
    Localizations.localeOf(context);
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        top: isFirst ? 8 : 24,
        bottom: 11,
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 21,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
              child: Text(
            _formatDate(date),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
          )),
          const SizedBox(width: 12),
          Expanded(
            child: Divider(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) {
      return l10n.uiNoDate;
    }

    final now = DateTime.now();

    final today = DateTime(
      now.year,
      now.month,
      now.day,
    );

    final target = DateTime(
      date.year,
      date.month,
      date.day,
    );

    final difference = today.difference(target).inDays;

    if (difference == 0) {
      return l10n.uiToday;
    }

    if (difference == 1) {
      return l10n.uiYesterday;
    }

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

    if (date.year == now.year) {
      return '${date.day} ${months[date.month - 1]}';
    }

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

class _NewsCard extends StatelessWidget {
  final NewsListItem item;
  final bool isLatest;
  const _NewsCard({super.key, required this.item, required this.isLatest});

  @override
  Widget build(BuildContext context) {
    Localizations.localeOf(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final hasImage = item.imageUrl?.trim().isNotEmpty == true;
    void openArticle() {
      tapFeedback();
      Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => NewsDetailScreen(newsId: item.id)));
    }

    return Semantics(
      button: true,
      onTap: openArticle,
      label: item.title,
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: openArticle,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: unioCardDecoration(context),
            child: LayoutBuilder(builder: (context, constraints) {
              final stacked = constraints.maxWidth < 280 ||
                  MediaQuery.textScalerOf(context).scale(16) > 23;
              final text = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(spacing: 10, runSpacing: 4, children: [
                      if (isLatest)
                        Text(l10n.uiLatest,
                            style: theme.textTheme.labelSmall?.copyWith(
                                color: colors.primary, letterSpacing: .6)),
                      if (item.publishedAt != null)
                        Text(
                            '${item.publishedAt!.hour.toString().padLeft(2, '0')}:${item.publishedAt!.minute.toString().padLeft(2, '0')}',
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: colors.onSurfaceVariant)),
                    ]),
                    const SizedBox(height: 8),
                    Text(item.title,
                        maxLines: stacked ? null : 4,
                        overflow: stacked ? null : TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium
                            ?.copyWith(height: 1.35)),
                  ]);
              if (!hasImage) return text;
              final thumbnail = ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                      width: 88,
                      height: 88,
                      child: _NewsImage(url: item.imageUrl!)));
              if (stacked)
                return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [text, const SizedBox(height: 12), thumbnail]);
              return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: text),
                    const SizedBox(width: 16),
                    thumbnail
                  ]);
            }),
          ),
        ),
      ),
    );
  }
}

class _NewsImage extends StatelessWidget {
  final String url;

  const _NewsImage({
    required this.url,
  });

  @override
  Widget build(BuildContext context) {
    Localizations.localeOf(context);
    final theme = Theme.of(context);

    return Image.network(
      url,
      webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
      cacheWidth: 264,
      fit: BoxFit.cover,
      filterQuality: FilterQuality.low,
      loadingBuilder: (
        context,
        child,
        loadingProgress,
      ) {
        if (loadingProgress == null) {
          return child;
        }

        return Container(
          color: theme.colorScheme.surfaceContainerHighest,
          alignment: Alignment.center,
          child: const SizedBox(
            width: 22,
            height: 22,
            child: UnioLoader(),
          ),
        );
      },
      errorBuilder: (_, __, ___) {
        return Container(
          color: theme.colorScheme.primary.withValues(
            alpha: 0.08,
          ),
          alignment: Alignment.center,
          child: Icon(
            Icons.image_not_supported_outlined,
            color: theme.colorScheme.primary.withValues(
              alpha: 0.4,
            ),
          ),
        );
      },
    );
  }
}
