import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Ultra-premium modern SaaS palette
  static const Color _primaryBlue = Color(0xFF3B82F6); // Vibrant Blue
  static const Color _accentCyan = Color(0xFF06B6D4);
  
  // Antigravity dark mode palette (Deep Slate, true weightlessness)
  static const Color _darkBackground = Color(0xFF0B1120);
  static const Color _darkSurface = Color(0xFF1E293B);
  
  // Clean light mode palette
  static const Color _lightBackground = Color(0xFFF8FAFC);
  static const Color _lightSurface = Colors.white;

  /// Returns text theme styled beautifully with Plus Jakarta Sans
  static TextTheme _baseTextTheme(Brightness brightness) {
    final Color textColor = brightness == Brightness.dark ? Colors.white : const Color(0xFF0F172A);
    final Color mutedColor = brightness == Brightness.dark ? const Color(0xFF94A3B8) : const Color(0xFF475569);

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
      primaryColor: _primaryBlue,
      scaffoldBackgroundColor: _lightBackground,
      colorScheme: const ColorScheme.light(
        primary: _primaryBlue,
        secondary: _accentCyan,
        surface: _lightSurface,
        onSurface: Color(0xFF0F172A),
      ),
      textTheme: _baseTextTheme(Brightness.light),
      appBarTheme: AppBarTheme(
        backgroundColor: _lightSurface.withAlpha(216), // Glassmorphism setup
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
        titleTextStyle: GoogleFonts.plusJakartaSans(
          color: const Color(0xFF0F172A),
          fontSize: 22,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
      ),
      cardTheme: CardThemeData(
        color: _lightSurface,
        elevation: 0, // We rely on custom painting or shadow definition for smooth shadows
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
      primaryColor: _primaryBlue,
      scaffoldBackgroundColor: _darkBackground,
      colorScheme: const ColorScheme.dark(
        primary: _primaryBlue,
        secondary: _accentCyan,
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
          side: BorderSide(color: Colors.white.withAlpha(20), width: 1.5),
        ),
      ),
    );
  }
}
