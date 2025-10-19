import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../core/storage/local_storage.dart';

/// Manages discharge data persistence across the app
class DischargeDataManager {
  // Task update listener functions
  static final List<Function()> _taskUpdateListeners = [];

  // Register a listener that will be called when tasks are updated
  static void addTaskUpdateListener(Function() listener) {
    _taskUpdateListeners.add(listener);
  }

  // Remove a previously registered listener
  static void removeTaskUpdateListener(Function() listener) {
    _taskUpdateListeners.remove(listener);
  }

  // Notify all listeners that tasks have been updated
  static void _notifyTaskUpdateListeners() {
    for (var listener in _taskUpdateListeners) {
      listener();
    }
  }

  static const String _keyDischargeUploaded = 'dischargeUploaded';
  static const String _keyMedications = 'medications';
  static const String _keyTasks = 'tasks';
  static const String _keyFollowUps = 'followUps';
  static const String _keyInstructions = 'instructions';
  static const String _keyUserName = 'userName';
  static const String _keyUserHeight = 'userHeight';
  static const String _keyUserWeight = 'userWeight';
  static const String _keyUserAge = 'userAge';
  static const String _keyUserSex = 'userSex';
  static const String _keyUserBedtime = 'userBedtime';
  static const String _keyUserWakeTime = 'userWakeTime';
  static const String _keyRawOcrText = 'rawOcrText';
  static const String _keyContacts = 'contacts';
  static const String _keyWarnings = 'warnings';

  /// Save discharge data to persistent storage
  static Future<void> saveDischargeData({
    required List<Map<String, dynamic>> medications,
    required List<Map<String, dynamic>> tasks,
    required List<Map<String, dynamic>> followUps,
    required List<Map<String, dynamic>> instructions,
    String? rawOcrText,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    // Mark discharge as uploaded
    await prefs.setBool(_keyDischargeUploaded, true);

    // Save medications
    await prefs.setString(_keyMedications, jsonEncode(medications));

    // Save tasks
    await prefs.setString(_keyTasks, jsonEncode(tasks));

    // Save follow-ups
    await prefs.setString(_keyFollowUps, jsonEncode(followUps));

    // Save instructions
    await prefs.setString(_keyInstructions, jsonEncode(instructions));

    // Save raw OCR text
    if (rawOcrText != null) {
      await prefs.setString(_keyRawOcrText, rawOcrText);
    }
  }

  /// Save profile data
  static Future<void> saveProfileData({
    String? name,
    int? height,
    int? weight,
    int? age,
    String? sex,
    String? bedtime,
    String? wakeTime,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (name != null) await prefs.setString(_keyUserName, name);
    if (height != null) await prefs.setInt(_keyUserHeight, height);
    if (weight != null) await prefs.setInt(_keyUserWeight, weight);
    if (age != null) await prefs.setInt(_keyUserAge, age);
    if (sex != null) await prefs.setString(_keyUserSex, sex);
    if (bedtime != null) await prefs.setString(_keyUserBedtime, bedtime);
    if (wakeTime != null) await prefs.setString(_keyUserWakeTime, wakeTime);
  }

  /// Load profile data
  static Future<Map<String, dynamic>> loadProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'name': prefs.getString(_keyUserName),
      'height': prefs.getInt(_keyUserHeight),
      'weight': prefs.getInt(_keyUserWeight),
      'age': prefs.getInt(_keyUserAge),
      'sex': prefs.getString(_keyUserSex),
      'bedtime': prefs.getString(_keyUserBedtime),
      'wakeTime': prefs.getString(_keyUserWakeTime),
    };
  }

  /// Load raw OCR text
  static Future<String?> loadRawOcrText() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyRawOcrText);
  }

  /// Check if discharge data has been uploaded
  static Future<bool> isDischargeUploaded() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyDischargeUploaded) ?? false;
  }

  /// Load medications from storage
  static Future<List<Map<String, dynamic>>> loadMedications() async {
    final prefs = await SharedPreferences.getInstance();
    final medicationsJson = prefs.getString(_keyMedications);
    if (medicationsJson == null) return [];

    final List<dynamic> decoded = jsonDecode(medicationsJson);
    return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  /// Save medications to storage
  static Future<void> saveMedications(
      List<Map<String, dynamic>> medications) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyMedications, jsonEncode(medications));

    // Notify all listeners that medications have been updated
    _notifyTaskUpdateListeners();
  }

  /// Load tasks from storage
  static Future<List<Map<String, dynamic>>> loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final tasksJson = prefs.getString(_keyTasks);
    if (tasksJson == null) return [];

    final List<dynamic> decoded = jsonDecode(tasksJson);
    return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  /// Save tasks to storage
  static Future<void> saveTasks(List<Map<String, dynamic>> tasks) async {
    final prefs = await SharedPreferences.getInstance();

    // Ensure all DateTime objects are converted to strings before saving
    final serializableTasks = tasks.map((task) {
      final serializedTask = Map<String, dynamic>.from(task);

      // Convert DateTime fields to ISO 8601 strings
      if (serializedTask['dueTime'] is DateTime) {
        serializedTask['dueTime'] =
            (serializedTask['dueTime'] as DateTime).toIso8601String();
      }
      if (serializedTask['startDate'] is DateTime) {
        serializedTask['startDate'] =
            (serializedTask['startDate'] as DateTime).toIso8601String();
      }
      if (serializedTask['dueDate'] is DateTime) {
        serializedTask['dueDate'] =
            (serializedTask['dueDate'] as DateTime).toIso8601String();
      }

      return serializedTask;
    }).toList();

    await prefs.setString(_keyTasks, jsonEncode(serializableTasks));

    // Notify all listeners that tasks have been updated
    _notifyTaskUpdateListeners();
  }

  /// Get the most recent task update listeners count - useful for debugging
  static int getTaskUpdateListenersCount() {
    return _taskUpdateListeners.length;
  }

  /// Load follow-ups from storage
  static Future<List<Map<String, dynamic>>> loadFollowUps() async {
    final prefs = await SharedPreferences.getInstance();
    final followUpsJson = prefs.getString(_keyFollowUps);
    if (followUpsJson == null) return [];

    final List<dynamic> decoded = jsonDecode(followUpsJson);
    return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  /// Load instructions from storage
  static Future<List<Map<String, dynamic>>> loadInstructions() async {
    final prefs = await SharedPreferences.getInstance();
    final instructionsJson = prefs.getString(_keyInstructions);
    if (instructionsJson == null) return [];

    final List<dynamic> decoded = jsonDecode(instructionsJson);
    return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  /// Save contacts information
  static Future<void> saveContacts(List<Map<String, dynamic>> contacts) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyContacts, jsonEncode(contacts));
  }

  /// Load contacts information
  static Future<List<Map<String, dynamic>>> loadContacts() async {
    final prefs = await SharedPreferences.getInstance();
    final contactsJson = prefs.getString(_keyContacts);
    if (contactsJson == null) return [];

    final List<dynamic> decoded = jsonDecode(contactsJson);
    return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  /// Save warnings information
  static Future<void> saveWarnings(List<Map<String, dynamic>> warnings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyWarnings, jsonEncode(warnings));
  }

  /// Load warnings information
  static Future<List<Map<String, dynamic>>> loadWarnings() async {
    final prefs = await SharedPreferences.getInstance();
    final warningsJson = prefs.getString(_keyWarnings);
    if (warningsJson == null) return [];

    final List<dynamic> decoded = jsonDecode(warningsJson);
    return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  /// Clear all discharge data
  static Future<void> clearDischargeData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyDischargeUploaded);
    await prefs.remove(_keyMedications);
    await prefs.remove(_keyTasks);
    await prefs.remove(_keyFollowUps);
    await prefs.remove(_keyInstructions);
    await prefs.remove(_keyUserName);
    await prefs.remove(_keyUserHeight);
    await prefs.remove(_keyUserWeight);
    await prefs.remove(_keyUserAge);
    await prefs.remove(_keyUserSex);
    await prefs.remove(_keyUserBedtime);
    await prefs.remove(_keyUserWakeTime);
    await prefs.remove(_keyRawOcrText);
    await prefs.remove(_keyContacts);
    await prefs.remove(_keyWarnings);

    // Clear AI chat history
    await LocalStorage.deleteSecure('ai_chats');
  }
}
