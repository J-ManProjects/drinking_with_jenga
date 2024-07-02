import 'package:flutter/material.dart';

// This class organises all theme parameters.
class Themes {
  static bool isDarkMode = false;
  static bool showItemCount = true;

  // Light theme
  static final ThemeData _themeLight = ThemeData.light().copyWith(
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.blue[700],
      iconTheme: const IconThemeData(
        color: Colors.white,
      ),
      titleTextStyle: const TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      shape: ContinuousRectangleBorder(),
    ),
    colorScheme: ColorScheme.fromSwatch().copyWith(
      secondary: Colors.blue[700],
    ),
    dividerTheme: DividerThemeData(
      color: Colors.grey[200],
    ),
    drawerTheme: const DrawerThemeData(
      shape: ContinuousRectangleBorder(),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(2.0)),
        ),
        padding: const EdgeInsets.symmetric(
          vertical: 8.0,
          horizontal: 12.0,
        ),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: Colors.blue[700],
      foregroundColor: Colors.white,
      shape: const CircleBorder(),
    ),
    inputDecorationTheme: InputDecorationTheme(
      fillColor: Colors.white,
      hintStyle: TextStyle(
        color: Colors.grey[700],
      ),
      prefixIconColor: Colors.grey[700],
      suffixIconColor: Colors.grey[700],
    ),
    iconTheme: const IconThemeData(
      color: Colors.grey,
    ),
    listTileTheme: ListTileThemeData(
      iconColor: Colors.grey[700],
    ),
    scaffoldBackgroundColor: Colors.blueGrey[50],
    snackBarTheme: SnackBarThemeData(
      backgroundColor: Colors.grey[800],
      contentTextStyle: const TextStyle(
        color: Colors.white,
      ),
    ),
    textSelectionTheme: TextSelectionThemeData(
      selectionColor: Colors.blue[700],
      cursorColor: Colors.blue[700],
    ),
  );

  // Dark theme
  static final ThemeData _themeDark = ThemeData.dark().copyWith(
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.grey[850],
      iconTheme: const IconThemeData(
        color: Colors.white,
      ),
      titleTextStyle: const TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: Colors.grey[800],
      shape: const ContinuousRectangleBorder(),
    ),
    colorScheme: ColorScheme.fromSwatch().copyWith(
      secondary: Colors.blue,
    ),
    dialogBackgroundColor: Colors.grey[800],
    dividerTheme: DividerThemeData(
      color: Colors.grey[700],
    ),
    drawerTheme: const DrawerThemeData(
      backgroundColor: Color(0xFF515151),
      shape: ContinuousRectangleBorder(),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        disabledBackgroundColor: const Color(0xFF515151),
        iconColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(2.0)),
        ),
        padding: const EdgeInsets.symmetric(
          vertical: 8.0,
          horizontal: 12.0,
        ),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Colors.blue,
      foregroundColor: Colors.white,
      shape: CircleBorder(),
    ),
    inputDecorationTheme: InputDecorationTheme(
      fillColor: Colors.grey[800],
      hintStyle: TextStyle(
        color: Colors.grey[400],
      ),
      prefixIconColor: Colors.grey[400],
      suffixIconColor: Colors.grey[400],
    ),
    listTileTheme: const ListTileThemeData(
      iconColor: Colors.white,
      tileColor: Color(0xFF515151),
      textColor: Colors.white,
    ),
    scaffoldBackgroundColor: const Color(0xFF3A3A3A),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: Colors.grey[800],
      contentTextStyle: const TextStyle(
        color: Colors.white,
      ),
    ),
    textSelectionTheme: const TextSelectionThemeData(
      selectionColor: Colors.blue,
      cursorColor: Colors.blue,
    ),
    textTheme: const TextTheme().apply(
      bodyColor: Colors.white,
    ),
  );

  // Toggles dark mode on or off.
  static void toggleDarkMode() {
    isDarkMode = !isDarkMode;
  }

  // Toggles item count on or off.
  static void toggleItemCount() {
    showItemCount = !showItemCount;
  }

  // Returns the appropriate heading color for the drawer, depending on isDarkMode.
  static dynamic getHeadingColor() {
    return isDarkMode ? Colors.grey[400] : Colors.grey[800];
  }

  // Returns the appropriate input form fill color, depending on isDarkMode.
  static dynamic getFormFillColor() {
    return isDarkMode ? const Color(0xFF515151) : Colors.white;
  }

  // Returns the appropriate positive color, depending on isDarkMode.
  static dynamic getPositiveColor() {
    return isDarkMode ? Colors.green[700] : Colors.green;
  }

  // Returns the appropriate neutral color, depending on isDarkMode.
  static dynamic getNeutralColor() {
    return isDarkMode ? Colors.blue[700] : Colors.blue;
  }

  // Returns the appropriate negative color, depending on isDarkMode.
  static dynamic getNegativeColor() {
    return isDarkMode ? Colors.red[900] : Colors.red;
  }

  // Returns either light or dark theme, depending on isDarkMode.
  static ThemeData getTheme() {
    return isDarkMode ? _themeDark : _themeLight;
  }

}
