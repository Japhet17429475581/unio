import '../services/locale_service.dart';
import 'package:flutter/material.dart';

import '../models/lesson.dart';
import '../config/calm_depth.dart';
import '../utils/lesson_type.dart';

/// Строка пары внутри карточки дня (режим «Неделя»)
class LessonRow extends StatelessWidget {
  final Lesson lesson;
  final bool showGroup;
  final VoidCallback? onTap;
  final bool highlighted;
  final bool timeline;
  final bool firstInTimeline;
  final bool lastInTimeline;

  const LessonRow({
    super.key,
    required this.lesson,
    this.showGroup = false,
    this.onTap,
    this.highlighted = false,
    this.timeline = false,
    this.firstInTimeline = false,
    this.lastInTimeline = false,
  });

  @override
  Widget build(BuildContext context) {
    Localizations.localeOf(context);
    final theme = Theme.of(context);
    final calm = timeline && theme.extension<UnioSignature>() != null;
    final style = typeStyle(lesson.type);
    final grey = theme.textTheme.bodySmall
        ?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    final accent = Color.lerp(style.color, theme.colorScheme.onSurface, .4)!;

    final content = Padding(
      padding: timeline
          ? EdgeInsets.zero
          : const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // время
            SizedBox(
              width: 48 * MediaQuery.textScalerOf(context).scale(13) / 13,
              child: Padding(
                  padding: EdgeInsets.only(top: timeline ? 18 : 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lesson.start,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(lesson.end, style: grey),
                    ],
                  )),
            ),
            SizedBox(width: timeline ? 8 : 12),
            if (timeline)
              SizedBox(
                  width: 14,
                  child: Stack(children: [
                    Positioned(
                        left: 6,
                        top: firstInTimeline ? 23 : 0,
                        bottom: lastInTimeline ? null : 0,
                        height:
                            lastInTimeline ? (firstInTimeline ? 0 : 23) : null,
                        child: Container(
                            width: 2, color: theme.colorScheme.outlineVariant)),
                    Positioned(
                        top: 18,
                        left: 2,
                        child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                                color: accent,
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: theme.scaffoldBackgroundColor,
                                    width: 2)))),
                  ]))
            else
              Container(
                  width: 3,
                  decoration: BoxDecoration(
                      color: accent, borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 12),
            // предмет, тип • аудитория, преподаватель
            Expanded(
              child: AnimatedContainer(
                  duration: MediaQuery.disableAnimationsOf(context)
                      ? Duration.zero
                      : Duration(milliseconds: highlighted ? 180 : 900),
                  curve: Curves.easeOutCubic,
                  margin:
                      timeline ? EdgeInsets.only(bottom: calm ? 8 : 12) : null,
                  padding:
                      timeline ? const EdgeInsets.all(16) : EdgeInsets.zero,
                  decoration: timeline
                      ? BoxDecoration(
                          color: Color.lerp(theme.colorScheme.surface, accent,
                              highlighted ? .10 : .025),
                          boxShadow: [
                            BoxShadow(
                                color: const Color(0xFF241744)
                                    .withValues(alpha: .045),
                                blurRadius: 16,
                                offset: const Offset(0, 5))
                          ],
                          borderRadius: BorderRadius.circular(
                              calm ? CalmDepth.cardRadius : 18),
                          border: Border.all(
                              color: highlighted
                                  ? accent
                                  : theme.colorScheme.outlineVariant
                                      .withValues(alpha: .6)),
                        )
                      : null,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lesson.subject,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: style.label,
                              style: TextStyle(
                                color: accent,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (lesson.room.isNotEmpty)
                              TextSpan(
                                  text:
                                      l10n.uiRoom404((lesson.room).toString())),
                          ],
                        ),
                        style: grey,
                      ),
                      if (showGroup
                          ? lesson.group.isNotEmpty
                          : lesson.teacher.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                            showGroup
                                ? l10n.uiGroup405((lesson.group).toString())
                                : lesson.teacher,
                            style: grey),
                      ],
                    ],
                  )),
            ),
          ],
        ),
      ),
    );
    return Material(
      animationDuration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : Duration(milliseconds: highlighted ? 180 : 900),
      color: highlighted && !timeline
          ? theme.colorScheme.primary.withValues(alpha: .08)
          : Colors.transparent,
      child: InkWell(onTap: onTap, child: content),
    );
  }
}
