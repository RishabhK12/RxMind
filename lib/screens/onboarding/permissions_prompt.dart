import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import 'package:rxmind_app/theme/theme_tokens.dart';
import 'package:rxmind_app/widgets/rx_card.dart';
import 'package:rxmind_app/widgets/rx_primary_button.dart';
import 'package:rxmind_app/widgets/rx_secondary_button.dart';

class PermissionsPromptScreen extends StatefulWidget {
  const PermissionsPromptScreen({super.key});

  @override
  State<PermissionsPromptScreen> createState() =>
      _PermissionsPromptScreenState();
}

class _PermissionsPromptScreenState extends State<PermissionsPromptScreen>
    with SingleTickerProviderStateMixin {
  bool _requesting = false;
  bool _animStarted = false;
  late final AnimationController _controller;
  late final Animation<double> _scaleAnim;

  Future<void> _requestPermissions() async {
    setState(() => _requesting = true);

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
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_animStarted) return;
    _animStarted = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1.0;
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    final card = RxCard(
      padding: const EdgeInsets.all(ThemeTokens.spacingLg),
      radius: ThemeTokens.radiusLg,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.lock_outline,
            size: 48,
            color: theme.colorScheme.primary,
            semanticLabel: 'Secure permissions',
          ),
          const SizedBox(height: ThemeTokens.spacingMd),
          Text(
            'One-Time Permissions',
            style: theme.textTheme.titleLarge?.copyWith(fontSize: 24),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'We need access to your camera and files to scan your discharge documents—all processing stays on this device.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
            maxLines: 4,
          ),
          const SizedBox(height: ThemeTokens.spacingLg),
          Row(
            children: [
              Expanded(
                child: RxSecondaryButton(
                  label: 'Skip',
                  onPressed: _requesting ? null : _skip,
                  expand: true,
                ),
              ),
              const SizedBox(width: ThemeTokens.spacingMd),
              Expanded(
                child: RxPrimaryButton(
                  label: 'Allow',
                  onPressed: _requesting ? null : _requestPermissions,
                  expand: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: reduceMotion
                  ? card
                  : ScaleTransition(
                      scale: _scaleAnim,
                      child: card,
                    ),
            ),
            if (_requesting)
              Positioned.fill(
                child: Container(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
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
