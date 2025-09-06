import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class ComplianceStatsScreen extends StatefulWidget {
  const ComplianceStatsScreen({super.key});

  @override
  State<ComplianceStatsScreen> createState() => ComplianceStatsScreenState();
}

class ComplianceStatsScreenState extends State<ComplianceStatsScreen>
    with SingleTickerProviderStateMixin {
  // Public method to trigger chart animation from navigation
  void resetAndAnimateCharts() {
    // Only animate if controller is initialized
    try {
      if (mounted) {
        _resetAndAnimateCharts();
      }
    } catch (_) {
      // Controller not yet initialized, do nothing
    }
  }

  final int healthScore = 87;
  final List<DayCount> _targetWeekData = [
    DayCount('Mon', 3),
    DayCount('Tue', 2),
    DayCount('Wed', 4),
    DayCount('Thu', 3),
    DayCount('Fri', 5),
    DayCount('Sat', 2),
    DayCount('Sun', 4),
  ];
  final List<PieData> _targetPieData = [
    PieData('On-Time', 85, Colors.teal),
    PieData('Missed', 15, Colors.red),
  ];

  List<DayCount> weekData = [];
  List<PieData> pieData = [];
  double piePercent = 0;

  // Animation removed

  @override
  void initState() {
    super.initState();
    weekData = List.generate(_targetWeekData.length, (i) {
      final target = _targetWeekData[i].count;
      return DayCount(_targetWeekData[i].day, target);
    });
    pieData = [
      PieData('On-Time', _targetPieData[0].value, Colors.teal),
      PieData('Missed', _targetPieData[1].value, Colors.red)
    ];
    piePercent = 1.0;
    // Instantly reset chart data
    void resetCharts() {
      setState(() {
        weekData = List.generate(_targetWeekData.length, (i) {
          final target = _targetWeekData[i].count;
          return DayCount(_targetWeekData[i].day, target);
        });
        pieData = [
          PieData('On-Time', _targetPieData[0].value, Colors.teal),
          PieData('Missed', _targetPieData[1].value, Colors.red)
        ];
        piePercent = 1.0;
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  void _resetAndAnimateCharts() {
    // Method no longer used; animation removed
  }

  // Animation logic removed

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
