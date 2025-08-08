import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({Key? key}) : super(key: key);

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  List<Map<String, dynamic>> tasksList = [
    {
      'id': '1',
      'title': 'Take Morning Meds',
      'isOverdue': false,
      'snoozeCount': 0,
    },
    {
      'id': '2',
      'title': 'Check Vitals',
      'isOverdue': true,
      'snoozeCount': 2,
    },
  ];

  @override
  void initState() {
    super.initState();
    _initNotifications();
  }

  Future<void> _initNotifications() async {
    const AndroidInitializationSettings androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings =
        InitializationSettings(android: androidInit);
    await _notifications.initialize(initSettings);
  }

  Future<void> _showEscalationNotification(String title) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'escalation_channel',
      'Escalation Notifications',
      channelDescription: 'High-priority reminders for overdue tasks',
      importance: Importance.max,
      priority: Priority.high,
      color: Color(0xFFD32F2F),
    );
    const NotificationDetails details =
        NotificationDetails(android: androidDetails);
    await _notifications.show(0, 'High-Priority Reminder', title, details);
  }

  void _reorderTasks(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex--;
      final item = tasksList.removeAt(oldIndex);
      tasksList.insert(newIndex, item);
    });
  }

  void _snoozeTask(Map<String, dynamic> task) {
    setState(() {
      task['snoozeCount'] = (task['snoozeCount'] ?? 0) + 1;
      // Here you would update the due time, e.g., by 1 hour
      if (task['snoozeCount'] >= 3) {
        _escalateReminder(task);
      }
    });
  }

  void _escalateReminder(Map<String, dynamic> task) {
    _showEscalationNotification('High-priority reminder for ${task['title']}!');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('High-priority reminder for ${task['title']}!')),
    );
  }

  void _deleteTask(String id) {
    setState(() {
      tasksList.removeWhere((t) => t['id'] == id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 1,
        title: Semantics(
          label: 'Tasks and Reminders',
          child: Text(
            'Tasks & Reminders',
            style: theme.textTheme.titleLarge,
          ),
        ),
      ),
      body: ReorderableListView(
        padding: const EdgeInsets.all(8),
        onReorder: _reorderTasks,
        children: [
          for (final task in tasksList)
            Semantics(
              label:
                  'Task: ${task['title']}${task['isOverdue'] ? ', overdue' : ''}',
              child: Slidable(
                key: ValueKey(task['id']),
                endActionPane: ActionPane(
                  motion: const DrawerMotion(),
                  children: [
                    Semantics(
                      label: 'Snooze task',
                      button: true,
                      child: SlidableAction(
                        onPressed: (_) => _snoozeTask(task),
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        icon: Icons.snooze,
                        label: 'Snooze',
                      ),
                    ),
                    Semantics(
                      label: 'Delete task',
                      button: true,
                      child: SlidableAction(
                        onPressed: (_) => _deleteTask(task['id']),
                        backgroundColor: theme.colorScheme.error,
                        foregroundColor: theme.colorScheme.onError,
                        icon: Icons.delete,
                        label: 'Delete',
                      ),
                    ),
                  ],
                ),
                child: _buildTaskCard(context, task),
              ),
            ),
        ],
      ),
      bottomSheet: Semantics(
        label:
            'Legend: Snooze reschedules by 1 hour. Overdue tasks are marked in red.',
        child: Container(
          color: theme.colorScheme.surface,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(Icons.snooze, size: 20, color: Colors.orange.shade700),
              const SizedBox(width: 4),
              Text('Snooze reschedules by 1 hr',
                  style: theme.textTheme.bodyMedium),
              const Spacer(),
              Icon(Icons.warning, size: 20, color: theme.colorScheme.error),
              const SizedBox(width: 4),
              Text('Overdue',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.colorScheme.error)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTaskCard(BuildContext context, Map<String, dynamic> task) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
        border: task['isOverdue'] == true
            ? Border.all(color: theme.colorScheme.error, width: 2)
            : null,
      ),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            color: task['isOverdue'] == true
                ? theme.colorScheme.error
                : theme.colorScheme.secondary,
            size: 28,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              task['title'],
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
                fontSize: 16,
                color: task['isOverdue'] == true
                    ? theme.colorScheme.error
                    : theme.colorScheme.onSurface,
              ),
            ),
          ),
          if (task['isOverdue'] == true)
            Icon(Icons.warning, color: theme.colorScheme.error),
          const SizedBox(width: 8),
          Icon(Icons.drag_handle,
              color: theme.colorScheme.onSurface.withOpacity(0.2)),
        ],
      ),
    );
  }
}
