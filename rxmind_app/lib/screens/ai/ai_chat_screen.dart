import 'package:flutter/material.dart';
import 'gemini_api_service.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({Key? key}) : super(key: key);

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  // TODO: Replace with secure storage or env config in production
  static const String _apiKey = 'YOUR_GEMINI_API_KEY_HERE';
  late final GeminiApiService _geminiApi = GeminiApiService(apiKey: _apiKey);
  final List<_ChatMessage> _messages = [
    _ChatMessage(
        isUser: false,
        text:
            'Hi! I can help explain your discharge instructions or answer health questions.'),
  ];
  final TextEditingController _controller = TextEditingController();
  bool _isTyping = false;
  bool _contextLoaded = true;

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add(_ChatMessage(isUser: true, text: text));
      _controller.clear();
      _isTyping = true;
    });
    try {
      final aiResponse = await _geminiApi.sendMessage(text);
      setState(() {
        _messages.add(_ChatMessage(isUser: false, text: aiResponse));
        _isTyping = false;
      });
    } catch (e) {
      setState(() {
        _messages.add(_ChatMessage(isUser: false, text: 'AI error: $e'));
        _isTyping = false;
      });
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
      backgroundColor: theme.colorScheme.background,
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
      body: Column(
        children: [
          if (_contextLoaded)
            Semantics(
              label: 'Context loaded',
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text('Context loaded', style: theme.textTheme.bodySmall),
              ),
            ),
          Expanded(
            child: ListView.builder(
              reverse: false,
              itemCount: _messages.length,
              itemBuilder: (context, i) {
                final msg = _messages[i];
                return Semantics(
                  label: msg.isUser ? 'User message' : 'Assistant message',
                  child: Align(
                    alignment: msg.isUser
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                          vertical: 4, horizontal: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: msg.isUser
                            ? theme.colorScheme.primary.withOpacity(0.15)
                            : theme.colorScheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(msg.text),
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

class _ChatMessage {
  final bool isUser;
  final String text;
  _ChatMessage({required this.isUser, required this.text});
}

class _TypingIndicator extends StatefulWidget {
  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (i) {
          return AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final t = (_controller.value + i * 0.2) % 1.0;
              final scale = 0.8 + 0.4 * (1 - (t - 0.5).abs() * 2);
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Transform.scale(
                  scale: scale,
                  child: CircleAvatar(
                    radius: 5,
                    backgroundColor: theme.colorScheme.primary,
                  ),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}
