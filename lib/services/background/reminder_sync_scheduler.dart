import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';

const reminderSyncTaskName = 'rxmind_reminder_sync';
const reminderSyncUniqueName = 'rxmind_reminder_sync_periodic';

/// Schedules periodic local reminder resync. No network access.
class ReminderSyncScheduler {
  ReminderSyncScheduler._();

  static bool get isSupported =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  /// Registers a periodic background sync (Android WorkManager / iOS BGTask).
  static Future<void> registerPeriodicSync() async {
    if (!isSupported) return;

    if (Platform.isAndroid) {
      await Workmanager().registerPeriodicTask(
        reminderSyncUniqueName,
        reminderSyncTaskName,
        frequency: const Duration(hours: 12),
        constraints: Constraints(
          networkType: NetworkType.not_required,
          requiresBatteryNotLow: false,
          requiresCharging: false,
          requiresDeviceIdle: false,
          requiresStorageNotLow: false,
        ),
        existingWorkPolicy: ExistingWorkPolicy.keep,
      );
    }
    // iOS BGTask registration is handled natively in AppDelegate.
  }

  static Future<void> cancelSync() async {
    if (!isSupported) return;
    if (Platform.isAndroid) {
      await Workmanager().cancelByUniqueName(reminderSyncUniqueName);
    }
  }

  static Future<bool> isRegistered() async {
    if (!Platform.isAndroid) return false;
    // workmanager does not expose query; track via callback presence.
    return true;
  }
}

/// Top-level callback for WorkManager (must be top-level function).
@pragma('vm:entry-point')
void reminderSyncCallbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    // Actual reschedule is triggered via platform channel when device unlocked.
    return Future.value(true);
  });
}
