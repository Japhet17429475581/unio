import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unio_app/services/auth_service.dart';
import 'package:unio_app/services/direct_portal_client.dart';
import 'package:unio_app/services/secure_storage_service.dart';

import 'support/portal_fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({
      'account_token': 'student-token',
      'group_code': 'TEST',
      'is_portal_mode': 'true',
      'portal_login': 'student',
      'portal_password': 'student-secret',
    });
    SharedPreferences.setMockInitialValues(
        {'teacher_fio': 'Старый тестовый вход'});
  });
  tearDown(() => DirectPortalClient.testFactory = null);

  test(
      'Teacher authenticates only with VGSPU and restores an independent secure session',
      () async {
    var posts = 0;
    DirectPortalClient.testFactory = () => fakePortal((request) {
          expect(request.uri.host, 'portal.vspu.ru');
          expect(request.uri.scheme, 'https');
          if (request.method == 'GET') return page(portalLoginHtml);
          posts++;
          expect(request.data['LoginForm[username]'], 'teacher');
          expect(request.data['LoginForm[password]'], ' secret ');
          return page(portalLoggedInHtml);
        });
    await http.runWithClient(() async {
      final result = await loginTeacherPortalAccount(
        login: ' teacher ',
        password: ' secret ',
        fio: ' Иванов   Иван Иванович ',
      );
      expect(result.fio, 'Иванов Иван Иванович');
    },
        () => MockClient((_) =>
            throw StateError('Teacher credentials must not reach UNIO API')));
    expect(posts, 1);
    final restored = await loadTeacherSession();
    expect(restored?.fio, 'Иванов Иван Иванович');
    expect(restored?.login, 'teacher');
    expect(restored?.password, ' secret ');
    expect((await loadSession())?.accountToken, 'student-token');
    expect((await loadSession())?.portalPassword, 'student-secret');
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getKeys(), {'teacher_fio'});
    await clearTeacherSession();
    expect(await loadTeacherSession(), isNull);
    expect((await loadSession())?.portalPassword, 'student-secret');
  });

  test('Rejected credentials never replace the last authenticated teacher',
      () async {
    await saveTeacherSession(const TeacherPortalSession(
        fio: 'Сохранённый преподаватель',
        login: 'saved',
        password: 'saved-secret'));
    DirectPortalClient.testFactory =
        () => fakePortal((_) => page(portalLoginHtml));
    await expectLater(
        loginTeacherPortalAccount(
            login: 'wrong', password: 'wrong', fio: 'Другой преподаватель'),
        throwsA(isA<DirectPortalException>()));
    final restored = await loadTeacherSession();
    expect(restored?.login, 'saved');
    expect(restored?.password, 'saved-secret');
  });

  test(
      'Legacy FIO alone cannot restore a portal login; malformed sessions are ignored',
      () async {
    expect(await loadTeacherSession(), isNull);
    FlutterSecureStorage.setMockInitialValues(
        {'teacher_portal_session_v1': '{broken'});
    expect(await loadTeacherSession(), isNull);
    FlutterSecureStorage.setMockInitialValues({
      'teacher_portal_session_v1':
          '{"fio":"Иван Иванов","login":"teacher","password":""}'
    });
    expect(await loadTeacherSession(), isNull);
  });

  test('Missing credentials fail before accessing the portal or storage',
      () async {
    DirectPortalClient.testFactory =
        () => throw StateError('No request expected');
    await expectLater(
        loginTeacherPortalAccount(
            login: 'teacher', password: '', fio: 'Иванов Иван Иванович'),
        throwsA(isA<AuthApiException>()));
    expect(await loadTeacherSession(), isNull);
  });
}
