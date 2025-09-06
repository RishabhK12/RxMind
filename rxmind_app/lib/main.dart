import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/storage/local_storage.dart';
import 'theme/app_theme.dart';
import 'screens/onboarding/splash_screen.dart';
import 'screens/onboarding/welcome_carousel.dart';
import 'screens/onboarding/permissions_prompt.dart';
import 'screens/onboarding/onboarding_profile_flow.dart';
import 'screens/profile/profile_setup_screen.dart';
import 'screens/home/home_dashboard.dart';
import 'screens/home/main_navigation_shell.dart';
import 'screens/ocr/upload_options.dart';
import 'screens/ocr/review_text.dart';
import 'screens/ocr/parsing_progress.dart';
import 'screens/ocr/parsed_summary.dart';
import 'screens/tracker/tasks_screen.dart';
import 'screens/tracker/medications_screen.dart';
import 'screens/stats/compliance_stats.dart';
import 'screens/settings/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
  runApp(const RxMindApp());
  // Initialize DB after first frame
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    await LocalStorage.initDb();
  });
}

class RxMindApp extends StatefulWidget {
  const RxMindApp({super.key});

  @override
  State<RxMindApp> createState() => _RxMindAppState();
}

class _RxMindAppState extends State<RxMindApp> {
  ThemeMode _themeMode = ThemeMode.light;
  bool _highContrast = false;
  double _textScale = 1.0;
  bool _reducedMotion = false;

  void updateTheme(ThemeMode mode) => setState(() => _themeMode = mode);
  void updateHighContrast(bool v) => setState(() => _highContrast = v);
  void updateTextScale(double v) => setState(() => _textScale = v);
  void updateReducedMotion(bool v) => setState(() => _reducedMotion = v);

  @override
  Widget build(BuildContext context) {
    return RxMindSettings(
      themeMode: _themeMode,
      highContrast: _highContrast,
      textScale: _textScale,
      reducedMotion: _reducedMotion,
      updateTheme: updateTheme,
      updateHighContrast: updateHighContrast,
      updateTextScale: updateTextScale,
      updateReducedMotion: updateReducedMotion,
      child: Builder(
        builder: (context) => MaterialApp(
          title: 'RxMind',
          debugShowCheckedModeBanner: false,
          theme:
              _highContrast ? AppTheme.highContrastTheme : AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: _themeMode,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              disableAnimations: _reducedMotion,
              textScaler: TextScaler.linear(_textScale),
            ),
            child: child!,
          ),
          initialRoute: '/splash',
          routes: {
            '/splash': (context) => const SplashScreen(),
            '/welcomeCarousel': (context) => const WelcomeCarousel(),
            '/permissionsPrompt': (context) => const PermissionsPromptScreen(),
            '/onboardingProfile': (context) => OnboardingProfileFlow(
                  onComplete: () =>
                      Navigator.pushReplacementNamed(context, '/mainNav'),
                ),
            '/mainNav': (context) => const MainNavigationShell(),
            '/profileSetup': (context) => const ProfileSetupScreen(),
            '/homeDashboard': (context) => const HomeDashboardScreen(),
            '/uploadOptions': (context) => const UploadOptionsScreen(),
            '/reviewText': (context) => const ReviewTextScreen(),
            '/parsingProgress': (context) => const ParsingProgressScreen(),
            '/parsedSummary': (context) => const ParsedSummaryScreen(),
            '/tasks': (context) => const TasksScreen(),
            '/medications': (context) => const MedicationsScreen(),
            '/stats': (context) => ComplianceStatsScreen(),
            '/settings': (context) => const SettingsScreen(),
          },
        ),
      ),
    );
  }
}

class RxMindSettings extends InheritedWidget {
  final ThemeMode themeMode;
  final bool highContrast;
  final double textScale;
  final bool reducedMotion;
  final void Function(ThemeMode) updateTheme;
  final void Function(bool) updateHighContrast;
  final void Function(double) updateTextScale;
  final void Function(bool) updateReducedMotion;

  const RxMindSettings({
    super.key,
    required this.themeMode,
    required this.highContrast,
    required this.textScale,
    required this.reducedMotion,
    required this.updateTheme,
    required this.updateHighContrast,
    required this.updateTextScale,
    required this.updateReducedMotion,
    required super.child,
  });

  static RxMindSettings of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<RxMindSettings>()!;

  @override
  bool updateShouldNotify(RxMindSettings oldWidget) =>
      themeMode != oldWidget.themeMode ||
      highContrast != oldWidget.highContrast ||
      textScale != oldWidget.textScale ||
      reducedMotion != oldWidget.reducedMotion;
}
