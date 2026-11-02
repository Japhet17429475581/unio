@TestOn('browser')
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:unio_app/services/secure_storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));
  test('PWA restores student access without storing the university password',
      () async {
    await saveSession(
        accountToken: 'synthetic-unio',
        groupCode: 'TEST-101',
        isPortalMode: true,
        portalLogin: 'synthetic-login',
        portalPassword: 'synthetic-password');
    final values = await const FlutterSecureStorage().readAll();
    expect(values.containsKey('portal_password'), isFalse);
    expect(values.values.join(), isNot(contains('synthetic-password')));
    final restored = await loadSession();
    expect(restored?.isPortalModeValid, isTrue);
    expect(restored?.portalPassword, isNull);
  });
  test('PWA teacher storage omits the university password', () async {
    await saveTeacherSession(const TeacherPortalSession(
        fio: 'Synthetic Teacher',
        login: 'synthetic-login',
        password: 'synthetic-password',
        webAccountToken: 'synthetic-unio'));
    final values = await const FlutterSecureStorage().readAll();
    expect(values.values.join(), isNot(contains('synthetic-password')));
    final restored = await loadTeacherSession();
    expect(restored?.webAccountToken, 'synthetic-unio');
    expect(restored?.password, '');
    await clearTeacherSession();
    expect(await loadTeacherSession(), isNull);
  });
}
