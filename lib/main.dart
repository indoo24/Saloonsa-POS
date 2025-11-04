import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/auth/login_page.dart';
import 'screens/casher/home_page.dart';
import 'screens/splash_screen.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final isDarkMode = prefs.getBool('isDarkMode') ?? false;
  final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
  final savedUserName = prefs.getString('userName');
  final rememberMe = prefs.getBool('rememberMe') ?? false;

  runApp(
    SalonApp(
      initialDarkMode: isDarkMode,
      initialLoggedIn: isLoggedIn,
      initialUserName: savedUserName,
      initialRememberMe: rememberMe,
    ),
  );
}

class SalonApp extends StatefulWidget {
  final bool initialDarkMode;
  final bool initialLoggedIn;
  final String? initialUserName;
  final bool initialRememberMe;

  const SalonApp({
    super.key,
    required this.initialDarkMode,
    required this.initialLoggedIn,
    required this.initialUserName,
    required this.initialRememberMe,
  });

  @override
  State<SalonApp> createState() => _SalonAppState();
}

class _SalonAppState extends State<SalonApp> {
  late bool isDarkMode;
  late bool isLoggedIn;
  String? userName;
  bool rememberMe = false;
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    isDarkMode = widget.initialDarkMode;
    isLoggedIn = widget.initialLoggedIn;
    userName = widget.initialUserName;
    rememberMe = widget.initialRememberMe;
  }

  Future<void> _toggleTheme() async {
    setState(() => isDarkMode = !isDarkMode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', isDarkMode);
  }

  Future<void> _handleLogin(String name, bool rememberSelection) async {
    setState(() {
      isLoggedIn = true;
      userName = name;
      rememberMe = rememberSelection;
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userName', name);
    await prefs.setBool('rememberMe', rememberSelection);

    if (rememberSelection) {
      await prefs.setBool('isLoggedIn', true);
    } else {
      await prefs.remove('isLoggedIn');
    }
  }

  Future<void> _handleLogout() async {
    setState(() {
      isLoggedIn = false;
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('rememberMe', rememberMe);
    await prefs.remove('isLoggedIn');
  }

  void _onSplashFinished() {
    if (!mounted) return;
    setState(() => _showSplash = false);
  }

  @override
  Widget build(BuildContext context) {
    final home = _showSplash
        ? SplashScreen(
            onToggleTheme: _toggleTheme,
            onFinished: _onSplashFinished,
          )
        : isLoggedIn
            ? HomePage(
                onToggleTheme: _toggleTheme,
                onLogout: _handleLogout,
                userName: userName,
              )
            : LoginPage(
                onToggleTheme: _toggleTheme,
                onLogin: _handleLogin,
                initialUserName: userName,
                rememberMe: rememberMe,
              );

    return MaterialApp(
      title: 'Salon POS',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: home,
    );
  }
}
