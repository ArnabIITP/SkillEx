import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Private constructor to prevent instantiation
  AppTheme._();

  // Define the core colors from your starter page
  static const Color primaryColor = Color(0xFFF37335);
  static const Color secondaryColor = Color(0xFFFDC830);
  static const Color whiteColor = Colors.white;
  static const Color darkTextColor = Color(0xFF333333); // For text on light backgrounds

  // --- Main Theme Data ---
  static final ThemeData lightTheme = ThemeData(
    // Set brightness and primary color swatch
    brightness: Brightness.light,
    primaryColor: primaryColor,
    scaffoldBackgroundColor: const Color(0xFFF5F5F5), // A neutral light background

    // --- Color Scheme ---
    // Defines the overall color palette for the app
    colorScheme: const ColorScheme.light(
      primary: primaryColor,
      secondary: secondaryColor,
      onPrimary: whiteColor, // Text/icons on primary color
      onSecondary: darkTextColor, // Text/icons on secondary color
      error: Colors.red,
      background: Color(0xFFF5F5F5),
      onBackground: darkTextColor,
      surface: whiteColor, // Color for card surfaces, dialogs
      onSurface: darkTextColor, // Text/icons on surface color
    ),

    // --- Typography ---
    // Use Google Fonts' Poppins as the default font family
    textTheme: GoogleFonts.poppinsTextTheme(ThemeData.light().textTheme).apply(
      bodyColor: darkTextColor,
      displayColor: darkTextColor,
    ),

    // --- AppBar Theme ---
    appBarTheme: AppBarTheme(
      backgroundColor: primaryColor,
      foregroundColor: whiteColor, // Sets color for icons and title
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: whiteColor,
      ),
    ),

    // --- Button Themes ---
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: whiteColor,
        textStyle: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        elevation: 2,
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryColor,
        side: const BorderSide(color: primaryColor, width: 2),
        textStyle: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryColor,
        textStyle: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),

    // --- Input Decoration Theme for TextFields ---
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      hintStyle: GoogleFonts.poppins(
        color: Colors.grey[400],
      ),
    ),

    // --- Icon Theme ---
    iconTheme: const IconThemeData(
      color: primaryColor,
    ),
  );
}
