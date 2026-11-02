import '../services/locale_service.dart';
import 'package:flutter/material.dart';

import '../config/brand.dart';
import '../config/university_config.dart';
import '../screens/portal_upgrade_screen.dart';
import 'tap_feedback.dart';
import 'feature_header.dart';
import 'unio_card.dart';

/// Оборачивает функционал, которому нужен полный вход через портал
/// (зачётка, заявления). Гостю показывает объяснение и кнопку входа
/// вместо содержимого; авторизованным через портал — сам контент.
class PortalGate extends StatelessWidget {
  final bool isPortalMode;
  final Future<void> Function(String login, String password) onUpgrade;
  final String featureName;
  final IconData icon;
  final WidgetBuilder builder;
  final VoidCallback? onAuthenticated;
  final bool modern;
  final String? description;
  final String? signInDescription;

  const PortalGate({
    super.key,
    required this.isPortalMode,
    required this.onUpgrade,
    required this.featureName,
    required this.icon,
    required this.builder,
    this.onAuthenticated,
    this.modern = false,
    this.description,
    this.signInDescription,
  });

  Future<void> _signIn(BuildContext context) async {
    tapFeedback();
    final authenticated = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
          builder: (_) => PortalUpgradeScreen(onSubmit: onUpgrade)),
    );
    if (context.mounted && authenticated == true) onAuthenticated?.call();
  }

  @override
  Widget build(BuildContext context) {
    Localizations.localeOf(context);
    if (isPortalMode) {
      return Builder(builder: builder);
    }

    final theme = Theme.of(context);

    if (modern)
      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          FeatureHeader(
              eyebrow: l10n.uiUniversityServices,
              title: featureName,
              description: description ??
                  l10n.uiViaThePortalRightInUnio((featureName).toString(),
                      (currentUniversity.shortName).toString()),
              icon: icon),
          const SizedBox(height: 20),
          UnioCard(
              padding: const EdgeInsets.all(24),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.lock_outline_rounded,
                        color: theme.colorScheme.primary),
                    const SizedBox(height: 14),
                    Text(l10n.uiPortalSignInRequired,
                        style: theme.textTheme.titleLarge),
                    const SizedBox(height: 10),
                    Text(
                        signInDescription ??
                            l10n.uiUseYourUniversityAccountToOpenThisSection,
                        style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant)),
                    const SizedBox(height: 22),
                    PrimaryButton(
                        label: l10n.uiSignInViaThePortal198(
                            (currentUniversity.shortName).toString()),
                        onPressed: () => _signIn(context)),
                  ])),
        ]),
      );

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: brandBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(UnioRadius.container),
              ),
              child: Icon(icon, color: brandBlue, size: 36),
            ),
            const SizedBox(height: 20),
            Text(
              featureName,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.uiAvailableAfterSigningInViaThePortalGuest(
                  (currentUniversity.shortName).toString()),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: PrimaryButton(
                label: l10n.uiSignInViaThePortal198(
                    (currentUniversity.shortName).toString()),
                gradient: true,
                onPressed: () => _signIn(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
