import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../../config/theme.dart';
import '../../../services/quiz_service.dart';
import '../../../models/quiz_model.dart';
import 'siswa_exam_screen.dart';

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
          content: const Text('Anda sudah mengerjakan kuis ini'),
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
              ? _buildEmptyState(theme)
              : RefreshIndicator(
                  onRefresh: _loadQuizzes,
                  child: ListView.builder(
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

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: AppTheme.tealDeep.withAlpha(20),
              shape: BoxShape.circle,
            ),
            child: Icon(LucideIcons.clipboardCheck, size: 56, color: AppTheme.tealDeep.withAlpha(180)),
          ),
          const SizedBox(height: 24),
          Text(
            'Belum ada kuis tersedia',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: theme.colorScheme.onSurface.withAlpha(170),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Kuis dari guru akan muncul di sini',
            style: TextStyle(
              fontSize: 14,
              color: theme.colorScheme.onSurface.withAlpha(120),
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
    final theme = Theme.of(context);
    
    bool isUpcoming = false;
    if (quiz.isScheduled && quiz.scheduledAt != null && !quiz.isActive) {
      if (quiz.scheduledAt!.isAfter(DateTime.now())) {
        isUpcoming = true;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withAlpha(isDark ? 200 : 255),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSubmitted
              ? Colors.green.withAlpha(40)
              : (isDark ? Colors.white.withAlpha(15) : Colors.black.withAlpha(8)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 60 : 8),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isSubmitted
                          ? [Colors.green.withAlpha(30), Colors.green.withAlpha(15)]
                          : [AppTheme.tealDeep.withAlpha(30), AppTheme.tealDeep.withAlpha(15)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    isSubmitted ? LucideIcons.checkCircle : (quiz.isSecureMode ? LucideIcons.shieldCheck : LucideIcons.fileText),
                    color: isSubmitted ? Colors.green : AppTheme.tealDeep,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        quiz.title,
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 17,
                          color: theme.colorScheme.onSurface,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${quiz.subject} • oleh ${quiz.createdByName}',
                        style: TextStyle(
                          fontSize: 13,
                          color: theme.colorScheme.onSurface.withAlpha(120),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            if (quiz.description.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                quiz.description,
                style: TextStyle(
                  fontSize: 13,
                  color: theme.colorScheme.onSurface.withAlpha(150),
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            const SizedBox(height: 16),

            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: [
                _InfoTag(icon: LucideIcons.helpCircle, label: '${quiz.questions.length} Soal', isDark: isDark),
                _InfoTag(icon: LucideIcons.clock, label: '${quiz.durationMinutes} Menit', isDark: isDark),
                _InfoTag(icon: LucideIcons.target, label: '${quiz.totalPoints} Poin', isDark: isDark),
                if (quiz.isSecureMode)
                  _InfoTag(icon: LucideIcons.lock, label: 'Secure', isDark: isDark, color: Colors.red),
              ],
            ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: isUpcoming
                  ? Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.orange.withAlpha(20),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.orange.withAlpha(40)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(LucideIcons.calendarClock, size: 18, color: Colors.orange),
                          const SizedBox(width: 8),
                          Text(
                            'Tersedia pada: ${DateFormat('dd MMM yyyy, HH:mm').format(quiz.scheduledAt!)}',
                            style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.orange),
                          ),
                        ],
                      ),
                    )
                  : ElevatedButton.icon(
                      onPressed: isSubmitted ? null : onStart,
                      icon: Icon(
                        isSubmitted ? LucideIcons.checkCircle : LucideIcons.play,
                        size: 18,
                      ),
                      label: Text(
                        isSubmitted ? 'Sudah Dikerjakan' : 'Mulai Ujian',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isSubmitted ? Colors.green.withAlpha(40) : AppTheme.tealDeep,
                        foregroundColor: isSubmitted ? Colors.green : Colors.white,
                        disabledBackgroundColor: Colors.green.withAlpha(isDark ? 30 : 15),
                        disabledForegroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoTag extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;
  final Color? color;

  const _InfoTag({required this.icon, required this.label, required this.isDark, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.onSurface.withAlpha(140);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: c),
        const SizedBox(width: 5),
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: c)),
      ],
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
      backgroundColor: theme.colorScheme.surface,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.tealDeep.withAlpha(30), AppTheme.orangeVivid.withAlpha(15)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.shieldAlert, size: 40, color: AppTheme.tealDeep),
            ),
            const SizedBox(height: 20),

            Text(
              'Mulai Ujian?',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: theme.colorScheme.onSurface,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              quiz.title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppTheme.tealDeep,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withAlpha(isDark ? 15 : 8),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.red.withAlpha(30)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'PERATURAN UJIAN:',
                    style: TextStyle(
                      fontSize: 11,
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
                    _rule('Max ${quiz.maxViolations} pelanggaran → auto submit'),
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
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      side: BorderSide(color: theme.colorScheme.onSurface.withAlpha(40)),
                    ),
                    child: const Text('Batal', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: onStart,
                    icon: const Icon(LucideIcons.play, size: 18),
                    label: const Text('Mulai Sekarang', style: TextStyle(fontWeight: FontWeight.w800)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.tealDeep,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
              style: TextStyle(fontSize: 13, color: Colors.red.withAlpha(200), height: 1.3),
            ),
          ),
        ],
      ),
    );
  }
}
