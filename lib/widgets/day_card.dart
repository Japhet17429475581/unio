import '../services/locale_service.dart';
import 'package:flutter/material.dart';
import '../config/calm_depth.dart';
import '../models/lesson.dart';
import '../utils/date_utils.dart';
import 'lesson_row.dart';
import 'unio_card.dart';

class DayCard extends StatelessWidget {
  final DateTime day;
  final bool isToday;
  final List<Lesson> lessons;
  final bool showGroups;
  final bool showScheduleHeader;
  final ValueChanged<Lesson>? onLessonTap;
  final Lesson? focusedLesson;
  final bool highlightFocus;
  final GlobalKey? focusKey;
  final Widget? daySelector;
  const DayCard(
      {super.key,
      required this.day,
      required this.isToday,
      required this.lessons,
      this.showGroups = false,
      this.showScheduleHeader = true,
      this.onLessonTap,
      this.focusedLesson,
      this.highlightFocus = true,
      this.focusKey,
      this.daySelector});

  @override
  Widget build(BuildContext context) {
    Localizations.localeOf(context);
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final calm = theme.extension<UnioSignature>() != null;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (daySelector != null && (calm || !showScheduleHeader))
        daySelector!
      else if (showScheduleHeader)
        UnioCard(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        runSpacing: 6,
                        spacing: 12,
                        children: [
                          Text(
                              isToday && daySelector != null
                                  ? l10n.uiToday330
                                  : l10n.uiSchedule297,
                              style: theme.textTheme.labelSmall
                                  ?.copyWith(color: muted, letterSpacing: .8)),
                          Text(dayMonthLabel(day),
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(color: muted)),
                        ]),
                  ),
                  if (daySelector != null) ...[
                    const SizedBox(height: 16),
                    daySelector!,
                  ],
                ])),
      Padding(
        padding: EdgeInsets.fromLTRB(
            0,
            !showScheduleHeader && daySelector == null ? 0 : (calm ? 20 : 24),
            0,
            calm ? 12 : 16),
        child: Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(weekdayName(day),
                  style: calm
                      ? theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700)
                      : theme.textTheme.titleLarge),
              if (calm)
                Text(dayMonthLabel(day),
                    style: theme.textTheme.bodySmall?.copyWith(color: muted)),
              Text(
                  isToday
                      ? l10n.uiToday331
                      : '· ${lessons.length} ${pairsLabel(lessons.length)}',
                  style: theme.textTheme.bodySmall?.copyWith(color: muted)),
            ]),
      ),
      if (lessons.isEmpty)
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
          child: Column(children: [
            Icon(Icons.wb_sunny_outlined,
                color: theme.colorScheme.primary, size: 32),
            const SizedBox(height: 12),
            Text(
                daySelector == null
                    ? l10n.uiNoClasses
                    : l10n.uiNoClassesTakeABreak,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleSmall),
            const SizedBox(height: 6),
            Text(l10n.uiChooseAnotherDayToViewItsSchedule,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(color: muted)),
          ]),
        )
      else
        for (var index = 0; index < lessons.length; index++)
          LessonRow(
            key: identical(lessons[index], focusedLesson) ? focusKey : null,
            lesson: lessons[index],
            timeline: true,
            firstInTimeline: index == 0,
            lastInTimeline: index == lessons.length - 1,
            highlighted:
                highlightFocus && identical(lessons[index], focusedLesson),
            showGroup: showGroups,
            onTap:
                onLessonTap == null ? null : () => onLessonTap!(lessons[index]),
          ),
    ]);
  }
}
