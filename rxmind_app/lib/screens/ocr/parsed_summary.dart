import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ParsedSummaryScreen extends StatefulWidget {
  final Map<String, dynamic>? parsedJson;
  const ParsedSummaryScreen({Key? key, this.parsedJson}) : super(key: key);

  @override
  State<ParsedSummaryScreen> createState() => _ParsedSummaryScreenState();
}

class _ParsedSummaryScreenState extends State<ParsedSummaryScreen> {
  // Dummy data for preview
  final List<Map<String, dynamic>> medications = [
    {'name': 'Aspirin', 'dose': '81mg', 'frequency': 'Daily'},
    {'name': 'Lisinopril', 'dose': '10mg', 'frequency': 'Morning'},
  ];
  final List<Map<String, dynamic>> followUps = [
    {'name': 'Cardiology', 'date': '2025-08-10 10:00 AM'},
  ];
  final List<Map<String, dynamic>> instructions = [
    {'name': 'No heavy lifting for 2 weeks.'},
    {'name': 'Monitor blood pressure daily.'},
  ];

  void _editItem(Map<String, dynamic> item) {
    // TODO: Implement edit modal or navigation
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.background,
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
                    ? item['name'].toString().substring(0, 40) + '...'
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
            onPressed: () {
              // TODO: Save and generate tasks/meds, then navigate
              Navigator.pushReplacementNamed(context, '/tasks');
            },
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
