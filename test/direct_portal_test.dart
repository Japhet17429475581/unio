import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:html/parser.dart' as html;
import 'package:unio_app/services/direct_portal_client.dart';
import 'package:unio_app/services/auth_service.dart';
import 'package:unio_app/services/requests_service.dart';
import 'package:unio_app/services/request_status_service.dart';
import 'support/portal_fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => FlutterSecureStorage.setMockInitialValues({
        'account_token': 'test-token',
        'group_code': 'TEST',
        'is_portal_mode': 'true',
        'portal_login': 'student',
        'portal_password': 'secret',
      }));
  tearDown(() => DirectPortalClient.testFactory = null);

  test(
      'Empty requests without Yii wrappers are accepted, unrelated empty pages are not',
      () {
    final result = parseRequestsList(
        '$portalLoggedInHtml<h1>Справки и заявления</h1><div class="empty">Нет заявлений</div>');
    expect(result.requests, isEmpty);
    expect(
        () => parseRequestsList(
            '$portalLoggedInHtml<h1>Новости</h1><div class="empty">Ничего не найдено</div>'),
        throwsA(isA<DirectPortalException>()));
  });

  test('Category selectors and edit links survive wrapper changes', () {
    final result = parseRequestsList(
        '$portalLoggedInHtml<select name="category_id"><option value="4">Обучение</option></select><a href="/request/123/edit">Справка</a>');
    expect(result.availableCategories.single.id, '4');
    expect(result.requests.single.id, '123');
    expect(result.requests.single.title, 'Справка');
    expect(result.requests.single.canFill, false);
  });

  test('Access challenges have a distinct safe code', () {
    expect(
        () => parseRequestsList(
            '<html><title>Just a moment...</title><form id="challenge-form"></form></html>'),
        throwsA(isA<DirectPortalException>()
            .having((e) => e.code, 'code', 'requests_access_challenge')));
  });

  test('Logout links confirm login only on the exact portal origin', () async {
    final client = fakePortal((request) => page(request.method == 'POST'
        ? '<a data-method="post" href="/auth/logout">Выход</a>'
        : portalLoginHtml));
    await client.login('student', 'secret');
    expect(
        DirectPortalClient.hasSession(
            html.parse('<a href="https://other.test/auth/logout">Выход</a>')),
        false);
    client.close();
  });

  test(
      'Password-change field does not invalidate an authenticated requests page',
      () {
    final result = parseRequestsList('$portalLoggedInHtml$portalListHtml'
        '<form action="/profile/password"><input type="password"></form>');
    expect(result.requests, hasLength(1));
    expect(
        () => parseRequestsList(portalLoginHtml),
        throwsA(isA<DirectPortalException>()
            .having((e) => e.code, 'code', 'portal_session_expired')));
  });

  test(
      'Empty responses and unexpected pages have distinct safe diagnostic codes',
      () {
    expect(
        () => parseRequestsList(''),
        throwsA(isA<DirectPortalException>()
            .having((e) => e.code, 'code', 'requests_empty_response')));
    expect(
        () => parseRequestsList('<html>Account confirmation required</html>'),
        throwsA(isA<DirectPortalException>()
            .having((e) => e.code, 'code', 'requests_unrecognized_page')));
    expect(
        parseRequestsList(
                '<div class="list-view"><div class="empty">Нет заявлений</div></div>')
            .requests,
        isEmpty);
  });

  test('Read-only requests list reauthenticates once when session expires',
      () async {
    var logins = 0;
    var reads = 0;
    DirectPortalClient.testFactory = () => fakePortal((request) {
          if (request.uri.path == '/login') {
            if (request.method == 'POST') {
              logins++;
              return page(portalLoggedInHtml);
            }
            return page(portalLoginHtml);
          }
          reads++;
          return page(reads == 1 ? portalLoginHtml : portalListHtml);
        });
    final result = await fetchRequestsList();
    expect(result.requests, hasLength(1));
    expect(logins, 2);
    expect(reads, 2);
  });

  test('Session errors never replay a mutating operation', () async {
    var writes = 0;
    DirectPortalClient.testFactory = () => fakePortal((request) {
          if (request.uri.path == '/login')
            return page(request.method == 'POST'
                ? portalLoggedInHtml
                : portalLoginHtml);
          writes++;
          return page(portalLoginHtml);
        });
    await expectLater(withPortal((client) async {
      final result =
          await client.request('/request/create', fields: {'type': 'test'});
      parseRequestsList(result.data ?? '');
    }), throwsA(isA<DirectPortalException>()));
    expect(writes, 1);
  });

  test(
      'Reads all six fields outside form, labels, hints, defaults and required flags',
      () {
    final form = parseRequestForm(portalFormHtml, '101');
    expect(form.fields, hasLength(6));
    expect(form.fields[1].label, 'Наименование организации');
    expect(form.fields[1].required, isTrue);
    expect(form.fields[1].hint, contains('официальное'));
    expect(form.fields[3].value, '1');
    expect(form.fields[4].required, isFalse);
    expect(form.notice, contains('3 рабочих дня'));
    expect(form.hasUnsupportedFields, isFalse);
    expect(form.action, 'https://portal.vspu.ru/request/101/edit');
  });

  test('Status changes are compared without inventing readiness', () {
    final initial = parseRequestsList(portalListHtml).requests;
    final ready = parseRequestsList(portalListHtml.replaceAll(
            'получение информации', 'Готова к выдаче'))
        .requests;
    expect(changedRequestStatuses(null, ready), isEmpty);
    expect(changedRequestStatuses({'101': initial.single.status}, ready),
        hasLength(1));
    expect(
        changedRequestStatuses({'101': ready.single.status}, ready), isEmpty);
    expect(isRequestReady('Готова к выдаче'), isTrue);
    expect(isRequestReady('Не готова'), isFalse);
    expect(isRequestReady('Уведомление о готовности'), isFalse);
  });

  test('Cookies from login redirect are used on the next request', () async {
    final calls = <RequestOptions>[];
    final client = fakePortal((options) {
      calls.add(options);
      if (calls.length == 1) return page(portalLoginHtml);
      if (calls.length == 2)
        return page('', status: 302, headers: {
          'location': ['/request/index'],
          'set-cookie': ['session=test-session; Path=/; Secure; HttpOnly'],
        });
      return page(portalLoggedInHtml);
    });
    await client.login('student', 'secret');
    expect(calls.last.headers['cookie'], contains('session=test-session'));
    expect(calls[1].data['_csrf'], 'csrf-test');
    expect(calls.every((o) => o.uri.host == 'portal.vspu.ru'), isTrue);
    client.close();
  });

  test('External redirects cannot receive credentials', () async {
    var calls = 0;
    final client = fakePortal((options) {
      calls++;
      return page('', status: 307, headers: {
        'location': ['https://other.example/collect']
      });
    });
    await expectLater(client.request('/login', fields: {'password': 'secret'}),
        throwsA(isA<DirectPortalException>()));
    expect(calls, 1);
    client.close();
  });

  test(
      'Portal HTTP redirects are upgraded before sending cookies or credentials',
      () async {
    for (final status in [302, 307]) {
      final calls = <RequestOptions>[];
      final client = fakePortal((options) {
        calls.add(options);
        if (calls.length == 1)
          return page('', status: status, headers: {
            'location': ['http://portal.vspu.ru/site/index'],
            'set-cookie': ['session=test; Path=/; Secure; HttpOnly'],
          });
        return page(portalLoggedInHtml);
      });
      await client.request('/login', fields: {'password': 'secret'});
      expect(calls, hasLength(2));
      expect(
          calls.every(
              (call) => call.uri.scheme == 'https' && call.uri.port == 443),
          isTrue);
      expect(calls.last.uri.path, '/site/index');
      expect(calls.last.headers['cookie'], contains('session=test'));
      expect(calls.last.method, status == 302 ? 'GET' : 'POST');
      client.close();
    }
  });

  test(
      'HTTP upgrade does not allow external hosts, userinfo or nonstandard ports',
      () {
    for (final address in [
      'http://other.example/login',
      'http://portal.vspu.ru.other.example/login',
      'http://portal.vspu.ru:8080/login',
      'http://user@portal.vspu.ru/login',
      'https://portal.vspu.ru:8443/login',
    ]) {
      expect(() => DirectPortalClient.checkedUri(address),
          throwsA(isA<DirectPortalException>()));
    }
    expect(
        DirectPortalClient.checkedUri('http://portal.vspu.ru:80/login').scheme,
        'https');
  });

  test('Types are loaded by category and COVID types are removed', () async {
    final client = fakePortal((options) {
      expect(options.uri.queryParameters['category_id'], '4');
      return page(jsonEncode({
        'result': 'ok',
        'items': {
          'a': {'id': 10, 'text': 'Справка об обучении'},
          'b': {'id': 11, 'text': 'Справка COVID-19'},
          'c': {'id': 12, 'text': 'Справка о коронавирусе'},
          'd': {'id': 13, 'text': 'Справка о получении ГСС'},
          'e': {
            'id': 14,
            'text':
                'Справка для назначения государственной социальной стипендии'
          },
        }
      }));
    });
    expect((await readRequestTypes(client, '4')).map((o) => o.id),
        ['10', '13', '14']);
    client.close();
  });

  test(
      'AJAX uses current page CSRF token and does not replace document referer',
      () async {
    final calls = <RequestOptions>[];
    final client = fakePortal((options) {
      calls.add(options);
      if (options.uri.path == '/request/index')
        return page(
            '<meta name="csrf-token" content="page-token">$portalListHtml');
      return page('{"result":"ok","items":[]}');
    });
    await client.request('/request/index');
    await client.request('/request/get-types?category_id=4', ajax: true);
    await client.request('/request/create',
        fields: {'CreateRequestForm[type_id]': '10'});
    expect(calls[1].headers['X-CSRF-Token'], 'page-token');
    expect(calls[1].headers['X-Requested-With'], 'XMLHttpRequest');
    expect(
        calls.last.headers['Referer'], 'https://portal.vspu.ru/request/index');
    expect(calls.last.headers['Origin'], 'https://portal.vspu.ru');
    client.close();
  });

  test(
      'Refused draft identifies the step without disclosing response or retrying POST',
      () async {
    var posts = 0;
    final client = fakePortal((options) {
      posts++;
      return page('Private student data: secret', status: 403);
    });
    await expectLater(
        client.request('/request/create', fields: {'password': 'secret'}),
        throwsA(isA<DirectPortalException>()
            .having((e) => e.message, 'step', contains('Создание черновика'))
            .having((e) => e.message, 'status', contains('HTTP 403'))
            .having((e) => e.message, 'privacy', isNot(contains('secret')))));
    expect(posts, 1);
    client.close();
  });

  test('Portal login sends only group code to Unio backend', () async {
    FlutterSecureStorage.setMockInitialValues({});
    DirectPortalClient.testFactory = () => fakePortal(
        (o) => page(o.method == 'GET' ? portalLoginHtml : portalLoggedInHtml));
    await http.runWithClient(() async {
      expect(
          await loginPortalAccount(
              login: 'student', password: 'secret', groupCode: 'TEST'),
          'new-token');
    },
        () => MockClient((request) async {
              if (request.url.path == '/api/v1/groups') {
                return http.Response('{"groups":["TEST"]}', 200);
              }
              expect(request.url.path, '/api/v1/auth/guest');
              final body = jsonDecode(request.body) as Map;
              expect(body.keys.toSet(), {'group_code', 'consents'});
              expect(body['group_code'], 'TEST');
              expect(request.body, isNot(contains('secret')));
              expect(request.body, isNot(contains('student')));
              expect(
                  request.headers.keys
                      .any((h) => h.toLowerCase().startsWith('x-portal')),
                  isFalse);
              return http.Response('{"account_token":"new-token"}', 200);
            }));
  });

  test(
      'HTTP 200 with unchanged draft is never reported as successful submission',
      () async {
    final posts = <RequestOptions>[];
    DirectPortalClient.testFactory = () => fakePortal((o) {
          if (o.uri.path == '/login')
            return page(
                o.method == 'GET' ? portalLoginHtml : portalLoggedInHtml);
          if (o.uri.path == '/request/index') return page(portalListHtml);
          if (o.method == 'POST') posts.add(o);
          return page(portalFormHtml);
        });
    final result = await submitRequestForm(
        requestId: '101', values: {'field_31': 'Организация'});
    expect(result.success, isFalse);
    expect(posts, hasLength(1));
    expect(
        posts.single.data.keys,
        containsAll([
          'field_30',
          'field_31',
          'field_32',
          'field_33',
          'field_34',
          'field_35'
        ]));
  });

  test('Unsupported attachments block partial submission', () {
    final form = parseRequestForm(
        portalFormHtml.replaceFirst('</form>', '<input type="file"></form>'),
        '101');
    expect(form.hasUnsupportedFields, isTrue);
  });

  test('Social stipend category and applications remain available', () {
    final list = parseRequestsList(
        portalListHtml.replaceAll('Обучение', 'Социальная стипендия'));
    expect(list.availableCategories.single.name, 'Социальная стипендия');
    expect(
        isUnavailableRequestType(
            'Назначение государственной социальной стипендии'),
        isFalse);
  });

  test('New drafts and submitted requests never request an edit page',
      () async {
    for (final status in ['Новое', 'На обработке', 'Готова к выдаче']) {
      final routes = <String>[];
      DirectPortalClient.testFactory = () => fakePortal((o) {
            routes.add(o.uri.path);
            if (o.uri.path == '/login')
              return page(
                  o.method == 'GET' ? portalLoginHtml : portalLoggedInHtml);
            return page(
                portalListHtml.replaceAll('получение информации', status));
          });
      await expectLater(
          fetchRequestForm('101'), throwsA(isA<RequestNotFillableException>()));
      expect(routes, isNot(contains('/request/101/edit')));
    }
    final ready = parseRequestsList(portalListHtml).requests.single;
    expect(ready.canFill, isTrue);
    expect(ready.displayStatus, 'Перейти к заполнению');
    expect(ready.status, 'получение информации');
  });

  test('Creating a request does not follow the redirect to an unprepared form',
      () async {
    final routes = <String>[];
    DirectPortalClient.testFactory = () => fakePortal((o) {
          routes.add(o.uri.path);
          if (o.uri.path == '/login')
            return page(
                o.method == 'GET' ? portalLoginHtml : portalLoggedInHtml);
          if (o.uri.path == '/request/get-types')
            return page('{"result":"ok","items":[{"id":10,"text":"Справка"}]}');
          if (o.uri.path == '/request/create')
            return page('', status: 302, headers: {
              'location': ['http://portal.vspu.ru/request/101/edit']
            });
          if (o.uri.path == '/request/index') return page(portalListHtml);
          throw StateError('Premature edit request');
        });
    expect(await createRequest(categoryId: '4', typeId: '10'), '101');
    expect(routes.where((r) => r == '/request/create'), hasLength(1));
    expect(routes, isNot(contains('/request/101/edit')));
  });

  test('Income form includes fields, template and restricted upload metadata',
      () {
    final form = parseRequestForm(incomeFormHtml, '101');
    expect(form.hasUnsupportedFields, isFalse);
    expect(form.fields, hasLength(5));
    expect(form.fields[1].label, 'Дата с');
    expect(form.fields[1].required, isTrue);
    expect(form.templateUrl, 'https://portal.vspu.ru/request/101/template');
    expect(form.attachments.single.fieldId, '147');
    expect(form.attachments.single.inputName, 'attachment');
    expect(form.attachments.single.extensions, contains('pdf'));
    expect(form.attachments.single.required, isTrue);
    expect(
        parseRequestForm(
                incomeFormHtml.replaceAll(
                    '/request/101/upload', 'https://other.example/upload'),
                '101')
            .hasUnsupportedFields,
        isTrue);
    expect(
        parseRequestForm(
                incomeFormHtml.replaceAll(
                    '/request/101/upload', '/request/102/upload'),
                '101')
            .hasUnsupportedFields,
        isTrue);
  });

  test('Income dates, quantity and conditional postal address are validated',
      () {
    final form = parseRequestForm(incomeFormHtml, '101');
    String? validate(String name, Map<String, dynamic> values) =>
        validateRequestValue(
            form.fields.singleWhere((f) => f.name == name), form, values);
    expect(validate('field_144', {'field_144': '31.02.2026'}), isNotNull);
    expect(validate('field_144', {'field_144': '01.02.2026'}), isNull);
    expect(
        validate('field_145',
            {'field_144': '02.02.2026', 'field_145': '01.02.2026'}),
        isNotNull);
    expect(validate('field_146', {'field_143': '1'}), isNull);
    expect(validate('field_146', {'field_143': '2'}), isNotNull);
    expect(
        validate('field_146',
            {'field_143': '2', 'field_146': 'Волгоград, ул. Тестовая, 1'}),
        isNull);
    expect(validate('field_166', {'field_166': '0'}), isNotNull);
    expect(validate('field_166', {'field_166': '1.5'}), isNotNull);
    expect(validate('field_166', {'field_166': '2'}), isNull);
  });

  for (final uploadError in [false, true]) {
    test('Income upload precedes submit; upload error=$uploadError', () async {
      final calls = <RequestOptions>[];
      var sent = false;
      DirectPortalClient.testFactory = () => fakePortal((o) {
            if (o.uri.path == '/login')
              return page(
                  o.method == 'GET' ? portalLoginHtml : portalLoggedInHtml);
            calls.add(o);
            if (o.uri.path == '/request/index')
              return page(sent
                  ? portalListHtml.replaceAll(
                      'получение информации', 'На обработке')
                  : portalListHtml);
            if (o.uri.path == '/request/101/upload')
              return page(uploadError ? '{"error":"rejected"}' : '{}');
            if (o.method == 'POST') {
              sent = true;
              return page('');
            }
            return page(incomeFormHtml);
          });
      final result = await submitRequestForm(requestId: '101', values: {
        'field_144': '01.01.2026',
        'field_145': '31.01.2026',
        'field_166': '1'
      }, files: {
        '147': RequestFile(
            name: 'application.pdf', bytes: Uint8List.fromList([1, 2, 3]))
      });
      expect(result.success, !uploadError);
      expect(sent, !uploadError);
      final upload = calls.singleWhere((o) => o.uri.path.endsWith('/upload'));
      final data = upload.data as FormData;
      expect(Map.fromEntries(data.fields), containsPair('field_id', '147'));
      expect(
          Map.fromEntries(data.fields), containsPair('_csrf', 'upload-csrf'));
      expect(data.files.single.key, 'attachment');
      expect(data.files.single.value.filename, 'application.pdf');
      expect(data.files.single.value.length, 3);
      expect(upload.headers['X-CSRF-Token'], 'upload-csrf');
      expect(upload.uri.host, 'portal.vspu.ru');
      if (!uploadError)
        expect(
            calls.indexOf(upload),
            lessThan(calls.indexWhere(
                (o) => o.method == 'POST' && o.uri.path.endsWith('/edit'))));
    });
  }

  test('Income required attachment prevents final POST when missing', () async {
    var posts = 0;
    DirectPortalClient.testFactory = () => fakePortal((o) {
          if (o.uri.path == '/login')
            return page(
                o.method == 'GET' ? portalLoginHtml : portalLoggedInHtml);
          if (o.uri.path == '/request/index') return page(portalListHtml);
          if (o.method == 'POST') posts++;
          return page(incomeFormHtml);
        });
    final result = await submitRequestForm(
        requestId: '101',
        values: {'field_144': '01.01.2026', 'field_145': '31.01.2026'});
    expect(result.success, isFalse);
    expect(result.errors, isNotEmpty);
    expect(posts, 0);
  });
}
