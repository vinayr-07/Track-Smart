import 'package:flutter/material.dart';

class ThemeService {
  static final lightColorScheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF00897B),
    brightness: Brightness.light,
  ).copyWith(
    primary: const Color(0xFF00897B),
    onPrimary: Colors.white,
    primaryContainer: const Color(0xFFA9EFE7),
    onPrimaryContainer: const Color(0xFF00201D),
    secondary: const Color(0xFF4A635F),
    onSecondary: Colors.white,
    surface: const Color(0xFFF8FAF9),
    surfaceContainerHighest: const Color(0xFFDBE5E2),
    outline: const Color(0xFF6F7977),
    onSurface: const Color(0xFF191C1C),
    onSurfaceVariant: const Color(0xFF3F4947),
    error: const Color(0xFFBA1A1A),
    onError: Colors.white,
    errorContainer: const Color(0xFFFFDAD6),
    onErrorContainer: const Color(0xFF410002),
  );

  static final darkColorScheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF66DDAA),
    brightness: Brightness.dark,
  ).copyWith(
    primary: const Color(0xFF66DDAA),
    onPrimary: const Color(0xFF003732),
    primaryContainer: const Color(0xFF005048),
    onPrimaryContainer: const Color(0xFFA9EFE7),
    secondary: const Color(0xFFB1CCC6),
    onSecondary: const Color(0xFF1C3531),
    surface: const Color(0xFF222928),
    surfaceContainerHighest: const Color(0xFF3F4947),
    outline: const Color(0xFF899391),
    onSurface: const Color(0xFFE1E3E2),
    onSurfaceVariant: const Color(0xFFBFC9C6),
    error: const Color(0xFFFFB4AB),
    onError: const Color(0xFF690005),
    errorContainer: const Color(0xFF93000A),
    onErrorContainer: const Color(0xFFFFDAD6),
  );

  static ThemeData getTheme(String themePreference) {
    // FIXED: Get platform brightness properly
    final platformBrightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;

    final isDark = themePreference == 'Dark' ||
        (themePreference == 'System' && platformBrightness == Brightness.dark);

    return ThemeData(
      useMaterial3: true,
      colorScheme: isDark ? darkColorScheme : lightColorScheme,
    );
  }
}
