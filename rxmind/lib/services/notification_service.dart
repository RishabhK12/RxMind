import 'database_service.dart';
import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  Future<void> rescheduleAllNotifications() async {
    final db = await DatabaseService().database;
    final now = DateTime.now();
    final tasks = await db.query('tasks');
    for (final t in tasks) {
      final timeStr = (t['time'] ?? '').toString();
      if (timeStr.isNotEmpty) {
        try {
          final match =
              RegExp(r'(\d{1,2}):(\d{2}) ?([AP]M)').firstMatch(timeStr);
          if (match != null) {
            int hour = int.parse(match.group(1)!);
            int minute = int.parse(match.group(2)!);
            final ampm = match.group(3);
            if (ampm == 'PM' && hour < 12) hour += 12;
            if (ampm == 'AM' && hour == 12) hour = 0;
            final scheduled =
                DateTime(now.year, now.month, now.day, hour, minute);
            if (scheduled.isAfter(now)) {
              await scheduleNotification(
                id: int.tryParse(t['id'].toString()) ??
                    scheduled.millisecondsSinceEpoch,
                title: (t['title'] ?? 'Task Reminder').toString(),
                body: (t['description'] ?? '').toString(),
                scheduledDate: scheduled,
              );
            }
          }
        } catch (_) {}
      }
    }
    final meds = await db.query('medications');
    for (final m in meds) {
      final dosage = (m['dosage'] ?? '').toString();
      if (dosage.contains('day') || dosage.contains('hour')) {
        await scheduleNotification(
          id: int.tryParse(m['id'].toString()) ??
              DateTime.now().millisecondsSinceEpoch,
          title: (m['name'] ?? 'Medication Reminder').toString(),
          body: (m['description'] ?? '').toString(),
          scheduledDate:
              DateTime.now().add(const Duration(minutes: 1)), // Placeholder
        );
      }
    }
  }

  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
    );
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'main_channel',
          'Main Channel',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
  }

  Future<void> cancelAll() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }
}
