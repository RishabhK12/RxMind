import 'notification_service.dart';
import 'ocr_service.dart';
import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:uuid/uuid.dart';
import 'database_service.dart';
import '../models/upload_queue.dart';
import 'gemini_service.dart';

typedef UploadQueueProcessedCallback = void Function();

class UploadQueueProcessor {
  static final UploadQueueProcessor _instance =
      UploadQueueProcessor._internal();
  factory UploadQueueProcessor() => _instance;
  UploadQueueProcessor._internal();

  final List<UploadQueueProcessedCallback> _listeners = [];
  void addListener(UploadQueueProcessedCallback cb) {
    if (!_listeners.contains(cb)) _listeners.add(cb);
  }

  void removeListener(UploadQueueProcessedCallback cb) {
    _listeners.remove(cb);
  }

  void _notifyListeners() {
    for (final cb in _listeners) {
      try {
        cb();
      } catch (_) {}
    }
  }

  StreamSubscription<dynamic>? _connectivitySubscription;
  bool _isProcessing = false;

  void start() {
    // Listen for connectivity changes
    _connectivitySubscription ??=
        Connectivity().onConnectivityChanged.listen((event) {
      ConnectivityResult result = ConnectivityResult.none;
      if (event.isNotEmpty) {
        result = event[0];
      }
      if (result != ConnectivityResult.none) {
        processQueue();
      }
    });
    // Also process on startup
    processQueue();
  }

  void dispose() {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
  }

  Future<void> processQueue() async {
    if (_isProcessing) return;
    _isProcessing = true;
    bool anySuccess = false;
    try {
      final db = await DatabaseService().database;
      final List<Map<String, dynamic>> items = await db.query(
        'upload_queue',
        where: 'status = ?',
        whereArgs: ['queued'],
      );
      for (final item in items) {
        final queueItem = UploadQueueItem.fromMap(item);
        final file = File(queueItem.filepath);
        if (!await file.exists()) {
          await db.update('upload_queue', {'status': 'error'},
              where: 'id = ?', whereArgs: [queueItem.id]);
          continue;
        }
        // Simulate upload logic (replace with real API call)
        final bool uploadSuccess = await _simulateUpload(file);
        if (uploadSuccess) {
          String dischargeText = '';
          final ext = file.path.toLowerCase();
          if (ext.endsWith('.jpg') ||
              ext.endsWith('.jpeg') ||
              ext.endsWith('.png') ||
              ext.endsWith('.bmp') ||
              ext.endsWith('.heic') ||
              ext.endsWith('.webp')) {
            // Use OCR for images
            try {
              dischargeText = await OcrService.extractTextFromImage(file);
            } catch (e) {
              debugPrint('OCR failed: $e');
            }
          } else {
            // Try to read as text file
            try {
              dischargeText = await file.readAsString();
            } catch (_) {}
          }
          if (dischargeText.isNotEmpty) {
            final geminiResult =
                await GeminiService().extractTasksAndMeds(dischargeText);
            if (geminiResult != null) {
              // Insert tasks
              final tasks = geminiResult['tasks'] as List<dynamic>?;
              if (tasks != null) {
                for (final t in tasks) {
                  final id = DateTime.now().millisecondsSinceEpoch.toString();
                  final timeStr = t['time'] ?? '';
                  await db.insert('tasks', {
                    'id': id,
                    'title': t['title'] ?? '',
                    'description': t['description'],
                    'time': timeStr,
                    'recurrence': t['recurrence'],
                    'completed': 0,
                    'created_at': DateTime.now().toIso8601String(),
                  });
                  // Schedule notification if time is valid
                  if (timeStr.isNotEmpty) {
                    try {
                      final now = DateTime.now();
                      // Parse time string (e.g., '8:00 AM daily')
                      final match = RegExp(r'(\d{1,2}):(\d{2}) ?([AP]M)')
                          .firstMatch(timeStr);
                      if (match != null) {
                        int hour = int.parse(match.group(1)!);
                        int minute = int.parse(match.group(2)!);
                        final ampm = match.group(3);
                        if (ampm == 'PM' && hour < 12) hour += 12;
                        if (ampm == 'AM' && hour == 12) hour = 0;
                        final scheduled = DateTime(
                            now.year, now.month, now.day, hour, minute);
                        if (scheduled.isAfter(now)) {
                          await NotificationService().scheduleNotification(
                            id: int.tryParse(id) ?? now.millisecondsSinceEpoch,
                            title: t['title'] ?? 'Task Reminder',
                            body: t['description'] ?? '',
                            scheduledDate: scheduled,
                          );
                        }
                      }
                    } catch (_) {}
                  }
                }
              }
              // Insert medications
              final meds = geminiResult['medications'] as List<dynamic>?;
              if (meds != null) {
                for (final m in meds) {
                  final id = DateTime.now().millisecondsSinceEpoch.toString();
                  await db.insert('medications', {
                    'id': id,
                    'name': m['name'] ?? '',
                    'description': m['description'],
                    'dosage': m['dosage'] ?? '',
                    'created_at': DateTime.now().toIso8601String(),
                  });
                  // Optionally schedule notification for recurring meds (if dosage/time info is present)
                  final dosage = m['dosage'] ?? '';
                  if (dosage.contains('day') || dosage.contains('hour')) {
                    await NotificationService().scheduleNotification(
                      id: int.tryParse(id) ??
                          DateTime.now().millisecondsSinceEpoch,
                      title: m['name'] ?? 'Medication Reminder',
                      body: m['description'] ?? '',
                      scheduledDate: DateTime.now().add(const Duration(
                          minutes: 1)), // Placeholder: schedule soon
                    );
                  }
                }
              }
            }
          }
          await db.delete('upload_queue',
              where: 'id = ?', whereArgs: [queueItem.id]);
          anySuccess = true;
        } else {
          await db.update('upload_queue', {'status': 'error'},
              where: 'id = ?', whereArgs: [queueItem.id]);
        }
      }
      if (anySuccess) _notifyListeners();
    } catch (e) {
      debugPrint('UploadQueueProcessor error: $e');
    } finally {
      _isProcessing = false;
    }
  }

  Future<bool> _simulateUpload(File file) async {
    // Simulate network upload delay
    await Future.delayed(Duration(seconds: 2));
    // Simulate random success/failure
    return true; // Change to randomize for testing if needed
  }

  Future<void> retryFailedUploads() async {
    final db = await DatabaseService().database;
    await db.update('upload_queue', {'status': 'queued'},
        where: 'status = ?', whereArgs: ['error']);
    await processQueue();
  }
}
