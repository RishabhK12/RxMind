import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: const Color(0xFF1E88E5),
    colorScheme: ColorScheme.light(
      primary: const Color(0xFF1E88E5),
      secondary: const Color(0xFF00BFA5),
      surface: Colors.white,
      error: const Color(0xFFD32F2F),
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: const Color(0xFF212121),
      onError: Colors.white,
    ),
    scaffoldBackgroundColor: const Color(0xFFF4F6F8),
    fontFamily: 'Poppins',
    textTheme: const TextTheme(
      displayLarge: TextStyle(
          fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 32),
      titleLarge: TextStyle(
          fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 20),
      titleMedium: TextStyle(
          fontFamily: 'Poppins', fontWeight: FontWeight.w500, fontSize: 16),
      bodyLarge: TextStyle(
          fontFamily: 'Poppins', fontWeight: FontWeight.w400, fontSize: 16),
      bodyMedium: TextStyle(
          fontFamily: 'Poppins', fontWeight: FontWeight.w400, fontSize: 14),
      labelLarge: TextStyle(
          fontFamily: 'Poppins', fontWeight: FontWeight.w500, fontSize: 12),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      elevation: 1,
      iconTheme: IconThemeData(color: Color(0xFF212121)),
      titleTextStyle: TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w600,
          fontSize: 20,
          color: Color(0xFF212121)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        textStyle: const TextStyle(
            fontFamily: 'Poppins', fontWeight: FontWeight.w500, fontSize: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 4,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        textStyle: const TextStyle(
            fontFamily: 'Poppins', fontWeight: FontWeight.w500, fontSize: 16),
      ),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      border: InputBorder.none,
      contentPadding: EdgeInsets.all(16),
      hintStyle: TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w400,
          fontSize: 16,
          color: Color(0xFFBDBDBD)),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: const Color(0xFF1E88E5),
    colorScheme: ColorScheme.dark(
      primary: const Color(0xFF1E88E5),
      secondary: const Color(0xFF00BFA5),
      surface: const Color(0xFF232526),
      error: const Color(0xFFD32F2F),
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Colors.white,
      onError: Colors.white,
    ),
    scaffoldBackgroundColor: const Color(0xFF181A1B),
    fontFamily: 'Poppins',
    textTheme: const TextTheme(
      displayLarge: TextStyle(
          fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 32),
      titleLarge: TextStyle(
          fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 20),
      titleMedium: TextStyle(
          fontFamily: 'Poppins', fontWeight: FontWeight.w500, fontSize: 16),
      bodyLarge: TextStyle(
          fontFamily: 'Poppins', fontWeight: FontWeight.w400, fontSize: 16),
      bodyMedium: TextStyle(
          fontFamily: 'Poppins', fontWeight: FontWeight.w400, fontSize: 14),
      labelLarge: TextStyle(
          fontFamily: 'Poppins', fontWeight: FontWeight.w500, fontSize: 12),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF232526),
      elevation: 1,
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w600,
          fontSize: 20,
          color: Colors.white),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        textStyle: const TextStyle(
            fontFamily: 'Poppins', fontWeight: FontWeight.w500, fontSize: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 4,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        textStyle: const TextStyle(
            fontFamily: 'Poppins', fontWeight: FontWeight.w500, fontSize: 16),
      ),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      border: InputBorder.none,
      contentPadding: EdgeInsets.all(16),
      hintStyle: TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w400,
          fontSize: 16,
          color: Color(0xFFBDBDBD)),
    ),
  );

  static ThemeData highContrastTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: Colors.black,
    colorScheme: ColorScheme.light(
      primary: Colors.black,
      secondary: Colors.yellow.shade800,
      surface: Colors.white,
      error: Colors.red.shade900,
      onPrimary: Colors.yellow.shade800,
      onSecondary: Colors.black,
      onSurface: Colors.black,
      onError: Colors.white,
    ),
    scaffoldBackgroundColor: Colors.white,
    fontFamily: 'Poppins',
    textTheme: const TextTheme(
      displayLarge: TextStyle(
          fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 36),
      titleLarge: TextStyle(
          fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 24),
      titleMedium: TextStyle(
          fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 18),
      bodyLarge: TextStyle(
          fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 18),
      bodyMedium: TextStyle(
          fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 16),
      labelLarge: TextStyle(
          fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 14),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.black,
      elevation: 1,
      iconTheme: IconThemeData(color: Colors.yellow),
      titleTextStyle: TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w700,
          fontSize: 24,
          color: Colors.yellow),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        textStyle: const TextStyle(
            fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 18),
        backgroundColor: Colors.black,
        foregroundColor: Colors.yellow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 4,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        textStyle: const TextStyle(
            fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 16),
        foregroundColor: Colors.black,
      ),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      border: InputBorder.none,
      contentPadding: EdgeInsets.all(16),
      hintStyle: TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w700,
          fontSize: 16,
          color: Colors.black),
    ),
  );
}
