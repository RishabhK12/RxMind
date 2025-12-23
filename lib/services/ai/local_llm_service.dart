import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_gemma/flutter_gemma.dart';

/// Local LLM service using `flutter_gemma` (MediaPipe GenAI / LiteRT).
/// All inference runs 100% on-device for complete privacy.
class LocalLlmService {
  LocalLlmService._();
  static final I = LocalLlmService._();

  bool _isModelLoaded = false;
  bool _isLoading = false;

  String? _lastInitError;

  InferenceModel? _model;

  // The underlying MediaPipe GenAI session currently behaves like a global
  // single-flight resource on some devices/builds. If two requests overlap, or
  // a previous session isn't properly closed after an error, subsequent calls
  // can fail with:
  //   PredictDone() AddQueryChunk should not be called before PredictDone
  // Serialize all inference calls to keep the engine in a consistent state.
  Future<void> _inferenceQueue = Future.value();

  Future<T> _enqueueInference<T>(Future<T> Function() op) {
    final completer = Completer<T>();

    _inferenceQueue = _inferenceQueue.then((_) async {
      try {
        final result = await op();
        completer.complete(result);
      } catch (e, st) {
        completer.completeError(e, st);
      }
    }).catchError((_) {
      // Swallow errors in the queue chain so future requests still run.
    });

    return completer.future;
  }

  /// Model file name (installed via flutter_gemma).
  /// Public repo, no HuggingFace token required.
  static const String _modelFileName =
      'TinyLlama-1.1B-Chat-v1.0_multi-prefill-seq_q8_ekv1280.task';

  /// Download URL for the model from HuggingFace.
  static const String _modelDownloadUrl =
      'https://huggingface.co/litert-community/TinyLlama-1.1B-Chat-v1.0/resolve/main/TinyLlama-1.1B-Chat-v1.0_multi-prefill-seq_q8_ekv1280.task';

  // This specific .task variant is built with KV-cache size 1280 (ekv1280).
  // Passing a larger maxTokens will fail during engine init.
  static const int _modelMaxContextTokens = 1280;

  // Token budgeting: LiteRT counts (input tokens + output tokens) against
  // maxTokens. We must reserve headroom for the model response and some
  // internal/system overhead.
  static const int _contextOverheadTokens = 128;

  // Conservative heuristic: ~3 characters per token. This intentionally
  // underestimates the allowed input size to avoid OUT_OF_RANGE at runtime.
  static const int _charsPerTokenEstimate = 3;

  bool get isModelLoaded => _isModelLoaded;
  bool get isLoading => _isLoading;
  String? get lastInitError => _lastInitError;

  /// Initialize and load the model.
  ///
  /// If the model is not installed yet, this will download and install it.
  Future<bool> initialize(
      {Function(double progress, String status)? onProgress}) async {
    if (_isModelLoaded) return true;
    if (_isLoading) return false;

    _isLoading = true;
    _lastInitError = null;
    try {
      final installed = await FlutterGemma.isModelInstalled(_modelFileName);
      final hasActive = FlutterGemma.hasActiveModel();

      // `flutter_gemma` does not guarantee the active model is persisted across
      // app restarts. If the model file is already installed but there's no
      // active spec, calling installModel().install() will *skip download* and
      // set the active model spec.
      if (!installed) {
        onProgress?.call(0.0, 'Downloading AI model...');
        await FlutterGemma.installModel(modelType: ModelType.llama)
            .fromNetwork(_modelDownloadUrl)
            .withProgress((progress) {
          onProgress?.call(
              progress / 100.0, 'Downloading AI model ($progress%)...');
        }).install();
      } else if (!hasActive) {
        onProgress?.call(0.0, 'Activating AI model...');
        await FlutterGemma.installModel(modelType: ModelType.llama)
            .fromNetwork(_modelDownloadUrl)
            .install();
      }

      onProgress?.call(0.95, 'Loading AI model...');

      // Force CPU backend.
      // The OpenCL/ML_DRIFT_CL GPU delegate can fail at runtime on some
      // devices and may trigger a native crash after a delegate failure.
      _model = await FlutterGemma.getActiveModel(
        maxTokens: _modelMaxContextTokens,
        preferredBackend: PreferredBackend.cpu,
      );

      _isModelLoaded = true;
      _isLoading = false;
      onProgress?.call(1.0, 'AI ready');

      if (kDebugMode) {
        debugPrint('[LocalLlmService] Model ready (flutter_gemma)');
      }

      return true;
    } catch (e, st) {
      _isLoading = false;
      _isModelLoaded = false;
      _lastInitError = e.toString();
      if (kDebugMode) {
        debugPrint('[LocalLlmService] Error initializing: $e');
        debugPrint('$st');
      }
      onProgress?.call(0.0, 'AI init error: ${_lastInitError!}');
      return false;
    }
  }

  /// Generate text using the local model
  Future<String> generateText(
    String prompt, {
    String? systemInstruction,
    double temperature = 0.7,
    int maxTokens = 512,
    double topP = 0.95,
    int topK = 40,
  }) async {
    return _enqueueInference(() async {
      if (!_isModelLoaded) {
        final initialized = await initialize();
        if (!initialized) {
          throw Exception(
              'Failed to initialize local LLM${_lastInitError == null ? '' : ': $_lastInitError'}');
        }
      }

      InferenceChat? chat;
      try {
        final model = _model;
        if (model == null) {
          throw Exception('Local model instance not available');
        }

        // Ensure the request fits within the model context.
        final preparedPrompt = _preparePromptForContext(
          userPrompt: prompt,
          systemInstruction: systemInstruction,
          desiredOutputTokens: maxTokens,
        );

        chat = await model.createChat(
          temperature: temperature,
          topP: topP,
          topK: topK,
          tokenBuffer: _clampDesiredOutputTokens(maxTokens),
          modelType: ModelType.llama,
        );

        if (systemInstruction != null && systemInstruction.isNotEmpty) {
          await chat.addQueryChunk(Message.systemInfo(text: systemInstruction));
        }
        await chat.addQueryChunk(
          Message.text(text: preparedPrompt, isUser: true),
        );

        final response = await chat.generateChatResponse();

        final rawText =
            response is TextResponse ? response.token : response.toString();
        final text = _extractJson(rawText.trim());
        return text;
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[LocalLlmService] Generation error: $e');
        }
        throw Exception('Failed to generate response: $e');
      } finally {
        try {
          await chat?.session.close();
        } catch (_) {
          // Best-effort close; ignore.
        }
      }
    });
  }

  /// Generate text with streaming support
  Stream<String> generateTextStream(
    String prompt, {
    String? systemInstruction,
    double temperature = 0.7,
    int maxTokens = 512,
    double topP = 0.95,
    int topK = 40,
  }) async* {
    final controller = StreamController<String>();

    // Run streaming inference in the same single-flight queue.
    unawaited(_enqueueInference(() async {
      if (!_isModelLoaded) {
        final initialized = await initialize();
        if (!initialized) {
          throw Exception(
              'Failed to initialize local LLM${_lastInitError == null ? '' : ': $_lastInitError'}');
        }
      }

      final model = _model;
      if (model == null) {
        throw Exception('Local model instance not available');
      }

      // Ensure the request fits within the model context.
      final preparedPrompt = _preparePromptForContext(
        userPrompt: prompt,
        systemInstruction: systemInstruction,
        desiredOutputTokens: maxTokens,
      );

      InferenceChat? chat;
      StreamSubscription? sub;
      try {
        chat = await model.createChat(
          temperature: temperature,
          topP: topP,
          topK: topK,
          tokenBuffer: _clampDesiredOutputTokens(maxTokens),
          modelType: ModelType.llama,
        );

        if (systemInstruction != null && systemInstruction.isNotEmpty) {
          await chat.addQueryChunk(Message.systemInfo(text: systemInstruction));
        }
        await chat.addQueryChunk(
          Message.text(text: preparedPrompt, isUser: true),
        );

        sub = chat.generateChatResponseAsync().listen(
          (response) {
            if (response is TextResponse) {
              controller.add(response.token);
            }
          },
          onError: (e, st) async {
            controller.addError(e, st);
            await sub?.cancel();
            try {
              await chat?.session.close();
            } catch (_) {}
            await controller.close();
          },
          onDone: () async {
            try {
              await chat?.session.close();
            } catch (_) {}
            await controller.close();
          },
          cancelOnError: true,
        );

        // Hold the inference lock until the stream is fully finished.
        await controller.done;
      } finally {
        try {
          await sub?.cancel();
        } catch (_) {}
        try {
          await chat?.session.close();
        } catch (_) {}
        if (!controller.isClosed) {
          await controller.close();
        }
      }
      return true;
    }).catchError((e, st) async {
      if (!controller.isClosed) {
        controller.addError(e, st);
        await controller.close();
      }
      return false;
    }));

    yield* controller.stream;
  }

  /// Extract JSON from text that may contain preamble or other content
  String _extractJson(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return trimmed;

    // If it's already valid JSON, keep it.
    try {
      jsonDecode(trimmed);
      return trimmed;
    } catch (_) {
      // continue
    }

    // Prefer a JSON object that looks like our discharge structure.
    const requiredKeys = <String>{
      'medications',
      'follow_ups',
      'instructions',
      'tasks',
      'warnings',
      'contacts',
    };

    String? best;
    int bestScore = -1;

    for (int i = 0; i < trimmed.length; i++) {
      if (trimmed.codeUnitAt(i) != 0x7B /* { */) continue;

      final end = _findMatchingJsonBrace(trimmed, i);
      if (end == -1) continue;

      final candidate = trimmed.substring(i, end + 1);
      Object? decoded;
      try {
        decoded = jsonDecode(candidate);
      } catch (_) {
        continue;
      }

      if (decoded is Map) {
        final keys = decoded.keys.map((k) => k.toString()).toSet();
        final score = keys.intersection(requiredKeys).length;

        // Prefer candidates that match our expected schema; tie-breaker is size.
        final isBetter = score > bestScore ||
            (score == bestScore &&
                best != null &&
                candidate.length > best!.length) ||
            (score == bestScore && best == null);

        if (isBetter) {
          bestScore = score;
          best = candidate;
          if (bestScore == requiredKeys.length) break;
        }
      }
    }

    if (best != null) return best!;

    // No JSON object found; return original so callers can still inspect/log it.
    return trimmed;
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

  int _clampDesiredOutputTokens(int desired) {
    // Keep output headroom reasonable for small-context models.
    if (desired <= 0) return 128;
    if (desired < 64) return desired;
    if (desired > 256) return 256;
    return desired;
  }

  String _preparePromptForContext({
    required String userPrompt,
    required String? systemInstruction,
    required int desiredOutputTokens,
  }) {
    final reservedOutput = _clampDesiredOutputTokens(desiredOutputTokens);

    // Available budget for (system + user) text.
    final maxInputTokens =
        _modelMaxContextTokens - reservedOutput - _contextOverheadTokens;
    if (maxInputTokens <= 0) {
      // Worst-case: still return something minimal.
      return userPrompt;
    }

    final maxCombinedChars = maxInputTokens * _charsPerTokenEstimate;
    final systemChars = (systemInstruction?.length ?? 0);

    // If system message already consumes the budget, heavily trim user prompt.
    final maxUserChars =
        (maxCombinedChars - systemChars).clamp(0, maxCombinedChars);
    if (userPrompt.length <= maxUserChars) return userPrompt;

    // Preserve a small prefix (often contains instructions) and a tail (often
    // contains the latest/most relevant extracted text), with a clear marker.
    final head = maxUserChars >= 2400 ? 2000 : (maxUserChars ~/ 3);
    final tail = (maxUserChars - head).clamp(0, maxUserChars);

    final headText = head > 0 ? userPrompt.substring(0, head) : '';
    final tailText =
        tail > 0 ? userPrompt.substring(userPrompt.length - tail) : '';

    return '$headText\n\n[TRUNCATED to fit on-device model context]\n\n$tailText';
  }

  /// Unload the model to free memory
  Future<void> unload() async {
    if (_isModelLoaded) {
      await _model?.close();
      _model = null;
      _isModelLoaded = false;
      if (kDebugMode) {
        debugPrint('[LocalLlmService] Model unloaded');
      }
    }
  }

  /// Get model info
  Future<Map<String, dynamic>?> getModelInfo() async {
    if (!_isModelLoaded) return null;
    return <String, dynamic>{
      'engine': 'flutter_gemma',
      'modelFile': _modelFileName,
    };
  }

  /// Check if the model file exists
  Future<bool> isModelDownloaded() async {
    return FlutterGemma.isModelInstalled(_modelFileName);
  }

  /// Delete the model file
  Future<void> deleteModel() async {
    await unload();
    if (kDebugMode) {
      debugPrint(
          '[LocalLlmService] deleteModel: not implemented for flutter_gemma');
    }
  }
}
