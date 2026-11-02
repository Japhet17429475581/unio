import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

enum AnalyticsEvent {
  screenView,
  onboardingStarted,
  onboardingFinished,
  roleSelected,
  loginAttempt,
  loginResult,
  logout,
  weekChanged,
  noteSaved,
  requestCreate,
  requestSubmit,
  templateSaved,
  guideOpened,
  guideCompleted,
  newsStoryOpened,
  newsFullOpened,
  teacherSelected,
  roomsSearch,
  settingChanged,
  notificationOpened,
}

enum AnalyticsScreen {
  schedule,
  gradebook,
  university,
  settings,
  news,
  newsArticle,
  requests,
  requestForm,
  lessonNotes,
  teacherSearch,
  teacherSchedule,
  freeRooms,
}

enum AnalyticsRole { student, teacher }

enum AnalyticsMethod { guest, portal }

enum AnalyticsOutcome { attempt, success, failed, unconfirmed, rejected }

enum AnalyticsAction { completed, skipped, next, previous, enabled, disabled }

enum AnalyticsSetting { darkTheme, push }

String _wireName(Enum value) => value.name.replaceAllMapped(
    RegExp('[A-Z]'), (match) => '_${match[0]!.toLowerCase()}');

final analytics = AnalyticsService();

/// No arbitrary strings: credentials, note text and portal data cannot be params.
/// The native SDK owns offline buffering and session tracking.
class AnalyticsService {
  final MethodChannel _channel;
  final bool _enabled;
  Future<bool>? _initialization;
  bool _consent = false;
  int _generation = 0;
  bool get consentGranted => _consent;

  AnalyticsService({MethodChannel? channel, bool? enabled})
      : _channel = channel ?? const MethodChannel('unio/analytics'),
        _enabled = enabled ??
            (!kIsWeb &&
                defaultTargetPlatform == TargetPlatform.android &&
                (kReleaseMode ||
                    const bool.fromEnvironment('MYTRACKER_DEBUG')) &&
                const bool.fromEnvironment('MYTRACKER_ENABLED',
                    defaultValue: true));

  Future<bool> initialize() =>
      !_consent ? Future.value(false) : _initialization ??= _initialize();

  Future<void> setConsent(bool accepted, {String? version}) async {
    final generation = ++_generation;
    _consent = false;
    _initialization = null;
    if (!_enabled &&
        (kIsWeb || defaultTargetPlatform != TargetPlatform.android)) return;
    try {
      final ready = await _channel.invokeMethod<bool>('setConsent', {
        'accepted': accepted && _enabled,
        'version': version,
      }).timeout(const Duration(seconds: 5));
      _consent = generation == _generation && accepted && ready == true;
    } on MissingPluginException {
      // No SDK on unsupported platforms.
    } catch (_) {
      // A failed revoke is surfaced, never presented as successful.
      if (!accepted) rethrow;
    }
  }

  Future<bool> _initialize() async {
    if (!_enabled) return false;
    try {
      return await _channel
              .invokeMethod<bool>('initialize')
              .timeout(const Duration(seconds: 2)) ??
          false;
    } catch (_) {
      return false;
    }
  }

  Future<void> track(
    AnalyticsEvent event, {
    AnalyticsScreen? screen,
    AnalyticsRole? role,
    AnalyticsMethod? method,
    AnalyticsOutcome? outcome,
    AnalyticsAction? action,
    AnalyticsSetting? setting,
    bool? hasPhotos,
  }) async {
    final generation = _generation;
    if (!await initialize() || !_consent || generation != _generation) return;
    final params = <String, String>{
      if (screen != null) 'screen': _wireName(screen),
      if (role != null) 'role': _wireName(role),
      if (method != null) 'method': _wireName(method),
      if (outcome != null) 'outcome': _wireName(outcome),
      if (action != null) 'action': _wireName(action),
      if (setting != null) 'setting': _wireName(setting),
      if (hasPhotos != null) 'has_photos': '$hasPhotos',
    };
    try {
      await _channel.invokeMethod<void>('trackEvent', {
        'name': _wireName(event),
        'params': params,
      }).timeout(const Duration(seconds: 2));
    } catch (_) {
      // Best effort: never replace the result of the user's actual action.
    }
  }

  void screen(AnalyticsScreen screen, {AnalyticsRole? role}) {
    unawaited(track(AnalyticsEvent.screenView, screen: screen, role: role));
  }
}
