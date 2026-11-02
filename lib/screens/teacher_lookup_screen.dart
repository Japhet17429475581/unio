import '../services/locale_service.dart';
import '../services/analytics_service.dart';
import '../utils/user_messages.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import '../widgets/feature_header.dart';
import '../widgets/unio_card.dart';

import '../widgets/unio_loader.dart';

import '../models/lesson.dart';
import '../models/next_lesson.dart';
import '../models/teacher_directory.dart';
import '../services/teachers_service.dart';
import '../utils/date_utils.dart';
import '../widgets/day_card.dart';
import '../widgets/message.dart';

class TeacherLookupScreen extends StatefulWidget {
  final TeacherEntry teacher;
  final DateTime Function() clock;
  const TeacherLookupScreen(
      {super.key, required this.teacher, this.clock = universityScheduleNow});
  @override
  State<TeacherLookupScreen> createState() => _TeacherLookupScreenState();
}

class _TeacherLookupScreenState extends State<TeacherLookupScreen>
    with WidgetsBindingObserver {
  final _weeks = <String, Future<TeacherLookupSchedule>>{};
  late DateTime _now;
  late DateTime _selected;
  Timer? _timer;
  bool _refreshing = false;

  @override
  void initState() {
    super.initState();
    analytics.screen(AnalyticsScreen.teacherSchedule);
    _now = widget.clock();
    _selected = DateTime(_now.year, _now.month, _now.day);
    WidgetsBinding.instance.addObserver(this);
    _watchClock();
  }

  void _watchClock() {
    _timer?.cancel();
    _timer = Timer(Duration(seconds: 60 - widget.clock().second), () {
      if (!mounted) return;
      _tick();
      _watchClock();
    });
  }

  void _tick() {
    final now = widget.clock();
    setState(() {
      if (isoDate(_selected) == isoDate(_now))
        _selected = DateTime(now.year, now.month, now.day);
      _now = now;
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _tick();
      _watchClock();
    } else {
      _timer?.cancel();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<TeacherLookupSchedule> _week(DateTime date) {
    final start = mondayOf(date);
    return _weeks.putIfAbsent(isoDate(start),
        () => fetchTeacherLookupSchedule(widget.teacher, date: start));
  }

  Future<void> _reload() async {
    if (_refreshing) return;
    final dates = {
      isoDate(mondayOf(_now)): mondayOf(_now),
      isoDate(mondayOf(_selected)): mondayOf(_selected)
    };
    final futures = <Future<TeacherLookupSchedule>>[];
    setState(() {
      _refreshing = true;
      for (final entry in dates.entries) {
        final future = fetchTeacherLookupSchedule(widget.teacher,
            date: entry.value, refresh: true);
        _weeks[entry.key] = future;
        futures.add(future);
      }
    });
    await Future.wait(futures.map((f) async {
      try {
        await f;
      } catch (_) {}
    }));
    if (mounted) setState(() => _refreshing = false);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
        context: context,
        initialDate: _selected,
        firstDate: DateTime(_now.year, _now.month, _now.day - 30),
        lastDate: DateTime(_now.year, _now.month, _now.day + 90));
    if (picked != null && mounted) setState(() => _selected = picked);
  }

  void _moveDay(int days) => setState(() {
        final date =
            DateTime(_selected.year, _selected.month, _selected.day + days);
        if (!date.isBefore(_firstDate) && !date.isAfter(_lastDate))
          _selected = date;
      });

  DateTime get _firstDate => DateTime(_now.year, _now.month, _now.day - 30);
  DateTime get _lastDate => DateTime(_now.year, _now.month, _now.day + 90);

  Widget _summary(TeacherLookupSchedule schedule) {
    final theme = Theme.of(context);
    final today = schedule.lessons
        .where((l) => l.date != null && isoDate(l.date!) == isoDate(_now))
        .toList();
    final current = today.where((l) {
      final start = lessonStartTime(l);
      final end = lessonStartTime(Lesson(
          date: l.date,
          start: l.end,
          end: l.end,
          subject: l.subject,
          type: l.type,
          teacher: l.teacher,
          room: l.room));
      return start != null &&
          end != null &&
          !start.isAfter(_now) &&
          end.isAfter(_now);
    }).toList();
    final next = NextLesson.fromSchedule(today, _now);
    return UnioCard(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(l10n.uiTodaySSchedule, style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          if (schedule.isPartial) ...[
            Text(l10n.uiPartOfTheScheduleIsUnavailableShowingKnown),
            const SizedBox(height: 12),
          ],
          if (current.isNotEmpty)
            for (final lesson in current)
              _statusLesson(
                  l10n.uiNow(
                      (lesson.start).toString(), (lesson.end).toString()),
                  lesson)
          else
            Text(
                schedule.isPartial || next.hasUnknownTimes
                    ? l10n.uiCouldNotDetermineWhetherThereIsAClass
                    : l10n.uiNoClassesScheduledRightNow,
                style: theme.textTheme.bodyMedium),
          const SizedBox(height: 12),
          if (next.lesson != null)
            _statusLesson(
                l10n.uiNext((next.lesson!.start).toString()), next.lesson!)
          else if (!schedule.isPartial)
            Text(
                next.hasUnknownTimes
                    ? l10n.uiTimesForUpcomingClassesAreNotSpecified
                    : l10n.uiNoMoreClassesToday,
                style: theme.textTheme.bodyMedium),
          const SizedBox(height: 12),
          Text(l10n.uiTheScheduleShowsPlannedClassesNotAPerson,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          if (schedule.isSaved)
            Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(l10n.uiSavedDataNotConfirmedWithTheServer,
                    style: theme.textTheme.bodySmall)),
        ]));
  }

  Widget _statusLesson(String label, Lesson lesson) {
    final theme = Theme.of(context);
    return Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: theme.textTheme.labelLarge
                  ?.copyWith(color: theme.colorScheme.primary)),
          const SizedBox(height: 4),
          Text(lesson.subject, style: theme.textTheme.titleSmall),
          Text(lesson.room.isEmpty
              ? l10n.uiRoomNotSpecified
              : l10n.uiRoom((lesson.room).toString())),
        ]));
  }

  Widget _todaySummary() => FutureBuilder<TeacherLookupSchedule>(
      future: _week(_now),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done)
          return const LinearProgressIndicator();
        if (snapshot.hasError)
          return Text(l10n.uiTodaySScheduleHasNotLoadedRefreshTo);
        return _summary(snapshot.data!);
      });

  @override
  Widget build(BuildContext context) {
    Localizations.localeOf(context);
    final theme = Theme.of(context);
    final selectedIsToday = isoDate(_selected) == isoDate(_now);
    return Scaffold(
        appBar: AppBar(title: Text(l10n.uiTeacher), actions: [
          IconButton(
              tooltip: l10n.uiRefreshSchedule,
              onPressed: _refreshing ? null : _reload,
              icon: const Icon(Icons.refresh_rounded)),
        ]),
        body: SafeArea(
            child: UnioRefreshIndicator(
                onRefresh: _reload,
                child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    children: [
                      FeatureHeader(
                          compact: true,
                          eyebrow: l10n.uiTeacher,
                          title: widget.teacher.fio,
                          description:
                              l10n.uiClassesAndRoomsFromTheUniversitySchedule,
                          icon: Icons.school_outlined),
                      const SizedBox(height: 20),
                      _todaySummary(),
                      const SizedBox(height: 24),
                      Text(l10n.uiClassSchedule,
                          style: theme.textTheme.titleLarge),
                      const SizedBox(height: 12),
                      Row(children: [
                        IconButton(
                            tooltip: l10n.uiPreviousDay,
                            onPressed: !_selected.isAfter(_firstDate)
                                ? null
                                : () => _moveDay(-1),
                            icon: const Icon(Icons.chevron_left_rounded)),
                        Expanded(
                            child: TextButton(
                                onPressed: _pickDate,
                                child: Text(
                                    selectedIsToday
                                        ? l10n.uiToday240(
                                            (dayMonthLabel(_selected))
                                                .toString())
                                        : fullDateLabel(_selected),
                                    textAlign: TextAlign.center))),
                        IconButton(
                            tooltip: l10n.uiNextDay,
                            onPressed: !_selected.isBefore(_lastDate)
                                ? null
                                : () => _moveDay(1),
                            icon: const Icon(Icons.chevron_right_rounded)),
                      ]),
                      if (!selectedIsToday)
                        Align(
                            alignment: Alignment.center,
                            child: TextButton(
                                onPressed: () => setState(() => _selected =
                                    DateTime(_now.year, _now.month, _now.day)),
                                child: Text(l10n.uiBackToToday))),
                      const SizedBox(height: 12),
                      FutureBuilder<TeacherLookupSchedule>(
                          future: _week(_selected),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState !=
                                ConnectionState.done)
                              return const Center(child: UnioLoader());
                            if (snapshot.hasError)
                              return Message(
                                  icon: Icons.cloud_off_rounded,
                                  title: l10n.uiCouldNotLoadClasses,
                                  text: userMessage(snapshot.error),
                                  actionLabel: l10n.uiTryAgain,
                                  onAction: _reload);
                            final schedule = snapshot.data!;
                            final lessons = schedule.lessons
                                .where((l) =>
                                    l.date != null &&
                                    isoDate(l.date!) == isoDate(_selected))
                                .toList();
                            return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  if (schedule.isPartial || schedule.isSaved)
                                    Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 12),
                                        child: Text(
                                            schedule.isPartial
                                                ? l10n
                                                    .uiTheScheduleHasNotLoadedCompletely
                                                : l10n.uiShowingSavedSchedule,
                                            style: theme.textTheme.bodySmall)),
                                  if (lessons.isEmpty && schedule.isPartial)
                                    Text(l10n.uiNoKnownClassesForThisDayTheFull)
                                  else
                                    DayCard(
                                        day: _selected,
                                        isToday: selectedIsToday,
                                        lessons: lessons,
                                        showGroups: true),
                                ]);
                          }),
                    ]))));
  }
}
