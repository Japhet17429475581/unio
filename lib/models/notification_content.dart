import 'notification_plan.dart';
import 'portal_request.dart';

/// The compact notification keeps the useful facts visible; the expanded
/// version adds context without repeating the subject or document title.
class NotificationContent {
  final String title, body, expandedBody, subtitle;
  const NotificationContent(
      {required this.title,
      required this.body,
      required this.expandedBody,
      required this.subtitle});

  factory NotificationContent.lesson(NotificationItem item) {
    final lesson = item.lesson;
    final subject = _clean(lesson.subject);
    final title = subject.isEmpty ? _clean(item.title) : subject;
    final start = _clean(lesson.start);
    final end = _clean(lesson.end);
    final room = _clean(lesson.room);
    final time = start.isEmpty
        ? ''
        : end.isEmpty
            ? start
            : '$start–$end';
    final location = room.isEmpty
        ? ''
        : RegExp(r'^(ауд\.?|аудитория)\s', caseSensitive: false).hasMatch(room)
            ? room
            : 'Ауд. $room';
    final facts = [time, location].where((text) => text.isNotEmpty).join(' · ');
    final body = facts.isEmpty ? _clean(item.body) : facts;
    final type = _lessonTypes[lesson.lessonType?.trim().toLowerCase()] ??
        _clean(lesson.lessonType);
    final teacher = _clean(lesson.teacher);
    final context =
        [type, teacher].where((text) => text.isNotEmpty).join(' · ');
    return NotificationContent(
      title: title.isEmpty ? 'Следующая пара' : title,
      body: body,
      expandedBody: [body, context].where((text) => text.isNotEmpty).join('\n'),
      subtitle: item.minutesBefore == 60
          ? 'Через час'
          : item.minutesBefore > 0
              ? 'Через ${item.minutesBefore} мин'
              : 'Расписание',
    );
  }

  factory NotificationContent.request(RequestListItem item,
      {required bool ready}) {
    final name = _clean(item.title);
    final status = _clean(item.displayStatus);
    final title = ready
        ? 'Документ готов'
        : item.canFill
            ? 'Можно заполнить заявление'
            : 'Обновление заявления';
    final document = name.isEmpty ? 'Заявление №${item.id}' : name;
    return NotificationContent(
      title: title,
      body: ready || item.canFill ? document : '$document · $status',
      expandedBody: '$document\nЗаявление №${item.id} · $status\n'
          '${item.canFill ? 'Откройте заявление, чтобы заполнить форму.' : 'Откройте заявление, чтобы посмотреть подробности.'}',
      subtitle: 'Заявления',
    );
  }
}

String _clean(String? value) =>
    (value ?? '').replaceAll(RegExp(r'\s+'), ' ').trim();
const _lessonTypes = {
  'lecture': 'Лекция',
  'practice': 'Практика',
  'lab': 'Лабораторная',
  'seminar': 'Семинар',
  'consultation': 'Консультация',
  'exam': 'Экзамен',
  'credit': 'Зачёт',
};
