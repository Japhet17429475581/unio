import '../services/locale_service.dart';
import 'signature_surface.dart';
import 'dart:async';

import 'package:flutter/material.dart';

import '../config/calm_depth.dart';
import '../models/lesson.dart';
import '../models/next_lesson.dart';

/// A summary of today's next start; an ongoing lesson is intentionally skipped.
class NextLessonCard extends StatefulWidget {
  final Future<List<Lesson>> schedule;
  final ValueChanged<Lesson> onLessonTap;
  final VoidCallback onRetry;
  final DateTime Function() clock;

  const NextLessonCard(
      {super.key,
      required this.schedule,
      required this.onLessonTap,
      required this.onRetry,
      this.clock = universityScheduleNow});

  @override
  State<NextLessonCard> createState() => _NextLessonCardState();
}

class _NextLessonCardState extends State<NextLessonCard>
    with WidgetsBindingObserver {
  Timer? _timer;
  late DateTime _now;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _now = widget.clock();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = widget.clock());
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      setState(() => _now = widget.clock());
      _startTimer();
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

  @override
  Widget build(BuildContext context) {
    Localizations.localeOf(context);
    return FutureBuilder<List<Lesson>>(
        future: widget.schedule,
        builder: (context, snapshot) {
          final theme = Theme.of(context);
          final signature =
              theme.extension<UnioSignature>() ?? const UnioSignature();
          if (snapshot.connectionState != ConnectionState.done) {
            return _quiet(Icons.schedule_rounded, l10n.uiLoadingTodaySClasses);
          }
          if (snapshot.hasError) {
            return _quiet(
                Icons.cloud_off_rounded, l10n.uiTodaySScheduleHasNotLoaded,
                onTap: widget.onRetry, caption: l10n.uiTapToTryAgain);
          }
          if (snapshot.data?.isEmpty ?? true) {
            return _quiet(
                Icons.event_note_rounded, l10n.uiNoScheduleFoundForThisWeek409,
                onTap: widget.onRetry, caption: l10n.uiTapToRefresh);
          }
          final next = NextLesson.fromSchedule(snapshot.data ?? [], _now);
          final lesson = next.lesson;
          if (lesson == null) {
            return _quiet(
                next.hasLessonsToday
                    ? Icons.task_alt_rounded
                    : Icons.wb_sunny_outlined,
                next.hasUnknownTimes
                    ? l10n.uiTimesForUpcomingClassesAreNotSpecified411
                    : next.hasLessonsToday
                        ? l10n.uiNoMoreClassesToday412
                        : l10n.uiNoClassesTodayEnjoyYourBreak,
                signature: true);
          }
          return TweenAnimationBuilder<double>(
              key: ValueKey('${lesson.date}-${lesson.start}-${lesson.subject}'),
              tween: Tween(begin: 0, end: 1),
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : CalmDepth.motion,
              curve: Curves.easeOutCubic,
              builder: (context, value, child) => Opacity(
                  opacity: value,
                  child: Transform.translate(
                      offset: Offset(0, 8 * (1 - value)), child: child)),
              child: Semantics(
                  button: true,
                  excludeSemantics: true,
                  onTap: () => widget.onLessonTap(lesson),
                  label: l10n.uiNextClassTodayGoToThisClassIn(
                      (lesson.subject).toString(),
                      (lesson.start).toString(),
                      (lesson.end).toString(),
                      (lesson.room.isEmpty
                              ? ''
                              : l10n.semanticRoomSuffix(lesson.room))
                          .toString()),
                  child: Material(
                      color: signature.start,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(26)),
                      clipBehavior: Clip.antiAlias,
                      child: SignatureSurface(
                          padding: EdgeInsets.zero,
                          child: InkWell(
                              onTap: () => widget.onLessonTap(lesson),
                              splashColor:
                                  signature.accent.withValues(alpha: .12),
                              child: Padding(
                                  padding: const EdgeInsets.all(22),
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        Row(children: [
                                          ExcludeSemantics(
                                              child: CustomPaint(
                                                  size: const Size(20, 20),
                                                  painter: _SignatureRibbon(
                                                      signature.accent))),
                                          const SizedBox(width: 8),
                                          Expanded(
                                              child: Text(
                                                  l10n.uiNextClassToday415,
                                                  style: theme
                                                      .textTheme.labelMedium
                                                      ?.copyWith(
                                                          color: signature
                                                              .secondary))),
                                          const SizedBox(width: 8),
                                          Icon(Icons.arrow_forward_rounded,
                                              size: 18,
                                              color: signature.secondary)
                                        ]),
                                        const SizedBox(height: 12),
                                        Text(lesson.subject,
                                            style: theme.textTheme.titleLarge
                                                ?.copyWith(
                                                    color: signature.foreground,
                                                    fontSize: 20,
                                                    height: 1.25,
                                                    fontWeight:
                                                        FontWeight.w700)),
                                        const SizedBox(height: 16),
                                        Wrap(
                                            alignment:
                                                WrapAlignment.spaceBetween,
                                            crossAxisAlignment:
                                                WrapCrossAlignment.end,
                                            spacing: 16,
                                            runSpacing: 12,
                                            children: [
                                              Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                        '${lesson.start}–${lesson.end}',
                                                        style: theme.textTheme
                                                            .titleSmall
                                                            ?.copyWith(
                                                                color: signature
                                                                    .foreground,
                                                                fontFeatures: const [
                                                              FontFeature
                                                                  .tabularFigures()
                                                            ])),
                                                    if (lesson
                                                        .room.isNotEmpty) ...[
                                                      const SizedBox(height: 4),
                                                      Text(
                                                          l10n.uiRoom224(
                                                              (lesson.room)
                                                                  .toString()),
                                                          style: theme.textTheme
                                                              .bodySmall
                                                              ?.copyWith(
                                                                  color: signature
                                                                      .secondary))
                                                    ]
                                                  ]),
                                              ExcludeSemantics(
                                                  child: Container(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 12,
                                                          vertical: 8),
                                                      decoration: BoxDecoration(
                                                          color: signature
                                                              .foreground
                                                              .withValues(
                                                                  alpha: .08),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                                      12)),
                                                      child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .end,
                                                          children: [
                                                            Text(
                                                                l10n.uiStartsIn,
                                                                style: theme
                                                                    .textTheme
                                                                    .labelSmall
                                                                    ?.copyWith(
                                                                        color: signature
                                                                            .secondary)),
                                                            Text(
                                                                lessonCountdown(
                                                                    next.remaining(
                                                                        _now)),
                                                                key: const ValueKey(
                                                                    'next-lesson-countdown'),
                                                                style: theme
                                                                    .textTheme
                                                                    .titleMedium
                                                                    ?.copyWith(
                                                                        color: signature
                                                                            .foreground,
                                                                        fontWeight: FontWeight.w600,
                                                                        fontFeatures: const [
                                                                      FontFeature
                                                                          .tabularFigures()
                                                                    ]))
                                                          ])))
                                            ])
                                      ])))))));
        });
  }

  Widget _quiet(IconData icon, String text,
      {VoidCallback? onTap, String? caption, bool signature = false}) {
    final theme = Theme.of(context);
    if (signature) {
      return SignatureSurface(
          child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .10),
                    borderRadius: BorderRadius.circular(14)),
                child: Icon(icon, color: const Color(0xFFBFAAFF), size: 24)),
            const SizedBox(width: 12),
            Text(l10n.uiYourDay,
                style: theme.textTheme.labelMedium
                    ?.copyWith(color: const Color(0xFFD1D6ED))),
          ]),
          const SizedBox(height: 16),
          Text(text,
              style: theme.textTheme.titleLarge
                  ?.copyWith(color: Colors.white, height: 1.3)),
          const SizedBox(height: 8),
          Text(l10n.uiTheScheduleForOtherDaysIsBelow,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: const Color(0xFFD1D6ED))),
        ],
      ));
    }
    return Material(
      color: theme.colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(26),
      child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(26),
          child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(children: [
                Icon(icon, size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(text, style: theme.textTheme.bodyMedium),
                      if (caption != null)
                        Text(caption, style: theme.textTheme.bodySmall),
                    ])),
              ]))),
    );
  }
}

class _SignatureRibbon extends CustomPainter {
  final Color color;
  const _SignatureRibbon(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(
        Path()
          ..moveTo(4, 4)
          ..lineTo(4, 11)
          ..cubicTo(4, 19, 16, 19, 16, 11)
          ..lineTo(16, 6),
        paint);
    canvas.drawLine(
        const Offset(12, 4),
        const Offset(16, 2),
        Paint()
          ..color = color.withValues(alpha: .55)
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(_SignatureRibbon oldDelegate) =>
      color != oldDelegate.color;
}
