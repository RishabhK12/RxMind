import 'package:flutter/material.dart';
import 'package:rxmind_app/services/contacts/native_contact_picker_service.dart';
import 'package:rxmind_app/services/discharge_data_manager.dart';
import 'package:rxmind_app/theme/theme_tokens.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  List<Map<String, dynamic>> _contacts = [];
  final _pickerService = NativeContactPickerService();

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    final contacts = await DischargeDataManager.loadContacts();
    setState(() {
      _contacts = contacts;
    });
  }

  Future<void> _saveContacts() async {
    await DischargeDataManager.saveContacts(_contacts);
  }

  Future<void> _pickFromDevice() async {
    final picked = await _pickerService.pickSingleContact();
    if (!mounted) return;
    if (picked == null) return;
    _addOrEditContact(
      prefilledName: picked.name,
      prefilledPhone: picked.phone,
    );
  }

  void _addOrEditContact({
    int? index,
    String? prefilledName,
    String? prefilledPhone,
  }) {
    final contact =
        index != null ? Map<String, dynamic>.from(_contacts[index]) : null;
    final nameController = TextEditingController(
      text: prefilledName ?? contact?['name'] as String?,
    );
    final phoneController = TextEditingController(
      text: prefilledPhone ?? contact?['phone'] as String?,
    );
    final addressController =
        TextEditingController(text: contact?['address'] as String?);
    final notesController =
        TextEditingController(text: contact?['notes'] as String?);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ThemeTokens.radiusLg),
          ),
          title: Text(index == null ? 'Add Contact' : 'Edit Contact'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Name')),
                TextField(
                    controller: phoneController,
                    decoration: const InputDecoration(labelText: 'Phone')),
                TextField(
                    controller: addressController,
                    decoration: const InputDecoration(labelText: 'Address')),
                TextField(
                    controller: notesController,
                    decoration: const InputDecoration(labelText: 'Notes')),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel')),
            TextButton(
              onPressed: () {
                final newContact = {
                  'name': nameController.text,
                  'phone': phoneController.text,
                  'address': addressController.text,
                  'notes': notesController.text,
                };
                setState(() {
                  if (index == null) {
                    _contacts.add(newContact);
                  } else {
                    _contacts[index] = newContact;
                  }
                });
                _saveContacts();
                Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _deleteContact(int index) {
    setState(() {
      _contacts.removeAt(index);
    });
    _saveContacts();
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    final Uri phoneUri = Uri(scheme: 'tel', path: cleanNumber);

    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      if (mounted) {
        final theme = Theme.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Could not launch phone dialer',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onInverseSurface,
              ),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        title: Text('Medical Contacts', style: theme.textTheme.titleLarge),
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: theme.colorScheme.primary),
            onPressed: () => _addOrEditContact(),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_pickerService.isSupported)
            Padding(
              padding: const EdgeInsets.all(ThemeTokens.spacingMd),
              child: Semantics(
                button: true,
                label: 'Add from device contacts',
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: _pickFromDevice,
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(ThemeTokens.radiusPill),
                      ),
                    ),
                    icon:
                        Icon(Icons.contacts, color: theme.colorScheme.primary),
                    label: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Add from device contacts',
                          style: theme.textTheme.bodyMedium,
                        ),
                        Text(
                          "You'll choose one contact. RxMind cannot access your full contact list.",
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          Expanded(
            child: ListView.builder(
              itemCount: _contacts.length,
              itemBuilder: (context, index) {
                final contact = _contacts[index];
                final hasPhone = contact['phone'] != null &&
                    contact['phone'].toString().isNotEmpty;

                return ListTile(
                  title: Text(contact['name'] ?? 'No Name'),
                  subtitle: hasPhone
                      ? InkWell(
                          onTap: () => _makePhoneCall(contact['phone']),
                          child: Text(
                            contact['phone'],
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.primary,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        )
                      : const Text('No phone number'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (hasPhone)
                        IconButton(
                          icon: const Icon(Icons.phone),
                          color: theme.colorScheme.secondary,
                          onPressed: () => _makePhoneCall(contact['phone']),
                        ),
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _addOrEditContact(index: index),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _deleteContact(index),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
