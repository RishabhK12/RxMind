import 'package:flutter/material.dart';
import 'package:rxmind_app/services/discharge_data_manager.dart';

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
      final profileData = await DischargeDataManager.loadProfileData();
      final name = profileData['name'];
      if (name != null && name.isNotEmpty) {
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
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Semantics(
          label: 'Loading RxMind',
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.98, end: 1.12).animate(
                CurvedAnimation(parent: _controller, curve: Curves.easeOut)),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Container(
                width: MediaQuery.of(context).size.width * 0.55,
                height: MediaQuery.of(context).size.width * 0.55,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    'RxMind',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
