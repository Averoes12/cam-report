import 'package:camreport/theme/global_colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class GlobalTheme {
  static ThemeData lightThemeData = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: GlobalColors.neutral,
    colorScheme: const ColorScheme.light(
      primary: GlobalColors.primary,
      secondary: GlobalColors.secondary,
      tertiary: GlobalColors.tertiary,
      surface: GlobalColors.surface,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: GlobalColors.textPrimary,
      error: GlobalColors.danger,
    ),
    textTheme: _textTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: GlobalColors.surface,
      foregroundColor: GlobalColors.textPrimary,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: GoogleFonts.plusJakartaSans(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: GlobalColors.textPrimary,
      ),
    ),
    cardTheme: CardThemeData(
      margin: EdgeInsets.zero,
      color: GlobalColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      elevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: GlobalColors.surface,
      hintStyle: GoogleFonts.inter(
        color: GlobalColors.textSecondary,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      labelStyle: GoogleFonts.inter(
        color: GlobalColors.textSecondary,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(22),
        borderSide: const BorderSide(color: GlobalColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(22),
        borderSide: const BorderSide(color: GlobalColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(22),
        borderSide: const BorderSide(color: GlobalColors.primary, width: 1.4),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: GlobalColors.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: GlobalColors.primary,
        side: const BorderSide(color: GlobalColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
      ),
    ),
    dividerColor: GlobalColors.border,
  );

  static final TextTheme _textTheme = TextTheme(
    headlineLarge: GoogleFonts.plusJakartaSans(
      fontSize: 30,
      fontWeight: FontWeight.w700,
      color: GlobalColors.textPrimary,
    ),
    headlineMedium: GoogleFonts.plusJakartaSans(
      fontSize: 22,
      fontWeight: FontWeight.w700,
      color: GlobalColors.textPrimary,
    ),
    titleLarge: GoogleFonts.plusJakartaSans(
      fontSize: 18,
      fontWeight: FontWeight.w700,
      color: GlobalColors.textPrimary,
    ),
    titleMedium: GoogleFonts.plusJakartaSans(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: GlobalColors.textPrimary,
    ),
    bodyLarge: GoogleFonts.inter(
      fontSize: 15,
      fontWeight: FontWeight.w500,
      color: GlobalColors.textPrimary,
    ),
    bodyMedium: GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: GlobalColors.textPrimary,
    ),
    bodySmall: GoogleFonts.inter(
      fontSize: 13,
      fontWeight: FontWeight.w500,
      color: GlobalColors.textSecondary,
    ),
    labelLarge: GoogleFonts.inter(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: GlobalColors.textPrimary,
    ),
    labelMedium: GoogleFonts.inter(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: GlobalColors.textSecondary,
    ),
  );
}
