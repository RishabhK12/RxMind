import 'package:flutter/material.dart';
import 'package:rxmind_app/theme/theme_tokens.dart';

/// Lightweight dashboard chrome for theme golden snapshots.
class DashboardThemeHarness extends StatelessWidget {
  const DashboardThemeHarness({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ext = Theme.of(context).extension<RxMindThemeExtension>();
    final linkColor = ext?.link ?? theme.colorScheme.primary;
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Welcome back', style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          Text('Your recovery overview', style: theme.textTheme.bodyMedium),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              title: const Text('Wellness task'),
              subtitle: const Text('Scheduled entry'),
              trailing: Icon(Icons.chevron_right, color: linkColor),
            ),
          ),
          const SizedBox(height: 8),
          FilledButton(onPressed: () {}, child: const Text('Log entry')),
          TextButton(onPressed: () {}, child: const Text('View details')),
        ],
      ),
    );
  }
}

/// Lightweight chat chrome for theme golden snapshots.
class ChatThemeHarness extends StatelessWidget {
  const ChatThemeHarness({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Wellness Chat')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: theme.colorScheme.primary),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'How can I help organize your recovery plan?',
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: FilledButton(
              onPressed: () {},
              child: const Text('Send message'),
            ),
          ),
        ],
      ),
    );
  }
}
