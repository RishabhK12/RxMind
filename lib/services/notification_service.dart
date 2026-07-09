import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io' show Platform;

import 'package:rxmind_app/core/notifications/neutral_notification_copy.dart';
import 'package:rxmind_app/core/storage/database_key_exception.dart';
import 'package:rxmind_app/core/storage/lock_safe_write_buffer.dart';

/// Service to manage task notifications with customizable timing.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static const String _keyNotificationsEnabled = 'notificationsEnabled';
  static const String _keyNotificationTimes = 'notificationTimes';

  static const List<int> defaultNotificationTimes = [120, 30, 5];

  bool _initialized = false;

  /// Exposed for tests to inspect scheduled notification content.
  FlutterLocalNotificationsPlugin get plugin => _notifications;

  Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _initialized = true;
  }

  void _onNotificationTapped(NotificationResponse response) {}

  Future<bool> checkAndRequestPermissions({bool skipRequest = false}) async {
    final notificationStatus = await Permission.notification.status;

    if (!notificationStatus.isGranted) {
      if (skipRequest) return false;
      if (notificationStatus.isDenied) {
        final result = await Permission.notification.request();
        if (!result.isGranted) {
          return false;
        }
      } else {
        return false;
      }
    }

    if (Platform.isAndroid) {
      try {
        final scheduleExactAlarmStatus =
            await Permission.scheduleExactAlarm.status;

        if (!scheduleExactAlarmStatus.isGranted && !skipRequest) {
          await Permission.scheduleExactAlarm.request();
        }
      } catch (e) {
        // Older Android version, exact alarms not required
      }
    }

    return true;
  }

  Future<bool> canScheduleExactAlarms() async {
    if (!Platform.isAndroid) return true;

    try {
      final status = await Permission.scheduleExactAlarm.status;
      return status.isGranted;
    } catch (e) {
      return false;
    }
  }

  Future<void> openNotificationSettings() async {
    await openAppSettings();
  }

  Future<bool> areNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyNotificationsEnabled) ?? true;
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyNotificationsEnabled, enabled);

    if (!enabled) {
      await cancelAllNotifications();
    }
  }

  Future<List<int>> getNotificationTimes() async {
    final prefs = await SharedPreferences.getInstance();
    final timesJson = prefs.getString(_keyNotificationTimes);

    if (timesJson == null) {
      return List.from(defaultNotificationTimes);
    }

    try {
      final List<dynamic> decoded = jsonDecode(timesJson);
      return decoded.map((e) => e as int).toList();
    } catch (e) {
      return List.from(defaultNotificationTimes);
    }
  }

  Future<void> setNotificationTimes(List<int> times) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyNotificationTimes, jsonEncode(times));
  }

  Future<void> scheduleTaskNotifications({
    required String taskId,
    required String taskTitle,
    required DateTime dueTime,
  }) async {
    final enabled = await areNotificationsEnabled();
    if (!enabled) return;

    final hasPermission = await checkAndRequestPermissions(skipRequest: true);
    if (!hasPermission) return;

    final notificationTimes = await getNotificationTimes();
    await cancelTaskNotifications(taskId);

    for (int i = 0; i < notificationTimes.length; i++) {
      final minutesBefore = notificationTimes[i];
      final notificationTime =
          dueTime.subtract(Duration(minutes: minutesBefore));

      if (notificationTime.isAfter(DateTime.now())) {
        await _scheduleNotification(
          id: _getNotificationId(taskId, i),
          scheduledTime: notificationTime,
          payload: taskId,
        );
      }
    }
  }

  Future<void> cancelTaskNotifications(String taskId) async {
    final notificationTimes = await getNotificationTimes();

    for (int i = 0; i < notificationTimes.length; i++) {
      await _notifications.cancel(_getNotificationId(taskId, i));
    }
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  Future<void> scheduleNotificationsForTasks(
    List<Map<String, dynamic>> tasks,
  ) async {
    for (final task in tasks) {
      if (task['completed'] == true) continue;

      final taskId = task['id']?.toString();
      final taskTitle = task['title']?.toString() ?? 'Task';
      final dueTime = task['dueTime'];

      if (taskId != null && dueTime != null) {
        DateTime? parsedDueTime;

        if (dueTime is DateTime) {
          parsedDueTime = dueTime;
        } else if (dueTime is String) {
          try {
            parsedDueTime = DateTime.parse(dueTime);
          } catch (e) {
            continue;
          }
        }

        if (parsedDueTime != null && parsedDueTime.isAfter(DateTime.now())) {
          try {
            await scheduleTaskNotifications(
              taskId: taskId,
              taskTitle: taskTitle,
              dueTime: parsedDueTime,
            );
          } on DatabaseKeyException {
            LockSafeWriteBuffer.instance.enqueue(
              PendingWrite(
                operation: 'reschedule_task',
                payload: {'taskId': taskId},
              ),
            );
          }
        }
      }
    }
  }

  Future<void> _scheduleNotification({
    required int id,
    required DateTime scheduledTime,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      NeutralNotificationCopy.channelId,
      NeutralNotificationCopy.channelName,
      channelDescription: NeutralNotificationCopy.channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      final canUseExactAlarms = await canScheduleExactAlarms();
      final scheduleMode = canUseExactAlarms
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle;

      await _notifications.zonedSchedule(
        id,
        NeutralNotificationCopy.title,
        NeutralNotificationCopy.body,
        tz.TZDateTime.from(scheduledTime, tz.local),
        notificationDetails,
        androidScheduleMode: scheduleMode,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );
    } catch (e) {
      try {
        await _notifications.zonedSchedule(
          id,
          NeutralNotificationCopy.title,
          NeutralNotificationCopy.body,
          tz.TZDateTime.from(scheduledTime, tz.local),
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: payload,
        );
      } catch (e2) {
        // Notification scheduling failed
      }
    }
  }

  int _getNotificationId(String taskId, int timeIndex) {
    final hash = taskId.hashCode;
    return (hash.abs() % 100000) * 10 + timeIndex;
  }
}
