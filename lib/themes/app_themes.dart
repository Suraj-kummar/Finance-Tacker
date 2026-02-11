import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/theme_provider.dart';

class AppThemes {
  // Brand Colors
  static const Color mountainMeadow = Color(0xFF10B981);
  static const Color slateBackground = Color(0xFFF8FAFC);
  
  static ThemeData getTheme(ThemeOption option, Brightness brightness) {
    switch (option) {
      case ThemeOption.system:
        return brightness == Brightness.dark ? _darkTheme : _lightTheme;
      case ThemeOption.light:
        return _lightTheme;
      case ThemeOption.dark:
        return _darkTheme;
      case ThemeOption.midnight:
        return _midnightTheme;
      case ThemeOption.cozy:
        return _cozyTheme;
      case ThemeOption.bright:
        return _brightTheme;
      case ThemeOption.ocean:
        return _oceanTheme;
      case ThemeOption.forest:
        return _forestTheme;
    }
  }

  // Light Theme
  static final ThemeData _lightTheme = ThemeData(
    useMaterial3: true,
    fontFamily: GoogleFonts.inter().fontFamily,
    colorScheme: ColorScheme.fromSeed(
      seedColor: mountainMeadow,
      primary: mountainMeadow,
      secondary: const Color(0xFF3B82F6),
      surface: slateBackground,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: slateBackground,
    textTheme: GoogleFonts.interTextTheme(),
  );

  // Dark Theme
  static final ThemeData _darkTheme = ThemeData(
    useMaterial3: true,
    fontFamily: GoogleFonts.inter().fontFamily,
    colorScheme: ColorScheme.fromSeed(
      seedColor: mountainMeadow,
      primary: mountainMeadow,
      secondary: const Color(0xFF60A5FA),
      surface: Colors.black,
      onSurface: Colors.white,
      brightness: Brightness.dark,
    ),
    scaffoldBackgroundColor: Colors.black,
    textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
  );

  // Midnight Theme - Deep blue-black with purple accents
  static final ThemeData _midnightTheme = ThemeData(
    useMaterial3: true,
    fontFamily: GoogleFonts.inter().fontFamily,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF8B5CF6),
      primary: const Color(0xFF8B5CF6), // Purple
      secondary: const Color(0xFF6366F1), // Indigo
      surface: const Color(0xFF0F172A), // Deep blue-black
      onSurface: Colors.white,
      brightness: Brightness.dark,
    ),
    scaffoldBackgroundColor: const Color(0xFF0F172A),
    textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
  );

  // Cozy Theme - Warm browns and oranges
  static final ThemeData _cozyTheme = ThemeData(
    useMaterial3: true,
    fontFamily: GoogleFonts.inter().fontFamily,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFFEA580C),
      primary: const Color(0xFFEA580C), // Orange
      secondary: const Color(0xFFD97706), // Amber
      surface: const Color(0xFFFFF7ED), // Warm cream
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: const Color(0xFFFFF7ED),
    textTheme: GoogleFonts.interTextTheme(),
  );

  // Bright Theme - High contrast vibrant colors
  static final ThemeData _brightTheme = ThemeData(
    useMaterial3: true,
    fontFamily: GoogleFonts.inter().fontFamily,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFFEC4899),
      primary: const Color(0xFFEC4899), // Pink
      secondary: const Color(0xFFF59E0B), // Yellow
      surface: Colors.white,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: Colors.white,
    textTheme: GoogleFonts.interTextTheme(),
  );

  // Ocean Theme - Blue tones with teal accents
  static final ThemeData _oceanTheme = ThemeData(
    useMaterial3: true,
    fontFamily: GoogleFonts.inter().fontFamily,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF06B6D4),
      primary: const Color(0xFF06B6D4), // Cyan
      secondary: const Color(0xFF0EA5E9), // Sky blue
      surface: const Color(0xFF082F49), // Deep ocean blue
      onSurface: Colors.white,
      brightness: Brightness.dark,
    ),
    scaffoldBackgroundColor: const Color(0xFF082F49),
    textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
  );

  // Forest Theme - Green tones with earthy colors
  static final ThemeData _forestTheme = ThemeData(
    useMaterial3: true,
    fontFamily: GoogleFonts.inter().fontFamily,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF059669),
      primary: const Color(0xFF059669), // Emerald
      secondary: const Color(0xFF10B981), // Green
      surface: const Color(0xFF064E3B), // Deep forest green
      onSurface: Colors.white,
      brightness: Brightness.dark,
    ),
    scaffoldBackgroundColor: const Color(0xFF064E3B),
    textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
  );
}
