import '../widgets/group_selection_dialog.dart';
import '../services/locale_service.dart';
import '../widgets/home_widget_sheet.dart';
import '../services/home_widget_service.dart';
import '../services/web_push_service.dart';
import '../services/app_version.dart';
import '../services/app_update_service.dart';
import 'dart:async';
import 'legal_documents_screen.dart';
import '../services/analytics_service.dart';
import '../utils/user_messages.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../widgets/pwa_help.dart';

import '../config/university_config.dart';
import '../services/push_service.dart';
import '../services/secure_storage_service.dart';
import '../widgets/tap_feedback.dart';
import '../widgets/unio_card.dart';
import '../widgets/feature_header.dart';
import '../widgets/signature_surface.dart';
import 'portal_upgrade_screen.dart';

/// Аккаунт, общие параметры и конфиденциальность в существующем стиле UNIO.
class SettingsTab extends StatefulWidget {
  final Future<void> Function()? onDelete;
  final String group;
  final String? accountGroup;
  final Future<void> Function(String)? onChangeGroup;
  final bool isPortalMode;
  final VoidCallback? onLogout;
  final Future<void> Function(String login, String password)? onUpgradeToPortal;
  final bool darkMode;
  final ValueChanged<bool> onDarkModeChanged;
  final String? teacherFio;
  final bool loggingOut;

  const SettingsTab({
    super.key,
    this.onDelete,
    required this.group,
    this.accountGroup,
    this.onChangeGroup,
    required this.isPortalMode,
    required this.onLogout,
    required this.onUpgradeToPortal,
    required this.darkMode,
    required this.onDarkModeChanged,
  })  : teacherFio = null,
        loggingOut = false;

  const SettingsTab.teacher({
    super.key,
    this.onDelete,
    required String fio,
    required this.onLogout,
    required this.darkMode,
    required this.onDarkModeChanged,
    this.loggingOut = false,
  })  : teacherFio = fio,
        group = '',
        accountGroup = null,
        onChangeGroup = null,
        isPortalMode = false,
        onUpgradeToPortal = null;

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> with WidgetsBindingObserver {
  bool _pushEnabled = false;
  bool _pushBusy = false;
  bool _loadingPrefs = true;
  bool _webPushAvailable = false;
  String? _portalLogin;
  bool _confirmingLogout = false;
  bool _checkingUpdate = false;
  late final Future<String> _version = loadAppVersion();
  bool get _guest => widget.teacherFio == null && !widget.isPortalMode;
  String get _logoutLabel => _guest ? l10n.uiEndGuestSession : l10n.uiSignOut;

  Future<void> _confirmLogout() async {
    if (_confirmingLogout || widget.loggingOut || widget.onLogout == null)
      return;
    _confirmingLogout = true;
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('$_logoutLabel?'),
          content: Text(_guest
              ? l10n.uiYouWillNeedToChooseAGroupAgain
              : l10n.uiYouWillNeedToSignInAgainTo),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(l10n.uiCancel)),
            FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(_guest ? l10n.uiEndSession : l10n.uiSignOut187)),
          ],
        ),
      );
      if (confirmed == true && mounted) widget.onLogout?.call();
    } finally {
      _confirmingLogout = false;
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(checkForAppUpdate(context));
    });
    if (widget.teacherFio == null) {
      _loadPushState();
      _loadPortalLogin();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      unawaited(checkForAppUpdate(context));
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _loadPushState() async {
    final enabled = await loadPushEnabled();
    final webAvailable = kIsWeb ? await prepareWebPush() : false;
    if (!mounted) return;
    setState(() {
      _pushEnabled = enabled;
      _webPushAvailable = webAvailable;
      _loadingPrefs = false;
    });
  }

  @override
  void didUpdateWidget(covariant SettingsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isPortalMode != widget.isPortalMode) _loadPortalLogin();
  }

  Future<void> _loadPortalLogin() async {
    final session = await loadSession();
    if (!mounted) return;
    setState(() => _portalLogin = session?.portalLogin);
  }

  Future<void> _togglePush(bool value) async {
    setState(() => _pushBusy = true);

    try {
      if (value) {
        await enablePush(group: widget.group);
      } else {
        await disablePush();
      }
      analytics.track(AnalyticsEvent.settingChanged,
          setting: AnalyticsSetting.push,
          action: value ? AnalyticsAction.enabled : AnalyticsAction.disabled);
      if (!mounted) return;
      setState(() {
        _pushEnabled = value;
        _pushBusy = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _pushBusy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(userMessage(e))),
      );
    }
  }

  Future<void> _openPortalUpgrade() async {
    tapFeedback();
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            PortalUpgradeScreen(onSubmit: widget.onUpgradeToPortal!),
      ),
    );
    _loadPortalLogin();
  }

  Future<void> _chooseLanguage() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => QuietTap(
          child: SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
            child: Text(l10n.language,
                style: Theme.of(context).textTheme.titleLarge),
          ),
          for (final entry in const {'ru': 'Русский', 'en': 'English'}.entries)
            ListTile(
              title: Text(entry.value),
              trailing: appLocale.locale.languageCode == entry.key
                  ? Icon(Icons.check_rounded,
                      color: Theme.of(context).colorScheme.primary)
                  : null,
              selected: appLocale.locale.languageCode == entry.key,
              onTap: () => Navigator.pop(context, entry.key),
            ),
          const SizedBox(height: 12),
        ]),
      )),
    );
    if (selected == null || !mounted) return;
    try {
      await appLocale.select(selected);
      if (mounted) setState(() {});
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.languageSaveFailed)),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    Localizations.localeOf(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final teacher = widget.teacherFio != null;
    return SignatureBackdrop(
        child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
          Text(l10n.uiSettings, style: theme.textTheme.headlineSmall),
          const SizedBox(height: 6),
          Text(l10n.uiAccountAndAppPreferences,
              style: theme.textTheme.bodyLarge
                  ?.copyWith(color: colors.onSurfaceVariant)),
          const SizedBox(height: 24),
          FeatureReveal(
              child: SignatureSurface(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                            child: Container(
                                padding: const EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: .10),
                                    border: Border.all(
                                        color: const Color(0xFFBFAAFF)
                                            .withValues(alpha: .35)),
                                    borderRadius: BorderRadius.circular(24)),
                                child: Icon(
                                    teacher
                                        ? Icons.school_outlined
                                        : Icons.person_outline_rounded,
                                    size: 34,
                                    color: const Color(0xFFD5C9FF)))),
                        const SizedBox(height: 16),
                        Text(
                            teacher
                                ? l10n.uiTeacher
                                : widget.isPortalMode
                                    ? (widget.accountGroup == null
                                        ? l10n.uiPersonalAccount
                                        : l10n.uiGroup(
                                            (widget.accountGroup).toString()))
                                    : l10n.uiGroup((widget.group).toString()),
                            textAlign: TextAlign.center,
                            style: theme.textTheme.headlineSmall
                                ?.copyWith(color: Colors.white)),
                        const SizedBox(height: 12),
                        Text(
                            widget.teacherFio ??
                                (widget.isPortalMode
                                    ? (_portalLogin ??
                                        l10n.uiPortal(
                                            (currentUniversity.shortName)
                                                .toString()))
                                    : l10n.uiGuestAccess),
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleMedium
                                ?.copyWith(color: Colors.white)),
                        if (!teacher &&
                            widget.isPortalMode &&
                            widget.accountGroup != widget.group) ...[
                          const SizedBox(height: 8),
                          Text(
                              l10n.uiScheduleForGroup(
                                  (widget.group).toString()),
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(color: const Color(0xFFD1D6ED))),
                        ],
                        if (!teacher && widget.onChangeGroup != null)
                          TextButton(
                              style: TextButton.styleFrom(
                                  foregroundColor: const Color(0xFFEAE2FF)),
                              onPressed: () => showDialog<void>(
                                  context: context,
                                  builder: (_) => GroupSelectionDialog(
                                      group: widget.group,
                                      onSave: widget.onChangeGroup!)),
                              child: Text(l10n.uiChangeGroup)),
                        if (!teacher && (!widget.isPortalMode || kIsWeb)) ...[
                          const SizedBox(height: 12),
                          PrimaryButton(
                              backgroundColor: const Color(0xFFEAE2FF),
                              foregroundColor: const Color(0xFF251D3D),
                              label: widget.isPortalMode
                                  ? l10n.uiSignInToThePortalAgain
                                  : l10n.uiSignInViaThePortal198(
                                      (currentUniversity.shortName).toString()),
                              onPressed: _openPortalUpgrade),
                        ],
                      ]))),
          const SizedBox(height: 24),
          Text(l10n.uiPreferences, style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          UnioCard(
              child: Column(children: [
            QuietTap(
                child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading:
                  Icon(Icons.language_rounded, color: colors.onSurfaceVariant),
              title: Text(l10n.language),
              subtitle: Text(appLocale.locale.languageCode == 'en'
                  ? 'English'
                  : 'Русский'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: _chooseLanguage,
            )),
            if (supportsAppUpdates) ...[
              const Divider(height: 24, thickness: .5),
              QuietTap(
                  child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.system_update_rounded,
                    color: colors.onSurfaceVariant),
                title: Text(appLocale.locale.languageCode == 'en'
                    ? 'Check for updates'
                    : 'Проверить обновления'),
                trailing: _checkingUpdate
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.chevron_right_rounded),
                onTap: _checkingUpdate
                    ? null
                    : () async {
                        setState(() => _checkingUpdate = true);
                        try {
                          await checkForAppUpdate(context, manual: true);
                        } finally {
                          if (mounted) setState(() => _checkingUpdate = false);
                        }
                      },
              )),
            ],
            const Divider(height: 24, thickness: .5),
            _SettingSwitch(
                value: widget.darkMode,
                onChanged: (value) {
                  tapFeedback();
                  widget.onDarkModeChanged(value);
                },
                icon: Icon(
                    widget.darkMode
                        ? Icons.dark_mode_outlined
                        : Icons.light_mode_outlined,
                    color: colors.onSurfaceVariant),
                title: Text(l10n.uiDarkTheme)),
            if (!teacher) ...[
              const Divider(height: 24, thickness: .5),
              _SettingSwitch(
                  value: _pushEnabled,
                  onChanged: _loadingPrefs ||
                          _pushBusy ||
                          (kIsWeb && !_webPushAvailable)
                      ? null
                      : (value) {
                          tapFeedback();
                          _togglePush(value);
                        },
                  icon: Icon(Icons.notifications_none_rounded,
                      color: colors.onSurfaceVariant),
                  title: Text(l10n.uiPushNotifications)),
              if (_pushBusy) const LinearProgressIndicator(minHeight: 2),
              if (kIsWeb && !_loadingPrefs && !_webPushAvailable)
                Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Text(
                        l10n.uiNotificationsAreCurrentlyUnavailableOnIphoneAddUnio,
                        style: TextStyle(fontSize: 12))),
            ],
          ])),
          if (homeWidget.supported) ...[
            const SizedBox(height: 12),
            UnioCard(
                child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.widgets_outlined),
              title: Text(l10n.uiScheduleWidget),
              subtitle: Text(l10n.uiYourNextClassOnTheHomeScreen),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => showHomeWidgetSheet(context,
                  label: widget.teacherFio ?? widget.group),
            )),
          ],
          const SizedBox(height: 24),
          Text(l10n.uiPrivacy, style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          UnioCard(
              child: QuietTap(
                  child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.privacy_tip_outlined),
                      title: Text(l10n.uiDocumentsAndData),
                      subtitle: Text(l10n.uiConsentAnalyticsAndDeletion),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => LegalDocumentsScreen(
                              onDelete: widget.onDelete)))))),
          if (kIsWeb) ...[
            const SizedBox(height: 24),
            UnioCard(
                child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.add_to_home_screen_rounded),
                    title: Text(l10n.uiInstallUnio),
                    subtitle: Text(l10n.uiAddToHomeScreenWebBeta),
                    onTap: () => showPwaHelp(context))),
            const SizedBox(height: 12),
            Text(l10n.uiNotesAreStoredInThisBrowserClearingSite),
          ],
          const SizedBox(height: 24),
          SecondaryButton(
              color: colors.error,
              label: widget.loggingOut ? l10n.uiSigningOut : _logoutLabel,
              icon: Icons.logout_rounded,
              onPressed: widget.onLogout == null || widget.loggingOut
                  ? null
                  : _confirmLogout,
              padding: const EdgeInsets.symmetric(vertical: 16)),
          const SizedBox(height: 24),
          FutureBuilder<String>(
              future: _version,
              builder: (context, snapshot) => Text(
                  snapshot.hasData
                      ? l10n.uiUnioVersion((snapshot.data).toString())
                      : 'UNIO',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: colors.onSurfaceVariant))),
        ]));
  }
}

/// Only the switch is interactive; labels and the surrounding card are not.
class _SettingSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final Widget title;
  final Widget? icon;
  const _SettingSwitch(
      {required this.value,
      required this.onChanged,
      required this.title,
      this.icon});

  @override
  Widget build(BuildContext context) {
    Localizations.localeOf(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        if (icon != null) ...[icon!, const SizedBox(width: 12)],
        Expanded(child: title),
        const SizedBox(width: 8),
        Semantics(
            label: title is Text ? (title as Text).data : null,
            child: Switch.adaptive(value: value, onChanged: onChanged))
      ])
    ]);
  }
}
