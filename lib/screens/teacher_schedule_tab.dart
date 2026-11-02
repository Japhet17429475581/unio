import 'package:flutter/material.dart';

import '../widgets/tap_feedback.dart';
import 'schedule_tab.dart';
import 'teacher_lesson_screen.dart';

class TeacherScheduleTab extends StatelessWidget {
  final String fio;

  const TeacherScheduleTab({super.key, required this.fio});

  @override
  Widget build(BuildContext context) {
    return ScheduleTab.teacher(
      fio: fio,
      onLessonTap: (lesson) {
        tapFeedback();
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => TeacherLessonScreen(lesson: lesson),
        ));
      },
    );
  }
}
