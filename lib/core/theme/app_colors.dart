import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary
  static const Color primary = Color(0xFF1A1A2E);
  static const Color primaryLight = Color(0xFF2D2D44);
  static const Color primaryDark = Color(0xFF0F0F1A);

  // Accent
  static const Color accent = Color(0xFFF5A623);
  static const Color accentLight = Color(0xFFFFD580);

  // Background - Light
  static const Color background = Color(0xFFF8F9FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color cardBackground = Color(0xFFFFFFFF);

  // Background - Dark
  static const Color backgroundDark = Color(0xFF0F0F1A);
  static const Color surfaceDark = Color(0xFF1A1A2E);

  // Text - Light
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textLight = Color(0xFF9CA3AF);
  static const Color textWhite = Color(0xFFFFFFFF);

  // Text - Dark
  static const Color textPrimaryDark = Color(0xFFF3F4F6);
  static const Color textSecondaryDark = Color(0xFF9CA3AF);

  // UI Elements
  static const Color divider = Color(0xFFE5E7EB);
  static const Color dividerDark = Color(0xFF2D2D44);
  static const Color border = Color(0xFFE5E7EB);
  static const Color chipSelected = Color(0xFF1A1A2E);
  static const Color chipUnselected = Color(0xFFF3F4F6);
  static const Color chipUnselectedDark = Color(0xFF2D2D44);
  static const Color searchBarBg = Color(0xFFF3F4F6);
  static const Color searchBarBgDark = Color(0xFF2D2D44);
  static const Color verified = Color(0xFF3B82F6);
  static const Color star = Color(0xFFF5A623);

  // Status
  static const Color online = Color(0xFF22C55E);
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color favorite = Color(0xFFEF4444);

  // Chat
  static const Color sentBubble = Color(0xFF1A1A2E);
  static const Color sentBubbleDark = Color(
    0xFFF5A623,
  ); // Golden for dark mode accent
  static const Color receivedBubble = Color(0xFFF3F4F6);
  static const Color receivedBubbleDark = Color(0xFF2D2D44);

  // Notification
  static const Color notifNew = Color(0xFF3B82F6);
  static const Color notifPrice = Color(0xFF10B981);
  static const Color notifMessage = Color(0xFFF5A623);

  // Gradient
  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Colors.transparent, Color(0xCC000000)],
  );

  static const LinearGradient welcomeGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Colors.transparent, Color(0x80000000), Color(0xCC000000)],
  );

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1A1A2E), Color(0xFF2D2D44)],
  );

  static const LinearGradient primaryGradientDark = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF5A623), Color(0xFFD48A1B)],
  );

  // Glass shadow
  static const Color glassShadow = Color(0x0A000000);
  static const Color glassShadowDark = Color(0x20000000);
}
