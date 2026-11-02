import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/assistant_chat.dart';
import 'local_write_guard.dart';
import 'secure_storage_service.dart';

abstract class ChatStorage {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
  Future<List<String>> keys(String prefix);
}

class SecureChatStorage implements ChatStorage {
  static const storage = FlutterSecureStorage(
      iOptions: IOSOptions(
          accessibility: KeychainAccessibility.first_unlock_this_device));
  @override
  Future<String?> read(String key) => storage.read(key: key);
  @override
  Future<void> write(String key, String value) =>
      privateWrite(() => storage.write(key: key, value: value));
  @override
  Future<void> delete(String key) =>
      privateWrite(() => storage.delete(key: key));
  @override
  Future<List<String>> keys(String prefix) async => (await storage.readAll())
      .keys
      .where((key) => key.startsWith(prefix))
      .toList();
}

Future<String?> currentChatOwner() async {
  final session = await loadSession();
  if (session == null) return null;
  // Only a digest is persisted in key names; credentials are never serialized.
  final identity = session.isPortalModeValid
      ? 'portal:${session.portalLogin!.trim()}'
      : 'guest:${session.accountToken}';
  return sha256.convert(utf8.encode('unio-chat-owner-v1:$identity')).toString();
}

/// Each encrypted message is one atomic storage record. The small encrypted
/// index is committed last; a crash cannot publish a half-written response.
class AssistantHistory {
  final ChatStorage storage;
  final String owner;
  List<ChatSession> sessions = [];
  String? selectedId;
  final Map<String, String> _encoded = {};
  Future<void> _queue = Future.value();
  bool closed = false;
  AssistantHistory(this.owner, {ChatStorage? storage})
      : storage = storage ?? SecureChatStorage();
  String get prefix => 'assistant_history_v1_$owner';
  String _key(String chat, String message) => '${prefix}_${chat}_$message';
  Future<void> _serial(Future<void> Function() action) {
    final result = _queue.then((_) async {
      if (closed) return;
      await action();
    });
    _queue = result.catchError((Object _) {});
    return result;
  }

  Future<void> open() async {
    final raw = await storage.read('${prefix}_index');
    if (raw == null) return;
    final json = jsonDecode(raw) as Map;
    if (json['version'] != 1)
      throw const FormatException('Unsupported history version');
    sessions = (json['sessions'] as List)
        .whereType<Map>()
        .map((j) => ChatSession.fromJson(Map<String, dynamic>.from(j)))
        .toList();
    selectedId = json['selected'] as String?;
  }

  Future<void> _index() => storage.write(
      '${prefix}_index',
      jsonEncode({
        'version': 1,
        'selected': selectedId,
        'sessions': sessions.map((s) => s.toJson()).toList()
      }));
  Future<List<AssistantMessage>> messages(ChatSession chat,
      {int? before, int limit = 60}) async {
    final end = before ?? chat.messageIds.length;
    final start = (end - limit).clamp(0, end);
    final result = <AssistantMessage>[];
    for (final id in chat.messageIds.sublist(start, end)) {
      final raw = await storage.read(_key(chat.id, id));
      if (raw == null) continue;
      try {
        result.add(AssistantMessage.fromJson(
            Map<String, dynamic>.from(jsonDecode(raw) as Map)));
      } catch (_) {
        result.add(AssistantMessage.fromJson({
          'id': id,
          'role': 'assistant',
          'payloadVersion': 0,
          'content': '…',
          'delivery': 'complete'
        }));
      }
    }
    return result;
  }

  Future<void> save(ChatSession chat, List<AssistantMessage> messages,
      {required String draft,
      required String context,
      required bool gradesContext}) {
    // Capture NOW, before awaiting: switching chats must not change this write.
    final encoded = {for (final m in messages) m.id: jsonEncode(m.toJson())};
    final ids = List<String>.of(chat.messageIds);
    for (final id in encoded.keys) {
      if (!ids.contains(id)) ids.add(id);
    }
    final meta = ChatSession.fromJson(chat.toJson())..messageIds = ids;
    final state = jsonEncode({
      'draft': privateChatText(draft),
      'context': privateChatText(context),
      'gradesContext': gradesContext
    });
    return _serial(() async {
      for (final entry in encoded.entries) {
        final key = _key(chat.id, entry.key);
        if (_encoded[key] != entry.value) {
          await storage.write(key, entry.value);
          _encoded[key] = entry.value;
        }
      }
      await storage.write('${prefix}_${chat.id}_state', state);
      final at = sessions.indexWhere((s) => s.id == chat.id);
      if (at < 0) {
        sessions.add(meta);
      } else {
        sessions[at] = meta;
      }
      chat.messageIds = ids;
      sessions.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      selectedId = chat.id;
      await _index();
    });
  }

  Future<Map<String, dynamic>> state(String id) async {
    final raw = await storage.read('${prefix}_${id}_state');
    return raw == null ? {} : Map<String, dynamic>.from(jsonDecode(raw) as Map);
  }

  Future<void> rename(ChatSession chat, String title) => _serial(() async {
        chat.title = privateChatText(title.trim());
        for (final s in sessions) {
          if (s.id == chat.id) s.title = chat.title;
        }
        await _index();
      });
  Future<void> delete(ChatSession chat) => _serial(() async {
        // Delete messages first. Failed deletion keeps index for a retry.
        // Include unindexed records left by a crash or a quota error.
        for (final key in await storage.keys('${prefix}_${chat.id}_')) {
          await storage.delete(key);
          _encoded.remove(key);
        }
        sessions.removeWhere((s) => s.id == chat.id);
        if (selectedId == chat.id) selectedId = null;
        await _index();
      });
  Future<List<ChatSession>> search(String query) async {
    await _queue;
    final q = query.trim().toLowerCase();
    final result = <ChatSession>[];
    for (final chat in List<ChatSession>.of(sessions)) {
      if (q.isEmpty ||
          '${chat.title} ${chat.preview}'.toLowerCase().contains(q)) {
        result.add(chat);
        continue;
      }
      for (var end = chat.messageIds.length; end > 0; end -= 60) {
        final page = await messages(chat, before: end);
        if (page.any((m) => m.text.toLowerCase().contains(q))) {
          result.add(chat);
          break;
        }
      }
    }
    return result;
  }

  Future<void> clearAll() => _serial(() async {
        for (final key in await storage.keys('${prefix}_')) {
          await storage.delete(key);
        }
        sessions.clear();
        selectedId = null;
        _encoded.clear();
        await _index();
      });
  Future<void> flush() => _queue;
  void close() {
    closed = true;
    _encoded.clear();
    sessions.clear();
  }
}
