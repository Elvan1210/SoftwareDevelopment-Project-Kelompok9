import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// MyPSKD Design System v5.0 (Sleek Slate & Indigo)
/// ═══════════════════════════════════════════════════════════════════════════
class AppTheme {
  // ─── Semantic Brand Colors ────────────────────────────────────────────────
  static const Color primary     = Color(0xFF4F46E5); // Indigo 600
  static const Color primaryDark = Color(0xFF6366F1); // Indigo 500
  static const Color primaryContainer = Color(0xFFB7E5CD); // Dari HTML
  static const Color primaryFixedVariant = Color(0xFF244F3D); // Dari HTML
  static const Color secondary = Color(0xFF336763); // Dari HTML
  
  // ─── Semantic State Colors ────────────────────────────────────────────────
  static const Color success = Color(0xFF10B981); // Emerald 500
  static const Color warning = Color(0xFFF59E0B); // Amber 500
  static const Color error   = Color(0xFFEF4444); // Red 500
  static const Color info    = Color(0xFF3B82F6); // Blue 500

  // ─── Light Mode ─────────────────────────────────────────────────────────
  static const Color lightBg      = Color(0xFFF9FAFB); // Gray 50
  static const Color lightSurface = Color(0xFFFFFFFF); // White
  static const Color lightBorder  = Color(0xFFE5E7EB); // Gray 200
  static const Color textLight    = Color(0xFF111827); // Gray 900 (High Contrast)
  static const Color textMutedLt  = Color(0xFF4B5563); // Gray 600 (High Contrast)

  // ─── Dark Mode ──────────────────────────────────────────────────────────
  static const Color darkBg      = Color(0xFF0F172A); // Slate 900
  static const Color darkSurface = Color(0xFF1E293B); // Slate 800
  static const Color darkCard    = Color(0xFF1E293B); // Slate 800
  static const Color darkBorder  = Color(0xFF334155); // Slate 700
  static const Color textDark    = Color(0xFFF9FAFB); // Gray 50 (High Contrast)
  static const Color textMutedDk = Color(0xFF9CA3AF); // Gray 400 (High Contrast)

  // ─── Legacy aliases (For backward compat during migration) ──────────────
  static const Color indigoPrimary = primary;
  static const Color indigoLight   = primaryDark;
  static const Color indigoDark    = Color(0xFF3730A3);
  static const Color tealDeep      = success;
  static const Color tealLight     = Color(0xFF34D399);
  static const Color amber         = warning;
  static const Color emerald       = success;
  static const Color rose          = error;
  static const Color sky           = info;
  static const Color orangeVivid   = Color(0xFFF97316);

  static Color getAccent(BuildContext context) => Theme.of(context).brightness == Brightness.dark ? primaryDark : primary;

  // ─── Text Themes ────────────────────────────────────────────────────────
  static TextTheme _textTheme(Brightness b) {
    final isD = b == Brightness.dark;
    final text  = isD ? textDark    : textLight;
    final muted = isD ? textMutedDk : textMutedLt;

    return TextTheme(
      displayLarge: GoogleFonts.inter(
        fontSize: 28, fontWeight: FontWeight.w900,
        color: text, letterSpacing: -1.0,
      ),
      headlineLarge: GoogleFonts.inter(
        fontSize: 24, fontWeight: FontWeight.w800,
        color: text, letterSpacing: -0.8,
      ),
      headlineMedium: GoogleFonts.inter(
        fontSize: 16, fontWeight: FontWeight.w800,
        color: text, letterSpacing: -0.5,
      ),
      headlineSmall: GoogleFonts.inter(
        fontSize: 16, fontWeight: FontWeight.w700,
        color: text, letterSpacing: -0.5,
      ),
      titleLarge: GoogleFonts.inter(
        fontSize: 16, fontWeight: FontWeight.w700,
        color: text, letterSpacing: -0.3,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 15, fontWeight: FontWeight.w600,
        color: text,
      ),
      titleSmall: GoogleFonts.inter(
        fontSize: 14, fontWeight: FontWeight.w600,
        color: muted,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 14, color: text, height: 1.6,
        fontWeight: FontWeight.w500,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 13, color: muted, height: 1.5,
        fontWeight: FontWeight.w400,
      ),
      labelLarge: GoogleFonts.inter(
        fontSize: 12, fontWeight: FontWeight.w600,
        color: muted, letterSpacing: 0.3,
      ),
      labelMedium: GoogleFonts.inter(
        fontSize: 11, fontWeight: FontWeight.w600,
        color: muted, letterSpacing: 0.5,
      ),
    );
  }

  // ─── Light Theme ────────────────────────────────────────────────────────
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
      primaryColor: primary,
      scaffoldBackgroundColor: lightBg,
      colorScheme: const ColorScheme.light(
        primary: primary,
        secondary: info,
        tertiary: lightBg,
        surface: lightSurface,
        onSurface: textLight,
        onPrimary: Colors.white,
        primaryContainer: Color(0xFFE0E7FF), // Indigo 100
        secondaryContainer: lightSurface,
        error: error,
      ),
      textTheme: _textTheme(Brightness.light),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: textLight),
        titleTextStyle: GoogleFonts.inter(
          color: textLight, fontSize: 18,
          fontWeight: FontWeight.w700, letterSpacing: -0.3,
        ),
      ),
      cardTheme: CardThemeData(
        color: lightSurface,
        elevation: 0,
        shadowColor: Colors.black.withAlpha(10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: lightBorder, width: 1.0),
        ),
      ),
      dividerColor: lightBorder,
      dividerTheme: const DividerThemeData(
        color: lightBorder, thickness: 1,
      ),
    );
  }

  // ─── Dark Theme ─────────────────────────────────────────────────────────
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      primaryColor: primaryDark,
      scaffoldBackgroundColor: darkBg,
      colorScheme: const ColorScheme.dark(
        primary: primaryDark,
        secondary: info,
        tertiary: darkBg,
        surface: darkSurface,
        onSurface: textDark,
        onPrimary: Colors.white,
        primaryContainer: Color(0xFF3730A3), // Indigo 800
        secondaryContainer: darkSurface,
        error: error,
      ),
      textTheme: _textTheme(Brightness.dark),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: textDark),
        titleTextStyle: GoogleFonts.inter(
          color: textDark, fontSize: 18,
          fontWeight: FontWeight.w700, letterSpacing: -0.3,
        ),
      ),
      cardTheme: CardThemeData(
        color: darkSurface,
        elevation: 0,
        shadowColor: Colors.black.withAlpha(40),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: darkBorder, width: 1.0),
        ),
      ),
      dividerColor: darkBorder,
      dividerTheme: const DividerThemeData(
        color: darkBorder, thickness: 1,
      ),
    );
  }

  static Color getStatusColor(String? status) {
    switch (status) {
      case 'Available': return success;
      case 'Busy':
      case 'Do Not Disturb': return error;
      case 'Be Right Back':
      case 'Appear Away': return warning;
      default: return textMutedLt;
    }
  }
}