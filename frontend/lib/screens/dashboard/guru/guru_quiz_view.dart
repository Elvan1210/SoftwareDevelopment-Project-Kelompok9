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
import 'guru_submission_detail.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../widgets/app_shell.dart';

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

  void _openLiveMonitor(Quiz quiz) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _LiveMonitorSheet(quiz: quiz, token: widget.token),
    );
  }

  void _copyShareCode(Quiz quiz) {
    if (quiz.shareCode != null) {
      Clipboard.setData(ClipboardData(text: quiz.shareCode!));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kode Share Kuis berhasil disalin! Bagikan ke guru/kelas lain.'), backgroundColor: Colors.green),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kode Share tidak tersedia untuk kuis ini.'), backgroundColor: Colors.red),
      );
    }
  }

  void _showImportDialog() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Tarik Kuis (Import)', style: TextStyle(fontWeight: FontWeight.w900)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Masukkan Kode Share kuis yang ingin Anda tarik ke kelas ini.', style: TextStyle(fontSize: 13)),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
              decoration: InputDecoration(
                hintText: 'Contoh: A1B2C3D4',
                filled: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              textCapitalization: TextCapitalization.characters,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              final code = ctrl.text.trim().toUpperCase();
              if (code.isEmpty) return;
              Navigator.pop(ctx);
              _importQuiz(code);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.tealDeep,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Import', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _importQuiz(String code) async {
    setState(() => _isLoading = true);
    final quiz = await QuizService.joinByCode(token: widget.token, shareCode: code);
    
    if (quiz == null) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kuis tidak ditemukan atau kode salah'), backgroundColor: Colors.red),
        );
      }
      return;
    }

    // Clone it!
    final quizData = quiz.toJson();
    quizData.remove('id');
    quizData.remove('_id');
    quizData['kelasId'] = widget.teamData['id']?.toString() ?? '';
    quizData['createdBy'] = widget.userData['id']?.toString() ?? widget.userData['_id']?.toString() ?? '';
    quizData['createdByName'] = widget.userData['nama'] ?? 'Guru';
    quizData['isActive'] = false; // Import as draft

    final result = await QuizService.createQuiz(token: widget.token, quizData: quizData);
    
    if (mounted) {
      setState(() => _isLoading = false);
      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kuis berhasil ditarik ke kelas ini!'), backgroundColor: Colors.green),
        );
        _loadQuizzes();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Gagal mengimpor kuis')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'import_quiz',
            onPressed: _showImportDialog,
            backgroundColor: Colors.blueAccent,
            foregroundColor: Colors.white,
            shape: const CircleBorder(),
            child: const Icon(LucideIcons.download),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'create_quiz',
            onPressed: _navigateToCreate,
            backgroundColor: AppTheme.tealDeep,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
            icon: const Icon(LucideIcons.plus),
            label: const Text('Buat Kuis', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
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
                        onLiveMonitor: () => _openLiveMonitor(_quizzes[index]),
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
              color: theme.colorScheme.onSurface.withAlpha(160),
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
  final VoidCallback onLiveMonitor;

  const _QuizCard({
    required this.quiz,
    required this.isDark,
    required this.onEdit,
    required this.onDelete,
    required this.onViewSubmissions,
    required this.onShare,
    required this.onLiveMonitor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PremiumCard(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 16),
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
                          color: theme.colorScheme.onSurface.withAlpha(160),
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
                    child: const Text(
                      'TERJADWAL',
                      style: TextStyle(
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
                        color: quiz.isActive ? Colors.green.withAlpha(160) : Colors.grey.withAlpha(160),
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
                if ((quiz.isActive || quiz.isScheduled) && quiz.isSecureMode)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _ActionBtn(
                      icon: LucideIcons.activity,
                      label: 'Live',
                      onTap: onLiveMonitor,
                      color: Colors.redAccent,
                    ),
                  ),
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

    return DefaultTabController(
      length: 2,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.9,
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
                color: theme.colorScheme.onSurface.withAlpha(160),
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
            
            TabBar(
              labelColor: AppTheme.tealDeep,
              unselectedLabelColor: theme.colorScheme.onSurface.withAlpha(160),
              indicatorColor: AppTheme.tealDeep,
              tabs: const [
                Tab(text: 'Daftar Siswa'),
                Tab(text: 'Statistik'),
              ],
            ),
            const SizedBox(height: 10),

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
                  Text('Hanya tampilkan siswa di kelas ini', style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface.withAlpha(160))),
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
                            color: theme.colorScheme.onSurface.withAlpha(160),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    : TabBarView(
                        children: [
                          ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: _submissions.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (ctx, i) {
                              final sub = _submissions[i];
                              final scorePercent = sub.totalPoints > 0
                                  ? (sub.score / sub.totalPoints * 100).round()
                                  : 0;

                              return ListTile(
                                onTap: () {
                                  Navigator.push(context, MaterialPageRoute(
                                    builder: (_) => GuruSubmissionDetail(submission: sub, quiz: widget.quiz)
                                  ));
                                },
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                tileColor: theme.colorScheme.surface.withAlpha(isDark ? 180 : 255),
                                leading: CircleAvatar(
                                  backgroundColor: scorePercent >= 70
                                      ? Colors.green.withAlpha(160)
                                      : Colors.red.withAlpha(160),
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
                                    color: theme.colorScheme.onSurface.withAlpha(160),
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
                          _buildAnalyticsTab(theme, isDark),
                        ],
                      ),
          ),
        ],
      ),
    ));
  }

  Widget _buildAnalyticsTab(ThemeData theme, bool isDark) {
    if (_submissions.isEmpty) return const SizedBox.shrink();

    int passed = 0;
    int failed = 0;
    double totalScore = 0;

    for (var sub in _submissions) {
      final scorePercent = sub.totalPoints > 0 ? (sub.score / sub.totalPoints * 100) : 0;
      totalScore += scorePercent;
      if (scorePercent >= 70) {
        passed++;
      } else {
        failed++;
      }
    }

    final avgScore = (totalScore / _submissions.length).round();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.tealDeep.withAlpha(20),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.tealDeep.withAlpha(50)),
                  ),
                  child: Column(
                    children: [
                      const Icon(LucideIcons.trendingUp, color: AppTheme.tealDeep),
                      const SizedBox(height: 10),
                      const Text('Rata-Rata', style: TextStyle(fontSize: 12)),
                      Text('$avgScore%', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppTheme.tealDeep)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.green.withAlpha(20),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.green.withAlpha(160)),
                  ),
                  child: Column(
                    children: [
                      const Icon(LucideIcons.checkCircle, color: Colors.green),
                      const SizedBox(height: 10),
                      const Text('Lulus (≥70)', style: TextStyle(fontSize: 12)),
                      Text('$passed', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.green)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
          const Text('Distribusi Kelulusan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                sections: [
                  PieChartSectionData(
                    color: Colors.green,
                    value: passed.toDouble(),
                    title: passed > 0 ? '$passed' : '',
                    radius: 50,
                    titleStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
                  ),
                  PieChartSectionData(
                    color: Colors.red,
                    value: failed.toDouble(),
                    title: failed > 0 ? '$failed' : '',
                    radius: 50,
                    titleStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Container(width: 12, height: 12, color: Colors.green),
                  const SizedBox(width: 6),
                  const Text('Lulus', style: TextStyle(fontSize: 12)),
                ],
              ),
              const SizedBox(width: 20),
              Row(
                children: [
                  Container(width: 12, height: 12, color: Colors.red),
                  const SizedBox(width: 6),
                  const Text('Tidak Lulus', style: TextStyle(fontSize: 12)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LiveMonitorSheet extends StatefulWidget {
  final Quiz quiz;
  final String token;

  const _LiveMonitorSheet({required this.quiz, required this.token});

  @override
  State<_LiveMonitorSheet> createState() => _LiveMonitorSheetState();
}

class _LiveMonitorSheetState extends State<_LiveMonitorSheet> {
  List<dynamic> _violations = [];
  bool _isLoading = true;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _fetchViolations();
    _startPolling();
  }

  void _startPolling() {
    Future.delayed(const Duration(seconds: 3), () {
      if (_isDisposed) return;
      _fetchViolations();
      _startPolling();
    });
  }

  Future<void> _fetchViolations() async {
    final v = await QuizService.getLiveViolations(token: widget.token, quizId: widget.quiz.id);
    if (!_isDisposed) {
      setState(() {
        _violations = v;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
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
              color: theme.colorScheme.onSurface.withAlpha(160),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Icon(LucideIcons.activity, color: Colors.redAccent, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Live Monitor: ${widget.quiz.title}',
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withAlpha(160),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.withAlpha(160)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8, height: 8,
                        decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 6),
                      const Text('LIVE', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 10)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading && _violations.isEmpty
                ? const Center(child: CircularProgressIndicator(color: Colors.redAccent))
                : _violations.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(LucideIcons.shieldCheck, size: 48, color: Colors.green.withAlpha(160)),
                            const SizedBox(height: 16),
                            const Text('Belum ada pelanggaran', style: TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _violations.length,
                        itemBuilder: (ctx, idx) {
                          final v = _violations[idx];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.red.withAlpha(isDark ? 30 : 15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.red.withAlpha(160)),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(LucideIcons.alertTriangle, color: Colors.red, size: 20),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        v['studentName'] ?? 'Unknown',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        v['reason'] ?? 'Pelanggaran terdeteksi',
                                        style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface.withAlpha(200)),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  v['timestamp'] != null 
                                      ? DateFormat('HH:mm:ss').format(DateTime.parse(v['timestamp']).toLocal())
                                      : '-',
                                  style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withAlpha(160), fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
