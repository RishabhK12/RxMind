import 'dart:convert';
import '../storage/local_storage.dart';

class ChatManager {
  // Each chat session is a list of messages
  List<List<Map<String, dynamic>>> _chats = [];
  int _activeChatIndex = 0;

  List<Map<String, dynamic>> get activeChat =>
      _chats.isNotEmpty ? _chats[_activeChatIndex] : [];
  int get activeChatIndex => _activeChatIndex;
  int get chatCount => _chats.length;

  Future<void> loadChats() async {
    final raw = await LocalStorage.readSecure('ai_chats');
    if (raw != null) {
      try {
        final decoded = List<List<Map<String, dynamic>>>.from(
            (jsonDecode(raw) as List)
                .map((chat) => List<Map<String, dynamic>>.from(chat)));
        _chats = decoded;
      } catch (_) {
        _chats = [[]];
      }
    } else {
      _chats = [[]];
    }
  }

  Future<void> saveChats() async {
    await LocalStorage.writeSecure('ai_chats', jsonEncode(_chats));
  }

  void addMessage(String role, String content) {
    if (_chats.isEmpty) _chats.add([]);
    _chats[_activeChatIndex].add({
      'role': role,
      'content': content,
      'timestamp': DateTime.now().toIso8601String()
    });
    saveChats();
  }

  void newChat() {
    _chats.add([]);
    _activeChatIndex = _chats.length - 1;
    saveChats();
  }

  void switchChat(int index) {
    if (index >= 0 && index < _chats.length) {
      _activeChatIndex = index;
      saveChats();
    }
  }

  void clearHistory() {
    if (_chats.isNotEmpty) {
      _chats[_activeChatIndex].clear();
      saveChats();
    }
  }

  List<List<Map<String, dynamic>>> get allChats => _chats;
}
