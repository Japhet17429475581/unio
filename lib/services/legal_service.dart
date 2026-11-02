import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'analytics_service.dart';

const legalStorage = FlutterSecureStorage(
  iOptions:
      IOSOptions(accessibility: KeychainAccessibility.first_unlock_this_device),
);
const legalJournalKey = 'legal_receipts_v1';
const legalActiveKey = 'legal_active_v1';

class LegalDocument {
  final String id, title, version, sha256, text;
  final bool draft;
  const LegalDocument(
      this.id, this.title, this.version, this.sha256, this.text, this.draft);
}

class LegalService {
  Map<String, LegalDocument>? _documents;
  Future<void> _writes = Future.value();
  Future<void> _analyticsWrites = Future.value();

  Future<Map<String, LegalDocument>> documents() async =>
      _documents ??= await _loadDocuments();
  Future<Map<String, LegalDocument>> _loadDocuments() async {
    final json =
        jsonDecode(await rootBundle.loadString('assets/legal/documents.json'))
            as Map;
    return json.map((id, d) => MapEntry(
        id as String,
        LegalDocument(id, d['title'], d['version'], d['sha256'], d['text'],
            d['draft'] == true)));
  }

  Future<List<Map<String, dynamic>>> receipts() async {
    final raw = await legalStorage.read(key: legalJournalKey);
    if (raw == null) return [];
    try {
      return (jsonDecode(raw) as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    } catch (_) {
      return [];
    } // Corrupt consent fails closed.
  }

  Future<Map<String, dynamic>?> latest(String id) async {
    final doc = (await documents())[id]!;
    for (final receipt in (await receipts()).reversed) {
      if (receipt['document'] == id) {
        return receipt['version'] == doc.version &&
                receipt['sha256'] == doc.sha256
            ? receipt
            : null;
      }
    }
    return null;
  }

  Future<bool> coreAccepted() async =>
      await legalStorage.read(key: legalActiveKey) == 'true' &&
      (await latest('terms'))?['accepted'] == true &&
      (await latest('personal_data'))?['accepted'] == true;

  String _eventId() {
    final random = Random.secure();
    final bytes = List.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 15) | 64;
    bytes[8] = (bytes[8] & 63) | 128;
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }

  Future<void> record(String id, bool accepted, {String origin = 'user'}) {
    final task = _writes.then((_) async {
      final doc = (await documents())[id]!;
      final journal = await receipts();
      journal.add({
        'event_id': _eventId(),
        'document': id,
        'version': doc.version,
        'sha256': doc.sha256,
        'accepted': accepted,
        'occurred_at': DateTime.now().toUtc().toIso8601String(),
        'origin': origin,
      });
      // Preserve the latest receipt of each purpose when bounding local history.
      final keep = journal.reversed.take(96).toList().reversed.toList();
      for (final purpose in (await documents()).keys) {
        if (!keep.any((e) => e['document'] == purpose)) {
          final prior =
              journal.where((e) => e['document'] == purpose).lastOrNull;
          if (prior != null) keep.insert(0, prior);
        }
      }
      await legalStorage.write(key: legalJournalKey, value: jsonEncode(keep));
    });
    _writes = task.catchError((Object _) {});
    return task;
  }

  Future<void> acceptCore() async {
    // A new login must not send a previous person's consent events to its account.
    if (await legalStorage.read(key: legalActiveKey) != 'true') {
      await legalStorage.delete(key: legalJournalKey);
    }
    await record('terms', true);
    await record('personal_data', true);
    await legalStorage.write(key: legalActiveKey, value: 'true');
  }

  Future<void> setAnalytics(bool enabled, {String origin = 'user'}) {
    final task = _analyticsWrites.then((_) => _applyAnalytics(enabled, origin));
    _analyticsWrites = task.catchError((Object _) {});
    return task;
  }

  Future<void> _applyAnalytics(bool enabled, String origin) async {
    // Revocation stops the native process even if evidence cannot be written.
    if (!enabled) {
      try {
        await record('analytics', false, origin: origin);
      } finally {
        await analytics.setConsent(false);
      }
    } else {
      if (!await coreAccepted()) throw StateError('core_consent_required');
      await record('analytics', true, origin: origin);
      await analytics.setConsent(true,
          version: (await documents())['analytics']!.version);
    }
  }

  Future<void> restoreAnalytics() async {
    final enabled = await coreAccepted() &&
        (await latest('analytics'))?['accepted'] == true;
    await analytics.setConsent(enabled,
        version: (await documents())['analytics']!.version);
  }

  Future<List<Map<String, dynamic>>> currentReceipts() async {
    final docs = await documents();
    return (await receipts())
        .where((r) => docs[r['document']]?.version == r['version'])
        .toList();
  }

  Future<void> sync(String token) async {
    final response = await http
        .put(Uri.https(apiHost, '/api/v1/auth/consents'),
            headers: {
              'X-Unio-Token': token,
              'Content-Type': 'application/json'
            },
            body: jsonEncode({'consents': await currentReceipts()}))
        .timeout(const Duration(seconds: 10));
    if (response.statusCode != 204) throw StateError('consent_sync_pending');
  }
}

final legal = LegalService();
