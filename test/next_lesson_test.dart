import 'package:flutter_test/flutter_test.dart';
import 'package:unio_app/models/lesson.dart';
import 'package:unio_app/models/next_lesson.dart';

Lesson lesson(String start, {String subject = 'Предмет', int day = 9}) =>
    Lesson(
        date: DateTime(2026, 10, day),
        start: start,
        end: '12:30',
        subject: subject,
        type: 'lecture',
        teacher: '',
        room: '314');

void main() {
  test('Only the next start today is selected, excluding ongoing and tomorrow',
      () {
    final next = lesson('11:00', subject: 'Следующая');
    final result = NextLesson.fromSchedule([
      lesson('12:30'),
      lesson('09:00', subject: 'Текущая'),
      lesson('08:00', day: 10),
      next,
    ], DateTime.utc(2026, 10, 9, 9, 30));
    expect(result.lesson, same(next));
    expect(result.remaining(DateTime.utc(2026, 10, 9, 9, 30)),
        const Duration(minutes: 90));
  });

  test('At the exact start, the counter switches to the following lesson', () {
    final result = NextLesson.fromSchedule(
        [lesson('09:00'), lesson('11:00')], DateTime.utc(2026, 10, 9, 9));
    expect(result.lesson?.start, '11:00');
  });

  test('Empty day and no more starts today have distinct states', () {
    final empty = NextLesson.fromSchedule(
        [lesson('11:00', day: 10)], DateTime.utc(2026, 10, 9, 14));
    final done = NextLesson.fromSchedule(
        [lesson('11:00')], DateTime.utc(2026, 10, 9, 14));
    expect(empty.hasLessonsToday, isFalse);
    expect(done.hasLessonsToday, isTrue);
    expect(done.lesson, isNull);
  });

  test('Unknown or invalid time is not mistaken for a finished day', () {
    final result = NextLesson.fromSchedule(
        [lesson('24:15'), lesson('09:75'), lesson('—')],
        DateTime.utc(2026, 10, 9, 9));
    expect(result.hasUnknownTimes, isTrue);
    expect(result.lesson, isNull);
  });

  test('Clock components work with both local and UTC API date representations',
      () {
    final item = lesson('11:00');
    final local =
        NextLesson.fromSchedule([item], DateTime(2026, 10, 9, 10, 59));
    final utc =
        NextLesson.fromSchedule([item], DateTime.utc(2026, 10, 9, 10, 59));
    expect(local.remaining(DateTime(2026, 10, 9, 10, 59)),
        const Duration(minutes: 1));
    expect(utc.remaining(DateTime.utc(2026, 10, 9, 10, 59)),
        const Duration(minutes: 1));
  });

  test('Counter formats hours and seconds without showing zero early', () {
    expect(lessonCountdown(const Duration(hours: 1, minutes: 2, seconds: 3)),
        '01:02:03');
    expect(lessonCountdown(const Duration(seconds: 59)), '00:59');
    expect(lessonCountdown(const Duration(milliseconds: 1)), '00:01');
    expect(lessonCountdown(const Duration(seconds: -1)), '00:00');
  });
}
