import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:rxmind_app/screens/tracker/glossary_detail_screen.dart';
import 'package:rxmind_app/screens/ai/gemini_api_service.dart';
import 'package:rxmind_app/gemini_api_key.dart';
import 'package:rxmind_app/services/discharge_data_manager.dart';
import 'dart:convert';

class MedicationsScreen extends StatefulWidget {
  const MedicationsScreen({super.key});

  @override
  State<MedicationsScreen> createState() => _MedicationsScreenState();
}

class _MedicationsScreenState extends State<MedicationsScreen> {
  final ScrollController _glossaryScrollController = ScrollController();
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
          info =
              'Name: ${data['name']}\nDescription: ${data['description']}\nInstructions: ${data['instructions']}\nSide Effects: ${data['side_effects']}';
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
    if (info.isEmpty) {
      info = errorMsg.isNotEmpty ? errorMsg : 'Unable to fetch information.';
    }
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

  @override
  void dispose() {
    _glossaryScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadDischargeStatus() async {
    final uploaded = await DischargeDataManager.isDischargeUploaded();
    final meds = await DischargeDataManager.loadMedications();

    setState(() {
      dischargeUploaded = uploaded;
      if (uploaded && meds.isNotEmpty) {
        medicationsList = meds.map((med) {
          // Ensure nextDoseTime is stored as String
          String nextDoseTimeStr;
          if (med['nextDoseTime'] is String) {
            nextDoseTimeStr = med['nextDoseTime'];
          } else if (med['nextDoseTime'] is DateTime) {
            nextDoseTimeStr =
                (med['nextDoseTime'] as DateTime).toIso8601String();
          } else {
            nextDoseTimeStr = DateTime.now().toIso8601String();
          }

          // Ensure lastTaken is stored as String if it exists
          String? lastTakenStr;
          if (med['lastTaken'] != null) {
            if (med['lastTaken'] is String) {
              lastTakenStr = med['lastTaken'];
            } else if (med['lastTaken'] is DateTime) {
              lastTakenStr = (med['lastTaken'] as DateTime).toIso8601String();
            }
          }

          return {
            'name': med['name'] ?? 'Unknown',
            'dose': med['dose'] ?? '',
            'frequency': med['frequency'] ?? 'As needed',
            'nextDoseTime': nextDoseTimeStr,
            'isOverdue': med['isOverdue'] ?? false,
            'lastTaken': lastTakenStr,
            'takenToday': med['takenToday'] ?? false,
            'completionHistory': med['completionHistory'] ?? [],
          };
        }).toList();
      } else {
        medicationsList = [];
      }
    });

    // Check for medications that need to be reset based on frequency
    _checkAndResetMedications();
  }

  /// Parse frequency string and calculate next dose time
  Duration _parseFrequency(String frequency) {
    final lowerFreq = frequency.toLowerCase();

    // Parse patterns like "twice daily", "3 times a day", "every 8 hours"
    if (lowerFreq.contains('hour')) {
      final match = RegExp(r'(\d+)\s*hour').firstMatch(lowerFreq);
      if (match != null) {
        final hours = int.tryParse(match.group(1) ?? '24') ?? 24;
        return Duration(hours: hours);
      }
    }

    if (lowerFreq.contains('once') ||
        lowerFreq.contains('daily') ||
        lowerFreq.contains('day')) {
      if (lowerFreq.contains('twice') || lowerFreq.contains('2')) {
        return const Duration(hours: 12);
      } else if (lowerFreq.contains('three') || lowerFreq.contains('3')) {
        return const Duration(hours: 8);
      } else if (lowerFreq.contains('four') || lowerFreq.contains('4')) {
        return const Duration(hours: 6);
      }
      return const Duration(hours: 24);
    }

    if (lowerFreq.contains('week')) {
      return const Duration(days: 7);
    }

    if (lowerFreq.contains('month')) {
      return const Duration(days: 30);
    }

    // Default to 24 hours
    return const Duration(hours: 24);
  }

  /// Check and reset medications based on their frequency
  Future<void> _checkAndResetMedications() async {
    bool needsUpdate = false;
    final now = DateTime.now();

    for (var med in medicationsList) {
      if (med['lastTaken'] != null && med['takenToday'] == true) {
        final lastTakenStr = med['lastTaken'] as String;
        final lastTaken = DateTime.parse(lastTakenStr);
        final frequency = med['frequency'] as String;
        final resetDuration = _parseFrequency(frequency);

        // Check if enough time has passed to reset
        if (now.difference(lastTaken) >= resetDuration) {
          med['takenToday'] = false;
          med['nextDoseTime'] = now.toIso8601String();
          needsUpdate = true;
        }
      }
    }

    if (needsUpdate) {
      await DischargeDataManager.saveMedications(medicationsList);
      if (mounted) setState(() {});
    }
  }

  /// Update the related task when medication status changes
  Future<void> _updateRelatedTask(int medIndex, bool markComplete) async {
    if (medIndex < 0 || medIndex >= medicationsList.length) return;

    // Get medication name
    final medName = medicationsList[medIndex]['name'] as String;

    // Load tasks
    final tasks = await DischargeDataManager.loadTasks();

    // Find task(s) that match this medication
    // Looking for tasks with titles like "Take [medication name]" or containing the medication name
    bool taskUpdated = false;
    for (var task in tasks) {
      final taskTitle = (task['title'] as String).toLowerCase();
      final medNameLower = medName.toLowerCase();

      // Check if task title contains the medication name
      if (taskTitle.contains(medNameLower) ||
          taskTitle.contains('take $medNameLower')) {
        if (markComplete) {
          // Mark task as completed
          task['completed'] = true;
          task['lastCompleted'] = DateTime.now().toIso8601String();
        } else {
          // Unmark task - clear completion status
          task['completed'] = false;
          task['lastCompleted'] = null;
          // Also clear recurring task fields that might prevent it from showing
          task['showAfter'] = null;
          task['nextOccurrence'] = null;
        }
        taskUpdated = true;

        // For recurring tasks, set the next occurrence based on medication frequency
        if (task['isRecurring'] == true && markComplete) {
          final frequency = medicationsList[medIndex]['frequency'] as String;
          final intervalDuration = _parseFrequency(frequency);
          final now = DateTime.now();

          task['showAfter'] = now.add(intervalDuration).toIso8601String();
          task['nextOccurrence'] = now.add(intervalDuration).toIso8601String();
        }
      }
    }

    // Save updated tasks if any were modified
    if (taskUpdated) {
      await DischargeDataManager.saveTasks(tasks);
    }
  }

  Future<void> _markTaken(int index) async {
    final now = DateTime.now();

    // Calculate next dose based on frequency
    final frequency = medicationsList[index]['frequency'] as String;
    final nextDoseDuration = _parseFrequency(frequency);

    setState(() {
      medicationsList[index]['nextDoseTime'] =
          now.add(nextDoseDuration).toIso8601String();
      medicationsList[index]['isOverdue'] = false;
      medicationsList[index]['takenToday'] = true;
      medicationsList[index]['lastTaken'] = now.toIso8601String();

      // Add to completion history
      List<dynamic> history = medicationsList[index]['completionHistory'] ?? [];
      history.add(now.toIso8601String());
      medicationsList[index]['completionHistory'] = history;
    });

    // Save medications
    await DischargeDataManager.saveMedications(medicationsList);

    // Update related task to mark as completed
    await _updateRelatedTask(index, true);
  }

  Future<void> _snoozeOneHour(int index) async {
    setState(() {
      // Parse current nextDoseTime and add one hour
      final currentNextDose = medicationsList[index]['nextDoseTime'] is String
          ? DateTime.parse(medicationsList[index]['nextDoseTime'])
          : medicationsList[index]['nextDoseTime'];

      medicationsList[index]['nextDoseTime'] =
          currentNextDose.add(const Duration(hours: 1)).toIso8601String();
      medicationsList[index]['isOverdue'] = false;
    });

    // Save medications
    await DischargeDataManager.saveMedications(medicationsList);
  }

  Future<void> _unmarkTaken(int index) async {
    // Calculate what the next dose should be based on last taken time
    final lastTaken = medicationsList[index]['lastTaken'];
    if (lastTaken == null) return;

    final frequency = medicationsList[index]['frequency'] as String;
    final resetDuration = _parseFrequency(frequency);

    DateTime parsedLastTaken;
    if (lastTaken is DateTime) {
      parsedLastTaken = lastTaken;
    } else {
      parsedLastTaken = DateTime.parse(lastTaken.toString());
    }

    setState(() {
      medicationsList[index]['nextDoseTime'] =
          parsedLastTaken.add(resetDuration).toIso8601String();
      medicationsList[index]['takenToday'] = false;
      medicationsList[index]['lastTaken'] = null;

      // Remove last entry from completion history
      List<dynamic> history = medicationsList[index]['completionHistory'] ?? [];
      if (history.isNotEmpty) {
        history.removeLast();
        medicationsList[index]['completionHistory'] = history;
      }
    });

    // Save medications
    await DischargeDataManager.saveMedications(medicationsList);
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
                  Container(
                    constraints: const BoxConstraints(maxHeight: 300),
                    child: Scrollbar(
                      controller: _glossaryScrollController,
                      child: ListView.builder(
                        controller: _glossaryScrollController,
                        shrinkWrap: true,
                        itemCount: glossaryTerms.length,
                        itemBuilder: (context, index) {
                          final term = glossaryTerms[index];
                          return Semantics(
                            button: true,
                            label: 'Glossary term: $term. Tap for definition.',
                            child: ListTile(
                              title:
                                  Text(term, style: theme.textTheme.bodyLarge),
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
                          );
                        },
                      ),
                    ),
                  ),
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
                    onUnmark: () => _unmarkTaken(i),
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
                            overflow: TextOverflow.ellipsis,
                            maxLines: 10,
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
                                        .add(const Duration(hours: 24))
                                        .toIso8601String(),
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
  final VoidCallback onUnmark;
  final bool isExpanded;
  const _MedicationCard(
      {required this.med,
      required this.onMarkTaken,
      required this.onSnooze,
      required this.onUnmark,
      this.isExpanded = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Parse nextDoseTime from string to DateTime
    final DateTime nextDose = med['nextDoseTime'] is String
        ? DateTime.parse(med['nextDoseTime'])
        : med['nextDoseTime'];
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
                      Expanded(
                        child: Semantics(
                          label: 'Medication name: ${med['name']}',
                          child: Text(
                            med['name'],
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w500,
                              fontSize: 16,
                              color: theme.colorScheme.onSurface,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
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
                      Expanded(
                        child: Semantics(
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
                                  : theme.colorScheme.onSurface
                                      .withOpacity(0.7),
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Column(
              children: [
                Semantics(
                  button: true,
                  label: isOverdue
                      ? 'Snooze medication ${med['name']} for 1 hour'
                      : med['takenToday'] == true
                          ? 'Unmark medication ${med['name']}'
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
                      : med['takenToday'] == true
                          ? ElevatedButton.icon(
                              onPressed: onUnmark,
                              icon: const Icon(Icons.check_circle,
                                  color: Colors.white, size: 20),
                              label: Text(
                                'Completed',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 10),
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
                if (med['takenToday'] == true) ...[
                  const SizedBox(height: 4),
                  TextButton(
                    onPressed: onUnmark,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      minimumSize: const Size(0, 0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'Undo',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.error,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
