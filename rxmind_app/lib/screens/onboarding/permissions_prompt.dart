import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';

class PermissionsPromptScreen extends StatefulWidget {
  const PermissionsPromptScreen({super.key});

  @override
  State<PermissionsPromptScreen> createState() =>
      _PermissionsPromptScreenState();
}

class _PermissionsPromptScreenState extends State<PermissionsPromptScreen>
    with SingleTickerProviderStateMixin {
  bool _requesting = false;
  late final AnimationController _controller;
  late final Animation<double> _scaleAnim;

  Future<void> _requestPermissions() async {
    setState(() => _requesting = true);

    // First try requesting each permission individually
    final cameraStatus = await Permission.camera.request();
    final storageStatus = await Permission.storage.request();

    if (!mounted) return;

    // Check if we have all permissions
    if (cameraStatus.isGranted && storageStatus.isGranted) {
      setState(() => _requesting = false);
      Navigator.pushReplacementNamed(context, '/onboardingProfile');
      return;
    }

    // If permissions aren't granted, open app settings
    if (!cameraStatus.isGranted || !storageStatus.isGranted) {
      // Show message about which permissions are needed
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Please enable both Camera and Storage permissions in settings'),
          duration: Duration(seconds: 3),
        ),
      );

      // Open app settings directly
      await openAppSettings();
    }

    // Check permissions again after user returns from settings
    if (!mounted) return;
    setState(() => _requesting = false);

    // Do a final check of permissions status
    final finalCameraStatus = await Permission.camera.status;
    final finalStorageStatus = await Permission.storage.status;

    if (finalCameraStatus.isGranted && finalStorageStatus.isGranted) {
      Navigator.pushReplacementNamed(context, '/onboardingProfile');
    } else {
      // Show more detailed instructions if user still hasn't granted permissions
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Please enable both Camera and Storage permissions to continue'),
          duration: Duration(seconds: 4),
        ),
      );
    }
  }

  void _skip() {
    Navigator.pushReplacementNamed(context, '/onboardingProfile');
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _scaleAnim = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Center(
        child: Stack(
          children: [
            ScaleTransition(
              scale: _scaleAnim,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lock_outline,
                        size: 48,
                        color: theme.colorScheme.primary,
                        semanticLabel: 'Secure permissions'),
                    const SizedBox(height: 16),
                    Text(
                      'One-Time Permissions',
                      style: theme.textTheme.titleLarge?.copyWith(fontSize: 24),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'We need access to your camera and files to scan your discharge documents—all processing stays on this device.',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: const Color(0xFF616161),
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 4,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: _requesting ? null : _skip,
                          style: TextButton.styleFrom(
                            foregroundColor: theme.colorScheme.primary,
                          ),
                          child: const Text('Skip'),
                        ),
                        ElevatedButton(
                          onPressed: _requesting ? null : _requestPermissions,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: _requesting
                                ? theme.colorScheme.primary
                                : Colors.white,
                            disabledBackgroundColor: Colors.white,
                            disabledForegroundColor: theme.colorScheme.primary,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 32, vertical: 12),
                          ),
                          child: Text(
                            'Allow',
                            style: TextStyle(
                              color: _requesting
                                  ? theme.colorScheme.primary
                                  : Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (_requesting)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.2),
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
