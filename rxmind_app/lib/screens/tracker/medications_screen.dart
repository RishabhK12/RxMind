import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class MedicationsScreen extends StatefulWidget {
  const MedicationsScreen({Key? key}) : super(key: key);

  @override
  State<MedicationsScreen> createState() => _MedicationsScreenState();
}

class _MedicationsScreenState extends State<MedicationsScreen> {
  // Dummy data for preview
  final List<Map<String, dynamic>> medicationsList = [
    {
      'name': 'Aspirin',
      'nextDoseTime': DateTime.now().add(const Duration(hours: 2)),
      'isOverdue': false,
    },
    {
      'name': 'Lisinopril',
      'nextDoseTime': DateTime.now().subtract(const Duration(hours: 1)),
      'isOverdue': true,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 1,
        title: Semantics(
          header: true,
          label: 'My Medications screen',
          child: Text(
            'My Medications',
            style: theme.textTheme.titleLarge,
          ),
        ),
      ),
      body: Semantics(
        label: 'List of medications and next dose times',
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: medicationsList.length,
          itemBuilder: (context, i) {
            final med = medicationsList[i];
            return _MedicationCard(med: med);
          },
        ),
      ),
    );
  }
}

class _MedicationCard extends StatelessWidget {
  final Map<String, dynamic> med;
  const _MedicationCard({required this.med});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final DateTime nextDose = med['nextDoseTime'];
    final bool isOverdue = med['isOverdue'] == true;
    final Duration diff = nextDose.difference(DateTime.now());
    final String countdown = isOverdue
        ? 'Overdue by ${diff.inHours.abs()}h ${diff.inMinutes.abs() % 60}m'
        : 'in ${diff.inHours}h ${diff.inMinutes % 60}m';
    return Semantics(
      container: true,
      label:
          'Medication card for ${med['name']}, next dose ${isOverdue ? 'overdue' : 'in time'}',
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
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
        ),
        child: Row(
          children: [
            Semantics(
              label: 'Medication icon',
              child: Icon(FontAwesomeIcons.pills,
                  color: theme.colorScheme.secondary, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(
                    label: 'Medication name: ${med['name']}',
                    child: Text(
                      med['name'],
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Semantics(
                        label: 'Timer icon',
                        child: Icon(Icons.timer,
                            size: 20, color: theme.colorScheme.primary),
                      ),
                      const SizedBox(width: 6),
                      Semantics(
                        label: isOverdue
                            ? 'Overdue by ${diff.inHours.abs()} hours and ${diff.inMinutes.abs() % 60} minutes'
                            : 'Next dose in ${diff.inHours} hours and ${diff.inMinutes % 60} minutes',
                        child: Text(
                          countdown,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                            color: isOverdue
                                ? theme.colorScheme.error
                                : theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Semantics(
              button: true,
              label: isOverdue
                  ? 'Snooze medication ${med['name']} for 1 hour'
                  : 'Mark medication ${med['name']} as taken',
              child: ElevatedButton(
                onPressed: () {
                  // TODO: Mark as taken, update nextDoseTime, handle snooze
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isOverdue
                      ? theme.colorScheme.error
                      : theme.colorScheme.secondary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                child: Text(
                  isOverdue ? 'Snooze +1h' : 'Mark Taken',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
