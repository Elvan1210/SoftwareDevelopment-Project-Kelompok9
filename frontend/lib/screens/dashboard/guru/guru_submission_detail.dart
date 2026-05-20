import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../models/quiz_model.dart';
import '../../../config/theme.dart';
import '../../../config/api_config.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../widgets/premium_ui.dart';

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
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          widget.submission.studentName,
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? Colors.white : AppTheme.textLight),
        ),
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: isDark ? Colors.white : AppTheme.textLight),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_aiScores != null)
            Padding(
              padding: const EdgeInsets.only(right: 8.0, top: 8, bottom: 8),
              child: PremiumElevatedButton(
                onPressed: _acceptAIScores,
                icon: LucideIcons.check,
                iconSize: 14,
                color: isDark ? const Color(0xFF1B3B2B) : const Color(0xFFE6F4EA),
                textColor: Colors.green,
                radius: 10,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: const Text('Terima & Simpan', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
              ),
            ),
          if (widget.quiz.questions.any((q) => q.questionType == 'essay'))
            Padding(
              padding: const EdgeInsets.only(right: 16.0, top: 8, bottom: 8),
              child: PremiumElevatedButton(
                onPressed: _isGradingAI ? null : _gradeWithAI,
                icon: _isGradingAI ? null : LucideIcons.sparkles,
                iconSize: 14,
                color: isDark ? const Color(0xFF2E243F) : const Color(0xFFF3E8FF),
                textColor: Colors.purple,
                radius: 10,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: _isGradingAI
                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.purple))
                    : const Text(
                        'Nilai Pakai AI',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                      ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildScoreHeader(isDark, theme),
            const SizedBox(height: 32),
            Row(
              children: [
                Text(
                  'DETAIL JAWABAN',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: isDark ? const Color(0xFF9EAAFF) : const Color(0xFF4C51BF),
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Divider(
                    color: isDark ? const Color(0xFF252D3D) : const Color(0xFFE5E7EB),
                    height: 1,
                    thickness: 1,
                  ),
                ),
              ],
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
    final isPass = percent >= 70;
    final color = isPass ? Colors.green : Colors.red;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2538) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: color.withAlpha(isDark ? 55 : 30),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 60 : 8),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF161D2B) : const Color(0xFFEEF2FF),
            borderRadius: BorderRadius.circular(19),
            border: Border.all(
              color: isDark ? const Color(0xFF2D3A54) : const Color(0xFFE5E7EB),
              width: 1.0,
            ),
          ),
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withAlpha(20),
                  border: Border.all(color: color.withAlpha(120), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: color.withAlpha(40),
                      blurRadius: 8,
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  '$percent%',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(LucideIcons.mail, size: 14, color: isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            widget.submission.studentEmail?.isNotEmpty == true ? widget.submission.studentEmail! : 'Email tidak tersedia',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Total Skor: ${widget.submission.score} / ${widget.submission.totalPoints}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : AppTheme.textLight,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: widget.submission.violations > 0 
                            ? Colors.orange.withAlpha(isDark ? 25 : 15) 
                            : Colors.green.withAlpha(isDark ? 25 : 15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: widget.submission.violations > 0 
                              ? Colors.orange.withAlpha(isDark ? 60 : 40) 
                              : Colors.green.withAlpha(isDark ? 60 : 40),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            widget.submission.violations > 0 ? LucideIcons.alertTriangle : LucideIcons.checkCircle,
                            size: 13,
                            color: widget.submission.violations > 0 ? Colors.orange : Colors.green,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${widget.submission.violations} Pelanggaran tercatat',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: widget.submission.violations > 0 ? Colors.orange : Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
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
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2538) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: (isEssay ? Colors.purple : AppTheme.indigoPrimary).withAlpha(isDark ? 55 : 30),
          width: 1.2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF161D2B) : const Color(0xFFEEF2FF),
            borderRadius: BorderRadius.circular(19),
            border: Border.all(
              color: isDark ? const Color(0xFF2D3A54) : const Color(0xFFE5E7EB),
              width: 1.0,
            ),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: (isEssay ? Colors.purple : AppTheme.indigoPrimary).withAlpha(20),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: (isEssay ? Colors.purple : AppTheme.indigoPrimary).withAlpha(80)),
                    ),
                    child: Text(
                      'Soal $index',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w900,
                        fontSize: 11,
                        color: isEssay ? Colors.purple : AppTheme.indigoPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '${q.points} Poin',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt,
                    ),
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
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : AppTheme.textLight,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              Divider(color: isDark ? const Color(0xFF2D3A54) : const Color(0xFFE5E7EB), height: 1),
              const SizedBox(height: 16),
              Text(
                'Jawaban Siswa:',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              
              if (isEssay)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF141824) : const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isDark ? const Color(0xFF222838) : const Color(0xFFE5E7EB)),
                      ),
                      child: Text(
                        studentAns?.toString() ?? 'Tidak diisi',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          height: 1.5,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : AppTheme.textLight,
                        ),
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
                                    style: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                      fontSize: 17,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              '💡 Feedback Gemini:',
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: Colors.white70,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _aiScores![q.id]['feedback'] ?? 'Tidak ada feedback.',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                color: Colors.white,
                                height: 1.6,
                                fontWeight: FontWeight.w600,
                              ),
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
        ),
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
        border: Border.all(color: isCorrect ? Colors.green.withAlpha(80) : Colors.red.withAlpha(80)),
      ),
      child: Text(
        isCorrect ? 'BENAR' : 'SALAH',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 9, 
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
          bgColor = isDark ? const Color(0xFF141824) : Colors.white;
          borderColor = isDark ? const Color(0xFF222838) : const Color(0xFFE5E7EB);
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
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: isStudentSelected || isActuallyCorrect 
                        ? (isDark ? Colors.white : AppTheme.textLight) 
                        : (isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt),
                    fontWeight: isStudentSelected ? FontWeight.w800 : FontWeight.w600,
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
