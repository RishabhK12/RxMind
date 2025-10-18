import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:rxmind_app/services/discharge_data_manager.dart';
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
    // TODO: Implement edit modal or navigation
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

                  // Parse dates
                  DateTime? dueDateTime;
                  if (taskMap['dueDate'] != null &&
                      taskMap['dueDate'].toString() != 'null') {
                    final dateStr = taskMap['dueDate'].toString();
                    final timeStr = (taskMap['dueTime'] != null &&
                            taskMap['dueTime'].toString() != 'null')
                        ? taskMap['dueTime'].toString()
                        : '00:00';

                    try {
                      dueDateTime = DateTime.parse('${dateStr}T$timeStr');
                    } catch (e) {
                      debugPrint('Error parsing date: $e');
                    }
                  }

                  tasksForStorage.add({
                    'id': UniqueKey().toString(),
                    'title': taskMap['title'] ?? 'Task',
                    'dueTime': dueDateTime?.toIso8601String() ??
                        DateTime.now().toIso8601String(),
                    'isOverdue': false,
                    'snoozeCount': 0,
                    'completed': false,
                    'isRecurring': taskMap['isRecurring'] ?? false,
                    'recurringPattern': taskMap['recurringPattern'],
                    'recurringInterval': taskMap['recurringInterval'],
                    'startDate': taskMap['startDate'] ??
                        dueDateTime?.toIso8601String() ??
                        DateTime.now().toIso8601String(),
                  });
                }
              }
            }
          }
        } catch (e) {
          debugPrint('Error processing tasks from JSON: $e');
        }
      }

      // Add follow-up appointments as tasks if not already added
      for (final followUp in followUps) {
        final String followUpTitle =
            'Follow-up: ${followUp['name'] ?? 'Appointment'}';
        if (tasksForStorage.every((task) => task['title'] != followUpTitle)) {
          tasksForStorage.add({
            'id': UniqueKey().toString(),
            'title': followUpTitle,
            'dueTime': followUp['date'] ??
                DateTime.now().add(const Duration(days: 7)).toIso8601String(),
            'isOverdue': false,
            'snoozeCount': 0,
            'completed': false,
            'isRecurring': false,
          });
        }
      }

      // Add instructions as tasks if not already added
      for (final instruction in instructions) {
        final String instructionTitle =
            instruction['name'] ?? instruction['instruction'] ?? 'Task';
        if (tasksForStorage
            .every((task) => task['title'] != instructionTitle)) {
          tasksForStorage.add({
            'id': UniqueKey().toString(),
            'title': instructionTitle,
            'dueTime': DateTime.now().toIso8601String(),
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
            tooltip: 'Chat with AI Assistant',
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
              thumbVisibility: true,
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
