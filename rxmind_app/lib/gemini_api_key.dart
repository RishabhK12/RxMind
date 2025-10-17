import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Loads Gemini API key from .env file in project root.
String get geminiApiKey => dotenv.env['GEMINI_API_KEY'] ?? '';
