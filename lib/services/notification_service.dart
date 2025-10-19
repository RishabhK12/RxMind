import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io' show Platform;

/// Service to manage task notifications with customizable timing
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  // Storage keys
  static const String _keyNotificationsEnabled = 'notificationsEnabled';
  static const String _keyNotificationTimes = 'notificationTimes';

  // Default notification times (in minutes before task)
  static const List<int> defaultNotificationTimes = [
    120,
    30,
    5
  ]; // 2hr, 30min, 5min

  bool _initialized = false;

  /// Initialize the notification service
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

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    // Navigate to relevant screen based on notification payload
  }

  /// Check and request notification permissions
  Future<bool> checkAndRequestPermissions() async {
    final notificationStatus = await Permission.notification.status;

    if (!notificationStatus.isGranted) {
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

        if (!scheduleExactAlarmStatus.isGranted) {
          await Permission.scheduleExactAlarm.request();
        }
      } catch (e) {
        // Older Android version, exact alarms not required
      }
    }

    return true;
  }

  /// Check if exact alarms are available (Android 12+)
  Future<bool> canScheduleExactAlarms() async {
    if (!Platform.isAndroid) return true;

    try {
      final status = await Permission.scheduleExactAlarm.status;
      return status.isGranted;
    } catch (e) {
      return false;
    }
  }

  /// Open app notification settings
  Future<void> openNotificationSettings() async {
    await openAppSettings();
  }

  /// Check if notifications are enabled in app settings
  Future<bool> areNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyNotificationsEnabled) ??
        true; // Enabled by default
  }

  /// Set notifications enabled/disabled
  Future<void> setNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyNotificationsEnabled, enabled);

    if (!enabled) {
      // Cancel all notifications if disabled
      await cancelAllNotifications();
    }
  }

  /// Get notification times (in minutes before task)
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

  /// Set notification times (in minutes before task)
  Future<void> setNotificationTimes(List<int> times) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyNotificationTimes, jsonEncode(times));
  }

  /// Schedule notifications for a task
  Future<void> scheduleTaskNotifications({
    required String taskId,
    required String taskTitle,
    required DateTime dueTime,
  }) async {
    // Check if notifications are enabled
    final enabled = await areNotificationsEnabled();
    if (!enabled) return;

    // Check system permissions
    final hasPermission = await checkAndRequestPermissions();
    if (!hasPermission) return;

    // Get notification times
    final notificationTimes = await getNotificationTimes();

    // Cancel any existing notifications for this task
    await cancelTaskNotifications(taskId);

    // Schedule a notification for each time offset
    for (int i = 0; i < notificationTimes.length; i++) {
      final minutesBefore = notificationTimes[i];
      final notificationTime =
          dueTime.subtract(Duration(minutes: minutesBefore));

      // Only schedule if notification time is in the future
      if (notificationTime.isAfter(DateTime.now())) {
        await _scheduleNotification(
          id: _getNotificationId(taskId, i),
          title: 'Task Reminder',
          body: '$taskTitle is due in ${_formatDuration(minutesBefore)}',
          scheduledTime: notificationTime,
          payload: taskId,
        );
      }
    }
  }

  /// Cancel all notifications for a specific task
  Future<void> cancelTaskNotifications(String taskId) async {
    final notificationTimes = await getNotificationTimes();

    for (int i = 0; i < notificationTimes.length; i++) {
      await _notifications.cancel(_getNotificationId(taskId, i));
    }
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  /// Schedule all notifications for a list of tasks
  Future<void> scheduleNotificationsForTasks(
      List<Map<String, dynamic>> tasks) async {
    for (final task in tasks) {
      if (task['completed'] == true) continue; // Skip completed tasks

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
            // Invalid date format, skip
            continue;
          }
        }

        if (parsedDueTime != null && parsedDueTime.isAfter(DateTime.now())) {
          await scheduleTaskNotifications(
            taskId: taskId,
            taskTitle: taskTitle,
            dueTime: parsedDueTime,
          );
        }
      }
    }
  }

  /// Schedule a single notification
  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'task_reminders',
      'Task Reminders',
      channelDescription: 'Notifications for upcoming tasks',
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
      // Check if we can use exact alarms
      final canUseExactAlarms = await canScheduleExactAlarms();

      // Choose schedule mode based on permission
      // exactAllowWhileIdle requires SCHEDULE_EXACT_ALARM permission
      // inexactAllowWhileIdle doesn't require special permission
      final scheduleMode = canUseExactAlarms
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle;

      await _notifications.zonedSchedule(
        id,
        title,
        body,
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
          title,
          body,
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

  /// Get unique notification ID for a task and time offset index
  int _getNotificationId(String taskId, int timeIndex) {
    // Create a unique int ID from taskId hash and index
    final hash = taskId.hashCode;
    // Ensure positive int and combine with index
    return (hash.abs() % 100000) * 10 + timeIndex;
  }

  /// Format duration in minutes to human-readable string
  String _formatDuration(int minutes) {
    if (minutes < 60) {
      return '$minutes minute${minutes == 1 ? '' : 's'}';
    } else if (minutes < 1440) {
      final hours = minutes ~/ 60;
      final mins = minutes % 60;
      if (mins == 0) {
        return '$hours hour${hours == 1 ? '' : 's'}';
      }
      return '$hours hour${hours == 1 ? '' : 's'} $mins minute${mins == 1 ? '' : 's'}';
    } else {
      final days = minutes ~/ 1440;
      return '$days day${days == 1 ? '' : 's'}';
    }
  }
}
