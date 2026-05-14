// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
//import 'dart:html' as html;
import 'package:flutter/foundation.dart';
import '../models/quiz_model.dart';
import 'package:intl/intl.dart';

class ExportService {
  static Future<void> exportSubmissionsToCsv(List<QuizSubmission> submissions, String quizTitle) async {
    if (!kIsWeb) {
      debugPrint('Export CSV saat ini hanya didukung di Web');
      return;
    }

    try {
      final List<List<String>> rows = [];
      rows.add([
        'No',
        'Nama Siswa',
        'Skor',
        'Total Poin',
        'Persentase',
        'Pelanggaran',
        'Auto Submit',
        'Waktu Submit'
      ]);

      int index = 1;
      for (var sub in submissions) {
        final pct = sub.totalPoints > 0 ? ((sub.score / sub.totalPoints) * 100).round() : 0;
        final dateFormatted = DateFormat('dd MMM yyyy, HH:mm').format(sub.submittedAt.toLocal());
        
        rows.add([
          index.toString(),
          '"${sub.studentName.replaceAll('"', '""')}"',
          sub.score.toString(),
          sub.totalPoints.toString(),
          '$pct%',
          sub.violations.toString(),
          sub.autoSubmitted ? 'Ya' : 'Tidak',
          '"$dateFormatted"'
        ]);
        index++;
      }

      final String csvData = rows.map((row) => row.join(',')).join('\n');
      // final bytes = html.Blob([csvData], 'text/csv;charset=utf-8;');
      // final url = html.Url.createObjectUrlFromBlob(bytes);
      
      final safeTitle = quizTitle.replaceAll(RegExp(r'[^\w\s]+'), '').trim().replaceAll(' ', '_');
      final fileName = 'Nilai_${safeTitle}_${DateFormat('yyyyMMdd').format(DateTime.now())}.csv';

      // html.AnchorElement(href: url)
      //   ..setAttribute('download', fileName)
      //   ..click();
        
      //  html.Url.revokeObjectUrl(url);
    } catch (e) {
      debugPrint('Export error: $e');
    }
  }
}
