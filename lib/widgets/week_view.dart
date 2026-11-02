import '../services/locale_service.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../config/calm_depth.dart';
import '../models/lesson.dart';
import '../utils/date_utils.dart';
import 'day_card.dart';
import 'message.dart';
import 'unio_loader.dart';

/// A week keeps its own selected day, including when navigating between weeks.
class WeekView extends StatefulWidget {
  final List<Lesson> lessons;
  final bool showGroups;
  final ValueChanged<Lesson>? onLessonTap;
  final VoidCallback? onDaySelected;
  final Widget? leading;
  final Widget? trailing;
  final ScrollController? controller;
  final Lesson? focusedLesson;
  final bool highlightFocus;
  final GlobalKey? focusKey;
  final DateTime? today;
  final DateTime weekStart;
  final String? emptyTitle;
  final Future<void> Function() onRefresh;
  const WeekView(
      {super.key,
      required this.lessons,
      this.showGroups = false,
      this.onLessonTap,
      this.onDaySelected,
      this.leading,
      this.trailing,
      this.controller,
      this.focusedLesson,
      this.highlightFocus = true,
      this.focusKey,
      this.today,
      required this.weekStart,
      required this.onRefresh,
      this.emptyTitle});
  @override
  State<WeekView> createState() => _WeekViewState();
}

class _WeekViewState extends State<WeekView> {
  int? _selected;
  final _dayScroll = ScrollController(keepScrollOffset: false);
  final _selectedDayKey = GlobalKey();
  Object get _storageKey =>
      (widget.key, isoDate(widget.weekStart), 'selected-day');
  @override
  void dispose() {
    _dayScroll.dispose();
    super.dispose();
  }

  void _revealDay() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_dayScroll.hasClients) return;
      final target = _selectedDayKey.currentContext?.findRenderObject();
      if (target != null)
        _dayScroll.position.ensureVisible(target, alignment: .5);
    });
  }

  void _revealLesson() {
    final lesson = widget.focusedLesson;
    if (lesson == null) return;
    void reveal() {
      final target = widget.focusKey?.currentContext?.findRenderObject();
      final controller = widget.controller;
      if (!mounted ||
          widget.focusedLesson != lesson ||
          target == null ||
          controller == null ||
          !controller.hasClients) return;
      controller.position.ensureVisible(target,
          alignment: .2,
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : CalmDepth.motion,
          curve: Curves.easeOutCubic);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      reveal();
      // A newly mounted week first inherits its estimated sliver extent.
      // Recheck after the first scroll lays out the full, scaled header.
      WidgetsBinding.instance.addPostFrameCallback((_) => reveal());
      WidgetsBinding.instance.scheduleFrame();
    });
  }

  int? _indexOf(DateTime? date) {
    if (date == null) return null;
    // Calendar dates, independent of daylight saving or a clock's time of day.
    final offset = DateTime.utc(date.year, date.month, date.day)
        .difference(DateTime.utc(widget.weekStart.year, widget.weekStart.month,
            widget.weekStart.day))
        .inDays;
    return offset >= 0 && offset < 7 ? offset : null;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _selected ??= _indexOf(widget.focusedLesson?.date) ??
        PageStorage.maybeOf(context)
            ?.readState(context, identifier: _storageKey) as int? ??
        _indexOf(widget.today ?? DateTime.now()) ??
        0;
    _revealDay();
    _revealLesson();
  }

  @override
  void didUpdateWidget(covariant WeekView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.weekStart != widget.weekStart) {
      _selected = _indexOf(widget.today ?? DateTime.now()) ?? 0;
    }
    if (widget.focusedLesson != oldWidget.focusedLesson &&
        widget.focusedLesson != null) {
      _selected = _indexOf(widget.focusedLesson!.date) ?? _selected;
      _revealDay();
      _revealLesson();
    }
  }

  void _select(int day) {
    setState(() => _selected = day);
    PageStorage.maybeOf(context)
        ?.writeState(context, day, identifier: _storageKey);
    widget.onDaySelected?.call();
  }

  @override
  Widget build(BuildContext context) {
    Localizations.localeOf(context);
    final selected = _selected ?? 0;
    final day = DateTime(widget.weekStart.year, widget.weekStart.month,
        widget.weekStart.day + selected);
    final lessons = widget.lessons
        .where((lesson) =>
            lesson.date != null && isoDate(lesson.date!) == isoDate(day))
        .toList()
      ..sort(compareLessons);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final today = widget.today ?? DateTime.now();
    final labels = [
      l10n.uiMon,
      l10n.uiTue,
      l10n.uiWed,
      l10n.uiThu,
      l10n.uiFri,
      l10n.uiSat,
      l10n.uiSun
    ];
    return UnioRefreshIndicator(
      onRefresh: widget.onRefresh,
      child: ListView(
        controller: widget.controller,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            if (widget.leading != null) ...[
              widget.leading!,
              const SizedBox(height: 24)
            ],
            if (widget.lessons.isEmpty) ...[
              const SizedBox(height: 48),
              Message(
                  icon: Icons.wb_sunny_rounded,
                  title: widget.emptyTitle ?? l10n.uiNoScheduleFoundForThisWeek,
                  text: l10n.uiPullDownToRefreshTheSchedule),
            ] else
              DayCard(
                day: day,
                isToday: isoDate(day) == isoDate(today),
                lessons: lessons,
                showGroups: widget.showGroups,
                onLessonTap: widget.onLessonTap,
                focusedLesson: widget.focusedLesson,
                highlightFocus: widget.highlightFocus,
                focusKey: widget.focusKey,
                daySelector: LayoutBuilder(builder: (context, constraints) {
                  final dayWidth = math.max(
                    48.0 * MediaQuery.textScalerOf(context).scale(13) / 13,
                    (constraints.maxWidth - 12) / 7,
                  );
                  return SingleChildScrollView(
                    controller: _dayScroll,
                    scrollDirection: Axis.horizontal,
                    child: Row(children: [
                      for (var i = 0; i < 7; i++) ...[
                        if (i > 0) const SizedBox(width: 2),
                        Semantics(
                          key: i == selected ? _selectedDayKey : null,
                          selected: i == selected,
                          button: true,
                          hint: i == _indexOf(today) ? l10n.uiToday : null,
                          label:
                              '${weekdayName(DateTime(widget.weekStart.year, widget.weekStart.month, widget.weekStart.day + i))}, ${dayMonthLabel(DateTime(widget.weekStart.year, widget.weekStart.month, widget.weekStart.day + i))}',
                          child: AnimatedContainer(
                            duration: MediaQuery.disableAnimationsOf(context)
                                ? Duration.zero
                                : CalmDepth.motion,
                            width: dayWidth,
                            decoration: BoxDecoration(
                              color: i == selected
                                  ? colors.primary
                                  : colors.surface.withValues(alpha: .55),
                              borderRadius: BorderRadius.circular(
                                  CalmDepth.controlRadius),
                              border: Border.all(
                                  color: i == selected
                                      ? colors.primary.withValues(alpha: .35)
                                      : Colors.transparent),
                            ),
                            child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  key: ValueKey('schedule-day-$i'),
                                  borderRadius: BorderRadius.circular(
                                      CalmDepth.controlRadius),
                                  onTap: () => _select(i),
                                  child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 4, vertical: 8),
                                      child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(labels[i],
                                                style: theme
                                                    .textTheme.labelSmall
                                                    ?.copyWith(
                                                        color: i == selected
                                                            ? colors.onPrimary
                                                            : colors
                                                                .onSurfaceVariant)),
                                            const SizedBox(height: 4),
                                            Text(
                                                '${DateTime(widget.weekStart.year, widget.weekStart.month, widget.weekStart.day + i).day}',
                                                style: theme
                                                    .textTheme.titleSmall
                                                    ?.copyWith(
                                                        color: i == selected
                                                            ? colors.onPrimary
                                                            : colors
                                                                .onSurface)),
                                            const SizedBox(height: 4),
                                            // Today remains visible when another day is selected.
                                            Container(
                                                width: 4,
                                                height: 4,
                                                decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    color: i == _indexOf(today)
                                                        ? (i == selected
                                                            ? colors.onPrimary
                                                            : colors.primary)
                                                        : Colors.transparent)),
                                          ])),
                                )),
                          ),
                        ),
                      ],
                    ]),
                  );
                }),
              ),
            if (widget.trailing != null) ...[
              const SizedBox(height: 28),
              widget.trailing!,
            ],
          ])
        ],
      ),
    );
  }
}
