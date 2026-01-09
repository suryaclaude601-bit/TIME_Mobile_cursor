import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AppThemes {
  // Font Configuration
  static const String defaultFontFamily = 'Poppins';

  // Dark Theme Colors
  static const Color darkBackground = Color(0xFF1c1f23);
  static const Color darkSurface = Color(0xFF2c2f33);
  static const Color darkBottomNav = Color(0xFF2a2a2a);
  static const Color darkText = Colors.white;
  static const Color darkTextSecondary = Colors.white70;

  // Light Theme Colors
  static const Color lightBackground = Color(0xFFF5F5F5);
  static const Color lightSurface = Colors.white;
  static const Color lightBottomNav = Color(0xFFFFFFFF);
  static const Color lightText = Color(0xFF1c1f23);
  static const Color lightTextSecondary = Color(0xFF666666);

  // Common Text Theme - Light
  static TextTheme _lightTextTheme = TextTheme(
    displayLarge: TextStyle(
      fontFamily: defaultFontFamily,
      fontSize: 32.sp,
      fontWeight: FontWeight.bold,
      color: lightText,
    ),
    displayMedium: TextStyle(
      fontFamily: defaultFontFamily,
      fontSize: 28.sp,
      fontWeight: FontWeight.bold,
      color: lightText,
    ),
    displaySmall: TextStyle(
      fontFamily: defaultFontFamily,
      fontSize: 24.sp,
      fontWeight: FontWeight.bold,
      color: lightText,
    ),
    headlineLarge: TextStyle(
      fontFamily: defaultFontFamily,
      fontSize: 22.sp,
      fontWeight: FontWeight.w600,
      color: lightText,
    ),
    headlineMedium: TextStyle(
      fontFamily: defaultFontFamily,
      fontSize: 20.sp,
      fontWeight: FontWeight.w600,
      color: lightText,
    ),
    headlineSmall: TextStyle(
      fontFamily: defaultFontFamily,
      fontSize: 18.sp,
      fontWeight: FontWeight.w600,
      color: lightText,
    ),
    titleLarge: TextStyle(
      fontFamily: defaultFontFamily,
      fontSize: 16.sp,
      fontWeight: FontWeight.bold,
      color: lightText,
    ),
    titleMedium: TextStyle(
      fontFamily: defaultFontFamily,
      fontSize: 14.sp,
      fontWeight: FontWeight.w600,
      color: lightText,
    ),
    titleSmall: TextStyle(
      fontFamily: defaultFontFamily,
      fontSize: 12.sp,
      fontWeight: FontWeight.w600,
      color: lightText,
    ),
    bodyLarge: TextStyle(
      fontFamily: defaultFontFamily,
      fontSize: 16.sp,
      fontWeight: FontWeight.normal,
      color: lightText,
    ),
    bodyMedium: TextStyle(
      fontFamily: defaultFontFamily,
      fontSize: 14.sp,
      fontWeight: FontWeight.normal,
      color: lightText,
    ),
    bodySmall: TextStyle(
      fontFamily: defaultFontFamily,
      fontSize: 12.sp,
      fontWeight: FontWeight.normal,
      color: lightText,
    ),
    labelLarge: TextStyle(
      fontFamily: defaultFontFamily,
      fontSize: 14.sp,
      fontWeight: FontWeight.w500,
      color: lightText,
    ),
    labelMedium: TextStyle(
      fontFamily: defaultFontFamily,
      fontSize: 12.sp,
      fontWeight: FontWeight.w500,
      color: lightText,
    ),
    labelSmall: TextStyle(
      fontFamily: defaultFontFamily,
      fontSize: 10.sp,
      fontWeight: FontWeight.w500,
      color: lightText,
    ),
  );

  // Common Text Theme - Dark
  static TextTheme _darkTextTheme = TextTheme(
    displayLarge: TextStyle(
      fontFamily: defaultFontFamily,
      fontSize: 32.sp,
      fontWeight: FontWeight.bold,
      color: darkText,
    ),
    displayMedium: TextStyle(
      fontFamily: defaultFontFamily,
      fontSize: 28.sp,
      fontWeight: FontWeight.bold,
      color: darkText,
    ),
    displaySmall: TextStyle(
      fontFamily: defaultFontFamily,
      fontSize: 24.sp,
      fontWeight: FontWeight.bold,
      color: darkText,
    ),
    headlineLarge: TextStyle(
      fontFamily: defaultFontFamily,
      fontSize: 22.sp,
      fontWeight: FontWeight.w600,
      color: darkText,
    ),
    headlineMedium: TextStyle(
      fontFamily: defaultFontFamily,
      fontSize: 20.sp,
      fontWeight: FontWeight.w600,
      color: darkText,
    ),
    headlineSmall: TextStyle(
      fontFamily: defaultFontFamily,
      fontSize: 18.sp,
      fontWeight: FontWeight.w600,
      color: darkText,
    ),
    titleLarge: TextStyle(
      fontFamily: defaultFontFamily,
      fontSize: 16.sp,
      fontWeight: FontWeight.bold,
      color: darkText,
    ),
    titleMedium: TextStyle(
      fontFamily: defaultFontFamily,
      fontSize: 14.sp,
      fontWeight: FontWeight.w600,
      color: darkText,
    ),
    titleSmall: TextStyle(
      fontFamily: defaultFontFamily,
      fontSize: 12.sp,
      fontWeight: FontWeight.w600,
      color: darkText,
    ),
    bodyLarge: TextStyle(
      fontFamily: defaultFontFamily,
      fontSize: 16.sp,
      fontWeight: FontWeight.normal,
      color: darkText,
    ),
    bodyMedium: TextStyle(
      fontFamily: defaultFontFamily,
      fontSize: 14.sp,
      fontWeight: FontWeight.normal,
      color: darkText,
    ),
    bodySmall: TextStyle(
      fontFamily: defaultFontFamily,
      fontSize: 12.sp,
      fontWeight: FontWeight.normal,
      color: darkText,
    ),
    labelLarge: TextStyle(
      fontFamily: defaultFontFamily,
      fontSize: 14.sp,
      fontWeight: FontWeight.w500,
      color: darkText,
    ),
    labelMedium: TextStyle(
      fontFamily: defaultFontFamily,
      fontSize: 12.sp,
      fontWeight: FontWeight.w500,
      color: darkText,
    ),
    labelSmall: TextStyle(
      fontFamily: defaultFontFamily,
      fontSize: 10.sp,
      fontWeight: FontWeight.w500,
      color: darkText,
    ),
  );

  // Dark Theme
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    fontFamily: defaultFontFamily, // Set default font
    scaffoldBackgroundColor: darkBackground,
    primaryColor: darkSurface,
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF6200EE),
      secondary: Color(0xFF03DAC6),
      surface: darkSurface,
      background: darkBackground,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: darkSurface,
      foregroundColor: darkText,
      elevation: 0,
      titleTextStyle: TextStyle(
        fontFamily: defaultFontFamily,
        fontSize: 20.sp,
        fontWeight: FontWeight.w600,
        color: darkText,
      ),
    ),
    textTheme: _darkTextTheme,
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: darkSurface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade700),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade700),
      ),
      hintStyle: TextStyle(
        fontFamily: defaultFontFamily,
        fontSize: 14.sp,
        color: darkTextSecondary,
      ),
      labelStyle: TextStyle(
        fontFamily: defaultFontFamily,
        fontSize: 14.sp,
        color: darkText,
      ),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: darkBottomNav,
      selectedItemColor: Colors.white,
      unselectedItemColor: Colors.grey,
      selectedLabelStyle: TextStyle(
        fontFamily: defaultFontFamily,
        fontSize: 12.sp,
        fontWeight: FontWeight.w500,
      ),
      unselectedLabelStyle: TextStyle(
        fontFamily: defaultFontFamily,
        fontSize: 12.sp,
        fontWeight: FontWeight.normal,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        textStyle: TextStyle(
          fontFamily: defaultFontFamily,
          fontSize: 16.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        textStyle: TextStyle(
          fontFamily: defaultFontFamily,
          fontSize: 14.sp,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
  );

  // Light Theme
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    fontFamily: defaultFontFamily, // Set default font
    scaffoldBackgroundColor: lightBackground,
    primaryColor: lightSurface,
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF6200EE),
      secondary: Color(0xFF03DAC6),
      surface: lightSurface,
      background: lightBackground,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: lightSurface,
      foregroundColor: lightText,
      elevation: 2,
      titleTextStyle: TextStyle(
        fontFamily: defaultFontFamily,
        fontSize: 20.sp,
        fontWeight: FontWeight.w600,
        color: lightText,
      ),
    ),
    textTheme: _lightTextTheme,
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      hintStyle: TextStyle(
        fontFamily: defaultFontFamily,
        fontSize: 14.sp,
        color: lightTextSecondary,
      ),
      labelStyle: TextStyle(
        fontFamily: defaultFontFamily,
        fontSize: 14.sp,
        color: lightText,
      ),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: lightBottomNav,
      selectedItemColor: const Color(0xFF1c1f23),
      unselectedItemColor: Colors.grey,
      selectedLabelStyle: TextStyle(
        fontFamily: defaultFontFamily,
        fontSize: 12.sp,
        fontWeight: FontWeight.w500,
      ),
      unselectedLabelStyle: TextStyle(
        fontFamily: defaultFontFamily,
        fontSize: 12.sp,
        fontWeight: FontWeight.normal,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        textStyle: TextStyle(
          fontFamily: defaultFontFamily,
          fontSize: 16.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        textStyle: TextStyle(
          fontFamily: defaultFontFamily,
          fontSize: 14.sp,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
  );

  // Helper method to get colors based on current theme
  static Color getBackgroundColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkBackground
        : lightBackground;
  }

  static Color getSurfaceColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkSurface
        : lightSurface;
  }

  static Color getTextColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkText
        : lightText;
  }

  static Color getBottomNavColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkBottomNav
        : lightBottomNav;
  }
}
