import 'package:flutter/material.dart';

const Color _seedColor = Color(0xFF00897B);

final ColorScheme _lightColorScheme =
    ColorScheme.fromSeed(seedColor: _seedColor, brightness: Brightness.light);
final ColorScheme _darkColorScheme =
    ColorScheme.fromSeed(seedColor: _seedColor, brightness: Brightness.dark);

final ThemeData lightTheme = ThemeData(
  useMaterial3: true,
  colorScheme: _lightColorScheme,
  scaffoldBackgroundColor: _lightColorScheme.surface,
  appBarTheme: AppBarTheme(
    backgroundColor: _lightColorScheme.surface,
    foregroundColor: _lightColorScheme.onSurface,
    elevation: 0,
    centerTitle: true,
    surfaceTintColor: Colors.transparent,
  ),
  textTheme: Typography.englishLike2021.apply(
    fontFamily: 'Cairo',
    bodyColor: _lightColorScheme.onSurface,
    displayColor: _lightColorScheme.onSurface,
  ),
  cardTheme: CardTheme(
    color: _lightColorScheme.surface,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
  ),
  floatingActionButtonTheme: FloatingActionButtonThemeData(
    backgroundColor: _lightColorScheme.primary,
    foregroundColor: _lightColorScheme.onPrimary,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    elevation: 2,
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      textStyle: const TextStyle(fontWeight: FontWeight.w600),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: _lightColorScheme.surfaceVariant.withOpacity(0.7),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide(color: _lightColorScheme.primary, width: 2),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    labelStyle: TextStyle(color: _lightColorScheme.onSurfaceVariant),
  ),
  snackBarTheme: SnackBarThemeData(
    behavior: SnackBarBehavior.floating,
    backgroundColor: _lightColorScheme.primaryContainer,
    contentTextStyle: TextStyle(color: _lightColorScheme.onPrimaryContainer),
  ),
  chipTheme: ChipThemeData(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    labelStyle: TextStyle(color: _lightColorScheme.onSurfaceVariant),
    backgroundColor: _lightColorScheme.surfaceVariant,
    selectedColor: _lightColorScheme.primaryContainer,
    secondarySelectedColor: _lightColorScheme.primaryContainer,
    disabledColor: _lightColorScheme.surfaceVariant.withOpacity(0.4),
    side: BorderSide.none,
  ),
);

final ThemeData darkTheme = ThemeData(
  useMaterial3: true,
  colorScheme: _darkColorScheme,
  scaffoldBackgroundColor: _darkColorScheme.surface,
  appBarTheme: AppBarTheme(
    backgroundColor: _darkColorScheme.surface,
    foregroundColor: _darkColorScheme.onSurface,
    elevation: 0,
    centerTitle: true,
    surfaceTintColor: Colors.transparent,
  ),
  textTheme: Typography.englishLike2021.apply(
    fontFamily: 'Cairo',
    bodyColor: _darkColorScheme.onSurface,
    displayColor: _darkColorScheme.onSurface,
  ),
  cardTheme: CardTheme(
    color: _darkColorScheme.surface,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
  ),
  floatingActionButtonTheme: FloatingActionButtonThemeData(
    backgroundColor: _darkColorScheme.primary,
    foregroundColor: _darkColorScheme.onPrimary,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    elevation: 2,
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      textStyle: const TextStyle(fontWeight: FontWeight.w600),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: _darkColorScheme.surfaceVariant.withOpacity(0.35),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide(color: _darkColorScheme.primary, width: 2),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    labelStyle: TextStyle(color: _darkColorScheme.onSurfaceVariant),
  ),
  snackBarTheme: SnackBarThemeData(
    behavior: SnackBarBehavior.floating,
    backgroundColor: _darkColorScheme.primaryContainer,
    contentTextStyle: TextStyle(color: _darkColorScheme.onPrimaryContainer),
  ),
  chipTheme: ChipThemeData(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    labelStyle: TextStyle(color: _darkColorScheme.onSurfaceVariant),
    backgroundColor: _darkColorScheme.surfaceVariant,
    selectedColor: _darkColorScheme.primaryContainer,
    secondarySelectedColor: _darkColorScheme.primaryContainer,
    disabledColor: _darkColorScheme.surfaceVariant.withOpacity(0.4),
    side: BorderSide.none,
  ),
);
