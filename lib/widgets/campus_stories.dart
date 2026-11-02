import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/news_article.dart';
import '../services/news_stories_controller.dart';
import '../screens/news_story_screen.dart';
import 'guide_stories.dart';
import 'story_circle.dart';
import 'story_entrance.dart';

class CampusStories extends StatefulWidget {
  final NewsStoriesController controller;
  final bool teacher;
  const CampusStories(
      {super.key, required this.controller, this.teacher = false});
  @override
  State<CampusStories> createState() => _CampusStoriesState();
}

class _CampusStoriesState extends State<CampusStories> {
  final _pages = PageController();
  Set<String> _seen = {};
  bool _opening = false;
  int _page = 0;
  @override
  void initState() {
    super.initState();
    // Start after this shelf has mounted.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.controller.start();
    });
    _loadSeen();
  }

  Future<void> _loadSeen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (mounted)
        setState(() => _seen = {
              ..._seen,
              ...?prefs.getStringList('news_stories_seen_v1')
            });
    } catch (_) {}
  }

  Future<void> _open(NewsListItem news) async {
    if (_opening) return;
    _opening = true;
    try {
      await Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => NewsStoryScreen(item: news)));
      if (!mounted) return;
      setState(() => _seen.add('${news.id}'));
      try {
        final prefs = await SharedPreferences.getInstance();
        final ids = {...?prefs.getStringList('news_stories_seen_v1'), ..._seen}
            .toList();
        await prefs.setStringList('news_stories_seen_v1',
            ids.reversed.take(200).toList().reversed.toList());
      } catch (_) {}
    } finally {
      _opening = false;
    }
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
      builder: (context, constraints) => ListenableBuilder(
          listenable: widget.controller,
          builder: (context, _) {
            final feed = widget.controller;
            final scale = MediaQuery.textScalerOf(context).scale(12) / 12;
            final perPage =
                (constraints.maxWidth / (84 * scale)).floor().clamp(1, 4);
            final pages = ((feed.items.length + 1) / perPage).ceil();
            if (_page >= pages) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && _pages.hasClients) _pages.jumpToPage(pages - 1);
              });
            }
            final lineHeight = MediaQuery.textScalerOf(context).scale(12) * 1.2;
            return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                      height: 76 + 2 * lineHeight,
                      child: PageView.builder(
                          controller: _pages,
                          itemCount: pages,
                          onPageChanged: (index) {
                            setState(() => _page = index);
                            if (index == pages - 1 &&
                                feed.hasMore &&
                                feed.error == null) feed.load();
                          },
                          itemBuilder: (context, page) => Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    for (var slot = 0; slot < perPage; slot++)
                                      Expanded(
                                          child: page * perPage + slot >
                                                  feed.items.length
                                              ? const SizedBox.shrink()
                                              : StoryEntrance(
                                                  key: ValueKey(page * perPage +
                                                              slot ==
                                                          0
                                                      ? 'story-entrance-guide'
                                                      : 'story-entrance-${feed.items[page * perPage + slot - 1].id}'),
                                                  orderFromRight:
                                                      perPage - slot - 1,
                                                  child: _tile(
                                                      page * perPage + slot,
                                                      feed.items),
                                                )),
                                  ]))),
                ]);
          }));

  Widget _tile(int index, List<NewsListItem> items) {
    if (index == 0) return GuideStories(teacher: widget.teacher);
    if (index > items.length) return const SizedBox.shrink();
    final item = items[index - 1];
    return StoryCircle(
        key: ValueKey('news-story-${item.id}'),
        label: item.title,
        imageUrl: item.imageUrl,
        seen: _seen.contains('${item.id}'),
        onTap: () => _open(item));
  }
}
