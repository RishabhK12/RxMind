import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_llama/flutter_llama.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:http/http.dart' as http;

/// Local LLM service using llama.cpp with TinyLlama model.
/// All inference runs 100% on-device for complete privacy.
class LocalLlmService {
  LocalLlmService._();
  static final I = LocalLlmService._();

  final FlutterLlama _llama = FlutterLlama.instance;
  bool _isModelLoaded = false;
  bool _isLoading = false;
  String? _modelPath;

  /// Model file name - TinyLlama 1.1B Chat Q4_K_S quantization (~640MB)
  /// Small enough for mobile, good quality for medical Q&A
  static const String _modelFileName = 'tinyllama-1.1b-chat-v1.0.Q4_K_S.gguf';

  /// Download URL for the model from HuggingFace
  static const String _modelDownloadUrl =
      'https://huggingface.co/TheBloke/TinyLlama-1.1B-Chat-v1.0-GGUF/resolve/main/tinyllama-1.1b-chat-v1.0.Q4_K_S.gguf';

  bool get isModelLoaded => _isModelLoaded;
  bool get isLoading => _isLoading;

  /// Initialize and load the model
  Future<bool> initialize(
      {Function(double progress, String status)? onProgress}) async {
    if (_isModelLoaded) return true;
    if (_isLoading) return false;

    _isLoading = true;

    try {
      // Get the model path
      _modelPath = await _getModelPath();

      // Check if model exists, download if not
      final modelFile = File(_modelPath!);
      if (!await modelFile.exists()) {
        onProgress?.call(0.0, 'Downloading AI model...');
        final success = await _downloadModel(onProgress);
        if (!success) {
          _isLoading = false;
          return false;
        }
      }

      onProgress?.call(0.9, 'Loading AI model...');

      // Configure and load the model
      final config = LlamaConfig(
        modelPath: _modelPath!,
        nThreads: 4, // Conservative for mobile
        nGpuLayers: -1, // Use GPU if available
        contextSize: 2048, // Sufficient for medical Q&A
        batchSize: 512,
        useGpu: true, // Enable GPU acceleration
        verbose: kDebugMode,
      );

      final success = await _llama.loadModel(config);
      _isModelLoaded = success;
      _isLoading = false;

      if (success) {
        onProgress?.call(1.0, 'AI ready');
        if (kDebugMode) {
          debugPrint('[LocalLlmService] Model loaded successfully');
        }
      } else {
        if (kDebugMode) {
          debugPrint('[LocalLlmService] Failed to load model');
        }
      }

      return success;
    } catch (e) {
      _isLoading = false;
      if (kDebugMode) {
        debugPrint('[LocalLlmService] Error initializing: $e');
      }
      return false;
    }
  }

  /// Get the path where the model should be stored
  Future<String> _getModelPath() async {
    final appDir = await getApplicationDocumentsDirectory();
    final modelsDir = Directory(path.join(appDir.path, 'models'));
    if (!await modelsDir.exists()) {
      await modelsDir.create(recursive: true);
    }
    return path.join(modelsDir.path, _modelFileName);
  }

  /// Download the model from HuggingFace
  Future<bool> _downloadModel(
      Function(double progress, String status)? onProgress) async {
    try {
      final modelFile = File(_modelPath!);

      // Create a client for the download
      final client = http.Client();
      final request = http.Request('GET', Uri.parse(_modelDownloadUrl));
      final response = await client.send(request);

      if (response.statusCode != 200) {
        if (kDebugMode) {
          debugPrint(
              '[LocalLlmService] Download failed: ${response.statusCode}');
        }
        return false;
      }

      final contentLength = response.contentLength ?? 0;
      int received = 0;

      final sink = modelFile.openWrite();

      await for (final chunk in response.stream) {
        sink.add(chunk);
        received += chunk.length;
        if (contentLength > 0) {
          final progress = received / contentLength;
          onProgress?.call(progress * 0.85,
              'Downloading AI model (${(progress * 100).toInt()}%)...');
        }
      }

      await sink.close();
      client.close();

      if (kDebugMode) {
        debugPrint('[LocalLlmService] Model downloaded successfully');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[LocalLlmService] Download error: $e');
      }
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
    if (!_isModelLoaded) {
      final initialized = await initialize();
      if (!initialized) {
        throw Exception('Failed to initialize local LLM');
      }
    }

    try {
      // Format prompt using Zephyr/TinyLlama chat template
      final formattedPrompt = _formatPrompt(prompt, systemInstruction);

      final params = GenerationParams(
        prompt: formattedPrompt,
        temperature: temperature,
        topP: topP,
        topK: topK,
        maxTokens: maxTokens,
        repeatPenalty: 1.1,
      );

      final response = await _llama.generate(params);

      // Clean up the response
      String text = response.text.trim();

      // Remove any trailing special tokens
      text = text.replaceAll('</s>', '').trim();
      text = text.replaceAll('<|user|>', '').trim();
      text = text.replaceAll('<|assistant|>', '').trim();
      text = text.replaceAll('<|system|>', '').trim();

      // Extract JSON if the response contains it
      text = _extractJson(text);

      if (kDebugMode) {
        debugPrint(
            '[LocalLlmService] Generated ${response.tokensGenerated} tokens at ${response.tokensPerSecond.toStringAsFixed(1)} tok/s');
      }

      return text;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[LocalLlmService] Generation error: $e');
      }
      throw Exception('Failed to generate response: $e');
    }
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
    if (!_isModelLoaded) {
      final initialized = await initialize();
      if (!initialized) {
        throw Exception('Failed to initialize local LLM');
      }
    }

    try {
      final formattedPrompt = _formatPrompt(prompt, systemInstruction);

      final params = GenerationParams(
        prompt: formattedPrompt,
        temperature: temperature,
        topP: topP,
        topK: topK,
        maxTokens: maxTokens,
        repeatPenalty: 1.1,
      );

      await for (final token in _llama.generateStream(params)) {
        // Filter out special tokens
        if (!token.contains('</s>') &&
            !token.contains('<|user|>') &&
            !token.contains('<|assistant|>') &&
            !token.contains('<|system|>')) {
          yield token;
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[LocalLlmService] Stream generation error: $e');
      }
      throw Exception('Failed to generate response: $e');
    }
  }

  /// Format the prompt using Zephyr/TinyLlama chat template
  String _formatPrompt(String userPrompt, String? systemInstruction) {
    final buffer = StringBuffer();

    // Add system instruction if provided
    if (systemInstruction != null && systemInstruction.isNotEmpty) {
      buffer.writeln('<|system|>');
      buffer.writeln(systemInstruction);
      buffer.writeln('</s>');
    }

    // Add user prompt
    buffer.writeln('<|user|>');
    buffer.writeln(userPrompt);
    buffer.writeln('</s>');
    buffer.writeln('<|assistant|>');

    return buffer.toString();
  }

  /// Extract JSON from text that may contain preamble or other content
  String _extractJson(String text) {
    // Try to find JSON object
    final jsonStart = text.indexOf('{');
    final jsonEnd = text.lastIndexOf('}');

    if (jsonStart != -1 && jsonEnd != -1 && jsonEnd > jsonStart) {
      return text.substring(jsonStart, jsonEnd + 1);
    }

    // Try to find JSON array
    final arrayStart = text.indexOf('[');
    final arrayEnd = text.lastIndexOf(']');

    if (arrayStart != -1 && arrayEnd != -1 && arrayEnd > arrayStart) {
      return text.substring(arrayStart, arrayEnd + 1);
    }

    // Return original if no JSON found
    return text;
  }

  /// Unload the model to free memory
  Future<void> unload() async {
    if (_isModelLoaded) {
      await _llama.unloadModel();
      _isModelLoaded = false;
      if (kDebugMode) {
        debugPrint('[LocalLlmService] Model unloaded');
      }
    }
  }

  /// Get model info
  Future<Map<String, dynamic>?> getModelInfo() async {
    if (!_isModelLoaded) return null;
    return await _llama.getModelInfo();
  }

  /// Check if the model file exists
  Future<bool> isModelDownloaded() async {
    final modelPath = await _getModelPath();
    return File(modelPath).existsSync();
  }

  /// Delete the model file
  Future<void> deleteModel() async {
    await unload();
    final modelPath = await _getModelPath();
    final modelFile = File(modelPath);
    if (await modelFile.exists()) {
      await modelFile.delete();
      if (kDebugMode) {
        debugPrint('[LocalLlmService] Model file deleted');
      }
    }
  }
}
