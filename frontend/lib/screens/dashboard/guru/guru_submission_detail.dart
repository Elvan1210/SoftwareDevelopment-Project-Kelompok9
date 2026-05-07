import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../models/quiz_model.dart';
import '../../../config/theme.dart';

class GuruSubmissionDetail extends StatelessWidget {
  final QuizSubmission submission;
  final Quiz quiz;

  const GuruSubmissionDetail({
    super.key,
    required this.submission,
    required this.quiz,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(submission.studentName),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildScoreHeader(isDark, theme),
            const SizedBox(height: 30),
            const Text(
              'Detail Jawaban',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 16),
            ...List.generate(quiz.questions.length, (index) {
              final q = quiz.questions[index];
              return _buildQuestionCard(q, index + 1, theme, isDark);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreHeader(bool isDark, ThemeData theme) {
    final percent = submission.totalPoints > 0
        ? (submission.score / submission.totalPoints * 100).round()
        : 0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: percent >= 70
            ? Colors.green.withAlpha(isDark ? 30 : 20)
            : Colors.red.withAlpha(isDark ? 30 : 20),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: percent >= 70 ? Colors.green.withAlpha(50) : Colors.red.withAlpha(50),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 35,
            backgroundColor: percent >= 70 ? Colors.green : Colors.red,
            child: Text(
              '$percent%',
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  submission.studentEmail?.isNotEmpty == true ? submission.studentEmail! : 'Email tidak tersedia',
                  style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurface.withAlpha(150)),
                ),
                const SizedBox(height: 8),
                Text(
                  'Total Skor: ${submission.score} / ${submission.totalPoints}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(LucideIcons.alertTriangle, size: 16, color: Colors.orange),
                    const SizedBox(width: 6),
                    Text(
                      '${submission.violations} Pelanggaran tercatat',
                      style: const TextStyle(fontSize: 13, color: Colors.orange),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(QuizQuestion q, int index, ThemeData theme, bool isDark) {
    bool isEssay = q.questionType == 'essay';
    dynamic studentAns = isEssay
        ? submission.essayAnswers[q.id]
        : submission.answers[q.id];

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withAlpha(isDark ? 150 : 255),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.onSurface.withAlpha(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.tealDeep.withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Soal $index',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.tealDeep),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${q.points} Poin',
                style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withAlpha(150)),
              ),
              const Spacer(),
              if (!isEssay) _buildStatusBadge(q, studentAns),
            ],
          ),
          const SizedBox(height: 16),
          if (q.imageUrl != null) ...[
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(q.imageUrl!, fit: BoxFit.contain),
              ),
            ),
            const SizedBox(height: 16),
          ],
          Text(
            q.question,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, height: 1.5),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          const Text('Jawaban Siswa:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          
          if (isEssay)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withAlpha(isDark ? 200 : 255),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.tealDeep.withAlpha(100)),
              ),
              child: Text(
                studentAns?.toString() ?? 'Tidak diisi',
                style: const TextStyle(fontSize: 14, height: 1.5),
              ),
            )
          else ...[
            _renderObjectiveAnswers(q, studentAns, theme, isDark),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusBadge(QuizQuestion q, dynamic studentAns) {
    bool isCorrect = false;
    if (q.questionType == 'multipleChoice') {
      int correct = q.correctAnswers.isNotEmpty ? q.correctAnswers.first : 0;
      isCorrect = studentAns == correct;
    } else if (q.questionType == 'multipleAnswer') {
      isCorrect = studentAns is int && q.correctAnswers.contains(studentAns);
    } else {
      List<int> sAns = studentAns is List ? List<int>.from(studentAns) : [];
      List<int> cAns = List.from(q.correctAnswers);
      sAns.sort();
      cAns.sort();
      isCorrect = sAns.length == cAns.length && 
                  sAns.asMap().entries.every((e) => e.value == cAns[e.key]);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isCorrect ? Colors.green.withAlpha(20) : Colors.red.withAlpha(20),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        isCorrect ? 'BENAR' : 'SALAH',
        style: TextStyle(
          fontSize: 10, 
          fontWeight: FontWeight.w900, 
          color: isCorrect ? Colors.green : Colors.red,
        ),
      ),
    );
  }

  Widget _renderObjectiveAnswers(QuizQuestion q, dynamic studentAns, ThemeData theme, bool isDark) {
    List<int> sAns = [];
    if (studentAns is int) sAns = [studentAns];
    if (studentAns is List) sAns = List<int>.from(studentAns);

    List<int> cAns = q.questionType == 'multipleChoice' 
        ? [q.correctAnswers.isNotEmpty ? q.correctAnswers.first : 0]
        : List.from(q.correctAnswers);

    return Column(
      children: List.generate(q.options.length, (i) {
        bool isStudentSelected = sAns.contains(i);
        bool isActuallyCorrect = cAns.contains(i);

        Color? bgColor;
        Color? borderColor;
        IconData? icon;

        if (isActuallyCorrect && isStudentSelected) {
          bgColor = Colors.green.withAlpha(20);
          borderColor = Colors.green;
          icon = LucideIcons.checkCircle;
        } else if (isActuallyCorrect && !isStudentSelected) {
          bgColor = Colors.green.withAlpha(10);
          borderColor = Colors.green.withAlpha(50);
          icon = LucideIcons.check;
        } else if (!isActuallyCorrect && isStudentSelected) {
          bgColor = Colors.red.withAlpha(20);
          borderColor = Colors.red;
          icon = LucideIcons.xCircle;
        } else {
          bgColor = theme.colorScheme.surface.withAlpha(isDark ? 200 : 255);
          borderColor = theme.colorScheme.onSurface.withAlpha(20);
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: borderColor),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Text(
                  q.options[i],
                  style: TextStyle(
                    fontSize: 14,
                    color: isStudentSelected || isActuallyCorrect 
                        ? theme.colorScheme.onSurface 
                        : theme.colorScheme.onSurface.withAlpha(150),
                    fontWeight: isStudentSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
