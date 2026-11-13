import '../services/schedule_repository.dart';
import '../services/locale_service.dart';
import '../widgets/signature_surface.dart';
import '../services/analytics_service.dart';
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../widgets/campus_stories.dart';
import '../services/news_stories_controller.dart';

import '../widgets/unio_loader.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../models/lesson.dart';
import '../config/calm_depth.dart';
import '../models/next_lesson.dart';
import '../services/lesson_notes_service.dart';
import '../utils/date_utils.dart';
import '../widgets/message.dart';
import '../widgets/tap_feedback.dart';
import '../widgets/week_view.dart';
import '../widgets/next_lesson_card.dart';
import 'lesson_notes_screen.dart';
import 'assistant_screen.dart';
import '../services/assistant_service.dart';
import '../services/portal_grades_repository.dart';
import '../widgets/assistant_entry_button.dart';

class ScheduleTab extends StatefulWidget {
  final String group;
  final ScheduleRepository? repository;
  final VoidCallback? onOpenSettings;
  final VoidCallback? onOpenNotifications;
  final String? teacherFio;
  final ValueChanged<Lesson>? onLessonTap;
  final VoidCallback? onOpenRequests;
  final VoidCallback? onOpenGrades;
  final PortalGradesRepository? gradesRepository;
  final DateTime Function() clock;

  const ScheduleTab(
      {super.key,
      required this.group,
      this.repository,
      this.onOpenSettings,
      this.onOpenNotifications,
      this.clock = universityScheduleNow,
      this.onOpenRequests,
      this.onOpenGrades,
      this.gradesRepository})
      : teacherFio = null,
        onLessonTap = null;

  const ScheduleTab.teacher({
    super.key,
    required String fio,
    this.repository,
    this.onOpenSettings,
    this.onOpenNotifications,
    this.onLessonTap,
    this.clock = universityScheduleNow,
  })  : group = '',
        onOpenRequests = null,
        onOpenGrades = null,
        gradesRepository = null,
        teacherFio = fio;

  @override
  State<ScheduleTab> createState() => ScheduleTabState();
}

class ScheduleTabState extends State<ScheduleTab> with WidgetsBindingObserver {
  /// 0 — эта неделя, 1 — следующая
  int _offset = 0;
  final _stories = NewsStoriesController();
  late final AssistantConversation? _assistant;

  // Каждую неделю грузим один раз — переключение кнопкой мгновенное
  late ScheduleRepository _repository;
  late final Future<void> _photoRecovery;
  bool _openingNotes = false;
  final _pages = PageController();
  final _scrollControllers = <String, ScrollController>{};
  final _focusKey = GlobalKey();
  Lesson? _focusedLesson;
  bool _highlightFocus = false;
  Timer? _highlightTimer;
  Timer? _dayTimer;
  late DateTime _today;
  int? _dragStart;

  @override
  void initState() {
    super.initState();
    _assistant = widget.onOpenSettings != null || widget.teacherFio != null
        ? null
        : AssistantConversation(
            grades: widget.gradesRepository == null
                ? null
                : () => widget.gradesRepository!.load());
    _repository = widget.repository ??
        ScheduleRepository(group: widget.group, teacherFio: widget.teacherFio);
    _repository.addListener(_repositoryChanged);
    _today = widget.clock();
    _prefetchWeeks();
    WidgetsBinding.instance.addObserver(this);
    _watchDay();
    _photoRecovery = _recoverPhotos();
  }

  void _repositoryChanged() {
    if (mounted) setState(() {});
  }

  void _checkDay() {
    final now = widget.clock();
    _repository.revalidate(now);
    if (isoDate(now) != isoDate(_today)) {
      setState(() {
        _today = now;
        _focusedLesson = null;
      });
      _prefetchWeeks();
    }
  }

  void _watchDay() {
    _dayTimer?.cancel();
    _dayTimer = Timer.periodic(const Duration(seconds: 1), (_) => _checkDay());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkDay();
      _repository.revalidate(widget.clock());
      _watchDay();
    } else {
      _dayTimer?.cancel();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _dayTimer?.cancel();
    _pages.dispose();
    _highlightTimer?.cancel();
    _stories.dispose();
    _repository.removeListener(_repositoryChanged);
    if (widget.repository == null) _repository.dispose();
    _assistant?.dispose();
    for (final controller in _scrollControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _changeWeek(int offset) async {
    if (!_pages.hasClients) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      _pages.jumpToPage(offset);
      return;
    }
    await _pages.animateToPage(offset,
        duration: CalmDepth.motion, curve: Curves.easeInOutCubic);
  }

  Future<void> showLesson(Lesson lesson) async {
    _highlightTimer?.cancel();
    setState(() {
      _focusedLesson = lesson;
      _highlightFocus = true;
    });
    await _changeWeek(0);
    if (!mounted) return;
    _highlightTimer = Timer(const Duration(milliseconds: 1800), () {
      if (mounted) setState(() => _highlightFocus = false);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final target = _focusKey.currentContext?.findRenderObject();
      final controller = _scrollControllers[isoDate(_weekStart(0))];
      if (mounted &&
          target != null &&
          controller != null &&
          controller.hasClients) {
        controller.position.ensureVisible(target,
            alignment: .2,
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : CalmDepth.motion,
            curve: Curves.easeOutCubic);
      }
    });
    // Request a frame even if the requested week was already selected.
    setState(() {});
  }

  bool _trackSwipe(ScrollNotification notification) {
    if (notification.depth != 0 || notification.metrics is! PageMetrics)
      return false;
    if (notification is ScrollStartNotification &&
        notification.dragDetails != null) {
      _dragStart = _offset;
    } else if (notification is ScrollEndNotification) {
      _dragStart = null;
    }
    return false;
  }

  Future<void> _recoverPhotos() async {
    if (widget.teacherFio != null ||
        kIsWeb ||
        defaultTargetPlatform != TargetPlatform.android) return;
    LessonNotesService service;
    try {
      service = await LessonNotesService.forCurrentStudent();
    } catch (_) {
      return; // No active local student session or storage unavailable.
    }
    try {
      final recovered = await service.recoverPhotos(ImagePicker());
      if (recovered && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.uiClassPhotosRecoveredAndSaved)),
        );
      }
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(l10n.uiCouldNotRecoverTheSelectedPhotosOpenThe)),
        );
    }
  }

  Future<void> openStudentNotes(Lesson lesson) async {
    if (_openingNotes) return;
    _openingNotes = true;
    tapFeedback();
    try {
      await _photoRecovery;
      if (!mounted) return;
      await Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => LessonNotesScreen(lesson: lesson, group: widget.group),
      ));
    } finally {
      _openingNotes = false;
    }
  }

  DateTime _weekStart(int offset) {
    final monday = mondayOf(_today);
    return DateTime(monday.year, monday.month, monday.day + 7 * offset);
  }

  Future<List<Lesson>> _weekFuture(int offset) =>
      _repository.week(_weekStart(offset));

  void _prefetchWeeks() {
    // Start both requests together. The services persist successful responses
    // on the device, and the pages reuse these same futures when swiped.
    // A background failure must not interrupt the visible week; its page still
    // receives the original error and offers the existing retry action.
    for (final offset in [0, 1]) {
      _weekFuture(offset).ignore();
    }
  }

  Future<void> _reloadWeek(int offset) async {
    final future = _repository.refresh(_weekStart(offset));
    if (_stories.items.isNotEmpty || _stories.error != null)
      _stories.load(refresh: true);
    setState(() {
      _focusedLesson = null;
    });

    try {
      await future;
    } catch (_) {}
  }

  @override
  void didUpdateWidget(covariant ScheduleTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.group != widget.group ||
        oldWidget.teacherFio != widget.teacherFio) {
      _repository.select(group: widget.group, teacherFio: widget.teacherFio);
      _prefetchWeeks();
      _assistant?.clear();
      _focusedLesson = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    Localizations.localeOf(context);
    return SignatureBackdrop(child: _buildSchedule(context));
  }

  Widget _buildSchedule(BuildContext context) {
    final todayFuture = _weekFuture(0);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: CampusStories(
              controller: _stories, teacher: widget.teacherFio != null),
        ),
        Expanded(
          child: NotificationListener<ScrollNotification>(
            onNotification: _trackSwipe,
            child: PageView.builder(
              key: ValueKey('weeks-${widget.teacherFio ?? widget.group}'),
              controller: _pages,
              itemCount: 2,
              onPageChanged: (offset) {
                if (_offset != offset)
                  analytics.track(AnalyticsEvent.weekChanged,
                      role: widget.teacherFio == null
                          ? AnalyticsRole.student
                          : AnalyticsRole.teacher,
                      action: offset > _offset
                          ? AnalyticsAction.next
                          : AnalyticsAction.previous);
                if (_dragStart != null) HapticFeedback.selectionClick();
                setState(() => _offset = offset);
              },
              itemBuilder: (context, offset) => _buildWeek(offset, todayFuture),
            ),
          ),
        ),
      ],
    );
  }

  Widget _weekHeader(int offset) {
    final theme = Theme.of(context);
    final isNext = offset == 1;
    final start = _weekStart(offset);
    final end = DateTime(start.year, start.month, start.day + 6);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(
                  child: Text(isNext ? l10n.uiNextWeek : l10n.uiThisWeek,
                      style: theme.textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w700))),
              if (widget.onOpenNotifications != null)
                IconButton(
                    tooltip: l10n.uiPushNotifications,
                    onPressed: widget.onOpenNotifications,
                    icon: const Icon(Icons.notifications_none_rounded)),
              if (widget.onOpenSettings != null)
                IconButton(
                    tooltip: l10n.uiSettings,
                    onPressed: widget.onOpenSettings,
                    icon: const Icon(Icons.settings_outlined))
              else if (widget.teacherFio == null)
                AssistantEntryButton(
                    onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => AssistantScreen(
                                conversation: _assistant!,
                                group: widget.group,
                                onOpenRequests: widget.onOpenRequests,
                                onOpenGrades: widget.onOpenGrades,
                                onLessonTap: openStudentNotes)))),
            ]),
            const SizedBox(height: 4),
            Text(
              '${rangeLabel(start, end)} • ${widget.teacherFio ?? widget.group}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 16),
        child: PrimaryButton(
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
          borderRadius: CalmDepth.controlRadius,
          label: isNext ? l10n.uiThisWeek : l10n.uiNextWeek,
          onPressed: () => _changeWeek(isNext ? 0 : 1),
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isNext) ...[
                Icon(
                  Icons.arrow_back_rounded,
                  size: 20,
                  color: theme.colorScheme.onPrimary,
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                  child: Text(
                isNext ? l10n.uiThisWeek : l10n.uiNextWeek,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: theme.colorScheme.onPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              )),
              if (!isNext) ...[
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_rounded,
                  size: 20,
                  color: theme.colorScheme.onPrimary,
                ),
              ],
            ],
          ),
        ),
      ),
    ]);
  }

  Widget _buildWeek(int offset, Future<List<Lesson>>? todayFuture) {
    final start = _weekStart(offset);
    final dateKey = isoDate(start);
    final controller =
        _scrollControllers.putIfAbsent(dateKey, () => ScrollController());
    final leading =
        Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const SizedBox(height: 12),
      _weekHeader(offset),
      if (todayFuture != null)
        NextLessonCard(
            key: ValueKey('next-lesson-${widget.group}-$dateKey'),
            schedule: todayFuture,
            clock: widget.clock,
            onLessonTap: showLesson,
            onRetry: () => _reloadWeek(0)),
    ]);
    return FutureBuilder<List<Lesson>>(
      key: ValueKey('${widget.teacherFio ?? widget.group}-$dateKey'),
      future: _weekFuture(offset),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done ||
            snapshot.hasError) {
          return UnioRefreshIndicator(
              onRefresh: () => _reloadWeek(offset),
              child: ListView(
                controller: controller,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                children: [
                  leading,
                  const SizedBox(height: 48),
                  if (snapshot.connectionState != ConnectionState.done)
                    const Center(child: UnioLoader())
                  else
                    Message(
                        icon: Icons.cloud_off_rounded,
                        title: l10n.uiCouldNotLoadSchedule,
                        text: l10n.uiCheckYourInternetConnectionAndTryAgain,
                        actionLabel: l10n.uiTryAgain,
                        onAction: () => _reloadWeek(offset)),
                ],
              ));
        }
        return WeekView(
            key:
                PageStorageKey('${widget.teacherFio ?? widget.group}-$dateKey'),
            lessons: snapshot.data ?? [],
            showScheduleHeader: widget.teacherFio == null,
            weekStart: start,
            controller: controller,
            today: widget.clock(),
            leading: leading,
            focusedLesson: offset == 0 ? _focusedLesson : null,
            highlightFocus: _highlightFocus,
            onDaySelected: () {
              if (_focusedLesson != null) setState(() => _focusedLesson = null);
            },
            focusKey: offset == 0 ? _focusKey : null,
            emptyTitle: l10n.uiNoScheduleFoundForThisWeek,
            onRefresh: () => _reloadWeek(offset),
            onLessonTap: widget.teacherFio == null
                ? openStudentNotes
                : widget.onLessonTap);
      },
    );
  }
}
