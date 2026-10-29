import 'package:flutter/material.dart';

class AppTheme {
  static const seed = Color(0xFF6C63FF);

  static final ThemeData dark = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorSchemeSeed: seed,
    scaffoldBackgroundColor: const Color(0xFF0E0F1A),
  );
}
