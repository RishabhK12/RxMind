import '../chd/repositories/chat_message_repository.dart';
import '../storage/sqlcipher_database.dart';

class ChatManager {
  List<Map<String, dynamic>> _chats = [];
  int _activeChatIndex = 0;
  ChatMessageRepository? _repo;

  Future<ChatMessageRepository> _repository() async {
    _repo ??= ChatMessageRepository(await SecureDatabase.instance());
    return _repo!;
  }

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
  String get activeSessionId => _chats.isNotEmpty
      ? _chats[_activeChatIndex]['session_id'] as String? ?? 'session_0'
      : 'session_0';

  String get activeChatName => _chats.isNotEmpty
      ? _chats[_activeChatIndex]['name'] ?? 'Chat ${_activeChatIndex + 1}'
      : 'New Chat';

  bool get activeDisclosureAcknowledged {
    if (_chats.isEmpty) return false;
    return _chats[_activeChatIndex]['ai_disclosure_ack'] == true;
  }

  Future<void> loadChats() async {
    final repo = await _repository();
    final sessions = await repo.getSessions();
    if (sessions.isEmpty) {
      _chats = [
        {
          'session_id': 'session_0',
          'name': 'Chat 1',
          'ai_disclosure_ack': false,
          'messages': <Map<String, dynamic>>[],
        }
      ];
      return;
    }

    _chats = [];
    for (final session in sessions) {
      final sessionId = session['session_id'] as String;
      final messages = await repo.getMessages(sessionId);
      _chats.add({
        'session_id': sessionId,
        'name': session['name'],
        'ai_disclosure_ack': session['ai_disclosure_ack'] == true,
        'messages': messages,
      });
    }
    _activeChatIndex = 0;
  }

  Future<void> saveChats() async {
    if (_chats.isEmpty) return;
    final repo = await _repository();
    for (final chat in _chats) {
      final sessionId =
          chat['session_id'] as String? ?? 'session_${_chats.indexOf(chat)}';
      final messages = (chat['messages'] as List?)
              ?.map((m) => Map<String, dynamic>.from(m as Map))
              .toList() ??
          <Map<String, dynamic>>[];
      await repo.saveSession(
        sessionId,
        chat['name'] as String? ?? 'Chat',
        messages,
      );
      if (chat['ai_disclosure_ack'] == true) {
        await repo.setDisclosureAck(sessionId, true);
      }
    }
  }

  Future<void> acknowledgeDisclosure() async {
    if (_chats.isEmpty) return;
    final sessionId = activeSessionId;
    _chats[_activeChatIndex]['ai_disclosure_ack'] = true;
    final repo = await _repository();
    await repo.setDisclosureAck(sessionId, true);
  }

  void addMessage(String role, String content) {
    if (_chats.isEmpty) {
      _chats.add({
        'session_id': 'session_0',
        'name': 'Chat 1',
        'ai_disclosure_ack': false,
        'messages': <Map<String, dynamic>>[],
      });
    }

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

    final sessionId = activeSessionId;
    final msgId =
        '${sessionId}_${DateTime.now().microsecondsSinceEpoch}_${messages.length}';

    messages.add({
      'id': msgId,
      'role': role,
      'content': content,
      'timestamp': DateTime.now().toIso8601String(),
    });

    _chats[_activeChatIndex]['messages'] = messages;

    if (_chats[_activeChatIndex]['name'] == 'Chat ${_activeChatIndex + 1}' &&
        role == 'user' &&
        messages.where((m) => m['role'] == 'user').length == 1) {
      final words = content.split(' ');
      final name = words.take(4).join(' ');
      _chats[_activeChatIndex]['name'] =
          name.length > 30 ? '${name.substring(0, 30)}...' : name;
    }

    saveChats();
  }

  void newChat() {
    final id = 'session_${DateTime.now().millisecondsSinceEpoch}';
    _chats.add({
      'session_id': id,
      'name': 'Chat ${_chats.length + 1}',
      'ai_disclosure_ack': false,
      'messages': <Map<String, dynamic>>[],
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

  Future<void> deleteAllChats() async {
    final repo = await _repository();
    await repo.deleteAll();
    _chats = [
      {
        'session_id': 'session_0',
        'name': 'Chat 1',
        'ai_disclosure_ack': false,
        'messages': <Map<String, dynamic>>[],
      }
    ];
    _activeChatIndex = 0;
  }

  List<Map<String, dynamic>> get allChats => _chats;
}
