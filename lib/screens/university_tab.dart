import '../services/locale_service.dart';
import 'package:flutter/material.dart';
import '../widgets/feature_header.dart';
import '../widgets/signature_surface.dart';

import '../widgets/portal_gate.dart';
import '../widgets/tap_feedback.dart';
import 'news_list_screen.dart';
import 'requests_list_screen.dart';
import 'teacher_search_screen.dart';

class _UniversityTile {
  final IconData icon;
  final String label;
  final String subtitle;
  final WidgetBuilder builder;

  const _UniversityTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.builder,
  });
}

/// Вкладка «Университет»: сервисы и новости.
/// Новый раздел — это просто ещё одна запись в списке [_tiles] ниже.
class UniversityTab extends StatelessWidget {
  final bool isPortalMode;
  final Future<void> Function(String login, String password)? onUpgradeToPortal;
  final bool isTeacher;

  const UniversityTab({
    super.key,
    required this.isPortalMode,
    required this.onUpgradeToPortal,
  }) : isTeacher = false;

  const UniversityTab.teacher({super.key})
      : isTeacher = true,
        isPortalMode = false,
        onUpgradeToPortal = null;

  List<_UniversityTile> get _tiles => [
        _UniversityTile(
          icon: Icons.article_rounded,
          label: l10n.uiNews,
          subtitle: l10n.uiUniversityEventsAnnouncementsAndCampusLife,
          builder: (_) => const NewsListScreen(),
        ),
        if (!isTeacher)
          _UniversityTile(
            icon: Icons.edit_document,
            label: l10n.uiSubmitAnApplication,
            subtitle: l10n.uiCertificatesFormsAndPortalResponses,
            builder: (_) => RequestsEntryScreen(
                isPortalMode: isPortalMode, onUpgrade: onUpgradeToPortal!),
          ),
        _UniversityTile(
            icon: Icons.person_search_rounded,
            label: l10n.uiTeachers,
            subtitle: l10n.uiSearchBySurnameClassesAndRooms,
            builder: (_) => const TeacherSearchScreen()),
      ];

  @override
  Widget build(BuildContext context) {
    Localizations.localeOf(context);
    final theme = Theme.of(context);
    return SignatureBackdrop(
        child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
          FeatureHeader(
              eyebrow: l10n.uiUnioUniversity,
              title: l10n.uiForYourStudies,
              description: l10n.uiNewsApplicationsAndTeacherSearchInOnePlace,
              icon: Icons.account_balance_rounded),
          const SizedBox(height: 24),
          for (final tile in _tiles)
            Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: FeatureLink(
                    title: tile.label,
                    subtitle: tile.subtitle,
                    icon: tile.icon,
                    accent: tile.icon == Icons.edit_document
                        ? theme.colorScheme.secondary
                        : tile.icon == Icons.person_search_rounded
                            ? theme.colorScheme.onSurfaceVariant
                            : theme.colorScheme.primary,
                    onTap: () {
                      tapFeedback();
                      Navigator.of(context)
                          .push(MaterialPageRoute(builder: tile.builder));
                    })),
        ]));
  }
}

class RequestsEntryScreen extends StatefulWidget {
  final bool isPortalMode;
  final Future<void> Function(String, String) onUpgrade;
  const RequestsEntryScreen(
      {super.key, required this.isPortalMode, required this.onUpgrade});
  @override
  State<RequestsEntryScreen> createState() => _RequestsEntryScreenState();
}

class _RequestsEntryScreenState extends State<RequestsEntryScreen> {
  bool _authenticated = false;
  @override
  Widget build(BuildContext context) {
    Localizations.localeOf(context);
    if (widget.isPortalMode || _authenticated)
      return const RequestsListScreen();
    return Scaffold(
      appBar: AppBar(title: Text(l10n.uiApplications)),
      body: SafeArea(
          child: PortalGate(
        isPortalMode: false,
        modern: true,
        onUpgrade: widget.onUpgrade,
        onAuthenticated: () => setState(() => _authenticated = true),
        featureName: l10n.uiCertificatesAndApplications,
        signInDescription:
            l10n.uiUseYourUniversityAccountYourApplicationsWillAppear,
        icon: Icons.edit_document,
        builder: (_) => const RequestsListScreen(),
      )),
    );
  }
}
