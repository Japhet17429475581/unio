import '../services/locale_service.dart';
import '../services/analytics_service.dart';
import '../utils/user_messages.dart';
import 'package:flutter/material.dart';

import '../widgets/unio_loader.dart';

import '../config/brand.dart';
import '../models/lesson.dart';
import '../models/teacher_schedule.dart';
import '../services/teachers_service.dart';
import '../utils/date_utils.dart';
import '../utils/lesson_type.dart';
import '../widgets/message.dart';
import '../widgets/lesson_actions.dart';
import '../widgets/unio_card.dart';
import '../widgets/feature_header.dart';

class TeacherLessonScreen extends StatelessWidget {
  final Lesson lesson;

  const TeacherLessonScreen({super.key, required this.lesson});

  @override
  Widget build(BuildContext context) {
    Localizations.localeOf(context);
    final type = typeStyle(lesson.type);
    final date = lesson.date;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.uiClass)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(UnioSpacing.lg),
          children: [
            FeatureHeader(
                compact: true,
                eyebrow: type.label,
                title: lesson.subject,
                description: l10n.uiClassDetailsAndTeachingTools,
                icon: Icons.school_outlined),
            const SizedBox(height: 16),
            UnioCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (date != null)
                    _DetailRow(
                        icon: Icons.calendar_today_rounded,
                        text: fullDateLabel(date)),
                  _DetailRow(
                      icon: Icons.schedule_rounded,
                      text: '${lesson.start} – ${lesson.end}'),
                  _DetailRow(
                    icon: Icons.meeting_room_rounded,
                    text: lesson.room.isEmpty
                        ? l10n.uiRoomNotSpecified
                        : l10n.uiRoom((lesson.room).toString()),
                  ),
                ],
              ),
            ),
            const SizedBox(height: UnioSpacing.xl),
            LessonActions(actions: [
              LessonAction(
                label: l10n.uiFindAnAvailableRoom,
                icon: Icons.meeting_room_outlined,
                selected: true,
                onTap:
                    date == null || lesson.start.isEmpty || lesson.end.isEmpty
                        ? null
                        : () => Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) => FreeRoomsScreen(lesson: lesson),
                            )),
              ),
              LessonAction(
                  label: l10n.uiBackToSchedule,
                  icon: Icons.calendar_month_rounded,
                  onTap: () => Navigator.of(context).maybePop()),
            ]),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _DetailRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    Localizations.localeOf(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: UnioSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: UnioSpacing.md),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class FreeRoomsScreen extends StatefulWidget {
  final Lesson lesson;

  const FreeRoomsScreen({super.key, required this.lesson});

  @override
  State<FreeRoomsScreen> createState() => _FreeRoomsScreenState();
}

class _FreeRoomsScreenState extends State<FreeRoomsScreen> {
  late Future<FreeRooms> _future;

  Future<FreeRooms> _request() => fetchFreeRooms(
        date: widget.lesson.date!,
        start: widget.lesson.start,
        end: widget.lesson.end,
      );

  @override
  void initState() {
    super.initState();
    analytics.screen(AnalyticsScreen.freeRooms, role: AnalyticsRole.teacher);
    analytics.track(AnalyticsEvent.roomsSearch, role: AnalyticsRole.teacher);
    _future = _request();
  }

  Future<void> _reload() async {
    final future = _request();
    setState(() {
      _future = future;
    });
    try {
      await future;
    } catch (_) {
      // Ошибку показывает FutureBuilder.
    }
  }

  @override
  Widget build(BuildContext context) {
    Localizations.localeOf(context);
    final lesson = widget.lesson;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.uiAvailableRooms)),
      body: SafeArea(
        child: FutureBuilder<FreeRooms>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: UnioLoader());
            }
            if (snapshot.hasError) {
              final error = snapshot.error;
              return SingleChildScrollView(
                child: Message(
                  icon: Icons.cloud_off_rounded,
                  title: l10n.uiCouldNotFindRooms,
                  text: userMessage(error),
                  actionLabel: l10n.uiTryAgain,
                  onAction: _reload,
                ),
              );
            }
            final result = snapshot.data!;
            return UnioRefreshIndicator(
              onRefresh: _reload,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(UnioSpacing.lg),
                children: [
                  FeatureHeader(
                      compact: true,
                      eyebrow: l10n.uiForTeachers,
                      title: l10n.uiARoomForYourClass,
                      description:
                          '${fullDateLabel(lesson.date!)} · ${lesson.start}–${lesson.end}',
                      icon: Icons.meeting_room_outlined),
                  const SizedBox(height: UnioSpacing.xl),
                  UnioCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.info_outline_rounded,
                                color: theme.colorScheme.primary),
                            const SizedBox(width: UnioSpacing.sm),
                            Expanded(
                                child: Text(result.note,
                                    style: theme.textTheme.bodySmall)),
                          ],
                        ),
                        const SizedBox(height: UnioSpacing.lg),
                        if (result.rooms.isEmpty)
                          Text(l10n.uiNoAvailableRoomsFoundInTheKnownSchedules,
                              style: theme.textTheme.bodyMedium)
                        else
                          Wrap(
                            spacing: UnioSpacing.sm,
                            runSpacing: UnioSpacing.sm,
                            children: [
                              for (final room in result.rooms)
                                Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 18, vertical: 20),
                                    decoration: BoxDecoration(
                                        color: theme
                                            .colorScheme.primaryContainer
                                            .withValues(alpha: .5),
                                        borderRadius:
                                            BorderRadius.circular(16)),
                                    child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.meeting_room_outlined,
                                              color: theme.colorScheme.primary),
                                          const SizedBox(height: 10),
                                          Text(
                                              l10n.uiRoom224((room).toString()),
                                              style:
                                                  theme.textTheme.titleSmall),
                                        ])),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
