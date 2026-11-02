import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'app.dart';
import 'widgets/welcome_visuals.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
    systemNavigationBarColor: welcomeBackground,
    systemNavigationBarDividerColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.light,
    systemNavigationBarContrastEnforced: false,
  ));
  // Exceptions may embed HTTP bodies, widget text or authorization headers.
  FlutterError.onError = (_) => debugPrint('flutter_error');
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('uncaught_error');
    return true;
  };
  runApp(const App());
}
