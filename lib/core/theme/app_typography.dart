import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Typography hierarchy following Material Design 3 guidelines.
/// Incorporates Google Fonts Outfit for UI text and Amiri for Arabic script.
class AppTypography {
  AppTypography._();

  static TextStyle arabicHeader({double fontSize = 28, Color? color}) {
    return GoogleFonts.amiri(
      fontSize: fontSize,
      fontWeight: FontWeight.bold,
      height: 1.8,
      color: color,
    );
  }

  static TextStyle arabicBody({double fontSize = 22, Color? color, double height = 2.0}) {
    return GoogleFonts.amiri(
      fontSize: fontSize,
      fontWeight: FontWeight.w500,
      height: height,
      color: color,
    );
  }

  static TextTheme textTheme(BuildContext context, {required bool isDark}) {
    final baseTextTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return GoogleFonts.outfitTextTheme(baseTextTheme).copyWith(
      displayLarge: GoogleFonts.outfit(
        fontSize: 36,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
        color: colorScheme.onSurface,
      ),
      displayMedium: GoogleFonts.outfit(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
      ),
      titleLarge: GoogleFonts.outfit(
        fontSize: 22,
        fontWeight: FontWeight.w500,
        letterSpacing: 0,
        color: colorScheme.onSurface,
      ),
      titleMedium: GoogleFonts.outfit(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.15,
        color: colorScheme.onSurface,
      ),
      bodyLarge: GoogleFonts.outfit(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.15,
        color: colorScheme.onSurface,
      ),
      bodyMedium: GoogleFonts.outfit(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.25,
        color: colorScheme.onSurfaceVariant,
      ),
      labelLarge: GoogleFonts.outfit(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        color: colorScheme.primary,
      ),
    );
  }
}
