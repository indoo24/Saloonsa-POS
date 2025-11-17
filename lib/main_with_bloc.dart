import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'screens/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/casher/casher_screen.dart';
import 'theme.dart';
import 'cubits/auth/auth_cubit.dart';
import 'cubits/auth/auth_state.dart';
import 'cubits/cashier/cashier_cubit.dart';
import 'repositories/auth_repository.dart';
import 'repositories/cashier_repository.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.light;

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      // STEP 1: Provide repositories to entire app
      // Repositories handle data fetching and business logic
      providers: [
        RepositoryProvider(create: (context) => AuthRepository()),
        RepositoryProvider(create: (context) => CashierRepository()),
      ],
      child: MultiBlocProvider(
        // STEP 2: Provide cubits to entire app
        // Cubits manage state for different features
        providers: [
          BlocProvider(
            create: (context) => AuthCubit(
              repository: context.read<AuthRepository>(),
            )..checkAuthStatus(), // Check if user is already logged in
          ),
          BlocProvider(
            create: (context) => CashierCubit(
              repository: context.read<CashierRepository>(),
            ),
          ),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Barber Cashier',
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: _themeMode,
          
          // STEP 3: Use BlocBuilder to decide which screen to show
          // This automatically switches screens based on authentication state
          // No need for manual navigation!
          home: BlocBuilder<AuthCubit, AuthState>(
            builder: (context, state) {
              // Show splash screen while checking if user is logged in
              if (state is AuthChecking) {
                return SplashScreen(onToggleTheme: _toggleTheme);
              } 
              // User is authenticated - show cashier screen
              else if (state is AuthAuthenticated) {
                return CashierScreen(onToggleTheme: _toggleTheme);
              } 
              // User not authenticated - show login screen
              else {
                return LoginScreen(onToggleTheme: _toggleTheme);
              }
            },
          ),
        ),
      ),
    );
  }
}
