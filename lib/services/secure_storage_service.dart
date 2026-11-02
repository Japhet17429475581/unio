import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'local_write_guard.dart';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Локальная сессия Unio.
///
/// Храним:
/// - account_token — токен аккаунта Unio
/// - group_code — группа студента
/// - is_portal_mode — вошёл ли пользователь через портал
/// - portal_login — логин портала ВГСПУ
/// - portal_password — пароль портала ВГСПУ
///
/// Данные хранятся через Keychain на iOS и Keystore на Android.
class PortalSession {
  final String accountToken;
  final String? groupCode;
  final String? accountGroup;
  final String? selectedScheduleGroup;
  final bool isPortalMode;
  final String? portalLogin;
  final String? portalPassword;

  const PortalSession({
    required this.accountToken,
    this.groupCode,
    this.accountGroup,
    this.selectedScheduleGroup,
    this.isPortalMode = false,
    this.portalLogin,
    this.portalPassword,
  });

  bool get isPortalModeValid =>
      isPortalMode && portalLogin != null && (kIsWeb || portalPassword != null);
}

const _storage = FlutterSecureStorage(
  iOptions:
      IOSOptions(accessibility: KeychainAccessibility.first_unlock_this_device),
);

const _kAccountToken = 'account_token';
const _kGroupCode = 'group_code';
const _kAccountGroup = 'account_group_v1';
const _kSelectedGroup = 'selected_schedule_group_v1';
const _kPortalMode = 'is_portal_mode';
const _kPortalLogin = 'portal_login';
const _kPortalPassword = 'portal_password';
const _kTeacherSession = 'teacher_portal_session_v1';

/// Kept separate from student credentials and student-only portal services.
class TeacherPortalSession {
  final String fio;
  final String login;
  final String password;
  final String? webAccountToken;
  const TeacherPortalSession(
      {required this.fio,
      required this.login,
      required this.password,
      this.webAccountToken});
}

Future<void> saveTeacherSession(TeacherPortalSession session) async {
  await _storage.write(key: 'session_closed_v1', value: 'true');
  await _storage.write(
    key: _kTeacherSession,
    value: jsonEncode({
      'fio': session.fio,
      'login': session.login,
      if (!kIsWeb) 'password': session.password,
      if (kIsWeb) 'web_account_token': session.webAccountToken,
    }),
  );

  await _storage.delete(key: 'session_closed_v1');
  allowPrivateWrites();
}

Future<TeacherPortalSession?> loadTeacherSession() async {
  if (await _storage.read(key: 'session_closed_v1') != null ||
      await _storage.read(key: 'privacy_cleanup_pending_v1') != null)
    return null;
  final raw = await _storage.read(key: _kTeacherSession);
  if (raw == null) return null;
  try {
    final data = jsonDecode(raw);
    if (data is! Map) return null;
    final fio = data['fio'],
        login = data['login'],
        password = data['password'] ?? '';
    final webToken = data['web_account_token'];
    if (fio is! String ||
        fio.trim().length < 3 ||
        fio.length > 255 ||
        login is! String ||
        login.trim().isEmpty ||
        password is! String ||
        (!kIsWeb && password.isEmpty) ||
        (kIsWeb && (webToken is! String || webToken.isEmpty))) return null;
    return TeacherPortalSession(
        fio: fio,
        login: login,
        password: password,
        webAccountToken: webToken is String ? webToken : null);
  } on FormatException {
    return null;
  }
}

Future<void> clearTeacherSession() => _storage.delete(key: _kTeacherSession);

/// Сохраняет текущую сессию.
Future<void> saveSession({
  required String accountToken,
  required String groupCode,
  required bool isPortalMode,
  String? portalLogin,
  String? portalPassword,
  String? accountGroup,
}) async {
  await _storage.write(key: 'session_closed_v1', value: 'true');
  await _storage.write(
    key: _kAccountToken,
    value: accountToken,
  );

  await _storage.write(
    key: _kGroupCode,
    value: groupCode,
  );

  // Only a trusted portal response may populate accountGroup.
  if (accountGroup == null) {
    await _storage.delete(key: _kAccountGroup);
  } else {
    await _storage.write(key: _kAccountGroup, value: accountGroup);
  }
  await _storage.write(key: _kSelectedGroup, value: accountGroup ?? groupCode);
  await _storage.write(
    key: _kPortalMode,
    value: isPortalMode ? 'true' : 'false',
  );

  if (isPortalMode && portalLogin != null && portalPassword != null) {
    await _storage.write(
      key: _kPortalLogin,
      value: portalLogin,
    );

    if (kIsWeb) {
      await _storage.delete(key: _kPortalPassword);
    } else {
      await _storage.write(key: _kPortalPassword, value: portalPassword);
    }
  } else {
    await _storage.delete(key: _kPortalLogin);
    await _storage.delete(key: _kPortalPassword);
  }
  await _storage.delete(key: 'session_closed_v1');
  allowPrivateWrites();
}

/// Загружает сохранённую сессию после запуска приложения.
Future<PortalSession?> loadSession() async {
  if (await _storage.read(key: 'session_closed_v1') != null ||
      await _storage.read(key: 'privacy_cleanup_pending_v1') != null)
    return null;
  final token = await _storage.read(key: _kAccountToken);

  if (token == null || token.isEmpty) {
    return null;
  }

  final groupCode = await _storage.read(key: _kGroupCode);
  final portalModeRaw = await _storage.read(key: _kPortalMode);

  final isPortalMode = portalModeRaw == 'true';

  final portalLogin = await _storage.read(key: _kPortalLogin);
  final portalPassword = await _storage.read(key: _kPortalPassword);

  return PortalSession(
    accountToken: token,
    groupCode: groupCode,
    accountGroup: await _storage.read(key: _kAccountGroup),
    selectedScheduleGroup:
        await _storage.read(key: _kSelectedGroup) ?? groupCode,
    isPortalMode: isPortalMode,
    portalLogin: portalLogin,
    portalPassword: portalPassword,
  );
}

/// Полностью удаляет локальную сессию.
Future<void> clearSession() async {
  var failed = false;
  try {
    await _storage.write(key: 'session_closed_v1', value: 'true');
  } catch (_) {
    failed = true;
  }
  for (final key in [
    _kPortalPassword,
    _kPortalLogin,
    _kAccountToken,
    _kGroupCode,
    _kPortalMode,
    _kAccountGroup,
    _kSelectedGroup
  ]) {
    try {
      await _storage.delete(key: key);
    } catch (_) {
      failed = true;
    }
  }
  if (failed) throw StateError('credential_cleanup_pending');
}

/// Changes only the viewed timetable; credentials and account identity are intact.
Future<void> saveSelectedScheduleGroup(String group) async {
  if (await loadSession() == null) throw StateError('session_closed');
  await _storage.write(key: _kSelectedGroup, value: group);
}
