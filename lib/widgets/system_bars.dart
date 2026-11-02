import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Applies to the whole Navigator, including routes without an app navigation bar.
class UnioSystemBars extends StatelessWidget {
  final Widget child;
  const UnioSystemBars({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: dark ? Brightness.light : Brightness.dark,
        statusBarBrightness: dark ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: theme.scaffoldBackgroundColor,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarIconBrightness:
            dark ? Brightness.light : Brightness.dark,
        // Android's three-button contrast scrim can otherwise stay light while
        // the app uses its own dark theme. Edge-to-edge uses the painted Scaffold.
        systemNavigationBarContrastEnforced: false,
      ),
      child: child,
    );
  }
}
