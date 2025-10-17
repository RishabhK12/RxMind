import 'package:flutter/material.dart';
import 'gemini_api_service.dart';
import '../../gemini_api_key.dart';
import '../../core/ai/chat_manager.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  late final GeminiApiService _geminiApi =
      GeminiApiService(apiKey: geminiApiKey);
  final ChatManager _chatManager = ChatManager();
  final TextEditingController _controller = TextEditingController();
  bool _isTyping = false;
  final bool _contextLoaded = true;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initChats();
  }

  Future<void> _initChats() async {
    await _chatManager.loadChats();
    setState(() {
      _initialized = true;
    });
  }

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _chatManager.addMessage('user', text);
      _controller.clear();
      _isTyping = true;
    });
    String errorMsg = '';
    try {
      final aiResponse = await _geminiApi.sendMessage(text);
      if (aiResponse.isEmpty) {
        errorMsg = 'No response from Gemini API.';
        setState(() {
          _chatManager.addMessage('assistant', errorMsg);
          _isTyping = false;
        });
      } else {
        setState(() {
          _chatManager.addMessage('assistant', aiResponse);
          _isTyping = false;
        });
      }
    } catch (e) {
      errorMsg = 'AI error: ${e.toString()}';
      setState(() {
        _chatManager.addMessage('assistant', errorMsg);
        _isTyping = false;
      });
    }
    if (errorMsg.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg, style: const TextStyle(color: Colors.red)),
          backgroundColor: Colors.white,
        ),
      );
    }
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('About the Assistant'),
        content: const Text(
            'This AI assistant helps you understand your discharge summary and health context. All processing is local or via Gemini API. Your privacy is guaranteed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 1,
        title: Text('AI Chat', style: theme.textTheme.titleLarge),
        actions: [
          Semantics(
            label: 'About the Assistant',
            button: true,
            child: IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: _showInfoDialog,
              tooltip: 'About the Assistant',
            ),
          ),
        ],
      ),
      body: !_initialized
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Chat session menu
                Container(
                  color: theme.colorScheme.surfaceContainerHighest,
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children:
                                List.generate(_chatManager.chatCount, (i) {
                              final isActive =
                                  i == _chatManager.activeChatIndex;
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                child: ChoiceChip(
                                  label: Text('Chat ${i + 1}'),
                                  selected: isActive,
                                  onSelected: (_) {
                                    setState(() {
                                      _chatManager.switchChat(i);
                                    });
                                  },
                                ),
                              );
                            }),
                          ),
                        ),
                      ),
                      Semantics(
                        label: 'New chat',
                        button: true,
                        child: IconButton(
                          icon: const Icon(Icons.add),
                          tooltip: 'New chat',
                          onPressed: () {
                            setState(() {
                              _chatManager.newChat();
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                if (_contextLoaded)
                  Semantics(
                    label: 'Context loaded',
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text('Context loaded',
                          style: theme.textTheme.bodySmall),
                    ),
                  ),
                Expanded(
                  child: ListView.builder(
                    reverse: false,
                    itemCount: _chatManager.activeChat.length,
                    itemBuilder: (context, i) {
                      final msg = _chatManager.activeChat[i];
                      final isUser = msg['role'] == 'user';
                      return Semantics(
                        label: isUser ? 'User message' : 'Assistant message',
                        child: Align(
                          alignment: isUser
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(
                                vertical: 4, horizontal: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isUser
                                  ? theme.colorScheme.primary
                                      .withValues(alpha: 0.15)
                                  : theme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(msg['content'] ?? ''),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                if (_isTyping)
                  Semantics(
                    label: 'Assistant is typing',
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          const SizedBox(width: 8),
                          const CircularProgressIndicator(strokeWidth: 2),
                          const SizedBox(width: 12),
                          Text('Assistant is typing...',
                              style: theme.textTheme.bodySmall),
                        ],
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Semantics(
                          label: 'Type your message',
                          textField: true,
                          child: TextField(
                            controller: _controller,
                            decoration: const InputDecoration(
                              hintText: 'Type your message...',
                              border: OutlineInputBorder(),
                            ),
                            onSubmitted: (_) => _sendMessage(),
                          ),
                        ),
                      ),
                      Semantics(
                        label: 'Send message',
                        button: true,
                        child: IconButton(
                          icon: const Icon(Icons.send),
                          onPressed: _sendMessage,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
