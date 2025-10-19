import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:rxmind_app/screens/ai/gemini_api_service.dart';
import 'package:rxmind_app/services/discharge_data_manager.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Message> _messages = [];
  bool _loading = false;
  late final GeminiApiService _model;
  String? _initialContext;
  bool _didRun = false;

  @override
  void initState() {
    super.initState();
    // Instead of using GoogleGemini directly, use our wrapper service
    _model = GeminiApiService(
      apiKey: const String.fromEnvironment('GEMINI_API_KEY'),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didRun) {
      _didRun = true;
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      _initialContext = args?['initial_context'] as String?;
      _loadInitialContext();
    }
  }

  Future<void> _loadInitialContext() async {
    if (_initialContext == null) {
      _initialContext = await DischargeDataManager.loadRawOcrText();
    }

    if (_initialContext != null && _initialContext!.isNotEmpty) {
      setState(() {
        _messages.add(Message(
            isUser: false,
            text:
                "Hello! I have your discharge summary. How can I help you today?"));
      });
    } else {
      setState(() {
        _messages.add(
            Message(isUser: false, text: "Hello! How can I help you today?"));
      });
    }
  }

  void _sendMessage() async {
    if (_controller.text.isEmpty) return;

    final userMessage = _controller.text;
    setState(() {
      _messages.add(Message(isUser: true, text: userMessage));
      _loading = true;
    });
    _controller.clear();

    try {
      String promptText;
      if (_initialContext != null && _initialContext!.isNotEmpty) {
        promptText =
            'Here is the patient\'s discharge summary for context:\n$_initialContext\n\nUser question: $userMessage';
      } else {
        promptText =
            'User question: $userMessage\n\nNote: No discharge summary is available for context.';
      }

      final response = await _model.sendMessage(promptText);

      setState(() {
        _messages.add(Message(isUser: false, text: response));
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _messages.add(Message(isUser: false, text: 'Error: ${e.toString()}'));
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Assistant'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8.0),
              reverse: true,
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[_messages.length - 1 - index];
                return MessageBubble(message: message);
              },
            ),
          ),
          if (_loading) const LinearProgressIndicator(),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Ask a question...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    onSubmitted: (value) => _sendMessage(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class Message {
  final bool isUser;
  final String text;

  Message({required this.isUser, required this.text});
}

class MessageBubble extends StatelessWidget {
  final Message message;

  const MessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: message.isUser
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: MarkdownBody(
          data: message.text,
          styleSheet: MarkdownStyleSheet(
            p: TextStyle(
              color: message.isUser
                  ? Theme.of(context).colorScheme.onPrimary
                  : Theme.of(context).colorScheme.onSecondaryContainer,
            ),
          ),
        ),
      ),
    );
  }
}
