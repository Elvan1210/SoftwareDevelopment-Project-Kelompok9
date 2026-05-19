import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../../config/theme.dart';
import '../../../services/quiz_service.dart';
import '../../../models/quiz_model.dart';
import 'siswa_exam_screen.dart';
import 'package:google_fonts/google_fonts.dart';

class SiswaQuizView extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String token;
  final dynamic teamData;

  const SiswaQuizView({
    super.key, 
    required this.userData, 
    required this.token,
    required this.teamData,
  });

  @override
  State<SiswaQuizView> createState() => _SiswaQuizViewState();
}

class _SiswaQuizViewState extends State<SiswaQuizView> {
  List<Quiz> _quizzes = [];
  bool _isLoading = true;
  final Map<String, bool> _submittedMap = {};
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadQuizzes();
    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {}); 
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadQuizzes() async {
    setState(() => _isLoading = true);

    final kelasId = widget.teamData['id']?.toString() ?? '';

    final quizzes = await QuizService.getQuizzesByKelas(
      token: widget.token,
      kelasId: kelasId,
    );
    final studentId = widget.userData['id']?.toString() ??
        widget.userData['_id']?.toString() ?? '';

    for (final quiz in quizzes) {
      final submitted = await QuizService.hasSubmitted(
        token: widget.token,
        quizId: quiz.id,
        studentId: studentId,
      );
      _submittedMap[quiz.id] = submitted;
    }

    if (mounted) {
      setState(() {
        _quizzes = quizzes.where((q) => q.isActive || (q.isScheduled && q.scheduledAt != null)).toList();
        _isLoading = false;
      });
    }
  }

  void _startExam(Quiz quiz) {
    if (_submittedMap[quiz.id] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Anda sudah mengerjakan kuis ini',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
          ),
          backgroundColor: AppTheme.orangeVivid,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _ExamStartDialog(
        quiz: quiz,
        onStart: () {
          Navigator.pop(ctx);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SiswaExamScreen(
                quiz: quiz,
                userData: widget.userData,
                token: widget.token,
              ),
            ),
          ).then((_) => _loadQuizzes());
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.tealDeep))
          : _quizzes.isEmpty
              ? _buildEmptyState(theme, isDark)
              : RefreshIndicator(
                  onRefresh: _loadQuizzes,
                  color: AppTheme.indigoPrimary,
                  child: ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(24),
                    itemCount: _quizzes.length,
                    itemBuilder: (context, index) {
                      final quiz = _quizzes[index];
                      final isSubmitted = _submittedMap[quiz.id] ?? false;

                      return _QuizTile(
                        quiz: quiz,
                        isDark: isDark,
                        isSubmitted: isSubmitted,
                        onStart: () => _startExam(quiz),
                      ).animate(delay: (100 + index * 60).ms)
                        .fadeIn(duration: 400.ms)
                        .slideY(begin: 0.05, curve: Curves.easeOutQuart);
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: AppTheme.indigoPrimary.withAlpha(20),
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.indigoPrimary.withAlpha(50), width: 1.5),
            ),
            child: Icon(LucideIcons.clipboardCheck, size: 56, color: AppTheme.indigoPrimary.withAlpha(180)),
          ),
          const SizedBox(height: 24),
          Text(
            'Belum ada kuis tersedia',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w900,
              fontSize: 18,
              color: isDark ? Colors.white : AppTheme.textLight,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Kuis dari guru akan muncul di sini',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuizTile extends StatelessWidget {
  final Quiz quiz;
  final bool isDark;
  final bool isSubmitted;
  final VoidCallback onStart;

  const _QuizTile({
    required this.quiz,
    required this.isDark,
    required this.isSubmitted,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    bool isUpcoming = false;
    if (quiz.isScheduled && quiz.scheduledAt != null && !quiz.isActive) {
      if (quiz.scheduledAt!.isAfter(DateTime.now())) {
        isUpcoming = true;
      }
    }

    bool isClosed = false;
    if (quiz.closedAt != null && DateTime.now().isAfter(quiz.closedAt!)) {
      isClosed = true;
    }

    final accentColor = isSubmitted ? Colors.green : AppTheme.indigoPrimary;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2538) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: accentColor.withAlpha(isDark ? 55 : 30),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: accentColor.withAlpha(20),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: accentColor.withAlpha(80)),
                    ),
                    child: Icon(
                      isSubmitted ? LucideIcons.checkCircle : (quiz.isSecureMode ? LucideIcons.shieldCheck : LucideIcons.fileText),
                      color: accentColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          quiz.title,
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            color: isDark ? Colors.white : AppTheme.textLight,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${quiz.subject} • oleh ${quiz.createdByName}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              if (quiz.description.isNotEmpty) ...[
                const SizedBox(height: 14),
                Text(
                  quiz.description,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt,
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              const SizedBox(height: 16),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _InfoTag(icon: LucideIcons.helpCircle, label: '${quiz.questions.length} Soal', isDark: isDark, color: Colors.blue),
                  _InfoTag(icon: LucideIcons.clock, label: '${quiz.durationMinutes} Menit', isDark: isDark, color: Colors.teal),
                  _InfoTag(icon: LucideIcons.target, label: '${quiz.totalPoints} Poin', isDark: isDark, color: Colors.orange),
                  if (quiz.isSecureMode)
                    _InfoTag(icon: LucideIcons.shieldAlert, label: 'Secure Mode', isDark: isDark, color: Colors.red),
                ],
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: isClosed
                    ? OutlinedButton.icon(
                        onPressed: null,
                        icon: const Icon(LucideIcons.xCircle, size: 15),
                        label: Text(
                          'Ujian Telah Ditutup',
                          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 13),
                        ),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: isDark ? const Color(0xFF3D1B1B) : const Color(0xFFFCE8E8),
                          foregroundColor: Colors.red,
                          side: BorderSide(color: isDark ? const Color(0xFF5C2E2E) : const Color(0xFFECA3A3), width: 1.0),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      )
                    : isUpcoming
                        ? OutlinedButton.icon(
                            onPressed: null,
                            icon: const Icon(LucideIcons.calendarClock, size: 15),
                            label: Text(
                              'Tersedia: ${DateFormat('dd MMM, HH:mm').format(quiz.scheduledAt!)}',
                              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 13),
                            ),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: isDark ? const Color(0xFF3D2D1B) : const Color(0xFFFEF3C7),
                              foregroundColor: Colors.orange,
                              side: BorderSide(color: isDark ? const Color(0xFF5C472E) : const Color(0xFFFCD34D), width: 1.0),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          )
                        : isSubmitted
                            ? OutlinedButton.icon(
                                onPressed: null,
                                icon: const Icon(LucideIcons.checkCircle, size: 15),
                                label: Text(
                                  'Sudah Dikerjakan',
                                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 13),
                                ),
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: isDark ? const Color(0xFF1B3B2B) : const Color(0xFFE6F4EA),
                                  foregroundColor: Colors.green,
                                  side: BorderSide(color: isDark ? const Color(0xFF2E5C3E) : const Color(0xFF82C793), width: 1.0),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              )
                            : ElevatedButton.icon(
                                onPressed: onStart,
                                icon: const Icon(LucideIcons.play, size: 15),
                                label: Text(
                                  'Mulai Ujian',
                                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 13),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.indigoPrimary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  elevation: 0,
                                ),
                              ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoTag extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;
  final Color color;

  const _InfoTag({
    required this.icon,
    required this.label,
    required this.isDark,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withAlpha(isDark ? 25 : 15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(isDark ? 60 : 40), width: 1.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExamStartDialog extends StatelessWidget {
  final Quiz quiz;
  final VoidCallback onStart;

  const _ExamStartDialog({required this.quiz, required this.onStart});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: isDark ? const Color(0xFF161B27) : Colors.white,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: isDark ? const Color(0xFF252D3D) : const Color(0xFFE5E7EB), width: 1.2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.withAlpha(isDark ? 25 : 15),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.red.withAlpha(80), width: 1.5),
              ),
              child: const Icon(LucideIcons.shieldAlert, size: 36, color: Colors.red),
            ),
            const SizedBox(height: 20),

            Text(
              'Mulai Ujian?',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : AppTheme.textLight,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              quiz.title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppTheme.indigoPrimary,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 20),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF161D2B) : const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? const Color(0xFF252D3D) : const Color(0xFFE5E7EB), width: 1.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PERATURAN UJIAN:',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (quiz.isSecureMode) ...[
                    _rule('Aplikasi akan masuk mode fullscreen'),
                    _rule('Dilarang pindah aplikasi (Alt+Tab)'),
                    _rule('Dilarang copy, paste, dan klik kanan'),
                    _rule('Setiap pelanggaran akan dicatat'),
                  ],
                  _rule('Durasi: ${quiz.durationMinutes} menit'),
                  _rule('Jumlah soal: ${quiz.questions.length}'),
                  _rule('Jawaban akan auto-save'),
                ],
              ),
            ),

            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: isDark ? const Color(0xFF2D3A54) : const Color(0xFFF3F4F6),
                      foregroundColor: isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt,
                      side: BorderSide(color: isDark ? const Color(0xFF2E384D) : const Color(0xFFE5E7EB), width: 1.0),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('Batal', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: onStart,
                    icon: const Icon(LucideIcons.play, size: 16),
                    label: Text(
                      'Mulai Sekarang',
                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 13),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.indigoPrimary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _rule(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.red)),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                color: Colors.red.withAlpha(200),
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
