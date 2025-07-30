import 'package:flutter/material.dart';

class StreaksWidget extends StatelessWidget {
  final List<Map<String, dynamic>> compliance;
  const StreaksWidget({required this.compliance, Key? key}) : super(key: key);

  int _calculateStreak() {
    final dates = compliance.map((c) => DateTime.parse(c['date'])).toList()
      ..sort();
    if (dates.isEmpty) return 0;
    int streak = 1;
    for (int i = dates.length - 2; i >= 0; i--) {
      if (dates[i + 1].difference(dates[i]).inDays == 1) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  @override
  Widget build(BuildContext context) {
    final streak = _calculateStreak();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.local_fire_department, color: Colors.orange, size: 28),
        const SizedBox(width: 8),
        Text(
          streak > 1 ? '$streak day streak!' : 'No streak yet',
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
