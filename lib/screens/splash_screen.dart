import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final VoidCallback onFinished;

  const SplashScreen({
    super.key,
    required this.onToggleTheme,
    required this.onFinished,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);

    _controller.forward();

    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      widget.onFinished();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              colorScheme.primaryContainer.withOpacity(0.9),
              colorScheme.primary,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  icon: Icon(
                    Theme.of(context).brightness == Brightness.dark
                        ? Icons.light_mode
                        : Icons.dark_mode,
                    color: colorScheme.onPrimary,
                  ),
                  tooltip: Theme.of(context).brightness == Brightness.dark
                      ? 'الوضع الفاتح'
                      : 'الوضع الداكن',
                  onPressed: widget.onToggleTheme,
                ),
              ),
              FadeTransition(
                opacity: _fadeIn,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.cut, size: 100, color: colorScheme.onPrimary),
                      const SizedBox(height: 20),
                      Text(
                        'Salon POS',
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: colorScheme.onPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'by Yousef',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                              color: colorScheme.onPrimary.withOpacity(0.85),
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
