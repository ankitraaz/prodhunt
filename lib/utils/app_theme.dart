import 'package:flutter/material.dart';

class AppTheme {
  // Light theme
  static ThemeData lightTheme() {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFFEA580C), // deepOrange-ish
      brightness: Brightness.light,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: 'Inter',
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
        ),
      ),
    );
  }

  // Dark theme
  static ThemeData darkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: Colors.black,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.deepPurple,
        brightness: Brightness.dark,
      ),
      fontFamily: 'Inter',
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.black,
        foregroundColor: Colors.deepPurple,
        elevation: 0,
      ),
      drawerTheme: const DrawerThemeData(backgroundColor: Colors.black),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Colors.white),
        bodyMedium: TextStyle(color: Colors.white70),
      ),
    );
  }
}
