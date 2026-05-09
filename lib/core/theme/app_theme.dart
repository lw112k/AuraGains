import 'package:flutter/material.dart';

// =====================================================================
      // ARCHITECTURE NOTE:
      // This global theme ONLY controls the core background canvas and the 
      // main brand typography (H1, H2, Logo).
      // 
      // ALL OTHER interactive component colors MUST be styled locally inside 
      // your respective View files. DO NOT ADD HERE, BECAUSE YOUR OWN FEATURE 
      // WILL HAVE UR OWN DESIGN IF U PUT HERE IT WILL MAKE CHANGES GLOBALLY
      // =====================================================================

class AppTheme {
  // 1. Foundation Colors
  static const Color backgroundDark = Color(0xFF121212);
  static const Color surfaceFrame = Color(0xFF1E1E1E);
  static const Color primaryAccent = Colors.cyanAccent;

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: surfaceFrame,

      // GLOBAL TYPOGRAPHY (The H1, H2, and Body text)
      textTheme: const TextTheme(
        // Acts as your "H1" - Huge, bold page titles
        displayLarge: TextStyle(
          color: Colors.white,
          fontSize: 32,
          fontWeight: FontWeight.w900, // Extra thick
          letterSpacing: 1.0,
        ),
        // Acts as your "H2" - Section headers or Card Titles
        headlineMedium: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
        // Standard body text for descriptions
        bodyMedium: TextStyle(
          color: Color(0xFFBDBDBD), // Colors.grey[400]
          fontSize: 14,
          height: 1.4, // Good line height for readability
        ),
      ),

      // Handling the Logo/Brand Font & Color
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
          fontSize: 20,
        ),
      ),
    );
  }
}
