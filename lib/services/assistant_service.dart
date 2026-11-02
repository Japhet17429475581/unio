import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'secure_storage_service.dart';
import 'locale_service.dart';
import '../models/portal_progress.dart';
import 'portal_service.dart';
import 'assistant_grades.dart';
import '../models/assistant_chat.dart';
import 'assistant_history.dart';
export '../models/assistant_chat.dart' show AssistantMessage, ChatSession;

/// These app requests are handled by UNIO without sending text to DeepSeek.
bool isAssistantAppRequest(String question) => RegExp(
        r'новост|\bnews\b|расписани|(?:^|\s)пар[аыу]?(?:\s|[?.,!]|$)|заняти|schedule|classes|lessons|(?:^|\s)(?:где|как|хочу|можно|закажи|заказать|оформи(?:ть)?|получить|открой|открыть|перейти|перейди|подать)(?:\s|[,.!?]|$).{0,65}(?:справк|заявлен)|(?:справк|заявлен).{0,45}(?:заказать|оформить|открыть|подать)|^\s*справки\s+и\s+заявления[?!.\s]*$|(?:where|how|order|request|open|submit).{0,55}(?:certificate|application)',
        caseSensitive: false)
    .hasMatch(question);

String assistantDisplayText(String text) => text
    .replaceAll(RegExp(r'\[S\d+(?:\s*[,;]\s*S\d+)*\]'), '')
    .replaceAll(RegExp(r' {2,}'), ' ')
    .trim();

/// One active chat, with bounded network context and device-only persistence.
class AssistantConversation extends ChangeNotifier {
  final http.Client _client;
  final Future<String?> Function() _token;
  final Future<PortalProgressResult> Function() _grades;
  final Future<bool> Function() _hasPortal;
  final List<AssistantMessage> messages = [];
  bool busy = false;
  String stage = 'searching';
  bool allowExternal = false;
  bool _closed = false;
  int _generation = 0;
  String _context = '';
  static final Set<AssistantConversation> _instances = {};
  static final Set<Future<void>> _closingWrites = {};
  AssistantHistory? history;
  ChatSession session = ChatSession();
  String draft = '';
  bool historyReady = false, historyFailed = false;
  int olderMessages = 0;
  bool _loadingHistory = false;
  bool _switching = false;
  bool _historyOpened = false;
  Timer? _draftTimer;
  Completer<void>? _abort;
  AssistantMessage? _pending;
  final Future<String?> Function() _owner;
  List<ChatSession> get sessions => history?.sessions ?? [];

  bool _gradesContext = false;
  AssistantConversation(
      {this.history,
      Future<String?> Function()? owner,
      http.Client? client,
      Future<String?> Function()? token,
      Future<PortalProgressResult> Function()? grades,
      Future<bool> Function()? hasPortal})
      : _owner = owner ?? currentChatOwner,
        _client = client ?? http.Client(),
        _grades = grades ?? fetchPortalGrades,
        _hasPortal = hasPortal ??
            (() async => (await loadSession())?.isPortalModeValid == true),
        _token = token ?? (() async => (await loadSession())?.accountToken) {
    _instances.add(this);
  }

  static Future<void> endSessions() async {
    await Future.wait(_closingWrites.toList());
    for (final chat in _instances.toList()) {
      chat.cancel();
      chat._draftTimer?.cancel();
      chat.allowExternal = false;
      await chat.flushHistory();
      chat.history?.close();
      chat.messages.clear();
      chat.draft = '';
      chat._context = '';
      chat._gradesContext = false;
      chat._closed = true;
    }
  }

  Future<void> initializeHistory() async {
    if (historyReady || _loadingHistory || _closed) return;
    _loadingHistory = true;
    try {
      if (history == null) {
        final owner = await _owner().timeout(const Duration(seconds: 5));
        if (_closed) return;
        if (owner == null) {
          historyReady = true;
          return;
        }
        history = AssistantHistory(owner);
      }
      await history!.open();
      _historyOpened = true;
      if (_closed) return;
      // Preserve an existing in-memory conversation when introducing persistence.
      if (messages.isEmpty && sessions.isNotEmpty) {
        final chosen = sessions.where((s) => s.id == history!.selectedId);
        await _restore(chosen.isEmpty ? sessions.first : chosen.first);
      }
    } catch (_) {
      historyFailed = true;
    } finally {
      _loadingHistory = false;
      historyReady = true;
      if (!_closed) notifyListeners();
    }
  }

  Future<void> _restore(ChatSession chosen) async {
    final loaded = await history!.messages(chosen);
    final state = await history!.state(chosen.id);
    if (_closed) return;
    session = chosen;
    messages
      ..clear()
      ..addAll(loaded);
    olderMessages =
        (chosen.messageIds.length - 60).clamp(0, chosen.messageIds.length);
    draft = '${state['draft'] ?? ''}';
    _context = '${state['context'] ?? ''}';
    if (_context.length > 500) _context = _context.substring(0, 500);
    _gradesContext = state['gradesContext'] == true;
  }

  Future<void> loadOlder() async {
    if (history == null || olderMessages == 0 || _loadingHistory) return;
    _loadingHistory = true;
    try {
      final page = await history!.messages(session, before: olderMessages);
      if (_closed) return;
      messages.insertAll(0, page);
      olderMessages = (olderMessages - 60).clamp(0, olderMessages);
    } catch (_) {
      historyFailed = true;
    } finally {
      _loadingHistory = false;
      if (!_closed) notifyListeners();
    }
  }

  void setDraft(String value) {
    draft = privateChatText(value);
    session.updatedAt = DateTime.now();
    _draftTimer?.cancel();
    _draftTimer = Timer(const Duration(milliseconds: 350), _save);
  }

  void _save() {
    if (_closed ||
        history == null ||
        !historyReady ||
        _loadingHistory ||
        historyFailed) return;
    if (messages.isEmpty && draft.isEmpty && session.title.isEmpty) return;
    unawaited(history!
        .save(session, List.of(messages),
            draft: draft, context: _context, gradesContext: _gradesContext)
        .catchError((Object _) {
      if (!_closed && !historyFailed) {
        historyFailed = true;
        notifyListeners();
      }
    }));
  }

  void _emit() {
    _save();
    if (!_closed) notifyListeners();
  }

  Future<void> retryPersistence() async {
    historyFailed = false;
    try {
      if (history == null) {
        historyReady = false;
        await initializeHistory();
      } else if (!_historyOpened) {
        await history!.open();
        _historyOpened = true;
      }
      await flushHistory();
    } catch (_) {
      historyFailed = true;
    }
    if (!_closed) notifyListeners();
  }

  Future<void> flushHistory() async {
    _draftTimer?.cancel();
    _save();
    await history?.flush();
  }

  void cancel() {
    _generation++;
    if (_abort != null && !_abort!.isCompleted) _abort!.complete();
    if (busy && _pending != null) {
      _pending!.delivery = 'interrupted';
      if (_pending!.response?['status'] == 'pending')
        _pending!.response = {'status': 'interrupted'};
      _pending!.updatedAt = DateTime.now();
    }
    _pending = null;
    busy = false;
    _emit();
  }

  Future<void> selectChat(ChatSession chosen) async {
    if (historyFailed ||
        _loadingHistory ||
        _switching ||
        chosen.id == session.id ||
        !sessions.any((s) => s.id == chosen.id)) return;
    _switching = true;
    try {
      cancel();
      await flushHistory();
      _loadingHistory = true;
      await _restore(chosen);
    } catch (_) {
      historyFailed = true;
    } finally {
      _loadingHistory = false;
      _switching = false;
    }
    _emit();
  }

  Future<void> newChat({bool discardUnsaved = false}) async {
    if (_loadingHistory || _switching || (historyFailed && !discardUnsaved))
      return;
    _switching = true;
    try {
      cancel();
      await flushHistory();
      session = ChatSession();
      messages.clear();
      olderMessages = 0;
      draft = '';
      _context = '';
      _gradesContext = false;
    } finally {
      _switching = false;
    }
    _emit();
  }

  Future<void> renameChat(ChatSession chosen, String title) async {
    if (title.trim().isEmpty) return;
    await history?.rename(chosen, title);
    if (session.id == chosen.id) session.title = privateChatText(title.trim());
    if (!_closed) notifyListeners();
  }

  Future<void> deleteChat(ChatSession chosen) async {
    if (chosen.id == session.id) await newChat(discardUnsaved: true);
    await history?.delete(chosen);
    if (!_closed) notifyListeners();
  }

  Future<void> clearHistory() async {
    await newChat(discardUnsaved: true);
    allowExternal = false;
    _switching = true;
    try {
      await history?.clearAll();
      if (history != null) {
        _historyOpened = true;
        historyFailed = false;
      }
    } finally {
      _switching = false;
    }
    if (!_closed) notifyListeners();
  }

  void rate(AssistantMessage message, int value) {
    message.feedback = message.feedback == value ? null : value;
    message.updatedAt = DateTime.now();
    _emit();
  }

  Future<void> retry(AssistantMessage answer, String group) async {
    if (busy) return;
    final at = messages.indexOf(answer);
    if (at != messages.length - 1 || at < 1) return;
    final q = messages[at - 1].question;
    if (q == null) return;
    // Keep the original message IDs and replace only this answer.
    await send(q, group, retryAnswer: answer);
  }

  bool isLocalRequest(String question) =>
      isAssistantAppRequest(question) ||
      isAssistantGradesRequest(question, followup: _gradesContext);

  Future<void> send(String question, String group,
      {AssistantMessage? retryAnswer}) async {
    final q = privateChatText(question.trim());
    if (busy ||
        _closed ||
        _switching ||
        _loadingHistory ||
        q.length < 2 ||
        q.length > 800) return;
    final gradesRequest = isAssistantGradesRequest(q, followup: _gradesContext);
    final explicitTopic = RegExp(
            r'образован|обучен|стип|общеж|общаг|дпо|идо|переподготов|справк|scholarship|education|dorm|tuition|courses',
            caseSensitive: false)
        .hasMatch(q);
    final followup = !explicitTopic &&
        RegExp(r'^(а(?:\s|[?!.]|$)|и(?:\s|[?!.]|$)|and\b|what about |which documents |как |какие |сколько |куда |кто |where |who |что нужно|нужно ли |можно ли |подробнее|расскажи подробнее|ещ[её]|tell me more|more details|how much)',
                caseSensitive: false)
            .hasMatch(q);
    busy = true;
    stage = gradesRequest ? 'grades_loading' : 'searching';
    final generation = _generation;
    if (session.title.isEmpty &&
        !RegExp(r'^(привет|здравствуй(?:те)?|hi|hello|hey)[!.\s]*$',
                caseSensitive: false)
            .hasMatch(q))
      session.title = q.length > 60 ? '${q.substring(0, 60)}?' : q;
    session.updatedAt = DateTime.now();
    session.preview = q;
    draft = '';
    _draftTimer?.cancel();
    if (retryAnswer == null) messages.add(AssistantMessage.question(q));
    final live =
        retryAnswer ?? AssistantMessage.response({'status': 'pending'});
    live.delivery = 'streaming';
    live.feedback = null;
    if (retryAnswer == null) messages.add(live);
    _pending = live;
    final abort = Completer<void>();
    _abort = abort;
    _emit();
    Map<String, dynamic> result;
    if (gradesRequest) {
      try {
        result = await _hasPortal()
            ? assistantGradesResult(
                q, await _grades().timeout(const Duration(seconds: 40)))
            : {'status': 'grades_auth_required'};
      } catch (_) {
        result = {'status': 'grades_unavailable'};
      }
      if (_closed || generation != _generation) return;
      _context = '';
      _gradesContext = true;
      live.response = result;
      live.delivery = 'complete';
      _pending = null;
      session.preview = live.text;
      session.updatedAt = DateTime.now();
      busy = false;
      _emit();
      return;
    }
    _gradesContext = false;
    try {
      final token = await _token();
      if (_closed || generation != _generation) return;
      if (token == null || token.isEmpty) {
        result = {'status': 'auth_required'};
      } else {
        final request = http.AbortableRequest(
            'POST', Uri.https(apiHost, '/api/v1/assistant/message'),
            abortTrigger: abort.future)
          ..headers.addAll({
            'Content-Type': 'application/json',
            'X-Unio-Token': token,
            'Accept': 'text/event-stream',
          })
          ..body = jsonEncode({
            'question': q,
            'group': group,
            'language': appLocale.locale.languageCode,
            'allow_external': allowExternal,
            'context_question': followup ? _context : '',
            'stream': true,
          });
        final response =
            await _client.send(request).timeout(const Duration(seconds: 40));
        if (response.statusCode == 401) {
          result = {'status': 'auth_required'};
        } else if (response.statusCode == 429) {
          result = {'status': 'limit'};
        } else if (response.statusCode != 200) {
          result = {'status': 'unavailable'};
        } else if ((response.headers['content-type'] ?? '')
            .contains('text/event-stream')) {
          var event = '';
          var bytes = 0;
          Map<String, dynamic>? completed;
          await for (final line in response.stream
              .transform(utf8.decoder)
              .transform(const LineSplitter())
              .timeout(const Duration(seconds: 40))) {
            if (_closed || generation != _generation) return;
            bytes += line.length;
            if (bytes > 100000) throw const FormatException('Oversized stream');
            if (line.startsWith('event:')) event = line.substring(6).trim();
            if (!line.startsWith('data:')) continue;
            final data =
                Map<String, dynamic>.from(jsonDecode(line.substring(5)) as Map);
            if (event == 'status') {
              stage = data['status'] as String? ?? 'searching';
              _emit();
            } else if (event == 'partial') {
              live.response = safeChatPayload(data);
              live.updatedAt = DateTime.now();
              _emit();
            } else if (event == 'result') {
              completed = data;
              break;
            }
          }
          result = completed ?? {'status': 'unavailable'};
        } else {
          final bytes = await response.stream
              .toBytes()
              .timeout(const Duration(seconds: 40));
          if (bytes.length > 100000)
            throw const FormatException('Oversized response');
          result =
              Map<String, dynamic>.from(jsonDecode(utf8.decode(bytes)) as Map);
        }
      }
    } on http.ClientException {
      result = {'status': 'network_error'};
    } on TimeoutException {
      if (!abort.isCompleted) abort.complete();
      result = {'status': 'network_error'};
    } catch (_) {
      result = {'status': 'unavailable'};
    }
    if (_closed || generation != _generation) return;
    if (result['status'] == 'answered' && (_context.isEmpty || !followup))
      _context = q.length > 500 ? q.substring(0, 500) : q;
    if (['network_error', 'unavailable'].contains(result['status']) &&
        live.response?['status'] == 'answered') {
      live.delivery = 'interrupted';
    } else {
      live.response = safeChatPayload(result);
      live.delivery = 'complete';
    }
    live.updatedAt = DateTime.now();
    _pending = null;
    session.updatedAt = DateTime.now();
    session.preview = live.text;
    busy = false;
    _emit();
  }

  void clear() {
    if (historyFailed) return;
    _generation++;
    cancel();
    messages.clear();
    session = ChatSession();
    draft = '';
    olderMessages = 0;
    _context = '';
    _gradesContext = false;
    allowExternal = false;
    busy = false;
    _emit();
  }

  @override
  void dispose() {
    _save();
    _draftTimer?.cancel();
    _instances.remove(this);
    if (history != null) {
      final store = history!;
      final closing = store.flush().whenComplete(store.close);
      _closingWrites.add(closing);
      unawaited(closing.whenComplete(() => _closingWrites.remove(closing)));
    }
    if (_abort != null && !_abort!.isCompleted) _abort!.complete();
    _closed = true;
    _generation++;
    messages.clear();
    _context = '';
    _gradesContext = false;
    _client.close();
    super.dispose();
  }
}
