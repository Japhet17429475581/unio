/// Portal times may use either 9:40 or 09:40. Unknown times follow timed lessons.
int? lessonMinutes(String value) {
  final match = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(value.trim());
  if (match == null) return null;
  final hour = int.parse(match[1]!);
  final minute = int.parse(match[2]!);
  return hour < 24 && minute < 60 ? hour * 60 + minute : null;
}

int compareLessons(Lesson a, Lesson b) {
  final day = (a.date ?? DateTime(9999)).compareTo(b.date ?? DateTime(9999));
  if (day != 0) return day;
  final start = (lessonMinutes(a.start) ?? 1440)
      .compareTo(lessonMinutes(b.start) ?? 1440);
  if (start != 0) return start;
  final end =
      (lessonMinutes(a.end) ?? 1440).compareTo(lessonMinutes(b.end) ?? 1440);
  if (end != 0) return end;
  final subject = a.subject.compareTo(b.subject);
  return subject != 0 ? subject : a.group.compareTo(b.group);
}

class Lesson {
  final DateTime? date;
  final String start;
  final String end;
  final String subject;
  final String? type;
  final String teacher;
  final String room;
  final String group;

  Lesson({
    required this.date,
    required this.start,
    required this.end,
    required this.subject,
    required this.type,
    required this.teacher,
    required this.room,
    this.group = '',
  });

  factory Lesson.fromJson(Map<String, dynamic> json) {
    return Lesson(
      date: DateTime.tryParse((json['date'] ?? '') as String),
      start: json['start'] ?? '',
      end: json['end'] ?? '',
      subject: json['subject'] ?? '',
      type: json['lesson_type'],
      teacher: json['teacher'] ?? '',
      room: json['room'] ?? '',
      group: json['group'] ?? '',
    );
  }
}
