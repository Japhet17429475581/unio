import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../services/assistant_service.dart';
import '../services/locale_service.dart';

class AssistantHistoryDrawer extends StatefulWidget {
  final AssistantConversation chat;
  const AssistantHistoryDrawer({super.key, required this.chat});
  @override
  State<AssistantHistoryDrawer> createState() => _HistoryState();
}

class _HistoryState extends State<AssistantHistoryDrawer> {
  final _search = TextEditingController();
  List<ChatSession>? _found;
  Timer? _timer;
  int _searchVersion = 0;
  AssistantConversation get chat => widget.chat;
  @override
  void initState() {
    super.initState();
    chat.addListener(_changed);
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    chat.removeListener(_changed);
    _timer?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _find(String value) {
    final generation = ++_searchVersion;
    chat.history?.cancelSearch();
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 250), () async {
      try {
        final result = await chat.history?.search(value) ?? [];
        if (mounted && generation == _searchVersion)
          setState(() => _found = result);
      } catch (_) {
        if (mounted) _failure();
      }
    });
  }

  void _failure() => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(l10n.aiHistoryFailure)));
  Future<bool> _confirm(String title, String body) async =>
      await showDialog<bool>(
          context: context,
          builder: (c) =>
              AlertDialog(title: Text(title), content: Text(body), actions: [
                TextButton(
                    onPressed: () => Navigator.pop(c, false),
                    child: Text(l10n.aiCancelAction)),
                TextButton(
                    onPressed: () => Navigator.pop(c, true),
                    child: Text(l10n.aiDeleteAction)),
              ])) ??
      false;
  Future<void> _rename(ChatSession session) async {
    final input = TextEditingController(text: session.title);
    final title = await showDialog<String>(
        context: context,
        builder: (c) => AlertDialog(
                title: Text(l10n.aiRename),
                content: TextField(
                    controller: input,
                    autofocus: true,
                    maxLength: 100,
                    onSubmitted: (value) => Navigator.pop(c, value)),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(c),
                      child: Text(l10n.aiCancelAction)),
                  TextButton(
                      onPressed: () => Navigator.pop(c, input.text),
                      child: Text(l10n.aiSaveAction)),
                ]));
    // The dialog route may still be animating out; defer disposal.
    Future.delayed(const Duration(milliseconds: 400), input.dispose);
    if (title == null || !mounted) return;
    try {
      await chat.renameChat(session, title);
      _find(_search.text);
    } catch (_) {
      if (mounted) _failure();
    }
  }

  String _period(DateTime date) {
    final today = DateUtils.dateOnly(DateTime.now());
    final days = today.difference(DateUtils.dateOnly(date.toLocal())).inDays;
    return days <= 0
        ? l10n.aiTodayGroup
        : days == 1
            ? l10n.aiYesterdayGroup
            : days < 7
                ? l10n.aiWeekGroup
                : l10n.aiEarlierGroup;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final sessions =
        _search.text.trim().isEmpty ? chat.sessions : (_found ?? []);
    return Drawer(
        width: 340,
        backgroundColor: colors.surfaceContainerLowest,
        child: SafeArea(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
              Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 8, 12),
                  child: Row(children: [
                    Expanded(
                        child: Text(l10n.aiHistory,
                            style: Theme.of(context).textTheme.titleMedium)),
                    IconButton(
                        tooltip: l10n.aiDeleteHistory,
                        icon: const Icon(Icons.delete_sweep_outlined),
                        onPressed: chat.history == null ||
                                (chat.sessions.isEmpty && !chat.historyFailed)
                            ? null
                            : () async {
                                if (!await _confirm(l10n.aiDeleteHistory,
                                        l10n.aiDeleteHistoryBody) ||
                                    !mounted) return;
                                try {
                                  await chat.clearHistory();
                                  if (mounted) {
                                    _search.clear();
                                    setState(() => _found = null);
                                  }
                                } catch (_) {
                                  if (mounted) _failure();
                                }
                              }),
                  ])),
              Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: OutlinedButton.icon(
                      onPressed: chat.historyFailed
                          ? null
                          : () async {
                              await chat.newChat();
                              if (context.mounted) Navigator.pop(context);
                            },
                      icon: const Icon(Icons.add_rounded, size: 20),
                      label: Text(l10n.aiNewChat))),
              Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                      controller: _search,
                      onChanged: (v) {
                        setState(() {});
                        _find(v);
                      },
                      decoration: InputDecoration(
                          hintText: l10n.aiHistorySearch,
                          prefixIcon: const Icon(Icons.search_rounded),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12)))),
              Expanded(
                  child: sessions.isEmpty
                      ? Center(
                          child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text(
                                  _search.text.isEmpty
                                      ? l10n.aiHistoryEmpty
                                      : l10n.aiHistoryNoResults,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      color: colors.onSurfaceVariant))))
                      : ListView.builder(
                          itemCount: sessions.length,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          itemBuilder: (context, index) {
                            final session = sessions[index];
                            final period = _period(session.updatedAt);
                            final heading = index == 0 ||
                                _period(sessions[index - 1].updatedAt) !=
                                    period;
                            return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (heading)
                                    Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                            12, 16, 12, 6),
                                        child: Text(period,
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelMedium
                                                ?.copyWith(
                                                    color: colors
                                                        .onSurfaceVariant))),
                                  ListTile(
                                      dense: true,
                                      selected: session.id == chat.session.id,
                                      selectedTileColor: colors.primaryContainer
                                          .withValues(alpha: .4),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12)),
                                      title: Text(
                                          session.title.isEmpty
                                              ? l10n.aiUntitled
                                              : session.title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis),
                                      subtitle: session.preview.isEmpty
                                          ? null
                                          : Text(
                                              session.preview
                                                  .replaceAll('\n', ' '),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis),
                                      onTap: chat.historyFailed
                                          ? null
                                          : () async {
                                              await chat.selectChat(session);
                                              if (context.mounted)
                                                Navigator.pop(context);
                                            },
                                      trailing: PopupMenuButton<String>(
                                          tooltip:
                                              '${l10n.aiHistory}: ${session.title}',
                                          onSelected: (value) async {
                                            if (value == 'rename') {
                                              await _rename(session);
                                              return;
                                            }
                                            if (!await _confirm(
                                                    l10n.aiDeleteChat,
                                                    l10n.aiDeleteChatBody) ||
                                                !mounted) return;
                                            try {
                                              await chat.deleteChat(session);
                                              _find(_search.text);
                                            } catch (_) {
                                              if (mounted) _failure();
                                            }
                                          },
                                          itemBuilder: (_) => [
                                                PopupMenuItem(
                                                    value: 'rename',
                                                    child: Text(l10n.aiRename)),
                                                PopupMenuItem(
                                                    value: 'delete',
                                                    child: Text(
                                                        l10n.aiDeleteChat)),
                                              ])),
                                ]);
                          })),
              Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Text(l10n.aiHistoryLocal,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant, height: 1.5))),
              if (kIsWeb)
                Padding(
                    padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
                    child: Text(l10n.aiHistoryBrowser,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant, height: 1.4))),
              Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: TextButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.maybePop(context);
                      },
                      icon: const Icon(Icons.arrow_back_rounded, size: 18),
                      label: Text(l10n.aiReturnSchedule))),
            ])));
  }
}
