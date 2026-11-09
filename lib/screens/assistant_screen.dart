import 'dart:async';
import 'package:flutter/services.dart';
import '../widgets/assistant_history_drawer.dart';
import '../widgets/unio_ai_brand.dart';
import '../widgets/unio_ai_motion.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/lesson.dart';
import '../models/news_article.dart';
import '../models/portal_progress.dart';
import '../widgets/subject_card.dart';
import 'news_detail_screen.dart';
import 'news_list_screen.dart';
import 'package:intl/intl.dart';
import '../services/assistant_service.dart';
import '../services/locale_service.dart';
import 'dart:math' as math;

class AssistantScreen extends StatefulWidget {
  final AssistantConversation conversation;
  final String group;
  final bool embedded;
  final ValueChanged<Lesson>? onLessonTap;
  final VoidCallback? onOpenRequests;
  final VoidCallback? onOpenGrades;
  const AssistantScreen(
      {super.key,
      required this.conversation,
      required this.group,
      this.embedded = false,
      this.onLessonTap,
      this.onOpenRequests,
      this.onOpenGrades});
  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen>
    with WidgetsBindingObserver {
  final _scaffold = GlobalKey<ScaffoldState>();
  String? _shownSession;
  String? _latestQuestion;
  bool _initialScroll = true;
  final _input = TextEditingController();
  final _inputFocus = FocusNode();
  final _scroll = ScrollController();
  bool _permissionOpen = false;
  AssistantConversation get chat => widget.conversation;
  @override
  void initState() {
    super.initState();
    chat.addListener(_changed);
    _inputFocus.addListener(_focusChanged);
    WidgetsBinding.instance.addObserver(this);
    unawaited(chat.initializeHistory());
    _input.text = chat.draft;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && chat.historyReady) _changed();
    });
  }

  void _focusChanged() {
    if (mounted) setState(() {});
  }

  void _changed() {
    if (!mounted) return;
    if (_shownSession != chat.session.id ||
        (_input.text.isEmpty && chat.draft.isNotEmpty)) {
      _shownSession = chat.session.id;
      _input.text = chat.draft;
      _initialScroll = true;
    }
    final questions = chat.messages.where((m) => m.question != null);
    final latestQuestion = questions.isEmpty ? null : questions.last.id;
    final sentNewQuestion =
        latestQuestion != null && latestQuestion != _latestQuestion;
    _latestQuestion = latestQuestion;
    final follow = sentNewQuestion ||
        _initialScroll ||
        !_scroll.hasClients ||
        _scroll.position.extentAfter < 140 ||
        (chat.messages.isNotEmpty && chat.messages.last.question != null);
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients || !follow) return;
      if (_initialScroll || MediaQuery.of(context).disableAnimations) {
        _initialScroll = false;
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      } else {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeOutCubic);
      }
    });
  }

  @override
  void dispose() {
    chat.removeListener(_changed);
    WidgetsBinding.instance.removeObserver(this);
    unawaited(chat.flushHistory());
    _input.dispose();
    _inputFocus.removeListener(_focusChanged);
    _inputFocus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) unawaited(chat.flushHistory());
  }

  Future<void> _send([String? suggestion]) async {
    if (chat.busy || _permissionOpen) return;
    final q = (suggestion ?? _input.text).trim();
    if (q.length < 2 || q.length > 800) return;
    FocusScope.of(context).unfocus();
    final sessionId = chat.session.id;
    if (!await _ensurePermission(q) || !mounted || sessionId != chat.session.id)
      return;
    _input.clear();
    FocusScope.of(context).unfocus();
    await chat.send(q, widget.group);
  }

  Future<bool> _ensurePermission(String q) async {
    if (!chat.isLocalRequest(q) && !chat.allowExternal) {
      _permissionOpen = true;
      final accepted = await showModalBottomSheet<bool>(
          context: context,
          isScrollControlled: true,
          showDragHandle: true,
          builder: _permissionSheet);
      _permissionOpen = false;
      if (!mounted || accepted != true) return false;
      chat.allowExternal = true;
    }
    return true;
  }

  Widget _permissionSheet(BuildContext context) => SafeArea(
      child: ConstrainedBox(
          constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * .85),
          child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Flexible(
                        child: SingleChildScrollView(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                          Icon(Icons.shield_outlined,
                              color: Theme.of(context).colorScheme.primary,
                              size: 32),
                          const SizedBox(height: 16),
                          Text(l10n.aiPrivacyTitle,
                              style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: 12),
                          Text(l10n.aiPrivacyBody),
                          const SizedBox(height: 14),
                          Text(l10n.aiReferenceNotice,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                      height: 1.5,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant)),
                        ]))),
                    const SizedBox(height: 16),
                    FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: Text(l10n.aiAllow)),
                    TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text(l10n.aiNotNow)),
                  ]))));

  @override
  Widget build(BuildContext context) {
    Localizations.localeOf(context);
    final theme = Theme.of(context), colors = theme.colorScheme;
    final media = MediaQuery.of(context);
    final availableHeight = media.size.height -
        media.viewInsets.bottom -
        kToolbarHeight -
        media.padding.vertical;
    final inputLines = ((availableHeight * .35) / media.textScaler.scale(22))
        .floor()
        .clamp(1, 5);
    return UnioAiMotion(
        busy: chat.busy,
        writing: chat.stage == 'writing',
        child: Scaffold(
          key: _scaffold,
          resizeToAvoidBottomInset: !widget.embedded,
          backgroundColor: colors.surfaceContainerLowest,
          drawer: AssistantHistoryDrawer(chat: chat),
          appBar: AppBar(
            backgroundColor: colors.surfaceContainerLowest,
            surfaceTintColor: Colors.transparent,
            centerTitle: true,
            leading: IconButton(
                tooltip: l10n.aiHistory,
                icon: const Icon(Icons.menu_rounded),
                onPressed: () {
                  FocusScope.of(context).unfocus();
                  _scaffold.currentState?.openDrawer();
                }),
            title: const UnioAiWordmark(),
            actions: [
              IconButton(
                  tooltip: l10n.aiNewChat,
                  icon: const Icon(Icons.edit_square, size: 22),
                  onPressed: !chat.historyReady || chat.historyFailed
                      ? null
                      : () async {
                          await chat.newChat();
                        }),
              const SizedBox(width: 6)
            ],
          ),
          body: UnioAiAtmosphere(
              empty: chat.messages.isEmpty,
              child: SafeArea(
                  top: false,
                  child: Center(
                      child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 760),
                    child: Column(children: [
                      if (chat.historyFailed)
                        ConstrainedBox(
                            constraints: BoxConstraints(
                                maxHeight: math.max(64, availableHeight * .32)),
                            child: SingleChildScrollView(
                                child: Padding(
                                    padding:
                                        const EdgeInsets.fromLTRB(16, 8, 16, 0),
                                    child: Column(children: [
                                      Text(l10n.aiHistoryFailure,
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                  color: colors.error,
                                                  height: 1.4)),
                                      TextButton(
                                          onPressed: chat.retryPersistence,
                                          child: Text(l10n.aiHistoryRetry)),
                                    ])))),
                      Expanded(
                          child: !chat.historyReady && chat.messages.isEmpty
                              ? const Center(
                                  child: CircularProgressIndicator.adaptive())
                              : chat.messages.isEmpty
                                  ? _empty()
                                  : ListView.builder(
                                      key: ValueKey(chat.session.id),
                                      controller: _scroll,
                                      padding: const EdgeInsets.fromLTRB(
                                          20, 18, 20, 12),
                                      itemCount: chat.messages.length + 2,
                                      itemBuilder: (context, index) {
                                        if (index == 0)
                                          return chat.olderMessages > 0
                                              ? TextButton(
                                                  onPressed: () async {
                                                    final before =
                                                        _scroll.hasClients
                                                            ? _scroll.position
                                                                .maxScrollExtent
                                                            : 0.0;
                                                    final offset =
                                                        _scroll.hasClients
                                                            ? _scroll.offset
                                                            : 0.0;
                                                    await chat.loadOlder();
                                                    WidgetsBinding.instance
                                                        .addPostFrameCallback(
                                                            (_) {
                                                      if (mounted &&
                                                          _scroll.hasClients)
                                                        _scroll.jumpTo(offset +
                                                            _scroll.position
                                                                .maxScrollExtent -
                                                            before);
                                                    });
                                                  },
                                                  child: Text(l10n.aiLoadOlder))
                                              : const SizedBox.shrink();
                                        if (index <= chat.messages.length) {
                                          final message =
                                              chat.messages[index - 1];
                                          return _Appear(
                                              key: ValueKey(message.id),
                                              child: _message(message));
                                        }
                                        return Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              if (chat.busy) _thinking(),
                                              if (!chat.busy &&
                                                  chat.messages.isNotEmpty)
                                                _suggestions(_followups()),
                                            ]);
                                      })),
                      _composer(inputLines),
                    ]),
                  )))),
        ));
  }

  Widget _thinking() {
    final status = switch (chat.stage) {
      'writing' => l10n.aiWriting,
      'schedule_loading' => l10n.aiLoadingSchedule,
      'grades_loading' => l10n.aiLoadingGrades,
      _ => l10n.aiSearching,
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(children: [
        const UnioAiMark(size: 24),
        const SizedBox(width: 12),
        Flexible(
            child: Semantics(
                liveRegion: true,
                child: AnimatedSwitcher(
                  duration: MediaQuery.disableAnimationsOf(context)
                      ? Duration.zero
                      : const Duration(milliseconds: 180),
                  child: Text(status,
                      key: ValueKey(chat.stage),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant)),
                ))),
      ]),
    );
  }

  Widget _composer(int inputLines) {
    final theme = Theme.of(context), colors = theme.colorScheme;
    return Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: UnioAiComposerSurface(
            focused: _inputFocus.hasFocus,
            child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 5, 6, 5),
                child:
                    Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Expanded(
                      child: TextField(
                          controller: _input,
                          focusNode: _inputFocus,
                          enabled: chat.historyReady,
                          minLines: 1,
                          maxLines: inputLines,
                          maxLength: 800,
                          textCapitalization: TextCapitalization.sentences,
                          textInputAction: TextInputAction.newline,
                          style: theme.textTheme.bodyMedium,
                          decoration: InputDecoration(
                              hintText: l10n.aiInput,
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              filled: false,
                              counterText: '',
                              contentPadding:
                                  const EdgeInsets.symmetric(vertical: 12)),
                          onChanged: (value) {
                            chat.setDraft(value);
                            setState(() {});
                          })),
                  const SizedBox(width: 6),
                  Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: IconButton.filled(
                          tooltip: chat.busy ? l10n.aiStop : l10n.aiSend,
                          onPressed: !chat.historyReady
                              ? null
                              : chat.busy
                                  ? chat.cancel
                                  : _input.text.trim().length < 2
                                      ? null
                                      : () => _send(),
                          style: IconButton.styleFrom(
                              backgroundColor: colors.primary,
                              foregroundColor: colors.onPrimary),
                          icon: Icon(
                              chat.busy
                                  ? Icons.stop_rounded
                                  : Icons.arrow_upward_rounded,
                              size: 21))),
                ]))));
  }

  List<String> _followups() {
    if (chat.messages.isEmpty) return [];
    final status = chat.messages.last.response?['status'];
    if (status == 'schedule') return [l10n.aiDayAfter];
    if (status == 'news') return [l10n.aiNewsFollowup];
    if (status == 'requests_help') return [];
    if (status != 'answered') return [];
    final questions = chat.messages.where((m) => m.question != null);
    if (questions.isEmpty) return [];
    final q = questions.last.question!.toLowerCase();
    if (RegExp(r'стип|scholarship').hasMatch(q))
      return [
        l10n.aiFollowup,
        l10n.aiContactsFollowup,
        l10n.aiEligibilityFollowup
      ];
    if (RegExp(r'контакт|почт|contact|email').hasMatch(q)) return [];
    return [l10n.aiFollowup, l10n.aiContactsFollowup];
  }

  Widget _empty() => LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const UnioAiMark(size: 66),
                    const SizedBox(height: 24),
                    Text(l10n.aiWelcome,
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(
                                fontWeight: FontWeight.w500,
                                letterSpacing: -.6,
                                height: 1.2)),
                    const SizedBox(height: 26),
                    _suggestions([
                      l10n.aiTomorrowFirst,
                      l10n.aiStarterGrades,
                      l10n.aiStarterRequests,
                      l10n.aiScholarship
                    ]),
                    const SizedBox(height: 24),
                    Text(l10n.aiHistoryLocal,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant)),
                    const SizedBox(height: 6),
                    Text(l10n.aiHistoryExternal,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant)),
                    const SizedBox(height: 60),
                  ]))));

  Widget _suggestions(List<String> labels) =>
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (final label in labels)
          Semantics(
              button: true,
              label: label,
              onTap: () => _send(label),
              excludeSemantics: true,
              child: ActionChip(
                  shape: const StadiumBorder(),
                  materialTapTargetSize: MaterialTapTargetSize.padded,
                  visualDensity: VisualDensity.standard,
                  label:
                      Text(label, style: Theme.of(context).textTheme.bodySmall),
                  backgroundColor: Colors.transparent,
                  side: BorderSide(
                      color: Theme.of(context)
                          .colorScheme
                          .outlineVariant
                          .withValues(alpha: .45)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 7),
                  onPressed: () => _send(label))),
      ]);

  Widget _message(AssistantMessage item) {
    final theme = Theme.of(context), c = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;
    if (item.question != null)
      return Align(
          alignment: Alignment.centerRight,
          child: Container(
              constraints: const BoxConstraints(maxWidth: 500),
              margin: const EdgeInsets.only(left: 40, bottom: 24),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
              decoration: BoxDecoration(
                  color: c.primaryContainer.withValues(alpha: dark ? .65 : .8),
                  borderRadius: BorderRadius.circular(18)),
              child: SelectableText(item.question!,
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.5))));
    final data = item.response ?? {}, status = data['status'];
    if (status == 'pending') return const SizedBox.shrink();
    return Padding(
        padding: const EdgeInsets.only(bottom: 26),
        child: Material(
            type: MaterialType.transparency,
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (status == 'answered') ...[
                for (final (i, claim)
                    in (data['claims'] as List? ?? []).indexed)
                  _Appear(
                      key: ValueKey('claim-$i'),
                      child: Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: _answerText('${claim['text']}'))),
                if (_linkedSources(data).isNotEmpty)
                  Theme(
                      data: theme.copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                          tilePadding: EdgeInsets.zero,
                          dense: true,
                          visualDensity: VisualDensity.compact,
                          title: Text(
                              '${l10n.aiSources} · ${_linkedSources(data).length}',
                              style: theme.textTheme.labelMedium
                                  ?.copyWith(color: c.onSurfaceVariant)),
                          children: [
                            for (final source in _linkedSources(data))
                              _source(Map<String, dynamic>.from(source), data),
                            Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Text(l10n.aiSourceNotice,
                                    style: theme.textTheme.bodySmall
                                        ?.copyWith(color: c.onSurfaceVariant)))
                          ])),
              ] else if (status == 'grades') ...[
                Text(l10n.aiGradesFromPortal,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: c.onSurfaceVariant)),
                const SizedBox(height: 12),
                for (final row in data['subjects'] as List) ...[
                  Text(
                      (row['semester'] as int) == 0
                          ? l10n.uiNoSemester
                          : l10n.uiSemester('${row['semester']}'),
                      style: theme.textTheme.labelMedium
                          ?.copyWith(color: c.onSurfaceVariant)),
                  const SizedBox(height: 8),
                  SubjectCard(
                      key: PageStorageKey(
                          'ai-${identityHashCode(item)}-${row['semester']}-${row['subject']}'),
                      subject: PortalSubject.fromJson(
                          Map<String, dynamic>.from(row)),
                      initiallyExpanded: true),
                  const SizedBox(height: 16),
                ],
                _openGrades(),
              ] else if ('$status'.startsWith('grades_')) ...[
                Text(_status(status),
                    style: theme.textTheme.bodyMedium?.copyWith(height: 1.65)),
                const SizedBox(height: 12),
                _openGrades(),
              ] else if (status == 'news') ...[
                Text(
                    data['date'] == null
                        ? l10n.aiNewsLatest
                        : l10n.aiNewsOnDate(_date('${data['date']}')),
                    style: theme.textTheme.bodyMedium?.copyWith(height: 1.6)),
                const SizedBox(height: 12),
                if ((data['items'] as List? ?? []).isEmpty)
                  Text(l10n.aiNewsEmpty),
                for (final row in (data['items'] as List? ?? []))
                  _news(Map<String, dynamic>.from(row)),
                if (data['has_more'] == true)
                  TextButton.icon(
                      onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const NewsListScreen())),
                      icon: const Icon(Icons.article_outlined, size: 18),
                      label: Text(l10n.aiAllNews)),
              ] else if (status == 'requests_help') ...[
                Text(l10n.aiRequestsHelp,
                    style: theme.textTheme.bodyMedium?.copyWith(height: 1.65)),
                const SizedBox(height: 14),
                if (data['action'] == 'open_requests' &&
                    widget.onOpenRequests != null)
                  FilledButton.tonalIcon(
                      onPressed: widget.onOpenRequests,
                      icon: const Icon(Icons.edit_document, size: 19),
                      label: Text(l10n.uiCertificatesAndApplications)),
                TextButton.icon(
                    onPressed: () async {
                      try {
                        await launchUrl(Uri.https('portal.vspu.ru'),
                            mode: LaunchMode.externalApplication);
                      } catch (_) {
                        if (mounted)
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(l10n.aiUnavailable)));
                      }
                    },
                    icon: const Icon(Icons.open_in_new_rounded, size: 17),
                    label: Text(l10n.aiOpenPortal)),
              ] else if (status == 'schedule') ...[
                Text('${data['date']} · ${data['group']}',
                    style: theme.textTheme.bodyMedium?.copyWith(height: 1.6)),
                const SizedBox(height: 12),
                if ((data['lessons'] as List).isEmpty) Text(l10n.aiNoLessons),
                for (final (i, row) in (data['lessons'] as List).indexed)
                  _Appear(
                      delay: i * 55,
                      child: _lesson(
                          Lesson.fromJson(Map<String, dynamic>.from(row)))),
              ] else if (status == 'legacy') ...[
                Text(l10n.aiLegacy, style: theme.textTheme.labelSmall),
                const SizedBox(height: 8),
                _answerText('${data['fallback_text'] ?? ''}'),
              ] else
                Text(_status(status),
                    style: theme.textTheme.bodyMedium?.copyWith(height: 1.6)),
              if (item.delivery == 'interrupted' && status != 'interrupted')
                Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(l10n.aiInterrupted,
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: c.onSurfaceVariant, height: 1.4))),
              if (item.delivery != 'streaming') _actions(item),
            ])));
  }

  Widget _answerText(String value) {
    final text = assistantDisplayText(value)
        .replaceAllMapped(RegExp(r'^\s*[-*]\s+', multiLine: true), (_) => '• ');
    final style =
        Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.65);
    if (!text.contains('**')) return SelectableText(text, style: style);
    final spans = <TextSpan>[];
    var start = 0;
    for (final match in RegExp(r'\*\*(.+?)\*\*').allMatches(text)) {
      if (match.start > start)
        spans.add(TextSpan(text: text.substring(start, match.start)));
      spans.add(TextSpan(
          text: match[1], style: const TextStyle(fontWeight: FontWeight.w600)));
      start = match.end;
    }
    if (start < text.length) spans.add(TextSpan(text: text.substring(start)));
    return SelectableText.rich(TextSpan(children: spans), style: style);
  }

  Widget _actions(AssistantMessage item) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    return Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Wrap(spacing: 0, children: [
          IconButton(
              tooltip: l10n.aiCopy,
              icon: const Icon(Icons.copy_rounded, size: 17),
              color: color,
              onPressed: () async {
                final text = item.text.isEmpty
                    ? _status(item.response?['status'])
                    : assistantDisplayText(item.text);
                await Clipboard.setData(ClipboardData(text: text));
                if (mounted)
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(l10n.aiCopied),
                      duration: const Duration(seconds: 1)));
              }),
          if (identical(item, chat.messages.last))
            IconButton(
                tooltip: l10n.aiRetry,
                icon: const Icon(Icons.refresh_rounded, size: 19),
                color: color,
                onPressed: chat.busy
                    ? null
                    : () async {
                        final index = chat.messages.indexOf(item);
                        if (index < 1) return;
                        final q = chat.messages[index - 1].question!;
                        if (!await _ensurePermission(q) || !mounted) return;
                        await chat.retry(item, widget.group);
                      }),
          IconButton(
              tooltip: l10n.aiHelpful,
              isSelected: item.feedback == 1,
              icon: const Icon(Icons.thumb_up_outlined, size: 17),
              selectedIcon: const Icon(Icons.thumb_up_rounded, size: 17),
              color: color,
              onPressed: () => chat.rate(item, 1)),
          IconButton(
              tooltip: l10n.aiNotHelpful,
              isSelected: item.feedback == -1,
              icon: const Icon(Icons.thumb_down_outlined, size: 17),
              selectedIcon: const Icon(Icons.thumb_down_rounded, size: 17),
              color: color,
              onPressed: () => chat.rate(item, -1)),
        ]));
  }

  Widget _openGrades() => widget.onOpenGrades == null
      ? const SizedBox.shrink()
      : FilledButton.tonalIcon(
          onPressed: widget.onOpenGrades,
          icon: const Icon(Icons.school_outlined, size: 19),
          label: Text(l10n.aiOpenGrades));

  Uri? _sourceUrl(dynamic value) {
    if (value is! String) return null;
    final uri = Uri.tryParse(value);
    return uri != null &&
            uri.scheme == 'https' &&
            uri.userInfo.isEmpty &&
            (!uri.hasPort || uri.port == 443) &&
            const {
              'www.vspu.ru',
              'vspu.ru',
              'files.vspu.ru',
              'portal.vspu.ru',
              'old.vspu.ru'
            }.contains(uri.host)
        ? uri
        : null;
  }

  List<Map<String, dynamic>> _linkedSources(Map<String, dynamic> response) =>
      (response['sources'] as List? ?? [])
          .whereType<Map>()
          .map((s) => Map<String, dynamic>.from(s))
          .where((s) =>
              s['title'] is String && (s['title'] as String).trim().isNotEmpty)
          .toList();

  String _date(String value) {
    final date = DateTime.tryParse(value);
    return date == null
        ? value
        : DateFormat.yMMMd(Localizations.localeOf(context).languageCode).format(
            value.contains('T')
                ? date.toUtc().add(const Duration(hours: 3))
                : date);
  }

  Widget _news(Map<String, dynamic> row) {
    final article = NewsArticle.fromJson(row);
    final theme = Theme.of(context), colors = theme.colorScheme;
    final uri = Uri.tryParse(article.imageUrl ?? '');
    final image = uri != null && uri.scheme == 'https' && uri.host.isNotEmpty;
    return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Material(
            color: colors.surfaceContainer.withValues(alpha: .7),
            borderRadius: BorderRadius.circular(20),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => NewsDetailScreen(
                        newsId: article.id,
                        initialArticle: row['content_truncated'] == true
                            ? null
                            : article))),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (image)
                        AspectRatio(
                            aspectRatio: 16 / 9,
                            child: Image.network(uri.toString(),
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => ColoredBox(
                                    color: colors.surfaceContainer,
                                    child: Icon(Icons.image_outlined,
                                        color: colors.onSurfaceVariant)))),
                      Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (article.publishedAt != null)
                                  Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: Text(
                                          _date(article.publishedAt!
                                              .toIso8601String()),
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                  color: colors
                                                      .onSurfaceVariant))),
                                Text(article.title,
                                    style: theme.textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        height: 1.4)),
                                const SizedBox(height: 10),
                                Text(
                                    article.content ??
                                        article.description ??
                                        '',
                                    maxLines: 6,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodyMedium
                                        ?.copyWith(height: 1.55)),
                                const SizedBox(height: 12),
                                Text(l10n.aiReadNews,
                                    style: theme.textTheme.labelLarge
                                        ?.copyWith(color: colors.primary)),
                              ])),
                    ]))));
  }

  Widget _lesson(Lesson lesson) {
    final theme = Theme.of(context), c = theme.colorScheme;
    return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Material(
            color: c.surfaceContainer.withValues(alpha: .7),
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: widget.onLessonTap == null
                    ? null
                    : () => widget.onLessonTap!(lesson),
                child: Padding(
                    padding: const EdgeInsets.all(15),
                    child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                              width: 62,
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(lesson.start,
                                        style: TextStyle(
                                            color: c.primary,
                                            fontWeight: FontWeight.w700)),
                                    const SizedBox(height: 3),
                                    Text(lesson.end,
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                                color: c.onSurfaceVariant))
                                  ])),
                          Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                Text(lesson.subject,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        height: 1.4)),
                                if (lesson.type?.isNotEmpty == true)
                                  Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(lesson.type!,
                                          style: theme.textTheme.labelSmall
                                              ?.copyWith(
                                                  color: c.onSurfaceVariant))),
                                if (lesson.room.isNotEmpty)
                                  Padding(
                                      padding: const EdgeInsets.only(top: 6),
                                      child: Row(children: [
                                        Icon(Icons.location_on_outlined,
                                            size: 15, color: c.primary),
                                        const SizedBox(width: 4),
                                        Expanded(
                                            child: Text(lesson.room,
                                                style:
                                                    theme.textTheme.bodySmall))
                                      ])),
                                if (lesson.teacher.isNotEmpty)
                                  Padding(
                                      padding: const EdgeInsets.only(top: 5),
                                      child: Text(lesson.teacher,
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                  color: c.onSurfaceVariant))),
                              ])),
                        ])))));
  }

  Widget _source(Map<String, dynamic> source, Map<String, dynamic> response) {
    final quotes = <String>{};
    for (final c in response['claims']) {
      for (final e in c['evidence']) {
        if (e['source_id'] == source['source_id'])
          quotes.add(e['quote'] as String);
      }
    }
    final colors = Theme.of(context).colorScheme;
    return Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: colors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
            border:
                Border.all(color: colors.outlineVariant.withValues(alpha: .6))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(Icons.description_outlined, size: 20, color: colors.primary),
            const SizedBox(width: 10),
            Expanded(
                child: Text('${source['title']}',
                    style: Theme.of(context).textTheme.labelLarge)),
          ]),
          if (_sourceUrl(source['source_url']) case final Uri url) ...[
            const SizedBox(height: 4),
            Text(url.host,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Theme.of(context).colorScheme.primary)),
          ],
          if (source['page'] != null) ...[
            const SizedBox(height: 5),
            Text('${l10n.aiPage} ${source['page']}',
                style: Theme.of(context).textTheme.bodySmall),
          ],
          if (source['category'] is String)
            Text(source['category'] as String,
                style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 8),
          for (final quote in quotes)
            Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: SelectableText('«$quote»',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(height: 1.5))),
          if (_sourceUrl(source['source_url']) != null)
            TextButton.icon(
                onPressed: () async {
                  final uri = _sourceUrl(source['source_url']);
                  if (uri == null) return;
                  try {
                    if (!await launchUrl(uri,
                        mode: LaunchMode.externalApplication))
                      throw StateError('unavailable');
                  } catch (_) {
                    if (mounted)
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.aiUnavailable)));
                  }
                },
                icon: const Icon(Icons.open_in_new_rounded, size: 15),
                label: Text(l10n.aiOpenSource)),
        ]));
  }

  String _status(dynamic value) => switch (value) {
        'network_error' => l10n.aiNetworkError,
        'interrupted' => l10n.aiInterrupted,
        'grades_auth_required' => l10n.aiGradesAuthRequired,
        'grades_unavailable' => l10n.aiGradesUnavailable,
        'grades_empty' => l10n.aiGradesEmpty,
        'grades_not_found' => l10n.aiGradesNotFound,
        'grades_on_device' => l10n.aiGradesAuthRequired,
        'news_choose_date' => l10n.aiNewsChooseDate,
        'news_unavailable' => l10n.aiNewsUnavailable,
        'off_topic' => l10n.aiOffTopic,
        'sensitive' => l10n.aiSensitive,
        'insufficient' => l10n.aiInsufficient,
        'not_configured' => l10n.aiNotConfigured,
        'choose_date' => l10n.aiChooseDate,
        'date_range' => l10n.aiDateRange,
        'choose_group' => l10n.aiChooseGroup,
        'schedule_unavailable' => l10n.aiScheduleUnavailable,
        'permission_required' => l10n.aiPermissionRequired,
        'auth_required' => l10n.aiAuthRequired,
        'limit' => l10n.aiLimit,
        'busy' => l10n.aiBusy,
        _ => l10n.aiUnavailable,
      };
}

class _Appear extends StatelessWidget {
  final Widget child;
  final int delay;
  const _Appear({super.key, required this.child, this.delay = 0});
  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).disableAnimations) return child;
    return TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: Duration(milliseconds: 360 + delay),
        curve: Interval(delay / (360 + delay), 1, curve: Curves.easeOutCubic),
        child: child,
        builder: (context, value, child) => Opacity(
            opacity: value,
            child: Transform.translate(
                offset: Offset(0, 14 * (1 - value)), child: child)));
  }
}
