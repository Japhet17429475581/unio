import 'locale_service.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart' as html;

import 'secure_storage_service.dart';
import 'web_portal_service.dart';

final _activePortalClients = <DirectPortalClient>{};

Future<void> closeActivePortalClients() async {
  for (final client in _activePortalClients.toList()) {
    client.close();
  }
  _activePortalClients.clear();
}

class DirectPortalException implements Exception {
  final String message;
  final String? code;
  final int? statusCode;
  const DirectPortalException(this.message, {this.code, this.statusCode});
  @override
  String toString() => message;
}

String portalText(String? text) =>
    (text ?? '').replaceAll(RegExp(r'\s+'), ' ').trim();

Element? portalAncestor(Element? element, bool Function(Element) matches) {
  for (var parent = element?.parent; parent != null; parent = parent.parent) {
    if (matches(parent)) return parent;
  }
  return null;
}

/// Cookies live only in RAM. Credentials and personal responses are sent only
/// to this HTTPS origin; redirects are checked before following them.
class DirectPortalClient {
  @visibleForTesting
  static DirectPortalClient Function()? testFactory;
  static final origin = Uri.parse('https://portal.vspu.ru');
  final Dio dio;
  final bool diagnosticsEnabled;
  Uri? _documentUri;
  String? _csrfToken;
  DirectPortalClient({Dio? transport, this.diagnosticsEnabled = true})
      : dio = transport ?? Dio() {
    dio.options = BaseOptions(
      responseType: ResponseType.plain,
      followRedirects: false,
      validateStatus: (code) => code != null && code < 400,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
      sendTimeout: const Duration(seconds: 20),
      headers: {
        'Accept-Language': 'ru-RU,ru;q=0.9',
        // Match the existing portal integration's browser-compatible client.
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) '
            'AppleWebKit/537.36 (KHTML, like Gecko) Chrome/140.0 Safari/537.36',
      },
    );
    if (!kIsWeb) dio.interceptors.add(CookieManager(CookieJar()));
  }

  static Uri checkedUri(String path) {
    var uri = origin.resolve(path);
    // The portal's reverse proxy emits absolute HTTP redirects even for
    // HTTPS requests. Upgrade only its exact host and standard HTTP port;
    // credentials and cookies must never be sent over an HTTP connection.
    if (uri.scheme == 'http' &&
        uri.host == origin.host &&
        uri.port == 80 &&
        uri.userInfo.isEmpty) {
      uri = uri.replace(scheme: 'https', port: 443);
    }
    if (uri.scheme != 'https' ||
        uri.host != origin.host ||
        uri.port != 443 ||
        uri.userInfo.isNotEmpty) {
      throw DirectPortalException(
          l10n.portalOtherSite);
    }
    return uri;
  }

  Future<Response<String>> request(String path,
      {Map<String, String>? fields,
      FormData? multipart,
      bool ajax = false,
      bool followRedirects = true}) async {
    assert(fields == null || multipart == null);
    if (kIsWeb) {
      try {
        final response = await webPortal.request(checkedUri(path),
            fields: fields,
            multipart: multipart,
            ajax: ajax,
            follow: followRedirects,
            referer: _documentUri,
            csrf: _csrfToken);
        if (!ajax &&
            (response.headers.value('content-type') ?? '')
                .contains('text/html')) {
          _documentUri = checkedUri(response.requestOptions.path);
          _csrfToken = html
              .parse(response.data)
              .querySelector('meta[name=csrf-token]')
              ?.attributes['content'];
        }
        return response;
      } on WebPortalException catch (error) {
        throw DirectPortalException(error.message, code: error.code);
      }
    }
    var uri = checkedUri(path);
    Object? data = multipart ?? fields;
    try {
      for (var redirects = 0; redirects < 6; redirects++) {
        final response = await dio.request<String>(uri.toString(),
            data: data,
            options: Options(
                method: data == null ? 'GET' : 'POST',
                contentType: data is FormData
                    ? Headers.multipartFormDataContentType
                    : Headers.formUrlEncodedContentType,
                headers: {
                  if (data != null) 'Origin': origin.toString(),
                  if (_documentUri != null) 'Referer': _documentUri.toString(),
                  if (ajax) 'X-Requested-With': 'XMLHttpRequest',
                  if (ajax && _csrfToken != null) 'X-CSRF-Token': _csrfToken,
                }));
        final code = response.statusCode!;
        if (![301, 302, 303, 307, 308].contains(code)) {
          if (!ajax &&
              (response.headers.value('content-type') ?? '')
                  .contains('text/html')) {
            _documentUri = uri;
            _csrfToken = html
                .parse(response.data)
                .querySelector('meta[name=csrf-token]')
                ?.attributes['content'];
          }
          return response;
        }
        final location = response.headers.value('location');
        if (location == null)
          throw DirectPortalException(l10n.portalNoRedirect);
        uri = checkedUri(uri.resolve(location).toString());
        if (!followRedirects) return response;
        if (code == 303 || code == 301 || code == 302) data = null;
        if (data is FormData) {
          throw DirectPortalException(
              l10n.portalUploadRedirect);
        }
      }
      throw DirectPortalException(
          l10n.portalTooManyRedirects);
    } on DioException catch (error) {
      // Never expose request headers, passwords or response bodies in logs/UI.
      final status = error.response?.statusCode;
      final route = error.requestOptions.uri.path;
      final step = route == '/login'
          ? l10n.operationSignIn
          : route == '/request/create'
              ? l10n.operationDraft
              : route == '/request/get-types'
                  ? l10n.operationTypes
                  : route == '/request/index'
                      ? l10n.operationRequests
                      : RegExp(r'^/request/\d+/edit$').hasMatch(route)
                          ? (error.requestOptions.method == 'POST'
                              ? l10n.operationSubmit
                              : l10n.operationForm)
                          : l10n.operationPortal;
      final body = '${error.response?.data ?? ''}'.toLowerCase();
      final csrfError = body.contains('csrf') ||
          body.contains('unable to verify your data submission');
      final reason = csrfError
          ? l10n.portalCsrfRejected
          : status == 401
              ? l10n.portalNeedsSignIn
              : status == 403
                  ? l10n.portalDenied
                  : status == null
                      ? l10n.portalNoResponse
                      : l10n.portalError;
      throw DirectPortalException(
          '$step: $reason${status == null ? '' : ' (HTTP $status)'}.',
          code: csrfError
              ? 'portal_csrf_rejected'
              : status == 401
                  ? 'portal_session_expired'
                  : status == null
                      ? 'portal_network_error'
                      : 'portal_http_error',
          statusCode: status);
    }
  }

  static Map<String, String> hiddenFields(Element? form) => {
        for (final input
            in form?.querySelectorAll('input[type=hidden][name]') ??
                <Element>[])
          input.attributes['name']!: input.attributes['value'] ?? '',
      };

  static Map<String, String> csrfFields(Document document) {
    final param =
        document.querySelector('meta[name=csrf-param]')?.attributes['content'];
    final token =
        document.querySelector('meta[name=csrf-token]')?.attributes['content'];
    return {
      if (param != null && token != null) param: token,
      for (final input in document.querySelectorAll('input[name="_csrf"]'))
        '_csrf': input.attributes['value'] ?? '',
    };
  }

  static bool hasSession(Document document) =>
      document.querySelectorAll('form[action], a[href]').any((element) {
        try {
          return checkedUri(element.attributes[
                      element.localName == 'form' ? 'action' : 'href']!)
                  .path ==
              '/auth/logout';
        } on DirectPortalException {
          return false;
        }
      });

  static void requireSession(Document document) {
    if (!hasSession(document) &&
        (document.querySelector('#login-form, input[type=password]') != null)) {
      throw DirectPortalException(
          l10n.portalSessionExpired,
          code: 'portal_session_expired');
    }
  }

  Future<void> login(String login, String password) async {
    final page = await request('/login');
    final document = html.parse(page.data);
    final form = document.querySelector('#login-form') ??
        portalAncestor(document.querySelector('input[type=password]'),
            (e) => e.localName == 'form');
    final action = form?.attributes['action'];
    final response = await request(
        action == null || action.isEmpty ? '/login' : action,
        fields: {
          ...hiddenFields(form),
          ...csrfFields(document),
          'LoginForm[username]': login,
          'LoginForm[password]': password,
          'RememberMe': '0',
        });
    final result = html.parse(response.data);
    if (!hasSession(result)) {
      throw DirectPortalException(
          l10n.portalSignInFailed);
    }
  }

  void close() => dio.close(force: true);
}

Future<T> withPortal<T>(Future<T> Function(DirectPortalClient client) action,
    {String? login, String? password, bool retryReadOnly = false}) async {
  if (login == null || password == null) {
    final session = await loadSession();
    if (session == null || !session.isPortalModeValid) {
      throw DirectPortalException(
          l10n.portalSignInRequired);
    }
    login = session.portalLogin!;
    password = session.portalPassword;
  }
  final client = DirectPortalClient.testFactory?.call() ?? DirectPortalClient();
  _activePortalClients.add(client);
  try {
    if (!kIsWeb) await client.login(login, password!);
    try {
      return await action(client);
    } on DirectPortalException catch (error) {
      // Only explicitly read-only callers may repeat after session expiry.
      // Creating drafts, uploading and submitting documents are never replayed.
      if (kIsWeb || !retryReadOnly || error.code != 'portal_session_expired')
        rethrow;
      await client.login(login, password!);
      return await action(client);
    }
  } finally {
    _activePortalClients.remove(client);
    client.close();
  }
}
