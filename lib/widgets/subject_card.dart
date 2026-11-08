import '../services/locale_service.dart';
import 'package:flutter/material.dart';
import '../models/portal_progress.dart';
import 'unio_card.dart';
import 'tap_feedback.dart';

String _value(dynamic value) =>
    value == null || '$value'.trim().isEmpty ? '—' : '$value';

class SubjectCard extends StatelessWidget {
  final PortalSubject subject;
  final bool initiallyExpanded;
  const SubjectCard(
      {super.key, required this.subject, this.initiallyExpanded = false});

  @override
  Widget build(BuildContext context) {
    Localizations.localeOf(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final grade = _value(subject.exam?.grade);
    final normalized = grade.toLowerCase().replaceAll('ё', 'е');
    final passed = {
      'отлично',
      'хорошо',
      'удовлетворительно',
      'зачтено',
      'зачет',
      '3',
      '4',
      '5'
    }.contains(normalized);
    final failed = {
      'неудовлетворительно',
      'не зачтено',
      'незачтено',
      'не зачет',
      'незачет',
      '2'
    }.contains(normalized);
    final accent = failed
        ? colors.error
        : passed
            ? colors.tertiary
            : colors.onSurfaceVariant;
    final cuts = [subject.firstCut, subject.secondCut, subject.thirdCut];
    return UnioCard(
        padding: const EdgeInsets.all(18),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(subject.subject, style: theme.textTheme.titleMedium),
          const SizedBox(height: 14),
          Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: accent.withValues(alpha: .10),
                  borderRadius: BorderRadius.circular(14)),
              child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    Text(grade == '—' ? l10n.uiNoResultYet : grade,
                        style: theme.textTheme.titleSmall
                            ?.copyWith(color: accent)),
                    Text(l10n.uiPts((_value(subject.exam?.points)).toString()),
                        style: theme.textTheme.titleMedium
                            ?.copyWith(color: colors.onSurface)),
                  ])),
          if (cuts.any((cut) => cut != null && !cut.isEmpty))
            QuietTap(
                child: ExpansionTile(
              initiallyExpanded: initiallyExpanded,
              key:
                  PageStorageKey('cuts-${subject.semester}-${subject.subject}'),
              tilePadding: EdgeInsets.zero,
              childrenPadding: EdgeInsets.zero,
              shape: const Border(),
              collapsedShape: const Border(),
              title: Text(l10n.uiCheckpointsAndAbsences,
                  style: theme.textTheme.labelMedium
                      ?.copyWith(color: colors.primary)),
              children: [
                for (var i = 0; i < cuts.length; i++)
                  Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                              color: colors.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(12)),
                          child: Wrap(
                              spacing: 16,
                              runSpacing: 8,
                              alignment: WrapAlignment.spaceBetween,
                              children: [
                                Text(l10n.uiCheckpoint((i + 1).toString()),
                                    style: theme.textTheme.labelMedium),
                                Text(
                                    l10n.uiPts(
                                        (_value(cuts[i]?.score)).toString()),
                                    style: theme.textTheme.bodySmall),
                                Text(
                                    l10n.uiMissedH(
                                        (_value(cuts[i]?.hours)).toString()),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                        color: colors.onSurfaceVariant)),
                              ])))
              ],
            )),
        ]));
  }
}
