import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:rxmind_app/core/storage/local_storage.dart';
import 'package:rxmind_app/services/discharge_data_manager.dart';
import 'package:rxmind_app/theme/theme_tokens.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  bool _reduceMotion = false;
  bool _started = false;

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
    Future.delayed(const Duration(milliseconds: 1200), _navigateNext);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (_started) return;
    _started = true;
    if (_reduceMotion) {
      _controller.value = 1.0;
    } else {
      _controller.forward();
    }
  }

  Future<void> _navigateNext() async {
    if (!mounted) return;

    final disclaimerAcked = await LocalStorage.isDisclaimerAcknowledged();
    final chdConsent = await LocalStorage.hasChdConsent();

    if (!disclaimerAcked || !chdConsent) {
      final initialStep = !disclaimerAcked
          ? 0
          : !chdConsent
              ? 2
              : 0;
      if (!mounted) return;
      Navigator.pushReplacementNamed(
        context,
        '/onboarding',
        arguments: initialStep,
      );
      return;
    }

    final profileData = await DischargeDataManager.loadProfileData();
    final name = profileData['name'];
    if (name != null && (name as String).isNotEmpty) {
      Navigator.pushReplacementNamed(context, '/mainNav');
    } else {
      Navigator.pushReplacementNamed(context, '/welcomeCarousel');
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
    final brandedLogo = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.asset(
          'assets/illus/logo.svg',
          width: MediaQuery.of(context).size.width * 0.45,
          colorFilter: ColorFilter.mode(
            theme.colorScheme.primary,
            BlendMode.srcIn,
          ),
          semanticsLabel: 'rxmind logo',
          errorBuilder: (context, error, stackTrace) {
            return Icon(
              Icons.medical_services_rounded,
              size: 80,
              color: theme.colorScheme.primary,
            );
          },
        ),
        const SizedBox(height: ThemeTokens.spacingMd),
        Text(
          'rxmind',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontFamily: ThemeTokens.fontFamily,
            fontWeight: FontWeight.w800,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ],
    );

    final Widget content = _reduceMotion
        ? brandedLogo
        : ScaleTransition(
            scale: Tween<double>(begin: 0.98, end: 1.08).animate(
              CurvedAnimation(parent: _controller, curve: Curves.easeOut),
            ),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: brandedLogo,
            ),
          );

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: Semantics(
          label: 'Loading rxmind',
          child: content,
        ),
      ),
    );
  }
}
