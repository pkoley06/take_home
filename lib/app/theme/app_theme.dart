import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static const Color defaultSeedColor = Colors.indigo;

  static ThemeData light(Color seedColor) {
    return _themeFrom(seedColor, Brightness.light);
  }

  static ThemeData dark(Color seedColor) {
    return _themeFrom(seedColor, Brightness.dark);
  }

  static ThemeData _themeFrom(Color seedColor, Brightness brightness) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: brightness,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
      ),
      cardTheme: const CardThemeData(
        clipBehavior: Clip.antiAlias,
      ),
    );
  }
}
