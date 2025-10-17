import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Manages discharge data persistence across the app
class DischargeDataManager {
  static const String _keyDischargeUploaded = 'dischargeUploaded';
  static const String _keyMedications = 'medications';
  static const String _keyTasks = 'tasks';
  static const String _keyFollowUps = 'followUps';
  static const String _keyInstructions = 'instructions';

  /// Save discharge data to persistent storage
  static Future<void> saveDischargeData({
    required List<Map<String, dynamic>> medications,
    required List<Map<String, dynamic>> tasks,
    required List<Map<String, dynamic>> followUps,
    required List<Map<String, dynamic>> instructions,
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

  /// Load tasks from storage
  static Future<List<Map<String, dynamic>>> loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final tasksJson = prefs.getString(_keyTasks);
    if (tasksJson == null) return [];

    final List<dynamic> decoded = jsonDecode(tasksJson);
    return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
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

  /// Clear all discharge data
  static Future<void> clearDischargeData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyDischargeUploaded);
    await prefs.remove(_keyMedications);
    await prefs.remove(_keyTasks);
    await prefs.remove(_keyFollowUps);
    await prefs.remove(_keyInstructions);
  }
}
