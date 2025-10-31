import 'package:flutter/material.dart';

const Color brandGold = Color(0xFFFFC107); // الذهبي الأساسي
const Color brandDark = Color(0xFF212121);

final lightTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.light(
    primary: brandGold,
    secondary: Colors.blueGrey.shade700,
    surface: Colors.white,
    onPrimary: Colors.black,
    onSurface: Colors.black87,
  ),
  scaffoldBackgroundColor: const Color(0xFFF9F9F9),
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.white,
    foregroundColor: Colors.black,
    elevation: 1,
    centerTitle: true,
  ),
  cardTheme: CardThemeData(
    color: Colors.white,
    elevation: 2,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  ),
  textTheme: const TextTheme(
    bodyMedium: TextStyle(fontFamily: 'Cairo'),
    titleMedium: TextStyle(fontWeight: FontWeight.bold),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: brandGold,
      foregroundColor: Colors.black,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
  ),
);

final darkTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  colorScheme: ColorScheme.dark(
    primary: brandGold,
    secondary: Colors.blueGrey.shade200,
    surface: brandDark,
    onPrimary: Colors.black,
    onSurface: Colors.white,
  ),
  scaffoldBackgroundColor: const Color(0xFF121212),
  appBarTheme: const AppBarTheme(
    backgroundColor: brandDark,
    foregroundColor: Colors.white,
    centerTitle: true,
  ),
  cardTheme: CardThemeData(
    color: brandDark,
    elevation: 2,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: brandGold,
      foregroundColor: Colors.black,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
  ),
);
