import '../services/locale_service.dart';
import '../utils/user_messages.dart';
import '../services/analytics_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '../config/university_config.dart';
import '../widgets/tap_feedback.dart';
import '../widgets/unio_card.dart';

/// Форма "войти через портал ВГСПУ" для гостя, который уже указал
/// группу — здесь запрашиваются только логин и пароль (группа уже
/// известна из аккаунта).
class PortalUpgradeScreen extends StatefulWidget {
  final Future<void> Function(String login, String password) onSubmit;

  const PortalUpgradeScreen({super.key, required this.onSubmit});

  @override
  State<PortalUpgradeScreen> createState() => _PortalUpgradeScreenState();
}

class _PortalUpgradeScreenState extends State<PortalUpgradeScreen> {
  final _loginController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  Future<void> _submit() async {
    if (_loading) return;
    final login = _loginController.text.trim();
    final password = _passwordController.text;

    if (login.isEmpty || password.isEmpty) {
      setState(() => _error = l10n.uiEnterYourPortalUsernameAndPassword(
          (currentUniversity.shortName).toString()));
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    analytics.track(AnalyticsEvent.loginAttempt,
        role: AnalyticsRole.student, method: AnalyticsMethod.portal);
    try {
      await widget.onSubmit(login, password);
      analytics.track(AnalyticsEvent.loginResult,
          role: AnalyticsRole.student,
          method: AnalyticsMethod.portal,
          outcome: AnalyticsOutcome.success);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      analytics.track(AnalyticsEvent.loginResult,
          role: AnalyticsRole.student,
          method: AnalyticsMethod.portal,
          outcome: AnalyticsOutcome.failed);
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = userMessage(e);
      });
    }
  }

  @override
  void dispose() {
    _loginController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Localizations.localeOf(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
          title: Text(l10n
              .uiSignInViaThePortal((currentUniversity.shortName).toString()))),
      body: SafeArea(
          child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Center(
            child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(l10n.uiUseYourUniversityPortalUsernameAndPassword,
                    style: theme.textTheme.bodyLarge
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant))),
            const SizedBox(height: 12),
            UnioCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: _loginController,
                        enabled: !_loading,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          hintText: l10n.uiPortalUsername,
                          prefixIcon: Icon(Icons.person_outline_rounded),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _passwordController,
                        enabled: !_loading,
                        obscureText: _obscure,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _submit(),
                        decoration: InputDecoration(
                          hintText: l10n.uiPortalPassword,
                          prefixIcon: const Icon(Icons.key_outlined),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscure
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                            onPressed: () {
                              tapFeedback();
                              setState(() => _obscure = !_obscure);
                            },
                          ),
                        ),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: theme.colorScheme.error),
                        ),
                      ],
                      const SizedBox(height: 16),
                      PrimaryButton(
                        label: l10n.uiSignIn,
                        onPressed: _submit,
                        loading: _loading,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        kIsWeb
                            ? l10n.uiYourPasswordIsNotSavedInTheBrowser
                            : l10n
                                .uiYourUsernameAndPasswordAreStoredEncryptedOn,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ])),
          ]),
        )),
      )),
    );
  }
}
