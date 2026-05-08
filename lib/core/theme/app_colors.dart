import 'package:flutter/material.dart';

/// Black + Gold palette — matches the "Black Building Academy" brand.
class AppColors {
  AppColors._();

  // Brand
  static const Color gold = Color(0xFFD4A437);
  static const Color goldLight = Color(0xFFEAC56A);
  static const Color goldDark = Color(0xFFA37D1F);
  static const Color black = Color(0xFF0B0B0F);
  static const Color charcoal = Color(0xFF1A1A22);
  static const Color graphite = Color(0xFF2A2A35);

  // Surfaces (light theme)
  static const Color background = Color(0xFFF7F7F9);
  static const Color surface = Colors.white;
  static const Color surfaceAlt = Color(0xFFF0F0F4);
  static const Color divider = Color(0xFFE5E5EC);

  // Text
  static const Color textPrimary = Color(0xFF12121A);
  static const Color textSecondary = Color(0xFF5A5A6A);
  static const Color textMuted = Color(0xFF8C8C9A);
  static const Color textInverse = Colors.white;

  // Status
  static const Color success = Color(0xFF1FA971);
  static const Color warning = Color(0xFFE8A33D);
  static const Color danger = Color(0xFFE5484D);
  static const Color info = Color(0xFF3B82F6);

  // Attendance status (calendar)
  static const Color attendancePresent = success;
  static const Color attendanceLate = warning;
  static const Color attendanceAbsent = danger;
  static const Color attendanceLeave = Color(0xFF3B82F6);
  static const Color attendanceHoliday = Color(0xFF9CA3AF);

  // Gradients
  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[Color(0xFF1A1A22), Color(0xFF0B0B0F)],
  );

  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[Color(0xFFEAC56A), Color(0xFFD4A437)],
  );
}
