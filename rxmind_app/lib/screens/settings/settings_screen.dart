import 'package:flutter/material.dart';
import '../../main.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:rxmind_app/services/discharge_data_manager.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _screenReader = false; // Placeholder, not implemented
  String? _name;
  int? _height;
  int? _weight;
  int? _age;
  String? _sex;
  TimeOfDay? _bedtime;
  TimeOfDay? _wakeTime;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final data = await DischargeDataManager.loadProfileData();
    setState(() {
      _name = data['name'];
      _height = data['height'];
      _weight = data['weight'];
      _age = data['age'];
      _sex = data['sex'];
      if (data['bedtime'] != null) {
        final parts = (data['bedtime'] as String).split(':');
        _bedtime =
            TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      }
      if (data['wakeTime'] != null) {
        final parts = (data['wakeTime'] as String).split(':');
        _wakeTime =
            TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      }
    });
  }

  Future<void> _saveProfileData() async {
    await DischargeDataManager.saveProfileData(
      name: _name,
      height: _height,
      weight: _weight,
      age: _age,
      sex: _sex,
      bedtime:
          _bedtime != null ? '${_bedtime!.hour}:${_bedtime!.minute}' : null,
      wakeTime:
          _wakeTime != null ? '${_wakeTime!.hour}:${_wakeTime!.minute}' : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = RxMindSettings.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 1,
        title: Text('Settings', style: theme.textTheme.titleLarge),
        // No leading/back button, navigation is via bottom nav bar
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        physics: const BouncingScrollPhysics(),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Semantics(
              label: 'Profile section',
              child: Text('Profile',
                  style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface
                          .withAlpha((0.6 * 255).toInt()))),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Name'),
            trailing: Text(_name ?? 'Not Set'),
            onTap: () async {
              final newName = await _showTextPicker(context, 'Name', _name);
              if (newName != null) {
                setState(() => _name = newName);
                await _saveProfileData();
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.height),
            title: const Text('Height'),
            trailing: Text('${_height ?? '--'} cm'),
            onTap: () async {
              final val = await _showNumberPicker(
                  context, 'Height (cm)', _height ?? 170, 100, 220);
              if (val != null) {
                setState(() => _height = val);
                await _saveProfileData();
              }
            },
            subtitle: Semantics(
              label: 'Tap to set height in centimeters',
              child: const SizedBox.shrink(),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.monitor_weight),
            title: const Text('Weight'),
            trailing: Text('${_weight ?? '--'} kg'),
            onTap: () async {
              final val = await _showNumberPicker(
                  context, 'Weight (kg)', _weight ?? 70, 30, 200);
              if (val != null) {
                setState(() => _weight = val);
                await _saveProfileData();
              }
            },
            subtitle: Semantics(
              label: 'Tap to set weight in kilograms',
              child: const SizedBox.shrink(),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.cake),
            title: const Text('Age'),
            trailing: Text('${_age ?? '--'}'),
            onTap: () async {
              final val =
                  await _showNumberPicker(context, 'Age', _age ?? 30, 10, 120);
              if (val != null) {
                setState(() => _age = val);
                await _saveProfileData();
              }
            },
            subtitle: Semantics(
              label: 'Tap to set age in years',
              child: const SizedBox.shrink(),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.transgender),
            title: const Text('Biological Sex'),
            trailing: Text(_sex ?? '--'),
            onTap: () async {
              final val = await showDialog<String>(
                context: context,
                builder: (ctx) => SimpleDialog(
                  title: const Text('Select Sex'),
                  children: [
                    SimpleDialogOption(
                        child: const Text('Male'),
                        onPressed: () => Navigator.pop(ctx, 'Male')),
                    SimpleDialogOption(
                        child: const Text('Female'),
                        onPressed: () => Navigator.pop(ctx, 'Female')),
                    SimpleDialogOption(
                        child: const Text('Other'),
                        onPressed: () => Navigator.pop(ctx, 'Other')),
                  ],
                ),
              );
              if (val != null) {
                setState(() => _sex = val);
                await _saveProfileData();
              }
            },
            subtitle: Semantics(
              label: 'Tap to set biological sex',
              child: const SizedBox.shrink(),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.bedtime),
            title: const Text('Bedtime'),
            trailing: Text(_bedtime?.format(context) ?? '--:--'),
            onTap: () async {
              final picked = await showTimePicker(
                  context: context,
                  initialTime: _bedtime ?? TimeOfDay(hour: 22, minute: 0));
              if (picked != null) {
                setState(() => _bedtime = picked);
                await _saveProfileData();
              }
            },
            subtitle: Semantics(
              label: 'Tap to set bedtime',
              child: const SizedBox.shrink(),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.wb_sunny),
            title: const Text('Wake Time'),
            trailing: Text(_wakeTime?.format(context) ?? '--:--'),
            onTap: () async {
              final picked = await showTimePicker(
                  context: context,
                  initialTime: _wakeTime ?? TimeOfDay(hour: 7, minute: 0));
              if (picked != null) {
                setState(() => _wakeTime = picked);
                await _saveProfileData();
              }
            },
            subtitle: Semantics(
              label: 'Tap to set wake time',
              child: const SizedBox.shrink(),
            ),
          ),
          Divider(height: 32, color: theme.colorScheme.surfaceContainerHighest),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Text('Data',
                style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface.withOpacity(0.6))),
          ),
          ListTile(
            leading: Icon(Icons.download, color: theme.colorScheme.primary),
            title: const Text('Export Data'),
            onTap: () async {
              // Export logic: gather all secure storage and database, zip, and save
              final storage = FlutterSecureStorage();
              final allData = await storage.readAll();
              // Export database file if exists
              String? dbPath;
              try {
                dbPath = await getDatabasesPath();
                dbPath = join(dbPath, 'rxmind.db');
              } catch (_) {}
              final archive = Archive();
              archive.addFile(ArchiveFile('secure_storage.json',
                  allData.toString().length, allData.toString().codeUnits));
              if (dbPath != null && await File(dbPath).exists()) {
                final dbBytes = await File(dbPath).readAsBytes();
                archive
                    .addFile(ArchiveFile('rxmind.db', dbBytes.length, dbBytes));
              }
              final zipData = ZipEncoder().encode(archive) ?? [];
              final output = await FilePicker.platform.saveFile(
                  dialogTitle: 'Export RxMind Data',
                  fileName: 'rxmind_export.zip');
              if (!mounted) return;
              if (output != null) {
                await File(output).writeAsBytes(zipData);
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Export successful!')));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Export cancelled.')));
              }
            },
            subtitle: Semantics(
              label: 'Export all your data as a backup zip file',
              child: const SizedBox.shrink(),
            ),
          ),
          ListTile(
            leading: Icon(Icons.delete_forever, color: theme.colorScheme.error),
            title: const Text('Delete All Data'),
            onTap: () {
              _showDeleteConfirmation(context);
            },
            subtitle: Semantics(
              label: 'Delete all your data from this device',
              child: const SizedBox.shrink(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Text('Theme',
                style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface.withOpacity(0.6))),
          ),
          ListTile(
            title: Text('Light Mode', style: theme.textTheme.bodyMedium),
            leading: Radio<ThemeMode>(
              value: ThemeMode.light,
              groupValue: settings.themeMode,
              onChanged: (v) => settings.updateTheme(v!),
            ),
            onTap: () => settings.updateTheme(ThemeMode.light),
          ),
          ListTile(
            title: Text('Dark Mode', style: theme.textTheme.bodyMedium),
            leading: Radio<ThemeMode>(
              value: ThemeMode.dark,
              groupValue: settings.themeMode,
              onChanged: (v) => settings.updateTheme(v!),
            ),
            onTap: () => settings.updateTheme(ThemeMode.dark),
          ),
          ListTile(
            title: Text('System Default', style: theme.textTheme.bodyMedium),
            leading: Radio<ThemeMode>(
              value: ThemeMode.system,
              groupValue: settings.themeMode,
              onChanged: (v) => settings.updateTheme(v!),
            ),
            onTap: () => settings.updateTheme(ThemeMode.system),
          ),
          SwitchListTile(
            value: settings.highContrast,
            onChanged: (v) {
              settings.updateHighContrast(v);
            },
            title: Text('High-Contrast', style: theme.textTheme.bodyMedium),
            secondary: Semantics(
              label: 'Toggle high-contrast mode',
              child: const Icon(Icons.contrast),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Text(
              'Accessibility',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color:
                    theme.colorScheme.onSurface.withAlpha((0.6 * 255).toInt()),
              ),
            ),
          ),
          SwitchListTile(
            value: settings.textScale > 1.1,
            onChanged: (v) {
              settings.updateTextScale(v ? 1.3 : 1.0);
            },
            title: Text('Large Text', style: theme.textTheme.bodyMedium),
            secondary: Semantics(
              label: 'Toggle large text for better readability',
              child: const Icon(Icons.format_size),
            ),
          ),
          // Screen reader mode is a placeholder; real support is via OS accessibility
          SwitchListTile(
            value: _screenReader,
            onChanged: (v) => setState(() => _screenReader = v),
            title:
                Text('Screen Reader Mode', style: theme.textTheme.bodyMedium),
            secondary: Semantics(
              label: 'Toggle screen reader mode for accessibility',
              child: const Icon(Icons.record_voice_over),
            ),
          ),
          SwitchListTile(
            value: settings.reducedMotion,
            onChanged: (v) {
              settings.updateReducedMotion(v);
            },
            title: Text('Reduced Motion', style: theme.textTheme.bodyMedium),
            secondary: Semantics(
              label: 'Toggle reduced motion for accessibility',
              child: const Icon(Icons.motion_photos_off),
            ),
          ),
          Divider(height: 32, color: theme.colorScheme.surfaceContainerHighest),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Text('About',
                style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface.withOpacity(0.6))),
          ),
          ListTile(
            leading: Icon(Icons.info_outline,
                color:
                    theme.colorScheme.onSurface.withAlpha((0.6 * 255).toInt())),
            title: const Text('Version'),
            subtitle: const Text('RxMind v1.0.0'),
          ),
          ListTile(
            leading: Icon(Icons.privacy_tip, color: theme.colorScheme.primary),
            title: const Text('Privacy'),
            subtitle: const Text(
                'All data is stored locally and never leaves your device.'),
          ),
          ListTile(
            leading: Icon(Icons.people, color: theme.colorScheme.secondary),
            title: const Text('Credits'),
            subtitle: const Text('Created by the RxMind team.'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: const Text(
              'Are you sure you want to delete all your data? This action cannot be undone.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(ctx).pop();
              },
            ),
            TextButton(
              child: Text('Delete',
                  style: TextStyle(color: Theme.of(context).colorScheme.error)),
              onPressed: () async {
                await DischargeDataManager.clearDischargeData();
                Navigator.of(ctx).pop(); // Close the dialog
                // Check if widget is still mounted before using BuildContext
                if (!mounted) return;
                // Navigate to a fresh start, e.g., the splash screen
                Navigator.of(context).pushNamedAndRemoveUntil(
                    '/splash', (Route<dynamic> route) => false);
              },
            ),
          ],
        );
      },
    );
  }

  Future<int?> _showNumberPicker(BuildContext context, String title,
      int initialValue, int min, int max) async {
    int temp = initialValue;
    return showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          height: 180,
          width: 120,
          child: ListWheelScrollView.useDelegate(
            itemExtent: 40,
            diameterRatio: 1.2,
            physics: const FixedExtentScrollPhysics(),
            onSelectedItemChanged: (i) => temp = min + i,
            childDelegate: ListWheelChildBuilderDelegate(
              childCount: max - min + 1,
              builder: (ctx, i) => Center(
                child: Text('${min + i}', style: const TextStyle(fontSize: 20)),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, temp),
              child: const Text('OK')),
        ],
      ),
    );
  }

  Future<String?> _showTextPicker(
      BuildContext context, String title, String? initialValue) {
    final controller = TextEditingController(text: initialValue);
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                Navigator.pop(ctx, controller.text);
              }
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
