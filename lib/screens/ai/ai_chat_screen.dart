import 'package:flutter/material.dart';
import 'package:rxmind_app/core/ai/ai_context_builder.dart';
import 'package:rxmind_app/core/ai/ai_report_store.dart';
import 'package:rxmind_app/core/ai/chat_manager.dart';
import 'package:rxmind_app/core/ai/local_ai_service.dart';
import 'package:rxmind_app/core/ai/safety_pipeline.dart';
import 'package:rxmind_app/core/ai/wellness_prompts.dart';
import 'package:rxmind_app/screens/ai/ai_disclosure_banner.dart';
import 'package:rxmind_app/screens/ai/assistant_message_bubble.dart';
import 'package:rxmind_app/screens/ai/emergency_static_screen.dart';
import 'package:rxmind_app/screens/ai/report_output_sheet.dart';
import 'package:rxmind_app/services/discharge_data_manager.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final LocalAiService _localAi = LocalAiService();
  final ChatManager _chatManager = ChatManager();
  final SafetyPipeline _pipeline = SafetyPipeline();
  final TextEditingController _controller = TextEditingController();
  bool _isTyping = false;
  bool _contextLoaded = false;
  bool _initialized = false;
  bool _dischargeUploaded = false;
  String _contextBlock = '';

  @override
  void initState() {
    super.initState();
    _initChats();
    _checkDischargeStatus();
    _loadContext();
    _localAi.ensureInitialized();
  }

  Future<void> _loadContext() async {
    try {
      final block = await AiContextBuilder.buildStructuredContext();
      if (mounted) {
        setState(() {
          _contextBlock = block;
          _contextLoaded = true;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _contextLoaded = false);
    }
  }

  Future<void> _checkDischargeStatus() async {
    final uploaded = await DischargeDataManager.isDischargeUploaded();
    if (mounted) {
      setState(() {
        _dischargeUploaded = uploaded;
      });
    }
  }

  Future<void> _initChats() async {
    await _chatManager.loadChats();
    setState(() {
      _initialized = true;
    });
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    if (!_chatManager.activeDisclosureAcknowledged) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Please acknowledge the AI disclosure before chatting.'),
        ),
      );
      return;
    }

    setState(() {
      _chatManager.addMessage('user', text);
      _controller.clear();
      _isTyping = true;
    });

    try {
      final result = await _pipeline.runChat(
        userMessage: text,
        systemPrompt: WellnessPrompts.chatSystemInstruction,
        contextBlock: _contextBlock,
      );

      if (!mounted) return;

      if (result.isEmergency) {
        setState(() => _isTyping = false);
        Navigator.of(context).push(
          MaterialPageRoute(
            fullscreenDialog: true,
            builder: (_) =>
                EmergencyStaticScreen(category: result.emergencyCategory!),
          ),
        );
        return;
      }

      if (result.rateLimited) {
        setState(() {
          _chatManager.addMessage(
            'assistant',
            'Rate limit reached. Please try again later.',
          );
          _isTyping = false;
        });
        return;
      }

      setState(() {
        _chatManager.addMessage(
          'assistant',
          result.displayText ?? LocalAiUnavailableException.fallbackMessage,
        );
        _isTyping = false;
      });
    } catch (e) {
      final errorMsg = 'Something went wrong: ${e.toString()}';
      setState(() {
        _chatManager.addMessage('assistant', errorMsg);
        _isTyping = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg, style: const TextStyle(color: Colors.red)),
            backgroundColor: Colors.white,
          ),
        );
      }
    }
  }

  Future<void> _reportMessage(Map<String, dynamic> msg) async {
    final messageId = msg['id']?.toString() ?? '';
    final content = msg['content']?.toString() ?? '';
    if (messageId.isEmpty || content.isEmpty) return;

    await showReportOutputSheet(
      context: context,
      onSubmit: (reason, note) async {
        final store = await AiReportStore.instance();
        await store.insert(
          messageId: messageId,
          messageHash: AiReportStore.hashContent(content),
          reason: reason,
          note: note,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Report saved locally.')),
          );
        }
      },
    );
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
        title: const Text('About the Wellness Guide'),
        content: const Text(
          'This wellness guide helps you organize and clarify recovery information '
          'from documents you provide. All data stays on your device. '
          'This app is not a medical device.',
        ),
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
    final needsDisclosure = _initialized &&
        _dischargeUploaded &&
        !_chatManager.activeDisclosureAcknowledged;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 1,
        title: GestureDetector(
          onTap: () {
            _showRenameDialog(
              _chatManager.activeChatIndex,
              _chatManager.activeChatName,
            );
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Chip(
              label: const Text('AI · On-Device'),
              visualDensity: VisualDensity.compact,
            ),
          ),
          Semantics(
            label: 'About the Wellness Guide',
            button: true,
            child: IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: _showInfoDialog,
              tooltip: 'About the Wellness Guide',
            ),
          ),
        ],
      ),
      body: !_initialized
          ? const Center(child: CircularProgressIndicator())
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
                          'The wellness guide works best after you upload a discharge document. '
                          'Please scan or upload your discharge paper first.',
                          style: theme.textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              : Stack(
                  children: [
                    Column(
                      children: [
                        Container(
                          color: theme.colorScheme.surfaceContainerHighest,
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 12,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: List.generate(
                                      _chatManager.chatCount,
                                      (i) {
                                        final isActive =
                                            i == _chatManager.activeChatIndex;
                                        final chatName =
                                            _chatManager.allChats[i]['name'] ??
                                                'Chat ${i + 1}';
                                        return Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 4,
                                          ),
                                          child: GestureDetector(
                                            onLongPress: () {
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
                                      },
                                    ),
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
                            label: 'Structured context loaded',
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                'Structured context loaded',
                                style: theme.textTheme.bodySmall,
                              ),
                            ),
                          ),
                        Expanded(
                          child: ListView.builder(
                            itemCount: _chatManager.activeChat.length,
                            itemBuilder: (context, i) {
                              final msg = _chatManager.activeChat[i];
                              final isUser = msg['role'] == 'user';
                              if (isUser) {
                                return Semantics(
                                  label: 'User message',
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: Container(
                                      margin: const EdgeInsets.symmetric(
                                        vertical: 4,
                                        horizontal: 12,
                                      ),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.primary
                                            .withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(msg['content'] ?? ''),
                                    ),
                                  ),
                                );
                              }
                              return Semantics(
                                label: 'Assistant message',
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: AssistantMessageBubble(
                                    content: msg['content'] ?? '',
                                    onReport: () => _reportMessage(msg),
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
                                  const CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Assistant is typing...',
                                    style: theme.textTheme.bodySmall,
                                  ),
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
                                    enabled: _chatManager
                                        .activeDisclosureAcknowledged,
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
                                  onPressed:
                                      _chatManager.activeDisclosureAcknowledged
                                          ? _sendMessage
                                          : null,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (needsDisclosure)
                      Positioned.fill(
                        child: AiDisclosureBanner(
                          onAcknowledged: () async {
                            await _chatManager.acknowledgeDisclosure();
                            if (mounted) setState(() {});
                          },
                        ),
                      ),
                  ],
                ),
    );
  }
}
