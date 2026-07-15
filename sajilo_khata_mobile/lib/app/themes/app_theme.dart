import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand color: Trustworthy Deep Teal
  static const Color primaryColor = Color(0xFF0F6E56);
  static const Color primaryLight = Color(0xFF168E6F);
  static const Color secondaryColor = Color(0xFFF7A072);
  static const Color errorColor = Color(0xFFEF4444);
  static const Color successColor = Color(0xFF10B981);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryColor,
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        error: errorColor,
        surface: Colors.white,
        background: Color(0xFFF5F7F8),
      ),
      scaffoldBackgroundColor: const Color(0xFFF5F7F8),
      fontFamily: GoogleFonts.notoSansDevanagari().fontFamily,
      textTheme: GoogleFonts.notoSansDevanagariTextTheme(
        ThemeData.light().textTheme,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: primaryColor),
        titleTextStyle: TextStyle(
          color: primaryColor,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardTheme(
        color: Colors.white,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
      ),
      buttonTheme: const ButtonThemeData(
        buttonColor: primaryColor,
        textTheme: ButtonTextTheme.primary,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primaryColor,
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        secondary: secondaryColor,
        error: errorColor,
        surface: Color(0xFF1E293B),
        background: Color(0xFF0F172A),
      ),
      scaffoldBackgroundColor: const Color(0xFF0F172A),
      fontFamily: GoogleFonts.notoSansDevanagari().fontFamily,
      textTheme: GoogleFonts.notoSansDevanagariTextTheme(
        ThemeData.dark().textTheme,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1E293B),
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardTheme(
        color: const Color(0xFF1E293B),
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1E293B),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF334155)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
      ),
    );
  }
}
