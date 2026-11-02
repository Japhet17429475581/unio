import 'legal_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'request_status_service.dart';
import 'secure_storage_service.dart';

const backgroundNotificationsTask = 'ru.unio.portal-status';
bool _initialized = false;

bool get _supported =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS);

@pragma('vm:entry-point')
void notificationTaskDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    WidgetsFlutterBinding.ensureInitialized();
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    if (prefs.getBool('push_enabled') != true || !await legal.coreAccepted())
      return true;
    try {
      await checkRequestStatuses();
      return true;
    } catch (_) {
      // A locked keychain, expired login or offline portal is retried later.
      // Never log credentials or personal response bodies.
      return false;
    }
  });
}

Future<void> startBackgroundNotifications() async {
  if (!_supported || !await legal.coreAccepted()) return;
  if ((await loadSession())?.isPortalModeValid != true) return;
  if (!_initialized) {
    await Workmanager().initialize(notificationTaskDispatcher);
    _initialized = true;
  }
  await Workmanager().registerPeriodicTask(
      backgroundNotificationsTask, backgroundNotificationsTask,
      frequency: const Duration(minutes: 30),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
      constraints: Constraints(networkType: NetworkType.connected));
}

Future<void> stopBackgroundNotifications() async {
  if (_supported)
    await Workmanager().cancelByUniqueName(backgroundNotificationsTask);
}

Future<void> refreshRequestNotifications() async {
  if (kIsWeb) return; // Opt-in web statuses are polled by the Web Push backend.
  final prefs = await SharedPreferences.getInstance();
  await prefs.reload();
  if (prefs.getBool('push_enabled') != true || !await legal.coreAccepted())
    return;
  try {
    await startBackgroundNotifications();
    await checkRequestStatuses();
  } catch (_) {
    debugPrint('[NOTIFICATIONS] portal status check deferred');
  }
}
