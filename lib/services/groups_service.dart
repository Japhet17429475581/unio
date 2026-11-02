import 'locale_service.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class GroupDirectoryException implements Exception {
  final String message;
  const GroupDirectoryException(this.message);
  @override
  String toString() => message;
}

String groupKey(String value) =>
    value.toUpperCase().replaceAll(RegExp(r'[^А-ЯЁA-Z0-9]'), '');

String _keyboardKey(String value) {
  const latin = 'QWERTYUIOP[]ASDFGHJKL;\'ZXCVBNM,.';
  const russian = 'ЙЦУКЕНГШЩЗХЪФЫВАПРОЛДЖЭЯЧСМИТЬБЮ';
  return groupKey(value.toUpperCase().split('').map((c) {
    final index = latin.indexOf(c);
    return index < 0 ? c : russian[index];
  }).join());
}

List<String> searchGroups(List<String> groups, String query) {
  final keys = {groupKey(query), _keyboardKey(query)}..remove('');
  if (keys.isEmpty) return groups.take(6).toList();
  int rank(String value) {
    final key = groupKey(value);
    if (keys.contains(key)) return 0;
    if (keys.any(key.startsWith)) return 1;
    if (keys.any(key.contains)) return 2;
    return 3;
  }

  final matches = groups.where((g) => rank(g) < 3).toList()
    ..sort((a, b) {
      final order = rank(a).compareTo(rank(b));
      return order == 0 ? a.compareTo(b) : order;
    });
  return matches.take(6).toList();
}

String resolveGroup(List<String> groups, String value) {
  final matches =
      groups.where((group) => groupKey(group) == groupKey(value)).toList();
  if (matches.length != 1) {
    throw GroupDirectoryException(
        l10n.groupNotInCatalog);
  }
  return matches.single;
}

Future<List<String>> fetchGroups() async {
  try {
    final response = await http
        .get(Uri.https(apiHost, '/api/v1/groups'))
        .timeout(const Duration(seconds: 60));
    if (response.statusCode != 200) throw FormatException();
    final data = jsonDecode(utf8.decode(response.bodyBytes));
    final groups = (data['groups'] as List)
        .cast<String>()
        .where((g) => g.trim().isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    if (groups.isEmpty) throw FormatException();
    return groups;
  } catch (_) {
    throw GroupDirectoryException(
        l10n.groupCheckConnection);
  }
}
