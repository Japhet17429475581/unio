import 'locale_service.dart';
import 'legal_service.dart';
import 'package:flutter/foundation.dart';
import 'web_portal_service.dart';
import '../utils/service_messages.dart';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/account_info.dart';
import 'direct_portal_client.dart';
import 'secure_storage_service.dart';
import 'groups_service.dart';

class AuthApiException implements Exception {
  final String message;

  const AuthApiException(this.message);

  @override
  String toString() => message;
}

Future<Map<String, dynamic>> _decodeOrThrow(http.Response response) async {
  final body = utf8.decode(response.bodyBytes);

  if (response.statusCode != 200) {
    try {
      final code = (jsonDecode(body) as Map)['detail']?['code'];
      if (code == 'unknown_group') {
        throw AuthApiException(
            l10n.groupNotInCatalogShort);
      }
      if (code == 'group_directory_unavailable') {
        throw AuthApiException(
            l10n.groupCheckFailed);
      }
    } on AuthApiException {
      rethrow;
    } catch (_) {}
    final message = responseMessage(response.statusCode);
    throw AuthApiException(message);
  }

  return jsonDecode(body) as Map<String, dynamic>;
}

/// Гостевой вход — только код группы, без пароля от портала.
/// Возвращает account_token.
Future<String> registerGuest({required String groupCode}) async {
  final uri = Uri.https(apiHost, '/api/v1/auth/guest');

  final http.Response response;
  try {
    response = await http
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'group_code': groupCode,
            'consents': await legal.currentReceipts()
          }),
        )
        .timeout(const Duration(seconds: 30));
  } catch (_) {
    throw AuthApiException(
      connectionMessage,
    );
  }

  final data = await _decodeOrThrow(response);
  final token = data['account_token'] as String?;
  if (token == null) {
    throw AuthApiException(l10n.signInIncomplete);
  }
  return token;
}

/// Вход напрямую в ВГСПУ. Сервер Unio получает только код группы.
Future<String> loginPortalAccount({
  required String login,
  required String password,
  required String groupCode,
}) async {
  try {
    groupCode = resolveGroup(await fetchGroups(), groupCode);
  } on GroupDirectoryException catch (error) {
    throw AuthApiException(error.message);
  }
  if (kIsWeb) {
    final existing = await loadSession();
    final result = await webPortal.login(
        login: login,
        password: password,
        group: groupCode,
        accountToken: existing?.accountToken);
    return result['account_token'] as String;
  }
  await withPortal((_) async {}, login: login, password: password);
  final existing = await loadSession();
  if (existing != null &&
      (!existing.isPortalMode || existing.groupCode == groupCode)) {
    return existing.accountToken;
  }
  return registerGuest(groupCode: groupCode);
}

/// Portal authentication is checked on-device. FIO selects a public timetable;
/// it is not a claim that the portal verified the user's employee role.
Future<TeacherPortalSession> loginTeacherPortalAccount({
  required String login,
  required String password,
  required String fio,
}) async {
  final normalizedFio = fio.trim().replaceAll(RegExp(r'\s+'), ' ');
  final normalizedLogin = login.trim();
  if (normalizedFio.length < 3 || normalizedFio.length > 255) {
    throw AuthApiException(l10n.fullNameRequired);
  }
  if (normalizedLogin.isEmpty || password.isEmpty) {
    throw AuthApiException(l10n.credentialsRequired);
  }
  String? webToken;
  if (kIsWeb) {
    final result = await webPortal.login(
        login: normalizedLogin, password: password, teacherFio: normalizedFio);
    webToken = result['account_token'] as String;
  } else {
    await withPortal((_) async {}, login: normalizedLogin, password: password);
  }
  final session = TeacherPortalSession(
      fio: normalizedFio,
      login: normalizedLogin,
      password: kIsWeb ? '' : password,
      webAccountToken: webToken);
  // One secure write, and only after the portal has accepted the credentials.
  await saveTeacherSession(session);
  return session;
}

/// Текущий аккаунт — используется при запуске приложения, чтобы понять,
/// гость сейчас или полноценный вход, и подтянуть group_code.
Future<AccountInfo> fetchMe(String accountToken) async {
  final uri = Uri.https(apiHost, '/api/v1/auth/me');

  final http.Response response;
  try {
    response = await http.get(uri, headers: {
      'X-Unio-Token': accountToken
    }).timeout(const Duration(seconds: 20));
  } catch (_) {
    throw AuthApiException(connectionMessage);
  }

  final data = await _decodeOrThrow(response);
  return AccountInfo.fromJson(data);
}

/// Выход — сообщаем бэку (best effort) и чистим локальное хранилище
/// вызывает сам вызывающий код после успешного или неуспешного запроса.
Future<void> logoutAccount(String accountToken) async {
  final uri = Uri.https(apiHost, '/api/v1/auth/logout');
  try {
    await http.post(uri, headers: {'X-Unio-Token': accountToken}).timeout(
        const Duration(seconds: 15));
  } catch (_) {
    // выходим локально в любом случае, даже если бэк не ответил
  }
}
