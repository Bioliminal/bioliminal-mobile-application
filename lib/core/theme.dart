import 'package:flutter/material.dart';

class AuraLinkTheme {
  AuraLinkTheme._();

  static const Color _primary = Color(0xFF00695C);
  static const Color _secondary = Color(0xFFFF6B6B);

  static const Color confidenceHigh = Color(0xFF4CAF50);
  static const Color confidenceMedium = Color(0xFFFFC107);
  static const Color confidenceLow = Color(0xFFF44336);

  static const double highThreshold = 0.9;
  static const double mediumThreshold = 0.7;

  static Color confidenceColor(double visibility) {
    if (visibility >= highThreshold) return confidenceHigh;
    if (visibility >= mediumThreshold) return confidenceMedium;
    return confidenceLow;
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _primary,
        secondary: _secondary,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
        headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
        titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        bodyLarge: TextStyle(fontSize: 16),
        bodyMedium: TextStyle(fontSize: 14),
        labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
    );
  }
}
