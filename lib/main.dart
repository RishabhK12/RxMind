import 'package:flutter/material.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:workmanager/workmanager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/storage/local_storage.dart';
import 'theme/app_theme.dart';
import 'screens/onboarding/splash_screen.dart';
import 'screens/onboarding/welcome_carousel.dart';
import 'screens/onboarding/onboarding_profile_flow.dart';
import 'screens/onboarding/onboarding_wizard_screen.dart';
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
import 'screens/settings/privacy_gate_screen.dart';
import 'services/notification_service.dart';
import 'services/discharge_data_manager.dart';
import 'services/background/reminder_sync_scheduler.dart';
import 'services/background/reminder_sync_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  tz.initializeTimeZones();

  if (ReminderSyncScheduler.isSupported) {
    await Workmanager().initialize(reminderSyncCallbackDispatcher);
  }

  await LocalStorage.initDb();

  final notificationService = NotificationService();
  await notificationService.initialize();

  try {
    final tasks = await DischargeDataManager.loadTasks();
    await notificationService.scheduleNotificationsForTasks(tasks);
    await ReminderSyncScheduler.registerPeriodicSync();
  } catch (e) {
    debugPrint('Task notification scheduling deferred: $e');
  }

  final prefs = await SharedPreferences.getInstance();
  final hasAcceptedPrivacy = prefs.getBool('privacy_terms_accepted') ?? false;

  runApp(RxMindApp(showPrivacyGate: !hasAcceptedPrivacy));
}

class RxMindApp extends StatefulWidget {
  final bool showPrivacyGate;
  const RxMindApp({super.key, required this.showPrivacyGate});

  @override
  State<RxMindApp> createState() => _RxMindAppState();
}

class _RxMindAppState extends State<RxMindApp> with WidgetsBindingObserver {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  ThemeMode _themeMode = ThemeMode.light;
  bool _highContrast = false;
  double _textScale = 1.0;
  bool _reducedMotion = false;
  late final String _initialRoute;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initialRoute = widget.showPrivacyGate ? '/privacyGate' : '/splash';
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ReminderSyncService.flushLockSafeBuffer();
      ReminderSyncService.rescheduleAllFromDatabase();
    }
  }

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
          navigatorKey: _navigatorKey,
          title: 'rxmind',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.resolve(
            mode: _themeMode,
            highContrast: _highContrast,
            platformBrightness: MediaQuery.platformBrightnessOf(context),
          ),
          darkTheme: _highContrast
              ? AppTheme.highContrastDarkTheme
              : AppTheme.darkTheme,
          themeMode: _themeMode,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              disableAnimations: _reducedMotion,
              textScaler: TextScaler.linear(_textScale),
            ),
            child: child!,
          ),
          initialRoute: _initialRoute,
          routes: {
            '/privacyGate': (context) => const PrivacyGateScreen(),
            '/splash': (context) => const SplashScreen(),
            '/disclaimerGate': (context) => OnboardingWizardScreen(
                  onDisclaimerAcknowledged: () async {
                    await LocalStorage.setDisclaimerAcknowledged();
                  },
                  onConsentGranted: () async {
                    await LocalStorage.setChdConsent();
                  },
                  onComplete: () {
                    if (!context.mounted) return;
                    Navigator.pushReplacementNamed(
                        context, '/onboardingProfile');
                  },
                ),
            '/chdConsent': (context) => OnboardingWizardScreen(
                  onDisclaimerAcknowledged: () async {
                    await LocalStorage.setDisclaimerAcknowledged();
                  },
                  onConsentGranted: () async {
                    await LocalStorage.setChdConsent();
                  },
                  onComplete: () {
                    if (!context.mounted) return;
                    Navigator.pushReplacementNamed(
                        context, '/onboardingProfile');
                  },
                ),
            '/onboarding': (context) {
              final initialStep =
                  ModalRoute.of(context)?.settings.arguments as int? ?? 0;
              return OnboardingWizardScreen(
                initialStep: initialStep,
                onDisclaimerAcknowledged: () async {
                  await LocalStorage.setDisclaimerAcknowledged();
                },
                onConsentGranted: () async {
                  await LocalStorage.setChdConsent();
                },
                onComplete: () {
                  if (!context.mounted) return;
                  Navigator.pushReplacementNamed(context, '/onboardingProfile');
                },
              );
            },
            '/welcomeCarousel': (context) => const WelcomeCarousel(),
            '/permissionsPrompt': (context) => OnboardingProfileFlow(
                  onComplete: () =>
                      Navigator.pushReplacementNamed(context, '/mainNav'),
                ),
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
