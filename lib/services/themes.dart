import 'package:flutter/material.dart';


// This class organises all theme parameters.
class Themes {
  static bool isDarkMode = false;
  static bool showItemCount = true;

  // Light theme
  static final ThemeData _themeLight = ThemeData.light().copyWith(
    scaffoldBackgroundColor: Colors.blueGrey[50],
    inputDecorationTheme: const InputDecorationTheme(
      fillColor: Colors.white,
    ),
  );

  // Dark theme
  static final ThemeData _themeDark = ThemeData.dark().copyWith(
    snackBarTheme: SnackBarThemeData(
      backgroundColor: Colors.grey[900],
      contentTextStyle: const TextStyle(
        color: Colors.white,
      ),
    ),
    colorScheme: ColorScheme.fromSwatch().copyWith(
      secondary: Colors.blue,
    ),
    textSelectionTheme: const TextSelectionThemeData(
      selectionColor: Colors.blue,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Colors.blue,
      foregroundColor: Colors.white,
    ),
  );


  // Toggles dark mode on or off.
  static void toggleDarkMode()
  { isDarkMode = !isDarkMode; }


  // Toggles item count on or off.
  static void toggleItemCount()
  { showItemCount = !showItemCount; }


  // Returns the appropriate heading color for the drawer, depending on isDarkMode.
  static dynamic getHeadingColor()
  { return isDarkMode ? Colors.grey[400] : Colors.grey[600]; }


  // Returns the appropriate positive color, depending on isDarkMode.
  static dynamic getPositiveColor()
  { return isDarkMode ? Colors.green[700] : Colors.green; }


  // Returns the appropriate neutral color, depending on isDarkMode.
  static dynamic getNeutralColor()
  { return isDarkMode ? Colors.blue[700] : Colors.blue; }


  // Returns the appropriate negative color, depending on isDarkMode.
  static dynamic getNegativeColor()
  { return isDarkMode ? Colors.red[900] : Colors.red; }


  // Returns either light or dark theme, depending on isDarkMode.
  static ThemeData getTheme()
  { return isDarkMode ? _themeDark : _themeLight; }


}