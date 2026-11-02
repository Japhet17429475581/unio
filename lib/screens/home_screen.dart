import '../services/locale_service.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import '../services/home_widget_service.dart';
import '../services/web_push_service.dart';
import '../services/analytics_service.dart';
import '../widgets/unio_navigation_bar.dart';

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

  @override
  void initState() {
    super.initState();
    homeWidget.openSchedule.addListener(_openWidgetSchedule);
    webPushNavigation.addListener(_openWebPush);
    unawaited(homeWidget.select(value: widget.group).catchError((Object _) {}));
    analytics.screen(AnalyticsScreen.schedule, role: AnalyticsRole.student);
    WidgetsBinding.instance.addObserver(this);
    notificationTapCount.addListener(_openSchedule);
    requestNotificationTap.addListener(_openRequests);
    refreshPushIfEnabled(widget.group);
    refreshRequestNotifications();
    WidgetsBinding.instance.addPostFrameCallback((_) => _openRequests());
    WidgetsBinding.instance.addPostFrameCallback((_) => _openWebPush());
  }

  void _openSchedule() {
    analytics.track(AnalyticsEvent.notificationOpened,
        screen: AnalyticsScreen.schedule);
    if (_index != 0)
      analytics.screen(AnalyticsScreen.schedule, role: AnalyticsRole.student);
    setState(() => _index = 0);
  }

  void _openWidgetSchedule() {
    if (!mounted) return;
    if (_index != 0)
      analytics.screen(AnalyticsScreen.schedule, role: AnalyticsRole.student);
    setState(() => _index = 0);
  }

  void _openAssistantGrades() {
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
    analytics.screen(AnalyticsScreen.gradebook, role: AnalyticsRole.student);
    setState(() => _index = 1);
  }

  void _openAssistantRequests() {
    if (!mounted) return;
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
    if (oldWidget.group != widget.group) {
      unawaited(
          homeWidget.select(value: widget.group).catchError((Object _) {}));
    }
    if (!oldWidget.isPortalMode && widget.isPortalMode) {
      _grades.clear();
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
      refreshPushIfEnabled(widget.group);
      refreshRequestNotifications();
    }
  }

  @override
  void dispose() {
    _grades.clear();
    WidgetsBinding.instance.removeObserver(this);
    homeWidget.openSchedule.removeListener(_openWidgetSchedule);
    webPushNavigation.removeListener(_openWebPush);
    notificationTapCount.removeListener(_openSchedule);
    requestNotificationTap.removeListener(_openRequests);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Localizations.localeOf(context);
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: _index,
          children: [
            ScheduleTab(
                key: ValueKey('student-schedule-${widget.isPortalMode}'),
                group: widget.group,
                gradesRepository: _grades,
                onOpenGrades: _openAssistantGrades,
                onOpenRequests: _openAssistantRequests),
            GradebookTab(
              repository: _grades,
              isPortalMode: widget.isPortalMode,
              onUpgradeToPortal: widget.onUpgradeToPortal,
            ),
            UniversityTab(
              isPortalMode: widget.isPortalMode,
              onUpgradeToPortal: widget.onUpgradeToPortal,
            ),
            SettingsTab(
              onDelete: widget.onDelete,
              group: widget.group,
              accountGroup: widget.accountGroup,
              onChangeGroup: widget.onChangeGroup,
              isPortalMode: widget.isPortalMode,
              onLogout: widget.onLogout,
              onUpgradeToPortal: widget.onUpgradeToPortal,
              darkMode: widget.darkMode,
              onDarkModeChanged: widget.onDarkModeChanged,
            ),
          ],
        ),
      ),
      bottomNavigationBar: UnioNavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (index) {
          if (index == _index) return;
          analytics.screen(
              const [
                AnalyticsScreen.schedule,
                AnalyticsScreen.gradebook,
                AnalyticsScreen.university,
                AnalyticsScreen.settings
              ][index],
              role: AnalyticsRole.student);
          tapFeedback();
          setState(() => _index = index);
        },
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month_rounded),
            label: l10n.uiSchedule,
          ),
          NavigationDestination(
            icon: Icon(Icons.school_outlined),
            selectedIcon: Icon(Icons.school_rounded),
            label: l10n.uiAcademicProgress,
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_outlined),
            selectedIcon: Icon(Icons.account_balance_rounded),
            label: l10n.uiUniversity,
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded),
            label: l10n.uiSettings,
          ),
        ],
      ),
    );
  }
}
