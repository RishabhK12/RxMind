import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:rxmind_app/theme/theme_tokens.dart';
import 'package:rxmind_app/widgets/rx_primary_button.dart';

class WelcomeCarousel extends StatefulWidget {
  const WelcomeCarousel({super.key});

  @override
  State<WelcomeCarousel> createState() => _WelcomeCarouselState();
}

class _WelcomeCarouselState extends State<WelcomeCarousel> {
  final PageController _pageController = PageController();
  int _pageIndex = 0;

  final List<_CarouselPage> _pages = [
    _CarouselPage(
      illustration: 'assets/illus/onboard1.svg',
      title: 'Welcome to RxMind',
      description:
          'Your on-device guide to safe hospital discharge. All your instructions, meds, and reminders in one secure place.',
      wellColor: ThemeTokens.blue50,
    ),
    _CarouselPage(
      illustration: 'assets/illus/onboard2.svg',
      title: 'Offline & Private',
      description:
          'Everything stays on your device. No cloud, no tracking. Your health data is stored locally on your device.',
      wellColor: ThemeTokens.emerald50,
    ),
    _CarouselPage(
      illustration: 'assets/illus/onboard3.svg',
      title: 'Organized Recovery',
      description:
          'Log, organize, and remind yourself about discharge instructions with tasks, glossary, and more.',
      wellColor: ThemeTokens.violet50,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      final newIndex = _pageController.page?.round() ?? 0;
      if (newIndex != _pageIndex) {
        setState(() => _pageIndex = newIndex);
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ext = RxMindThemeExtension.of(context);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics: const BouncingScrollPhysics(),
                itemCount: _pages.length,
                itemBuilder: (context, i) {
                  final page = _pages[i];
                  final pageContent = Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 32),
                        padding: const EdgeInsets.all(ThemeTokens.spacingXl),
                        decoration: BoxDecoration(
                          color: page.wellColor,
                          borderRadius:
                              BorderRadius.circular(ThemeTokens.radiusLg),
                        ),
                        child: SvgPicture.asset(
                          page.illustration,
                          height: 160,
                          errorBuilder: (_, __, ___) => Icon(
                            Icons.image_outlined,
                            size: 72,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: ThemeTokens.spacingXl),
                      Text(
                        page.title,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontSize: 24,
                          color: theme.colorScheme.onSurface,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: ThemeTokens.spacingMd),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          page.description,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.7),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  );

                  if (reduceMotion) return pageContent;

                  return AnimatedBuilder(
                    animation: _pageController,
                    builder: (context, child) {
                      double value = 1.0;
                      if (_pageController.position.haveDimensions) {
                        final pageValue = _pageController.page;
                        value = ((pageValue ?? _pageIndex.toDouble()) - i)
                            .toDouble();
                        value = (1 - (value.abs() * 0.2)).clamp(0.8, 1.0);
                      }
                      return Opacity(
                        opacity: value,
                        child: Transform.translate(
                          offset: Offset(0, 40 * (1 - value)),
                          child: child,
                        ),
                      );
                    },
                    child: pageContent,
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(ThemeTokens.radiusPill),
                  border: Border.all(color: ext.border, width: 1.5),
                ),
                child: SmoothPageIndicator(
                  controller: _pageController,
                  count: _pages.length,
                  effect: WormEffect(
                    dotHeight: 10,
                    dotWidth: 10,
                    spacing: 8,
                    dotColor: ThemeTokens.brandMuted,
                    activeDotColor: theme.colorScheme.primary,
                  ),
                ),
              ),
            ),
            Container(
              height: 100,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              child: _pageIndex < 2
                  ? Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          _pageController.nextPage(
                            duration: reduceMotion
                                ? Duration.zero
                                : const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                        child: const Text('Next'),
                      ),
                    )
                  : RxPrimaryButton(
                      label: 'Get Started',
                      onPressed: () {
                        Navigator.pushReplacementNamed(
                          context,
                          '/permissionsPrompt',
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CarouselPage {
  final String illustration;
  final String title;
  final String description;
  final Color wellColor;
  const _CarouselPage({
    required this.illustration,
    required this.title,
    required this.description,
    required this.wellColor,
  });
}
