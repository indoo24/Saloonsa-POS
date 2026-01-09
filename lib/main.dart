import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/error/error_handler.dart';
import 'theme.dart';
import 'screens/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/casher/casher_screen.dart';
import 'screens/setup/app_setup_screen.dart';
import 'cubits/auth/auth_cubit.dart';
import 'cubits/auth/auth_state.dart';
import 'cubits/cashier/cashier_cubit.dart';
import 'cubits/printer/printer_cubit.dart';
import 'cubits/settings/settings_cubit.dart';
import 'repositories/auth_repository.dart';
import 'repositories/cashier_repository.dart';
import 'services/app_setup_service.dart';
import 'widgets/validation_blocker_dialog.dart';

Future<void> main() async {
  // Initialize error handling BEFORE anything else
  WidgetsFlutterBinding.ensureInitialized();

  // Run app with global error handling
  await GlobalErrorHandler.runAppWithErrorHandling(await _buildApp());
}

Future<Widget> _buildApp() async {
  final prefs = await SharedPreferences.getInstance();
  final isDarkMode = prefs.getBool('isDarkMode') ?? false;
  final subdomain = prefs.getString('subdomain');

  // Check if first-launch setup is completed
  final setupService = AppSetupService();
  final setupCompleted = await setupService.isSetupCompleted();

  return SalonApp(
    initialDarkMode: isDarkMode,
    subdomain: subdomain,
    requiresSetup: !setupCompleted,
  );
}

class SalonApp extends StatefulWidget {
  final bool initialDarkMode;
  final String? subdomain;
  final bool requiresSetup;

  const SalonApp({
    super.key,
    required this.initialDarkMode,
    this.subdomain,
    this.requiresSetup = false,
  });

  @override
  State<SalonApp> createState() => _SalonAppState();
}

class _SalonAppState extends State<SalonApp> {
  late bool isDarkMode;
  late bool requiresSetup;
  final AppSetupService _setupService = AppSetupService();
  ValidationResult? _validationResult;

  @override
  void initState() {
    super.initState();
    isDarkMode = widget.initialDarkMode;
    requiresSetup = widget.requiresSetup;

    // If setup is complete, perform validation on launch
    if (!requiresSetup) {
      _performStartupValidation();
    }
  }

  Future<void> _toggleTheme() async {
    setState(() => isDarkMode = !isDarkMode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', isDarkMode);
  }

  /// Perform validation check on every app launch
  Future<void> _performStartupValidation() async {
    final validation = await _setupService.performValidation();

    if (!validation.isValid && mounted) {
      setState(() {
        _validationResult = validation;
      });
      _showValidationDialog();
    }
  }

  /// Show non-dismissible validation dialog
  void _showValidationDialog() {
    if (_validationResult == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ValidationBlockerDialog(
        validationResult: _validationResult!,
        onRetryValidation: () {
          Navigator.of(context).pop();
          _performStartupValidation();
        },
      ),
    );
  }

  /// Called when setup is completed
  void _onSetupComplete() {
    setState(() {
      requiresSetup = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Step 1: Provide repositories to entire app
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(create: (context) => AuthRepository()),
        RepositoryProvider(create: (context) => CashierRepository()),
      ],
      child: MultiBlocProvider(
        // Step 2: Provide cubits to entire app
        providers: [
          BlocProvider(
            create: (context) =>
                AuthCubit(repository: context.read<AuthRepository>())
                  ..checkAuthStatus(), // Check if user is already logged in
          ),
          BlocProvider(
            create: (context) =>
                CashierCubit(repository: context.read<CashierRepository>()),
          ),
          BlocProvider(
            create: (context) =>
                PrinterCubit()..initialize(), // Auto-reconnect to printer
          ),
          BlocProvider(
            create: (context) =>
                SettingsCubit()..loadSettings(), // Load app settings on startup
          ),
        ],
        child: MaterialApp(
          title: 'Salon POS',
          debugShowCheckedModeBanner: false,
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
          // Add localization support
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en', ''), // English
            Locale('ar', ''), // Arabic
          ],
          // Step 3: Use BlocBuilder to decide which screen to show
          // This automatically switches screens based on authentication state
          home: requiresSetup
              ? AppSetupScreen(onSetupComplete: _onSetupComplete)
              : BlocBuilder<AuthCubit, AuthState>(
                  builder: (context, state) {
                    // Show splash screen while checking if user is logged in
                    if (state is AuthChecking) {
                      return SplashScreen(
                        onToggleTheme: _toggleTheme,
                        subdomain: widget.subdomain,
                      );
                    }
                    // User is authenticated - show cashier screen
                    else if (state is AuthAuthenticated) {
                      return CashierScreen(onToggleTheme: _toggleTheme);
                    }
                    // User not authenticated - show login screen
                    else {
                      return LoginScreen(
                        onToggleTheme: _toggleTheme,
                        subdomain: widget.subdomain,
                      );
                    }
                  },
                ),
        ),
      ),
    );
  }
}
