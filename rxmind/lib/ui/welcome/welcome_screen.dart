import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../constants/animations.dart';
import '../../components/parallax_background.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _logoOpacity;
  late Animation<Offset> _logoOffset;

  @override
  void initState() {
    super.initState();
    _checkOnboarding();
    _controller = AnimationController(
      vsync: this,
      duration: AnimationConstants.fadeDuration,
    );
    _logoOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    _logoOffset =
        Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.forward();
  }

  Future<void> _checkOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    final done = prefs.getBool('onboarding_complete') ?? false;
    if (done && mounted) {
      Future.microtask(
          () => Navigator.of(context).pushReplacementNamed('/main'));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: ParallaxBackground(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SlideTransition(
                position: _logoOffset,
                child: FadeTransition(
                  opacity: _logoOpacity,
                  child: Column(
                    children: [
                      // TODO: Replace with animated app logo
                      Icon(Icons.local_hospital,
                          size: 96, color: theme.colorScheme.primary),
                      const SizedBox(height: 24),
                      Text(
                        'Your health, organized simply.',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 48),
              TweenAnimationBuilder<double>(
                tween:
                    Tween(begin: 1.0, end: AnimationConstants.buttonPulseScale),
                duration: AnimationConstants.buttonPulseDuration,
                curve: Curves.easeInOut,
                builder: (context, scale, child) {
                  return Transform.scale(
                    scale: scale,
                    child: child,
                  );
                },
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(32)),
                    backgroundColor: theme.colorScheme.primary,
                    shadowColor: theme.colorScheme.primary
                        .withAlpha((0.4 * 255).toInt()),
                    elevation: 8,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 48, vertical: 18),
                  ),
                  onPressed: () async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('onboarding_complete', false);
                    context.go('/info');
                  },
                  child: const Text(
                    'Get Started',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.2),
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
