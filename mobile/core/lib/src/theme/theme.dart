import 'package:flutter/material.dart';

import 'gm_tokens.dart';

/// Material 3 theme built from the shared Gud Meal design tokens (packages/tokens/tokens.json).
ThemeData buildGudMealTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final scheme = ColorScheme(
    brightness: brightness,
    primary: dark ? GmDark.primary : GmLight.primary,
    onPrimary: dark ? GmDark.onPrimary : GmLight.onPrimary,
    primaryContainer: dark ? GmDark.primarySoft : GmLight.primarySoft,
    onPrimaryContainer: dark ? GmDark.primaryStrong : GmLight.primaryStrong,
    secondary: dark ? GmDark.secondary : GmLight.secondary,
    onSecondary: dark ? GmDark.onSecondary : GmLight.onSecondary,
    secondaryContainer: dark ? GmDark.secondarySoft : GmLight.secondarySoft,
    onSecondaryContainer: dark ? GmDark.secondary : GmLight.secondary,
    tertiary: dark ? GmDark.accent : GmLight.accent,
    onTertiary: dark ? GmDark.text : GmLight.text,
    error: dark ? GmDark.danger : GmLight.danger,
    onError: Colors.white,
    surface: dark ? GmDark.surface : GmLight.surface,
    onSurface: dark ? GmDark.text : GmLight.text,
    onSurfaceVariant: dark ? GmDark.muted : GmLight.muted,
    surfaceContainerHighest: dark ? GmDark.surfaceMuted : GmLight.surfaceMuted,
    outline: dark ? GmDark.border : GmLight.border,
    outlineVariant: dark ? GmDark.border : GmLight.border,
  );
  final background = dark ? GmDark.background : GmLight.background;
  final base = ThemeData(useMaterial3: true, colorScheme: scheme, scaffoldBackgroundColor: background);
  final text = base.textTheme.apply(bodyColor: scheme.onSurface, displayColor: scheme.onSurface);
  return base.copyWith(
    textTheme: text.copyWith(
      headlineLarge: text.headlineLarge?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.5),
      headlineMedium: text.headlineMedium?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.3),
      titleLarge: text.titleLarge?.copyWith(fontWeight: FontWeight.w700),
    ),
    appBarTheme: AppBarTheme(backgroundColor: background, foregroundColor: scheme.onSurface, elevation: 0, centerTitle: false),
    cardTheme: CardThemeData(
      color: scheme.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(GmRadius.lg),
        side: BorderSide(color: scheme.outline),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(64, 48),
        shape: const StadiumBorder(),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(minimumSize: const Size(64, 48), shape: const StadiumBorder()),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surface,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(GmRadius.md), borderSide: BorderSide(color: scheme.outline)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(GmRadius.md), borderSide: BorderSide(color: scheme.outline)),
    ),
    chipTheme: base.chipTheme.copyWith(shape: const StadiumBorder()),
  );
}
