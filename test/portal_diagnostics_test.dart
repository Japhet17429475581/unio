import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:unio_app/services/direct_portal_client.dart';
import 'package:unio_app/services/portal_diagnostics.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => FlutterSecureStorage.setMockInitialValues({
        'account_token': 'synthetic-token',
        'group_code': 'synthetic-group',
        'portal_login': 'synthetic-login',
        'portal_password': 'synthetic-password',
        'is_portal_mode': 'true',
      }));

  test(
      'Diagnostic sends only a bounded error code and version, deduplicating repeats',
      () async {
    var calls = 0;
    final service = PortalDiagnostics(client: MockClient((request) async {
      calls++;
      expect(request.url.path, '/api/v1/diagnostics/portal');
      expect(request.headers['X-Unio-Token'], 'synthetic-token');
      final data = jsonDecode(request.body) as Map;
      expect(data.keys.toSet(),
          {'operation', 'version', 'code', 'platform', 'status'});
      expect(data['code'], 'requests_unrecognized_page');
      expect(data['status'], 200);
      for (final value in [
        'synthetic-login',
        'synthetic-password',
        'synthetic-group',
        'synthetic-html',
        'synthetic-token'
      ]) {
        expect(request.body, isNot(contains(value)));
      }
      return http.Response('', 204);
    }));
    const error = DirectPortalException('synthetic-html',
        code: 'requests_unrecognized_page', statusCode: 200);
    await service.report(error);
    await service.report(error);
    await service.report(
        const DirectPortalException('synthetic-html', code: 'untrusted-code'));
    expect(calls, 1);
  });

  test('Unavailable backend does not replace the original user error',
      () async {
    final service = PortalDiagnostics(
        client:
            MockClient((_) async => throw Exception('synthetic-sensitive')));
    await service.report(const DirectPortalException('original',
        code: 'requests_empty_response'));
  });
}
