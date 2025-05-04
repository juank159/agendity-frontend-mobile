import 'package:flutter/material.dart';

class ThemeConfig {
  // Tema claro
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      primarySwatch: Colors.blue,
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
        titleTextStyle: TextStyle(
          color: Colors.black,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: const CardTheme(
        color: Colors.white,
        shadowColor: Colors.black12,
      ),
      iconTheme: const IconThemeData(
        color: Colors.black87,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Colors.black87),
        bodyMedium: TextStyle(color: Colors.black87),
        titleLarge: TextStyle(color: Colors.black),
      ),
      buttonTheme: ButtonThemeData(
        buttonColor: Colors.blue,
        textTheme: ButtonTextTheme.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      colorScheme: ColorScheme.light(
        primary: Colors.blue,
        secondary: Colors.blue.shade700,
        surface: Colors.white,
        background: Colors.grey.shade50,
        error: Colors.red,
      ),
      // Continúa personalizando según necesites
    );
  }

  // Tema oscuro
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primarySwatch: Colors.blue,
      scaffoldBackgroundColor: Colors.grey[900],
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.grey[850],
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardTheme(
        color: Colors.grey[850],
        shadowColor: Colors.black45,
      ),
      iconTheme: const IconThemeData(
        color: Colors.white70,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Colors.white70),
        bodyMedium: TextStyle(color: Colors.white70),
        titleLarge: TextStyle(color: Colors.white),
      ),
      buttonTheme: ButtonThemeData(
        buttonColor: Colors.blueAccent,
        textTheme: ButtonTextTheme.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      colorScheme: ColorScheme.dark(
        primary: Colors.blue,
        secondary: Colors.blue.shade300,
        surface: Colors.grey[850]!,
        background: Colors.grey[900]!,
        error: Colors.redAccent,
      ),
      // Personaliza según necesites
    );
  }

  // Tema adicional (ejemplo: modo alto contraste)
  static ThemeData get highContrastTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primarySwatch: Colors.yellow,
      scaffoldBackgroundColor: Colors.black,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.yellow),
        titleTextStyle: TextStyle(
          color: Colors.yellow,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: const CardTheme(
        color: Colors.black,
        shadowColor: Colors.yellowAccent,
      ),
      iconTheme: const IconThemeData(
        color: Colors.yellow,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Colors.white),
        bodyMedium: TextStyle(color: Colors.white),
        titleLarge: TextStyle(color: Colors.yellow),
      ),
      colorScheme: const ColorScheme.dark(
        primary: Colors.yellow,
        secondary: Colors.yellowAccent,
        surface: Colors.black,
        background: Colors.black,
        error: Colors.red,
      ),
    );
  }
}
