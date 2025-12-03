import 'package:flutter/material.dart';

class AppTheme {
  // Design Palette matching your screenshots
  static const Color background = Color(0xFF000000); // Pure Black
  static const Color scaffoldBackground = Color(0xFF000000);
  static const Color cardColor = Color(0xFF1C1C1E); // Dark Grey for elements
  static const Color surface = Color(0xFF1C1C1E);
  static const Color accentRed = Color(0xFFFF3B30); // The Signature Red
  static const Color softGrey = Color(0xFF9A9A9A);

  static ThemeData dark() {
    final base = ThemeData.dark();
    return base.copyWith(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: scaffoldBackground,
      primaryColor: accentRed,
      cardColor: cardColor,
      canvasColor: cardColor,
      dialogBackgroundColor: cardColor,

      // Color Scheme
      colorScheme: base.colorScheme.copyWith(
        primary: accentRed,
        secondary: accentRed,
        surface: surface,
        background: background,
        onSurface: Colors.white,
      ),

      // AppBar Theme (Flat Black)
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20.0,
          fontWeight: FontWeight.bold,
        ),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
        ),
      ),

      // 🔥 FIXED: DialogTheme → DialogThemeData
      dialogTheme: DialogThemeData(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        contentTextStyle: TextStyle(color: Colors.grey[400]),
      ),

      // Floating Action Button Theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accentRed,
        foregroundColor: Colors.white,
        elevation: 4,
      ),

      // Bottom Navigation Theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: background,
        selectedItemColor: accentRed,
        unselectedItemColor: softGrey,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
      ),

      // Text Theme
      textTheme: base.textTheme
          .apply(bodyColor: Colors.white, displayColor: Colors.white)
          .copyWith(
            titleLarge: TextStyle(
              fontSize: 22.0,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            titleMedium: TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            titleSmall: TextStyle(
              fontSize: 14.0,
              fontWeight: FontWeight.w600,
              color: softGrey,
            ),
            bodyMedium: TextStyle(fontSize: 14.0, color: Colors.grey[400]),
            bodyLarge: TextStyle(fontSize: 16.0, color: Colors.white),
          ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardColor,
        hintStyle: TextStyle(color: Colors.grey[600]),
        prefixIconColor: Colors.grey[600],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15.0),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15.0),
          borderSide: BorderSide(color: accentRed, width: 1.5),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      ),

      // Text Selection Theme
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: accentRed,
        selectionColor: accentRed.withOpacity(0.3),
        selectionHandleColor: accentRed,
      ),
    );
  }
}
