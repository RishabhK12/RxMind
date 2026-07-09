import 'package:flutter/material.dart';
import 'package:rxmind_app/theme/theme_tokens.dart';
import 'package:rxmind_app/widgets/rx_primary_button.dart';
import 'package:rxmind_app/widgets/rx_secondary_button.dart';

enum PermissionType { camera, photoLibrary, notification }

class PermissionDisclosureContent {
  const PermissionDisclosureContent({
    required this.title,
    required this.dataCollected,
    required this.storage,
    required this.benefit,
  });

  final String title;
  final String dataCollected;
  final String storage;
  final String benefit;
}

PermissionDisclosureContent _contentFor(PermissionType type) {
  switch (type) {
    case PermissionType.camera:
      return const PermissionDisclosureContent(
        title: 'Camera Access',
        dataCollected:
            'Photos of discharge documents you choose to capture with the camera.',
        storage:
            'Images are processed on your device only. Raw frames are not saved to storage.',
        benefit:
            'Lets you photograph discharge paperwork for on-device text extraction.',
      );
    case PermissionType.photoLibrary:
      return const PermissionDisclosureContent(
        title: 'Photo Library Access',
        dataCollected:
            'Only the specific image or PDF file you select from your library.',
        storage:
            'Selected files are processed locally on your device. Nothing is uploaded.',
        benefit:
            'Lets you choose an existing document for on-device text extraction.',
      );
    case PermissionType.notification:
      return const PermissionDisclosureContent(
        title: 'Notification Access',
        dataCollected:
            'No health data is sent off-device. Reminders use neutral copy only.',
        storage:
            'Reminder schedules are stored in your encrypted on-device database.',
        benefit: 'Sends local wellness reminders for entries you schedule.',
      );
  }
}

/// Shows a blocking disclosure modal before invoking [permission_handler].
Future<bool> showPermissionDisclosure(
  BuildContext context,
  PermissionType type,
) async {
  final content = _contentFor(type);
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      final theme = Theme.of(ctx);
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ThemeTokens.radiusLg),
        ),
        title: Text(content.title, style: theme.textTheme.titleLarge),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('What we access', style: theme.textTheme.titleSmall),
              const SizedBox(height: 4),
              Text(content.dataCollected, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 12),
              Text('How it is stored', style: theme.textTheme.titleSmall),
              const SizedBox(height: 4),
              Text(content.storage, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 12),
              Text('Why you benefit', style: theme.textTheme.titleSmall),
              const SizedBox(height: 4),
              Text(content.benefit, style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
        actionsAlignment: MainAxisAlignment.end,
        actions: [
          RxSecondaryButton(
            label: 'Cancel',
            expand: false,
            onPressed: () => Navigator.of(ctx).pop(false),
          ),
          const SizedBox(width: ThemeTokens.spacingSm),
          RxPrimaryButton(
            label: 'Continue',
            expand: false,
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      );
    },
  );
  return result ?? false;
}
