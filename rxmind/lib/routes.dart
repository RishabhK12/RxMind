import 'package:go_router/go_router.dart';
import 'ui/welcome/welcome_screen.dart';
import 'ui/info/info_screen.dart';
import 'ui/mainnav/main_nav.dart';
// import other screens as you build them

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
  ],
);
