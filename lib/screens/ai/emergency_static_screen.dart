import 'package:flutter/material.dart';
import 'package:rxmind_app/core/ai/emergency_resources.dart';
import 'package:rxmind_app/core/ai/safety_result.dart';
import 'package:rxmind_app/core/chd/repositories/contact_repository.dart';
import 'package:rxmind_app/core/storage/sqlcipher_database.dart';
import 'package:rxmind_app/screens/ai/emergency_call_tile.dart';
import 'package:rxmind_app/theme/theme_tokens.dart';

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
    final scheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        backgroundColor: scheme.error,
        foregroundColor: scheme.onError,
        iconTheme: IconThemeData(color: scheme.onError),
        title: Semantics(
          header: true,
          child: Text(
            EmergencyResources.title,
            style: theme.textTheme.titleLarge?.copyWith(
              color: scheme.onError,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(ThemeTokens.spacingLg),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(ThemeTokens.spacingMd),
            decoration: BoxDecoration(
              color: scheme.error.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(ThemeTokens.radiusSm),
              border: Border.all(color: scheme.error, width: 1.5),
            ),
            child: Text(
              EmergencyResources.body,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: scheme.onSurface,
                fontWeight: FontWeight.w600,
                height: 1.45,
              ),
            ),
          ),
          const SizedBox(height: ThemeTokens.spacingLg),
          const EmergencyCallTile(
            number: '911',
            label: EmergencyResources.emergency911Label,
          ),
          const EmergencyCallTile(
            number: '988',
            label: EmergencyResources.crisis988Label,
          ),
          const SizedBox(height: ThemeTokens.spacingMd),
          Text(
            EmergencyResources.savedContactsHeader,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: ThemeTokens.spacingSm),
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
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  Icons.person_outline,
                  color: scheme.onSurface,
                ),
                title: Text(name),
                subtitle: phone.isNotEmpty ? Text(phone) : null,
              );
            }),
          const SizedBox(height: ThemeTokens.spacingLg),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(EmergencyResources.returnToChat),
          ),
        ],
      ),
    );
  }
}
