import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({Key? key}) : super(key: key);

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _conditionsController = TextEditingController();
  bool _saving = false;

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final storage = FlutterSecureStorage();
    await storage.write(key: 'name', value: _nameController.text.trim());
    await storage.write(key: 'age', value: _ageController.text.trim());
    await storage.write(
        key: 'conditions', value: _conditionsController.text.trim());
    await storage.write(key: 'profileComplete', value: 'true');
    setState(() => _saving = false);
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/homeDashboard');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _conditionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 1,
        leading: IconButton(
          icon: Icon(Icons.arrow_back,
              color: theme.colorScheme.onSurface, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Set Up Your Profile',
          style: theme.textTheme.titleLarge,
        ),
      ),
      body: AnimatedScale(
        scale: _saving ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 4,
                  child: TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      prefixIcon:
                          Icon(Icons.person, color: theme.colorScheme.primary),
                      hintText: 'Name',
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(16),
                    ),
                    style: theme.textTheme.bodyLarge,
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Name required' : null,
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 4,
                  child: TextFormField(
                    controller: _ageController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      prefixIcon:
                          Icon(Icons.cake, color: theme.colorScheme.secondary),
                      hintText: 'Age',
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(16),
                    ),
                    style: theme.textTheme.bodyLarge,
                    validator: (v) {
                      final age = int.tryParse(v ?? '');
                      if (age == null || age < 0 || age > 120)
                        return 'Enter valid age';
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 4,
                  child: TextFormField(
                    controller: _conditionsController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.health_and_safety,
                          color: theme.colorScheme.primary),
                      hintText: 'Health Conditions (optional)',
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(16),
                    ),
                    style: theme.textTheme.bodyLarge,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.lock,
                        size: 20,
                        color: theme.colorScheme.onSurface.withOpacity(0.5)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'All information is encrypted and stored only on this device.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                            color:
                                theme.colorScheme.onSurface.withOpacity(0.6)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: AnimatedScale(
        scale: _saving ? 0.9 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: FloatingActionButton(
          backgroundColor: theme.colorScheme.secondary,
          onPressed: _saving ? null : _saveProfile,
          child: _saving
              ? const CircularProgressIndicator(color: Colors.white)
              : const Icon(Icons.check, color: Colors.white, size: 28),
        ),
      ),
    );
  }
}
