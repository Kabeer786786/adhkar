import 'package:flutter/material.dart';

/// Design tokens and Material 3 color system for Adhkar.
/// Uses a Warm Cream, Sunset Gold & Peach palette inspired by modern Islamic UI designs.
class AppColors {
  AppColors._();

  // Primary Palette - Rich Forest Green & Emerald
  static const Color primaryLight = Color(0xFF2A531D);
  static const Color primaryDark = Color(0xFF86EFAC);
  static const Color primaryContainerLight = Color(0xFFE7F6E3);
  static const Color primaryContainerDark = Color(0xFF1E3A15);

  // Secondary Palette - Emerald Green Accent
  static const Color secondaryLight = Color(0xFF16A34A);
  static const Color secondaryDark = Color(0xFF4ADE80);
  static const Color secondaryContainerLight = Color(0xFFDCFCE7);
  static const Color secondaryContainerDark = Color(0xFF14532D);

  // Tertiary Accent - Soft Forest Green
  static const Color tertiaryLight = Color(0xFF15803D);
  static const Color tertiaryDark = Color(0xFF86EFAC);

  // Background & Surfaces - Fresh Soft Green Tint (Light)
  static const Color backgroundLight = Color(0xFFFFFFFF);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceVariantLight = Color(0xFFE7F6E3);
  static const Color outlineLight = Color(0xFFC8E6C9);

  // Background & Surfaces - Deep Dark Mode
  static const Color backgroundDark = Color(0xFF0F1A0E);
  static const Color surfaceDark = Color(0xFF162514);
  static const Color surfaceVariantDark = Color(0xFF1F351B);
  static const Color outlineDark = Color(0xFF2E4D28);

  // Text Colors
  static const Color textPrimaryLight = Color(0xFF1A3512);
  static const Color textSecondaryLight = Color(0xFF4B6B42);
  static const Color textPrimaryDark = Color(0xFFF0FDF4);
  static const Color textSecondaryDark = Color(0xFFA7F3D0);

  // Status & Prayer Highlights
  static const Color fajrColor = Color(0xFF2A531D);
  static const Color dhuhrColor = Color(0xFF16A34A);
  static const Color asrColor = Color(0xFF15803D);
  static const Color maghribColor = Color(0xFFD97724);
  static const Color ishaColor = Color(0xFF1E5D2A);
  static const Color qiyamColor = Color(0xFF047857);

  // Functional colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
}

