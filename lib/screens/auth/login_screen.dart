import 'package:barber_casher/screens/casher/casher_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;


  const LoginScreen({super.key, required this.onToggleTheme});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {

  final _formKey = GlobalKey<FormState>();
  bool _isPasswordObscured = true;

  // Controllers for text fields
  final _subdomainController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _subdomainController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() {
    if (_formKey.currentState!.validate()) {
      // TODO: Implement login API logic here
      // final subdomain = _subdomainController.text;
      // final username = _usernameController.text;
      // final password = _passwordController.text;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Logging in...')),
      );
    }
  }

  void _continueAsGuest() {

    // TODO: Implement guest navigation logic
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Continuing as guest...')),
    );
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => CashierScreen(onToggleTheme: widget.onToggleTheme)));
  }

  @override
  Widget build(BuildContext context) {

    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // App Logo
                  Icon(
                    Icons.shield_moon_outlined,
                    size: 80,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'مرحباً بك مجدداً',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cairo(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'سجل الدخول للمتابعة',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 32),

                  // Subdomain Field
                  TextFormField(
                    controller: _subdomainController,
                    decoration: InputDecoration(
                      labelText: 'النطاق الفرعي',
                      prefixText: 'https://',
                      suffixText: '.saloonsa.com',
                      border: const OutlineInputBorder(),
                      prefixStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6)),
                      suffixStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6)),
                    ),
                    keyboardType: TextInputType.text,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'الرجاء إدخال النطاق الفرعي';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Username Field
                  TextFormField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: 'اسم المستخدم أو البريد الإلكتروني',
                      prefixIcon: Icon(Icons.person_outline),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'الرجاء إدخال اسم المستخدم';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Password Field
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _isPasswordObscured,
                    decoration: InputDecoration(
                      labelText: 'كلمة المرور',
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordObscured ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordObscured = !_isPasswordObscured;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'الرجاء إدخال كلمة المرور';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 30),

                  // Login Button
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    onPressed: _login,
                    child: const Text('تسجيل الدخول'),
                  ),
                  const SizedBox(height: 16),

                  // Continue as Guest Button
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold),
                      side: BorderSide(color: theme.colorScheme.primary),
                    ),
                    onPressed: _continueAsGuest,
                    child: const Text('المتابعة كزائر'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
