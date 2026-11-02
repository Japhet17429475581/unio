class NotificationLesson {
  final String start;
  final String? end;
  final String subject;
  final String? lessonType;
  final String room;
  final String? teacher;

  const NotificationLesson({
    required this.start,
    this.end,
    required this.subject,
    this.lessonType,
    required this.room,
    this.teacher,
  });

  factory NotificationLesson.fromJson(Map<String, dynamic> json) =>
      NotificationLesson(
        start: (json['start'] ?? '').toString(),
        end: json['end'] as String?,
        subject: (json['subject'] ?? '').toString(),
        lessonType: json['lesson_type'] as String?,
        room: (json['room'] ?? '').toString(),
        teacher: json['teacher'] as String?,
      );
}

class NotificationItem {
  final String id;
  final DateTime? scheduledAt;
  final int minutesBefore;
  final String title;
  final String body;
  final String date;
  final NotificationLesson lesson;
  final bool past;

  const NotificationItem({
    required this.id,
    required this.scheduledAt,
    required this.minutesBefore,
    required this.title,
    required this.body,
    required this.date,
    required this.lesson,
    required this.past,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) =>
      NotificationItem(
        id: (json['id'] ?? '').toString(),
        // Даты без смещения — время вуза; сервис планирования назначает
        // Europe/Moscow. Даты с явным смещением сохраняют свой момент UTC.
        scheduledAt: DateTime.tryParse((json['scheduled_at'] ?? '').toString()),
        minutesBefore: (json['minutes_before'] as num?)?.toInt() ?? 0,
        title: (json['title'] ?? '').toString(),
        body: (json['body'] ?? '').toString(),
        date: (json['date'] ?? '').toString(),
        lesson: NotificationLesson.fromJson(
          (json['lesson'] as Map<String, dynamic>?) ?? const {},
        ),
        past: json['past'] == true,
      );
}
