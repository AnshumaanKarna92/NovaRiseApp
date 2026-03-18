import "package:flutter/material.dart";

class AppTheme {
  static ThemeData light() {
    const primary = Color(0xFF003D5B); // Academy Navy
    const secondary = Color(0xFFD4AF37); // Heritage Gold
    const success = Color(0xFF00A86B); // Leaf Green
    const background = Color(0xFFF8F9FA); // Clean Light Gray
    const surface = Colors.white;

    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        secondary: secondary,
        onSecondary: Colors.white,
        surface: surface,
        brightness: Brightness.light,
      ),
      useMaterial3: true,
      scaffoldBackgroundColor: background,
      textTheme: const TextTheme(
        headlineMedium: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, letterSpacing: -0.8, color: primary),
        headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5, color: primary),
        titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: primary),
        titleMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: 0.1),
        titleSmall: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 0.2),
        bodyLarge: TextStyle(fontSize: 17, height: 1.6, color: Colors.black87),
        bodyMedium: TextStyle(fontSize: 15, height: 1.6, color: Colors.black87),
        bodySmall: TextStyle(fontSize: 13, height: 1.5, color: Colors.black54),
        labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 1.1),
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        backgroundColor: background,
        elevation: 0,
        scrolledUnderElevation: 4,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          color: primary,
          fontSize: 22,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.5,
        ),
        iconTheme: IconThemeData(color: primary, size: 28),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: primary.withValues(alpha: 0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: primary.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
          elevation: 2,
          shadowColor: primary.withValues(alpha: 0.2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          side: BorderSide(color: primary.withValues(alpha: 0.2)),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: surface,
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: primary.withValues(alpha: 0.08), width: 1.2),
        ),
      ),
    );
  }
}
