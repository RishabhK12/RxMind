import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'discharge_data_manager.dart';
import 'package:rxmind_app/core/stats/compliance_calculator.dart';

class PdfExportService {
  static Future<File> generateHealthReport() async {
    final pdf = pw.Document();

    // Load all data
    final profileData = await DischargeDataManager.loadProfileData();
    final userName = profileData['name']?.toString() ?? 'Patient';
    final medications = await DischargeDataManager.loadMedications();
    final tasks = await DischargeDataManager.loadTasks();
    final followUps = await DischargeDataManager.loadFollowUps();
    final instructions = await DischargeDataManager.loadInstructions();
    final warnings = await DischargeDataManager.loadWarnings();

    // Calculate compliance stats
    final complianceStats = await _calculateComplianceStats(tasks);

    // Limit the amount of data to prevent TooManyPagesException
    final maxItemsPerSection = 10;
    final limitedMedications = medications.take(maxItemsPerSection).toList();
    final limitedTasks = tasks.take(maxItemsPerSection).toList();
    final limitedFollowUps = followUps.take(maxItemsPerSection).toList();
    final limitedInstructions = instructions.take(maxItemsPerSection).toList();
    final limitedWarnings = warnings.take(maxItemsPerSection).toList();

    // Generate PDF pages
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        maxPages: 20,
        footer: (context) {
          if (medications.length > maxItemsPerSection ||
              tasks.length > maxItemsPerSection ||
              followUps.length > maxItemsPerSection ||
              instructions.length > maxItemsPerSection ||
              warnings.length > maxItemsPerSection) {
            return pw.Container(
              alignment: pw.Alignment.centerRight,
              margin: const pw.EdgeInsets.only(top: 10),
              child: pw.Text(
                'Note: Some items were omitted due to space limitations.',
                style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
              ),
            );
          } else {
            return pw.SizedBox.shrink();
          }
        },
        build: (context) => [
          _buildHeader(userName),
          pw.SizedBox(height: 12),
          _buildProfileSection(profileData),
          pw.SizedBox(height: 12),
          _buildComplianceSection(complianceStats),
          pw.SizedBox(height: 12),
          _buildMedicationsSection(limitedMedications),
          pw.SizedBox(height: 12),
          _buildTasksSection(limitedTasks),
          pw.SizedBox(height: 12),
          _buildFollowUpsSection(limitedFollowUps),
          pw.SizedBox(height: 12),
          _buildInstructionsSection(limitedInstructions),
          pw.SizedBox(height: 12),
          _buildWarningsSection(limitedWarnings),
          pw.SizedBox(height: 12),
          _buildFooter(),
        ],
      ),
    );

    // Save PDF to device
    final output = await getApplicationDocumentsDirectory();
    final timestamp = DateFormat('yyyy-MM-dd_HHmmss').format(DateTime.now());
    final fileName = 'RxMind_Health_Report_$timestamp.pdf';
    final file = File('${output.path}/$fileName');
    await file.writeAsBytes(await pdf.save());

    return file;
  }

  static pw.Widget _buildHeader(String userName) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'RxMind Health Report',
            style: pw.TextStyle(
              fontSize: 28,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue900,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'Patient: $userName',
            style: pw.TextStyle(fontSize: 16, color: PdfColors.blue800),
          ),
          pw.Text(
            'Generated: ${DateFormat('MMMM dd, yyyy - hh:mm a').format(DateTime.now())}',
            style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildProfileSection(Map<String, dynamic> profile) {
    final age = profile['age']?.toString() ?? 'N/A';
    final sex = profile['sex']?.toString() ?? 'N/A';
    final height = profile['height']?.toString() ?? 'N/A';
    final weight = profile['weight']?.toString() ?? 'N/A';
    final bedtime = profile['bedtime']?.toString() ?? 'N/A';
    final wakeTime = profile['wakeTime']?.toString() ?? 'N/A';

    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Patient Profile',
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 12),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _buildProfileItem('Age', age),
              _buildProfileItem('Sex', sex),
              _buildProfileItem(
                  'Height', height != 'N/A' ? '$height cm' : 'N/A'),
              _buildProfileItem(
                  'Weight', weight != 'N/A' ? '$weight lbs' : 'N/A'),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _buildProfileItem('Bedtime', bedtime),
              _buildProfileItem('Wake Time', wakeTime),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildProfileItem(String label, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label,
            style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
        pw.Text(value, style: pw.TextStyle(fontSize: 12)),
      ],
    );
  }

  static pw.Widget _buildComplianceSection(Map<String, dynamic> stats) {
    final percentage = stats['percentage'] ?? 0;
    final completed = stats['completed'] ?? 0;
    final total = stats['total'] ?? 0;

    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: percentage >= 80
            ? PdfColors.green50
            : percentage >= 50
                ? PdfColors.amber50
                : PdfColors.red50,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(
          color: percentage >= 80
              ? PdfColors.green300
              : percentage >= 50
                  ? PdfColors.amber300
                  : PdfColors.red300,
        ),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Overall Compliance',
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 12),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: [
              pw.Column(
                children: [
                  pw.Text(
                    '$percentage%',
                    style: pw.TextStyle(
                      fontSize: 36,
                      fontWeight: pw.FontWeight.bold,
                      color: percentage >= 80
                          ? PdfColors.green900
                          : percentage >= 50
                              ? PdfColors.amber900
                              : PdfColors.red900,
                    ),
                  ),
                  pw.Text('Compliance Rate', style: pw.TextStyle(fontSize: 10)),
                ],
              ),
              pw.Column(
                children: [
                  pw.Text(
                    '$completed/$total',
                    style: pw.TextStyle(
                        fontSize: 24, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text('Tasks Completed', style: pw.TextStyle(fontSize: 10)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildMedicationsSection(
      List<Map<String, dynamic>> medications) {
    if (medications.isEmpty) {
      return pw.SizedBox.shrink();
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Medications',
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 8),
        pw.Table(
          // Using more compact table with simpler borders
          border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
          columnWidths: {
            0: const pw.FlexColumnWidth(3), // name
            1: const pw.FlexColumnWidth(2), // dosage
            2: const pw.FlexColumnWidth(2), // frequency
            3: const pw.FlexColumnWidth(3), // instructions
          },
          defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
          children: [
            // Header
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.blue50),
              children: [
                _buildTableCell('Medication', isHeader: true, compact: true),
                _buildTableCell('Dosage', isHeader: true, compact: true),
                _buildTableCell('Frequency', isHeader: true, compact: true),
                _buildTableCell('Instructions', isHeader: true, compact: true),
              ],
            ),
            // Data rows
            ...medications.map((med) => pw.TableRow(
                  children: [
                    _buildTableCell(med['name'] ?? 'N/A', compact: true),
                    _buildTableCell(med['dosage'] ?? 'N/A', compact: true),
                    _buildTableCell(med['frequency'] ?? 'N/A', compact: true),
                    _buildTableCell(med['instructions'] ?? 'N/A',
                        compact: true, maxLines: 3),
                  ],
                )),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildTasksSection(List<Map<String, dynamic>> tasks) {
    if (tasks.isEmpty) {
      return pw.SizedBox.shrink();
    }

    // Filter out warnings (they're shown in the warnings section)
    final filteredTasks = tasks.where((t) => t['type'] != 'warning').toList();

    if (filteredTasks.isEmpty) {
      return pw.SizedBox.shrink();
    }

    final completedTasks =
        filteredTasks.where((t) => t['completed'] == true).toList();
    final pendingTasks =
        filteredTasks.where((t) => t['completed'] != true).toList();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Tasks & Care Instructions',
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 12),
        if (pendingTasks.isNotEmpty) ...[
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.blue50,
              borderRadius: pw.BorderRadius.circular(8),
              border: pw.Border.all(color: PdfColors.blue200),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  children: [
                    pw.Container(
                      width: 16,
                      height: 16,
                      decoration: pw.BoxDecoration(
                        shape: pw.BoxShape.circle,
                        border:
                            pw.Border.all(color: PdfColors.blue900, width: 2),
                      ),
                    ),
                    pw.SizedBox(width: 8),
                    pw.Text(
                      'Pending Tasks (${pendingTasks.length})',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue900,
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 8),
                ...pendingTasks.map((task) => _buildTaskItem(task, false)),
              ],
            ),
          ),
          pw.SizedBox(height: 12),
        ],
        if (completedTasks.isNotEmpty) ...[
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.green50,
              borderRadius: pw.BorderRadius.circular(8),
              border: pw.Border.all(color: PdfColors.green200),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  children: [
                    pw.Container(
                      width: 16,
                      height: 16,
                      decoration: pw.BoxDecoration(
                        shape: pw.BoxShape.circle,
                        color: PdfColors.green700,
                      ),
                    ),
                    pw.SizedBox(width: 8),
                    pw.Text(
                      'Completed Tasks (${completedTasks.length})',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.green700,
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 8),
                ...completedTasks.map((task) => _buildTaskItem(task, true)),
              ],
            ),
          ),
        ],
      ],
    );
  }

  static pw.Widget _buildTaskItem(Map<String, dynamic> task, bool completed) {
    final isCustomTask = task['type'] == 'task';
    // Use a simpler layout to reduce PDF complexity
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 6),
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: completed ? PdfColors.white : PdfColors.grey50,
        borderRadius: pw.BorderRadius.circular(4),
        border: pw.Border.all(
          color: completed ? PdfColors.green400 : PdfColors.grey400,
          width: 1,
        ),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: 12,
            height: 12,
            margin: const pw.EdgeInsets.only(right: 8, top: 2),
            decoration: pw.BoxDecoration(
              shape: pw.BoxShape.circle,
              color: completed ? PdfColors.green500 : PdfColors.grey300,
            ),
            child: completed
                ? pw.Center(
                    child: pw.Text('✓',
                        style:
                            pw.TextStyle(color: PdfColors.white, fontSize: 8)))
                : null,
          ),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  task['title'] ?? 'Task',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    decoration:
                        completed ? pw.TextDecoration.lineThrough : null,
                    color: completed ? PdfColors.grey600 : PdfColors.black,
                  ),
                ),
                // Only show minimal description if available
                if (task['description'] != null)
                  pw.Text(
                    task['description'],
                    maxLines: 2,
                    style: pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                  ),
                // Show compact due date and completion status on one line when possible
                pw.Text(
                  [
                    if (task['dueTime'] != null)
                      'Due: ${_formatDateTimeCompact(task['dueTime'])}',
                    if (completed && task['lastCompleted'] != null)
                      'Completed: ${_formatDateTimeCompact(task['lastCompleted'])}',
                    if (task['isRecurring'] == true)
                      'Recurring: ${task['recurringPattern'] ?? 'daily'}',
                    if (isCustomTask) 'CUSTOM'
                  ].join(' | '),
                  style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Add a compact date formatter to reduce text length
  static String _formatDateTimeCompact(dynamic dateTime) {
    try {
      DateTime dt;
      if (dateTime is DateTime) {
        dt = dateTime;
      } else {
        dt = DateTime.parse(dateTime.toString());
      }
      return DateFormat('MM/dd/yy').format(dt);
    } catch (e) {
      return dateTime.toString();
    }
  }

  static pw.Widget _buildFollowUpsSection(
      List<Map<String, dynamic>> followUps) {
    if (followUps.isEmpty) {
      return pw.SizedBox.shrink();
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Follow-up Appointments',
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 8),
        // Use a single container with multiple items to reduce PDF complexity
        pw.Container(
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(
            color: PdfColors.blue50,
            borderRadius: pw.BorderRadius.circular(6),
            border: pw.Border.all(color: PdfColors.blue200),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: followUps
                .map((followUp) => pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(vertical: 4),
                      child: pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('- ', style: pw.TextStyle(fontSize: 10)),
                          pw.Expanded(
                            child: pw.Text(
                              _formatFollowUp(followUp),
                              style: pw.TextStyle(fontSize: 9),
                            ),
                          ),
                        ],
                      ),
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }

  /// Format follow-up appointment for display
  static String _formatFollowUp(Map<String, dynamic> followUp) {
    final name = followUp['name'] ?? followUp['text'] ?? 'Appointment';
    final date = followUp['date'];

    if (date != null && date.toString().isNotEmpty) {
      return '$name - $date';
    } else {
      return name;
    }
  }

  static pw.Widget _buildInstructionsSection(
      List<Map<String, dynamic>> instructions) {
    if (instructions.isEmpty) {
      return pw.SizedBox.shrink();
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Care Instructions',
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 8),
        // Use a single container with multiple items to reduce PDF complexity
        pw.Container(
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey100,
            borderRadius: pw.BorderRadius.circular(6),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: instructions
                .map((instruction) => pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(vertical: 4),
                      child: pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('- ', style: pw.TextStyle(fontSize: 10)),
                          pw.Expanded(
                            child: pw.Text(
                              instruction['name'] ??
                                  instruction['text'] ??
                                  instruction.toString(),
                              style: pw.TextStyle(fontSize: 9),
                            ),
                          ),
                        ],
                      ),
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildWarningsSection(List<Map<String, dynamic>> warnings) {
    if (warnings.isEmpty) {
      return pw.SizedBox.shrink();
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Warnings & Restrictions',
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 8),
        pw.Container(
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(
            color: PdfColors.amber50,
            borderRadius: pw.BorderRadius.circular(6),
            border: pw.Border.all(color: PdfColors.amber300, width: 0.5),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: warnings
                .map((warning) => pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(vertical: 4),
                      child: pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('! ',
                              style: pw.TextStyle(
                                  fontSize: 10,
                                  color: PdfColors.amber900,
                                  fontWeight: pw.FontWeight.bold)),
                          pw.SizedBox(width: 4),
                          pw.Expanded(
                            child: pw.Text(
                              warning['name'] ??
                                  warning['text'] ??
                                  warning.toString(),
                              style: pw.TextStyle(fontSize: 9),
                            ),
                          ),
                        ],
                      ),
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildTableCell(String text,
      {bool isHeader = false, bool compact = false, int? maxLines}) {
    return pw.Padding(
      padding:
          compact ? const pw.EdgeInsets.all(4) : const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        maxLines: maxLines,
        style: pw.TextStyle(
          fontSize: compact ? (isHeader ? 9 : 8) : (isHeader ? 11 : 10),
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  static pw.Widget _buildFooter() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300)),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            'This report was generated by RxMind',
            style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
          ),
          pw.Text(
            'Keep this document for your health records',
            style: pw.TextStyle(fontSize: 9, color: PdfColors.grey500),
          ),
        ],
      ),
    );
  }

  static Future<Map<String, dynamic>> _calculateComplianceStats(
      List<Map<String, dynamic>> tasks) async {
    // Use the shared compliance calculator to ensure consistency across the app
    final compliance = ComplianceCalculator.calculateFromTasks(tasks);

    return {
      'percentage': compliance['percentage'],
      'completed': compliance['completed'],
      'total': compliance['total'],
    };
  }
}
