import 'package:flutter/material.dart';
import 'calm_depth.dart';

const unioBlue = Color(0xFF0A5CFF);
const unioBlueDeep = Color(0xFF0B2AA8);
const unioViolet = Color(0xFF6B2FF5);
const brandBlue = unioBlue;
const unioGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [unioBlue, unioViolet],
);
const unioSuccess = Color(0xFF17B26A);
const unioWarning = Color(0xFFF5A524);
const unioError = Color(0xFFE5484D);

class UnioSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 20.0;
  static const xxl = 24.0;
  static const xxxl = 32.0;
}

class UnioRadius {
  static const chip = 14.0;
  static const control = 18.0;
  static const card = 26.0;
  static const container = 32.0;
}

// Onest is bundled with the app; typography works offline too.
const _fontFamily = 'Onest';

ThemeData buildTheme(Brightness brightness) =>
    CalmDepth.theme(_buildTheme(brightness));

// Gradebook keeps its existing presentation until its separate implementation.
ThemeData buildGradebookTheme(Brightness brightness) => _buildTheme(brightness);

// Onboarding keeps its own original palette when the application theme evolves.
ThemeData buildWelcomeTheme() => _buildTheme(Brightness.dark, welcome: true);

ThemeData _buildTheme(Brightness brightness, {bool welcome = false}) {
  final dark = brightness == Brightness.dark;
  final welcomeScheme = ColorScheme.fromSeed(
    seedColor: unioViolet,
    brightness: brightness,
  ).copyWith(
    primary: dark ? const Color(0xFFAD98FF) : const Color(0xFF6544C8),
    onPrimary: dark ? const Color(0xFF191329) : Colors.white,
    primaryContainer: dark ? const Color(0xFF342A53) : const Color(0xFFEAE3FF),
    onPrimaryContainer:
        dark ? const Color(0xFFEAE3FF) : const Color(0xFF38226D),
    secondary: dark ? const Color(0xFF8ACBFF) : const Color(0xFF256BA5),
    tertiary: unioSuccess,
    error: dark ? const Color(0xFFFF9296) : unioError,
    surface: dark ? const Color(0xFF191D30) : Colors.white,
    onSurface: dark ? const Color(0xFFF3F0FF) : const Color(0xFF222035),
    onSurfaceVariant: dark ? const Color(0xFFABAFC5) : const Color(0xFF67647A),
    surfaceContainerLow:
        dark ? const Color(0xFF151828) : const Color(0xFFF7F5FC),
    surfaceContainer: dark ? const Color(0xFF22263B) : const Color(0xFFF0EDF8),
    surfaceContainerHigh:
        dark ? const Color(0xFF2A2E44) : const Color(0xFFEAE5F5),
    outlineVariant: dark ? const Color(0xFF38394E) : const Color(0xFFE4DFEE),
  );
  final scheme = welcome
      ? welcomeScheme
      : ColorScheme.fromSeed(seedColor: unioBlue, brightness: brightness)
          .copyWith(
          primary: dark ? const Color(0xFF8CB8FF) : const Color(0xFF175CD3),
          onPrimary: dark ? const Color(0xFF082B60) : Colors.white,
          primaryContainer:
              dark ? const Color(0xFF203754) : const Color(0xFFEAF1FF),
          onPrimaryContainer:
              dark ? const Color(0xFFD5E5FF) : const Color(0xFF174A91),
          secondary: dark ? const Color(0xFF7DD3C3) : const Color(0xFF157A6E),
          onSecondary: dark ? const Color(0xFF073C34) : Colors.white,
          secondaryContainer:
              dark ? const Color(0xFF173D38) : const Color(0xFFE4F4EF),
          onSecondaryContainer:
              dark ? const Color(0xFFB9ECE0) : const Color(0xFF14594E),
          tertiary: dark ? const Color(0xFF92D7AE) : const Color(0xFF237A4B),
          error: dark ? const Color(0xFFFF9A9A) : const Color(0xFFBC3038),
          surface: dark ? const Color(0xFF1A2029) : Colors.white,
          onSurface: dark ? const Color(0xFFF1F4F8) : const Color(0xFF182230),
          onSurfaceVariant:
              dark ? const Color(0xFFADB8C7) : const Color(0xFF596579),
          surfaceContainerLowest: dark ? const Color(0xFF10151C) : Colors.white,
          surfaceContainerLow:
              dark ? const Color(0xFF171D25) : const Color(0xFFF8FAFC),
          surfaceContainer:
              dark ? const Color(0xFF222B36) : const Color(0xFFF0F3F7),
          surfaceContainerHigh:
              dark ? const Color(0xFF2B3542) : const Color(0xFFE7ECF2),
          surfaceContainerHighest:
              dark ? const Color(0xFF354150) : const Color(0xFFDDE4ED),
          outline: dark ? const Color(0xFF748195) : const Color(0xFF7A8799),
          outlineVariant:
              dark ? const Color(0xFF343F4E) : const Color(0xFFDDE4EC),
          surfaceTint: Colors.transparent,
        );
  final textTheme = _buildTextTheme(scheme.onSurface);
  final control = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(UnioRadius.control),
  );
  return ThemeData(
    useMaterial3: true,
    fontFamily: _fontFamily,
    colorScheme: scheme,
    textTheme: textTheme,
    scaffoldBackgroundColor: welcome
        ? const Color(0xFF0F1122)
        : dark
            ? const Color(0xFF11161D)
            : const Color(0xFFF4F6F9),
    appBarTheme: AppBarTheme(
      backgroundColor:
          welcome ? Colors.transparent : scheme.surfaceContainerLow,
      elevation: 0,
      scrolledUnderElevation: 0,
      foregroundColor: scheme.onSurface,
      titleTextStyle: textTheme.titleLarge,
    ),
    cardTheme: CardThemeData(
      color: scheme.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(welcome ? UnioRadius.card : 20),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: .65)),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      indicatorColor: scheme.primaryContainer,
      elevation: 0,
      height: 72,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return TextStyle(
          fontFamily: _fontFamily,
          fontSize: 12,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: selected ? scheme.primary : scheme.onSurfaceVariant,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? scheme.primary
                : scheme.onSurfaceVariant,
          )),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected) ? scheme.onPrimary : null),
      trackColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected) ? scheme.primary : null),
    ),
    filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
      shape: control,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    )),
    outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
            shape: control,
            foregroundColor: welcome ? null : scheme.onSurface,
            side: welcome ? null : BorderSide(color: scheme.outlineVariant),
            padding: welcome
                ? null
                : const EdgeInsets.symmetric(horizontal: 20, vertical: 14))),
    chipTheme: ChipThemeData(
      backgroundColor: scheme.surfaceContainer,
      selectedColor: scheme.primaryContainer,
      side: BorderSide.none,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(UnioRadius.chip)),
      labelStyle: textTheme.labelMedium,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    ),
    dividerTheme:
        DividerThemeData(color: scheme.outlineVariant.withValues(alpha: .5)),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surfaceContainer,
      hintStyle: TextStyle(color: scheme.onSurfaceVariant),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(UnioRadius.control),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(UnioRadius.control),
        borderSide: BorderSide(color: scheme.primary, width: 1.5),
      ),
    ),
  );
}

TextTheme _buildTextTheme(Color baseColor) {
  TextStyle style(double size, FontWeight weight, {double? height}) =>
      TextStyle(
        fontFamily: _fontFamily,
        fontSize: size,
        fontWeight: weight,
        height: height,
        color: baseColor,
        letterSpacing: size >= 24 ? -.6 : 0,
      );
  return TextTheme(
    headlineMedium: style(28, FontWeight.w800, height: 1.15),
    headlineSmall: style(24, FontWeight.w800, height: 1.18),
    titleLarge: style(20, FontWeight.w700, height: 1.25),
    titleMedium: style(17, FontWeight.w700, height: 1.3),
    titleSmall: style(15, FontWeight.w700, height: 1.3),
    bodyLarge: style(16, FontWeight.w500, height: 1.45),
    bodyMedium: style(15, FontWeight.w400, height: 1.4),
    bodySmall: style(13, FontWeight.w500, height: 1.35),
    labelLarge: style(16, FontWeight.w700, height: 1.2),
    labelMedium: style(13, FontWeight.w600, height: 1.2),
    labelSmall: style(12, FontWeight.w600, height: 1.2),
  );
}
