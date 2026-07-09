import 'package:flutter/material.dart';
import 'package:rxmind_app/services/discharge_data_manager.dart';
import 'package:rxmind_app/theme/theme_tokens.dart';
import 'package:rxmind_app/widgets/rx_card.dart';
import 'package:rxmind_app/widgets/rx_primary_button.dart';
import 'dart:convert';

class ParsedSummaryScreen extends StatefulWidget {
  final Map<String, dynamic>? parsedJson;
  const ParsedSummaryScreen({super.key, this.parsedJson});

  @override
  State<ParsedSummaryScreen> createState() => _ParsedSummaryScreenState();
}

class _ParsedSummaryScreenState extends State<ParsedSummaryScreen> {
  List<Map<String, dynamic>> medications = [];
  List<Map<String, dynamic>> followUps = [];
  List<Map<String, dynamic>> instructions = [];
  List<Map<String, dynamic>> contacts = [];
  List<Map<String, dynamic>> warnings = [];
  List<Map<String, dynamic>> tasks = [];
  bool _loading = true;
  bool _didRun = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didRun) {
      _didRun = true;
      _parseDischargeData();
    }
  }

  Future<void> _parseDischargeData() async {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final parsedJsonString = args?['parsedJson'] as String? ?? '';

    if (parsedJsonString.isNotEmpty) {
      try {
        String jsonStr = parsedJsonString;
        final jsonStart = parsedJsonString.indexOf('{');
        final jsonEnd = parsedJsonString.lastIndexOf('}');
        if (jsonStart != -1 && jsonEnd != -1) {
          jsonStr = parsedJsonString.substring(jsonStart, jsonEnd + 1);
        }

        final Map<String, dynamic> parsed = jsonDecode(jsonStr);

        // Extract medications
        if (parsed.containsKey('medications') &&
            parsed['medications'] is List) {
          medications = (parsed['medications'] as List)
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
        }

        // Extract follow-ups
        if (parsed.containsKey('follow_ups') && parsed['follow_ups'] is List) {
          followUps = (parsed['follow_ups'] as List)
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
        }

        // Extract instructions
        if (parsed.containsKey('instructions') &&
            parsed['instructions'] is List) {
          instructions = (parsed['instructions'] as List)
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
        }

        // Extract warnings and restrictions dynamically
        if (parsed.containsKey('tasks') && parsed['tasks'] is List) {
          final List<Map<String, dynamic>> allTasks = (parsed['tasks'] as List)
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();

          tasks = [];
          warnings = [];

          for (final task in allTasks) {
            final description =
                task['description']?.toString().toLowerCase() ?? '';

            // Check for keywords to categorize as warnings/restrictions
            if (description.contains('do not') ||
                description.contains('no driving') ||
                description.contains('use crutches')) {
              warnings.add(task);
            } else {
              tasks.add(task);
            }
          } // Ensure this closing brace is present and properly aligned
        }

        // Simplify language dynamically
        final Map<String, String> simplifications = {
          'ambulation': 'walking',
          'submerge': 'immerse',
          'orthopedics': 'bone doctor',
        };

        tasks = tasks.map((task) {
          if (task['description'] != null) {
            String description = task['description'];
            simplifications.forEach((complex, simple) {
              description = description.replaceAll(complex, simple);
            });
            task['description'] = description;
          }
          return task;
        }).toList();

        warnings = warnings.map((warning) {
          if (warning['description'] != null) {
            String description = warning['description'];
            simplifications.forEach((complex, simple) {
              description = description.replaceAll(complex, simple);
            });
            warning['description'] = description;
          }
          return warning;
        }).toList();
      } catch (e) {
        medications = [];
        followUps = [];
        instructions = [];
        warnings = [];
        tasks = [];
        final theme = Theme.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error parsing data: $e',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onError,
              ),
            ),
            backgroundColor: theme.colorScheme.error,
          ),
        );
      }
    }

    setState(() {
      _loading = false;
    });
  }

  void _editItem(Map<String, dynamic> item) {
    // Edit functionality to be implemented
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _confirmAndSave() async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: CircularProgressIndicator(
          color: Theme.of(context).colorScheme.secondary,
        ),
      ),
    );

    try {
      // Convert medications to the format expected by medications_screen
      final medicationsForStorage = medications.map((med) {
        return {
          'name': med['name'] ?? 'Unknown Medication',
          'dose': med['dose'] ?? '',
          'frequency': med['frequency'] ?? 'As needed',
          'nextDoseTime': DateTime.now().toIso8601String(),
          'isOverdue': false,
        };
      }).toList();

      // Convert follow-ups and instructions to tasks
      final tasksForStorage = <Map<String, dynamic>>[];

      // Parse tasks from JSON if available
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null &&
          args.containsKey('parsedJson') &&
          args['parsedJson'] is String) {
        try {
          final jsonStr = args['parsedJson'] as String;
          final jsonStart = jsonStr.indexOf('{');
          final jsonEnd = jsonStr.lastIndexOf('}');

          if (jsonStart != -1 && jsonEnd != -1) {
            final extractedJson = jsonStr.substring(jsonStart, jsonEnd + 1);
            final Map<String, dynamic> parsed = jsonDecode(extractedJson);

            // Handle parsed tasks
            if (parsed.containsKey('tasks') && parsed['tasks'] is List) {
              final tasks = parsed['tasks'] as List;
              for (final task in tasks) {
                if (task is Map) {
                  // Convert task to proper format
                  final Map<String, dynamic> taskMap =
                      Map<String, dynamic>.from(task);

                  // Skip tasks with type='warning' - they go in warnings section only
                  final String taskType = taskMap['type']?.toString() ?? 'task';
                  if (taskType == 'warning') {
                    continue; // Don't add warnings as tasks
                  }

                  // Check if this task has a specific date from the discharge paper
                  final bool hasSpecificDate =
                      taskMap['hasSpecificDate'] == true;

                  final now = DateTime.now();
                  final tomorrow = DateTime(now.year, now.month, now.day)
                      .add(const Duration(days: 1));

                  DateTime? dueDateTime;

                  if (hasSpecificDate &&
                      taskMap['dueDate'] != null &&
                      taskMap['dueDate'].toString() != 'null') {
                    // This task has a specific date from the discharge paper - USE IT EXACTLY!
                    final dateStr = taskMap['dueDate'].toString();
                    final timeStr = (taskMap['dueTime'] != null &&
                            taskMap['dueTime'].toString() != 'null')
                        ? taskMap['dueTime'].toString()
                        : '09:00';

                    try {
                      // Parse and preserve the EXACT date from the discharge paper
                      dueDateTime = DateTime.parse('${dateStr}T$timeStr');
                    } catch (e) {
                      // If parsing fails, fall back to default
                      dueDateTime = DateTime(
                        tomorrow.year,
                        tomorrow.month,
                        tomorrow.day,
                        9,
                        0,
                      );
                    }
                  } else if (taskMap['dueDate'] != null &&
                      taskMap['dueDate'].toString() != 'null') {
                    // No specific date - this is a recurring task, start tomorrow
                    final dateStr = taskMap['dueDate'].toString();
                    final timeStr = (taskMap['dueTime'] != null &&
                            taskMap['dueTime'].toString() != 'null')
                        ? taskMap['dueTime'].toString()
                        : '09:00';

                    try {
                      // Parse the original time
                      final parsedTime = DateTime.parse('${dateStr}T$timeStr');
                      // Set the date to tomorrow to avoid overdue status for recurring tasks
                      dueDateTime = DateTime(
                        tomorrow.year,
                        tomorrow.month,
                        tomorrow.day,
                        parsedTime.hour,
                        parsedTime.minute,
                      );
                    } catch (e) {
                      // Use default if parsing fails - tomorrow at 9 AM
                      dueDateTime = DateTime(
                        tomorrow.year,
                        tomorrow.month,
                        tomorrow.day,
                        9,
                        0,
                      );
                    }
                  } else {
                    // No date specified - use tomorrow at 9 AM
                    dueDateTime = DateTime(
                      tomorrow.year,
                      tomorrow.month,
                      tomorrow.day,
                      9,
                      0,
                    );
                  }

                  tasksForStorage.add({
                    'id': UniqueKey().toString(),
                    'title': taskMap['title'] ?? 'Task',
                    'description': taskMap['description'],
                    'dueTime': dueDateTime.toIso8601String(),
                    'isOverdue': false,
                    'snoozeCount': 0,
                    'completed': false,
                    'isRecurring': taskMap['isRecurring'] ?? false,
                    'recurringPattern': taskMap['recurringPattern'],
                    'recurringInterval': taskMap['recurringInterval'],
                    'startDate': dueDateTime.toIso8601String(),
                    'type': taskMap['type'] ?? 'task',
                    'category': taskMap['category'],
                    'priority': taskMap['priority'],
                    'hasSpecificDate': hasSpecificDate,
                  });
                }
              }
            }

            // Process warnings if they exist
            if (parsed.containsKey('warnings') && parsed['warnings'] is List) {
              List<Map<String, dynamic>> warningsForStorage = [];
              final warningsArray = parsed['warnings'] as List;

              for (final warningObj in warningsArray) {
                if (warningObj is Map) {
                  final String warningText =
                      warningObj['text']?.toString() ?? '';
                  if (warningText.isNotEmpty) {
                    warningsForStorage.add({
                      'id': UniqueKey().toString(),
                      'text': warningText,
                    });
                  }
                }
              }

              // Save warnings using the same mechanism as other data
              if (warningsForStorage.isNotEmpty) {
                await DischargeDataManager.saveWarnings(warningsForStorage);
              }
            }
          }
        } catch (e) {
          // Continue processing
        }
      }

      // Add follow-up appointments as tasks if not already added
      final now = DateTime.now();
      final tomorrow =
          DateTime(now.year, now.month, now.day).add(const Duration(days: 1));

      for (final followUp in followUps) {
        final String followUpTitle =
            'Follow-up: ${followUp['name'] ?? 'Appointment'}';
        if (tasksForStorage.every((task) => task['title'] != followUpTitle)) {
          // Check if follow-up has a specific date
          final bool hasSpecificDate = followUp['hasSpecificDate'] == true;

          DateTime followUpDateTime;
          try {
            if (followUp['date'] != null &&
                followUp['date'].toString().isNotEmpty) {
              // Try to parse the date string in various formats
              String dateStr = followUp['date'].toString();

              // Handle "YYYY-MM-DD HH:MM" format
              if (dateStr.contains(' ')) {
                final parts = dateStr.split(' ');
                followUpDateTime = DateTime.parse('${parts[0]}T${parts[1]}');
              } else {
                // Just a date without time
                followUpDateTime = DateTime.parse(dateStr);
              }

              // If this has a specific date from discharge paper, DON'T override it
              // Only ensure it's not in the past for non-specific dates
              if (!hasSpecificDate && followUpDateTime.isBefore(tomorrow)) {
                followUpDateTime =
                    DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 9, 0);
              }
            } else {
              followUpDateTime =
                  DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 9, 0);
            }
          } catch (e) {
            followUpDateTime =
                DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 9, 0);
          }

          tasksForStorage.add({
            'id': UniqueKey().toString(),
            'title': followUpTitle,
            'description':
                'Follow-up appointment for ${followUp['name'] ?? 'medical care'}',
            'dueTime': followUpDateTime.toIso8601String(),
            'isOverdue': false,
            'snoozeCount': 0,
            'completed': false,
            'isRecurring': false,
            'hasSpecificDate': hasSpecificDate,
          });
        }
      }

      // Add instructions as tasks if not already added
      for (final instruction in instructions) {
        final String instructionTitle =
            instruction['name'] ?? instruction['instruction'] ?? 'Task';
        if (tasksForStorage
            .every((task) => task['title'] != instructionTitle)) {
          // Set all instruction tasks to tomorrow at 9 AM
          final tomorrowMorning =
              DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 9, 0);

          tasksForStorage.add({
            'id': UniqueKey().toString(),
            'title': instructionTitle,
            'description': instruction['description'] ?? instructionTitle,
            'dueTime': tomorrowMorning.toIso8601String(),
            'isOverdue': false,
            'snoozeCount': 0,
            'completed': false,
            'isRecurring': false,
          });
        }
      }

      // Save to persistent storage
      await DischargeDataManager.saveDischargeData(
        medications: medicationsForStorage,
        tasks: tasksForStorage,
        followUps: followUps,
        instructions: instructions,
      );

      await DischargeDataManager.purgeRawOcrText();

      // Save contacts separately
      if (contacts.isNotEmpty) {
        // Load existing contacts and merge with new ones (avoiding duplicates)
        final existingContacts = await DischargeDataManager.loadContacts();
        final allContacts = [...existingContacts, ...contacts];

        // Remove duplicates based on phone number
        final uniqueContacts = <String, Map<String, dynamic>>{};
        for (final contact in allContacts) {
          final phone = contact['phone']?.toString() ?? '';
          if (phone.isNotEmpty) {
            uniqueContacts[phone] = contact;
          }
        }

        await DischargeDataManager.saveContacts(uniqueContacts.values.toList());
      }

      if (!mounted) return;
      Navigator.pop(context); // Dismiss loading dialog

      // Navigate to main app
      Navigator.of(context)
          .pushNamedAndRemoveUntil('/mainNav', (Route<dynamic> route) => false);

      // Show success message
      final theme = Theme.of(context);
      final ext = RxMindThemeExtension.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Discharge data saved successfully!',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSecondary,
            ),
          ),
          backgroundColor: ext.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Dismiss loading dialog
      final theme = Theme.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error saving data: $e',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onError,
            ),
          ),
          backgroundColor: theme.colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        title: Text('Discharge Summary', style: theme.textTheme.titleLarge),
        actions: [
          IconButton(
            icon: Icon(
              Icons.smart_toy_outlined,
              color: theme.colorScheme.primary,
            ),
            tooltip: 'Chat with Wellness Guide',
            onPressed: () async {
              final meds = await DischargeDataManager.loadMedications();
              final tasks = await DischargeDataManager.loadTasks();
              if (!context.mounted) return;
              Navigator.pushNamed(context, '/chat', arguments: {
                'structured_context': {
                  'medications': meds,
                  'tasks': tasks,
                },
              });
            },
          ),
        ],
      ),
      body: _loading
          ? Center(
              child: CircularProgressIndicator(
                color: theme.colorScheme.secondary,
              ),
            )
          : Scrollbar(
              controller: _scrollController,
              child: ListView(
                controller: _scrollController,
                padding: const EdgeInsets.all(ThemeTokens.spacingMd),
                children: [
                  Semantics(
                    label: 'Medications section',
                    child: _buildSection(
                      context: context,
                      icon: Icons.medication,
                      iconColor: theme.colorScheme.secondary,
                      wellColor: ThemeTokens.emerald50,
                      title: 'Medications',
                      items: medications,
                      itemBuilder: (item) => _buildItemTile(
                        context,
                        item,
                        subtitle:
                            'Dose: ${item['dose']} • Frequency: ${item['frequency']}',
                      ),
                    ),
                  ),
                  const SizedBox(height: ThemeTokens.spacingMd),
                  Semantics(
                    label: 'Follow-Ups section',
                    child: _buildSection(
                      context: context,
                      icon: Icons.calendar_today,
                      iconColor: theme.colorScheme.primary,
                      wellColor: ThemeTokens.blue50,
                      title: 'Follow-Ups',
                      items: followUps,
                      itemBuilder: (item) => _buildItemTile(
                        context,
                        item,
                        subtitle: item['date'],
                      ),
                    ),
                  ),
                  const SizedBox(height: ThemeTokens.spacingMd),
                  Semantics(
                    label: 'Instructions section',
                    child: _buildSection(
                      context: context,
                      icon: Icons.menu_book,
                      iconColor:
                          theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      wellColor: ThemeTokens.amber50,
                      title: 'Instructions',
                      items: instructions,
                      itemBuilder: (item) => _buildItemTile(
                        context,
                        item,
                        subtitle: item['name'].toString().length > 40
                            ? '${item['name'].toString().substring(0, 40)}...'
                            : item['name'],
                      ),
                    ),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: Semantics(
        label: 'Confirm and continue',
        button: true,
        child: Container(
          padding: const EdgeInsets.all(ThemeTokens.spacingMd),
          color: theme.colorScheme.surface,
          child: SafeArea(
            child: RxPrimaryButton(
              label: 'Confirm & Continue',
              onPressed: _confirmAndSave,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required Color wellColor,
    required String title,
    required List<Map<String, dynamic>> items,
    required Widget Function(Map<String, dynamic>) itemBuilder,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return RxCard(
      radius: ThemeTokens.radiusMd,
      padding: const EdgeInsets.all(ThemeTokens.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isDark ? ThemeTokens.darkMuted : wellColor,
                  borderRadius: BorderRadius.circular(ThemeTokens.radiusSm),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: ThemeTokens.spacingMd),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: ThemeTokens.spacingSm),
          ...items.map(itemBuilder),
        ],
      ),
    );
  }

  Widget _buildItemTile(BuildContext context, Map<String, dynamic> item,
      {String? subtitle}) {
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        item['name'] ?? 'Unnamed Item',
        style: theme.textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w500,
          color: theme.colorScheme.onSurface,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            )
          : null,
      trailing: IconButton(
        icon: Icon(
          Icons.edit,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
        ),
        onPressed: () => _editItem(item),
      ),
      onTap: () => _editItem(item),
    );
  }
}
