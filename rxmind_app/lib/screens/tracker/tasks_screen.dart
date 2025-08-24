import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  List<Map<String, dynamic>> tasksList = [
    {
      'id': UniqueKey().toString(),
      'title': 'Take Morning Meds',
      'isOverdue': false,
      'snoozeCount': 0,
      'dueTime': DateTime.now().add(const Duration(hours: 1)),
    },
    {
      'id': UniqueKey().toString(),
      'title': 'Check Vitals',
      'isOverdue': true,
      'snoozeCount': 2,
      'dueTime': DateTime.now().add(const Duration(hours: 2)),
    },
  ];
  List<Map<String, dynamic>> completedTasks = [];
  bool showCompletedDropdown = false;

  // Ensure all tasks have unique, non-null IDs before building the list
  List<Map<String, dynamic>> get _safeTasksList {
    final seen = <dynamic>{};
    for (final task in tasksList) {
      if (task['id'] == null || seen.contains(task['id'])) {
        task['id'] = UniqueKey().toString();
      }
      seen.add(task['id']);
    }
    // Only show incomplete tasks, sorted by dueTime ascending
    final list = tasksList.where((t) => t['completed'] != true).toList();
    list.sort((a, b) {
      final at = a['dueTime'] as DateTime? ?? DateTime.now();
      final bt = b['dueTime'] as DateTime? ?? DateTime.now();
      return at.compareTo(bt);
    });
    return list;
  }

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

  void _toggleCompleteTask(Map<String, dynamic> task) async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Task Action'),
        content: const Text(
            'Would you like to snooze this task or mark it as complete?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop('snooze'),
            child: const Text('Snooze'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop('complete'),
            child: const Text('Complete'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
    if (result == 'snooze') {
      setState(() {
        task['snoozeCount'] = (task['snoozeCount'] ?? 0) + 1;
        task['dueTime'] = (task['dueTime'] as DateTime? ?? DateTime.now())
            .add(const Duration(hours: 1));
      });
      if (task['snoozeCount'] >= 3) {
        _escalateReminder(task);
      }
    } else if (result == 'complete') {
      setState(() {
        task['completed'] = true;
        completedTasks.insert(0, {...task});
      });
      // Animate checkmark (handled in widget)
      await Future.delayed(const Duration(milliseconds: 400));
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
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
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Column(
              children: [
                // Main task list
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                    children: [
                      ReorderableListView(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        onReorder: _reorderTasks,
                        children: [
                          for (final task in _safeTasksList)
                            Semantics(
                              key: ValueKey(task['id']),
                              label:
                                  'Task: ${task['title']}${task['isOverdue'] ? ', overdue' : ''}',
                              child: Slidable(
                                key: ValueKey(task['id']),
                                endActionPane: ActionPane(
                                  motion: const DrawerMotion(),
                                  children: [
                                    Semantics(
                                      label: 'Delete task',
                                      button: true,
                                      child: SlidableAction(
                                        onPressed: (_) =>
                                            _deleteTask(task['id']),
                                        backgroundColor:
                                            theme.colorScheme.error,
                                        foregroundColor:
                                            theme.colorScheme.onError,
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
                      const SizedBox(height: 8),
                      // Completed tasks dropdown, now just below the main list
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            GestureDetector(
                              onTap: () => setState(() =>
                                  showCompletedDropdown =
                                      !showCompletedDropdown),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary
                                      .withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 12, horizontal: 12),
                                child: Row(
                                  children: [
                                    Text('Completed Tasks',
                                        style: theme.textTheme.titleMedium),
                                    const Spacer(),
                                    AnimatedRotation(
                                      turns: showCompletedDropdown ? 0.5 : 0.0,
                                      duration:
                                          const Duration(milliseconds: 200),
                                      child: const Icon(Icons.expand_more),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            AnimatedCrossFade(
                              crossFadeState: showCompletedDropdown
                                  ? CrossFadeState.showSecond
                                  : CrossFadeState.showFirst,
                              duration: const Duration(milliseconds: 200),
                              firstChild: const SizedBox.shrink(),
                              secondChild: completedTasks.isEmpty
                                  ? Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Text('No completed tasks yet.',
                                          style: theme.textTheme.bodyMedium),
                                    )
                                  : SizedBox(
                                      height: 160,
                                      child: ListView.separated(
                                        itemCount: completedTasks.length,
                                        separatorBuilder: (context, i) =>
                                            const SizedBox(height: 10),
                                        itemBuilder: (context, i) {
                                          final t = completedTasks[i];
                                          return ListTile(
                                            leading: Icon(Icons.check_circle,
                                                color:
                                                    theme.colorScheme.primary),
                                            title: Text(t['title'] ?? '',
                                                style:
                                                    theme.textTheme.bodyLarge),
                                            subtitle: t['isOverdue'] == true
                                                ? Text('Was overdue',
                                                    style: TextStyle(
                                                        color: theme
                                                            .colorScheme.error))
                                                : null,
                                          );
                                        },
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16), // Small gap before legend
                    ],
                  ),
                ),
              ],
            );
          },
        ),
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
    final dueTime = task['dueTime'] as DateTime?;
    final dueTimeStr =
        dueTime != null ? TimeOfDay.fromDateTime(dueTime).format(context) : '';
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
          GestureDetector(
            onTap: () => _toggleCompleteTask(task),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              transitionBuilder: (child, anim) =>
                  ScaleTransition(scale: anim, child: child),
              child: task['completed'] == true
                  ? Icon(Icons.check_circle,
                      key: const ValueKey('checked'),
                      color: theme.colorScheme.primary,
                      size: 28)
                  : Icon(Icons.radio_button_unchecked,
                      key: const ValueKey('unchecked'),
                      color: task['isOverdue'] == true
                          ? theme.colorScheme.error
                          : theme.colorScheme.secondary,
                      size: 28),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              children: [
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
                if (dueTimeStr.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Text(
                      dueTimeStr,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.secondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                if ((task['snoozeCount'] ?? 0) > 0)
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Icon(Icons.snooze, color: Colors.orange, size: 20),
                  ),
              ],
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
