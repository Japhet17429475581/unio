import '../utils/service_messages.dart';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/notification_plan.dart';
import '../utils/date_utils.dart';

class NotificationsApiException implements Exception {
  final String message;

  NotificationsApiException(this.message);

  @override
  String toString() => message;
}

/// GET /api/v1/notifications/plan?group=...&date=YYYY-MM-DD
Future<List<NotificationItem>> fetchNotificationPlan({
  required String group,
  required DateTime date,
}) async {
  final uri = Uri.https(apiHost, '/api/v1/notifications/plan', {
    'group': group,
    'date': isoDate(date),
    // Фильтруем прошедшие события на устройстве в часовом поясе вуза.
    'include_past': 'true',
  });

  final http.Response response;
  try {
    response = await http.get(uri).timeout(const Duration(seconds: 30));
  } catch (_) {
    throw NotificationsApiException(connectionMessage);
  }

  if (response.statusCode != 200) {
    throw NotificationsApiException(responseMessage(response.statusCode));
  }

  final data =
      jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
  return (data['notifications'] as List? ?? [])
      .map((e) => NotificationItem.fromJson(e as Map<String, dynamic>))
      .toList();
}
