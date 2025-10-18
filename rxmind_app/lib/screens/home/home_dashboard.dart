import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rxmind_app/services/discharge_data_manager.dart';

// Extension to capitalize first letter of string
extension StringExtension on String {
  String capitalize() {
    return isNotEmpty ? '${this[0].toUpperCase()}${substring(1)}' : this;
  }
}

typedef DashboardTabCallback = void Function(int tabIndex);

class HomeDashboardScreen extends StatefulWidget {
  final DashboardTabCallback? onNavigateToTab;
  const HomeDashboardScreen({super.key, this.onNavigateToTab});

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
  String? userName;
  bool dischargeUploaded = false;
  List<Map<String, dynamic>> tasks = [];

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    userName = prefs.getString('userName');
    dischargeUploaded = await DischargeDataManager.isDischargeUploaded();

    if (!dischargeUploaded) {
      setState(() {
        tasks = [
          {
            'title': 'Upload Discharge Paper',
            'progress': 0.0,
            'uploadTask': true
          },
        ];
      });
    } else {
      // Load real tasks from storage
      final storedTasks = await DischargeDataManager.loadTasks();

      // Filter tasks for today and upcoming tasks
      final now = DateTime.now();
      final filteredTasks = <Map<String, dynamic>>[];

      for (final task in storedTasks) {
        // Skip completed tasks
        if (task['completed'] == true) continue;

        try {
          // Handle regular tasks
          if (task['dueTime'] != null) {
            final dueTime = DateTime.parse(task['dueTime'].toString());
            // Only include tasks due today or in the future
            if (!dueTime.isBefore(DateTime(now.year, now.month, now.day))) {
              filteredTasks.add({
                'title': task['title'] ?? 'Task',
                'progress': 0.0,
                'dueTime': dueTime,
              });
            }
          }

          // Handle recurring tasks
          if (task['isRecurring'] == true) {
            final recurringPattern =
                task['recurringPattern']?.toString().toLowerCase() ?? 'daily';

            // Calculate next occurrence for recurring task
            DateTime nextOccurrence;
            if (task['startDate'] != null) {
              try {
                final startDate = DateTime.parse(task['startDate'].toString());
                final now = DateTime.now();
                final recurringInterval = task['recurringInterval'] is int
                    ? task['recurringInterval'] as int
                    : (task['recurringInterval'] != null
                        ? int.tryParse(task['recurringInterval'].toString()) ??
                            1
                        : 1);

                // Calculate next occurrence based on pattern
                switch (recurringPattern) {
                  case 'daily':
                    final daysSinceStart = now.difference(startDate).inDays;
                    final daysToAdd = recurringInterval -
                        (daysSinceStart % recurringInterval);
                    nextOccurrence = now.add(Duration(
                        days: daysToAdd == recurringInterval ? 0 : daysToAdd));
                    break;
                  case 'weekly':
                    final weeksSinceStart =
                        now.difference(startDate).inDays ~/ 7;
                    final weeksToAdd = recurringInterval -
                        (weeksSinceStart % recurringInterval);
                    nextOccurrence = now.add(Duration(
                        days:
                            (weeksToAdd == recurringInterval ? 0 : weeksToAdd) *
                                7));
                    break;
                  case 'monthly':
                    // Simple monthly calculation - can be improved for more complex cases
                    final monthDiff = (now.year - startDate.year) * 12 +
                        now.month -
                        startDate.month;
                    final monthsToAdd =
                        recurringInterval - (monthDiff % recurringInterval);
                    nextOccurrence = DateTime(
                      now.year,
                      now.month +
                          (monthsToAdd == recurringInterval ? 0 : monthsToAdd),
                      startDate.day,
                    );
                    break;
                  default:
                    nextOccurrence = now;
                }

                // For recurring tasks, show them on dashboard with next occurrence date
                filteredTasks.add({
                  'title':
                      '${task['title'] ?? 'Task'} (${recurringPattern.capitalize()})',
                  'progress': task['completed'] == true ? 1.0 : 0.0,
                  'recurring': true,
                  'dueTime': nextOccurrence,
                });
                continue;
              } catch (e) {
                debugPrint('Error calculating recurring task schedule: $e');
              }
            }

            // Fallback if date calculation fails
            filteredTasks.add({
              'title':
                  '${task['title'] ?? 'Task'} (${recurringPattern.capitalize()})',
              'progress': task['completed'] == true ? 1.0 : 0.0,
              'recurring': true,
            });
          }
        } catch (e) {
          debugPrint('Error processing task for dashboard: $e');
        }
      }

      // Sort by due time
      filteredTasks.sort((a, b) {
        if (a['dueTime'] == null && b['dueTime'] == null) {
          return 0;
        }
        if (a['dueTime'] == null) {
          return 1;
        }
        if (b['dueTime'] == null) {
          return -1;
        }

        final aTime = a['dueTime'] as DateTime;
        final bTime = b['dueTime'] as DateTime;
        return aTime.compareTo(bTime);
      });

      // Limit to 5 most important tasks
      final dashboardTasks = filteredTasks.take(5).toList();

      if (dashboardTasks.isEmpty) {
        dashboardTasks.add({
          'title': 'No upcoming tasks',
          'progress': 1.0,
        });
      }

      setState(() {
        tasks = dashboardTasks;
      });
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
        title: Row(
          children: [
            Semantics(
              label: 'User profile avatar',
              button: true,
              child: InkWell(
                borderRadius: BorderRadius.circular(22),
                onTap: () => Navigator.pushNamed(context, '/settings'),
                child: CircleAvatar(
                  radius: 22,
                  backgroundColor: theme.colorScheme.secondary,
                  child: Text(
                    userName != null && userName!.isNotEmpty
                        ? userName![0].toUpperCase()
                        : '?',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: theme.colorScheme.onSecondary,
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Semantics(
              label: userName != null && userName!.isNotEmpty
                  ? 'Welcome $userName'
                  : 'Welcome to RxMind',
              child: Text(
                userName != null && userName!.isNotEmpty
                    ? 'Welcome $userName'
                    : 'Welcome to RxMind',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
      body: AnimatedScale(
        scale: 1.0,
        duration: const Duration(milliseconds: 300),
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              sliver: SliverToBoxAdapter(
                child: Semantics(
                  label: 'Upcoming Tasks',
                  child: Text(
                    'Upcoming Tasks',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 160,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: tasks.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemBuilder: (context, i) {
                    final task = tasks[i];
                    return Semantics(
                      label:
                          'Task: ${task['title']}, progress ${(task['progress'] * 100).round()} percent',
                      child: GestureDetector(
                        onTap: () {
                          // If it's the upload discharge task, go directly to upload screen
                          if (task['uploadTask'] == true) {
                            Navigator.pushNamed(context, '/uploadOptions');
                          } else {
                            // Otherwise go to tasks tab
                            widget.onNavigateToTab?.call(2); // 2 = Tasks tab
                          }
                        },
                        child: _TaskCard(
                          title: task['title'],
                          progress: task['progress'],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              sliver: SliverGrid(
                delegate: SliverChildListDelegate([
                  Semantics(
                    label: 'Upload Discharge',
                    button: true,
                    child: _ActionTile(
                      icon: Icons.upload_file,
                      label: 'Upload Discharge',
                      color: theme.colorScheme.primary,
                      onTap: () =>
                          Navigator.pushNamed(context, '/uploadOptions'),
                    ),
                  ),
                  Semantics(
                    label: 'Medications',
                    button: true,
                    child: _ActionTile(
                      icon: FontAwesomeIcons.pills,
                      label: 'Medications',
                      color: theme.colorScheme.secondary,
                      onTap: () => widget.onNavigateToTab
                          ?.call(3), // 3 = Medications tab
                    ),
                  ),
                  Semantics(
                    label: 'Tasks & Reminders',
                    button: true,
                    child: _ActionTile(
                      icon: Icons.checklist_rtl,
                      label: 'Tasks & Reminders',
                      color: theme.colorScheme.primary,
                      onTap: () =>
                          widget.onNavigateToTab?.call(2), // 2 = Tasks tab
                    ),
                  ),
                  Semantics(
                    label: 'Stats',
                    button: true,
                    child: _ActionTile(
                      icon: Icons.bar_chart,
                      label: 'Stats',
                      color: theme.colorScheme.secondary,
                      onTap: () =>
                          widget.onNavigateToTab?.call(1), // 1 = Charts tab
                    ),
                  ),
                  Semantics(
                    label: 'Export Data',
                    button: true,
                    child: _ActionTile(
                      icon: Icons.download,
                      label: 'Export Data',
                      color: theme.colorScheme.primary,
                      onTap: () async {
                        // TODO: Implement PDF export with correct imports
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text('Export feature coming soon.')),
                        );
                      },
                    ),
                  ),
                ]),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisExtent: 120,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Semantics(
        label: 'Add new task',
        button: true,
        child: FloatingActionButton(
          backgroundColor: theme.colorScheme.secondary,
          child: const Icon(Icons.add, size: 28, color: Colors.white),
          onPressed: () async {
            final result = await showDialog<Map<String, dynamic>>(
              context: context,
              builder: (context) {
                final _titleController = TextEditingController();
                DateTime? _selectedDate;
                TimeOfDay? _selectedTime;
                bool _repeat = false;
                int _repeatEvery = 1;
                String _repeatPeriod = 'day';
                return StatefulBuilder(
                  builder: (context, setState) => AlertDialog(
                    title: const Text('Create New Task'),
                    content: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextField(
                            controller: _titleController,
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
                                      initialDate: DateTime.now(),
                                      firstDate: DateTime(2020),
                                      lastDate: DateTime(2100),
                                    );
                                    if (picked != null) {
                                      setState(() => _selectedDate = picked);
                                    }
                                  },
                                  child: Text(_selectedDate == null
                                      ? 'Pick Date'
                                      : '${_selectedDate!.month}/${_selectedDate!.day}/${_selectedDate!.year}'),
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
                                      setState(() => _selectedTime = picked);
                                    }
                                  },
                                  child: Text(_selectedTime == null
                                      ? 'Pick Time'
                                      : _selectedTime!.format(context)),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Checkbox(
                                value: _repeat,
                                onChanged: (v) =>
                                    setState(() => _repeat = v ?? false),
                              ),
                              const Text('Repeat'),
                              if (_repeat) ...[
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
                                        _repeatEvery = int.tryParse(v) ?? 1),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                DropdownButton<String>(
                                  value: _repeatPeriod,
                                  items: const [
                                    DropdownMenuItem(
                                        value: 'day', child: Text('day')),
                                    DropdownMenuItem(
                                        value: 'week', child: Text('week')),
                                    DropdownMenuItem(
                                        value: 'month', child: Text('month')),
                                  ],
                                  onChanged: (v) => setState(
                                      () => _repeatPeriod = v ?? 'day'),
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
                          if (_titleController.text.trim().isEmpty ||
                              _selectedDate == null ||
                              _selectedTime == null) return;
                          Navigator.pop(context, {
                            'title': _titleController.text.trim(),
                            'date': _selectedDate,
                            'time': _selectedTime,
                            'repeat': _repeat,
                            'repeatEvery': _repeatEvery,
                            'repeatPeriod': _repeatPeriod,
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
              // TODO: Save the new task to persistent storage or state
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Task "${result['title']}" created!')),
              );
            }
          },
        ),
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final String title;
  final double progress;
  const _TaskCard({required this.title, required this.progress});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 180,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 48,
                height: 48,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 5,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  valueColor:
                      AlwaysStoppedAnimation(theme.colorScheme.secondary),
                ),
              ),
              Text(
                '${(progress * 100).round()}%',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w500,
              fontSize: 16,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionTile(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Ink(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 12),
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                fontSize: 15,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
