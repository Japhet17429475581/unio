import 'package:flutter/material.dart';

/// Shared design system for working screens; onboarding has its own theme.
abstract final class CalmDepth {
  static const gutter = 16.0;
  static const cardRadius = 22.0;
  static const controlRadius = 16.0;
  static const motion = Duration(milliseconds: 300);

  static ThemeData theme(ThemeData base) {
    final dark = base.brightness == Brightness.dark;
    final scheme = base.colorScheme.copyWith(
      primary: dark ? const Color(0xFFB5A0FF) : const Color(0xFF6841CE),
      onPrimary: dark ? const Color(0xFF20133E) : Colors.white,
      primaryContainer:
          dark ? const Color(0xFF363054) : const Color(0xFFEAE2FC),
      onPrimaryContainer:
          dark ? const Color(0xFFE4DAFF) : const Color(0xFF50209E),
      surface: dark ? const Color(0xFF202136) : Colors.white,
      onSurface: dark ? const Color(0xFFF3F0FF) : const Color(0xFF252139),
      onSurfaceVariant:
          dark ? const Color(0xFFB7B6CC) : const Color(0xFF656078),
      surfaceContainerLow:
          dark ? const Color(0xFF1B1D31) : const Color(0xFFF5F2FC),
      surfaceContainer:
          dark ? const Color(0xFF2B2D45) : const Color(0xFFEEEAF7),
      surfaceContainerHigh:
          dark ? const Color(0xFF33354F) : const Color(0xFFE8E3F3),
      surfaceContainerHighest:
          dark ? const Color(0xFF3C3E58) : const Color(0xFFE1DAEE),
      surfaceContainerLowest:
          dark ? const Color(0xFF111326) : const Color(0xFFF7F5FC),
      outlineVariant: dark ? const Color(0xFF3B3B56) : const Color(0xFFE3DEEE),
      surfaceTint: Colors.transparent,
    );
    return base.copyWith(
      colorScheme: scheme,
      scaffoldBackgroundColor:
          dark ? const Color(0xFF111326) : const Color(0xFFF7F5FC),
      textTheme: base.textTheme.apply(
        bodyColor: scheme.onSurface,
        displayColor: scheme.onSurface,
      ),
      appBarTheme: base.appBarTheme.copyWith(
        backgroundColor: scheme.surfaceContainerLowest,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle:
            base.textTheme.titleLarge?.copyWith(color: scheme.onSurface),
      ),
      cardTheme: CardThemeData(
          color: scheme.surface,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(cardRadius),
              side: BorderSide(color: scheme.outlineVariant))),
      navigationBarTheme: base.navigationBarTheme.copyWith(
        backgroundColor: scheme.surface,
        indicatorColor: scheme.primaryContainer,
        iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? scheme.primary
                : scheme.onSurfaceVariant)),
        labelTextStyle: WidgetStateProperty.resolveWith((states) =>
            base.textTheme.labelSmall!.copyWith(
                color: states.contains(WidgetState.selected)
                    ? scheme.primary
                    : scheme.onSurfaceVariant)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? scheme.onPrimary : null),
        trackColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? scheme.primary : null),
      ),
      dividerTheme:
          DividerThemeData(color: scheme.outlineVariant, thickness: 1),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: scheme.primaryContainer,
          foregroundColor: scheme.onPrimaryContainer,
          elevation: 1,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(cardRadius))),
      bottomSheetTheme: BottomSheetThemeData(
          backgroundColor: scheme.surface,
          surfaceTintColor: Colors.transparent,
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)))),
      chipTheme: base.chipTheme.copyWith(
          backgroundColor: scheme.surfaceContainer,
          selectedColor: scheme.primaryContainer,
          labelStyle:
              base.textTheme.labelMedium?.copyWith(color: scheme.onSurface),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4)),
      inputDecorationTheme: base.inputDecorationTheme.copyWith(
        fillColor: scheme.surfaceContainerLow,
        hintStyle: TextStyle(color: scheme.onSurfaceVariant),
        labelStyle: TextStyle(color: scheme.onSurfaceVariant),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(controlRadius),
            borderSide: BorderSide(color: scheme.outlineVariant)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(controlRadius),
            borderSide: BorderSide(color: scheme.outlineVariant)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(controlRadius),
            borderSide: BorderSide(color: scheme.primary, width: 1.5)),
      ),
      filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
              backgroundColor: scheme.primary,
              foregroundColor: scheme.onPrimary,
              minimumSize: const Size(48, 48),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(controlRadius)))),
      outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
              foregroundColor: scheme.onSurface,
              side: BorderSide(color: scheme.outlineVariant),
              minimumSize: const Size(48, 48),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(controlRadius)))),
      extensions: [...base.extensions.values, const UnioSignature()],
    );
  }
}

/// Signature is reserved for focal surfaces, including in the light theme.
@immutable
class UnioSignature extends ThemeExtension<UnioSignature> {
  final Color start;
  final Color end;
  final Color foreground;
  final Color secondary;
  final Color accent;

  const UnioSignature({
    this.start = const Color(0xFF44306D),
    this.end = const Color(0xFF182F57),
    this.foreground = const Color(0xFFF7F5FF),
    this.secondary = const Color(0xFFD1D6ED),
    this.accent = const Color(0xFFB8A1FF),
  });

  @override
  UnioSignature copyWith(
          {Color? start,
          Color? end,
          Color? foreground,
          Color? secondary,
          Color? accent}) =>
      UnioSignature(
        start: start ?? this.start,
        end: end ?? this.end,
        foreground: foreground ?? this.foreground,
        secondary: secondary ?? this.secondary,
        accent: accent ?? this.accent,
      );

  @override
  UnioSignature lerp(covariant UnioSignature? other, double t) {
    if (other == null) return this;
    return UnioSignature(
      start: Color.lerp(start, other.start, t)!,
      end: Color.lerp(end, other.end, t)!,
      foreground: Color.lerp(foreground, other.foreground, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
    );
  }
}
