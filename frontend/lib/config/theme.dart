import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Steve Jobs / Swiss Spa Minimalist Palette
  // Pure, absolute Onyx/Charcoal for darks, breathy Alabaster/Stone for lights
  static const Color primarySlate = Color(0xFF1A1A1A); // Deep Slate
  static const Color primarySage = Color(0xFFA6ACA2);  // Subdued luxury sage
  
  // Backwards compatibility for existing code during transition
  @Deprecated('Use theme.primaryColor instead')
  static const Color primaryTeal = primarySlate; 
  @Deprecated('Use theme.colorScheme.secondary instead')
  static const Color accentOrange = primarySage; 
  @Deprecated('Use theme.primaryColor instead')
  static const Color secondaryTeal = primarySage; 

  @Deprecated('Use getAccent instead')
  static Color getAdaptiveTeal(BuildContext context) {
    return getAccent(context);
  }

  // New Adaptive Tokens
  static Color getAccent(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? primarySage : primarySlate;
  }
  
  // Strict dark mode palette
  static const Color _darkBackground = Color(0xFF0F0F11); // Deep Onyx
  static const Color _darkSurface = Color(0xFF161618);    // Slightly lighter Onyx

  // Strict light mode palette
  static const Color _lightBackground = Color(0xFFFBFAF9); // Warm Alabaster
  static const Color _lightSurface = Color(0xFFFFFFFF);    // Pure White Surface

  // Premium design tokens (Glassmorphism)
  static Color getGlassColor(BuildContext context) => Theme.of(context).brightness == Brightness.dark 
      ? Colors.white.withAlpha(8) 
      : Colors.black.withAlpha(3);
  
  static Color getGlassBorder(BuildContext context) => Theme.of(context).brightness == Brightness.dark 
      ? Colors.white.withAlpha(15) 
      : Colors.black.withAlpha(10);

  static Color getInnerGlow(BuildContext context) => Theme.of(context).brightness == Brightness.dark 
      ? Colors.white.withAlpha(8) 
      : Colors.white.withAlpha(40);
  
  // Text Colors
  static const Color _textLight = Color(0xFF171717); // Almost crisp black
  static const Color _textMutedLight = Color(0xFF595959); // WCAG AA: 5.9:1 on white

  static TextTheme _baseTextTheme(Brightness brightness) {
    final Color textColor = brightness == Brightness.dark ? const Color(0xFFF4F4F5) : _textLight;
    final Color mutedColor = brightness == Brightness.dark ? const Color(0xFFA1A1AA) : _textMutedLight;

    return TextTheme(
      // Display/Heading: Cormorant Garamond for luxury spa feel
      displayLarge: GoogleFonts.cormorantGaramond(fontSize: 48, fontWeight: FontWeight.w600, color: textColor, letterSpacing: -1.0),
      headlineMedium: GoogleFonts.cormorantGaramond(fontSize: 28, fontWeight: FontWeight.w600, color: textColor, letterSpacing: -0.5),
      titleLarge: GoogleFonts.manrope(fontSize: 20, fontWeight: FontWeight.w700, color: textColor, letterSpacing: -0.3),
      
      // Body: Manrope for Steve Jobs precision
      bodyLarge: GoogleFonts.manrope(fontSize: 16, color: mutedColor, height: 1.6, fontWeight: FontWeight.w500),
      bodyMedium: GoogleFonts.manrope(fontSize: 14, color: mutedColor, height: 1.5, fontWeight: FontWeight.w500),
      labelLarge: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 0.5),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
      primaryColor: primarySlate,
      scaffoldBackgroundColor: _lightBackground,
      colorScheme: const ColorScheme.light(
        primary: primarySlate,
        secondary: primarySage,
        tertiary: primarySage,
        surface: _lightSurface,
        onSurface: _textLight,
      ),
      textTheme: _baseTextTheme(Brightness.light),
      appBarTheme: AppBarTheme(
        backgroundColor: _lightBackground.withAlpha(216), // Blends with background
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: _textLight),
        titleTextStyle: GoogleFonts.manrope(
          color: _textLight,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
      ),
      cardTheme: CardThemeData(
        color: _lightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Color(0xFFE5E5E5), width: 1.0), // Very subtle line
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      primaryColor: primarySage, // Distinct accent
      scaffoldBackgroundColor: _darkBackground,
      colorScheme: const ColorScheme.dark(
        primary: primarySage,
        secondary: primarySage,
        tertiary: primarySlate,
        surface: _darkSurface,
        onSurface: Color(0xFFF4F4F5),
      ),
      textTheme: _baseTextTheme(Brightness.dark),
      appBarTheme: AppBarTheme(
        backgroundColor: _darkBackground.withAlpha(216), 
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: Color(0xFFF4F4F5)),
        titleTextStyle: GoogleFonts.manrope(
          color: const Color(0xFFF4F4F5),
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
      ),
      cardTheme: CardThemeData(
        color: _darkSurface.withAlpha(180), // Frost effect
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: Colors.white.withAlpha(12), width: 1.0), // Micro subtle stroke
        ),
      ),
    );
  }
}

