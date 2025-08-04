import 'package:go_router/go_router.dart';
import 'ui/welcome/welcome_screen.dart';
import 'ui/info/info_screen.dart';
import 'ui/mainnav/main_nav.dart';
import 'screens/measurement_flow.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const WelcomeScreen(),
    ),
    GoRoute(
      path: '/info',
      builder: (context, state) => const InfoScreen(),
    ),
    GoRoute(
      path: '/main',
      builder: (context, state) => const MainNav(),
    ),
    GoRoute(
      path: '/measurement/weight',
      builder: (context, state) => const WeightScreen(),
    ),
    GoRoute(
      path: '/measurement/height',
      builder: (context, state) => const HeightScreen(),
    ),
    GoRoute(
      path: '/measurement/blood_pressure',
      builder: (context, state) => const BloodPressureScreen(),
    ),
    GoRoute(
      path: '/measurement/heart_rate',
      builder: (context, state) => const HeartRateScreen(),
    ),
    GoRoute(
      path: '/measurement/temperature',
      builder: (context, state) => const TemperatureScreen(),
    ),
    GoRoute(
      path: '/measurement/spo2',
      builder: (context, state) => const SpO2Screen(),
    ),
    GoRoute(
      path: '/measurement/glucose',
      builder: (context, state) => const GlucoseScreen(),
    ),
    GoRoute(
      path: '/measurement/optional',
      builder: (context, state) => const OptionalScreen(),
    ),
  ],
);
