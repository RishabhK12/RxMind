import 'package:flutter/material.dart';
import 'package:csv/csv.dart';
import '../../components/shimmer_card.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../services/database_service.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:lottie/lottie.dart';
import '../../components/parallax_background.dart';

// ...existing code...
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Future<void> _exportDataAsCSV() async {
    final db = await DatabaseService().database;
    final tasks = await db.query('tasks');
    final meds = await db.query('medications');
    final compliance = await db.query('compliance');

    String tasksCsv = const ListToCsvConverter().convert([
      [
        'id',
        'title',
        'description',
        'time',
        'recurrence',
        'completed',
        'created_at'
      ],
      ...tasks.map((t) => [
            t['id'],
            t['title'],
            t['description'],
            t['time'],
            t['recurrence'],
            t['completed'],
            t['created_at']
          ])
    ]);
    String medsCsv = const ListToCsvConverter().convert([
      ['id', 'name', 'description', 'dosage', 'created_at'],
      ...meds.map((m) =>
          [m['id'], m['name'], m['description'], m['dosage'], m['created_at']])
    ]);
    String complianceCsv = const ListToCsvConverter().convert([
      ['id', 'task_id', 'date'],
      ...compliance.map((c) => [c['id'], c['task_id'], c['date']])
    ]);

    String allCsv =
        '-- TASKS --\n$tasksCsv\n\n-- MEDICATIONS --\n$medsCsv\n\n-- COMPLIANCE --\n$complianceCsv';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exported Data (CSV)'),
        content: SingleChildScrollView(child: SelectableText(allCsv)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'))
        ],
      ),
    );
  }

  String? _apiKey;
  final _apiKeyController = TextEditingController();
  // Removed unused fields
  bool notificationsEnabled = true;
  bool darkMode = false;
  String userName = 'User';
  String avatarUrl = '';
  // Removed unused field
  Future<void> _pickAvatar() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? picked = await picker.pickImage(source: ImageSource.gallery);
      if (picked != null) {
        setState(() => avatarUrl = picked.path);
        await _saveProfile();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile picture updated!')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _loadProfile();
    // Removed call to _loadFailedUploads
    _apiKey = dotenv.env['GEMINI_API_KEY'];
    _apiKeyController.text = _apiKey ?? '';
  }

  // Removed unused _failedUploads logic

  // Removed unused method

  Future<void> _loadProfile() async {
    // Simulate loading user profile from DB or prefs
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userName = prefs.getString('userName') ?? 'User';
      avatarUrl = prefs.getString('avatarUrl') ?? '';
      notificationsEnabled = prefs.getBool('notificationsEnabled') ?? true;
      darkMode = prefs.getBool('darkMode') ?? false;
    });
  }

  Future<void> _saveProfile() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userName', userName);
    await prefs.setString('avatarUrl', avatarUrl);
    await prefs.setBool('notificationsEnabled', notificationsEnabled);
    await prefs.setBool('darkMode', darkMode);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings saved!')),
      );
    }
  }

  void _showEditNameDialog() {
    String tempName = userName;
    final controller = TextEditingController(text: userName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Name'),
        content: TextField(
          decoration: const InputDecoration(labelText: 'Name'),
          controller: controller,
          autofocus: true,
          onChanged: (v) => tempName = v,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              setState(() => userName = tempName);
              await _saveProfile();
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Name updated!')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // Removed unused method

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ParallaxBackground(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: const Text('Settings'),
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
          body: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Center(
                child: SizedBox(
                  height: 80,
                  width: 80,
                  child: Lottie.asset(
                    'assets/lottie/gear.json',
                    repeat: true,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Profile with shimmer effect
              Center(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _pickAvatar,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            if (avatarUrl.isNotEmpty)
                              BoxShadow(
                                color: Colors.black
                                    .withAlpha((0.15 * 255).toInt()),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                          ],
                        ),
                        child: avatarUrl.isEmpty
                            ? const ShimmerCard(height: 80, width: 80)
                            : CircleAvatar(
                                radius: 40,
                                backgroundImage: avatarUrl.startsWith('http')
                                    ? NetworkImage(avatarUrl)
                                    : FileImage(File(avatarUrl))
                                        as ImageProvider,
                                child: null,
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(userName, style: theme.textTheme.titleLarge),
                        IconButton(
                          icon: const Icon(Icons.edit, size: 20),
                          onPressed: _showEditNameDialog,
                          tooltip: 'Edit Name',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Export Data (CSV)
              Card(
                margin: const EdgeInsets.only(bottom: 24),
                child: ListTile(
                  leading: const Icon(Icons.download),
                  title: const Text('Export Data (CSV)'),
                  onTap: _exportDataAsCSV,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
