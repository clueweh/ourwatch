import 'package:flutter/material.dart';

class AppColors {
  static final ValueNotifier<bool> isDarkMode = ValueNotifier<bool>(true);

  static bool get _isDark => isDarkMode.value;

  static Color get background => _isDark
    ? const Color(0xFF0D0E11)
    : const Color(0xFFF4F5F7);
  static Color get cardBg =>
    _isDark ? const Color(0xFF16181D) : const Color(0xFFFFFFFF);
  static Color get inputBg =>
    _isDark ? const Color(0xFF1C1E24) : const Color(0xFFFFFFFF);
  static const Color primaryRed = Color(0xFFE53935);
  static Color get borderDark =>
    _isDark ? const Color(0xFF2A2D36) : const Color(0xFFD9DDE5);
  static Color get textPrimary =>
    _isDark ? Colors.white : const Color(0xFF1A1D24);
  static Color get textSecondary =>
    _isDark ? const Color(0xFF8E95A5) : const Color(0xFF626B78);
  static const Color activeBadge = Color(0xFFE53935);
}