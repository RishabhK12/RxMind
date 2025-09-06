// Removed unused import
import 'package:pdf/widgets.dart' as pw;
import 'dart:io';

class ExportService {
  Future<File> generatePdfSummary(
      String filePath, Map<String, dynamic> summary) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Column(
          children: [
            pw.Text('RxMind Weekly Summary', style: pw.TextStyle(fontSize: 24)),
            pw.SizedBox(height: 16),
            pw.Text('Adherence: ${summary['adherence']}%'),
            pw.Text('Tasks Completed: ${summary['tasksCompleted']}'),
            pw.Text('Meds Taken: ${summary['medsTaken']}'),
            // ...more summary fields
          ],
        ),
      ),
    );
    final file = File(filePath);
    await file.writeAsBytes(await pdf.save());
    return file;
  }
}
