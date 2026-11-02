import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unio_app/services/web_portal_service.dart';

class BridgeAdapter implements HttpClientAdapter {
  final Future<ResponseBody> Function(RequestOptions) handler;
  BridgeAdapter(this.handler);
  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? stream,
          Future<void>? cancelFuture) =>
      handler(options);
  @override
  void close({bool force = false}) {}
}

ResponseBody jsonBody(int status, Object value) =>
    ResponseBody.fromString(jsonEncode(value), status, headers: {
      'content-type': ['application/json']
    });

void main() {
  test('Expired access refreshes once before retrying a rejected action',
      () async {
    var requests = 0;
    var refreshes = 0;
    final dio = Dio()
      ..httpClientAdapter = BridgeAdapter((options) async {
        expect(options.headers['X-Unio-Web'], '1');
        if (options.path.endsWith('/refresh')) {
          refreshes++;
          return jsonBody(200, {'success': true});
        }
        requests++;
        if (requests == 1)
          return jsonBody(401, {
            'detail': {'code': 'web_access_expired'}
          });
        return jsonBody(200, {
          'status': 302,
          'data': '',
          'url': 'https://portal.vspu.ru/request/1/edit',
          'content_type': 'text/html',
          'location': '/request/index'
        });
      });
    final bridge = WebPortalService(
        transport: dio, baseUrl: 'https://unio.test/api/v1/web-portal');
    final response = await bridge.request(
        Uri.parse('https://portal.vspu.ru/request/1/edit'),
        fields: {'field': 'value'},
        follow: false);
    expect(response.statusCode, 302);
    expect(response.headers.value('location'), '/request/index');
    expect(requests, 2);
    expect(refreshes, 1);
  });

  test('University expiry and network failures never replay a submitted form',
      () async {
    for (final networkFailure in [false, true]) {
      var calls = 0;
      final dio = Dio()
        ..httpClientAdapter = BridgeAdapter((options) async {
          calls++;
          if (networkFailure)
            throw DioException(
                requestOptions: options, type: DioExceptionType.receiveTimeout);
          return jsonBody(401, {
            'detail': {'code': 'portal_reauthentication_required'}
          });
        });
      final bridge = WebPortalService(
          transport: dio, baseUrl: 'https://unio.test/api/v1/web-portal');
      await expectLater(
          bridge.request(Uri.parse('https://portal.vspu.ru/request/1/edit'),
              fields: {'field': 'value'}),
          throwsA(isA<WebPortalException>()));
      expect(calls, 1);
    }
  });
}
