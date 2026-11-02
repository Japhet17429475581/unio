import '../services/locale_service.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import '../services/home_widget_service.dart';
import '../services/analytics_service.dart';
import '../widgets/unio_navigation_bar.dart';

import '../widgets/tap_feedback.dart';
import 'settings_tab.dart';
import 'teacher_schedule_tab.dart';
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

class _TeacherHomeScreenState extends State<TeacherHomeScreen> {
  int _index = 0;
  bool _loggingOut = false;

  @override
  void initState() {
    super.initState();
    homeWidget.openSchedule.addListener(_openSchedule);
    unawaited(homeWidget
        .select(value: widget.fio, teacher: true)
        .catchError((Object _) {}));
    analytics.screen(AnalyticsScreen.schedule, role: AnalyticsRole.teacher);
  }

  Future<void> _logout() async {
    if (_loggingOut) return;
    setState(() => _loggingOut = true);
    try {
      await widget.onLogout();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.uiCouldNotSignOutPleaseTryAgain)),
      );
    } finally {
      if (mounted) setState(() => _loggingOut = false);
    }
  }

  void _openSchedule() {
    if (mounted) setState(() => _index = 0);
  }

  @override
  void dispose() {
    homeWidget.openSchedule.removeListener(_openSchedule);
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
            TeacherScheduleTab(fio: widget.fio),
            const UniversityTab.teacher(),
            SettingsTab.teacher(
              onDelete: widget.onDelete,
              fio: widget.fio,
              darkMode: widget.darkMode,
              onDarkModeChanged: widget.onDarkModeChanged,
              onLogout: _loggingOut ? null : _logout,
              loggingOut: _loggingOut,
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
                AnalyticsScreen.university,
                AnalyticsScreen.settings
              ][index],
              role: AnalyticsRole.teacher);
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
