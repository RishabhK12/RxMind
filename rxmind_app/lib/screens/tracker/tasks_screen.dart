import 'package:flutter/material.dart';
import 'package:rxmind_app/services/discharge_data_manager.dart';
import 'package:rxmind_app/screens/stats/compliance_stats.dart';
import 'package:rxmind_app/services/notification_service.dart';
import 'package:rxmind_app/core/task/task_update_helper.dart';

class TasksScreen extends StatefulWidget {
  final GlobalKey<ComplianceStatsScreenState>? complianceStatsKey;

  const TasksScreen({super.key, this.complianceStatsKey});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  List<Map<String, dynamic>> tasksList = [];
  bool dischargeUploaded = false;
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _loadDischargeStatus();

    // Set up a listener to refresh tasks when medications are taken
    DischargeDataManager.addTaskUpdateListener(_loadDischargeStatus);
  }

  @override
  void dispose() {
    // Remove the listener when screen is disposed
    DischargeDataManager.removeTaskUpdateListener(_loadDischargeStatus);
    super.dispose();
  }

  Future<void> _loadDischargeStatus() async {
    final uploaded = await DischargeDataManager.isDischargeUploaded();
    final tasks = await DischargeDataManager.loadTasks();

    // Parse and prepare tasks data
    final List<Map<String, dynamic>> parsedTasks = [];
    final List<Map<String, dynamic>> newCompletedTasks = [];

    if (uploaded && tasks.isNotEmpty) {
      for (var task in tasks) {
        // Parse dueTime if it's a string
        DateTime? dueTime;
        if (task['dueTime'] is String && task['dueTime'] != null) {
          try {
            // Try parsing as full datetime first
            dueTime = DateTime.parse(task['dueTime']);
          } catch (e) {
            // If that fails, try parsing as time only (HH:MM format)
            try {
              final timeParts = (task['dueTime'] as String).split(':');
              if (timeParts.length == 2) {
                final now = DateTime.now();
                dueTime = DateTime(now.year, now.month, now.day,
                    int.parse(timeParts[0]), int.parse(timeParts[1]));
              }
            } catch (e2) {
              dueTime = null; // No valid time
            }
          }
        } else if (task['dueTime'] is DateTime) {
          dueTime = task['dueTime'];
        } else {
          dueTime = null; // No time specified
        }

        final parsedTask = {
          'id': task['id'] ?? UniqueKey().toString(),
          'title': task['title'] ?? 'Task',
          'description': task['description'], // Preserve description
          'dueTime': dueTime,
          'isOverdue': task['isOverdue'] ?? false,
          'snoozeCount': task['snoozeCount'] ?? 0,
          'completed': task['completed'] ?? false,
          'isRecurring': task['isRecurring'] ?? false,
          'recurringPattern': task['recurringPattern'],
          'recurringInterval': task['recurringInterval'],
          'lastCompleted': task['lastCompleted'],
          'nextOccurrence': task['nextOccurrence'],
          'showAfter': task['showAfter'],
          'startDate': task['startDate'],
          'dueDate': task['dueDate'],
          'type': task['type'],
          'category': task['category'], // Preserve category
          'priority': task['priority'], // Preserve priority
        };

        parsedTasks.add(parsedTask);

        // If task is completed, add to completed tasks list
        if (parsedTask['completed'] == true) {
          newCompletedTasks.add({...parsedTask});
        }
      }
    }

    // Now update state with all the new data (only if widget is still mounted)
    if (mounted) {
      setState(() {
        dischargeUploaded = uploaded;
        tasksList = parsedTasks;
        completedTasks = newCompletedTasks;
      });
    }
  }

  List<Map<String, dynamic>> completedTasks = [];
  bool showCompletedDropdown = false;

  // Ensure all tasks have unique, non-null IDs before building the list
  List<Map<String, dynamic>> get _safeTasksList {
    final seen = <dynamic>{};
    final now = DateTime.now();

    for (final task in tasksList) {
      if (task['id'] == null || seen.contains(task['id'])) {
        task['id'] = UniqueKey().toString();
      }
      seen.add(task['id']);

      // Update isOverdue status based on current time
      if (task['completed'] != true && task['dueTime'] != null) {
        try {
          DateTime dueTime;
          if (task['dueTime'] is DateTime) {
            dueTime = task['dueTime'] as DateTime;
          } else {
            dueTime = DateTime.parse(task['dueTime'].toString());
          }
          task['isOverdue'] = now.isAfter(dueTime);
        } catch (e) {
          task['isOverdue'] = false;
        }
      } else {
        task['isOverdue'] = false;
      }
    }

    // Filter out completed tasks and recurring tasks that shouldn't show yet
    final list = tasksList.where((t) {
      // Skip ALL completed tasks (they should only appear in the dropdown)
      if (t['completed'] == true) {
        // For recurring tasks, check if they should show again
        if (t['isRecurring'] == true) {
          final showAfter = t['showAfter'];
          if (showAfter != null) {
            try {
              final showAfterTime = DateTime.parse(showAfter);
              // Only show if current time is past the "show after" time
              if (now.isBefore(showAfterTime)) {
                return false;
              }
              // Reset completion status since it's time to show again
              t['completed'] = false;
              t['snoozeCount'] = 0;
              // Update dueTime to the next occurrence
              if (t['nextOccurrence'] != null) {
                t['dueTime'] = t['nextOccurrence'];
                t['nextOccurrence'] = null;
                t['showAfter'] = null;
              }
              // Now it's not completed, so allow it to show
              return true;
            } catch (e) {
              // If parsing fails, don't show
              return false;
            }
          } else {
            // Recurring task with no showAfter time - don't show if completed
            return false;
          }
        }
        // Non-recurring completed task - never show in main list
        return false;
      }

      return true;
    }).toList();

    // Sort by dueTime ascending (tasks with no time go to end)
    list.sort((a, b) {
      if (a['dueTime'] == null && b['dueTime'] == null) return 0;
      if (a['dueTime'] == null) return 1;
      if (b['dueTime'] == null) return -1;

      DateTime at;
      DateTime bt;

      try {
        if (a['dueTime'] is DateTime) {
          at = a['dueTime'] as DateTime;
        } else {
          at = DateTime.parse(a['dueTime'].toString());
        }

        if (b['dueTime'] is DateTime) {
          bt = b['dueTime'] as DateTime;
        } else {
          bt = DateTime.parse(b['dueTime'].toString());
        }

        return at.compareTo(bt);
      } catch (e) {
        return 0;
      }
    });
    return list;
  }

  // Removed unused _snoozeTask function

  void _escalateReminder(Map<String, dynamic> task) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('High-priority reminder for ${task['title']}!')),
    );
  }

  String _formatCompletedTime(String? isoString) {
    if (isoString == null) return '';
    try {
      final dateTime = DateTime.parse(isoString);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inMinutes < 60) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}h ago';
      } else {
        return '${difference.inDays}d ago';
      }
    } catch (e) {
      return '';
    }
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

        DateTime currentDueTime;
        if (task['dueTime'] is DateTime) {
          currentDueTime = task['dueTime'] as DateTime;
        } else if (task['dueTime'] != null) {
          currentDueTime = DateTime.parse(task['dueTime'].toString());
        } else {
          currentDueTime = DateTime.now();
        }

        task['dueTime'] = currentDueTime.add(const Duration(hours: 1));
      });
      if (task['snoozeCount'] >= 3) {
        _escalateReminder(task);
      }
      // Save updated tasks
      await DischargeDataManager.saveTasks(tasksList);

      // Reschedule notifications for snoozed task
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
            // Invalid date format
          }
        }

        if (parsedDueTime != null) {
          await _notificationService.scheduleTaskNotifications(
            taskId: taskId,
            taskTitle: taskTitle,
            dueTime: parsedDueTime,
          );
        }
      }
    } else if (result == 'complete') {
      // Use the TaskUpdateHelper to ensure consistent update logic
      final updatedTaskInfo = await TaskUpdateHelper.updateTaskCompletion(
        tasks: tasksList,
        task: task,
        completed: true,
      );

      // Find and update the task in the tasksList with the complete updated info
      final taskIndex = tasksList.indexWhere((t) => t['id'] == task['id']);
      if (taskIndex != -1) {
        tasksList[taskIndex] = updatedTaskInfo;
      }

      setState(() {
        // Update the completed tasks list
        completedTasks.insert(0, {...updatedTaskInfo});
      });

      // Cancel notifications for completed task
      final taskId = task['id']?.toString();
      if (taskId != null) {
        await _notificationService.cancelTaskNotifications(taskId);
      }

      // If recurring, schedule notifications for next occurrence
      if (updatedTaskInfo['isRecurring'] == true &&
          updatedTaskInfo['nextOccurrence'] != null) {
        try {
          final nextDueTime = DateTime.parse(updatedTaskInfo['nextOccurrence']);
          if (taskId != null) {
            await _notificationService.scheduleTaskNotifications(
              taskId: taskId,
              taskTitle: updatedTaskInfo['title']?.toString() ?? 'Task',
              dueTime: nextDueTime,
            );
          }
        } catch (e) {
          // Invalid date format
        }
      }

      // Refresh stats screen immediately
      widget.complianceStatsKey?.currentState?.refreshStats();

      // Animate checkmark
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
                      // Completed tasks dropdown
                      if (completedTasks.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 16),
                          child: Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                ListTile(
                                  leading: Icon(Icons.check_circle,
                                      color: theme.colorScheme.primary),
                                  title: Text(
                                    'Completed Tasks (${completedTasks.length})',
                                    style:
                                        theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  trailing: Icon(
                                    showCompletedDropdown
                                        ? Icons.expand_less
                                        : Icons.expand_more,
                                  ),
                                  onTap: () {
                                    setState(() {
                                      showCompletedDropdown =
                                          !showCompletedDropdown;
                                    });
                                  },
                                ),
                                if (showCompletedDropdown)
                                  ...completedTasks.map((task) {
                                    return ListTile(
                                      leading: Icon(
                                        Icons.check_circle_outline,
                                        color: Colors.green,
                                        size: 20,
                                      ),
                                      title: Text(
                                        task['title'],
                                        style: TextStyle(
                                          decoration:
                                              TextDecoration.lineThrough,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      trailing: task['lastCompleted'] != null
                                          ? Text(
                                              _formatCompletedTime(
                                                  task['lastCompleted']),
                                              style: theme.textTheme.bodySmall
                                                  ?.copyWith(
                                                color: Colors.grey,
                                              ),
                                            )
                                          : null,
                                      onTap: () async {
                                        // Show dialog to mark as incomplete
                                        final result = await showDialog<bool>(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: const Text(
                                                'Mark as Incomplete'),
                                            content: Text(
                                                'Do you want to mark "${task['title']}" as incomplete?'),
                                            actions: [
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.of(context)
                                                        .pop(false),
                                                child: const Text('Cancel'),
                                              ),
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.of(context)
                                                        .pop(true),
                                                child: const Text(
                                                    'Mark Incomplete'),
                                              ),
                                            ],
                                          ),
                                        );

                                        if (result == true) {
                                          // Use TaskUpdateHelper for consistent updates
                                          final updatedTask =
                                              await TaskUpdateHelper
                                                  .updateTaskCompletion(
                                            tasks: tasksList,
                                            task: task,
                                            completed: false,
                                          );

                                          setState(() {
                                            // Remove from completed tasks
                                            completedTasks.remove(task);

                                            // Find and update in tasksList
                                            final index = tasksList.indexWhere(
                                                (t) => t['id'] == task['id']);
                                            if (index != -1) {
                                              tasksList[index] = updatedTask;
                                            } else {
                                              // Add back to tasksList if not found
                                              tasksList.add(updatedTask);
                                            }
                                          });

                                          // Reschedule notifications for the task
                                          final taskId =
                                              updatedTask['id']?.toString();
                                          final dueTime =
                                              updatedTask['dueTime'];

                                          if (taskId != null &&
                                              dueTime != null) {
                                            DateTime? parsedDueTime;

                                            if (dueTime is DateTime) {
                                              parsedDueTime = dueTime;
                                            } else if (dueTime is String) {
                                              try {
                                                parsedDueTime =
                                                    DateTime.parse(dueTime);
                                              } catch (e) {
                                                // Invalid date format
                                              }
                                            }

                                            if (parsedDueTime != null) {
                                              await _notificationService
                                                  .scheduleTaskNotifications(
                                                taskId: taskId,
                                                taskTitle:
                                                    task['title']?.toString() ??
                                                        'Task',
                                                dueTime: parsedDueTime,
                                              );
                                            }
                                          }

                                          // Refresh stats screen immediately
                                          widget
                                              .complianceStatsKey?.currentState
                                              ?.refreshStats();
                                        }
                                      },
                                    );
                                  }),
                              ],
                            ),
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
                  final result = await showDialog<Map<String, dynamic>>(
                    context: context,
                    builder: (context) {
                      final titleController = TextEditingController();
                      final now = DateTime.now();
                      final tomorrow = DateTime(now.year, now.month, now.day)
                          .add(const Duration(days: 1));
                      DateTime? selectedDate = tomorrow; // Default to tomorrow
                      TimeOfDay? selectedTime;
                      bool repeat = false;
                      int repeatEvery = 1;
                      String repeatPeriod = 'day';
                      return StatefulBuilder(
                        builder: (context, setState) => AlertDialog(
                          title: const Text('Create New Task'),
                          content: SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TextField(
                                  controller: titleController,
                                  decoration: const InputDecoration(
                                    labelText: 'Task Title',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: () async {
                                          final picked = await showDatePicker(
                                            context: context,
                                            initialDate: tomorrow,
                                            firstDate: tomorrow,
                                            lastDate: DateTime(2100),
                                          );
                                          if (picked != null) {
                                            setState(
                                                () => selectedDate = picked);
                                          }
                                        },
                                        child: Text(selectedDate == null
                                            ? 'Pick Date'
                                            : '${selectedDate!.month}/${selectedDate!.day}/${selectedDate!.year}'),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: () async {
                                          final picked = await showTimePicker(
                                            context: context,
                                            initialTime: TimeOfDay.now(),
                                          );
                                          if (picked != null) {
                                            setState(
                                                () => selectedTime = picked);
                                          }
                                        },
                                        child: Text(selectedTime == null
                                            ? 'Pick Time'
                                            : selectedTime!.format(context)),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Checkbox(
                                      value: repeat,
                                      onChanged: (v) =>
                                          setState(() => repeat = v ?? false),
                                    ),
                                    const Text('Repeat'),
                                    if (repeat) ...[
                                      const SizedBox(width: 8),
                                      SizedBox(
                                        width: 48,
                                        child: TextField(
                                          keyboardType: TextInputType.number,
                                          decoration: const InputDecoration(
                                            hintText: '1',
                                            border: OutlineInputBorder(),
                                          ),
                                          onChanged: (v) => setState(() =>
                                              repeatEvery =
                                                  int.tryParse(v) ?? 1),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      DropdownButton<String>(
                                        value: repeatPeriod,
                                        items: const [
                                          DropdownMenuItem(
                                              value: 'day', child: Text('day')),
                                          DropdownMenuItem(
                                              value: 'week',
                                              child: Text('week')),
                                          DropdownMenuItem(
                                              value: 'month',
                                              child: Text('month')),
                                        ],
                                        onChanged: (v) => setState(
                                            () => repeatPeriod = v ?? 'day'),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                if (titleController.text.trim().isEmpty ||
                                    selectedDate == null ||
                                    selectedTime == null) {
                                  return;
                                }
                                Navigator.pop(context, {
                                  'title': titleController.text.trim(),
                                  'date': selectedDate,
                                  'time': selectedTime,
                                  'repeat': repeat,
                                  'repeatEvery': repeatEvery,
                                  'repeatPeriod': repeatPeriod,
                                });
                              },
                              child: const Text('Create'),
                            ),
                          ],
                        ),
                      );
                    },
                  );

                  if (result != null) {
                    // Create new task with proper structure
                    final selectedDate = result['date'] as DateTime;
                    final selectedTime = result['time'] as TimeOfDay;
                    final dueTime = DateTime(
                      selectedDate.year,
                      selectedDate.month,
                      selectedDate.day,
                      selectedTime.hour,
                      selectedTime.minute,
                    );

                    final newTask = {
                      'id': UniqueKey().toString(),
                      'title': result['title'],
                      'dueTime': dueTime.toIso8601String(),
                      'completed': false,
                      'isRecurring': result['repeat'] as bool,
                      'recurringPattern': result['repeat'] == true
                          ? (result['repeatPeriod'] == 'day'
                              ? 'daily'
                              : result['repeatPeriod'] == 'week'
                                  ? 'weekly'
                                  : 'monthly')
                          : null,
                      'recurringInterval': result['repeat'] == true
                          ? result['repeatEvery'] as int
                          : null,
                      'startDate': dueTime.toIso8601String(),
                      'isOverdue': false,
                      'type': 'task',
                    };

                    // Add to tasksList
                    setState(() {
                      tasksList.add(newTask);
                    });

                    // Save to storage
                    await DischargeDataManager.saveTasks(tasksList);

                    // Schedule notifications for the new task
                    await _notificationService.scheduleTaskNotifications(
                      taskId: newTask['id'],
                      taskTitle: newTask['title'],
                      dueTime: dueTime,
                    );

                    // Refresh UI
                    await _loadDischargeStatus();

                    // Refresh stats screen
                    widget.complianceStatsKey?.currentState?.refreshStats();

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content:
                                Text('Task "${result['title']}" created!')),
                      );
                    }
                  }
                },
              ),
            )
          : null,
    );
  }

  Widget _buildTaskCard(BuildContext context, Map<String, dynamic> task) {
    final theme = Theme.of(context);

    DateTime? dueTime;
    if (task['dueTime'] != null) {
      if (task['dueTime'] is DateTime) {
        dueTime = task['dueTime'] as DateTime;
      } else {
        try {
          dueTime = DateTime.parse(task['dueTime'].toString());
        } catch (e) {
          dueTime = null;
        }
      }
    }

    final dueTimeStr = dueTime != null
        ? TimeOfDay.fromDateTime(dueTime).format(context)
        : null;

    // Format date as "Mon, Oct 20"
    final dueDateStr = dueTime != null
        ? '${_getDayOfWeekShort(dueTime.weekday)}, ${_getMonthShort(dueTime.month)} ${dueTime.day}'
        : null;

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
            child: GestureDetector(
              onTap: () => _showTaskDetails(context, task),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
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
                      if ((task['snoozeCount'] ?? 0) > 0)
                        Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: Icon(Icons.snooze,
                              color: Colors.orange, size: 20),
                        ),
                    ],
                  ),
                  if (dueDateStr != null || dueTimeStr != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          Icon(
                            Icons.schedule,
                            size: 14,
                            color: theme.colorScheme.secondary.withOpacity(0.7),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${dueDateStr ?? ''} ${dueTimeStr != null ? 'at $dueTimeStr' : ''}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color:
                                  theme.colorScheme.secondary.withOpacity(0.9),
                              fontWeight: FontWeight.w500,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
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

  String _getDayOfWeekShort(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }

  String _getMonthShort(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return months[month - 1];
  }

  void _showTaskDetails(BuildContext context, Map<String, dynamic> task) {
    final theme = Theme.of(context);

    DateTime? dueTime;
    if (task['dueTime'] != null) {
      if (task['dueTime'] is DateTime) {
        dueTime = task['dueTime'] as DateTime;
      } else {
        try {
          dueTime = DateTime.parse(task['dueTime'].toString());
        } catch (e) {
          dueTime = null;
        }
      }
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Task Title
              Text(
                task['title'] ?? 'Task',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Task Details
              if (task['description'] != null &&
                  task['description'].toString().isNotEmpty)
                _buildDetailRow(
                  context,
                  Icons.description,
                  'Description',
                  task['description'].toString(),
                ),

              if (dueTime != null)
                _buildDetailRow(
                  context,
                  Icons.calendar_today,
                  'Due Date',
                  '${_getDayOfWeekShort(dueTime.weekday)}, ${_getMonthShort(dueTime.month)} ${dueTime.day}, ${dueTime.year}',
                ),

              if (dueTime != null)
                _buildDetailRow(
                  context,
                  Icons.access_time,
                  'Time',
                  TimeOfDay.fromDateTime(dueTime).format(context),
                ),

              if (task['isRecurring'] == true)
                _buildDetailRow(
                  context,
                  Icons.repeat,
                  'Recurrence',
                  _getRecurrenceText(task),
                ),

              if (task['type'] != null)
                _buildDetailRow(
                  context,
                  Icons.category,
                  'Type',
                  task['type'].toString().toUpperCase(),
                ),

              if (task['category'] != null)
                _buildDetailRow(
                  context,
                  Icons.label,
                  'Category',
                  task['category'].toString(),
                ),

              if (task['priority'] != null)
                _buildDetailRow(
                  context,
                  Icons.flag,
                  'Priority',
                  task['priority'].toString(),
                ),

              if (task['completed'] == true && task['lastCompleted'] != null)
                _buildDetailRow(
                  context,
                  Icons.check_circle,
                  'Completed',
                  _formatCompletedTime(task['lastCompleted']),
                ),

              const SizedBox(height: 24),

              // Close Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Close',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(
      BuildContext context, IconData icon, String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getRecurrenceText(Map<String, dynamic> task) {
    final pattern = task['recurringPattern']?.toString() ?? 'daily';
    final interval = task['recurringInterval'] ?? 1;

    if (interval == 1) {
      return pattern.replaceFirst('ly', '').substring(0, 1).toUpperCase() +
          pattern.replaceFirst('ly', '').substring(1);
    } else {
      return 'Every $interval ${pattern.replaceFirst('ly', '')}s';
    }
  }
}
