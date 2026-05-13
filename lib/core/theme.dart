// lib/core/theme.dart
import 'package:flutter/material.dart';

/// AppTheme — Premium, high-fidelity theme for a world-class experience.
/// Standardizes the "Titan" aesthetic (Glassmorphism, 32px radii, Neon Accents).
class AppTheme {
  // --- High-Visibility Branding Palette ---
  static const Color primaryTeal = Color(0xFF008080);
  static const Color electricTeal = Color(0xFF00FFCC);
  static const Color goldenAmber = Color(0xFFFFCC00);
  static const Color premiumBlack = Color(0xFF050505);
  static const Color surfaceMidnight = Color(0xFF121212);
  static const Color errorRed = Color(0xFFFF3333);

  // --- DARK THEME (The Flagship Experience) ---
  static final ThemeData dark = ThemeData(
    useMaterial3: true,
    fontFamily: 'NotoSans',
    brightness: Brightness.dark,
    scaffoldBackgroundColor: premiumBlack,
    
    colorScheme: const ColorScheme.dark(
      primary: primaryTeal,
      onPrimary: Colors.white,
      secondary: goldenAmber,
      onSecondary: Colors.black,
      surface: surfaceMidnight,
      onSurface: Colors.white,
      error: errorRed,
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: Colors.white, size: 22),
      titleTextStyle: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w900,
        color: Colors.white,
        letterSpacing: 2.0,
      ),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryTeal,
        foregroundColor: Colors.white,
        elevation: 8,
        shadowColor: primaryTeal.withValues(alpha: 0.4),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        textStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1.5),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.03),
      hintStyle: const TextStyle(color: Colors.white24, fontSize: 14),
      labelStyle: const TextStyle(color: electricTeal, fontWeight: FontWeight.bold, fontSize: 12),
      floatingLabelStyle: const TextStyle(color: goldenAmber, fontWeight: FontWeight.w900),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: electricTeal, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: errorRed, width: 1.5),
      ),
    ),

    cardTheme: CardThemeData(
      color: Colors.white.withValues(alpha: 0.04),
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(32),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
      ),
    ),

    textTheme: const TextTheme(
      headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5),
      headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white),
      bodyLarge: TextStyle(fontSize: 16, color: Colors.white, height: 1.6),
      bodyMedium: TextStyle(fontSize: 14, color: Colors.white70, height: 1.5),
      labelLarge: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: electricTeal, letterSpacing: 1.2),
    ),

    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.black,
      indicatorColor: primaryTeal.withValues(alpha: 0.15),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return const IconThemeData(color: electricTeal);
        return const IconThemeData(color: Colors.white24);
      }),
      labelTextStyle: WidgetStateProperty.all(
        const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white38, letterSpacing: 1),
      ),
    ),

    // Fixed: Using DialogThemeData to satisfy the latest SDK requirements
    dialogTheme: DialogThemeData(
      backgroundColor: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      titleTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18),
      contentTextStyle: const TextStyle(color: Colors.white54, fontSize: 14),
    ),
  );

  // --- LIGHT THEME (Clean & Credible) ---
  static final ThemeData light = ThemeData(
    useMaterial3: true,
    fontFamily: 'NotoSans',
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFF5F7F9),
    
    colorScheme: ColorScheme.light(
      primary: primaryTeal,
      onPrimary: Colors.white,
      secondary: primaryTeal.withValues(alpha: 0.8),
      surface: Colors.white,
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: premiumBlack,
      elevation: 0.5,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w900,
        color: premiumBlack,
      ),
    ),

    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.04),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.grey.withValues(alpha: 0.05),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: primaryTeal, width: 2),
      ),
    ),
  );
}
