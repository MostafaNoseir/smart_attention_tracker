import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Primary palette — deep navy + electric teal
  static const background = Color(0xFF0A0E1A);
  static const surface = Color(0xFF111827);
  static const surfaceElevated = Color(0xFF1A2235);
  static const surfaceBorder = Color(0xFF243047);

  static const primary = Color(0xFF00D4AA);       // Electric teal
  static const primaryDim = Color(0xFF00D4AA33);
  static const primaryGlow = Color(0xFF00D4AA66);

  static const accent = Color(0xFF6C63FF);         // Purple accent
  static const accentDim = Color(0xFF6C63FF22);

  static const warning = Color(0xFFFFB547);
  static const warningDim = Color(0xFFFFB54722);
  static const danger = Color(0xFFFF5C5C);
  static const dangerDim = Color(0xFFFF5C5C22);
  static const success = Color(0xFF2ECC71);
  static const successDim = Color(0xFF2ECC7122);

  // Text
  static const textPrimary = Color(0xFFF0F4FF);
  static const textSecondary = Color(0xFF8B95A8);
  static const textMuted = Color(0xFF4A5568);

  // Chart colors
  static const chartFocus = Color(0xFF00D4AA);
  static const chartDistract = Color(0xFFFF5C5C);
  static const chartDistractor = Color(0xFFFFB547);

  // Target shape colors for session
  static const List<Color> targetColors = [
    Color(0xFFFF6B6B),
    Color(0xFF4ECDC4),
    Color(0xFFFFE66D),
    Color(0xFF6C63FF),
    Color(0xFFFF8E53),
    Color(0xFF26D0CE),
    Color(0xFFFF61D2),
    Color(0xFF8BFF61),
  ];
}

class AppTheme {
  static ThemeData get theme {
    final base = ThemeData.dark();
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        background: AppColors.background,
        surface: AppColors.surface,
        primary: AppColors.primary,
        secondary: AppColors.accent,
        error: AppColors.danger,
      ),
      textTheme: GoogleFonts.spaceGroteskTextTheme(base.textTheme).copyWith(
        displayLarge: GoogleFonts.spaceGrotesk(
          fontSize: 48,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          letterSpacing: -1.5,
        ),
        displayMedium: GoogleFonts.spaceGrotesk(
          fontSize: 36,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          letterSpacing: -1,
        ),
        headlineLarge: GoogleFonts.spaceGrotesk(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        headlineMedium: GoogleFonts.spaceGrotesk(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        titleLarge: GoogleFonts.spaceGrotesk(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        titleMedium: GoogleFonts.spaceGrotesk(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 15,
          color: AppColors.textSecondary,
          height: 1.6,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 13,
          color: AppColors.textSecondary,
          height: 1.5,
        ),
        labelLarge: GoogleFonts.spaceGrotesk(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
          color: AppColors.textPrimary,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceElevated,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.surfaceBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.surfaceBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
        hintStyle: GoogleFonts.inter(
          color: AppColors.textMuted,
          fontSize: 14,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.background,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.spaceGrotesk(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
          elevation: 0,
        ),
      ),
      // cardTheme: CardTheme(
      //   color: AppColors.surface,
      //   shape: RoundedRectangleBorder(
      //     borderRadius: BorderRadius.circular(16),
      //     side: const BorderSide(color: AppColors.surfaceBorder, width: 0.8),
      //   ),
      //   elevation: 0,
      //   margin: EdgeInsets.zero,
      // ),
      cardTheme: CardThemeData(
  color: AppColors.surface,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(16),
    side: const BorderSide(color: AppColors.surfaceBorder, width: 0.8),
  ),
  elevation: 0,
  margin: EdgeInsets.zero,
),
      dividerTheme: const DividerThemeData(
        color: AppColors.surfaceBorder,
        thickness: 0.8,
      ),
    );
  }
}