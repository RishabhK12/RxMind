import 'package:flutter/material.dart';

import 'package:medilab_prokit/store/AppStore.dart';
import 'utils/app_theme.dart';
import 'routes.dart';
import 'services/upload_queue_processor.dart';
import 'services/notification_service.dart';

final AppStore appStore = AppStore();

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  NotificationService().init().then((_) {
    NotificationService().rescheduleAllNotifications();
  });
  UploadQueueProcessor().start();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'RxMind',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        // Clamp textScaleFactor for accessibility (min 1.0, max 1.4)
        // Clamp text scaling for accessibility (min 1.0, max 1.4)
        final double scale = mediaQuery.textScaler.scale(1.0).clamp(1.0, 1.4);
        return MediaQuery(
          data: mediaQuery.copyWith(textScaler: TextScaler.linear(scale)),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
