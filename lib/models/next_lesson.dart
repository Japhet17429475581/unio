import 'lesson.dart';

/// VGSPU timetable times use Moscow time (UTC+3), regardless of device timezone.
/// UTC values here represent the university's wall clock, not an API instant.
DateTime universityScheduleNow() =>
    DateTime.now().toUtc().add(const Duration(hours: 3));

DateTime? lessonStartTime(Lesson lesson) {
  final date = lesson.date;
  final match = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(lesson.start.trim());
  if (date == null || match == null) return null;
  final hour = int.parse(match[1]!);
  final minute = int.parse(match[2]!);
  if (hour > 23 || minute > 59) return null;
  return DateTime.utc(date.year, date.month, date.day, hour, minute);
}

class NextLesson {
  final Lesson? lesson;
  final DateTime? startsAt;
  final bool hasLessonsToday;
  final bool hasUnknownTimes;

  const NextLesson._(
      {this.lesson,
      this.startsAt,
      required this.hasLessonsToday,
      required this.hasUnknownTimes});

  factory NextLesson.fromSchedule(List<Lesson> lessons, DateTime now) {
    // Compare calendar/time components: API dates don't carry a timezone.
    final wallNow = DateTime.utc(now.year, now.month, now.day, now.hour,
        now.minute, now.second, now.millisecond, now.microsecond);
    final today = lessons
        .where((l) =>
            l.date?.year == now.year &&
            l.date?.month == now.month &&
            l.date?.day == now.day)
        .toList();
    final upcoming = today
        .where((l) => lessonStartTime(l)?.isAfter(wallNow) == true)
        .toList()
      ..sort((a, b) => lessonStartTime(a)!.compareTo(lessonStartTime(b)!));
    return NextLesson._(
        lesson: upcoming.firstOrNull,
        startsAt: upcoming.isEmpty ? null : lessonStartTime(upcoming.first),
        hasLessonsToday: today.isNotEmpty,
        hasUnknownTimes: today.any((l) => lessonStartTime(l) == null));
  }

  Duration remaining(DateTime now) => startsAt == null
      ? Duration.zero
      : startsAt!.difference(DateTime.utc(now.year, now.month, now.day,
          now.hour, now.minute, now.second, now.millisecond, now.microsecond));
}

String lessonCountdown(Duration remaining) {
  final seconds = (remaining.inMilliseconds / 1000).ceil().clamp(0, 86400);
  final hours = seconds ~/ 3600;
  final minutes = (seconds % 3600) ~/ 60;
  final tail = (seconds % 60).toString().padLeft(2, '0');
  return hours > 0
      ? '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:$tail'
      : '${minutes.toString().padLeft(2, '0')}:$tail';
}
