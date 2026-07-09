import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:rxmind_app/main.dart';
import 'package:rxmind_app/screens/onboarding/disclaimer_gate_screen.dart';
import 'package:rxmind_app/screens/settings/privacy_terms_screen.dart';
import 'package:rxmind_app/theme/theme_tokens.dart';
import 'package:rxmind_app/widgets/rx_app_bar_logo.dart';
import 'package:rxmind_app/widgets/rx_primary_button.dart';
import 'package:rxmind_app/widgets/rx_secondary_button.dart';

/// Unified 5-step onboarding wizard integrating disclaimer, CHD consent,
/// feature carousel, and profile setup entry.
class OnboardingWizardScreen extends StatefulWidget {
  const OnboardingWizardScreen({
    super.key,
    required this.onComplete,
    required this.onDisclaimerAcknowledged,
    required this.onConsentGranted,
    this.initialStep = 0,
  });

  final VoidCallback onComplete;
  final Future<void> Function() onDisclaimerAcknowledged;
  final Future<void> Function() onConsentGranted;
  final int initialStep;

  static const int totalSteps = 5;

  @override
  State<OnboardingWizardScreen> createState() => _OnboardingWizardScreenState();
}

class _OnboardingWizardScreenState extends State<OnboardingWizardScreen> {
  late final PageController _pageController;
  late final PageController _carouselController;
  late int _currentStep;
  int _carouselIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentStep =
        widget.initialStep.clamp(0, OnboardingWizardScreen.totalSteps - 1);
    _pageController = PageController(initialPage: _currentStep);
    _carouselController = PageController();
  }

  final List<_CarouselSlide> _carouselSlides = const [
    _CarouselSlide(
      asset: 'assets/illus/onboard1.svg',
      semanticsLabel: 'Welcome illustration showing recovery organization',
      title: 'Welcome to RxMind',
      description:
          'Your on-device guide to safe hospital discharge. All your instructions, meds, and reminders in one secure place.',
      wellColor: ThemeTokens.blue50,
    ),
    _CarouselSlide(
      asset: 'assets/illus/onboard2.svg',
      semanticsLabel: 'Privacy illustration showing on-device storage',
      title: 'Offline & Private',
      description:
          'Everything stays on your device. No cloud, no tracking. Your health data is stored locally on your device.',
      wellColor: ThemeTokens.emerald50,
    ),
    _CarouselSlide(
      asset: 'assets/illus/onboard3.svg',
      semanticsLabel: 'Organization illustration showing tasks and reminders',
      title: 'Organized Recovery',
      description:
          'Log, organize, and remind yourself about discharge instructions with tasks, glossary, and more.',
      wellColor: ThemeTokens.violet50,
    ),
  ];

  bool get _reducedMotion {
    try {
      return RxMindSettings.of(context).reducedMotion ||
          MediaQuery.disableAnimationsOf(context);
    } catch (_) {
      return MediaQuery.disableAnimationsOf(context);
    }
  }

  double get _progress =>
      (_currentStep + 1) / OnboardingWizardScreen.totalSteps;

  Future<void> _nextStep() async {
    if (_currentStep == 1) {
      await widget.onDisclaimerAcknowledged();
    } else if (_currentStep == 2) {
      await widget.onConsentGranted();
    }

    if (_currentStep >= OnboardingWizardScreen.totalSteps - 1) {
      widget.onComplete();
      return;
    }

    setState(() => _currentStep++);
    if (_reducedMotion) {
      _pageController.jumpToPage(_currentStep);
    } else {
      await _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _carouselController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                child: Semantics(
                  label:
                      'Progress: Step ${_currentStep + 1} of ${OnboardingWizardScreen.totalSteps}',
                  value: '${(_progress * 100).round()} percent',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius:
                            BorderRadius.circular(ThemeTokens.radiusPill),
                        child: LinearProgressIndicator(
                          value: _progress,
                          minHeight: 8,
                          backgroundColor: ThemeTokens.brandMuted,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Step ${_currentStep + 1} of ${OnboardingWizardScreen.totalSteps}',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildWelcomeStep(theme),
                    _buildDisclaimerStep(theme),
                    _buildConsentStep(theme),
                    _buildCarouselStep(theme),
                    _buildProfileStep(theme),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeStep(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Semantics(
            label: 'RxMind logo',
            child: Container(
              padding: const EdgeInsets.all(ThemeTokens.spacingLg),
              decoration: BoxDecoration(
                color: ThemeTokens.blue50,
                borderRadius: BorderRadius.circular(ThemeTokens.radiusLg),
              ),
              child: const RxAppBarLogo(showWordmark: false, height: 96),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Get Started with RxMind',
            style: theme.textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'A personal recovery organizer that keeps your discharge information '
            'private and on your device.',
            style: theme.textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const Spacer(),
          Semantics(
            label: 'Continue',
            button: true,
            child: RxPrimaryButton(label: 'Continue', onPressed: _nextStep),
          ),
        ],
      ),
    );
  }

  Widget _buildDisclaimerStep(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Spacer(),
          Icon(Icons.info_outline, size: 64, color: theme.colorScheme.primary),
          const SizedBox(height: 24),
          Text(
            'Important Notice',
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Text(
            DisclaimerGateScreen.disclaimerText,
            style: theme.textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const Spacer(),
          Semantics(
            label: 'I Understand',
            button: true,
            child: RxPrimaryButton(label: 'I Understand', onPressed: _nextStep),
          ),
        ],
      ),
    );
  }

  Widget _buildConsentStep(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Consumer Health Data',
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'RxMind collects and stores the following categories of '
                    'Consumer Health Data locally on your device only:',
                  ),
                  SizedBox(height: 12),
                  _Bullet('Discharge documents you scan or import'),
                  _Bullet(
                      'Medications, tasks, and follow-up reminders you enter'),
                  _Bullet('Recovery instructions and wellness notes'),
                  _Bullet('Optional profile and scheduling preferences'),
                  SizedBox(height: 16),
                  Text(
                    'Your data is stored locally on your device. It is not '
                    'uploaded to cloud servers as part of routine app use.',
                  ),
                  SizedBox(height: 12),
                  Text(
                    'You may withdraw consent at any time by going to '
                    'Settings → Delete All Data, which permanently erases '
                    'all stored health information.',
                  ),
                ],
              ),
            ),
          ),
          RxSecondaryButton(
            label: 'View Privacy Policy',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PrivacyTermsScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          Semantics(
            label: 'I Agree',
            button: true,
            child: RxPrimaryButton(label: 'I Agree', onPressed: _nextStep),
          ),
        ],
      ),
    );
  }

  Widget _buildCarouselStep(ThemeData theme) {
    return Column(
      children: [
        Expanded(
          child: PageView.builder(
            controller: _carouselController,
            onPageChanged: (i) => setState(() => _carouselIndex = i),
            itemCount: _carouselSlides.length,
            itemBuilder: (context, i) {
              final slide = _carouselSlides[i];
              return Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Semantics(
                      label: slide.semanticsLabel,
                      child: Container(
                        padding: const EdgeInsets.all(ThemeTokens.spacingLg),
                        decoration: BoxDecoration(
                          color: slide.wellColor,
                          borderRadius:
                              BorderRadius.circular(ThemeTokens.radiusLg),
                        ),
                        child: SvgPicture.asset(
                          slide.asset,
                          height: 160,
                          errorBuilder: (_, __, ___) => Icon(
                            Icons.image_outlined,
                            size: 100,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      slide.title,
                      style: theme.textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      slide.description,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(24),
          child: Semantics(
            label: _carouselIndex < _carouselSlides.length - 1
                ? 'Next Slide'
                : 'Continue',
            button: true,
            child: RxPrimaryButton(
              label: _carouselIndex < _carouselSlides.length - 1
                  ? 'Next Slide'
                  : 'Continue',
              onPressed: () {
                if (_carouselIndex < _carouselSlides.length - 1) {
                  _carouselController.nextPage(
                    duration: _reducedMotion
                        ? Duration.zero
                        : const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                } else {
                  _nextStep();
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileStep(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_outline,
              size: 72, color: theme.colorScheme.primary),
          const SizedBox(height: 24),
          Text(
            'Set Up Your Profile',
            style: theme.textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Optional: add your name, schedule, and preferences to personalize '
            'reminders and your dashboard.',
            style: theme.textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const Spacer(),
          Semantics(
            label: 'Set Up Profile',
            button: true,
            child: RxPrimaryButton(
              label: 'Set Up Profile',
              onPressed: widget.onComplete,
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: widget.onComplete,
            child: const Text('Skip for now'),
          ),
        ],
      ),
    );
  }
}

class _CarouselSlide {
  const _CarouselSlide({
    required this.asset,
    required this.semanticsLabel,
    required this.title,
    required this.description,
    required this.wellColor,
  });

  final String asset;
  final String semanticsLabel;
  final String title;
  final String description;
  final Color wellColor;
}

class _Bullet extends StatelessWidget {
  const _Bullet(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('•  '),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
