class ChatManager {
  List<Map<String, dynamic>> _messages = [];

  List<Map<String, dynamic>> get messages => _messages;

  void addMessage(String role, String content) {
    _messages.add({
      'role': role,
      'content': content,
      'timestamp': DateTime.now().toIso8601String()
    });
    // TODO: Persist locally
  }

  void clearHistory() {
    _messages.clear();
    // TODO: Remove from local storage
  }
}
