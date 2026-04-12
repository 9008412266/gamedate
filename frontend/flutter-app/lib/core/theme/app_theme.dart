import 'package:flutter/material.dart';

/// App-wide design system.
/// Supports dark and light modes with a gaming-inspired color palette.
class AppTheme {
  // Brand Colors
  static const Color primaryPink   = Color(0xFFFF6B9D);
  static const Color primaryPurple = Color(0xFF9B59B6);
  static const Color accentGold    = Color(0xFFFFD700);
  static const Color accentCyan    = Color(0xFF00E5FF);

  // Dark Mode Colors
  static const Color darkBg        = Color(0xFF0D0D1A);
  static const Color darkSurface   = Color(0xFF1A1A2E);
  static const Color darkCard      = Color(0xFF16213E);
  static const Color darkDivider   = Color(0xFF2D2D4A);

  // Light Mode Colors
  static const Color lightBg       = Color(0xFFF8F9FA);
  static const Color lightSurface  = Color(0xFFFFFFFF);
  static const Color lightCard     = Color(0xFFF0F2F5);

  // Status Colors
  static const Color success       = Color(0xFF4CAF50);
  static const Color warning       = Color(0xFFFF9800);
  static const Color error         = Color(0xFFE53935);
  static const Color online        = Color(0xFF4CAF50);
  static const Color offline       = Color(0xFF9E9E9E);

  static const String fontFamily = 'Poppins';

  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    fontFamily: fontFamily,
    colorScheme: ColorScheme.dark(
      primary: primaryPink,
      secondary: primaryPurple,
      surface: darkSurface,
      background: darkBg,
      error: error,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Colors.white,
      onBackground: Colors.white,
    ),
    scaffoldBackgroundColor: darkBg,
    cardColor: darkCard,
    dividerColor: darkDivider,

    appBarTheme: const AppBarTheme(
      backgroundColor: darkSurface,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(
        fontFamily: fontFamily,
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryPink,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(
          fontFamily: fontFamily,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryPink,
        side: const BorderSide(color: primaryPink),
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: darkCard,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryPink, width: 2),
      ),
      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
    ),

    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: darkSurface,
      selectedItemColor: primaryPink,
      unselectedItemColor: Colors.white54,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),

    cardTheme: CardThemeData(
      color: darkCard,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  );

  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    fontFamily: fontFamily,
    colorScheme: ColorScheme.light(
      primary: primaryPink,
      secondary: primaryPurple,
      surface: lightSurface,
      background: lightBg,
      error: error,
    ),
    scaffoldBackgroundColor: lightBg,
    cardColor: lightCard,

    appBarTheme: const AppBarTheme(
      backgroundColor: lightSurface,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: Color(0xFF1A1A2E)),
      titleTextStyle: TextStyle(
        fontFamily: fontFamily,
        color: Color(0xFF1A1A2E),
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryPink,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(
          fontFamily: fontFamily,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    cardTheme: CardThemeData(
      color: lightSurface,
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  );

  // Gradient helpers
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryPink, primaryPurple],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFFFD700), Color(0xFFFF8C00)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkCardGradient = LinearGradient(
    colors: [darkCard, darkSurface],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
