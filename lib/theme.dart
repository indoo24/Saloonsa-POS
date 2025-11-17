import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const Color brandGold = Color(0xFFFFC107);
const Color brandBlue = Color(0xFF004D74);
const Color lightGray = Color(0xFFF0F0F0);
const Color darkGray = Color(0xFF1E1E1E);

final lightColorScheme = ColorScheme.fromSeed(
  seedColor: brandBlue,
  brightness: Brightness.light,
  primary: brandBlue,
  secondary: brandGold,
  background: lightGray,
  surface: Colors.white,
  onPrimary: Colors.white,
  onSecondary: Colors.black,
  onBackground: Colors.black,
  onSurface: Colors.black,
);

final darkColorScheme = ColorScheme.fromSeed(
  seedColor: brandBlue,
  brightness: Brightness.dark,
  primary: brandBlue,
  secondary: brandGold,
  background: const Color(0xFF121212),
  surface: darkGray,
  onPrimary: Colors.white,
  onSecondary: Colors.black,
  onBackground: Colors.white,
  onSurface: Colors.white,
);

final lightTheme = ThemeData(
  useMaterial3: true,
  colorScheme: lightColorScheme,
  scaffoldBackgroundColor: lightColorScheme.background,
  appBarTheme: AppBarTheme(
    backgroundColor: lightColorScheme.surface,
    foregroundColor: lightColorScheme.onSurface,
    elevation: 0,
    centerTitle: true,
    titleTextStyle: GoogleFonts.cairo(
      fontWeight: FontWeight.bold,
      fontSize: 20,
      color: lightColorScheme.onSurface,
    ),
  ),
  cardTheme: CardThemeData(
    color: lightColorScheme.surface,
    elevation: 4,
    shadowColor: Colors.black.withOpacity(0.1),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  ),
  textTheme: TextTheme(
    bodyMedium: GoogleFonts.cairo(color: lightColorScheme.onSurface),
    titleMedium: GoogleFonts.cairo(fontWeight: FontWeight.bold),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: brandGold,
      foregroundColor: Colors.black,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.symmetric(vertical: 16),
      textStyle: GoogleFonts.cairo(fontWeight: FontWeight.bold),
    ),
  ),
  iconTheme: IconThemeData(color: lightColorScheme.onSurface),
);

final darkTheme = ThemeData(
  useMaterial3: true,
  colorScheme: darkColorScheme,
  scaffoldBackgroundColor: darkColorScheme.background,
  appBarTheme: AppBarTheme(
    backgroundColor: darkColorScheme.surface,
    foregroundColor: darkColorScheme.onSurface,
    elevation: 0,
    centerTitle: true,
    titleTextStyle: GoogleFonts.cairo(
      fontWeight: FontWeight.bold,
      fontSize: 20,
      color: darkColorScheme.onSurface,
    ),
  ),
  cardTheme: CardThemeData(
    color: darkColorScheme.surface,
    elevation: 4,
    shadowColor: Colors.black.withOpacity(0.2),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  ),
  textTheme: TextTheme(
    bodyMedium: GoogleFonts.cairo(color: darkColorScheme.onSurface),
    titleMedium: GoogleFonts.cairo(fontWeight: FontWeight.bold),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: brandGold,
      foregroundColor: Colors.black,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.symmetric(vertical: 16),
      textStyle: GoogleFonts.cairo(fontWeight: FontWeight.bold),
    ),
  ),
  iconTheme: IconThemeData(color: darkColorScheme.onSurface),
);
