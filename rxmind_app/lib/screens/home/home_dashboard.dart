import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rxmind_app/services/discharge_data_manager.dart';
import 'package:rxmind_app/services/pdf_export_service.dart';
import 'package:rxmind_app/screens/pdf/pdf_preview_screen.dart';
import 'dart:convert';

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
  List<Map<String, dynamic>> warnings = [];
  List<Map<String, dynamic>> contacts = [];

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _loadWarnings();
    _loadContacts();

    // Register to receive task updates
    DischargeDataManager.addTaskUpdateListener(_refreshDashboard);
  }

  @override
  void dispose() {
    // Remove task update listener when screen is disposed
    DischargeDataManager.removeTaskUpdateListener(_refreshDashboard);
    super.dispose();
  }

  void _refreshDashboard() {
    _loadUserProfile();
  }

  Future<void> _loadWarnings() async {
    final prefs = await SharedPreferences.getInstance();
    final String? warningsJson = prefs.getString('warnings');

    if (warningsJson != null && warningsJson.isNotEmpty) {
      try {
        final List<dynamic> parsedWarnings = jsonDecode(warningsJson);
        setState(() {
          warnings = List<Map<String, dynamic>>.from(parsedWarnings);
        });
      } catch (e) {
        // Error parsing warnings data
      }
    }
  }

  Future<void> _loadContacts() async {
    final prefs = await SharedPreferences.getInstance();
    final String? contactsJson = prefs.getString('contacts');

    if (contactsJson != null && contactsJson.isNotEmpty) {
      try {
        final List<dynamic> parsedContacts = jsonDecode(contactsJson);
        setState(() {
          contacts = List<Map<String, dynamic>>.from(parsedContacts);
        });
      } catch (e) {
        // Error parsing contacts data
      }
    }
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

        // Skip warnings - they'll be shown in the warnings widget
        if (task['type'] == 'warning') continue;

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
                'taskId': task['id'],
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

                // Only show recurring tasks if they're due within 3 hours (per requirements)
                // or if they're already overdue
                final timeDifference = nextOccurrence.difference(now);
                if (timeDifference.isNegative || timeDifference.inHours <= 3) {
                  filteredTasks.add({
                    'title': task['title'] ?? 'Task',
                    'progress': task['completed'] == true ? 1.0 : 0.0,
                    'recurring': true,
                    'dueTime': nextOccurrence,
                    'taskId': task['id'],
                  });
                }
                continue;
              } catch (e) {
                // Error calculating recurring task schedule
              }
            }

            filteredTasks.add({
              'title': task['title'] ?? 'Task',
              'progress': task['completed'] == true ? 1.0 : 0.0,
              'recurring': true,
              'taskId': task['id'],
            });
          }
        } catch (e) {
          // Error processing task for dashboard
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

        // Handle both DateTime objects and String representations
        DateTime aTime;
        DateTime bTime;

        if (a['dueTime'] is DateTime) {
          aTime = a['dueTime'] as DateTime;
        } else {
          aTime = DateTime.parse(a['dueTime'].toString());
        }

        if (b['dueTime'] is DateTime) {
          bTime = b['dueTime'] as DateTime;
        } else {
          bTime = DateTime.parse(b['dueTime'].toString());
        }

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

            // Add warnings widget if we have any warnings
            if (warnings.isNotEmpty) ...[
              SliverPadding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                sliver: SliverToBoxAdapter(
                  child: Semantics(
                    label: 'Important Reminders',
                    child: Text(
                      'Important Reminders',
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverToBoxAdapter(
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
                    color: Colors.amber.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                color: Colors.amber.shade700,
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Warnings & Restrictions',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  color: Colors.amber.shade900,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ...warnings.map((warning) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.circle,
                                      size: 8,
                                      color: Colors.amber.shade800,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        warning['text'] ?? '',
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                          color: Colors.grey.shade900,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],

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
                ]),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisExtent: 120,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
              ),
            ),

            // Export Data - Full Width
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              sliver: SliverToBoxAdapter(
                child: Semantics(
                  label: 'Export Data',
                  button: true,
                  child: SizedBox(
                    height: 60,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        try {
                          // Show loading indicator
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (context) => const Center(
                              child: CircularProgressIndicator(),
                            ),
                          );

                          // Generate PDF
                          final pdfFile =
                              await PdfExportService.generateHealthReport();

                          // Close loading dialog
                          if (!context.mounted) return;
                          Navigator.of(context).pop();

                          // Navigate to preview screen
                          if (!context.mounted) return;
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  PdfPreviewScreen(pdfFile: pdfFile),
                            ),
                          );
                        } catch (e) {
                          // Close loading dialog if still open
                          if (context.mounted &&
                              Navigator.of(context).canPop()) {
                            Navigator.of(context).pop();
                          }

                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error exporting PDF: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      icon: Icon(Icons.download,
                          color: theme.colorScheme.onPrimary),
                      label: Text(
                        'Export Health Report',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onPrimary,
                          fontWeight: FontWeight.w500,
                          fontSize: 15,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      // FloatingActionButton removed - task creation is available in the Tasks tab
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
        mainAxisSize: MainAxisSize.min,
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
          const SizedBox(height: 12),
          Flexible(
            child: Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
                fontSize: 15,
                color: theme.colorScheme.onSurface,
              ),
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
