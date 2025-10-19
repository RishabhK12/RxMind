import 'package:flutter/material.dart';
import 'package:rxmind_app/services/discharge_data_manager.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  List<Map<String, dynamic>> _contacts = [];

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

  void _addOrEditContact([int? index]) {
    final contact =
        index != null ? Map<String, dynamic>.from(_contacts[index]) : null;
    final nameController =
        TextEditingController(text: contact?['name'] as String?);
    final phoneController =
        TextEditingController(text: contact?['phone'] as String?);
    final addressController =
        TextEditingController(text: contact?['address'] as String?);
    final notesController =
        TextEditingController(text: contact?['notes'] as String?);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
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
    // Remove any non-digit characters except + at the start
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    final Uri phoneUri = Uri(scheme: 'tel', path: cleanNumber);

    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch phone dialer')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medical Contacts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _addOrEditContact(),
          ),
        ],
      ),
      body: ListView.builder(
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
                      style: const TextStyle(
                        color: Colors.blue,
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
                    color: Colors.green,
                    onPressed: () => _makePhoneCall(contact['phone']),
                  ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _addOrEditContact(index),
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
    );
  }
}
