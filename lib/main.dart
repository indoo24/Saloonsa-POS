import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme.dart';
import 'screens/splash_screen.dart';
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final isDarkMode = prefs.getBool('isDarkMode') ?? false;
  runApp(SalonApp(initialDarkMode: isDarkMode));
}
class SalonApp extends StatefulWidget {
  final bool initialDarkMode;
  const SalonApp({super.key, required this.initialDarkMode});
  @override
  State<SalonApp> createState() => _SalonAppState();
}
class _SalonAppState extends State<SalonApp> {
  late bool isDarkMode;
  @override
  void initState() {
    super.initState();
    isDarkMode = widget.initialDarkMode;
  }
  Future<void> _toggleTheme() async {
    setState(() => isDarkMode = !isDarkMode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', isDarkMode);
  }
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Salon POS',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: SplashScreen(onToggleTheme: _toggleTheme),
    );
  }
}