import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import '../models/course_model.dart';

class PdfService {
  static Future<File> generateAssignmentReport(List<Assignment> assignments) async {
    final pdf = pw.Document();
    
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Text('Assignment Report', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
            ),
            pw.SizedBox(height: 20),
            pw.Text('Generated on: ${DateTime.now().toString().split('.')[0]}'),
            pw.SizedBox(height: 20),
            pw.Table.fromTextArray(
              headers: ['Title', 'Due Date', 'Status', 'Marks'],
              data: assignments.map((assignment) => [
                assignment.title,
                assignment.dueDate.toString().split(' ')[0],
                assignment.status.toUpperCase(),
                '${assignment.totalMarks}',
              ]).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              cellAlignment: pw.Alignment.centerLeft,
            ),
          ];
        },
      ),
    );
    
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/assignment_report.pdf');
    await file.writeAsBytes(await pdf.save());
    
    return file;
  }
  
  static Future<File> generateProgressReport(Map<String, dynamic> stats) async {
    final pdf = pw.Document();
    
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Progress Report', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 20),
              pw.Text('Generated on: ${DateTime.now().toString().split('.')[0]}'),
              pw.SizedBox(height: 30),
              pw.Text('Statistics:', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Text('Enrolled Courses: ${stats['enrolled'] ?? 0}'),
              pw.Text('Completed Courses: ${stats['completed'] ?? 0}'),
              pw.Text('Total Study Hours: ${stats['hours'] ?? 0}'),
              pw.SizedBox(height: 20),
              pw.Text('Performance Summary:', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Text('You are making great progress in your learning journey!'),
            ],
          );
        },
      ),
    );
    
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/progress_report.pdf');
    await file.writeAsBytes(await pdf.save());
    
    return file;
  }
}