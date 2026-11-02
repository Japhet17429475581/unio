import '../services/locale_service.dart';
import '../services/analytics_service.dart';
import '../utils/user_messages.dart';
import 'package:flutter/material.dart';

import '../models/teacher_directory.dart';
import '../services/teachers_service.dart';
import '../widgets/message.dart';
import '../widgets/feature_header.dart';
import 'teacher_lookup_screen.dart';

class TeacherSearchScreen extends StatefulWidget {
  const TeacherSearchScreen({super.key});
  @override
  State<TeacherSearchScreen> createState() => _TeacherSearchScreenState();
}

class _TeacherSearchScreenState extends State<TeacherSearchScreen> {
  final _query = TextEditingController();
  TeacherDirectory? _directory;
  List<TeacherEntry> _recent = [];
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    analytics.screen(AnalyticsScreen.teacherSearch);
    _load();
    loadRecentTeachers().then((recent) {
      if (mounted) setState(() => _recent = _resolveRecent(recent));
    });
  }

  Future<void> _load() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final directory = await fetchTeacherDirectory();
      if (mounted)
        setState(() {
          _directory = directory;
          _recent = _resolveRecent(_recent);
        });
    } catch (error) {
      if (mounted) setState(() => _error = userMessage(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<TeacherEntry> _resolveRecent(List<TeacherEntry> entries) =>
      mergeTeacherEntries(
          entries.map((entry) => _directory?.resolve(entry) ?? entry));

  Future<void> _open(TeacherEntry entry) async {
    analytics.track(AnalyticsEvent.teacherSelected);
    final current = _directory?.resolve(entry) ?? entry;
    FocusScope.of(context).unfocus();
    final recent = [
      current,
      ..._recent.where((t) =>
          normalizeTeacherSearch(t.fio) != normalizeTeacherSearch(current.fio))
    ].take(6).toList();
    setState(() => _recent = recent);
    await saveRecentTeachers(recent);
    if (!mounted) return;
    await Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => TeacherLookupScreen(teacher: current)));
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Widget _person(TeacherEntry entry) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: FeatureLink(
          title: entry.fio,
          subtitle: l10n.uiViewClassesAndRooms,
          icon: Icons.person_outline_rounded,
          onTap: () => _open(entry)));

  @override
  Widget build(BuildContext context) {
    Localizations.localeOf(context);
    final theme = Theme.of(context);
    final query = normalizeTeacherSearch(_query.text);
    final matches = _directory?.search(query) ?? [];
    return Scaffold(
        appBar: AppBar(title: Text(l10n.uiFindATeacher), actions: [
          IconButton(
              tooltip: l10n.uiRefreshDirectory,
              onPressed: _loading ? null : _load,
              icon: const Icon(Icons.refresh_rounded)),
        ]),
        body: SafeArea(
            child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          children: [
            TextField(
                controller: _query,
                onChanged: (_) => setState(() {}),
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                    hintText: l10n.uiSurnameOrPartOfAName,
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _query.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: l10n.uiClearSearch,
                            onPressed: () => setState(() => _query.clear()),
                            icon: const Icon(Icons.close_rounded)))),
            if (_loading)
              const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: LinearProgressIndicator()),
            if (_directory?.isSaved == true)
              Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(l10n.uiSearchingTheSavedDirectory,
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant))),
            const SizedBox(height: 20),
            if (_error != null)
              Message(
                  icon: Icons.cloud_off_rounded,
                  title: l10n.uiDirectoryCurrentlyUnavailable,
                  text: _error!,
                  actionLabel: l10n.uiTryAgain,
                  onAction: _load),
            if (query.length < 2) ...[
              if (_recent.isNotEmpty) ...[
                Row(children: [
                  Expanded(
                      child: Text(l10n.uiRecentlyViewed,
                          style: theme.textTheme.titleMedium)),
                  TextButton(
                      onPressed: () async {
                        setState(() => _recent = []);
                        await saveRecentTeachers([]);
                      },
                      child: Text(l10n.uiClear))
                ]),
                for (final entry in _recent) _person(entry),
              ] else if (!_loading && _error == null)
                Message(
                    icon: Icons.person_search_rounded,
                    title: l10n.uiWhoAreYouLookingFor,
                    text: l10n.uiEnterAtLeastTwoLettersOfASurname),
            ] else if (_directory != null) ...[
              if (matches.isEmpty)
                Message(
                    icon: Icons.search_off_rounded,
                    title: l10n.uiNoMatches,
                    text: l10n.uiCheckTheSurnameOrTryFewerLetters)
              else ...[
                Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(l10n.uiChooseATeacher,
                        style: theme.textTheme.titleMedium)),
                for (final entry in matches.take(30)) _person(entry),
                if (matches.length > 30)
                  Text(l10n.uiMoreMatchesAvailableRefineTheSurname,
                      style: theme.textTheme.bodySmall),
              ],
            ],
          ],
        )));
  }
}
