import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: const Color(0xFF3A86FF),
    scaffoldBackgroundColor: const Color(0xFFF8F9FB),
    colorScheme: ColorScheme.light(
      primary: const Color(0xFF3A86FF),
      secondary: const Color(0xFF00B4D8),
      surface: Colors.white,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Colors.black,
    ),
    textTheme: GoogleFonts.interTextTheme(),
    fontFamily: 'Inter',
    useMaterial3: true,
  );

  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: const Color(0xFF3A86FF),
    scaffoldBackgroundColor: const Color(0xFF181A20),
    colorScheme: ColorScheme.dark(
      primary: const Color(0xFF3A86FF),
      secondary: const Color(0xFF00B4D8),
      surface: const Color(0xFF23262F),
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Colors.white,
    ),
    textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
    fontFamily: 'Inter',
    useMaterial3: true,
  );
}
