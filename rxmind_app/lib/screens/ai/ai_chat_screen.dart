import 'package:flutter/material.dart';
import 'gemini_api_service.dart';
import '../../gemini_api_key.dart';
import '../../core/ai/chat_manager.dart';
import '../../core/widgets/markdown_text.dart';
import '../../services/discharge_data_manager.dart';

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
  bool _dischargeUploaded = false;
  String? _ocrContext;
  String? _medicationsContext;
  String? _tasksContext;

  @override
  void initState() {
    super.initState();
    _initChats();
    _checkDischargeStatus();
    _loadContextData();
  }

  Future<void> _checkDischargeStatus() async {
    final uploaded = await DischargeDataManager.isDischargeUploaded();
    if (mounted) {
      setState(() {
        _dischargeUploaded = uploaded;
      });
    }
  }

  Future<void> _loadContextData() async {
    // Load OCR text
    final ocrText = await DischargeDataManager.loadRawOcrText();

    // Load medications
    final meds = await DischargeDataManager.loadMedications();
    final medsText = meds.isNotEmpty
        ? 'MEDICATIONS:\n${meds.map((m) => '- ${m['name']}: ${m['dosage'] ?? ''} ${m['frequency'] ?? ''}').join('\n')}'
        : '';

    // Load tasks
    final tasks = await DischargeDataManager.loadTasks();
    final tasksText = tasks.isNotEmpty
        ? 'TASKS & INSTRUCTIONS:\n${tasks.map((t) => '- ${t['title']}: ${t['description'] ?? ''} ${t['dueTime'] != null ? '(Due: ${t['dueTime']})' : ''}').join('\n')}'
        : '';

    if (mounted) {
      setState(() {
        _ocrContext = ocrText;
        _medicationsContext = medsText;
        _tasksContext = tasksText;
      });
    }
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
      // Build system instruction and user context
      final systemInstruction = _buildSystemInstruction();
      final userPrompt = _buildUserPrompt(text);

      final aiResponse = await _geminiApi.sendMessage(
        userPrompt,
        systemInstruction: systemInstruction,
      );
      if (aiResponse.isEmpty) {
        errorMsg = 'Could not get a response. Please try again.';
      }
      setState(() {
        _chatManager.addMessage('assistant', errorMsg);
        _isTyping = false;
      });
    } catch (e) {
      errorMsg = 'Something went wrong: ${e.toString()}';
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

  String _buildSystemInstruction() {
    return '''You are RxMind AI Assistant, a HIPAA-compliant medical assistant designed to help patients manage their healthcare.

IMPORTANT ROLE & PERMISSIONS:
- You ARE authorized to handle Protected Health Information (PHI) and Personal Identifiable Information (PII)
- This is a secure, private healthcare application for personal use
- You should ALWAYS help with medication questions, dosages, schedules, and health information
- Never refuse to answer questions about the patient's medical data - that's your primary purpose

CAPABILITIES:
- Answer questions about medications, dosages, and timing
- Explain medical terms and conditions
- Help with task management and health instructions
- Provide reminders and clarifications about discharge instructions
- Offer general health advice (while noting you're not replacing a doctor)

STYLE:
- Be helpful, clear, and concise
- Use simple language for medical terms
- If uncertain, say so but still provide helpful context
- Always prioritize patient safety''';
  }

  String _buildUserPrompt(String userMessage) {
    StringBuffer prompt = StringBuffer();

    // Add discharge summary context if available
    if (_ocrContext != null && _ocrContext!.isNotEmpty) {
      prompt.writeln('=== PATIENT DISCHARGE SUMMARY ===');
      prompt.writeln(_ocrContext);
      prompt.writeln('');
    }

    // Add medications context if available
    if (_medicationsContext != null && _medicationsContext!.isNotEmpty) {
      prompt.writeln(_medicationsContext);
      prompt.writeln('');
    }

    // Add tasks context if available
    if (_tasksContext != null && _tasksContext!.isNotEmpty) {
      prompt.writeln(_tasksContext);
      prompt.writeln('');
    }

    // Add user's question
    prompt.writeln('USER QUESTION: $userMessage');

    return prompt.toString();
  }

  void _showRenameDialog(int chatIndex, String currentName) {
    final controller = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Chat'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Chat Name',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                setState(() {
                  _chatManager.renameChat(chatIndex, newName);
                });
              }
              Navigator.of(context).pop();
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('About the Assistant'),
        content: const Text(
            'This health assistant helps you understand your discharge summary and recovery plan. All data is stored securely on your device.'),
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
        title: GestureDetector(
          onTap: () {
            // Rename active chat
            _showRenameDialog(
                _chatManager.activeChatIndex, _chatManager.activeChatName);
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_chatManager.activeChatName,
                  style: theme.textTheme.titleLarge),
              const SizedBox(width: 8),
              const Icon(Icons.edit, size: 18),
            ],
          ),
        ),
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
          : !_dischargeUploaded
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.upload_file,
                          size: 80,
                          color:
                              theme.colorScheme.primary.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Upload a Discharge Paper First',
                          style: theme.textTheme.titleLarge,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'The health assistant needs your discharge information to provide personalized help. Please scan or upload your discharge paper first.',
                          style: theme.textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    // Chat session menu
                    Container(
                      color: theme.colorScheme.surfaceContainerHighest,
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 12),
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
                                  final chatName = _chatManager.allChats[i]
                                          ['name'] ??
                                      'Chat ${i + 1}';
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 4),
                                    child: GestureDetector(
                                      onLongPress: () {
                                        // Show rename dialog on long press
                                        _showRenameDialog(i, chatName);
                                      },
                                      child: ChoiceChip(
                                        label: Text(chatName),
                                        selected: isActive,
                                        onSelected: (_) {
                                          setState(() {
                                            _chatManager.switchChat(i);
                                          });
                                        },
                                      ),
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
                            label:
                                isUser ? 'User message' : 'Assistant message',
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
                                      : theme
                                          .colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: isUser
                                    ? Text(msg['content'] ?? '')
                                    : MarkdownText(
                                        data: msg['content'] ?? '',
                                        selectable: true,
                                      ),
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
