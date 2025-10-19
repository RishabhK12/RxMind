import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:rxmind_app/services/discharge_data_manager.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

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
  bool _loading = true;
  bool _didRun = false;
  String _rawOcrText = '';
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
    // Get the parsed JSON from the route arguments
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    _rawOcrText = args?['ocrText'] as String? ?? '';
    final parsedJsonString = args?['parsedJson'] as String? ?? '';

    if (parsedJsonString.isNotEmpty) {
      try {
        // Extract JSON from the response (handle markdown code blocks)
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

        // Extract contacts
        if (parsed.containsKey('contacts') && parsed['contacts'] is List) {
          contacts = (parsed['contacts'] as List)
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
        }
      } catch (e) {
        // If parsing fails, use dummy data
        medications = [
          {'name': 'Aspirin', 'dose': '81mg', 'frequency': 'Daily'},
          {'name': 'Lisinopril', 'dose': '10mg', 'frequency': 'Morning'},
        ];
        followUps = [
          {'name': 'Cardiology', 'date': '2025-08-10 10:00 AM'},
        ];
        instructions = [
          {'name': 'No heavy lifting for 2 weeks.'},
          {'name': 'Monitor blood pressure daily.'},
        ];
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error parsing data: $e')),
        );
      }
    } else {
      // Use dummy data if no parsed data available
      medications = [
        {'name': 'Aspirin', 'dose': '81mg', 'frequency': 'Daily'},
        {'name': 'Lisinopril', 'dose': '10mg', 'frequency': 'Morning'},
      ];
      followUps = [
        {'name': 'Cardiology', 'date': '2025-08-10 10:00 AM'},
      ];
      instructions = [
        {'name': 'No heavy lifting for 2 weeks.'},
        {'name': 'Monitor blood pressure daily.'},
      ];
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
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
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
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString(
                    'warnings', jsonEncode(warningsForStorage));
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
        rawOcrText: _rawOcrText,
      );

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Discharge data saved successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Dismiss loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving data: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Discharge Summary'),
        actions: [
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.robot),
            tooltip: 'Chat with Health Assistant',
            onPressed: () {
              Navigator.pushNamed(context, '/chat',
                  arguments: {'initial_context': _rawOcrText});
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Scrollbar(
              controller: _scrollController,
              child: ListView(
                controller: _scrollController,
                padding: const EdgeInsets.all(16.0),
                children: [
                  Semantics(
                    label: 'Medications section',
                    child: _buildSection(
                      context: context,
                      icon: FontAwesomeIcons.pills,
                      iconColor: theme.colorScheme.secondary,
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
                  Semantics(
                    label: 'Follow-Ups section',
                    child: _buildSection(
                      context: context,
                      icon: Icons.calendar_today,
                      iconColor: theme.colorScheme.primary,
                      title: 'Follow-Ups',
                      items: followUps,
                      itemBuilder: (item) => _buildItemTile(
                        context,
                        item,
                        subtitle: item['date'],
                      ),
                    ),
                  ),
                  Semantics(
                    label: 'Instructions section',
                    child: _buildSection(
                      context: context,
                      icon: Icons.menu_book,
                      iconColor: theme.colorScheme.onSurface.withAlpha(153),
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
          padding: const EdgeInsets.all(16),
          color: theme.colorScheme.surface,
          child: ElevatedButton(
            onPressed: _confirmAndSave,
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.secondary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 4,
            ),
            child: const Text('Confirm & Continue'),
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required List<Map<String, dynamic>> items,
    required Widget Function(Map<String, dynamic>) itemBuilder,
  }) {
    final theme = Theme.of(context);
    return ExpansionTile(
      leading: Icon(icon, color: iconColor, size: 28),
      title: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          fontSize: 18,
          color: theme.colorScheme.onSurface,
        ),
      ),
      childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: items.map(itemBuilder).toList(),
    );
  }

  Widget _buildItemTile(BuildContext context, Map<String, dynamic> item,
      {String? subtitle}) {
    final theme = Theme.of(context);
    return ListTile(
      title: Text(
        item['name'] ?? 'Unnamed Item',
        style: theme.textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w500,
          fontSize: 16,
          color: theme.colorScheme.onSurface,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withAlpha(153),
                fontSize: 14,
              ),
            )
          : null,
      trailing: IconButton(
        icon:
            Icon(Icons.edit, color: theme.colorScheme.onSurface.withAlpha(153)),
        onPressed: () => _editItem(item),
      ),
      onTap: () => _editItem(item),
    );
  }
}
