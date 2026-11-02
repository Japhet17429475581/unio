import '../services/locale_service.dart';
import '../utils/user_messages.dart';
import 'package:flutter/foundation.dart';
import '../services/web_portal_service.dart';
import 'package:flutter/material.dart';

import '../widgets/unio_loader.dart';

import '../models/portal_progress.dart';
import '../services/portal_grades_repository.dart';
import '../widgets/message.dart';
import '../widgets/portal_gate.dart';
import '../widgets/semester_section.dart';
import '../widgets/signature_surface.dart';
import '../widgets/feature_header.dart';

/// Вкладка «Успеваемость». Доступна только после входа через портал —
/// это обеспечивает PortalGate, форма логина здесь больше не нужна.
class GradebookTab extends StatelessWidget {
  final bool isPortalMode;
  final Future<void> Function(String login, String password) onUpgradeToPortal;
  final PortalGradesRepository? repository;

  const GradebookTab({
    super.key,
    required this.isPortalMode,
    required this.onUpgradeToPortal,
    this.repository,
  });

  @override
  Widget build(BuildContext context) {
    Localizations.localeOf(context);
    return PortalGate(
      isPortalMode: isPortalMode,
      modern: true,
      onUpgrade: onUpgradeToPortal,
      featureName: l10n.uiAcademicProgress,
      description: l10n.uiPointsGradesAndPassResultsOrganisedBySemester,
      signInDescription: l10n.uiSignInWithYourUniversityAccountToView,
      icon: Icons.school_rounded,
      builder: (_) => _GradesView(repository: repository),
    );
  }
}

class _GradesView extends StatefulWidget {
  final PortalGradesRepository? repository;
  const _GradesView({this.repository});

  @override
  State<_GradesView> createState() => _GradesViewState();
}

class _GradesViewState extends State<_GradesView> {
  late final PortalGradesRepository _repository;
  late Future<PortalProgressResult> _future;
  int? _selectedSemester;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? PortalGradesRepository();
    _future = _repository.load();
    if (kIsWeb) webPortal.authChanges.addListener(_reauthenticated);
  }

  void _reauthenticated() {
    _repository.clear();
    if (mounted) _reload();
  }

  @override
  void dispose() {
    if (widget.repository == null) _repository.clear();
    if (kIsWeb) webPortal.authChanges.removeListener(_reauthenticated);
    super.dispose();
  }

  Future<void> _reload() async {
    final future = _repository.load(refresh: true);
    setState(() => _future = future);
    try {
      await future;
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    Localizations.localeOf(context);
    return FutureBuilder<PortalProgressResult>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: UnioLoader());
        }

        if (snapshot.hasError) {
          final error = snapshot.error;
          return Message(
            icon: Icons.cloud_off_rounded,
            title: l10n.uiCouldNotLoadAcademicProgress,
            text: userMessage(error),
            actionLabel: l10n.uiTryAgain,
            onAction: _reload,
          );
        }

        final result = snapshot.data!;

        if (!result.success) {
          return Message(
            icon: Icons.error_outline_rounded,
            title: l10n.uiCouldNotRetrieveAcademicProgress,
            text: result.message,
            actionLabel: l10n.uiTryAgain,
            onAction: _reload,
          );
        }

        if (result.subjects.isEmpty) {
          return UnioRefreshIndicator(
            onRefresh: _reload,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(height: 80),
                Message(
                  icon: Icons.inbox_outlined,
                  title: l10n.uiNoDataYet,
                  text: l10n.uiPullDownToRefresh,
                ),
              ],
            ),
          );
        }

        final theme = Theme.of(context);
        final bySemester = <int, List<PortalSubject>>{};
        for (final subject in result.subjects) {
          bySemester.putIfAbsent(subject.semester, () => []).add(subject);
        }
        final semesters = bySemester.keys.toList()
          ..sort((a, b) => b.compareTo(a));
        final selected = semesters.contains(_selectedSemester)
            ? _selectedSemester!
            : semesters.first;

        return UnioRefreshIndicator(
          onRefresh: _reload,
          child: SignatureBackdrop(
              child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            children: [
              FeatureHeader(
                  eyebrow: l10n.uiVgspuPortal,
                  title: l10n.uiAcademicProgress,
                  icon: Icons.school_outlined,
                  description: l10n.uiPointsAbsencesAndSubjectResults),
              const SizedBox(height: 20),
              if (semesters.length > 1) ...[
                SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(children: [
                      for (final semester in semesters)
                        Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                                label: Text(semester == 0
                                    ? l10n.uiNoSemester
                                    : l10n.uiSemester((semester).toString())),
                                selected: selected == semester,
                                onSelected: (_) => setState(
                                    () => _selectedSemester = semester)))
                    ])),
                const SizedBox(height: 20),
              ],
              SemesterSection(
                  semester: selected, subjects: bySemester[selected]!),
              const SizedBox(height: 16),
              Text(l10n.uiEachCheckpointShowsCumulativePointsAndHoursMissed,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ],
          )),
        );
      },
    );
  }
}
