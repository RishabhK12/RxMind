import 'dart:convert';
import '../storage/local_storage.dart';

class ChatManager {
  // Each chat session is a list of messages with a name
  List<Map<String, dynamic>> _chats = [];
  int _activeChatIndex = 0;

  List<Map<String, dynamic>> get activeChat {
    if (_chats.isEmpty) return [];
    final messages = _chats[_activeChatIndex]['messages'];
    if (messages is List<Map<String, dynamic>>) return messages;
    if (messages is List) {
      return messages.map((m) => Map<String, dynamic>.from(m as Map)).toList();
    }
    return [];
  }

  int get activeChatIndex => _activeChatIndex;
  int get chatCount => _chats.length;
  String get activeChatName => _chats.isNotEmpty
      ? _chats[_activeChatIndex]['name'] ?? 'Chat ${_activeChatIndex + 1}'
      : 'New Chat';

  Future<void> loadChats() async {
    final raw = await LocalStorage.readSecure('ai_chats');
    if (raw != null) {
      try {
        final decoded = jsonDecode(raw) as List;
        _chats = decoded.map((chat) {
          return {
            'name': chat['name'] as String? ?? 'Chat',
            'messages': (chat['messages'] as List?)?.map((msg) {
                  return Map<String, dynamic>.from(msg as Map);
                }).toList() ??
                [],
          };
        }).toList();
      } catch (_) {
        _chats = [
          {'name': 'Chat 1', 'messages': <Map<String, dynamic>>[]}
        ];
      }
    } else {
      _chats = [
        {'name': 'Chat 1', 'messages': <Map<String, dynamic>>[]}
      ];
    }
  }

  Future<void> saveChats() async {
    await LocalStorage.writeSecure('ai_chats', jsonEncode(_chats));
  }

  void addMessage(String role, String content) {
    if (_chats.isEmpty)
      _chats.add({'name': 'Chat 1', 'messages': <Map<String, dynamic>>[]});

    final currentMessages = _chats[_activeChatIndex]['messages'];
    List<Map<String, dynamic>> messages;

    if (currentMessages is List<Map<String, dynamic>>) {
      messages = List<Map<String, dynamic>>.from(currentMessages);
    } else if (currentMessages is List) {
      messages = currentMessages
          .map((m) => Map<String, dynamic>.from(m as Map))
          .toList();
    } else {
      messages = <Map<String, dynamic>>[];
    }

    messages.add({
      'role': role,
      'content': content,
      'timestamp': DateTime.now().toIso8601String()
    });

    _chats[_activeChatIndex]['messages'] = messages;

    // Auto-name chat based on first user message if still using default name
    if (_chats[_activeChatIndex]['name'] == 'Chat ${_activeChatIndex + 1}' &&
        role == 'user' &&
        messages.where((m) => m['role'] == 'user').length == 1) {
      // Use first few words of first user message
      final words = content.split(' ');
      final name = words.take(4).join(' ');
      _chats[_activeChatIndex]['name'] =
          name.length > 30 ? '${name.substring(0, 30)}...' : name;
    }

    saveChats();
  }

  void newChat() {
    _chats.add({
      'name': 'Chat ${_chats.length + 1}',
      'messages': <Map<String, dynamic>>[]
    });
    _activeChatIndex = _chats.length - 1;
    saveChats();
  }

  void switchChat(int index) {
    if (index >= 0 && index < _chats.length) {
      _activeChatIndex = index;
      saveChats();
    }
  }

  void renameChat(int index, String newName) {
    if (index >= 0 && index < _chats.length) {
      _chats[index]['name'] = newName;
      saveChats();
    }
  }

  void renameActiveChat(String newName) {
    renameChat(_activeChatIndex, newName);
  }

  void clearHistory() {
    if (_chats.isNotEmpty) {
      _chats[_activeChatIndex]['messages'] = <Map<String, dynamic>>[];
      saveChats();
    }
  }

  List<Map<String, dynamic>> get allChats => _chats;
}
