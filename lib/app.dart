import 'services/api_service.dart';
import 'services/locale_service.dart';
import 'l10n/app_localizations.dart';
import 'services/home_widget_service.dart';
import 'services/web_portal_service.dart';
import 'services/web_push_service.dart';
import 'services/groups_service.dart';
import 'services/push_service.dart';
import 'services/retention_service.dart';
import 'dart:async';
import 'screens/legal_documents_screen.dart';
import 'services/legal_service.dart';
import 'services/privacy_service.dart';
import 'services/privacy_jobs_service.dart';
import 'services/analytics_service.dart';
import 'package:flutter/material.dart';
import 'widgets/system_bars.dart';

import 'widgets/unio_loader.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'config/brand.dart';
import 'screens/home_screen.dart';
import 'screens/teacher_home_screen.dart';
import 'screens/welcome_screen.dart';
import 'services/auth_service.dart';
import 'services/teachers_service.dart';
import 'services/local_notifications_service.dart';
import 'services/secure_storage_service.dart';
import 'widgets/welcome_visuals.dart';

/// Глобальный ключ навигации — нужен, чтобы тап по локальному
/// уведомлению мог открыть корневой экран приложения.
final navigatorKey = GlobalKey<NavigatorState>();

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> with WidgetsBindingObserver {
  bool _needsLegal = false;
  bool _ending = false;
  int _sessionGeneration = 0;
  bool _loading = true;

  String? _accountToken;
  String? _groupCode;
  String? _accountGroup;
  String? _teacherFio;
  bool _isPortalMode = false;

  bool _darkMode = false;

  @override
  void initState() {
    super.initState();
    appLocale.addListener(_localeChanged);
    initializeWebPush();
    homeWidget.initialize(
        onOpenSchedule: () =>
            navigatorKey.currentState?.popUntil((route) => route.isFirst));
    WidgetsBinding.instance.addObserver(this);
    _bootstrap();
  }

  @override
  void dispose() {
    appLocale.removeListener(_localeChanged);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _localeChanged() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(_retryPrivacy());
  }

  Future<void> _retryPrivacy() async {
    try {
      await recoverPrivateCleanup();
      await pruneLocalData();
      final pending = await privacyJobs.hasPending();
      final complete = await privacyJobs.retry();
      if (pending && mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final context = navigatorKey.currentContext;
          if (context != null && mounted)
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(complete
                    ? l10n.uiTheServerHasConfirmedDeletionAndSignOut
                    : l10n.uiTheServerRequestIsStillWaitingForA)));
        });
      }
      final session = await loadSession();
      if (session != null && await legal.coreAccepted())
        await legal.sync(session.accountToken);
    } catch (_) {/* durable jobs remain pending */}
  }

  Future<void> _ensureLegal() async {
    await recoverPrivateCleanup();
    if (await legal.coreAccepted()) return;
    final accepted = await navigatorKey.currentState!.push<bool>(
        MaterialPageRoute(
            builder: (_) =>
                const LegalDocumentsScreen(requireAcceptance: true)));
    if (accepted != true)
      throw AuthApiException(l10n.uiPleaseAcceptTheDocumentsToSignInAnalytics);
  }

  Future<void> _bootstrap() async {
    try {
      await appLocale.load();
      await _loadPrivateState();
    } catch (_) {
      if (mounted)
        setState(() {
          _loading = false;
          _accountToken = null;
          _teacherFio = null;
        });
    }
  }

  Future<void> _loadPrivateState() async {
    try {
      await recoverPrivateCleanup();
    } catch (_) {/* loadSession fails closed */}
    final coreAccepted = await legal.coreAccepted();
    if (!coreAccepted) {
      try {
        await homeWidget.clear();
      } catch (_) {/* cleanup can be retried */}
    }
    try {
      await legal.restoreAnalytics();
    } catch (_) {/* native gate remains closed */}
    unawaited(_retryPrivacy());

    try {
      await initLocalNotifications(
        onNotificationTap: () {
          navigatorKey.currentState?.popUntil(
            (route) => route.isFirst,
          );
        },
      );
    } catch (e) {}

    final prefs = await SharedPreferences.getInstance();
    final darkMode = prefs.getBool('dark_mode') ?? false;
    final legacyTeacherFio = prefs.getString(teacherFioPreferenceKey);
    final teacherSession = await loadTeacherSession();
    final teacherFio = teacherSession?.fio;

    final session = await loadSession();

    // Existing accounts should not see first-run onboarding after signing out.
    if (session != null ||
        teacherSession != null ||
        (legacyTeacherFio != null && legacyTeacherFio.trim().isNotEmpty)) {
      try {
        await prefs.setBool(onboardingCompletedPreferenceKey, true);
      } catch (_) {
        // This optional preference must not interrupt session loading.
      }
    }

    String? accountToken =
        session?.accountToken ?? teacherSession?.webAccountToken;

    // ВАЖНО:
    // берём группу и режим сначала из локального Secure Storage.
    String? groupCode = session?.selectedScheduleGroup ?? session?.groupCode;
    bool isPortalMode = session?.isPortalMode ?? false;

    if (session != null && coreAccepted) {
      try {
        final me = await fetchMe(
          session.accountToken,
        ).timeout(
          const Duration(seconds: 10),
        );

        // Сервер может пока не возвращать эти поля.
        // Поэтому НЕ затираем локальные значения null/false.

        if (groupCode == null &&
            me.groupCode != null &&
            me.groupCode!.isNotEmpty) {
          groupCode = me.groupCode;
        }

        if (me.isPortal) {
          isPortalMode = true;
        }
      } catch (e) {
        // НЕ удаляем локальную сессию только потому,
        // что backend временно недоступен.
        //
        // Если Secure Storage содержит токен + группу,
        // пользователь должен остаться авторизованным.
      }
    }

    if (!mounted) return;

    setState(() {
      _needsLegal =
          !coreAccepted && (session != null || teacherSession != null);
      _darkMode = darkMode;
      _teacherFio = teacherFio != null && teacherFio.trim().isNotEmpty
          ? teacherFio
          : null;
      _accountToken = accountToken;
      _groupCode = groupCode;
      _accountGroup = session?.accountGroup;
      _isPortalMode = isPortalMode;
      _loading = false;
    });
  }

  Future<void> _setDarkMode(bool value) async {
    setState(() => _darkMode = value);
    final prefs = await SharedPreferences.getInstance();
    // Read the latest selection if switches were changed while prefs loaded.
    await prefs.setBool('dark_mode', _darkMode);
    analytics.track(AnalyticsEvent.settingChanged,
        setting: AnalyticsSetting.darkTheme,
        action: _darkMode ? AnalyticsAction.enabled : AnalyticsAction.disabled);
  }

  Future<void> _loginTeacher(String login, String password, String fio) async {
    await _ensureLegal();
    final session = await loginTeacherPortalAccount(
        login: login, password: password, fio: fio);
    if (!mounted) return;
    setState(() {
      _teacherFio = session.fio;
      _accountToken = session.webAccountToken;
    });
  }

  Future<void> _logoutTeacher() async {
    await _endSession();
  }

  /// Гостевой вход — только код группы.
  Future<void> _loginGuest(String groupCode) async {
    await _ensureLegal();
    final token = await registerGuest(
      groupCode: groupCode,
    );

    await saveSession(
      accountToken: token,
      groupCode: groupCode,
      isPortalMode: false,
    );

    if (!mounted) return;

    setState(() {
      _accountToken = token;
      _groupCode = groupCode;
      _accountGroup = null;
      _isPortalMode = false;
    });
  }

  /// Полный вход через портал ВГСПУ.
  Future<void> _loginPortal({
    required String login,
    required String password,
    required String groupCode,
  }) async {
    await _ensureLegal();
    final token = await loginPortalAccount(
      login: login,
      password: password,
      groupCode: groupCode,
    );

    await saveSession(
      accountToken: token,
      groupCode: groupCode,
      isPortalMode: true,
      portalLogin: login,
      portalPassword: password,
    );

    if (!mounted) return;

    setState(() {
      _accountToken = token;
      _groupCode = groupCode;
      _accountGroup = null;
      _isPortalMode = true;
    });
    webPortal.authChanges.value++;
  }

  Future<void> _changeGroup(String input) async {
    final group = resolveGroup(await fetchGroups(), input);
    if (group == _groupCode) return;
    // Validate the new timetable before committing the selection. No cache
    // fallback here: a failed request leaves the old group selected.
    await fetchLessons(group,
        date: DateTime.now(), week: true, allowCacheFallback: false);
    await saveSelectedScheduleGroup(group);
    if (!mounted) return;
    setState(() => _groupCode = group);
    // Notification failures must not undo an already persisted selection.
    unawaited(refreshPushIfEnabled(group).catchError((Object _) {}));
  }

  Future<void> _logout() => _endSession();

  Future<void> _endSession({bool deleteData = false}) async {
    if (_ending) return;
    _ending = true;
    var localFailed = false;
    final token = _accountToken;
    navigatorKey.currentState?.popUntil((route) => route.isFirst);
    setState(() => _loading = true);
    await WidgetsBinding.instance.endOfFrame;
    try {
      await endPrivateSession(token: token, deleteData: deleteData);
    } catch (_) {
      localFailed = true;
    }
    if (!mounted) return;
    setState(() {
      _accountToken = null;
      _groupCode = null;
      _accountGroup = null;
      _teacherFio = null;
      _isPortalMode = false;
      _needsLegal = false;
      _loading = false;
      _sessionGeneration++;
    });
    final completed = await privacyJobs.retry().catchError((Object _) => false);
    _ending = false;
    if (!mounted) return;
    final context = navigatorKey.currentContext;
    if (context != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(localFailed
              ? l10n.uiCleanupIsIncompleteWeWillRetryOnThe
              : !completed
                  ? l10n.uiYouAreSignedOutTheServerRequestIs
                  : deleteData
                      ? l10n.uiYourUnioAccountAndLocalDataHaveBeen
                      : l10n.uiYouHaveSignedOut)));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return MaterialApp(
        locale: appLocale.locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        navigatorKey: navigatorKey,
        title: 'Unio',
        builder: (context, child) => UnioSystemBars(child: child!),
        debugShowCheckedModeBanner: false,
        // Bootstrap is always painted dark, including the system bar. The
        // saved app theme is loaded later and must not colour this first frame.
        theme: buildWelcomeTheme()
            .copyWith(scaffoldBackgroundColor: welcomeBackground),
        themeAnimationDuration: Duration.zero,
        home: const Scaffold(
          backgroundColor: welcomeBackground,
          body: Center(
            child: UnioLoader(color: welcomeAccent),
          ),
        ),
      );
    }

    return MaterialApp(
      locale: appLocale.locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      navigatorKey: navigatorKey,
      title: 'Unio',
      builder: (context, child) => UnioSystemBars(child: child!),
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      themeAnimationDuration: const Duration(milliseconds: 450),
      themeAnimationCurve: Curves.easeInOutCubic,
      themeMode: _darkMode ? ThemeMode.dark : ThemeMode.light,
      home: _needsLegal
          ? LegalDocumentsScreen(
              requireAcceptance: true,
              onAccepted: _bootstrap,
              onDecline: _logout)
          : _teacherFio != null
              ? TeacherHomeScreen(
                  key: ValueKey(_sessionGeneration),
                  fio: _teacherFio!,
                  darkMode: _darkMode,
                  onDarkModeChanged: _setDarkMode,
                  onLogout: _logoutTeacher,
                  onDelete: () => _endSession(deleteData: true),
                )
              : _accountToken == null || _groupCode == null
                  ? WelcomeScreen(
                      onGuestLogin: _loginGuest,
                      onTeacherLogin: _loginTeacher,
                      onPortalLogin: (
                        login,
                        password,
                        groupCode,
                      ) =>
                          _loginPortal(
                        login: login,
                        password: password,
                        groupCode: groupCode,
                      ),
                    )
                  : HomeScreen(
                      key: ValueKey(
                        _sessionGeneration,
                      ),
                      group: _groupCode!,
                      accountGroup: _accountGroup,
                      onChangeGroup: _changeGroup,
                      isPortalMode: _isPortalMode,
                      onLogout: _logout,
                      onDelete: () => _endSession(deleteData: true),
                      onUpgradeToPortal: (
                        login,
                        password,
                      ) =>
                          _loginPortal(
                        login: login,
                        password: password,
                        groupCode: _groupCode!,
                      ),
                      darkMode: _darkMode,
                      onDarkModeChanged: _setDarkMode,
                    ),
    );
  }
}
