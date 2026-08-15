import 'package:flutter/material.dart';

/// Design tokens from Final Design v1.1 (Rutgers Scarlet).
abstract final class CwcColors {
  static const primary = Color(0xFFCC0033);
  static const primaryTint = Color(0xFFFAE7EC);
  static const ink = Color(0xFF21262B);
  static const sub = Color(0xFF5F6A72);
  static const line = Color(0xFFE4E1DB);
  static const surface = Color(0xFFFCFBF9);
  static const card = Color(0xFFFFFFFF);
  static const neutralEmphasis = Color(0xFF0D0D0D);
}

ThemeData buildCwcTheme() {
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.light(
      primary: CwcColors.primary,
      onPrimary: Colors.white,
      secondary: CwcColors.sub,
      onSecondary: Colors.white,
      surface: CwcColors.surface,
      onSurface: CwcColors.ink,
      outline: CwcColors.line,
      error: CwcColors.neutralEmphasis,
    ),
    scaffoldBackgroundColor: CwcColors.surface,
  );

  return base.copyWith(
    appBarTheme: const AppBarTheme(
      backgroundColor: CwcColors.surface,
      foregroundColor: CwcColors.ink,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: CwcColors.ink,
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: CwcColors.card,
      indicatorColor: CwcColors.primaryTint,
      elevation: 0,
      height: 72,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return TextStyle(
          fontSize: 14,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          color: selected ? CwcColors.primary : CwcColors.sub,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(
          color: selected ? CwcColors.primary : CwcColors.sub,
          size: 24,
        );
      }),
    ),
    cardTheme: CardThemeData(
      color: CwcColors.card,
      elevation: 1,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: CwcColors.line),
      ),
    ),
    chipTheme: base.chipTheme.copyWith(
      backgroundColor: CwcColors.card,
      selectedColor: CwcColors.primaryTint,
      side: const BorderSide(color: CwcColors.line),
      labelStyle: const TextStyle(color: CwcColors.ink, fontSize: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: CwcColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(48, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: CwcColors.ink,
        minimumSize: const Size(48, 48),
        side: const BorderSide(color: CwcColors.line, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    textTheme: base.textTheme.copyWith(
      bodyLarge: base.textTheme.bodyLarge?.copyWith(
        fontSize: 18,
        height: 1.4,
        color: CwcColors.ink,
      ),
      bodyMedium: base.textTheme.bodyMedium?.copyWith(
        fontSize: 18,
        height: 1.4,
        color: CwcColors.ink,
      ),
      bodySmall: base.textTheme.bodySmall?.copyWith(
        fontSize: 18,
        height: 1.4,
        color: CwcColors.ink,
      ),
      titleMedium: base.textTheme.titleMedium?.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: CwcColors.ink,
      ),
    ),
  );
}
