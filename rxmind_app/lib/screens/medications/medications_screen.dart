import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:rxmind_app/gemini_api_key.dart';
import 'package:rxmind_app/screens/ai/gemini_api_service.dart';
import 'package:rxmind_app/services/discharge_data_manager.dart';

class MedicationsScreen extends StatefulWidget {
  const MedicationsScreen({super.key});

  @override
  State<MedicationsScreen> createState() => _MedicationsScreenState();
}

class _MedicationsScreenState extends State<MedicationsScreen> {
  List<Map<String, dynamic>> _medications = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadMedications();
  }

  Future<void> _loadMedications() async {
    final medications = await DischargeDataManager.loadMedications();
    setState(() {
      _medications = medications;
      _loading = false;
    });
  }

  void _showMedicationInfo(String medicationName) async {
    showDialog(
      context: context,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final geminiService = GeminiApiService(
        apiKey: geminiApiKey,
      );
      final prompt =
          'Provide a brief, easy-to-understand summary for the medication "$medicationName". Include what it is used for, common side effects, and important precautions. Format the response in Markdown with clear headings.';

      final response = await geminiService.sendMessage(prompt);
      final responseText =
          response.isNotEmpty ? response : 'No information available.';

      if (!mounted) return;
      Navigator.pop(context); // Dismiss loading indicator

      // Show in a scrollable dialog with markdown rendering
      showDialog(
        context: context,
        builder: (context) => Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        medicationName,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Flexible(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: MarkdownBody(
                      data: responseText,
                      selectable: true,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Dismiss loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching information: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medications'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _medications.length,
              itemBuilder: (context, index) {
                final med = _medications[index];
                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    title: Text(
                      med['name'] ?? 'Unnamed Medication',
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    subtitle: Text(
                      'Dose: ${med['dose']} - Frequency: ${med['frequency']}',
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    onTap: () => _showMedicationInfo(
                        med['name'] ?? 'Unnamed Medication'),
                  ),
                );
              },
            ),
    );
  }
}
