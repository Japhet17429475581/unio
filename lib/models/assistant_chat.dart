import 'dart:math';

String newChatId() {
  final random = Random.secure();
  return List.generate(16, (_) => random.nextInt(256))
      .map((n) => n.toRadixString(16).padLeft(2, '0'))
      .join();
}

String privateChatText(String value) => value
    .replaceAll(RegExp(r'\b(?:unio_|sk-)[A-Za-z0-9_-]+'), '[hidden]')
    .replaceAll(RegExp(r'\bBearer\s+\S+', caseSensitive: false), '[hidden]')
    .replaceAll(
        RegExp(
            r'(?:пароль|password|portal_login|portal_password|account_token|token|токен)\s*[:=]\s*\S+',
            caseSensitive: false),
        '[hidden]');

dynamic _safePayload(dynamic value) {
  if (value is String) return privateChatText(value);
  if (value is List) return value.map(_safePayload).toList();
  if (value is Map)
    return <String, dynamic>{
      for (final entry in value.entries)
        if (!RegExp(
                r'password|token|credential|cookie|authorization|portal_login|^login$',
                caseSensitive: false)
            .hasMatch('${entry.key}'))
          '${entry.key}': _safePayload(entry.value),
    };
  return value;
}

Map<String, dynamic> safeChatPayload(Map<String, dynamic> value) =>
    Map<String, dynamic>.from(_safePayload(value) as Map);

class AssistantMessage {
  final String id;
  final DateTime createdAt;
  DateTime updatedAt;
  final String? question;
  Map<String, dynamic>? response;
  String delivery;
  int? feedback;
  AssistantMessage.question(String value)
      : id = newChatId(),
        createdAt = DateTime.now(),
        updatedAt = DateTime.now(),
        question = privateChatText(value),
        response = null,
        delivery = 'complete';
  AssistantMessage.response(this.response)
      : id = newChatId(),
        createdAt = DateTime.now(),
        updatedAt = DateTime.now(),
        question = null,
        delivery = 'complete';
  AssistantMessage._(this.id, this.createdAt, this.updatedAt, this.question,
      this.response, this.delivery, this.feedback);

  String get text {
    if (question != null) return question!;
    final data = response ?? {};
    if (data['status'] == 'answered')
      return (data['claims'] as List? ?? [])
          .whereType<Map>()
          .map((c) => '${c['text'] ?? ''}')
          .join('\n\n')
          .replaceAll(RegExp(r'\[S\d+(?:\s*[,;]\s*S\d+)*\]'), '')
          .replaceAll(RegExp(r' {2,}'), ' ')
          .trim();
    if (data['status'] == 'schedule')
      return [
        '${data['date'] ?? ''} · ${data['group'] ?? ''}',
        for (final row in data['lessons'] as List? ?? [])
          '${row['start'] ?? ''}–${row['end'] ?? ''} ${row['subject'] ?? ''} ${row['room'] ?? ''} ${row['teacher'] ?? ''}'
      ].join('\n');
    if (data['status'] == 'grades')
      return [
        for (final row in data['subjects'] as List? ?? [])
          [
            '${row['subject'] ?? ''}',
            for (final key in ['first_cut', 'second_cut', 'third_cut'])
              '${row[key]?['score'] ?? '—'} / ${row[key]?['hours'] ?? '—'}',
            '${row['exam']?['points'] ?? '—'} · ${row['exam']?['grade'] ?? '—'}',
          ].join('\n')
      ].join('\n\n');
    if (data['status'] == 'news')
      return [
        for (final row in data['items'] as List? ?? [])
          '${row['title'] ?? ''}\n${row['content'] ?? row['description'] ?? ''}'
      ].join('\n\n');
    return '${data['fallback_text'] ?? ''}';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'createdAt': createdAt.toUtc().toIso8601String(),
        'updatedAt': updatedAt.toUtc().toIso8601String(),
        'role': question == null ? 'assistant' : 'user',
        'content': privateChatText(text),
        'payloadVersion': 1,
        'payload': response == null ? null : safeChatPayload(response!),
        'delivery': delivery,
        'feedback': feedback,
      };
  factory AssistantMessage.fromJson(Map<String, dynamic> json) {
    final content = privateChatText('${json['content'] ?? ''}');
    final isQuestion = json['role'] == 'user';
    final payload = json['payload'];
    var data = json['payloadVersion'] == 1 && payload is Map
        ? safeChatPayload(Map<String, dynamic>.from(payload))
        : {'status': 'legacy', 'fallback_text': content};
    final collection = switch (data['status']) {
      'answered' => 'claims',
      'schedule' => 'lessons',
      'grades' => 'subjects',
      'news' => 'items',
      _ => null,
    };
    if (collection != null &&
        (data[collection] is! List ||
            (data[collection] as List).any((item) => item is! Map))) {
      data = {'status': 'legacy', 'fallback_text': content};
    }
    if (json['delivery'] == 'streaming' && data['status'] == 'pending') {
      data = {'status': 'interrupted'};
    }
    return AssistantMessage._(
        '${json['id']}',
        DateTime.tryParse('${json['createdAt']}') ?? DateTime.now(),
        DateTime.tryParse('${json['updatedAt']}') ?? DateTime.now(),
        isQuestion ? content : null,
        isQuestion ? null : data,
        json['delivery'] == 'streaming'
            ? 'interrupted'
            : '${json['delivery'] ?? 'complete'}',
        json['feedback'] == 1 || json['feedback'] == -1
            ? json['feedback'] as int
            : null);
  }
}

class ChatSession {
  final String id;
  String title, preview;
  final DateTime createdAt;
  DateTime updatedAt;
  List<String> messageIds;
  ChatSession(
      {String? id,
      this.title = '',
      this.preview = '',
      DateTime? createdAt,
      DateTime? updatedAt,
      List<String>? messageIds})
      : id = id ?? newChatId(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now(),
        messageIds = messageIds ?? [];
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': privateChatText(title),
        'preview': privateChatText(
            preview.length > 160 ? preview.substring(0, 160) : preview),
        'createdAt': createdAt.toUtc().toIso8601String(),
        'updatedAt': updatedAt.toUtc().toIso8601String(),
        'messageIds': messageIds
      };
  factory ChatSession.fromJson(Map<String, dynamic> j) => ChatSession(
      id: '${j['id']}',
      title: '${j['title'] ?? ''}',
      preview: '${j['preview'] ?? ''}',
      createdAt: DateTime.tryParse('${j['createdAt']}'),
      updatedAt: DateTime.tryParse('${j['updatedAt']}'),
      messageIds:
          (j['messageIds'] as List? ?? []).whereType<String>().toList());
}
