import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
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
  List<Map<String, dynamic>> warnings = [];
  List<Map<String, dynamic>> tasks = [];
  bool _loading = true;
  bool _didRun = false;
  String _rawOcrText = '';
  final ScrollController _scrollController = ScrollController();

  static const List<String> _expectedTopLevelKeys = <String>[
    'medications',
    'follow_ups',
    'instructions',
    'tasks',
    'warnings',
    'contacts',
  ];

  String _clipForLog(String s, {int maxChars = 4000}) {
    if (s.length <= maxChars) return s;
    return '${s.substring(0, maxChars)}\n\n[TRUNCATED LOG: ${s.length - maxChars} chars omitted]';
  }

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
    _rawOcrText = args?['ocrText'] as String? ?? '';
    final parsedJsonString = args?['parsedJson'] as String? ?? '';

    if (kDebugMode) {
      debugPrint(
          '[ParsedSummary] parsedJsonString length: ${parsedJsonString.length}');
      debugPrint(
          '[ParsedSummary] parsedJsonString (clipped):\n${_clipForLog(parsedJsonString)}');
    }

    if (parsedJsonString.isNotEmpty) {
      try {
        final Map<String, dynamic> parsed =
            _decodeAndNormalizeParsedJson(parsedJsonString);

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error parsing data: $e')),
        );
      }
    }

    setState(() {
      _loading = false;
    });
  }

  /// Extracts and cleans JSON from a potentially messy LLM response
  String _extractAndCleanJson(String input) {
    String text = input.trim();

    // Remove markdown code blocks if present
    text = text.replaceAll(RegExp(r'```json\s*'), '');
    text = text.replaceAll(RegExp(r'```\s*'), '');

    // Find the JSON object
    final jsonStart = text.indexOf('{');
    final jsonEnd = text.lastIndexOf('}');

    if (jsonStart == -1 || jsonEnd == -1 || jsonEnd <= jsonStart) {
      // Return a default empty structure if no JSON found
      return _getEmptyJsonStructure();
    }

    String jsonStr = text.substring(jsonStart, jsonEnd + 1);

    // Clean up common issues in LLM-generated JSON
    // Fix trailing commas before closing brackets/braces
    jsonStr = jsonStr.replaceAll(RegExp(r',\s*}'), '}');
    jsonStr = jsonStr.replaceAll(RegExp(r',\s*\]'), ']');

    // Replace smart quotes with regular quotes
    jsonStr =
        jsonStr.replaceAll('"', '"').replaceAll('"', '"').replaceAll(''', "'")
        .replaceAll(''', "'");

    // Try to validate the JSON, return empty structure if invalid
    try {
      jsonDecode(jsonStr);
      return jsonStr;
    } catch (e) {
      // Try to repair incomplete JSON by closing unclosed brackets
      String repaired = _tryRepairJson(jsonStr);
      try {
        jsonDecode(repaired);
        return repaired;
      } catch (_) {
        // If repair fails, return empty structure
        return _getEmptyJsonStructure();
      }
    }
  }

  Map<String, dynamic> _decodeAndNormalizeParsedJson(String parsedJsonString) {
    dynamic decoded = _tryDecodeRawJson(parsedJsonString);
    decoded ??= _tryDecodeRawJson(_extractAndCleanJson(parsedJsonString));

    // If the model output is truncated (common when it invents huge fields like
    // URLs/descriptions), JSON decoding can fail. Salvage meds from the raw
    // string so the UI still shows something.
    if (decoded == null) {
      final salvagedMeds = _salvageMedicationsFromText(parsedJsonString);
      if (salvagedMeds.isNotEmpty) {
        final out = _emptyExpectedStructure();
        out['medications'] = salvagedMeds;
        if (kDebugMode) {
          debugPrint(
              '[ParsedSummary] JSON decode failed; salvaged meds: ${salvagedMeds.length}');
        }
        return out;
      }
      decoded = jsonDecode(_getEmptyJsonStructure());
    }

    final Map<String, dynamic> normalized = _normalizeToExpectedSchema(decoded);

    if (kDebugMode) {
      debugPrint(
          '[ParsedSummary] normalized keys: ${normalized.keys.toList()}');
      debugPrint(
          '[ParsedSummary] normalized meds: ${(normalized['medications'] as List).length}, '
          'tasks: ${(normalized['tasks'] as List).length}');
    }

    return normalized;
  }

  List<Map<String, dynamic>> _salvageMedicationsFromText(String input) {
    // 1) Try to extract a full medications array: "medications": [ ... ]
    final medsArray = _tryExtractJsonArrayForKey(input, 'medications');
    if (medsArray != null) {
      return _normalizeMedications(medsArray);
    }

    // 2) Try to extract the first medication object from within a medications array.
    final firstObj =
        _tryExtractFirstJsonObjectInArrayForKey(input, 'medications');
    if (firstObj != null) {
      return _normalizeMedications(<dynamic>[firstObj]);
    }

    // 3) Some alternate schemas use "medication".
    final medsArrayAlt = _tryExtractJsonArrayForKey(input, 'medication');
    if (medsArrayAlt != null) {
      return _normalizeMedications(medsArrayAlt);
    }
    final firstObjAlt =
        _tryExtractFirstJsonObjectInArrayForKey(input, 'medication');
    if (firstObjAlt != null) {
      return _normalizeMedications(<dynamic>[firstObjAlt]);
    }

    return <Map<String, dynamic>>[];
  }

  List<dynamic>? _tryExtractJsonArrayForKey(String input, String key) {
    final idx = input.indexOf('"$key"');
    if (idx == -1) return null;

    final colon = input.indexOf(':', idx);
    if (colon == -1) return null;

    int i = colon + 1;
    while (i < input.length && _isWhitespace(input.codeUnitAt(i))) {
      i++;
    }
    if (i >= input.length || input.codeUnitAt(i) != 0x5B /* [ */) return null;

    final end = _findMatchingJsonBracket(input, i);
    if (end == -1) return null;

    final candidate = input.substring(i, end + 1);
    try {
      final decoded = jsonDecode(candidate);
      return decoded is List ? decoded : null;
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic>? _tryExtractFirstJsonObjectInArrayForKey(
      String input, String key) {
    final idx = input.indexOf('"$key"');
    if (idx == -1) return null;
    final colon = input.indexOf(':', idx);
    if (colon == -1) return null;

    // Find first '{' after the key.
    int i = colon + 1;
    while (i < input.length && input.codeUnitAt(i) != 0x7B /* { */) {
      i++;
    }
    if (i >= input.length) return null;

    final end = _findMatchingJsonBrace(input, i);
    if (end == -1) return null;

    final candidate = input.substring(i, end + 1);
    try {
      final decoded = jsonDecode(candidate);
      return decoded is Map ? Map<String, dynamic>.from(decoded) : null;
    } catch (_) {
      return null;
    }
  }

  bool _isWhitespace(int c) {
    return c == 0x20 /* space */ ||
        c == 0x0A /* \n */ ||
        c == 0x0D /* \r */ ||
        c == 0x09 /* \t */;
  }

  int _findMatchingJsonBracket(String s, int startIndex) {
    int depth = 0;
    bool inString = false;
    bool escaped = false;

    for (int i = startIndex; i < s.length; i++) {
      final int c = s.codeUnitAt(i);

      if (inString) {
        if (escaped) {
          escaped = false;
          continue;
        }
        if (c == 0x5C /* \\ */) {
          escaped = true;
          continue;
        }
        if (c == 0x22 /* " */) {
          inString = false;
        }
        continue;
      }

      if (c == 0x22 /* " */) {
        inString = true;
        continue;
      }

      if (c == 0x5B /* [ */) depth++;
      if (c == 0x5D /* ] */) {
        depth--;
        if (depth == 0) return i;
        if (depth < 0) return -1;
      }
    }
    return -1;
  }

  int _findMatchingJsonBrace(String s, int startIndex) {
    int depth = 0;
    bool inString = false;
    bool escaped = false;

    for (int i = startIndex; i < s.length; i++) {
      final int c = s.codeUnitAt(i);

      if (inString) {
        if (escaped) {
          escaped = false;
          continue;
        }
        if (c == 0x5C /* \\ */) {
          escaped = true;
          continue;
        }
        if (c == 0x22 /* " */) {
          inString = false;
        }
        continue;
      }

      if (c == 0x22 /* " */) {
        inString = true;
        continue;
      }

      if (c == 0x7B /* { */) depth++;
      if (c == 0x7D /* } */) {
        depth--;
        if (depth == 0) return i;
        if (depth < 0) return -1;
      }
    }
    return -1;
  }

  dynamic _tryDecodeRawJson(String input) {
    final String text = input.trim();
    if (text.isEmpty) return null;
    try {
      return jsonDecode(text);
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> _emptyExpectedStructure() {
    return <String, dynamic>{
      'medications': <dynamic>[],
      'follow_ups': <dynamic>[],
      'instructions': <dynamic>[],
      'tasks': <dynamic>[],
      'warnings': <dynamic>[],
      'contacts': <dynamic>[],
    };
  }

  bool _looksLikeExpectedSchema(Map<String, dynamic> map) {
    for (final key in _expectedTopLevelKeys) {
      if (!map.containsKey(key)) return false;
    }
    return true;
  }

  Map<String, dynamic> _normalizeToExpectedSchema(dynamic decoded) {
    // The UI expects a single object with the expected keys.
    // Some models return arrays or different key names; adapt those here.
    Map<String, dynamic>? root;

    if (decoded is Map) {
      root = Map<String, dynamic>.from(decoded);
    } else if (decoded is List && decoded.isNotEmpty && decoded.first is Map) {
      root = Map<String, dynamic>.from(decoded.first as Map);
    }

    if (root == null) {
      return _emptyExpectedStructure();
    }

    if (_looksLikeExpectedSchema(root)) {
      // Ensure arrays exist.
      for (final key in _expectedTopLevelKeys) {
        if (root[key] is! List) root[key] = <dynamic>[];
      }
      return root;
    }

    final Map<String, dynamic> out = _emptyExpectedStructure();

    // Support alternate schemas seen in the wild.
    // Example: { checkup: { medication: [...] , notes: ... } }
    Map<String, dynamic> checkup = <String, dynamic>{};
    if (root['checkup'] is Map) {
      checkup = Map<String, dynamic>.from(root['checkup'] as Map);
    }

    final dynamic medsCandidate = root['medications'] ??
        root['medication'] ??
        checkup['medications'] ??
        checkup['medication'];
    final List<Map<String, dynamic>> meds =
        _normalizeMedications(medsCandidate);
    out['medications'] = meds;

    // Convert free-form notes into a basic task/instruction so the UI shows something.
    final String? notes =
        (root['notes'] ?? checkup['notes'])?.toString().trim().isEmpty == true
            ? null
            : (root['notes'] ?? checkup['notes'])?.toString().trim();
    final String? medicationNotes =
        (root['medication_notes'] ?? checkup['medication_notes'])
                    ?.toString()
                    .trim()
                    .isEmpty ==
                true
            ? null
            : (root['medication_notes'] ?? checkup['medication_notes'])
                ?.toString()
                .trim();

    final List<Map<String, dynamic>> tasksOut = <Map<String, dynamic>>[];
    final List<Map<String, dynamic>> instructionsOut = <Map<String, dynamic>>[];

    void addNoteAsInstructionOrTask(String text) {
      final t = text.trim();
      if (t.isEmpty) return;
      // If it looks like an action verb, put it into tasks; otherwise into instructions.
      final lower = t.toLowerCase();
      final looksAction = lower.startsWith('call ') ||
          lower.startsWith('contact ') ||
          lower.startsWith('carry ') ||
          lower.startsWith('take ') ||
          lower.startsWith('do ') ||
          lower.startsWith('avoid ') ||
          lower.startsWith('monitor ') ||
          lower.contains('follow up') ||
          lower.contains('follow-up');

      if (looksAction) {
        tasksOut.add(_basicTaskFromText(t));
      } else {
        instructionsOut.add(<String, dynamic>{'name': t});
      }
    }

    if (notes != null) addNoteAsInstructionOrTask(notes);
    if (medicationNotes != null) addNoteAsInstructionOrTask(medicationNotes);

    out['tasks'] = tasksOut;
    out['instructions'] = instructionsOut;

    return out;
  }

  List<Map<String, dynamic>> _normalizeMedications(dynamic medsCandidate) {
    final List<Map<String, dynamic>> out = <Map<String, dynamic>>[];
    if (medsCandidate is! List) return out;

    for (final item in medsCandidate) {
      if (item is Map) {
        final map = Map<String, dynamic>.from(item);
        final String name =
            (map['name'] ?? map['drug'] ?? map['medication'] ?? '')
                .toString()
                .trim();
        final String rawDose =
            (map['dose'] ?? map['dosage'] ?? map['strength'] ?? '')
                .toString()
                .trim();
        final String rawFreq = (map['frequency'] ?? '').toString().trim();
        final String mergedDose = rawDose.isNotEmpty
            ? rawDose
            : (map['dosage'] ?? map['dose'] ?? map['instructions'] ?? '')
                .toString()
                .trim();

        final String derivedFreq =
            rawFreq.isNotEmpty ? rawFreq : _deriveFrequencyFromText(mergedDose);

        if (name.isEmpty && mergedDose.isEmpty) continue;
        out.add(<String, dynamic>{
          'name': name.isEmpty ? 'Medication' : name,
          'dose': mergedDose,
          'frequency': derivedFreq,
        });
      } else if (item is String) {
        final s = item.trim();
        if (s.isEmpty) continue;
        out.add(<String, dynamic>{'name': s, 'dose': '', 'frequency': ''});
      }
    }

    return out;
  }

  String _deriveFrequencyFromText(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('night') ||
        lower.contains('bedtime') ||
        lower.contains('qhs')) return 'nightly';
    if (lower.contains('daily') ||
        lower.contains('once a day') ||
        lower.contains('qd')) return 'daily';
    if (lower.contains('twice') || lower.contains('bid')) return 'twice daily';
    if (lower.contains('three') || lower.contains('tid'))
      return 'three times daily';
    if (lower.contains('as needed') || lower.contains('prn'))
      return 'as needed';
    return '';
  }

  Map<String, dynamic> _basicTaskFromText(String text) {
    // Minimal task structure matching what the UI expects.
    final title = text.length <= 60 ? text : '${text.substring(0, 60)}…';
    return <String, dynamic>{
      'title': title,
      'description': text,
      'dueDate': '',
      'dueTime': '',
      'isRecurring': false,
      'recurringPattern': '',
      'recurringInterval': 0,
      'startDate': '',
      'type': 'task',
      'hasSpecificDate': false,
    };
  }

  /// Returns empty but valid JSON structure
  String _getEmptyJsonStructure() {
    return '{"medications":[],"follow_ups":[],"instructions":[],"tasks":[],"warnings":[],"contacts":[]}';
  }

  /// Attempts to repair truncated/incomplete JSON
  String _tryRepairJson(String json) {
    String repaired = json;

    // Count brackets
    int openBraces = '{'.allMatches(repaired).length;
    int closeBraces = '}'.allMatches(repaired).length;
    int openBrackets = '['.allMatches(repaired).length;
    int closeBrackets = ']'.allMatches(repaired).length;

    // Remove incomplete last property (common truncation issue)
    // Look for patterns like: ,"key": or ,"key":[ that are incomplete
    repaired = repaired.replaceAll(RegExp(r',\s*"[^"]*":\s*$'), '');
    repaired = repaired.replaceAll(RegExp(r',\s*"[^"]*":\s*\[\s*$'), '');
    repaired = repaired.replaceAll(RegExp(r',\s*"[^"]*":\s*\{\s*$'), '');

    // Remove trailing incomplete string values
    repaired = repaired.replaceAll(RegExp(r':\s*"[^"]*$'), ': ""');

    // Recount after cleanup
    openBraces = '{'.allMatches(repaired).length;
    closeBraces = '}'.allMatches(repaired).length;
    openBrackets = '['.allMatches(repaired).length;
    closeBrackets = ']'.allMatches(repaired).length;

    // Add missing closing brackets
    while (closeBrackets < openBrackets) {
      repaired += ']';
      closeBrackets++;
    }

    // Add missing closing braces
    while (closeBraces < openBraces) {
      repaired += '}';
      closeBraces++;
    }

    return repaired;
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
          final Map<String, dynamic> parsed =
              _decodeAndNormalizeParsedJson(jsonStr);

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
                final bool hasSpecificDate = taskMap['hasSpecificDate'] == true;

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
                final String warningText = warningObj['text']?.toString() ?? '';
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
              await prefs.setString('warnings', jsonEncode(warningsForStorage));
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
        title: const Text('Document Summary'),
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
