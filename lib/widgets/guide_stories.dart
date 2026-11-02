import '../services/locale_service.dart';
import '../services/analytics_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'unio_card.dart';
import 'story_circle.dart';

const guideSeenPreference = 'unio_guide_seen_v1';

class GuideSlide {
  final String title, text;
  final String? chapter;
  final int step;
  const GuideSlide(this.title, this.text, {this.chapter, this.step = 0});
}

class GuideStory {
  final String id, label;
  final IconData icon;
  final Color accent;
  final List<GuideSlide> slides;
  const GuideStory(this.id, this.label, this.icon, this.accent, this.slides);
}

List<GuideStory> guideChapters({required bool teacher}) => [
      GuideStory('schedule', l10n.uiSchedule, Icons.calendar_month_rounded,
          Color(0xFFAD98FF), [
        GuideSlide(l10n.uiHowToViewYourSchedule,
            l10n.uiChooseADayOnTheScheduleTimesAre),
        GuideSlide(
            l10n.uiHowToSwitchWeeks, l10n.uiSwipeLeftForNextWeekAndRightFor),
      ]),
      if (!teacher)
        GuideStory('notes', l10n.uiHomeworkAndNotes, Icons.edit_note_rounded,
            Color(0xFF8ACBFF), [
          GuideSlide(
              l10n.uiHowToAddHomework, l10n.uiOpenAClassWriteDownHomeworkOrAn),
          GuideSlide(
              l10n.uiHowToAddPhotos, l10n.uiScrollTheActionBarToAddPhotosFrom),
        ]),
      if (!teacher)
        GuideStory('requests', l10n.uiApplications, Icons.description_outlined,
            Color(0xFF91D6C3), [
          GuideSlide(l10n.uiHowToRequestACertificate,
              l10n.uiOpenUniversitySubmitAnApplicationAndSignIn),
          GuideSlide(l10n.uiFillingOutAnApplication,
              l10n.uiWhenOpenFormAppearsOpenTheApplicationAfter),
        ]),
      if (teacher)
        GuideStory('rooms', l10n.uiRooms, Icons.meeting_room_outlined,
            Color(0xFF91D6C3), [
          GuideSlide(
              l10n.uiFindARoom, l10n.uiOpenAClassAndSelectFindAnAvailable),
          GuideSlide(l10n.uiWhatTheSearchShows,
              l10n.uiUnioOnlyChecksTheSchedulesItKnowsA),
        ]),
      GuideStory('teachers', l10n.uiTeachers, Icons.person_search_outlined,
          Color(0xFFFFC497), [
        GuideSlide(
            l10n.uiTeacherSearch, l10n.uiOpenTeachersInTheUniversityTabEnterAt),
        GuideSlide(
            l10n.uiClassesAndRooms, l10n.uiATeacherSCardShowsClassesAndRooms),
      ]),
    ];

List<GuideStory> guideStories({required bool teacher}) => [
      GuideStory(
          teacher ? 'unio-teacher-v2' : 'unio-student-v2',
          l10n.uiGettingStarted,
          Icons.auto_stories_outlined,
          const Color(0xFFA78BFA), [
        for (final chapter in guideChapters(teacher: teacher))
          for (var i = 0; i < chapter.slides.length; i++)
            GuideSlide(chapter.slides[i].title, chapter.slides[i].text,
                chapter: chapter.id, step: i),
      ]),
    ];

class GuideStories extends StatefulWidget {
  final bool teacher;
  const GuideStories({super.key, this.teacher = false});
  @override
  State<GuideStories> createState() => _GuideStoriesState();
}

class _GuideStoriesState extends State<GuideStories> {
  Set<String> _seen = {};
  bool _opening = false;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (mounted)
        setState(() =>
            _seen = {..._seen, ...?prefs.getStringList(guideSeenPreference)});
    } catch (_) {/* Guides also work without persistence. */}
  }

  Future<void> _open(GuideStory story) async {
    if (_opening) return;
    _opening = true;
    analytics.track(AnalyticsEvent.guideOpened,
        role: widget.teacher ? AnalyticsRole.teacher : AnalyticsRole.student);
    final reduced = MediaQuery.disableAnimationsOf(context);
    try {
      final completed = await Navigator.of(context).push<bool>(PageRouteBuilder(
        fullscreenDialog: true,
        transitionDuration:
            reduced ? Duration.zero : const Duration(milliseconds: 280),
        reverseTransitionDuration:
            reduced ? Duration.zero : const Duration(milliseconds: 220),
        pageBuilder: (_, __, ___) => GuideStoryScreen(story: story),
        transitionsBuilder: (_, animation, __, child) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
                position: Tween(begin: const Offset(0, .04), end: Offset.zero)
                    .animate(CurvedAnimation(
                        parent: animation, curve: Curves.easeOutCubic)),
                child: child)),
      ));
      if (completed == true) {
        analytics.track(AnalyticsEvent.guideCompleted,
            role:
                widget.teacher ? AnalyticsRole.teacher : AnalyticsRole.student);
        if (mounted) setState(() => _seen.add(story.id));
        try {
          final prefs = await SharedPreferences.getInstance();
          final seen = {...?prefs.getStringList(guideSeenPreference), story.id};
          await prefs.setStringList(guideSeenPreference, seen.toList());
        } catch (_) {
          /* Viewing a guide must never fail due to local preferences. */
        }
      }
    } finally {
      _opening = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    Localizations.localeOf(context);
    final story = guideStories(teacher: widget.teacher).single;
    return StoryCircle(
        key: const ValueKey('guide-unio'),
        label: l10n.uiGettingStarted,
        icon: Icons.auto_stories_outlined,
        seen: _seen.contains(story.id),
        onTap: () => _open(story));
  }
}

class GuideStoryScreen extends StatefulWidget {
  final GuideStory story;
  const GuideStoryScreen({super.key, required this.story});
  @override
  State<GuideStoryScreen> createState() => _GuideStoryScreenState();
}

class _GuideStoryScreenState extends State<GuideStoryScreen> {
  final _pages = PageController();
  int _index = 0;
  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _move(int direction) {
    final target = _index + direction;
    if (target >= widget.story.slides.length) {
      Navigator.pop(context, true);
      return;
    }
    if (target < 0) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      _pages.jumpToPage(target);
      return;
    }
    _pages.animateToPage(target,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic);
  }

  @override
  Widget build(BuildContext context) {
    Localizations.localeOf(context);
    return Theme(
        data: Theme.of(context),
        child: Builder(builder: (context) {
          final theme = Theme.of(context);
          final story = widget.story;
          return Scaffold(
              backgroundColor: theme.scaffoldBackgroundColor,
              body: DecoratedBox(
                  decoration: BoxDecoration(
                      gradient: RadialGradient(
                          center: const Alignment(.8, -.6),
                          radius: 1.5,
                          colors: [
                        theme.colorScheme.surfaceContainerLow,
                        theme.scaffoldBackgroundColor
                      ])),
                  child: SafeArea(
                      child: Column(children: [
                    Padding(
                        padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
                        child: Row(children: [
                          for (var i = 0; i < story.slides.length; i++)
                            Expanded(
                                child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 3),
                                    child: AnimatedContainer(
                                        duration: MediaQuery
                                                .disableAnimationsOf(context)
                                            ? Duration.zero
                                            : const Duration(milliseconds: 200),
                                        height: 3,
                                        decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(4),
                                            color: i <= _index
                                                ? story.accent
                                                : Colors.white
                                                    .withValues(alpha: .16)))))
                        ])),
                    Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(children: [
                          Icon(story.icon, color: story.accent, size: 22),
                          const SizedBox(width: 10),
                          Expanded(
                              child: Text(story.label,
                                  style: theme.textTheme.titleSmall)),
                          Text('${_index + 1}/${story.slides.length}',
                              style: theme.textTheme.bodySmall),
                          IconButton(
                              tooltip: l10n.uiCloseGuide,
                              onPressed: () => Navigator.pop(context, false),
                              icon: const Icon(Icons.close_rounded))
                        ])),
                    Expanded(
                        child: PageView.builder(
                            controller: _pages,
                            itemCount: story.slides.length,
                            onPageChanged: (value) =>
                                setState(() => _index = value),
                            itemBuilder: (context, index) =>
                                SingleChildScrollView(
                                    padding: const EdgeInsets.fromLTRB(
                                        24, 20, 24, 24),
                                    child: Center(
                                        child: ConstrainedBox(
                                            constraints: const BoxConstraints(
                                                maxWidth: 480),
                                            child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  ExcludeSemantics(
                                                      child: GuideArtwork(
                                                          story: guideChapters(
                                                                  teacher: story
                                                                      .id
                                                                      .contains(
                                                                          'teacher'))
                                                              .firstWhere((chapter) =>
                                                                  chapter.id ==
                                                                  story
                                                                      .slides[
                                                                          index]
                                                                      .chapter),
                                                          step: story
                                                              .slides[index]
                                                              .step)),
                                                  const SizedBox(height: 24),
                                                  Text(l10n.uiAppGuide,
                                                      style: theme
                                                          .textTheme.labelSmall
                                                          ?.copyWith(
                                                              color:
                                                                  story.accent,
                                                              letterSpacing:
                                                                  1.5)),
                                                  const SizedBox(height: 16),
                                                  Text(
                                                      story.slides[index].title,
                                                      style: theme.textTheme
                                                          .headlineMedium
                                                          ?.copyWith(
                                                              fontSize: 26,
                                                              height: 1.15)),
                                                  const SizedBox(height: 18),
                                                  Text(story.slides[index].text,
                                                      style: theme
                                                          .textTheme.bodyLarge
                                                          ?.copyWith(
                                                              color: theme
                                                                  .colorScheme
                                                                  .onSurfaceVariant,
                                                              height: 1.6))
                                                ])))))),
                    Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                        child: Row(children: [
                          if (_index > 0) ...[
                            IconButton.filledTonal(
                                tooltip: l10n.uiBack,
                                onPressed: () => _move(-1),
                                icon: const Icon(Icons.arrow_back_rounded)),
                            const SizedBox(width: 12)
                          ],
                          Expanded(
                              child: FilledButton.icon(
                                  onPressed: () => _move(1),
                                  style: FilledButton.styleFrom(
                                      backgroundColor:
                                          theme.colorScheme.primaryContainer,
                                      foregroundColor:
                                          theme.colorScheme.onPrimaryContainer),
                                  icon: Icon(_index == story.slides.length - 1
                                      ? Icons.check_rounded
                                      : Icons.arrow_forward_rounded),
                                  label: Text(_index == story.slides.length - 1
                                      ? l10n.uiGotIt
                                      : l10n.uiNext276)))
                        ]))
                  ]))));
        }));
  }
}

/// Code-native miniatures, deliberately marked as examples rather than live data.
class GuideArtwork extends StatelessWidget {
  final GuideStory story;
  final int step;
  const GuideArtwork({super.key, required this.story, required this.step});
  @override
  Widget build(BuildContext context) {
    Localizations.localeOf(context);
    final theme = Theme.of(context);
    Widget line(IconData icon, String title, String caption) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(children: [
          Icon(icon, color: story.accent, size: 24),
          const SizedBox(width: 14),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(title, style: theme.textTheme.titleSmall),
                const SizedBox(height: 4),
                Text(caption,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ])),
        ]));
    return UnioCard(
        padding: const EdgeInsets.all(22),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(l10n.uiExample((story.label.toUpperCase()).toString()),
              style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  letterSpacing: 1.5)),
          const SizedBox(height: 18),
          if (story.id == 'schedule') ...[
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final day in [
                l10n.uiMon,
                l10n.uiTue,
                l10n.uiWed,
                l10n.uiThu,
                l10n.uiFri
              ])
                Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                        color: day == l10n.uiWed
                            ? story.accent
                            : theme.colorScheme.surfaceContainer,
                        borderRadius: BorderRadius.circular(13)),
                    child: Text(day,
                        style: theme.textTheme.labelSmall?.copyWith(
                            color: day == l10n.uiWed
                                ? const Color(0xFF191329)
                                : theme.colorScheme.onSurfaceVariant)))
            ]),
            line(
                Icons.schedule_rounded, l10n.uiForeignLanguage, l10n.uiRoom374),
            line(
                step == 0 ? Icons.location_on_outlined : Icons.swipe_rounded,
                step == 0 ? l10n.uiPedagogy : l10n.uiNextWeek,
                step == 0 ? l10n.uiRoom376 : l10n.uiSwipeLeft),
          ] else if (story.id == 'notes') ...[
            line(Icons.check_circle_outline, l10n.uiReadChapter,
                l10n.uiAssignmentForTheNextClass),
            Container(
                height: 72,
                decoration: BoxDecoration(
                    color: story.accent.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(16)),
                child: Icon(
                    step == 0
                        ? Icons.edit_note_rounded
                        : Icons.add_photo_alternate_outlined,
                    color: story.accent,
                    size: 38)),
            const SizedBox(height: 14),
            Text(l10n.uiSavedOnThisDevice, style: theme.textTheme.bodySmall),
          ] else if (story.id == 'requests') ...[
            line(Icons.hourglass_empty_rounded, l10n.uiNew,
                l10n.uiThePortalIsPreparingTheForm),
            line(Icons.edit_document, l10n.uiOpenForm,
                l10n.uiYouCanOpenTheApplication),
            line(Icons.mark_email_read_outlined, l10n.uiUniversityResponse,
                l10n.uiTheStatusWillAppearInTheList),
          ] else if (story.id == 'rooms') ...[
            line(Icons.schedule_rounded, '10:10–11:40',
                l10n.uiSelectedClassTime),
            Wrap(spacing: 10, runSpacing: 10, children: [
              for (final room in ['201', '205', '314'])
                Chip(label: Text(l10n.uiRoom224((room).toString())))
            ]),
            const SizedBox(height: 12),
            Text(l10n.uiBasedOnKnownSchedules,
                style: theme.textTheme.bodySmall),
          ] else ...[
            line(Icons.search_rounded, l10n.uiSearchBySurname,
                l10n.uiChooseTheFullName),
            line(Icons.person_outline_rounded, l10n.uiTeacherDetails,
                l10n.uiTodayAndOtherDays),
            line(Icons.location_on_outlined, l10n.uiRoomAndTime,
                l10n.uiFromTheClassSchedule),
          ],
        ]));
  }
}
