import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:rxmind_app/services/discharge_data_manager.dart';

class ComplianceStatsScreen extends StatefulWidget {
  const ComplianceStatsScreen({super.key});

  @override
  State<ComplianceStatsScreen> createState() => ComplianceStatsScreenState();
}

class ComplianceStatsScreenState extends State<ComplianceStatsScreen>
    with SingleTickerProviderStateMixin {
  // Data fields
  List<DayCount> weekData = [];
  List<PieData> pieData = [];
  int healthScore = 0;

  @override
  void initState() {
    super.initState();
    _loadDischargeStatus();
    _loadTaskComplianceData();
  }

  Future<void> _loadDischargeStatus() async {
    // Check if discharge data is available, but we don't need to store it since
    // we already load task compliance data separately
    await DischargeDataManager.isDischargeUploaded();
  }

  Future<void> _loadTaskComplianceData() async {
    try {
      // Load tasks from storage
      final tasks = await DischargeDataManager.loadTasks();

      if (tasks.isEmpty) {
        setState(() {
          healthScore = 0;
          weekData = [];
          pieData = [];
        });
        return;
      }

      // Calculate task compliance by day of week
      final now = DateTime.now();
      final weekStart = now.subtract(Duration(days: now.weekday - 1));

      // Initialize data for each day of the week
      final Map<String, int> completedByDay = {
        'Mon': 0,
        'Tue': 0,
        'Wed': 0,
        'Thu': 0,
        'Fri': 0,
        'Sat': 0,
        'Sun': 0,
      };

      final Map<String, int> totalByDay = Map.from(completedByDay);

      // Track total tasks and completed tasks for pie chart
      int totalTasks = 0;
      int completedTasks = 0;

      // Analyze each task
      for (final task in tasks) {
        try {
          // Skip if no dueTime
          if (task['dueTime'] == null) continue;

          final dueTime = DateTime.parse(task['dueTime'].toString());
          final isCompleted = task['completed'] == true;
          final isRecurring = task['isRecurring'] == true;

          // Handle recurring tasks
          if (isRecurring) {
            final recurringPattern =
                task['recurringPattern']?.toString().toLowerCase() ?? 'daily';
            final int recurringInterval = task['recurringInterval'] is int
                ? task['recurringInterval'] as int
                : (task['recurringInterval'] != null
                    ? int.tryParse(task['recurringInterval'].toString()) ?? 1
                    : 1); // Get task start date or use dueTime as fallback
            final startDateStr = task['startDate']?.toString();
            DateTime startDate;
            try {
              startDate =
                  startDateStr != null ? DateTime.parse(startDateStr) : dueTime;
            } catch (e) {
              startDate = dueTime;
            }

            // Generate instances based on recurring pattern
            DateTime current = startDate;
            while (current.isBefore(now) || current.isAtSameMomentAs(now)) {
              // Check if this instance falls within the current week
              if (current.isAfter(weekStart) ||
                  current.isAtSameMomentAs(weekStart)) {
                final dayKey = _getDayKey(current.weekday);
                totalByDay[dayKey] = (totalByDay[dayKey] ?? 0) + 1;
                totalTasks++;

                // For recurring tasks, check if it's completed for this specific instance
                final bool instanceCompleted = isCompleted;

                if (instanceCompleted) {
                  completedByDay[dayKey] = (completedByDay[dayKey] ?? 0) + 1;
                  completedTasks++;
                }
              }

              // Move to next occurrence based on pattern
              switch (recurringPattern) {
                case 'daily':
                  current = current.add(Duration(days: recurringInterval));
                  break;
                case 'weekly':
                  current = current.add(Duration(days: 7 * recurringInterval));
                  break;
                case 'monthly':
                  current = DateTime(current.year,
                      current.month + recurringInterval, current.day);
                  break;
                default:
                  current = current.add(Duration(days: recurringInterval));
              }
            }
          } else {
            // Handle non-recurring tasks
            // Only include tasks from this week
            if (dueTime.isAfter(weekStart) ||
                dueTime.isAtSameMomentAs(weekStart)) {
              final dayKey = _getDayKey(dueTime.weekday);
              totalByDay[dayKey] = (totalByDay[dayKey] ?? 0) + 1;
              totalTasks++;

              if (isCompleted) {
                completedByDay[dayKey] = (completedByDay[dayKey] ?? 0) + 1;
                completedTasks++;
              }
            }
          }
        } catch (e) {
          debugPrint('Error processing task: $e');
        }
      }

      // Convert to chart data format
      final List<DayCount> chartData = [];
      for (final entry in completedByDay.entries) {
        // Calculate percentage of tasks completed for each day
        final total = totalByDay[entry.key] ?? 0;
        final completed = entry.value;
        final percentage = total > 0 ? (completed / total * 100).round() : 0;
        chartData.add(DayCount(entry.key, percentage));
      }

      // Calculate pie chart data
      int completionPercentage =
          totalTasks > 0 ? ((completedTasks / totalTasks) * 100).round() : 0;
      final List<PieData> pieChartData = [
        PieData('Completed', completionPercentage, Colors.green),
        PieData('Missed', 100 - completionPercentage, Colors.red),
      ];

      // Calculate health score (0-100)
      final int calculatedHealthScore = completionPercentage;

      setState(() {
        weekData = chartData;
        pieData = pieChartData;
        healthScore = calculatedHealthScore;
      });
    } catch (e) {
      debugPrint('Error loading task compliance data: $e');
    }
  }

  String _getDayKey(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'Mon';
      case DateTime.tuesday:
        return 'Tue';
      case DateTime.wednesday:
        return 'Wed';
      case DateTime.thursday:
        return 'Thu';
      case DateTime.friday:
        return 'Fri';
      case DateTime.saturday:
        return 'Sat';
      case DateTime.sunday:
        return 'Sun';
      default:
        return 'Mon';
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  final List<String> glossaryTerms = [
    'Hypertension',
    'Beta Blocker',
    'Systolic'
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 1,
        title: Semantics(
          header: true,
          label: 'Your Health Trends screen',
          child: Text(
            'Your Health Trends',
            style: theme.textTheme.titleLarge,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              label: 'Your health score is $healthScore',
              child: Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondary,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Text(
                      '$healthScore',
                      style: theme.textTheme.displayLarge
                          ?.copyWith(color: theme.colorScheme.onSecondary),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Health Score',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(color: theme.colorScheme.onSecondary),
                    ),
                  ],
                ),
              ),
            ),
            if (weekData.isNotEmpty)
              Semantics(
                label: 'Weekly medication compliance bar chart',
                child: SizedBox(
                  height: 200,
                  child: SfCartesianChart(
                    primaryXAxis: CategoryAxis(),
                    series: <CartesianSeries<dynamic, dynamic>>[
                      ColumnSeries<dynamic, dynamic>(
                        dataSource: weekData,
                        xValueMapper: (d, _) => d.day,
                        yValueMapper: (d, _) => d.count,
                        color: theme.colorScheme.primary,
                        animationDuration: 0,
                      ),
                    ],
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: Text('No weekly data to display.',
                      style: theme.textTheme.bodyMedium),
                ),
              ),
            const SizedBox(height: 24),
            if (pieData.isNotEmpty)
              Semantics(
                label: 'Pie chart showing on-time versus missed doses',
                child: SizedBox(
                  height: 200,
                  child: SfCircularChart(
                    series: <CircularSeries<dynamic, dynamic>>[
                      PieSeries<dynamic, dynamic>(
                        dataSource: pieData,
                        xValueMapper: (d, _) => d.label,
                        yValueMapper: (d, _) => d.value,
                        pointColorMapper: (d, _) => d.color,
                        dataLabelMapper: (d, _) => '${d.value}%',
                        dataLabelSettings:
                            const DataLabelSettings(isVisible: true),
                        animationDuration: 0,
                      ),
                    ],
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: Text('No pie chart data to display.',
                      style: theme.textTheme.bodyMedium),
                ),
              ),
            const SizedBox(height: 24),
            // Health glossary moved to Medications tab
            const SizedBox(height: 24),
            Semantics(
              label: 'Data export and import section',
              child: Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Semantics(
                        button: true,
                        label: 'Export your health data',
                        child: ElevatedButton(
                          onPressed: () {
                            // TODO: Export backup
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text(
                            'Export Data',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.onPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      // Removed Import Data button
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DayCount {
  final String day;
  final int count;
  DayCount(this.day, this.count);
}

class PieData {
  final String label;
  final int value;
  final Color color;
  PieData(this.label, this.value, this.color);
}
