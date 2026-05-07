import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../../config/theme.dart';
import '../../../services/quiz_service.dart';
import '../../../services/export_service.dart';
import '../../../models/quiz_model.dart';
import 'guru_quiz_create_screen.dart';

class GuruQuizView extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String token;
  final dynamic teamData;

  const GuruQuizView({
    super.key, 
    required this.userData, 
    required this.token,
    required this.teamData,
  });

  @override
  State<GuruQuizView> createState() => _GuruQuizViewState();
}

class _GuruQuizViewState extends State<GuruQuizView> {
  List<Quiz> _quizzes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadQuizzes();
  }

  Future<void> _loadQuizzes() async {
    setState(() => _isLoading = true);
    final quizzes = await QuizService.getQuizzesByKelas(
      token: widget.token,
      kelasId: widget.teamData['id']?.toString() ?? '',
    );
    if (mounted) {
      setState(() {
        _quizzes = quizzes;
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteQuiz(String quizId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus Kuis?', style: TextStyle(fontWeight: FontWeight.w900)),
        content: const Text('Kuis dan semua jawaban siswa akan dihapus permanen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Hapus', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await QuizService.deleteQuiz(token: widget.token, quizId: quizId);
      _loadQuizzes();
    }
  }

  void _navigateToCreate() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GuruQuizCreateScreen(
          userData: widget.userData,
          token: widget.token,
          teamData: widget.teamData,
        ),
      ),
    );
    if (result == true) _loadQuizzes();
  }

  void _navigateToEdit(Quiz quiz) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GuruQuizCreateScreen(
          userData: widget.userData,
          token: widget.token,
          teamData: widget.teamData,
          existingQuiz: quiz,
        ),
      ),
    );
    if (result == true) _loadQuizzes();
  }

  void _viewSubmissions(Quiz quiz) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _SubmissionsSheet(quiz: quiz, token: widget.token, kelasId: widget.teamData['id']?.toString() ?? ''),
    );
  }

  void _copyShareCode(Quiz quiz) {
    if (quiz.shareCode != null) {
      Clipboard.setData(ClipboardData(text: quiz.shareCode!));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kode Share Kuis berhasil disalin! Bagikan ke kelas lain.'), backgroundColor: Colors.green),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kode Share tidak tersedia untuk kuis ini.'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToCreate,
        backgroundColor: AppTheme.tealDeep,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
        icon: const Icon(LucideIcons.plus),
        label: const Text('Buat Kuis', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
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
                      return _QuizCard(
                        quiz: _quizzes[index],
                        isDark: isDark,
                        onEdit: () => _navigateToEdit(_quizzes[index]),
                        onDelete: () => _deleteQuiz(_quizzes[index].id),
                        onViewSubmissions: () => _viewSubmissions(_quizzes[index]),
                        onShare: () => _copyShareCode(_quizzes[index]),
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
            child: Icon(LucideIcons.clipboardList, size: 56, color: AppTheme.tealDeep.withAlpha(180)),
          ),
          const SizedBox(height: 24),
          Text(
            'Belum ada kuis',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: theme.colorScheme.onSurface.withAlpha(170),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Buat kuis pertama untuk ujian siswa',
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

class _QuizCard extends StatelessWidget {
  final Quiz quiz;
  final bool isDark;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onViewSubmissions;
  final VoidCallback onShare;

  const _QuizCard({
    required this.quiz,
    required this.isDark,
    required this.onEdit,
    required this.onDelete,
    required this.onViewSubmissions,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withAlpha(isDark ? 200 : 255),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white.withAlpha(15) : Colors.black.withAlpha(8),
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
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.tealDeep.withAlpha(isDark ? 40 : 20),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    quiz.isSecureMode ? LucideIcons.shieldCheck : LucideIcons.clipboardList,
                    color: AppTheme.tealDeep,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        quiz.title,
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          color: theme.colorScheme.onSurface,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        quiz.description,
                        style: TextStyle(
                          fontSize: 13,
                          color: theme.colorScheme.onSurface.withAlpha(140),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (quiz.isScheduled)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.withAlpha(isDark ? 40 : 20),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.withAlpha(80)),
                    ),
                    child: Text(
                      'TERJADWAL',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: Colors.orange,
                        letterSpacing: 0.5,
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: quiz.isActive
                          ? Colors.green.withAlpha(isDark ? 40 : 20)
                          : Colors.grey.withAlpha(isDark ? 40 : 20),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: quiz.isActive ? Colors.green.withAlpha(80) : Colors.grey.withAlpha(60),
                      ),
                    ),
                    child: Text(
                      quiz.isActive ? 'AKTIF' : 'NONAKTIF',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: quiz.isActive ? Colors.green : Colors.grey,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 16),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _InfoChip(
                  icon: LucideIcons.helpCircle,
                  label: '${quiz.questions.length} Soal',
                  color: AppTheme.orangeVivid,
                  isDark: isDark,
                ),
                _InfoChip(
                  icon: LucideIcons.clock,
                  label: '${quiz.durationMinutes} Menit',
                  color: AppTheme.tealLight,
                  isDark: isDark,
                ),
                if (quiz.isScheduled && quiz.scheduledAt != null)
                  _InfoChip(
                    icon: LucideIcons.calendarClock,
                    label: DateFormat('dd MMM, HH:mm').format(quiz.scheduledAt!),
                    color: Colors.orange,
                    isDark: isDark,
                  ),
                if (quiz.isSecureMode)
                  _InfoChip(
                    icon: LucideIcons.lock,
                    label: 'Secure Mode',
                    color: AppTheme.tealDeep,
                    isDark: isDark,
                  ),
              ],
            ),

            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),

            Row(
              children: [
                _ActionBtn(
                  icon: LucideIcons.barChart2,
                  label: 'Hasil',
                  onTap: onViewSubmissions,
                  color: AppTheme.tealDeep,
                ),
                const SizedBox(width: 8),
                _ActionBtn(
                  icon: LucideIcons.share2,
                  label: 'Share',
                  onTap: onShare,
                  color: Colors.blue,
                ),
                const Spacer(),
                _ActionBtn(
                  icon: LucideIcons.edit3,
                  label: 'Edit',
                  onTap: onEdit,
                  color: AppTheme.orangeVivid,
                ),
                const SizedBox(width: 8),
                _ActionBtn(
                  icon: LucideIcons.trash2,
                  label: 'Hapus',
                  onTap: onDelete,
                  color: Colors.red,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isDark;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withAlpha(isDark ? 25 : 12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(isDark ? 50 : 30)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withAlpha(15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withAlpha(40)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color),
            ),
          ],
        ),
      ),
    );
  }
}

class _SubmissionsSheet extends StatefulWidget {
  final Quiz quiz;
  final String token;
  final String kelasId;

  const _SubmissionsSheet({required this.quiz, required this.token, required this.kelasId});

  @override
  State<_SubmissionsSheet> createState() => _SubmissionsSheetState();
}

class _SubmissionsSheetState extends State<_SubmissionsSheet> {
  List<QuizSubmission> _submissions = [];
  bool _isLoading = true;
  bool _filterByKelas = true;

  @override
  void initState() {
    super.initState();
    _loadSubmissions();
  }

  Future<void> _loadSubmissions() async {
    setState(() => _isLoading = true);
    final subs = await QuizService.getSubmissions(
      token: widget.token,
      quizId: widget.quiz.id,
      kelasId: _filterByKelas ? widget.kelasId : null,
    );
    if (mounted) {
      setState(() {
        _submissions = subs;
        _isLoading = false;
      });
    }
  }

  void _exportCsv() {
    if (_submissions.isEmpty) return;
    ExportService.exportSubmissionsToCsv(_submissions, widget.quiz.title);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withAlpha(50),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Icon(LucideIcons.barChart2, color: AppTheme.tealDeep, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Hasil: ${widget.quiz.title}',
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TextButton.icon(
                  onPressed: _exportCsv,
                  icon: const Icon(LucideIcons.download, size: 16),
                  label: const Text('Export CSV'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.tealDeep,
                    backgroundColor: AppTheme.tealDeep.withAlpha(20),
                  ),
                ),
              ],
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Checkbox(
                  value: _filterByKelas,
                  onChanged: (val) {
                    setState(() => _filterByKelas = val ?? true);
                    _loadSubmissions();
                  },
                ),
                Text('Hanya tampilkan siswa di kelas ini', style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface.withAlpha(150))),
              ],
            ),
          ),
          
          const Divider(height: 1),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.tealDeep))
                : _submissions.isEmpty
                    ? Center(
                        child: Text(
                          'Belum ada siswa yang mengerjakan',
                          style: TextStyle(
                            color: theme.colorScheme.onSurface.withAlpha(140),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _submissions.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (ctx, i) {
                          final sub = _submissions[i];
                          final scorePercent = sub.totalPoints > 0
                              ? (sub.score / sub.totalPoints * 100).round()
                              : 0;

                          return ListTile(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            tileColor: theme.colorScheme.surface.withAlpha(isDark ? 180 : 255),
                            leading: CircleAvatar(
                              backgroundColor: scorePercent >= 70
                                  ? Colors.green.withAlpha(30)
                                  : Colors.red.withAlpha(30),
                              child: Text(
                                '$scorePercent%',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  color: scorePercent >= 70 ? Colors.green : Colors.red,
                                ),
                              ),
                            ),
                            title: Text(
                              sub.studentName,
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            subtitle: Text(
                              'Skor: ${sub.score}/${sub.totalPoints} • Pelanggaran: ${sub.violations}',
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.onSurface.withAlpha(140),
                              ),
                            ),
                            trailing: sub.autoSubmitted
                                ? Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withAlpha(20),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      'AUTO',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.red,
                                      ),
                                    ),
                                  )
                                : null,
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
