import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Ultra-premium modern SaaS palette based on new logo assets
  static const Color primaryTeal = Color(0xFF075864); // Deep Teal
  static const Color accentOrange = Color(0xFFF27F33); // Orange
  static const Color secondaryTeal = Color(0xFF76AFB8); // Light Teal
  
  // Strict dark mode palette
  static const Color _darkBackground = Colors.black;
  static const Color _darkSurface = Colors.black;

  /// Returns Light Teal in Dark Mode, Deep Teal in Light Mode for optimal contrast
  static Color getAdaptiveTeal(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? secondaryTeal : primaryTeal;
  }
  
  // Strict light mode palette
  static const Color _lightBackground = Colors.white;
  static const Color _lightSurface = Colors.white;
  
  // Text Colors
  static const Color _textLight = Color(0xFF0F172A); // High contrast slate-900 per Pro Max rule
  static const Color _textMutedLight = Color(0xFF475569); // slate-600 minimum for muted text

  /// Returns text theme styled beautifully with Plus Jakarta Sans
  static TextTheme _baseTextTheme(Brightness brightness) {
    final Color textColor = brightness == Brightness.dark ? Colors.white : _textLight;
    final Color mutedColor = brightness == Brightness.dark ? const Color(0xFF94A3B8) : _textMutedLight;

    return GoogleFonts.plusJakartaSansTextTheme(
      TextTheme(
        displayLarge: TextStyle(fontSize: 48, fontWeight: FontWeight.w800, color: textColor, letterSpacing: -1.5),
        headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: textColor, letterSpacing: -0.5),
        titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: textColor, letterSpacing: -0.2),
        bodyLarge: TextStyle(fontSize: 16, color: mutedColor, height: 1.6),
        bodyMedium: TextStyle(fontSize: 14, color: mutedColor, height: 1.5),
        labelLarge: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.2), // Buttons
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
      primaryColor: primaryTeal,
      scaffoldBackgroundColor: _lightBackground,
      colorScheme: const ColorScheme.light(
        primary: primaryTeal,
        secondary: accentOrange,
        tertiary: secondaryTeal,
        surface: _lightSurface,
        onSurface: _textLight,
      ),
      textTheme: _baseTextTheme(Brightness.light),
      appBarTheme: AppBarTheme(
        backgroundColor: _lightSurface.withAlpha(216), // Glassmorphism setup (min 80% opacity in light mode)
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: _textLight),
        titleTextStyle: GoogleFonts.plusJakartaSans(
          color: _textLight,
          fontSize: 22,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
      ),
      cardTheme: CardThemeData(
        color: _lightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5), // Subtle border
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      primaryColor: secondaryTeal,
      scaffoldBackgroundColor: _darkBackground,
      colorScheme: const ColorScheme.dark(
        primary: secondaryTeal,
        secondary: accentOrange,
        tertiary: secondaryTeal,
        surface: _darkSurface,
        onSurface: Colors.white,
      ),
      textTheme: _baseTextTheme(Brightness.dark),
      appBarTheme: AppBarTheme(
        backgroundColor: _darkBackground.withAlpha(216), // Glassmorphism setup
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: GoogleFonts.plusJakartaSans(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
      ),
      cardTheme: CardThemeData(
        color: _darkSurface.withAlpha(153), // Semi-transparent for glass effect
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: secondaryTeal.withAlpha(30), width: 1.5), // Subtle teal border
        ),
      ),
    );
  }
}
