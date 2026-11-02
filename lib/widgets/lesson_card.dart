import 'package:flutter/material.dart';
import '../models/lesson.dart';
import 'lesson_row.dart';
import 'unio_card.dart';

class LessonCard extends StatelessWidget {
  final Lesson lesson;
  const LessonCard({super.key, required this.lesson});
  @override
  Widget build(BuildContext context) => UnioCard(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: LessonRow(lesson: lesson),
      );
}
