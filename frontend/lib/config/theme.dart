import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Nautical Bauhaus Palette (Teal-Orange Industrial)
  static const Color tealDeep = Color(0xFF075864);   // #075864
  static const Color tealLight = Color(0xFF76AFB8);  // #76AFB8
  static const Color orangeVivid = Color(0xFFF27F33); // #F27F33
  
  // Derivatives
  static const Color bgDarkest = Color(0xFF121212); // Dark Background
  static const Color bgDarker = Color(0xFF1E1E1E);  // Dark Surface
  static const Color bgLightest = Colors.white; // Light Background
  static const Color textMutedDark = Color(0xFF8DBCC3); // Muted Text Dark Mode
  static const Color textMutedLight = Color(0xFF26494F); // Muted Text Light Mode
  
  // Adaptive Tokens
  static Color getAccent(BuildContext context) {
    return orangeVivid;
  }
  
  // Faux-Glass design tokens (Using White/Black derivatives)
  static Color getGlassColor(BuildContext context) => Theme.of(context).brightness == Brightness.dark 
      ? Colors.white.withAlpha(15) 
      : tealDeep.withAlpha(5);
  
  static Color getGlassBorder(BuildContext context) => Theme.of(context).brightness == Brightness.dark 
      ? Colors.white.withAlpha(25) 
      : tealDeep.withAlpha(15);

  static Color getInnerGlow(BuildContext context) => Theme.of(context).brightness == Brightness.dark 
      ? Colors.white.withAlpha(12) 
      : Colors.white.withAlpha(60);
  
  static TextTheme _baseTextTheme(Brightness brightness) {
    final Color textColor = brightness == Brightness.dark ? Colors.white : bgDarkest;
    final Color mutedColor = brightness == Brightness.dark ? textMutedDark : textMutedLight;

    return TextTheme(
      displayLarge: GoogleFonts.cormorantGaramond(fontSize: 48, fontWeight: FontWeight.w600, color: textColor, letterSpacing: -1.0),
      headlineMedium: GoogleFonts.cormorantGaramond(fontSize: 28, fontWeight: FontWeight.w600, color: textColor, letterSpacing: -0.5),
      titleLarge: GoogleFonts.manrope(fontSize: 20, fontWeight: FontWeight.w800, color: textColor, letterSpacing: -0.5),
      bodyLarge: GoogleFonts.manrope(fontSize: 16, color: mutedColor, height: 1.6, fontWeight: FontWeight.w500),
      bodyMedium: GoogleFonts.manrope(fontSize: 14, color: mutedColor, height: 1.5, fontWeight: FontWeight.w500),
      labelLarge: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 0.5),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
      primaryColor: tealDeep,
      scaffoldBackgroundColor: bgLightest,
      colorScheme: const ColorScheme.light(
        primary: tealDeep,
        secondary: orangeVivid,
        tertiary: tealLight,
        surface: Colors.white,
        onSurface: bgDarkest,
      ),
      textTheme: _baseTextTheme(Brightness.light),
      appBarTheme: AppBarTheme(
        backgroundColor: bgLightest.withAlpha(240),
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: bgDarkest),
        titleTextStyle: GoogleFonts.manrope(
          color: bgDarkest,
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: tealDeep.withAlpha(15), width: 1.0),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      primaryColor: tealLight, 
      scaffoldBackgroundColor: bgDarkest,
      colorScheme: const ColorScheme.dark(
        primary: tealLight,
        secondary: orangeVivid,
        tertiary: tealDeep,
        surface: bgDarker,
        onSurface: Colors.white,
      ),
      textTheme: _baseTextTheme(Brightness.dark),
      appBarTheme: AppBarTheme(
        backgroundColor: bgDarkest.withAlpha(240), 
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: GoogleFonts.manrope(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
      ),
      cardTheme: CardThemeData(
        color: bgDarker, 
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: Colors.white.withAlpha(15), width: 1.0),
        ),
      ),
    );
  }
}
