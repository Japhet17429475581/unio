import '../widgets/unio_navigation_bar.dart';
import '../services/locale_service.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import '../services/home_widget_service.dart';
import '../services/analytics_service.dart';
import '../services/schedule_repository.dart';
import '../services/app_update_service.dart';
import 'teacher_lesson_screen.dart';

import '../widgets/tap_feedback.dart';
import 'settings_tab.dart';
import 'schedule_tab.dart';
import 'university_tab.dart';

class TeacherHomeScreen extends StatefulWidget {
  final String fio;
  final Future<void> Function()? onDelete;
  final bool darkMode;
  final ValueChanged<bool> onDarkModeChanged;
  final Future<void> Function() onLogout;

  const TeacherHomeScreen({
    super.key,
    this.onDelete,
    required this.fio,
    required this.darkMode,
    required this.onDarkModeChanged,
    required this.onLogout,
  });

  @override
  State<TeacherHomeScreen> createState() => _TeacherHomeScreenState();
}

class _TeacherHomeScreenState extends State<TeacherHomeScreen>
    with WidgetsBindingObserver {
  int _index = 0;
  bool _loggingOut = false;
  final _scheduleKey = GlobalKey<ScheduleTabState>();
  final _settingsChanges = ValueNotifier(0);
  late final ScheduleRepository _schedule;

  @override
  void initState() {
    super.initState();
    _schedule = ScheduleRepository(group: '', teacherFio: widget.fio);
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(checkForAppUpdate(context));
    });
    analytics.screen(AnalyticsScreen.schedule, role: AnalyticsRole.teacher);
    homeWidget.openSchedule.addListener(_openSchedule);
    unawaited(homeWidget
        .select(value: widget.fio, teacher: true)
        .catchError((Object _) {}));
  }

  Future<void> _logout() async {
    if (_loggingOut) return;
    setState(() => _loggingOut = true);
    _settingsChanges.value++;
    try {
      await widget.onLogout();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.uiCouldNotSignOutPleaseTryAgain)),
      );
    } finally {
      if (mounted) {
        setState(() => _loggingOut = false);
        _settingsChanges.value++;
      }
    }
  }

  void _openSchedule() {
    if (mounted) setState(() => _index = 0);
  }

  @override
  void dispose() {
    homeWidget.openSchedule.removeListener(_openSchedule);
    WidgetsBinding.instance.removeObserver(this);
    _schedule.dispose();
    _settingsChanges.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed)
      unawaited(checkForAppUpdate(context));
  }

  @override
  void didUpdateWidget(covariant TeacherHomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _settingsChanges.value++;
    });
    if (oldWidget.fio != widget.fio) {
      _schedule.select(group: '', teacherFio: widget.fio);
      unawaited(homeWidget
          .select(value: widget.fio, teacher: true)
          .catchError((Object _) {}));
    }
  }

  void _openSettings() => Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ListenableBuilder(
          listenable: _settingsChanges,
          builder: (context, _) => Scaffold(
                appBar: AppBar(toolbarHeight: 48),
                body: SafeArea(
                    child: Center(
                        child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 640),
                            child: SettingsTab.teacher(
                                showHeader: true,
                                onDelete: widget.onDelete,
                                fio: widget.fio,
                                darkMode: widget.darkMode,
                                onDarkModeChanged: widget.onDarkModeChanged,
                                onLogout: _loggingOut ? null : _logout,
                                loggingOut: _loggingOut)))),
              ))));

  void _select(int index) {
    if (index == _index) return;
    analytics.screen(
        index == 0 ? AnalyticsScreen.schedule : AnalyticsScreen.university,
        role: AnalyticsRole.teacher);
    tapFeedback();
    setState(() => _index = index);
  }

  @override
  Widget build(BuildContext context) {
    Localizations.localeOf(context);
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(index: _index, children: [
          ScheduleTab.teacher(
              key: _scheduleKey,
              fio: widget.fio,
              repository: _schedule,
              onOpenSettings: _openSettings,
              onLessonTap: (lesson) => Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => TeacherLessonScreen(lesson: lesson)))),
          const UniversityTab.teacher(),
        ]),
      ),
      bottomNavigationBar: UnioNavigationBar(
          selectedIndex: _index,
          onDestinationSelected: _select,
          destinations: [
            NavigationDestination(
                icon: const Icon(Icons.calendar_month_outlined),
                selectedIcon: const Icon(Icons.calendar_month_rounded),
                label: l10n.uiSchedule),
            NavigationDestination(
                icon: const Icon(Icons.account_balance_outlined),
                selectedIcon: const Icon(Icons.account_balance_rounded),
                label: l10n.uiUniversity),
          ]),
    );
  }
}
