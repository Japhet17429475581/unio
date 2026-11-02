import '../services/locale_service.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/direct_portal_client.dart';
import '../services/web_portal_service.dart';
import '../services/news_service.dart';
import '../services/push_service.dart';

import 'service_messages.dart';
export 'service_messages.dart';

/// Never display an arbitrary exception or server response as interface text.
String userMessage(Object? error, {String? fallback}) {
  fallback ??= retryMessage;
  // These codes come from our parser, not from upstream bodies or exceptions.
  if (error is DirectPortalException) {
    if (error.code == 'requests_access_challenge') {
      return l10n.uiThePortalHasRestrictedAccessTryAnotherNetwork;
    }
    if (error.code == 'requests_empty_response') {
      return l10n.uiCouldNotLoadTheListTryRefreshingIt;
    }
    if (error.code == 'requests_unrecognized_page') {
      return l10n.uiOpenYourVgspuPortalAccountAnActionMay;
    }
  }
  final message = switch (error) {
    ApiException e => e.message,
    AuthApiException e => e.message,
    DirectPortalException e => e.message,
    WebPortalException e => e.message,
    NewsApiException e => e.message,
    PushApiException e => e.message,
    _ => null,
  };
  return message == null
      ? fallback
      : readableMessage(message, fallback: fallback);
}

String readableMessage(String message, {String? fallback}) {
  fallback ??= retryMessage;
  final lower = message.toLowerCase();
  final status =
      RegExp(r'(?:http\s*|ошибка сервера\s*\()(\d{3})', caseSensitive: false)
          .firstMatch(message);
  if (status != null) return responseMessage(int.parse(status[1]!));
  if (lower.contains('сессия') || lower.contains('войдите заново')) {
    return l10n.uiSignInAgainAndRetryThisAction;
  }
  if (lower.contains('другой сайт') || lower.contains('небезопасн')) {
    return l10n.uiCouldNotOpenThePageSecurelyPleaseTry;
  }
  if (lower.contains('подключиться к серверу') ||
      lower.contains('socketexception') ||
      lower.contains('failed host lookup') ||
      lower.contains('timeout')) return connectionMessage;
  if (RegExp(
          r'б[эе]к[эе]?нд|backend|http|account_token|traceback|exception|формат ответа|вернул|возврат|сервер|csrf|json|stack trace',
          caseSensitive: false)
      .hasMatch(message)) {
    return unavailableMessage;
  }
  return message.trim().isEmpty ? fallback : message;
}
