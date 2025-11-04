import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget {
  final void Function(String userName, bool rememberMe) onLogin;
  final VoidCallback onToggleTheme;
  final String? initialUserName;
  final bool rememberMe;

  const LoginPage({
    super.key,
    required this.onLogin,
    required this.onToggleTheme,
    this.initialUserName,
    this.rememberMe = false,
  });

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _passwordController;
  bool _rememberMe = false;
  bool _isPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialUserName ?? '');
    _passwordController = TextEditingController();
    _rememberMe = widget.rememberMe;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      widget.onLogin(_nameController.text.trim(), _rememberMe);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 720;

            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isWide ? 520 : constraints.maxWidth,
                  ),
                  child: Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    color: colorScheme.surfaceVariant.withOpacity(0.6),
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'مرحبا بعودتك',
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineSmall
                                          ?.copyWith(fontWeight: FontWeight.w700),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'سجل دخولك لإدارة فواتير الصالون',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                    ),
                                  ],
                                ),
                                IconButton(
                                  onPressed: widget.onToggleTheme,
                                  tooltip: Theme.of(context).brightness == Brightness.dark
                                      ? 'الوضع الفاتح'
                                      : 'الوضع الداكن',
                                  icon: Icon(
                                    Theme.of(context).brightness == Brightness.dark
                                        ? Icons.light_mode
                                        : Icons.dark_mode,
                                  ),
                                )
                              ],
                            ),
                            const SizedBox(height: 32),
                            TextFormField(
                              controller: _nameController,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                labelText: 'اسم المستخدم',
                                prefixIcon: Icon(Icons.person_outline),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'يرجى إدخال اسم المستخدم';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: !_isPasswordVisible,
                              decoration: InputDecoration(
                                labelText: 'كلمة المرور',
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _isPasswordVisible
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                  ),
                                  onPressed: () => setState(
                                    () => _isPasswordVisible = !_isPasswordVisible,
                                  ),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'يرجى إدخال كلمة المرور';
                                }
                                if (value.trim().length < 4) {
                                  return 'كلمة المرور يجب أن تتكون من 4 أحرف على الأقل';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Switch(
                                  value: _rememberMe,
                                  onChanged: (value) => setState(() => _rememberMe = value),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'تذكرني في هذا الجهاز',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(color: colorScheme.onSurfaceVariant),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed: _submit,
                                icon: const Icon(Icons.login_rounded),
                                label: const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                  child: Text('تسجيل الدخول'),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
