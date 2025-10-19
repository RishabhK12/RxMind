import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:rxmind_app/services/discharge_data_manager.dart';
import 'package:rxmind_app/services/pdf_export_service.dart';
import 'package:rxmind_app/screens/pdf/pdf_preview_screen.dart';
import 'package:rxmind_app/core/stats/compliance_calculator.dart';

class ComplianceStatsScreen extends StatefulWidget {
  const ComplianceStatsScreen({super.key});

  @override
  State<ComplianceStatsScreen> createState() => ComplianceStatsScreenState();
}

class ComplianceStatsScreenState extends State<ComplianceStatsScreen>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  // Data fields
  List<DayCount> weekData = [];
  List<PieData> pieData = [];
  int healthScore = 0;

  @override
  bool get wantKeepAlive => false; // Don't keep alive to allow refresh

  @override
  void initState() {
    super.initState();
    _loadDischargeStatus();
    _loadTaskComplianceData();

    // Set up a listener to auto-refresh when tasks are updated
    DischargeDataManager.addTaskUpdateListener(_loadTaskComplianceData);
  }

  @override
  void dispose() {
    // Remove the listener when screen is disposed
    DischargeDataManager.removeTaskUpdateListener(_loadTaskComplianceData);
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload data when screen becomes visible
    _loadTaskComplianceData();
  }

  /// Public method to refresh stats data - can be called from other screens
  void refreshStats() {
    _loadTaskComplianceData();
  }

  Future<void> _loadDischargeStatus() async {
    // Check if discharge data is available, but we don't need to store it since
    // we already load task compliance data separately
    await DischargeDataManager.isDischargeUploaded();
  }

  Future<void> _loadTaskComplianceData() async {
    try {
      final tasks = await DischargeDataManager.loadTasks();
      final medications = await DischargeDataManager.loadMedications();

      if (tasks.isEmpty && medications.isEmpty) {
        setState(() {
          healthScore = 0;
          weekData = [];
          pieData = [];
        });
        return;
      }

      final now = DateTime.now();
      final weekStart = now.subtract(Duration(days: now.weekday - 1));

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

      int totalDueItems = 0;
      int completedItems = 0;
      int overdueItems = 0;

      // Process tasks
      for (final task in tasks) {
        try {
          if (task['dueTime'] == null) continue;

          final dueTime = DateTime.parse(task['dueTime'].toString());
          final isCompleted = task['completed'] == true;
          final isRecurring = task['isRecurring'] == true;

          if (isRecurring) {
            final recurringPattern =
                task['recurringPattern']?.toString().toLowerCase() ?? 'daily';
            final int recurringInterval = task['recurringInterval'] is int
                ? task['recurringInterval'] as int
                : (int.tryParse(task['recurringInterval']?.toString() ?? '1') ??
                    1);

            final startDateStr = task['startDate']?.toString();
            DateTime startDate;
            try {
              startDate =
                  startDateStr != null ? DateTime.parse(startDateStr) : dueTime;
            } catch (e) {
              startDate = dueTime;
            }

            DateTime current = startDate;
            while (current.isBefore(now.add(const Duration(days: 1)))) {
              final isThisWeek = current
                      .isAfter(weekStart.subtract(const Duration(days: 1))) &&
                  current.isBefore(now.add(const Duration(days: 1)));

              if (isThisWeek) {
                final dayKey = _getDayKey(current.weekday);
                final isPastDue = current.isBefore(now);

                // Count ALL tasks (past, present, and future)
                totalByDay[dayKey] = (totalByDay[dayKey] ?? 0) + 1;
                totalDueItems++;

                if (isCompleted) {
                  // Count completed tasks
                  completedByDay[dayKey] = (completedByDay[dayKey] ?? 0) + 1;
                  completedItems++;
                } else if (isPastDue) {
                  // Count overdue tasks (but they still contribute to the total)
                  overdueItems++;
                }
                // Future tasks are counted for the total but not marked as overdue
              }
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
            final isThisWeek =
                dueTime.isAfter(weekStart.subtract(const Duration(days: 1))) &&
                    dueTime.isBefore(now.add(const Duration(days: 1)));
            final isPastDue = dueTime.isBefore(now);

            // Count ALL tasks (past, present, and future) that are in this week
            if (isThisWeek) {
              final dayKey = _getDayKey(dueTime.weekday);
              totalByDay[dayKey] = (totalByDay[dayKey] ?? 0) + 1;
              totalDueItems++;

              if (isCompleted) {
                // Count completed tasks
                completedByDay[dayKey] = (completedByDay[dayKey] ?? 0) + 1;
                completedItems++;
              } else if (isPastDue) {
                // Count overdue items for display separately
                overdueItems++;
              }
              // Future tasks are counted in the total but not marked as overdue
            }
          }
        } catch (e) {
          // Continue processing other tasks
        }
      }

      // Process medications
      for (final med in medications) {
        try {
          final completionHistory =
              med['completionHistory'] as List<dynamic>? ?? [];

          // Count completed doses from this week
          for (final completionTimeStr in completionHistory) {
            try {
              final completionTime =
                  DateTime.parse(completionTimeStr.toString());
              final isThisWeek = completionTime
                  .isAfter(weekStart.subtract(const Duration(days: 1)));

              if (isThisWeek) {
                final dayKey = _getDayKey(completionTime.weekday);
                completedByDay[dayKey] = (completedByDay[dayKey] ?? 0) + 1;
                completedItems++;
                totalByDay[dayKey] = (totalByDay[dayKey] ?? 0) + 1;
                totalDueItems++;
              }
            } catch (e) {
              // Continue with next completion time
            }
          }

          // Calculate expected doses and missed doses
          final frequency = med['frequency']?.toString() ?? 'Once daily';
          final lastTaken = med['lastTaken'];

          if (lastTaken != null) {
            try {
              DateTime lastTakenTime;
              if (lastTaken is DateTime) {
                lastTakenTime = lastTaken;
              } else {
                lastTakenTime = DateTime.parse(lastTaken.toString());
              }

              final expectedInterval = _parseFrequencyDuration(frequency);
              DateTime expectedDoseTime = lastTakenTime.add(expectedInterval);

              // Find all missed doses up to now
              while (expectedDoseTime.isBefore(now)) {
                final isThisWeek = expectedDoseTime
                    .isAfter(weekStart.subtract(const Duration(days: 1)));

                if (isThisWeek) {
                  // Check if this dose was actually taken (in completion history)
                  bool wasTaken = completionHistory.any((timeStr) {
                    try {
                      final time = DateTime.parse(timeStr.toString());
                      return time.difference(expectedDoseTime).abs().inHours <
                          2;
                    } catch (e) {
                      return false;
                    }
                  });

                  if (!wasTaken) {
                    final dayKey = _getDayKey(expectedDoseTime.weekday);
                    totalByDay[dayKey] = (totalByDay[dayKey] ?? 0) + 1;
                    totalDueItems++;
                    overdueItems++;
                  }
                }

                expectedDoseTime = expectedDoseTime.add(expectedInterval);
              }
            } catch (e) {
              // Continue with next medication
            }
          }
        } catch (e) {
          // Continue with next medication
        }
      }

      // Build chart data
      final List<DayCount> chartData = [];
      for (final entry in completedByDay.entries) {
        final total = totalByDay[entry.key] ?? 0;
        final completed = entry.value;
        final percentage = total > 0 ? (completed / total * 100).round() : 0;
        chartData.add(DayCount(entry.key, percentage));
      }

      // Get the global compliance metrics for consistent calculation
      final globalCompliance =
          await ComplianceCalculator.calculateOverallCompliance();
      final int completionPercentage = globalCompliance['percentage'];

      // Calculate pending items and percentages using consistent data
      final int pendingItems = totalDueItems - completedItems - overdueItems;
      final int pendingPercentage = totalDueItems > 0
          ? ((pendingItems / totalDueItems) * 100).round()
          : 0;
      final int overduePercentage = totalDueItems > 0
          ? ((overdueItems / totalDueItems) * 100).round()
          : 0;

      // Build enhanced pie chart with the updated compliance data
      final List<PieData> pieChartData = [
        PieData('Completed', completionPercentage, Colors.green),
        PieData('Pending', pendingPercentage, Colors.amber),
        PieData('Overdue', overduePercentage, Colors.red),
      ];

      // Health score weighs completion heavily and penalizes overdue items
      final int calculatedHealthScore = totalDueItems > 0
          ? ((completedItems / totalDueItems * 80) +
                  ((totalDueItems - overdueItems) / totalDueItems * 20))
              .round()
          : 100;

      setState(() {
        weekData = chartData;
        pieData = pieChartData;
        healthScore = calculatedHealthScore.clamp(0, 100);
      });
    } catch (e) {
      // Error loading compliance data
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

  /// Parse frequency string and calculate duration
  Duration _parseFrequencyDuration(String frequency) {
    final lowerFreq = frequency.toLowerCase();

    // Parse patterns like "twice daily", "3 times a day", "every 8 hours"
    if (lowerFreq.contains('hour')) {
      final match = RegExp(r'(\d+)\s*hour').firstMatch(lowerFreq);
      if (match != null) {
        final hours = int.tryParse(match.group(1) ?? '24') ?? 24;
        return Duration(hours: hours);
      }
    }

    if (lowerFreq.contains('once') ||
        lowerFreq.contains('daily') ||
        lowerFreq.contains('day')) {
      if (lowerFreq.contains('twice') || lowerFreq.contains('2')) {
        return const Duration(hours: 12);
      } else if (lowerFreq.contains('three') || lowerFreq.contains('3')) {
        return const Duration(hours: 8);
      } else if (lowerFreq.contains('four') || lowerFreq.contains('4')) {
        return const Duration(hours: 6);
      }
      return const Duration(hours: 24);
    }

    if (lowerFreq.contains('week')) {
      return const Duration(days: 7);
    }

    if (lowerFreq.contains('month')) {
      return const Duration(days: 30);
    }

    // Default to 24 hours
    return const Duration(hours: 24);
  }

  Color _getColumnColor(int value, ThemeData theme) {
    if (value >= 80) {
      return Colors.green[400] ?? Colors.green;
    } else if (value >= 50) {
      return Colors.amber;
    } else {
      return Colors.redAccent;
    }
  }

  Color _getHealthScoreColor(int score) {
    if (score >= 80) {
      return Colors.green[600] ?? Colors.green;
    } else if (score >= 60) {
      return Colors.lightGreen[700] ?? Colors.lightGreen;
    } else if (score >= 40) {
      return Colors.amber[700] ?? Colors.amber;
    } else if (score >= 20) {
      return Colors.deepOrange;
    } else {
      return Colors.red[700] ?? Colors.red;
    }
  }

  IconData _getHealthScoreIcon(int score) {
    if (score >= 80) {
      return Icons.sentiment_very_satisfied;
    } else if (score >= 60) {
      return Icons.sentiment_satisfied;
    } else if (score >= 40) {
      return Icons.sentiment_neutral;
    } else if (score >= 20) {
      return Icons.sentiment_dissatisfied;
    } else {
      return Icons.sentiment_very_dissatisfied;
    }
  }

  Widget _buildLegendItem(
      BuildContext context, String label, Color color, String percentage) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$label: $percentage',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }

  final List<String> glossaryTerms = [
    'Hypertension',
    'Beta Blocker',
    'Systolic'
  ];

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
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
                padding: const EdgeInsets.all(20),
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _getHealthScoreColor(healthScore),
                      _getHealthScoreColor(healthScore).withOpacity(0.7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: _getHealthScoreColor(healthScore).withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Health Score',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.white.withOpacity(0.9),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              '$healthScore',
                              style: theme.textTheme.displayLarge?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 4.0),
                              child: Text(
                                '/100',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: Colors.white.withOpacity(0.7),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(
                          _getHealthScoreIcon(healthScore),
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (weekData.isNotEmpty)
              Semantics(
                label: 'Weekly medication compliance bar chart',
                child: Container(
                  height: 250,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.shadow.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: SfCartesianChart(
                    title: ChartTitle(
                      text: 'Weekly Task Compliance',
                      textStyle: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      alignment: ChartAlignment.near,
                    ),
                    primaryXAxis: CategoryAxis(
                      majorGridLines: const MajorGridLines(width: 0),
                      labelStyle: theme.textTheme.bodyMedium,
                    ),
                    primaryYAxis: NumericAxis(
                      minimum: 0,
                      maximum: 100,
                      interval: 20,
                      labelFormat: '{value}%',
                      labelStyle: theme.textTheme.bodySmall,
                      axisLine: const AxisLine(width: 0),
                      majorTickLines: const MajorTickLines(size: 0),
                    ),
                    series: <CartesianSeries<dynamic, dynamic>>[
                      ColumnSeries<dynamic, dynamic>(
                        dataSource: weekData,
                        xValueMapper: (d, _) => d.day,
                        yValueMapper: (d, _) => d.count,
                        pointColorMapper: (d, _) =>
                            _getColumnColor(d.count, theme),
                        borderRadius: BorderRadius.circular(4),
                        dataLabelSettings: DataLabelSettings(
                          isVisible: true,
                          labelAlignment: ChartDataLabelAlignment.top,
                          textStyle: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                          labelPosition: ChartDataLabelPosition.outside,
                          builder: (dynamic data, dynamic point, dynamic series,
                              int pointIndex, int seriesIndex) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 2),
                              child: Text(
                                '${data.count}%',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          },
                        ),
                        animationDuration: 800,
                        animationDelay: 100,
                        width: 0.7,
                      ),
                    ],
                    tooltipBehavior: TooltipBehavior(
                      enable: true,
                      format: 'point.x: point.y%',
                      header: '',
                    ),
                    plotAreaBorderWidth: 0,
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
                label:
                    'Overall compliance chart showing completed, pending, and overdue tasks',
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.shadow.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Overall Compliance',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Pie chart using Syncfusion
                      SizedBox(
                        height: 200,
                        child: SfCircularChart(
                          legend: Legend(
                            isVisible: false,
                          ),
                          series: <CircularSeries>[
                            DoughnutSeries<PieData, String>(
                              dataSource: pieData,
                              xValueMapper: (PieData data, _) => data.label,
                              yValueMapper: (PieData data, _) => data.value,
                              pointColorMapper: (PieData data, _) => data.color,
                              innerRadius: '60%',
                              radius: '80%',
                              dataLabelSettings: const DataLabelSettings(
                                isVisible: true,
                                labelPosition: ChartDataLabelPosition.outside,
                                textStyle: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              dataLabelMapper: (PieData data, _) =>
                                  '${data.value}%',
                            ),
                          ],
                          annotations: <CircularChartAnnotation>[
                            CircularChartAnnotation(
                              widget: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '$healthScore%',
                                    style: theme.textTheme.headlineMedium
                                        ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                  Text(
                                    'Health Score',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurface
                                          .withOpacity(0.7),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Legend
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 16,
                        runSpacing: 8,
                        children: [
                          _buildLegendItem(
                            context,
                            'Completed',
                            Colors.green,
                            '${pieData.isNotEmpty ? pieData[0].value : 0}%',
                          ),
                          _buildLegendItem(
                            context,
                            'Pending',
                            Colors.amber,
                            '${pieData.length > 1 ? pieData[1].value : 0}%',
                          ),
                          _buildLegendItem(
                            context,
                            'Overdue',
                            Colors.red,
                            '${pieData.length > 2 ? pieData[2].value : 0}%',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: Text('No compliance data to display.',
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
                          onPressed: () async {
                            try {
                              // Show loading indicator
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (context) => const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );

                              // Generate PDF
                              final pdfFile =
                                  await PdfExportService.generateHealthReport();

                              // Close loading dialog
                              if (!mounted) return;
                              Navigator.of(context).pop();

                              // Navigate to preview screen
                              if (!mounted) return;
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      PdfPreviewScreen(pdfFile: pdfFile),
                                ),
                              );
                            } catch (e) {
                              // Close loading dialog if still open
                              if (mounted && Navigator.of(context).canPop()) {
                                Navigator.of(context).pop();
                              }

                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error exporting PDF: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
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
