import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'secure_storage_service.dart';
import 'web_portal_transport.dart';
import 'web_push_bridge.dart';

final webPushNavigation = ValueNotifier<String?>(null);
String? _publicKey;
int _generation = 0;

Future<bool> prepareWebPush() async {
  if (!kIsWeb || !browserPushSupported()) return false;
  final client = webPortalTransport();
  try {
    final response = await client.get(
        '${Uri.base.origin}/api/v1/web-push/config',
        options: Options(headers: {'X-Unio-Web': '1'}));
    if (response.data['enabled'] != true) return false;
    _publicKey = response.data['public_key'] as String;
    return true;
  } catch (_) {
    return false;
  } finally {
    client.close();
  }
}

Future<void> enableWebPush(String owner, {bool teacher = false}) async {
  final generation = ++_generation;
  if (_publicKey == null) throw StateError('push_not_available');
  // Trigger permission synchronously from the switch's user gesture on iOS.
  final subscriptionFuture = browserPushSubscribe(_publicKey!);
  final client = webPortalTransport();
  try {
    final subscription = jsonDecode(await subscriptionFuture) as Map;
    if (generation != _generation) throw StateError('push_cancelled');
    final session = await loadSession();
    final token =
        session?.accountToken ?? (await loadTeacherSession())?.webAccountToken;
    if (token == null) throw StateError('login_required');
    if (generation != _generation) throw StateError('push_cancelled');
    await client.post('${Uri.base.origin}/api/v1/web-push/subscription',
        data: {
          'endpoint': subscription['endpoint'],
          ...Map<String, dynamic>.from(subscription['keys'] as Map),
          'kind': teacher ? 'teacher' : 'group',
          'owner': owner,
        },
        options: Options(headers: {'X-Unio-Web': '1', 'X-Unio-Token': token}));
    if (generation != _generation) {
      await client.delete('${Uri.base.origin}/api/v1/web-push/subscription',
          options:
              Options(headers: {'X-Unio-Web': '1', 'X-Unio-Token': token}));
      throw StateError('push_cancelled');
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('push_enabled', true);
    await prefs.setString('push_group', owner);
  } catch (_) {
    try {
      await browserPushUnsubscribe();
    } catch (_) {}
    rethrow;
  } finally {
    client.close();
  }
}

Future<void> refreshWebPush(String owner) async {
  final generation = _generation;
  final prefs = await SharedPreferences.getInstance();
  if (prefs.getBool('push_enabled') != true) return;
  final raw = await browserPushCurrent();
  if (raw.isEmpty) {
    await prefs.setBool('push_enabled', false);
    return;
  }
  final subscription = jsonDecode(raw) as Map;
  final token = (await loadSession())?.accountToken;
  if (token == null || generation != _generation) return;
  final client = webPortalTransport();
  try {
    await client.post('${Uri.base.origin}/api/v1/web-push/subscription',
        data: {
          'endpoint': subscription['endpoint'],
          ...Map<String, dynamic>.from(subscription['keys'] as Map),
          'kind': 'group',
          'owner': owner,
        },
        options: Options(headers: {'X-Unio-Web': '1', 'X-Unio-Token': token}));
    if (generation != _generation) {
      await client.delete('${Uri.base.origin}/api/v1/web-push/subscription',
          options:
              Options(headers: {'X-Unio-Web': '1', 'X-Unio-Token': token}));
      return;
    }
    await prefs.setString('push_group', owner);
  } finally {
    client.close();
  }
}

Future<void> disableWebPush() async {
  _generation++;
  try {
    await browserPushUnsubscribe();
  } finally {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('push_enabled', false);
    await prefs.remove('push_group');
  }
  final token = (await loadSession())?.accountToken ??
      (await loadTeacherSession())?.webAccountToken;
  if (token == null) return;
  final client = webPortalTransport();
  try {
    await client.delete('${Uri.base.origin}/api/v1/web-push/subscription',
        options: Options(headers: {'X-Unio-Web': '1', 'X-Unio-Token': token}));
  } catch (_) {
    /* unsubscribed endpoint no longer receives messages */
  } finally {
    client.close();
  }
}

void initializeWebPush() {
  if (!kIsWeb) return;
  browserPushListen((screen) => webPushNavigation.value = screen);
  final screen = Uri.base.queryParameters['screen'];
  if (screen == 'schedule' || screen == 'requests')
    webPushNavigation.value = screen;
}
