/// Deprecated: The app no longer uses a local Gemini API key. All requests
/// are routed through the backend proxy which holds the key securely.
/// This remains only to avoid import errors in any legacy code.
String get geminiApiKey => '';
