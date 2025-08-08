import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class WelcomeCarousel extends StatefulWidget {
  const WelcomeCarousel({Key? key}) : super(key: key);

  @override
  State<WelcomeCarousel> createState() => _WelcomeCarouselState();
}

class _WelcomeCarouselState extends State<WelcomeCarousel> {
  final PageController _pageController = PageController();
  int _pageIndex = 0;

  final List<_CarouselPage> _pages = [
    _CarouselPage(
      illustration: 'assets/illus/onboard1.svg',
      title: 'Welcome to Discharge Assistant',
      description:
          'Your on-device guide to safe hospital discharge. All your instructions, meds, and reminders in one secure place.',
    ),
    _CarouselPage(
      illustration: 'assets/illus/onboard2.svg',
      title: 'Offline & Private',
      description:
          'Everything stays on your device. No cloud, no tracking. Your health data is always encrypted.',
    ),
    _CarouselPage(
      illustration: 'assets/illus/onboard3.svg',
      title: 'Smarter Recovery',
      description:
          'Scan, organize, and act on your discharge instructions with reminders, glossary, and more.',
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
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
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
                  return AnimatedBuilder(
                    animation: _pageController,
                    builder: (context, child) {
                      double value = 1.0;
                      if (_pageController.position.haveDimensions) {
                        final pageValue = _pageController.page;
                        value = ((pageValue != null
                                    ? pageValue
                                    : _pageIndex.toDouble()) -
                                i)
                            .toDouble();
                        value = (1 - (value.abs() * 0.2)).clamp(0.8, 1.0);
                      }
                      return Opacity(
                        opacity: value,
                        child: Transform.translate(
                          offset: Offset(0, 40 * (1 - value)),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Removed top image for cleaner look
                              const SizedBox(height: 32),
                              Text(
                                page.title,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(fontSize: 24),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 32),
                                child: Text(
                                  page.description,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.copyWith(
                                          color: const Color(0xFF616161)),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: SmoothPageIndicator(
                controller: _pageController,
                count: _pages.length,
                effect: WormEffect(
                  dotHeight: 10,
                  dotWidth: 10,
                  spacing: 8,
                  dotColor: Theme.of(context).colorScheme.surfaceVariant,
                  activeDotColor: Theme.of(context).colorScheme.secondary,
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
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                        child: const Text('Next'),
                      ),
                    )
                  : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pushReplacementNamed(
                            context,
                            '/permissionsPrompt',
                          );
                        },
                        child: const Text('Get Started'),
                      ),
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
  const _CarouselPage({
    required this.illustration,
    required this.title,
    required this.description,
  });
}
