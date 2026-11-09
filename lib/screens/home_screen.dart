import '../widgets/unio_navigation_bar.dart';
import '../widgets/unio_ai_brand.dart';
import '../services/locale_service.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import '../services/home_widget_service.dart';
import '../services/web_push_service.dart';
import '../services/analytics_service.dart';
import '../services/schedule_repository.dart';
import '../services/assistant_service.dart';
import '../services/app_update_service.dart';
import 'assistant_screen.dart';

import '../services/push_service.dart';
import '../services/local_notifications_service.dart';
import '../services/background_notifications_service.dart';
import '../services/request_status_service.dart';
import '../services/secure_storage_service.dart';
import '../services/portal_grades_repository.dart';
import 'requests_list_screen.dart';
import '../widgets/tap_feedback.dart';
import 'gradebook_tab.dart';
import 'schedule_tab.dart';
import 'settings_tab.dart';
import 'university_tab.dart';

class HomeScreen extends StatefulWidget {
  final String group;
  final String? accountGroup;
  final Future<void> Function(String)? onChangeGroup;
  final bool isPortalMode;
  final VoidCallback onLogout;
  final Future<void> Function(String login, String password) onUpgradeToPortal;
  final Future<void> Function()? onDelete;
  final bool darkMode;
  final ValueChanged<bool> onDarkModeChanged;

  const HomeScreen({
    super.key,
    this.onDelete,
    this.accountGroup,
    this.onChangeGroup,
    required this.group,
    required this.isPortalMode,
    required this.onLogout,
    required this.onUpgradeToPortal,
    required this.darkMode,
    required this.onDarkModeChanged,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int _index = 0;
  final _grades = PortalGradesRepository();
  final _scheduleKey = GlobalKey<ScheduleTabState>();
  final _settingsChanges = ValueNotifier(0);
  late final ScheduleRepository _schedule;
  late AssistantConversation _assistant;
  bool _assistantVisited = false;
  bool _gradesVisited = false;

  @override
  void initState() {
    super.initState();
    _schedule = ScheduleRepository(group: widget.group);
    _assistant = AssistantConversation(grades: () => _grades.load());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(checkForAppUpdate(context));
    });
    analytics.screen(AnalyticsScreen.schedule, role: AnalyticsRole.student);
    homeWidget.openSchedule.addListener(_openWidgetSchedule);
    webPushNavigation.addListener(_openWebPush);
    unawaited(homeWidget.select(value: widget.group).catchError((Object _) {}));
    WidgetsBinding.instance.addObserver(this);
    notificationTapCount.addListener(_openSchedule);
    requestNotificationTap.addListener(_openRequests);
    refreshPushIfEnabled(widget.group);
    refreshRequestNotifications();
    WidgetsBinding.instance.addPostFrameCallback((_) => _openRequests());
    WidgetsBinding.instance.addPostFrameCallback((_) => _openWebPush());
  }

  void _openSchedule() {
    Navigator.of(context).popUntil((route) => route.isFirst);
    analytics.track(AnalyticsEvent.notificationOpened,
        screen: AnalyticsScreen.schedule);
    if (_index != 0)
      analytics.screen(AnalyticsScreen.schedule, role: AnalyticsRole.student);
    setState(() => _index = 0);
  }

  void _openWidgetSchedule() {
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
    if (_index != 0)
      analytics.screen(AnalyticsScreen.schedule, role: AnalyticsRole.student);
    setState(() => _index = 0);
  }

  void _openAssistantGrades() {
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
    _select(1);
  }

  void _openAssistantRequests() {
    if (!mounted) return;
    setState(() {
      _index = 0;
      _assistantVisited = false;
    });
    // Leave the chat before the portal upgrade can replace its account scope.
    // Returning from requests must not reveal a disposed guest conversation.
    Navigator.of(context).popUntil((route) => route.isFirst);
    Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => RequestsEntryScreen(
            isPortalMode: widget.isPortalMode,
            onUpgrade: widget.onUpgradeToPortal)));
  }

  void _openWebPush() {
    final screen = webPushNavigation.value;
    if (!mounted || screen == null) return;
    webPushNavigation.value = null;
    if (screen == 'requests' && widget.isPortalMode) {
      Navigator.of(context).popUntil((route) => route.isFirst);
      Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => const RequestsListScreen()));
    } else if (screen == 'schedule') {
      Navigator.of(context).popUntil((route) => route.isFirst);
      _openWidgetSchedule();
    }
  }

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Settings lives on a sibling Navigator route. Notify after this
    // build, when those routes may safely rebuild with the new account/theme.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _settingsChanges.value++;
    });
    if (oldWidget.group != widget.group) {
      _schedule.select(group: widget.group);
      _assistant.clear();
      unawaited(
          homeWidget.select(value: widget.group).catchError((Object _) {}));
    }
    if (!oldWidget.isPortalMode && widget.isPortalMode) {
      _grades.clear();
      final previous = _assistant;
      previous.cancel();
      _assistant = AssistantConversation(grades: () => _grades.load());
      _assistantVisited = _index == 3;
      WidgetsBinding.instance.addPostFrameCallback((_) => previous.dispose());
      refreshRequestNotifications();
    }
  }

  Future<void> _openRequests() async {
    final payload = requestNotificationTap.value;
    if (payload == null || !widget.isPortalMode) return;
    requestNotificationTap.value = null;
    final session = await loadSession();
    if (!mounted ||
        session?.portalLogin == null ||
        payload.split(':').elementAtOrNull(1) !=
            portalOwner(session!.portalLogin!)) return;
    analytics.track(AnalyticsEvent.notificationOpened,
        screen: AnalyticsScreen.requests);
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const RequestsListScreen()));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(checkForAppUpdate(context));
      refreshPushIfEnabled(widget.group);
      refreshRequestNotifications();
    }
  }

  @override
  void dispose() {
    _grades.clear();
    _schedule.dispose();
    _assistant.dispose();
    _settingsChanges.dispose();
    WidgetsBinding.instance.removeObserver(this);
    homeWidget.openSchedule.removeListener(_openWidgetSchedule);
    webPushNavigation.removeListener(_openWebPush);
    notificationTapCount.removeListener(_openSchedule);
    requestNotificationTap.removeListener(_openRequests);
    super.dispose();
  }

  void _openSettings({bool notifications = false}) {
    analytics.screen(AnalyticsScreen.settings, role: AnalyticsRole.student);
    Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => ListenableBuilder(
            listenable: _settingsChanges,
            builder: (context, _) => Scaffold(
                  appBar: AppBar(
                      toolbarHeight: 48,
                      title: notifications
                          ? Text(l10n.uiPushNotifications)
                          : null),
                  body: SafeArea(
                      child: Center(
                          child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 640),
                              child: SettingsTab(
                                showHeader: true,
                                notificationsOnly: notifications,
                                onDelete: widget.onDelete,
                                group: widget.group,
                                accountGroup: widget.accountGroup,
                                onChangeGroup: widget.onChangeGroup,
                                isPortalMode: widget.isPortalMode,
                                onLogout: widget.onLogout,
                                onUpgradeToPortal: widget.onUpgradeToPortal,
                                darkMode: widget.darkMode,
                                onDarkModeChanged: widget.onDarkModeChanged,
                              )))),
                ))));
  }

  void _select(int index) {
    if (index == _index) return;
    FocusScope.of(context).unfocus();
    if (index < 3)
      analytics.screen(
          const [
            AnalyticsScreen.schedule,
            AnalyticsScreen.gradebook,
            AnalyticsScreen.university
          ][index],
          role: AnalyticsRole.student);
    tapFeedback();
    setState(() {
      _index = index;
      if (index == 1) _gradesVisited = true;
      if (index == 3) _assistantVisited = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    Localizations.localeOf(context);
    return PopScope(
      canPop: _index == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _index != 0) _select(0);
      },
      child: Scaffold(
        body: SafeArea(
          child: IndexedStack(index: _index, children: [
            ScheduleTab(
                key: _scheduleKey,
                group: widget.group,
                repository: _schedule,
                onOpenSettings: _openSettings,
                onOpenNotifications: () => _openSettings(notifications: true),
                gradesRepository: _grades,
                onOpenGrades: _openAssistantGrades,
                onOpenRequests: _openAssistantRequests),
            if (_gradesVisited)
              GradebookTab(
                  repository: _grades,
                  isPortalMode: widget.isPortalMode,
                  onUpgradeToPortal: widget.onUpgradeToPortal)
            else
              const SizedBox.shrink(),
            UniversityTab(
                isPortalMode: widget.isPortalMode,
                onUpgradeToPortal: widget.onUpgradeToPortal),
            if (_assistantVisited)
              TickerMode(
                  enabled: _index == 3,
                  child: AssistantScreen(
                      key: ValueKey(widget.isPortalMode),
                      conversation: _assistant,
                      group: widget.group,
                      embedded: true,
                      onOpenGrades: _openAssistantGrades,
                      onOpenRequests: _openAssistantRequests,
                      onLessonTap: (lesson) =>
                          _scheduleKey.currentState?.openStudentNotes(lesson)))
            else
              const SizedBox.shrink(),
          ]),
        ),
        bottomNavigationBar: MediaQuery.viewInsetsOf(context).bottom > 0
            ? null
            : UnioNavigationBar(
                selectedIndex: _index,
                onDestinationSelected: _select,
                destinations: [
                  NavigationDestination(
                      icon: const Icon(Icons.calendar_month_outlined),
                      selectedIcon: const Icon(Icons.calendar_month_rounded),
                      label: l10n.uiSchedule),
                  NavigationDestination(
                      icon: const Icon(Icons.school_outlined),
                      selectedIcon: const Icon(Icons.school_rounded),
                      label: l10n.uiAcademicProgress),
                  NavigationDestination(
                      icon: const Icon(Icons.account_balance_outlined),
                      selectedIcon: const Icon(Icons.account_balance_rounded),
                      label: l10n.uiUniversity),
                  NavigationDestination(
                      icon: const UnioAiMark(size: 25, muted: true),
                      selectedIcon: const UnioAiMark(size: 25),
                      label: l10n.aiTitle),
                ],
              ),
      ),
    );
  }
}
