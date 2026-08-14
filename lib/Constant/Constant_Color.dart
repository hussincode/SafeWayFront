import 'package:flutter/material.dart';

class AppColors {
  AppColors._();
  static const Color bgGradientStart = Color(0xFFF1F5F4);
  static const Color bgGradientMid = Color(0xFFF8F3EE);
  static const Color bgGradientEnd = Color(0xFFF1F5F4);

  static const Color darkNavy = Color(0xFF141B24);
  static const Color accentGreen = Color(0xFF2E7D5B);
  static const Color badgeBg = Color(0xFFCFEEDD);
  static const Color badgeDot = Color(0xFF1E9E63);

  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textMuted = Color(0xFF9CA3AF);

  static const Color cardBg = Colors.white;
  static const Color inputBg = Color(0xFFF3F4F1);
  static const Color divider = Color(0xFFE5E7EB);
}

class AppGradients {
  AppGradients._();

  static const LinearGradient softBackground = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      AppColors.bgGradientStart,
      AppColors.bgGradientMid,
      AppColors.bgGradientEnd,
    ],
    stops: [0.0, 0.5, 1.0],
  );
}
