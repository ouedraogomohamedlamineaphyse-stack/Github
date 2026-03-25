import 'package:flutter/material.dart';

class AppTheme {
  static const Color rouge = Color(0xFFCC0000);
  static const Color vert = Color(0xFF009A00);
  static const Color jaune = Color(0xFFFFD700);
  static const Color blanc = Colors.white;

  static ThemeData get lightTheme => ThemeData(
        brightness: Brightness.light,
        primaryColor: rouge,
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
        appBarTheme: const AppBarTheme(
          backgroundColor: rouge,
          foregroundColor: blanc,
          centerTitle: true,
          elevation: 0,
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: rouge,
          primary: rouge,
          secondary: vert,
          brightness: Brightness.light,
        ),
        cardColor: Colors.white,
        useMaterial3: true,
      );

  static ThemeData get darkTheme => ThemeData(
        brightness: Brightness.dark,
        primaryColor: rouge,
        scaffoldBackgroundColor: const Color(0xFF121212),
        appBarTheme: const AppBarTheme(
          backgroundColor: rouge,
          foregroundColor: blanc,
          centerTitle: true,
          elevation: 0,
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: rouge,
          primary: rouge,
          secondary: vert,
          brightness: Brightness.dark,
        ),
        cardColor: const Color(0xFF1E1E1E),
        useMaterial3: true,
      );

  // Garde la compatibilité avec l'ancien code
  static ThemeData get theme => lightTheme;
}