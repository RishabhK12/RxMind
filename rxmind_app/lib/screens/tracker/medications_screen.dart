import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:rxmind_app/screens/tracker/glossary_detail_screen.dart';
import 'package:rxmind_app/screens/ai/gemini_api_service.dart';
import 'package:rxmind_app/gemini_api_key.dart';
import 'dart:convert';

class MedicationsScreen extends StatefulWidget {
  const MedicationsScreen({super.key});

  @override
  State<MedicationsScreen> createState() => _MedicationsScreenState();
}

class _MedicationsScreenState extends State<MedicationsScreen> {
  final List<String> glossaryTerms = [
    'Hypertension',
    'Beta Blocker',
    'Systolic',
    'Diuretic',
    'Anticoagulant',
    'ACE Inhibitor',
    'Statin',
  ];
  int? expandedIndex;
  Map<String, String> medGlossary = {};

  Future<void> _fetchMedInfo(String name, int index) async {
    if (medGlossary.containsKey(name)) return;
    final GeminiApiService geminiService =
        GeminiApiService(apiKey: geminiApiKey);
    String prompt = '''
You are a medical assistant. Please provide ONLY the following JSON object for the medication "$name":
{
  "name": "<medication name>",
  "description": "<one-sentence plain-language summary>",
  "instructions": "<concise instructions for use>",
  "side_effects": "<common side effects, comma separated>"
}
Do NOT include any extra text, preamble, or confirmation. Only output the JSON object. If you cannot find information, return:
{
  "name": "$name",
  "description": "No information found.",
  "instructions": "",
  "side_effects": ""
}
''';
    int attempts = 0;
    String info = '';
    String errorMsg = '';
    while (attempts < 2) {
      try {
        final response = await geminiService.sendMessage(prompt);
        final jsonStart = response.indexOf('{');
        final jsonEnd = response.lastIndexOf('}');
        if (jsonStart != -1 && jsonEnd != -1) {
          final jsonStr = response.substring(jsonStart, jsonEnd + 1);
          final data = json.decode(jsonStr);
          info = 'Name: ' +
              data['name'].toString() +
              '\n' +
              'Description: ' +
              data['description'].toString() +
              '\n' +
              'Instructions: ' +
              data['instructions'].toString() +
              '\n' +
              'Side Effects: ' +
              data['side_effects'].toString();
          break;
        } else {
          errorMsg = 'Malformed response from Gemini API.';
          attempts++;
        }
      } catch (e) {
        errorMsg = 'Error: ${e.toString()}';
        break;
      }
    }
    if (info.isEmpty)
      info = errorMsg.isNotEmpty ? errorMsg : 'Unable to fetch information.';
    setState(() {
      medGlossary[name] = info;
    });
    if (errorMsg.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg, style: const TextStyle(color: Colors.red)),
          backgroundColor: Colors.white,
        ),
      );
    }
  }

  List<Map<String, dynamic>> medicationsList = [];
  bool dischargeUploaded = false;

  @override
  void initState() {
    super.initState();
    _loadDischargeStatus();
  }

  Future<void> _loadDischargeStatus() async {
    // TODO: Implement real discharge upload status and medication list loading from persistent storage
    // Example:
    // final prefs = await SharedPreferences.getInstance();
    // dischargeUploaded = prefs.getBool('dischargeUploaded') ?? false;
    // medicationsList = await loadMedicationsFromStorage();
    // setState(() {});
  }

  void _markTaken(int index) {
    final oldNextDose = medicationsList[index]['nextDoseTime'];
    final oldOverdue = medicationsList[index]['isOverdue'];
    setState(() {
      medicationsList[index]['nextDoseTime'] =
          DateTime.now().add(const Duration(hours: 24));
      medicationsList[index]['isOverdue'] = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 22),
            const SizedBox(width: 12),
            Text(
              '${medicationsList[index]['name']} marked as taken!',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            setState(() {
              medicationsList[index]['nextDoseTime'] = oldNextDose;
              medicationsList[index]['isOverdue'] = oldOverdue;
            });
          },
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
    );
  }

  void _snoozeOneHour(int index) {
    setState(() {
      medicationsList[index]['nextDoseTime'] =
          (medicationsList[index]['nextDoseTime'] as DateTime)
              .add(const Duration(hours: 1));
      medicationsList[index]['isOverdue'] = false;
    });
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
          header: true,
          label: 'My Medications screen',
          child: Text(
            'My Medications',
            style: theme.textTheme.titleLarge,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 4,
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Health Glossary', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  ...glossaryTerms.map((term) => Semantics(
                        button: true,
                        label: 'Glossary term: $term. Tap for definition.',
                        child: ListTile(
                          title: Text(term, style: theme.textTheme.bodyLarge),
                          trailing: Icon(Icons.info_outline,
                              color: theme.colorScheme.primary),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    GlossaryDetailScreen(term: term),
                              ),
                            );
                          },
                        ),
                      )),
                ],
              ),
            ),
          ),
          if (medicationsList.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'No medications yet. Tap + to add a new medication.',
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ),
          ...List.generate(medicationsList.length, (i) {
            final med = medicationsList[i];
            final isExpanded = expandedIndex == i;
            return Column(
              children: [
                GestureDetector(
                  onTap: () async {
                    setState(() {
                      expandedIndex = expandedIndex == i ? null : i;
                    });
                    if (expandedIndex == i) {
                      await _fetchMedInfo(med['name'], i);
                    }
                  },
                  child: _MedicationCard(
                    med: med,
                    onMarkTaken: () => _markTaken(i),
                    onSnooze: () => _snoozeOneHour(i),
                    isExpanded: isExpanded,
                  ),
                ),
                if (isExpanded)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 8, left: 8, right: 8),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: medGlossary[med['name']] == null
                        ? Row(
                            children: [
                              const SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              ),
                              SizedBox(width: 12),
                              Text('Loading info...',
                                  style:
                                      Theme.of(context).textTheme.bodyMedium),
                            ],
                          )
                        : Text(
                            medGlossary[med['name']]!,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                  ),
              ],
            );
          }),
        ],
      ),
      floatingActionButton: dischargeUploaded
          ? Semantics(
              label: 'Add new medication',
              button: true,
              child: FloatingActionButton(
                backgroundColor: theme.colorScheme.secondary,
                child: const Icon(Icons.add, size: 28, color: Colors.white),
                onPressed: () async {
                  showDialog(
                    context: context,
                    builder: (ctx) {
                      final TextEditingController nameController =
                          TextEditingController();
                      final TextEditingController instructionsController =
                          TextEditingController();
                      return AlertDialog(
                        title: const Text('Add Medication'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextField(
                              controller: nameController,
                              decoration: const InputDecoration(
                                  labelText: 'Medication Name'),
                            ),
                            TextField(
                              controller: instructionsController,
                              decoration: const InputDecoration(
                                  labelText: 'Instructions'),
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              final name = nameController.text.trim();
                              final instructions =
                                  instructionsController.text.trim();
                              if (name.isNotEmpty) {
                                setState(() {
                                  medicationsList.add({
                                    'name': name,
                                    'instructions': instructions,
                                    'nextDoseTime': DateTime.now()
                                        .add(const Duration(hours: 24)),
                                    'isOverdue': false,
                                  });
                                });
                                Navigator.pop(ctx);
                              }
                            },
                            child: const Text('Add'),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            )
          : null,
    );
  }
}

class _MedicationCard extends StatelessWidget {
  final Map<String, dynamic> med;
  final VoidCallback onMarkTaken;
  final VoidCallback onSnooze;
  final bool isExpanded;
  const _MedicationCard(
      {required this.med,
      required this.onMarkTaken,
      required this.onSnooze,
      this.isExpanded = false});

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
          crossAxisAlignment: CrossAxisAlignment.start,
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
                  Row(
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
                      const SizedBox(width: 6),
                      Icon(
                        isExpanded ? Icons.expand_less : Icons.expand_more,
                        size: 20,
                        color: theme.colorScheme.primary,
                      ),
                    ],
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
                                : theme.colorScheme.onSurface.withOpacity(
                                    0.7), // TODO: update if withOpacity is deprecated in your Flutter version
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
                  : (med['isOverdue'] == false &&
                          med['nextDoseTime'] != null &&
                          (med['nextDoseTime'] as DateTime).isAfter(
                              DateTime.now()
                                  .subtract(const Duration(minutes: 1))))
                      ? 'Medication ${med['name']} already marked as taken'
                      : 'Mark medication ${med['name']} as taken',
              child: isOverdue
                  ? ElevatedButton(
                      onPressed: onSnooze,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.error,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                      ),
                      child: Text(
                        'Snooze +1h',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSecondary,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    )
                  : (med['isOverdue'] == false &&
                          med['nextDoseTime'] != null &&
                          (med['nextDoseTime'] as DateTime).isAfter(
                              DateTime.now()
                                  .subtract(const Duration(minutes: 1))))
                      ? ElevatedButton.icon(
                          onPressed: null,
                          icon: const Icon(Icons.check_circle,
                              color: Colors.grey),
                          label: Text(
                            'Completed',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: Colors.grey,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                theme.disabledColor.withOpacity(0.15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            elevation: 0,
                          ),
                        )
                      : ElevatedButton(
                          onPressed: onMarkTaken,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.secondary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                          ),
                          child: Text(
                            'Mark Taken',
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
