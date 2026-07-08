import 'package:flutter/foundation.dart';

/// Manages on-device Gemma model lifecycle. Model weights live in app-private storage.
class ModelLoader {
  ModelLoader._();

  static bool _initAttempted = false;
  static bool _modelReady = false;

  static const String modelDirName = 'gemma_models';

  static bool get isModelReady => _modelReady;

  /// Attempts lazy initialization of flutter_gemma runtime.
  static Future<void> initialize() async {
    if (_initAttempted) return;
    _initAttempted = true;

    try {
      // flutter_gemma requires mobile native engines; skip on desktop/test VM.
      if (kIsWeb) return;

      // Dynamic init deferred until flutter_gemma packages are linked on device.
      // Model file must be placed in app-private dir via first-run download.
      _modelReady = false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('ModelLoader: init failed: $e');
      }
      _modelReady = false;
    }
  }

  @visibleForTesting
  static void setModelReadyForTest(bool ready) {
    _modelReady = ready;
    _initAttempted = true;
  }

  @visibleForTesting
  static void resetForTest() {
    _initAttempted = false;
    _modelReady = false;
  }
}
