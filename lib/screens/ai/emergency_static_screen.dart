import 'package:flutter/material.dart';
import 'package:rxmind_app/core/ai/emergency_resources.dart';
import 'package:rxmind_app/core/ai/safety_result.dart';
import 'package:rxmind_app/core/chd/repositories/contact_repository.dart';
import 'package:rxmind_app/core/storage/sqlcipher_database.dart';
import 'package:rxmind_app/screens/ai/emergency_call_tile.dart';

class EmergencyStaticScreen extends StatefulWidget {
  const EmergencyStaticScreen({super.key, required this.category});

  final EmergencyCategory category;

  @override
  State<EmergencyStaticScreen> createState() => _EmergencyStaticScreenState();
}

class _EmergencyStaticScreenState extends State<EmergencyStaticScreen> {
  List<Map<String, dynamic>> _contacts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    try {
      final db = await SecureDatabase.instance();
      final contacts = await ContactRepository(db).getAll();
      if (mounted) {
        setState(() {
          _contacts = contacts;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Semantics(
          header: true,
          child: const Text(EmergencyResources.title),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(EmergencyResources.body, style: theme.textTheme.bodyLarge),
          const SizedBox(height: 24),
          const EmergencyCallTile(
            number: '911',
            label: EmergencyResources.emergency911Label,
          ),
          const EmergencyCallTile(
            number: '988',
            label: EmergencyResources.crisis988Label,
          ),
          const SizedBox(height: 16),
          Text(
            EmergencyResources.savedContactsHeader,
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (_contacts.isEmpty)
            Text(
              'No contacts saved yet. Add care team contacts in Settings.',
              style: theme.textTheme.bodyMedium,
            )
          else
            ..._contacts.map((c) {
              final name = c['name']?.toString() ?? 'Contact';
              final phone = c['phone']?.toString() ?? '';
              return ListTile(
                leading: const Icon(Icons.person_outline),
                title: Text(name),
                subtitle: phone.isNotEmpty ? Text(phone) : null,
              );
            }),
          const SizedBox(height: 24),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(EmergencyResources.returnToChat),
          ),
        ],
      ),
    );
  }
}
