import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:rxmind_app/main.dart'; // Use RxMindSettings from main
import 'package:rxmind_app/theme/app_theme.dart';
import 'package:rxmind_app/theme/theme_tokens.dart';
import 'package:rxmind_app/screens/settings/contacts_screen.dart';
import 'package:rxmind_app/core/storage/secure_wipe_service.dart';
import 'package:rxmind_app/screens/settings/privacy_terms_screen.dart';
import 'package:rxmind_app/services/discharge_data_manager.dart';
import 'package:rxmind_app/services/pdf_export_service.dart';
import 'package:rxmind_app/screens/pdf/pdf_preview_screen.dart';
import 'package:rxmind_app/services/notification_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rxmind_app/core/permissions/permission_disclosure_store.dart';
import 'package:rxmind_app/screens/permissions/permission_disclosure_dialog.dart';
import 'package:rxmind_app/widgets/rx_card.dart';
import 'package:rxmind_app/widgets/rx_primary_button.dart';
import 'package:rxmind_app/widgets/rx_section_header.dart';

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

  // Notification settings
  bool _notificationsEnabled = true;
  List<int> _selectedNotificationTimes = [
    120,
    30,
    5
  ]; // Default: 2hr, 30min, 5min
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _loadProfileData();
    _loadNotificationSettings();
  }

  Future<void> _loadNotificationSettings() async {
    final enabled = await _notificationService.areNotificationsEnabled();
    final times = await _notificationService.getNotificationTimes();

    if (mounted) {
      setState(() {
        _notificationsEnabled = enabled;
        _selectedNotificationTimes = times;
      });
    }
  }

  Future<void> _loadProfileData() async {
    final data = await DischargeDataManager.loadProfileData();
    if (mounted) {
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

  Widget _sectionLabel(BuildContext context, String title,
      {String? semanticsLabel}) {
    final label = Padding(
      padding: const EdgeInsets.fromLTRB(
        ThemeTokens.spacingMd,
        ThemeTokens.spacingLg,
        ThemeTokens.spacingMd,
        ThemeTokens.spacingSm,
      ),
      child: RxSectionHeader(title: title),
    );
    if (semanticsLabel == null) return label;
    return Semantics(label: semanticsLabel, child: label);
  }

  Widget _groupCard({required List<Widget> children}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: ThemeTokens.spacingMd),
      child: RxCard(
        radius: ThemeTokens.radiusMd,
        padding: EdgeInsets.zero,
        child: Column(children: children),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = RxMindSettings.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        title: Text('Settings', style: theme.textTheme.titleLarge),
        // No leading/back button, navigation is via bottom nav bar
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: ThemeTokens.spacingXl),
        physics: const BouncingScrollPhysics(),
        children: [
          _sectionLabel(context, 'Profile', semanticsLabel: 'Profile section'),
          _groupCard(
            children: [
              ListTile(
                leading: Icon(Icons.person, color: theme.colorScheme.primary),
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
                leading: Icon(Icons.height, color: theme.colorScheme.primary),
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
                leading: Icon(Icons.monitor_weight,
                    color: theme.colorScheme.primary),
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
                leading: Icon(Icons.cake, color: theme.colorScheme.secondary),
                title: const Text('Age'),
                trailing: Text('${_age ?? '--'}'),
                onTap: () async {
                  final val = await _showNumberPicker(
                      context, 'Age', _age ?? 30, 10, 120);
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
                leading:
                    Icon(Icons.transgender, color: theme.colorScheme.primary),
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
                leading: Icon(Icons.bedtime, color: theme.colorScheme.primary),
                title: const Text('Bedtime'),
                trailing: Text(_bedtime?.format(context) ?? '--:--'),
                onTap: () async {
                  final picked = await showTimePicker(
                      context: context,
                      initialTime:
                          _bedtime ?? const TimeOfDay(hour: 22, minute: 0));
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
                leading:
                    Icon(Icons.wb_sunny, color: theme.colorScheme.secondary),
                title: const Text('Wake Time'),
                trailing: Text(_wakeTime?.format(context) ?? '--:--'),
                onTap: () async {
                  final picked = await showTimePicker(
                      context: context,
                      initialTime:
                          _wakeTime ?? const TimeOfDay(hour: 7, minute: 0));
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
            ],
          ),
          _sectionLabel(context, 'Data'),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: ThemeTokens.spacingMd,
              vertical: ThemeTokens.spacingSm,
            ),
            child: RxPrimaryButton(
              label: 'Export Data',
              icon: Icons.download,
              onPressed: _exportData,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: ThemeTokens.spacingMd,
              vertical: ThemeTokens.spacingSm,
            ),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  _showDeleteConfirmation(context);
                },
                icon: Icon(Icons.delete_forever,
                    color: theme.colorScheme.onError),
                label: Text(
                  'Delete All Data',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onError,
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.error,
                  foregroundColor: theme.colorScheme.onError,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(ThemeTokens.radiusPill),
                  ),
                ),
              ),
            ),
          ),
          _sectionLabel(context, 'Medical Contacts'),
          _groupCard(
            children: [
              ListTile(
                leading: Icon(Icons.local_hospital,
                    color: theme.colorScheme.secondary),
                title: const Text('Doctor/Hospital Contacts'),
                trailing: Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                ),
                onTap: () {
                  _showContactsScreen(context);
                },
                subtitle: const Text('Add and manage medical contacts'),
              ),
            ],
          ),
          _sectionLabel(context, 'Theme'),
          _groupCard(
            children: [
              RadioListTile<ThemeMode>(
                title: Text('Light Mode', style: theme.textTheme.bodyMedium),
                value: ThemeMode.light,
                groupValue: settings.themeMode,
                onChanged: (v) => settings.updateTheme(v!),
              ),
              RadioListTile<ThemeMode>(
                title: Text('Dark Mode', style: theme.textTheme.bodyMedium),
                value: ThemeMode.dark,
                groupValue: settings.themeMode,
                onChanged: (v) => settings.updateTheme(v!),
              ),
              RadioListTile<ThemeMode>(
                title:
                    Text('System Default', style: theme.textTheme.bodyMedium),
                value: ThemeMode.system,
                groupValue: settings.themeMode,
                onChanged: (v) => settings.updateTheme(v!),
              ),
              SwitchListTile(
                value: settings.highContrast,
                onChanged: (v) async {
                  if (v) {
                    final confirmed = await _showHighContrastPreview(context);
                    if (confirmed == true && mounted) {
                      settings.updateHighContrast(true);
                    }
                  } else {
                    settings.updateHighContrast(false);
                  }
                },
                title: Text('High-Contrast', style: theme.textTheme.bodyMedium),
                secondary: Semantics(
                  label: 'Toggle high-contrast mode',
                  child: const Icon(Icons.contrast),
                ),
              ),
            ],
          ),
          _sectionLabel(context, 'Notifications'),
          _groupCard(
            children: [
              SwitchListTile(
                value: _notificationsEnabled,
                onChanged: (v) async {
                  if (!v) {
                    // Show warning before disabling
                    final confirm =
                        await _showDisableNotificationsDialog(context);
                    if (confirm != true) return;
                  }

                  // Check system permissions when enabling
                  if (v) {
                    final status = await Permission.notification.status;
                    if (!status.isGranted) {
                      final acked =
                          await PermissionDisclosureStore.isAcknowledged(
                              'notification');
                      if (!acked) {
                        if (!mounted) return;
                        final disclosed = await showPermissionDisclosure(
                          context,
                          PermissionType.notification,
                        );
                        if (!disclosed) return;
                        await PermissionDisclosureStore.setAcknowledged(
                            'notification');
                      }
                      final requested = await _notificationService
                          .checkAndRequestPermissions();
                      if (!requested) {
                        // Show dialog to open settings
                        if (!mounted) return;
                        await _showPermissionDialog(context);
                        return;
                      }
                    }

                    // For Android, also check exact alarm permission
                    final canScheduleExact =
                        await _notificationService.canScheduleExactAlarms();
                    if (!canScheduleExact) {
                      if (!mounted) return;
                      await _showExactAlarmPermissionDialog(context);
                      // Continue anyway - inexact alarms will be used
                    }
                  }

                  setState(() => _notificationsEnabled = v);
                  await _notificationService.setNotificationsEnabled(v);

                  // Reschedule notifications if enabled
                  if (v) {
                    final tasks = await DischargeDataManager.loadTasks();
                    await _notificationService
                        .scheduleNotificationsForTasks(tasks);
                  }
                },
                title: Text('Enable Notifications',
                    style: theme.textTheme.bodyMedium),
                subtitle: const Text('Receive reminders for upcoming tasks'),
                secondary: Icon(Icons.notifications_active,
                    color: theme.colorScheme.primary),
              ),
              if (_notificationsEnabled)
                ListTile(
                  leading:
                      Icon(Icons.access_time, color: theme.colorScheme.primary),
                  title: const Text('Notification Times'),
                  subtitle: Text(
                      _formatNotificationTimes(_selectedNotificationTimes)),
                  trailing: Icon(Icons.edit,
                      size: 20, color: theme.colorScheme.primary),
                  onTap: () => _showNotificationTimesDialog(context),
                ),
            ],
          ),
          _sectionLabel(context, 'Accessibility'),
          _groupCard(
            children: [
              ListTile(
                leading: Semantics(
                  label: 'Text size slider',
                  child:
                      Icon(Icons.format_size, color: theme.colorScheme.primary),
                ),
                title: Text('Text Size', style: theme.textTheme.bodyMedium),
                subtitle: Text(
                  '${(settings.textScale * 100).round()}%',
                  style: theme.textTheme.bodySmall,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: ThemeTokens.spacingMd),
                child: Slider(
                  value: settings.textScale.clamp(1.0, 2.0),
                  min: 1.0,
                  max: 2.0,
                  divisions: 10,
                  label: '${(settings.textScale * 100).round()}%',
                  onChanged: (v) => settings.updateTextScale(v),
                ),
              ),
              // Screen reader mode is a placeholder; real support is via OS accessibility
              SwitchListTile(
                value: _screenReader,
                onChanged: (v) => setState(() => _screenReader = v),
                title: Text('Screen Reader Mode',
                    style: theme.textTheme.bodyMedium),
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
                title:
                    Text('Reduced Motion', style: theme.textTheme.bodyMedium),
                secondary: Semantics(
                  label: 'Toggle reduced motion for accessibility',
                  child: const Icon(Icons.motion_photos_off),
                ),
              ),
            ],
          ),
          _sectionLabel(context, 'About'),
          _groupCard(
            children: [
              ListTile(
                leading: Icon(
                  Icons.info_outline,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                title: const Text('Version'),
                subtitle: const Text('rxmind v1.0.0'),
              ),
              ListTile(
                leading:
                    Icon(Icons.privacy_tip, color: theme.colorScheme.primary),
                title: const Text('Privacy'),
                subtitle: const Text(
                    'All data is stored locally and never leaves your device.'),
                trailing: Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                ),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const PrivacyTermsScreen(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.people, color: theme.colorScheme.secondary),
                title: const Text('Credits'),
                subtitle: const Text('Created by the rxmind team.'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<bool?> _showDisableNotificationsDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Disable Notifications?'),
        content: const Text(
          'You will no longer receive reminders for your tasks. '
          'You can re-enable notifications anytime from settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Disable',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showPermissionDialog(BuildContext context) {
    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Notification Permission Required'),
        content: const Text(
          'rxmind needs notification permission to remind you about upcoming tasks. '
          'Please enable notifications in your device settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _notificationService.openNotificationSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  Future<void> _showExactAlarmPermissionDialog(BuildContext context) {
    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Exact Alarm Permission'),
        content: const Text(
          'For more precise notification timing, rxmind needs permission to schedule exact alarms. '
          'Without this permission, notifications may be slightly delayed.\n\n'
          'You can grant this permission in your device settings under:\n'
          'Settings → Apps → rxmind → Alarms & reminders',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Use Inexact Timing'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _notificationService.openNotificationSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  String _formatNotificationTimes(List<int> times) {
    if (times.isEmpty) return 'None';

    final formatted = times.map((minutes) {
      if (minutes < 60) {
        return '${minutes}min';
      } else {
        final hours = minutes ~/ 60;
        final mins = minutes % 60;
        if (mins == 0) {
          return '${hours}h';
        }
        return '${hours}h ${mins}min';
      }
    }).toList();

    return formatted.join(', ');
  }

  Future<void> _showNotificationTimesDialog(BuildContext context) async {
    // Available preset times (in minutes)
    final presetTimes = [
      {'value': 5, 'label': '5 minutes before'},
      {'value': 10, 'label': '10 minutes before'},
      {'value': 15, 'label': '15 minutes before'},
      {'value': 30, 'label': '30 minutes before'},
      {'value': 60, 'label': '1 hour before'},
      {'value': 120, 'label': '2 hours before'},
      {'value': 180, 'label': '3 hours before'},
      {'value': 360, 'label': '6 hours before'},
      {'value': 720, 'label': '12 hours before'},
      {'value': 1440, 'label': '1 day before'},
    ];

    final selectedTimes = List<int>.from(_selectedNotificationTimes);
    int? customTime;

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Notification Times'),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Select when to receive notifications:',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 16),
                      ...presetTimes.map((preset) {
                        final value = preset['value'] as int;
                        final label = preset['label'] as String;
                        return CheckboxListTile(
                          title: Text(label),
                          value: selectedTimes.contains(value),
                          onChanged: (checked) {
                            setDialogState(() {
                              if (checked == true) {
                                selectedTimes.add(value);
                                selectedTimes.sort((a, b) =>
                                    b.compareTo(a)); // Sort descending
                              } else {
                                selectedTimes.remove(value);
                              }
                            });
                          },
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                        );
                      }),
                      const Divider(height: 32),
                      const Text(
                        'Custom time:',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              decoration: const InputDecoration(
                                labelText: 'Minutes before',
                                hintText: 'e.g., 45',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              keyboardType: TextInputType.number,
                              onChanged: (value) {
                                customTime = int.tryParse(value);
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () {
                              if (customTime != null && customTime! > 0) {
                                setDialogState(() {
                                  if (!selectedTimes.contains(customTime)) {
                                    selectedTimes.add(customTime!);
                                    selectedTimes
                                        .sort((a, b) => b.compareTo(a));
                                  }
                                  customTime = null;
                                });
                              }
                            },
                            child: const Text('Add'),
                          ),
                        ],
                      ),
                      if (selectedTimes.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        const Text(
                          'Selected times:',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: selectedTimes.map((time) {
                            return Chip(
                              label: Text(_formatSingleTime(time)),
                              deleteIcon: const Icon(Icons.close, size: 18),
                              onDeleted: () {
                                setDialogState(() {
                                  selectedTimes.remove(time);
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    setState(() {
                      _selectedNotificationTimes = selectedTimes;
                    });
                    await _notificationService
                        .setNotificationTimes(selectedTimes);

                    // Reschedule all task notifications with new times
                    final tasks = await DischargeDataManager.loadTasks();
                    await _notificationService
                        .scheduleNotificationsForTasks(tasks);

                    if (!mounted) return;
                    Navigator.pop(ctx);
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _formatSingleTime(int minutes) {
    if (minutes < 60) {
      return '$minutes min';
    } else if (minutes < 1440) {
      final hours = minutes ~/ 60;
      final mins = minutes % 60;
      if (mins == 0) {
        return '$hours hour${hours == 1 ? '' : 's'}';
      }
      return '$hours hour${hours == 1 ? '' : 's'} $mins min';
    } else {
      final days = minutes ~/ 1440;
      return '$days day${days == 1 ? '' : 's'}';
    }
  }

  void _showContactsScreen(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ContactsScreen(),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    final controller = TextEditingController();
    String? liveMessage;

    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final canDelete = controller.text == 'DELETE';
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(ThemeTokens.radiusLg),
              ),
              title: const Text('Confirm Deletion'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Semantics(
                    liveRegion: true,
                    child: Text(liveMessage ?? ''),
                  ),
                  const Text(
                    'This permanently erases all medications, tasks, documents, '
                    'and profile data from this device. Type DELETE to confirm.',
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller,
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: 'Type DELETE',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => setDialogState(() {}),
                  ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
                TextButton(
                  child: Text(
                    'Delete All Data',
                    style: TextStyle(
                      color: canDelete
                          ? Theme.of(context).colorScheme.error
                          : Theme.of(context).disabledColor,
                    ),
                  ),
                  onPressed: canDelete
                      ? () async {
                          setDialogState(
                            () =>
                                liveMessage = 'Erasing all data, please wait.',
                          );
                          await SecureWipeService.wipeAll();
                          if (!mounted) return;
                          setDialogState(
                            () => liveMessage = 'All data erased successfully.',
                          );
                          Navigator.of(ctx).pop();
                          Navigator.of(context).pushNamedAndRemoveUntil(
                            '/splash',
                            (Route<dynamic> route) => false,
                          );
                        }
                      : null,
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<bool?> _showHighContrastPreview(BuildContext context) async {
    final completer = Completer<bool?>();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        Future.delayed(const Duration(seconds: 3), () {
          if (ctx.mounted && !completer.isCompleted) {
            Navigator.of(ctx).pop(true);
            completer.complete(true);
          }
        });
        return AlertDialog(
          title: const Text('High-Contrast Preview'),
          content: Theme(
            data: AppTheme.highContrastTheme,
            child: Builder(
              builder: (previewContext) {
                final previewTheme = Theme.of(previewContext);
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Sample card',
                          style: previewTheme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Body text preview with high contrast colors.',
                          style: previewTheme.textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: () {},
                          child: const Text('Sample button'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (!completer.isCompleted) completer.complete(false);
                Navigator.of(ctx).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (!completer.isCompleted) completer.complete(true);
                Navigator.of(ctx).pop();
              },
              child: const Text('Apply'),
            ),
          ],
        );
      },
    );
    return completer.future;
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

  Future<void> _exportData() async {
    final theme = Theme.of(context);
    String exportStatus = 'Starting PDF export';
    try {
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Semantics(
          liveRegion: true,
          label: exportStatus,
          child: const Center(child: CircularProgressIndicator()),
        ),
      );

      exportStatus = 'Generating health report PDF';
      final pdfFile = await PdfExportService.generateHealthReport();

      if (!mounted) return;
      Navigator.of(context).pop();

      exportStatus = 'PDF export complete';
      if (!mounted) return;
      SemanticsService.announce(exportStatus, TextDirection.ltr);

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => PdfPreviewScreen(
            pdfFile: pdfFile,
            exportAnnouncement: exportStatus,
          ),
        ),
      );
    } catch (e) {
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      exportStatus = 'PDF export failed';
      SemanticsService.announce('$exportStatus: $e', TextDirection.ltr);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error exporting PDF: $e',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onError,
            ),
          ),
          backgroundColor: theme.colorScheme.error,
        ),
      );
    }
  }
}
