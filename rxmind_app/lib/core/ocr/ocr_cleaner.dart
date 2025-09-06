class OcrCleaner {
  static String cleanText(String rawText) {
    // Remove artifacts, excessive whitespace, and normalize line breaks
    String cleaned = rawText.replaceAll(RegExp(r'\s+'), ' ');
    cleaned = cleaned.replaceAll(RegExp(r'\n+'), '\n');
    cleaned = cleaned.trim();
    return cleaned;
  }
}
