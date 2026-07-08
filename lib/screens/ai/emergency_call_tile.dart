import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class EmergencyCallTile extends StatelessWidget {
  const EmergencyCallTile({
    super.key,
    required this.number,
    required this.label,
  });

  final String number;
  final String label;

  Future<void> _call() async {
    final uri = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      label: 'Call $number',
      button: true,
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 6),
        child: ListTile(
          leading: Icon(Icons.phone, color: theme.colorScheme.error),
          title: Text(number, style: theme.textTheme.titleMedium),
          subtitle: Text(label),
          onTap: _call,
        ),
      ),
    );
  }
}
