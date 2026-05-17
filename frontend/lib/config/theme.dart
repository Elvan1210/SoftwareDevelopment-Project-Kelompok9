import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// MyPSKD Design System v2.0 — "Deep Space" Dark SaaS
/// Primary: Indigo #6366F1  |  Secondary: Purple #8B5CF6
/// ═══════════════════════════════════════════════════════════════════════════
class AppTheme {
  // ─── Core Brand Colors ──────────────────────────────────────────────────
  static const Color indigoPrimary   = Color(0xFF6366F1); // #6366F1
  static const Color indigoLight     = Color(0xFF818CF8); // #818CF8
  static const Color indigoDark      = Color(0xFF4F46E5); // #4F46E5
  static const Color purpleSecondary = Color(0xFF8B5CF6); // #8B5CF6
  static const Color purpleLight     = Color(0xFFA78BFA); // #A78BFA

  // ─── Accent Colors ──────────────────────────────────────────────────────
  static const Color amber     = Color(0xFFF59E0B); // Warm yellow
  static const Color emerald   = Color(0xFF10B981); // Success green
  static const Color rose      = Color(0xFFEF4444); // Error red
  static const Color sky       = Color(0xFF38BDF8); // Info blue

  // ─── Dark Mode Backgrounds ──────────────────────────────────────────────
  static const Color darkBg      = Color(0xFF0D0D1A); // Deep space navy
  static const Color darkSurface = Color(0xFF13131F); // Elevated surface
  static const Color darkCard    = Color(0xFF1C1C2E); // Card background
  static const Color darkBorder  = Color(0xFF2A2A42); // Subtle border

  // ─── Light Mode Backgrounds ─────────────────────────────────────────────
  static const Color lightBg      = Color(0xFFF5F5FF); // Warm white + purple tinge
  static const Color lightSurface = Color(0xFFFFFFFF); // Pure white card
  static const Color lightBorder  = Color(0xFFE8E6FF); // Soft purple border

  // ─── Text ───────────────────────────────────────────────────────────────
  static const Color textDark    = Color(0xFFF8F8FF); // Almost white
  static const Color textMutedDk = Color(0xFF9999CC); // Muted purple-gray
  static const Color textLight   = Color(0xFF1A1A3E); // Deep navy
  static const Color textMutedLt = Color(0xFF6B6B99); // Muted purple

  // ─── Legacy Aliases (backward compat) ─────────────────────────────────
  static const Color tealDeep    = indigoPrimary;
  static const Color tealLight   = purpleLight;
  static const Color orangeVivid = amber;       
  static const Color bgDarkest   = darkBg;      
  static const Color bgDarker    = darkCard;    

  static Color getAccent(BuildContext context) => indigoPrimary;

  // ─── Text Themes ────────────────────────────────────────────────────────
  static TextTheme _textTheme(Brightness b) {
    final isD = b == Brightness.dark;
    final text = isD ? textDark : textLight;
    final muted = isD ? textMutedDk : textMutedLt;

    return TextTheme(
      displayLarge: GoogleFonts.poppins(
        fontSize: 48, fontWeight: FontWeight.w800,
        color: text, letterSpacing: -1.5,
      ),
      headlineLarge: GoogleFonts.poppins(
        fontSize: 36, fontWeight: FontWeight.w800,
        color: text, letterSpacing: -1.0,
      ),
      headlineMedium: GoogleFonts.poppins(
        fontSize: 28, fontWeight: FontWeight.w700,
        color: text, letterSpacing: -0.8,
      ),
      headlineSmall: GoogleFonts.poppins(
        fontSize: 22, fontWeight: FontWeight.w700,
        color: text, letterSpacing: -0.5,
      ),
      titleLarge: GoogleFonts.poppins(
        fontSize: 18, fontWeight: FontWeight.w700,
        color: text, letterSpacing: -0.3,
      ),
      titleMedium: GoogleFonts.poppins(
        fontSize: 16, fontWeight: FontWeight.w600,
        color: text,
      ),
      titleSmall: GoogleFonts.poppins(
        fontSize: 14, fontWeight: FontWeight.w600,
        color: muted,
      ),
      bodyLarge: GoogleFonts.poppins(
        fontSize: 15, color: muted, height: 1.7,
        fontWeight: FontWeight.w400,
      ),
      bodyMedium: GoogleFonts.poppins(
        fontSize: 13, color: muted, height: 1.6,
        fontWeight: FontWeight.w400,
      ),
      labelLarge: GoogleFonts.poppins(
        fontSize: 13, fontWeight: FontWeight.w700,
        color: text, letterSpacing: 0.3,
      ),
      labelMedium: GoogleFonts.poppins(
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
      primaryColor: indigoPrimary,
      scaffoldBackgroundColor: lightBg,
      colorScheme: const ColorScheme.light(
        primary: indigoPrimary,
        secondary: purpleSecondary,
        tertiary: purpleLight,
        surface: lightSurface,
        onSurface: textLight,
        onPrimary: Colors.white,
        primaryContainer: Color(0xFFEDE9FE),
        secondaryContainer: Color(0xFFF3E8FF),
        error: rose,
      ),
      textTheme: _textTheme(Brightness.light),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: textLight),
        titleTextStyle: GoogleFonts.poppins(
          color: textLight, fontSize: 18,
          fontWeight: FontWeight.w700, letterSpacing: -0.3,
        ),
      ),
      cardTheme: CardThemeData(
        color: lightSurface,
        elevation: 0,
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
      primaryColor: indigoLight,
      scaffoldBackgroundColor: darkBg,
      colorScheme: const ColorScheme.dark(
        primary: indigoLight,
        secondary: purpleLight,
        tertiary: purpleSecondary,
        surface: darkCard,
        onSurface: textDark,
        onPrimary: Colors.white,
        primaryContainer: Color(0xFF312E81),
        secondaryContainer: Color(0xFF4C1D95),
        error: rose,
      ),
      textTheme: _textTheme(Brightness.dark),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: textDark),
        titleTextStyle: GoogleFonts.poppins(
          color: textDark, fontSize: 18,
          fontWeight: FontWeight.w700, letterSpacing: -0.3,
        ),
      ),
      cardTheme: CardThemeData(
        color: darkCard,
        elevation: 0,
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

  // ─── TAMBAHAN: Helper Warna Status ─────────────────────────────────────────
  static Color getStatusColor(String? status) {
    switch (status) {
      case 'Available': return emerald;
      case 'Busy':
      case 'Do Not Disturb': return rose;
      case 'Be Right Back':
      case 'Appear Away': return amber;
      case 'Appear Offline':
      default: return Colors.grey;
    }
  }
}