import 'package:flutter/material.dart';
import '../ai/local_ai_service.dart';
import '../../core/ai/local_ai_stub.dart';
import '../../core/widgets/markdown_text.dart';

class GlossaryDetailScreen extends StatefulWidget {
  final String term;
  const GlossaryDetailScreen({super.key, required this.term});

  @override
  State<GlossaryDetailScreen> createState() => _GlossaryDetailScreenState();
}

class _GlossaryDetailScreenState extends State<GlossaryDetailScreen> {
  late final LocalAiService _localAi = LocalAiService();
  String? definition;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchDefinition();
  }

  Future<void> fetchDefinition() async {
    try {
      final response = await _localAi.sendMessage(widget.term);
      setState(() {
        definition = response;
        loading = false;
      });
    } catch (e) {
      setState(() {
        definition = LocalAiStub.unavailableMessage;
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.term),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
      ),
      body: Center(
        child: loading
            ? CircularProgressIndicator(color: theme.colorScheme.primary)
            : SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: MarkdownText(data: definition ?? ''),
                ),
              ),
      ),
    );
  }
}
