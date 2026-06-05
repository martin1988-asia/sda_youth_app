import 'package:flutter/material.dart';

class AppTheme {
  // ✅ CORE BRAND COLORS
  static const Color primary = Color(0xFF00E6B8);
  static const Color secondary = Color(0xFFFFCC00);

  // ✅ SURFACE SYSTEM
  static const Color bg = Color(0xFF0A0A0A);
  static const Color surface = Color(0xFF121212);
  static const Color surfaceSoft = Color(0xFF181818);

  static const Color error = Color(0xFFFF3333);

  // ✅ TEXT COLORS
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Colors.white70;
  static const Color textMuted = Colors.white38;

  // ✅ MAIN DARK THEME
  static final ThemeData dark = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    fontFamily: 'NotoSans',

    scaffoldBackgroundColor: bg,

    colorScheme: const ColorScheme.dark(
      primary: primary,
      secondary: secondary,
      surface: surface,
      error: error,
    ),

    // ✅ APPBAR
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: textPrimary),
      titleTextStyle: TextStyle(
        color: textPrimary,
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
    ),

    // ✅ BUTTONS
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.black,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
      ),
    ),

    // ✅ INPUTS
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surface,
      hintStyle: const TextStyle(color: textMuted),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),

      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),

      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0x1AFFFFFF)),
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: primary),
      ),
    ),

    // ✅ CARDS
    cardTheme: CardThemeData(
      color: surfaceSoft,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0x14FFFFFF)),
      ),
    ),

    // ✅ TEXT SYSTEM
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: textPrimary, fontSize: 15),
      bodyMedium: TextStyle(color: textSecondary, fontSize: 14),
      titleMedium: TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
    ),

    // ✅ ✅ FIXED (IMPORTANT)
    tabBarTheme: const TabBarThemeData(
      indicatorColor: primary,
      labelColor: textPrimary,
      unselectedLabelColor: textMuted,
    ),
  );
}
