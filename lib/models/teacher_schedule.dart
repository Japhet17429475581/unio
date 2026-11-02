import 'lesson.dart';

class TeacherSchedule {
  final List<Lesson> lessons;
  final List<String> groupsPreview;
  final int groupsTotal;
  final bool hasMoreGroups;
  final bool fromLocalCache;

  const TeacherSchedule({
    required this.lessons,
    required this.groupsPreview,
    required this.groupsTotal,
    required this.hasMoreGroups,
    this.fromLocalCache = false,
  });

  factory TeacherSchedule.fromJson(Map<String, dynamic> json,
      {bool fromLocalCache = false}) {
    final lessons = json['lessons'];
    final groups = json['groups'];
    if (lessons is! List || groups is! Map<String, dynamic>) {
      throw const FormatException('Некорректное расписание преподавателя');
    }
    return TeacherSchedule(
      fromLocalCache: fromLocalCache,
      lessons: lessons
          .map((item) => Lesson.fromJson(item as Map<String, dynamic>))
          .toList()
        ..sort(compareLessons),
      groupsPreview: (groups['preview'] as List).cast<String>(),
      groupsTotal: groups['total'] as int,
      hasMoreGroups: groups['has_more'] == true,
    );
  }
}

class FreeRooms {
  final List<String> rooms;
  final String note;

  const FreeRooms({required this.rooms, required this.note});

  factory FreeRooms.fromJson(Map<String, dynamic> json) {
    return FreeRooms(
      rooms: (json['rooms'] as List).cast<String>(),
      note: json['note'] as String? ??
          'Свободные аудитории определяются по расписаниям, '
              'которые уже известны UNIO.',
    );
  }
}
