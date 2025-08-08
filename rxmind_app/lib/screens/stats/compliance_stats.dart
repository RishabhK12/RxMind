import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class ComplianceStatsScreen extends StatefulWidget {
  const ComplianceStatsScreen({Key? key}) : super(key: key);

  @override
  State<ComplianceStatsScreen> createState() => _ComplianceStatsScreenState();
}

class _ComplianceStatsScreenState extends State<ComplianceStatsScreen> {
  // Dummy data for preview
  final int healthScore = 87;
  final List<DayCount> weekData = [
    DayCount('Mon', 3),
    DayCount('Tue', 2),
    DayCount('Wed', 4),
    DayCount('Thu', 3),
    DayCount('Fri', 5),
    DayCount('Sat', 2),
    DayCount('Sun', 4),
  ];
  final List<PieData> pieData = [
    PieData('On-Time', 85, Colors.teal),
    PieData('Missed', 15, Colors.red),
  ];
  final List<String> glossaryTerms = [
    'Hypertension',
    'Beta Blocker',
    'Systolic'
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.background,
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
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
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
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Semantics(
              label: 'Health glossary section',
              child: Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Health Glossary',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      ...glossaryTerms.map((term) => Semantics(
                            button: true,
                            label: 'Glossary term: $term. Tap for definition.',
                            child: ListTile(
                              title: Text(
                                term,
                                style: theme.textTheme.bodyLarge,
                              ),
                              trailing: Icon(Icons.info_outline,
                                  color: theme.colorScheme.primary),
                              onTap: () {
                                // TODO: Show bottom sheet with definition
                              },
                            ),
                          )),
                    ],
                  ),
                ),
              ),
            ),
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
                      const SizedBox(height: 12),
                      Semantics(
                        button: true,
                        label: 'Import your health data',
                        child: ElevatedButton(
                          onPressed: () {
                            // TODO: Import backup
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.secondary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text(
                            'Import Data',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.onSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
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
