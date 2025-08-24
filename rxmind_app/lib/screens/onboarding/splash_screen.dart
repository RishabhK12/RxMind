import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));
    _controller.forward();
    Future.delayed(const Duration(milliseconds: 1200), () async {
      if (!mounted) return;
      final prefs = await SharedPreferences.getInstance();
      final complete = prefs.getBool('onboardingComplete') ?? false;
      if (complete) {
        Navigator.pushReplacementNamed(context, '/mainNav');
      } else {
        Navigator.pushReplacementNamed(context, '/welcomeCarousel');
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Semantics(
          label: 'Loading Discharge Assistant',
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.98, end: 1.12).animate(
                CurvedAnimation(parent: _controller, curve: Curves.easeOut)),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SvgPicture.asset(
                'assets/illus/logo.svg',
                width: MediaQuery.of(context).size.width * 0.55,
                height: MediaQuery.of(context).size.width * 0.55,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
