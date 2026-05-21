import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
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
        widget.userData['_id']?.toString() ??
        '';

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
        _quizzes = quizzes
            .where(
                (q) => q.isActive || (q.isScheduled && q.scheduledAt != null))
            .toList();
        _isLoading = false;
      });
    }
  }

  void _startExam(Quiz quiz) {
    if (_submittedMap[quiz.id] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Anda sudah mengerjakan kuis ini',
            style: TextStyle(fontWeight: FontWeight.w700)),
          backgroundColor: AppTheme.orangeVivid,
          behavior: SnackBarBehavior.floating,
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
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.success))
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
                      )
                          .animate(delay: (100 + index * 60).ms)
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
              border: Border.all(
                  color: AppTheme.indigoPrimary.withAlpha(50), width: 1.5),
            ),
            child: Icon(LucideIcons.clipboardCheck,
                size: 56, color: AppTheme.indigoPrimary.withAlpha(180)),
          ),
          const SizedBox(height: 24),
          Text(
            'Belum ada kuis tersedia',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : AppTheme.textLight),
          ),
          const SizedBox(height: 8),
          Text(
            'Kuis dari guru akan muncul di sini',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt),
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

    final accentColor = isSubmitted ? AppTheme.success : AppTheme.indigoPrimary;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(color: Theme.of(context).colorScheme.onSurface, width: 2),
        boxShadow: [BoxShadow(color: Theme.of(context).colorScheme.onSurface, offset: const Offset(4, 4), blurRadius: 0)],
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
                  color: accentColor,
                  border: Border.all(color: Theme.of(context).colorScheme.onSurface, width: 1.5),
                  boxShadow: [BoxShadow(color: Theme.of(context).colorScheme.onSurface, offset: const Offset(2, 2), blurRadius: 0)],
                ),
                child: Icon(
                  isSubmitted ? LucideIcons.checkCircle : (quiz.isSecureMode ? LucideIcons.shieldCheck : LucideIcons.fileText),
                  color: Colors.white, size: 22,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      quiz.title,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: Theme.of(context).textTheme.bodyLarge!.color!,
                          letterSpacing: -0.3),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${quiz.subject} • oleh ${quiz.createdByName}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).textTheme.bodyMedium!.color!),
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
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).textTheme.bodyMedium!.color!,
                  height: 1.45, fontWeight: FontWeight.w500),
              maxLines: 2, overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 16),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: [
              _InfoTag(icon: LucideIcons.helpCircle, label: '${quiz.questions.length} Soal', color: AppTheme.info),
              _InfoTag(icon: LucideIcons.clock, label: '${quiz.durationMinutes} Menit', color: AppTheme.primary),
              _InfoTag(icon: LucideIcons.target, label: '${quiz.totalPoints} Poin', color: AppTheme.warning),
              if (quiz.isSecureMode)
                const _InfoTag(icon: LucideIcons.shieldAlert, label: 'Secure Mode', color: AppTheme.error),
            ],
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: isClosed || isUpcoming || isSubmitted ? null : onStart,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isClosed ? Theme.of(context).colorScheme.surface
                    : isUpcoming ? AppTheme.warning
                    : isSubmitted ? AppTheme.success
                    : AppTheme.indigoPrimary,
                border: Border.all(color: Theme.of(context).colorScheme.onSurface, width: 1.5),
                boxShadow: isClosed || isUpcoming || isSubmitted ? [] :
                  [BoxShadow(color: Theme.of(context).colorScheme.onSurface, offset: const Offset(3, 3), blurRadius: 0)],
              ),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(
                  isClosed ? LucideIcons.xCircle
                      : isUpcoming ? LucideIcons.calendarClock
                      : isSubmitted ? LucideIcons.checkCircle
                      : LucideIcons.play,
                  size: 15,
                  color: isClosed ? Theme.of(context).textTheme.bodyMedium!.color! : Colors.white,
                ),
                const SizedBox(width: 8),
                Text(
                  isClosed ? 'UJIAN TELAH DITUTUP'
                      : isUpcoming ? 'TERSEDIA: ${DateFormat('dd MMM, HH:mm').format(quiz.scheduledAt!)}'
                      : isSubmitted ? 'SUDAH DIKERJAKAN'
                      : 'MULAI UJIAN',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w900, letterSpacing: 0.5,
                    color: isClosed ? Theme.of(context).textTheme.bodyMedium!.color! : Colors.white,
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoTag extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoTag({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: Theme.of(context).colorScheme.onSurface, width: 1.5),
        boxShadow: [BoxShadow(color: Theme.of(context).colorScheme.onSurface, offset: const Offset(2, 2), blurRadius: 0)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900, color: Colors.white),
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

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border.all(color: theme.colorScheme.onSurface, width: 2),
          boxShadow: [BoxShadow(color: theme.colorScheme.onSurface, offset: const Offset(6, 6))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              color: AppTheme.error,
              child: Row(children: [
                const Icon(LucideIcons.shieldAlert, size: 24, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('MULAI UJIAN?', style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.5)),
                      Text(quiz.title, style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700, color: Colors.white.withAlpha(200)),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ]),
            ),
            // Rules
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: theme.colorScheme.onSurface, width: 2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('PERATURAN UJIAN:', style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w900, letterSpacing: 0.5, color: AppTheme.error)),
                  const SizedBox(height: 10),
                  if (quiz.isSecureMode) ...[
                    _rule(context, 'Aplikasi akan masuk mode fullscreen'),
                    _rule(context, 'Dilarang pindah aplikasi (Alt+Tab)'),
                    _rule(context, 'Dilarang copy, paste, dan klik kanan'),
                    _rule(context, 'Setiap pelanggaran akan dicatat'),
                  ],
                  _rule(context, 'Durasi: ${quiz.durationMinutes} menit'),
                  _rule(context, 'Jumlah soal: ${quiz.questions.length}'),
                  _rule(context, 'Jawaban akan auto-save'),
                ],
              ),
            ),
            // Actions
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: theme.colorScheme.onSurface, width: 1.5),
                        boxShadow: [BoxShadow(color: theme.colorScheme.onSurface, offset: const Offset(2, 2))],
                      ),
                      child: Center(child: Text('BATAL', style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w900, color: theme.textTheme.bodyLarge!.color!))),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: GestureDetector(
                    onTap: onStart,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.indigoPrimary,
                        border: Border.all(color: theme.colorScheme.onSurface, width: 1.5),
                        boxShadow: [BoxShadow(color: theme.colorScheme.onSurface, offset: const Offset(3, 3))],
                      ),
                      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        const Icon(LucideIcons.play, size: 16, color: Colors.white),
                        const SizedBox(width: 8),
                        Text('MULAI SEKARANG', style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w900, color: Colors.white)),
                      ]),
                    ),
                  ),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _rule(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.error)),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.error.withAlpha(200),
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
