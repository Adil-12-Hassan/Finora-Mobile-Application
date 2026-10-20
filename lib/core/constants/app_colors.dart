import 'package:flutter/material.dart';

class AppColors {
  // Primary
  static const Color primary = Color(0xFF7C6EF5); // Violet accent
  static const Color primaryDark = Color(0xFF6357D4); // Darker violet (pressed)
  static const Color primaryLight = Color(0xFF9D92F7); // Lighter violet

  // Background
  static const Color background = Color(0xFF0A0A0F); // Deep space black
  static const Color surface = Color(0xFF12121A); // Card background
  static const Color surfaceElevated = Color(0xFF1A1A26); // Elevated cards

  // Text
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0B0C3);
  static const Color textMuted = Color(0xFF6B6B80);

  // Status
  static const Color success = Color(0xFF4CAF82);
  static const Color error = Color(0xFFEF5350);
  static const Color warning = Color(0xFFFFB74D);

  // Border
  static const Color border = Color(0xFF2A2A3D);

  // Category Colors
  static const Map<String, Color> categoryColors = {
    'Food': Color(0xFFFF6B6B),
    'Transport': Color(0xFF4ECDC4),
    'Shopping': Color(0xFFFFE66D),
    'Bills': Color(0xFF7C6EF5),
    'Health': Color(0xFF4CAF82),
    'Entertainment': Color(0xFFFF8E53),
    'Other': Color(0xFFB0B0C3),
  };
}
