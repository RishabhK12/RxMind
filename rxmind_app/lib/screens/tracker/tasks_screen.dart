import 'package:flutter/material.dart';
import 'package:rxmind_app/services/discharge_data_manager.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  List<Map<String, dynamic>> tasksList = [];
  bool dischargeUploaded = false;

  @override
  void initState() {
    super.initState();
    _loadDischargeStatus();
  }

  Future<void> _loadDischargeStatus() async {
    final uploaded = await DischargeDataManager.isDischargeUploaded();
    final tasks = await DischargeDataManager.loadTasks();

    setState(() {
      dischargeUploaded = uploaded;
      if (uploaded && tasks.isNotEmpty) {
        tasksList = tasks.map((task) {
          // Parse dueTime if it's a string
          DateTime? dueTime;
          if (task['dueTime'] is String) {
            try {
              dueTime = DateTime.parse(task['dueTime']);
            } catch (e) {
              dueTime = DateTime.now();
            }
          } else if (task['dueTime'] is DateTime) {
            dueTime = task['dueTime'];
          } else {
            dueTime = DateTime.now();
          }

          return {
            'id': task['id'] ?? UniqueKey().toString(),
            'title': task['title'] ?? 'Task',
            'dueTime': dueTime,
            'isOverdue': task['isOverdue'] ?? false,
            'snoozeCount': task['snoozeCount'] ?? 0,
            'completed': task['completed'] ?? false,
          };
        }).toList();
      } else {
        tasksList = [];
      }
    });
  }

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

  // Removed unused _snoozeTask function

  void _escalateReminder(Map<String, dynamic> task) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('High-priority reminder for ${task['title']}!')),
    );
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
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                    children: [
                      for (final task in _safeTasksList)
                        Semantics(
                          key: ValueKey(task['id']),
                          label:
                              'Task: ${task['title']}${task['isOverdue'] ? ', overdue' : ''}',
                          child: _buildTaskCard(context, task),
                        ),
                      if (_safeTasksList.isEmpty && !dischargeUploaded)
                        Semantics(
                          label: 'Upload Discharge Paper',
                          button: true,
                          child: GestureDetector(
                            onTap: () =>
                                Navigator.pushNamed(context, '/uploadOptions'),
                            child: Container(
                              margin: const EdgeInsets.symmetric(
                                  vertical: 6, horizontal: 8),
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
                                border: Border.all(
                                    color: theme.colorScheme.primary, width: 2),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.upload_file,
                                      color: theme.colorScheme.primary,
                                      size: 28),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Upload Discharge Paper',
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 16,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      if (_safeTasksList.isEmpty && dischargeUploaded)
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            'No tasks yet. Tap + to add a new task.',
                            style: theme.textTheme.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: dischargeUploaded
          ? Semantics(
              label: 'Add new task',
              button: true,
              child: FloatingActionButton(
                backgroundColor: theme.colorScheme.secondary,
                child: const Icon(Icons.add, size: 28, color: Colors.white),
                onPressed: () async {
                  // TODO: Implement manual task creation
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('Manual task creation coming soon!')),
                  );
                },
              ),
            )
          : null,
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
