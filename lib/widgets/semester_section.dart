import '../services/locale_service.dart';
import 'package:flutter/material.dart';
import '../models/portal_progress.dart';
import 'subject_card.dart';

class SemesterSection extends StatelessWidget {
  final int semester;
  final List<PortalSubject> subjects;
  const SemesterSection(
      {super.key, required this.semester, required this.subjects});

  @override
  Widget build(BuildContext context) {
    Localizations.localeOf(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(
          semester == 0
              ? l10n.uiSubjects
              : l10n.uiSemester445((semester).toString()),
          style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 16),
      for (final subject in subjects)
        Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: SubjectCard(subject: subject))
    ]);
  }
}
