import 'package:flutter/material.dart';

class EnXStyle {
  static const Color primaryBlue = Color(0xFF1D2A4E);
  static const Color backgroundBlack = Color(0xFF020306);
  static const Color accentGreen = Color(0xFF25D366); // Verde do Pigeon [cite: 2026-01-22]

  static ThemeData theme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: primaryBlue,
    scaffoldBackgroundColor: backgroundBlack,
    
    // Remove o roxo padrão e define a identidade EnX
    colorScheme: const ColorScheme.dark(
      primary: Colors.white, 
      secondary: accentGreen,
      surface: backgroundBlack,
    ),

    // Estilo global dos campos de texto (Inputs) [cite: 2025-10-27]
    inputDecorationTheme: const InputDecorationTheme(
      labelStyle: TextStyle(color: Colors.white70),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: primaryBlue),
        borderRadius: BorderRadius.zero,
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.white),
        borderRadius: BorderRadius.zero,
      ),
    ),
    
    // Padronização dos textos
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.white),
      bodyMedium: TextStyle(color: Colors.white70),
    ),
  );
}
