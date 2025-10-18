import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Manages discharge data persistence across the app
class DischargeDataManager {
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
    await prefs.remove(_keyUserName);
    await prefs.remove(_keyUserHeight);
    await prefs.remove(_keyUserWeight);
    await prefs.remove(_keyUserAge);
    await prefs.remove(_keyUserSex);
    await prefs.remove(_keyUserBedtime);
    await prefs.remove(_keyUserWakeTime);
    await prefs.remove(_keyRawOcrText);
  }
}
