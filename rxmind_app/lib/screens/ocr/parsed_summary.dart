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

  @override
  void initState() {
    super.initState();
    _parseDischargeData();
  }

  Future<void> _parseDischargeData() async {
    // Get the parsed JSON from the route arguments
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final parsedJsonString = args?['parsedJson'] as String? ?? '';

    if (parsedJsonString.isEmpty) {
      // Use dummy data if no parsed data available
      setState(() {
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
        _loading = false;
      });
      return;
    }

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
      if (parsed.containsKey('medications') && parsed['medications'] is List) {
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

    setState(() {
      _loading = false;
    });
  }

  void _editItem(Map<String, dynamic> item) {
    // TODO: Implement edit modal or navigation
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

      // Add follow-up appointments as tasks
      for (final followUp in followUps) {
        tasksForStorage.add({
          'id': UniqueKey().toString(),
          'title': 'Follow-up: ${followUp['name'] ?? 'Appointment'}',
          'dueTime': followUp['date'] ??
              DateTime.now().add(const Duration(days: 7)).toIso8601String(),
          'isOverdue': false,
          'snoozeCount': 0,
          'completed': false,
        });
      }

      // Add instructions as tasks
      for (final instruction in instructions) {
        tasksForStorage.add({
          'id': UniqueKey().toString(),
          'title': instruction['name'] ?? instruction['instruction'] ?? 'Task',
          'dueTime': DateTime.now().toIso8601String(),
          'isOverdue': false,
          'snoozeCount': 0,
          'completed': false,
        });
      }

      // Save to persistent storage
      await DischargeDataManager.saveDischargeData(
        medications: medicationsForStorage,
        tasks: tasksForStorage,
        followUps: followUps,
        instructions: instructions,
      );

      if (!mounted) return;
      Navigator.pop(context); // Dismiss loading dialog

      // Navigate to main app
      Navigator.pushReplacementNamed(context, '/mainNav');

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

    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 1,
        leading: Semantics(
          label: 'Back',
          button: true,
          child: IconButton(
            icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: Semantics(
          label: 'Review Parsed Data',
          child: Text(
            'Review Parsed Data',
            style: theme.textTheme.titleLarge,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
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
              iconColor: theme.colorScheme.onSurface.withOpacity(0.6),
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
        item['name'],
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
                color: theme.colorScheme.onSurface.withOpacity(0.6),
                fontSize: 14,
              ),
            )
          : null,
      trailing: IconButton(
        icon: Icon(Icons.edit,
            color: theme.colorScheme.onSurface.withOpacity(0.6)),
        onPressed: () => _editItem(item),
      ),
      onTap: () => _editItem(item),
    );
  }
}
