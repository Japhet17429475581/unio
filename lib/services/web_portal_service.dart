import 'locale_service.dart';
import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'legal_service.dart';
import 'web_portal_transport.dart';

class WebPortalException implements Exception {
  final String message;
  final String? code;
  const WebPortalException(this.message, {this.code});
  @override
  String toString() => message;
}

class WebPortalService {
  final Dio transport;
  Future<void>? _refreshing;
  final String? baseUrl;
  final authChanges = ValueNotifier<int>(0);
  WebPortalService({Dio? transport, this.baseUrl})
      : transport = transport ?? webPortalTransport();
  String get _base => baseUrl ?? '${Uri.base.origin}/api/v1/web-portal';

  Options get _options => Options(
      headers: {'X-Unio-Web': '1'},
      validateStatus: (status) => status != null && status < 600,
      sendTimeout: const Duration(seconds: 35),
      receiveTimeout: const Duration(seconds: 60));

  String? _code(Response response) {
    final data = response.data;
    return data is Map && data['detail'] is Map
        ? data['detail']['code'] as String?
        : null;
  }

  Never _error(Response response) {
    final code = _code(response);
    throw WebPortalException(
        switch (code) {
          'portal_login_rejected' => l10n.portalCheckCredentials,
          'portal_reauthentication_required' =>
            l10n.portalReauthenticate,
          'web_auth_required' ||
          'refresh_reused' =>
            l10n.webSignInEnded,
          'web_portal_not_configured' ||
          'web_origin_denied' =>
            l10n.webConfigMissing,
          'payload_too_large' ||
          'attachment_too_large' =>
            l10n.attachmentLimit,
          'unknown_group' => l10n.chooseSuggestedGroup,
          _ => response.statusCode == 429
              ? l10n.tooManyRequests
              : l10n.portalConnectionFailed,
        },
        code: code);
  }

  Future<Map<String, dynamic>> login(
      {required String login,
      required String password,
      String? group,
      String? teacherFio,
      String? accountToken}) async {
    try {
      final response = await transport.post('$_base/login',
          data: {
            'login': login,
            'password': password,
            if (group != null) 'group': group,
            if (teacherFio != null) 'teacher_fio': teacherFio,
            if (accountToken != null) 'account_token': accountToken,
            'consents': await legal.currentReceipts(),
          },
          options: _options);
      if (response.statusCode != 200) _error(response);
      return Map<String, dynamic>.from(response.data as Map);
    } on DioException {
      throw WebPortalException(
          l10n.checkInternet);
    }
  }

  Future<void> _refresh() => _refreshing ??= (() async {
        try {
          for (var attempt = 0; attempt < 3; attempt++) {
            final response =
                await transport.post('$_base/refresh', options: _options);
            if (response.statusCode == 200) return;
            if (_code(response) != 'refresh_race') _error(response);
            await Future<void>.delayed(const Duration(milliseconds: 150));
          }
          throw WebPortalException(
              l10n.refreshSignInFailed);
        } finally {
          _refreshing = null;
        }
      })();

  Future<Response<String>> request(Uri uri,
      {Map<String, String>? fields,
      FormData? multipart,
      bool ajax = false,
      bool follow = true,
      Uri? referer,
      String? csrf}) async {
    final payload = {
      'path': uri.toString(),
      'ajax': ajax,
      'follow': follow,
      'fields': multipart == null ? fields : Map.fromEntries(multipart.fields),
      'referer': referer?.toString(),
      'csrf': csrf,
    };
    Object body() {
      if (multipart == null) return payload;
      final data = FormData();
      data.fields.add(MapEntry('payload', jsonEncode(payload)));
      data.files.addAll(multipart.files
          .map((entry) => MapEntry(entry.key, entry.value.clone())));
      return data;
    }

    try {
      var response = await transport.post('$_base/request',
          data: body(), options: _options);
      if (response.statusCode == 401 &&
          {'web_auth_required', 'web_access_expired'}
              .contains(_code(response))) {
        await _refresh();
        // The bridge rejected authorization before executing the portal action.
        response = await transport.post('$_base/request',
            data: body(), options: _options);
      }
      if (response.statusCode != 200) _error(response);
      final result = response.data as Map;
      return Response<String>(
          data: result['data'] as String,
          statusCode: result['status'] as int,
          requestOptions: RequestOptions(path: result['url'] as String),
          headers: Headers.fromMap({
            'content-type': [result['content_type'] as String? ?? ''],
            if (result['location'] != null)
              'location': [result['location'] as String],
          }));
    } on DioException {
      throw WebPortalException(
          l10n.checkInternet);
    }
  }

  Future<void> logout() async {
    final cancellation = CancelToken();
    final deadline =
        Timer(const Duration(seconds: 3), () => cancellation.cancel());
    try {
      final response = await transport.post('$_base/logout',
          options: _options, cancelToken: cancellation);
      if (response.statusCode != 200) _error(response);
    } finally {
      deadline.cancel();
    }
  }
}

final webPortal = WebPortalService();
