import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../models/quiz_model.dart';
import '../../../config/theme.dart';
import '../../../config/api_config.dart';

class GuruSubmissionDetail extends StatefulWidget {
  final QuizSubmission submission;
  final Quiz quiz;
  final String token;

  const GuruSubmissionDetail({
    super.key,
    required this.submission,
    required this.quiz,
    required this.token,
  });

  @override
  State<GuruSubmissionDetail> createState() => _GuruSubmissionDetailState();
}

class _GuruSubmissionDetailState extends State<GuruSubmissionDetail> {
  Map<String, dynamic>? _aiScores;
  bool _isGradingAI = false;

  Future<void> _gradeWithAI() async {
    setState(() => _isGradingAI = true);
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/api/quiz/submissions/${widget.submission.id}/ai-grade'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          _aiScores = data['suggestedScores'];
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Berhasil menilai dengan AI!'), backgroundColor: Colors.green),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal menilai dengan AI.'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      debugPrint('AI Grading Error: $e');
    } finally {
      setState(() => _isGradingAI = false);
    }
  }
  Future<void> _acceptAIScores() async {
    if (_aiScores == null) return;
    
    final formattedScores = {};
    _aiScores!.forEach((k, v) {
      formattedScores[k] = v['score'];
    });

    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/quiz/submissions/${widget.submission.id}/grade-essay'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
        body: jsonEncode({'essayScores': formattedScores}),
      );

      if (res.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Nilai AI berhasil disimpan!'), backgroundColor: Colors.green),
          );
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      debugPrint('Error saving AI scores: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.submission.studentName),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (_aiScores != null)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: ElevatedButton.icon(
                onPressed: _acceptAIScores,
                icon: const Icon(LucideIcons.check, size: 16),
                label: const Text('Terima & Simpan', style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          if (widget.quiz.questions.any((q) => q.questionType == 'essay'))
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: ElevatedButton.icon(
                onPressed: _isGradingAI ? null : _gradeWithAI,
                icon: _isGradingAI
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(LucideIcons.sparkles, size: 16),
                label: const Text('Nilai Pakai AI', style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.tealDeep,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
        ],
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
            ...List.generate(widget.quiz.questions.length, (index) {
              final q = widget.quiz.questions[index];
              return _buildQuestionCard(q, index + 1, theme, isDark);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreHeader(bool isDark, ThemeData theme) {
    final percent = widget.submission.totalPoints > 0
        ? (widget.submission.score / widget.submission.totalPoints * 100).round()
        : 0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: percent >= 70
            ? Colors.green.withAlpha(isDark ? 30 : 20)
            : Colors.red.withAlpha(isDark ? 30 : 20),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: percent >= 70 ? Colors.green.withAlpha(160) : Colors.red.withAlpha(160),
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
                  widget.submission.studentEmail?.isNotEmpty == true ? widget.submission.studentEmail! : 'Email tidak tersedia',
                  style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurface.withAlpha(160)),
                ),
                const SizedBox(height: 8),
                Text(
                  'Total Skor: ${widget.submission.score} / ${widget.submission.totalPoints}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(LucideIcons.alertTriangle, size: 16, color: Colors.orange),
                    const SizedBox(width: 6),
                    Text(
                      '${widget.submission.violations} Pelanggaran tercatat',
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
        ? widget.submission.essayAnswers[q.id]
        : widget.submission.answers[q.id];

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
                style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withAlpha(160)),
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                ),
                if (_aiScores != null && _aiScores![q.id] != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF5B247A), Color(0xFF1BCEDF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(color: const Color(0xFF1BCEDF).withAlpha(80), blurRadius: 16, offset: const Offset(0, 8)),
                        BoxShadow(color: Colors.purpleAccent.withAlpha(60), blurRadius: 4, spreadRadius: 1),
                      ],
                      border: Border.all(color: Colors.white.withAlpha(100), width: 1.5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.auto_awesome, color: Colors.amberAccent, size: 28)
                              .animate(onPlay: (c) => c.repeat())
                              .shimmer(duration: const Duration(seconds: 2), color: Colors.white)
                              .scaleXY(begin: 0.9, end: 1.1, duration: const Duration(seconds: 1), curve: Curves.easeInOut)
                              .then().scaleXY(begin: 1.1, end: 0.9, duration: const Duration(seconds: 1), curve: Curves.easeInOut),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Saran Nilai AI: ${_aiScores![q.id]['score']} / ${q.points}',
                                style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 18, letterSpacing: 0.5),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Text('💡 Feedback Gemini:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white70)),
                        const SizedBox(height: 6),
                        Text(
                          _aiScores![q.id]['feedback'] ?? 'Tidak ada feedback.',
                          style: const TextStyle(fontSize: 14, color: Colors.white, height: 1.6, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: const Duration(milliseconds: 400)).slideY(begin: 0.1, curve: Curves.easeOutBack)
                   .shimmer(duration: const Duration(seconds: 3), color: Colors.white.withAlpha(40)),
                ],
              ],
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
          borderColor = Colors.green.withAlpha(160);
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
                        : theme.colorScheme.onSurface.withAlpha(160),
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
