import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ComplianceCalendar extends StatelessWidget {
  final List<Map<String, dynamic>> compliance;
  const ComplianceCalendar({required this.compliance, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final weekDays = List.generate(
        7, (i) => now.subtract(Duration(days: now.weekday - 1 - i)));
    final completedDays = compliance.map((c) => c['date']).toSet();
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: weekDays.map((day) {
        final dateStr = DateFormat('yyyy-MM-dd').format(day);
        final done = completedDays.contains(dateStr);
        return Column(
          children: [
            Text(DateFormat('E').format(day),
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            CircleAvatar(
              radius: 16,
              backgroundColor: done ? Colors.greenAccent : Colors.grey[300],
              child: done
                  ? const Icon(Icons.check, color: Colors.white, size: 18)
                  : null,
            ),
          ],
        );
      }).toList(),
    );
  }
}
