import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// MyPSKD Design System v3.0 — "SMART LMS" Clean Edu Style
/// Primary: Periwinkle #7B83EB  |  Sidebar: Deep Indigo #2D2F7E
/// Background: Lavender Mist #F0F2FF
/// ═══════════════════════════════════════════════════════════════════════════
class AppTheme {
  // ─── Core Brand Colors ──────────────────────────────────────────────────
  static const Color indigoPrimary   = Color(0xFF7B83EB); // Periwinkle #7B83EB
  static const Color indigoLight     = Color(0xFF9BA3F5); // Light periwinkle
  static const Color indigoDark      = Color(0xFF5B63CB); // Dark periwinkle
  static const Color purpleSecondary = Color(0xFF8B5CF6); // Purple
  static const Color purpleLight     = Color(0xFFA78BFA); // Light purple

  // ─── Sidebar & Dark UI ──────────────────────────────────────────────────
  static const Color sidebarDark     = Color(0xFF2D2F7E); // Deep indigo sidebar
  static const Color sidebarDarker   = Color(0xFF1E2060); // Deeper sidebar shade
  static const Color sidebarActive   = Color(0xFF3D3F9E); // Active sidebar item

  // ─── Accent Colors ──────────────────────────────────────────────────────
  static const Color amber     = Color(0xFFF59E0B); // Warm yellow
  static const Color emerald   = Color(0xFF10B981); // Success green
  static const Color rose      = Color(0xFFEF4444); // Error red
  static const Color sky       = Color(0xFF38BDF8); // Info blue

  // ─── Dark Mode Backgrounds ──────────────────────────────────────────────
  static const Color darkBg      = Color(0xFF161D2B); // Premium dark charcoal
  static const Color darkSurface = Color(0xFF161B27); // Elevated dark surface
  static const Color darkCard    = Color(0xFF1C2230); // Clean minimalist dark card
  static const Color darkBorder  = Color(0xFF252D3D); // Sharp neutral dark border

  // ─── Light Mode Backgrounds (SMART LMS Style) ───────────────────────────
  static const Color lightBg      = Color(0xFFF8F9FC); // Clean off-white background
  static const Color lightSurface = Color(0xFFFFFFFF); // Pure white card
  static const Color lightBorder  = Color(0xFFE5E7EB); // Soft neutral light border

  // ─── Text ───────────────────────────────────────────────────────────────
  static const Color textDark    = Color(0xFFF8F8FF); // Almost white
  static const Color textMutedDk = Color(0xFF9FA3CC); // Muted purple-gray
  static const Color textLight   = Color(0xFF1A1A3E); // Deep navy
  static const Color textMutedLt = Color(0xFF6B7099); // Muted cool gray

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

  // ─── Light Theme (SMART LMS Style) ─────────────────────────────────────
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
        primaryContainer: Color(0xFFDDE1FF),
        secondaryContainer: Color(0xFFEDE9FE),
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
        shadowColor: const Color(0x197B83EB),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
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
        primaryContainer: Color(0xFF2D2F7E),
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