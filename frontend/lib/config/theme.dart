import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// MyPSKD Design System v4.0
/// Base: #B4D3D9 | Surface: #F2EAE0 | Accent: #9B8EC7 | Text: #2D2250
/// ═══════════════════════════════════════════════════════════════════════════
class AppTheme {
  // ─── Core Brand Colors ──────────────────────────────────────────────────
  static const Color primary     = Color(0xFF9B8EC7); // Soft purple — accent
  static const Color base        = Color(0xFFB4D3D9); // Teal-blue — background
  static const Color surface     = Color(0xFFF2EAE0); // Warm cream — cards
  static const Color textPrimary = Color(0xFF2D2250); // Deep navy — text

  // ─── Legacy aliases (backward compat) ───────────────────────────────────
  static const Color indigoPrimary   = primary;
  static const Color indigoLight     = Color(0xFFBDA6CE);
  static const Color indigoDark      = Color(0xFF6B5E9E);
  static const Color purpleSecondary = primary;
  static const Color purpleLight     = Color(0xFFBDA6CE);
  static const Color tealDeep        = primary;
  static const Color tealLight       = base;
  static const Color sidebarDark     = textPrimary;
  static const Color sidebarDarker   = Color(0xFF1A1040);
  static const Color sidebarActive   = primary;

  // ─── Semantic Colors (tetap sama) ───────────────────────────────────────
  static const Color amber   = Color(0xFFF59E0B);
  static const Color emerald = Color(0xFF10B981);
  static const Color rose    = Color(0xFFA32D2D); // error only
  static const Color sky     = Color(0xFF38BDF8);
  static const Color orangeVivid = Color(0xFFF27F33);

  // ─── Light Mode ─────────────────────────────────────────────────────────
  static const Color lightBg      = base;
  static const Color lightSurface = surface;
  static const Color lightBorder  = Color(0xFFD4C5B8);
  static const Color textLight    = textPrimary;
  static const Color textMutedLt  = Color(0xFF6B5E9E);

  // ─── Dark Mode ──────────────────────────────────────────────────────────
  static const Color darkBg      = Color(0xFF1A1040);
  static const Color darkSurface = Color(0xFF2D2250);
  static const Color darkCard    = Color(0xFF2D2250);
  static const Color darkBorder  = Color(0xFF3D3270);
  static const Color textDark    = surface;
  static const Color textMutedDk = Color(0xFFBDA6CE);
  static const Color bgDarkest   = darkBg;
  static const Color bgDarker    = darkCard;

  static Color getAccent(BuildContext context) => primary;

  // ─── Text Themes ────────────────────────────────────────────────────────
  static TextTheme _textTheme(Brightness b) {
    final isD = b == Brightness.dark;
    final text  = isD ? textDark    : textLight;
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
      primaryColor: primary,
      scaffoldBackgroundColor: lightBg,
      colorScheme: const ColorScheme.light(
        primary: primary,
        secondary: Color(0xFFBDA6CE),
        tertiary: base,
        surface: surface,
        onSurface: textPrimary,
        onPrimary: Colors.white,
        primaryContainer: Color(0xFFDDD8F0),
        secondaryContainer: surface,
        error: rose,
      ),
      textTheme: _textTheme(Brightness.light),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: textPrimary),
        titleTextStyle: GoogleFonts.poppins(
          color: textPrimary, fontSize: 18,
          fontWeight: FontWeight.w700, letterSpacing: -0.3,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shadowColor: primary.withAlpha(30),
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
      primaryColor: primary,
      scaffoldBackgroundColor: darkBg,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: Color(0xFFBDA6CE),
        tertiary: base,
        surface: darkCard,
        onSurface: textDark,
        onPrimary: Colors.white,
        primaryContainer: Color(0xFF3D3270),
        secondaryContainer: Color(0xFF2D2250),
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

  static Color getStatusColor(String? status) {
    switch (status) {
      case 'Available': return emerald;
      case 'Busy':
      case 'Do Not Disturb': return rose;
      case 'Be Right Back':
      case 'Appear Away': return amber;
      default: return Colors.grey;
    }
  }
}