import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../../config/theme.dart';
import '../../../services/quiz_service.dart';
import '../../../services/export_service.dart';
import '../../../models/quiz_model.dart';
import 'guru_quiz_create_screen.dart';
import 'guru_submission_detail.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../widgets/app_shell.dart';
import '../../../widgets/neo_brutalism.dart';

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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: Theme.of(context).dividerColor, width: 1.2),
        ),
        title: Text(
          'Hapus Kuis?',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900, color: isDark ? Colors.white : AppTheme.textLight),
        ),
        content: Text(
          'Kuis dan semua jawaban siswa akan dihapus secara permanen.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: isDark ? Colors.white70 : AppTheme.textLight),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Batal',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt, fontWeight: FontWeight.bold),
            ),
          ),
          NeoButton(
            onTap: () => Navigator.pop(ctx, true),
            text: 'Hapus',
            color: AppTheme.error,
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
        const SnackBar(
          content: Text('Kode Share Kuis berhasil disalin! Bagikan ke guru/kelas lain.',
            style: TextStyle(fontWeight: FontWeight.w800)),
          backgroundColor: AppTheme.success,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kode Share tidak tersedia untuk kuis ini.',
            style: TextStyle(fontWeight: FontWeight.w800)),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  void _showImportDialog() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: Theme.of(context).dividerColor, width: 1.2),
        ),
        title: Text(
          'Tarik Kuis (Import)',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900, color: isDark ? Colors.white : AppTheme.textLight),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Masukkan Kode Share kuis yang ingin Anda tarik ke kelas ini.', 
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: isDark ? Colors.white70 : AppTheme.textLight),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border.all(color: Theme.of(context).dividerColor),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: TextField(
                controller: ctrl,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: isDark ? Colors.white : AppTheme.textLight),
                decoration: InputDecoration(
                  hintText: 'Contoh: A1B2C3D4',
                  hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(color: isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt),
                  border: InputBorder.none,
                ),
                textCapitalization: TextCapitalization.characters,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Batal',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt, fontWeight: FontWeight.bold),
            ),
          ),
          NeoButton(
            onTap: () async {
              final code = ctrl.text.trim().toUpperCase();
              if (code.isEmpty) return;
              Navigator.pop(ctx);
              _importQuiz(code);
            },
            text: 'Import',
            color: AppTheme.indigoPrimary,
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
          const SnackBar(content: Text('Kuis tidak ditemukan atau kode salah'), backgroundColor: AppTheme.error),
        );
      }
      return;
    }

    final quizData = quiz.toJson();
    quizData.remove('id');
    quizData.remove('_id');
    quizData['kelasId'] = widget.teamData['id']?.toString() ?? '';
    quizData['createdBy'] = widget.userData['id']?.toString() ?? widget.userData['_id']?.toString() ?? '';
    quizData['createdByName'] = widget.userData['nama'] ?? 'Guru';
    quizData['isActive'] = false; 

    final result = await QuizService.createQuiz(token: widget.token, quizData: quizData);
    
    if (mounted) {
      setState(() => _isLoading = false);
      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kuis berhasil ditarik ke kelas ini!'), backgroundColor: AppTheme.success),
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
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.small(
            heroTag: 'import_quiz',
            onPressed: _showImportDialog,
            backgroundColor: AppTheme.info,
            foregroundColor: Colors.white,
            shape: const CircleBorder(),
            child: const Icon(LucideIcons.download),
          ),
          const SizedBox(height: 12),
          AppFAB(
            onPressed: _navigateToCreate,
            icon: LucideIcons.plus,
            label: 'Buat Kuis',
            color: AppTheme.success,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.success))
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
            child: Icon(LucideIcons.clipboardList, size: 56, color: AppTheme.indigoPrimary.withAlpha(180)),
          ),
          const SizedBox(height: 24),
          Text(
            'Belum ada kuis',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : AppTheme.textLight),
          ),
          const SizedBox(height: 8),
          Text(
            'Buat kuis pertama untuk ujian siswa',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600,
              color: isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt),
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
    final accentColor = quiz.isSecureMode ? AppTheme.primary : AppTheme.success;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: NeoCard(
        color: Theme.of(context).colorScheme.surface,
        borderColor: Theme.of(context).colorScheme.onSurface,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: accentColor.withAlpha(20),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: accentColor.withAlpha(80)),
                    ),
                    child: Icon(
                      quiz.isSecureMode ? LucideIcons.shieldCheck : LucideIcons.clipboardList,
                      color: accentColor,
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
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900,
                            color: isDark ? Colors.white : AppTheme.textLight,
                            letterSpacing: -0.3),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          quiz.description.isNotEmpty ? quiz.description : 'Tidak ada deskripsi',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt,
                            fontWeight: FontWeight.w600),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  if (quiz.isScheduled)
                    const NeoBadge(label: 'TERJADWAL', color: AppTheme.warning)
                  else
                    NeoBadge(
                      label: quiz.isActive ? 'AKTIF' : 'NONAKTIF',
                      color: quiz.isActive ? AppTheme.success : Colors.grey,
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
                    color: AppTheme.success,
                    isDark: isDark,
                  ),
                  if (quiz.isScheduled && quiz.scheduledAt != null)
                    _InfoChip(
                      icon: LucideIcons.calendarClock,
                      label: DateFormat('dd MMM, HH:mm').format(quiz.scheduledAt!),
                      color: AppTheme.warning,
                      isDark: isDark,
                    ),
                  if (quiz.isSecureMode)
                    _InfoChip(
                      icon: LucideIcons.lock,
                      label: 'Secure Mode',
                      color: AppTheme.success,
                      isDark: isDark,
                    ),
                ],
              ),

              const SizedBox(height: 16),
              Divider(height: 1, color: Theme.of(context).dividerColor),
              const SizedBox(height: 14),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _ActionBtn(
                    icon: LucideIcons.barChart2,
                    label: 'Hasil',
                    onTap: onViewSubmissions,
                    color: AppTheme.indigoPrimary,
                    isDark: isDark,
                  ),
                  if ((quiz.isActive || quiz.isScheduled) && quiz.isSecureMode)
                    _ActionBtn(
                      icon: LucideIcons.activity,
                      label: 'Live',
                      onTap: onLiveMonitor,
                      color: AppTheme.error,
                      isDark: isDark,
                    ),
                  _ActionBtn(
                    icon: LucideIcons.share2,
                    label: 'Share',
                    onTap: onShare,
                    color: AppTheme.info,
                    isDark: isDark,
                  ),
                  _ActionBtn(
                    icon: LucideIcons.edit3,
                    label: 'Edit',
                    onTap: onEdit,
                    color: AppTheme.primary,
                    isDark: isDark,
                  ),
                  _ActionBtn(
                    icon: LucideIcons.trash2,
                    label: 'Hapus',
                    onTap: onDelete,
                    color: AppTheme.error,
                    isDark: isDark,
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
        color: color.withAlpha(isDark ? 25 : 15),
        border: Border.all(color: Theme.of(context).colorScheme.onSurface, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.onSurface,
            offset: const Offset(2, 2),
            blurRadius: 0,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800, color: color),
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
  final bool isDark;

  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withAlpha(isDark ? 30 : 20),
          border: Border.all(color: Theme.of(context).colorScheme.onSurface, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.onSurface,
              offset: const Offset(2, 2),
              blurRadius: 0,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 5),
            Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800, color: color),
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
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: Theme.of(context).dividerColor, width: 1.2),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            NeoCard(
              color: Theme.of(context).colorScheme.surface,
              borderColor: Theme.of(context).colorScheme.onSurface,
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const Icon(LucideIcons.barChart2, color: AppTheme.success, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Hasil: ${widget.quiz.title}',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900, color: isDark ? Colors.white : AppTheme.textLight),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  NeoButton(
                    onTap: _exportCsv,
                    text: 'Export CSV',
                    color: AppTheme.success,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                ],
              ),
            ),
            
            TabBar(
              labelColor: AppTheme.indigoPrimary,
              unselectedLabelColor: isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt,
              indicatorColor: AppTheme.indigoPrimary,
              labelStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w800),
              unselectedLabelStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
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
                    activeColor: AppTheme.indigoPrimary,
                    value: _filterByKelas,
                    onChanged: (val) {
                      setState(() => _filterByKelas = val ?? true);
                      _loadSubmissions();
                    },
                  ),
                  Text(
                    'Hanya tampilkan siswa di kelas ini', 
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          
          Divider(height: 1, color: Theme.of(context).dividerColor),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.success))
                : _submissions.isEmpty
                    ? Center(
                        child: Text(
                          'Belum ada siswa yang mengerjakan',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt,
                            fontWeight: FontWeight.w700),
                        ),
                      )
                    : TabBarView(
                        children: [
                          ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: _submissions.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (ctx, i) {
                              final sub = _submissions[i];
                              final scorePercent = sub.totalPoints > 0
                                  ? (sub.score / sub.totalPoints * 100).round()
                                  : 0;
                              final pass = scorePercent >= 70;
                              final color = pass ? AppTheme.success : AppTheme.error;

                              return NeoCard(
                                color: Theme.of(context).colorScheme.surface,
                                borderColor: pass ? AppTheme.success : AppTheme.error,
                                padding: EdgeInsets.zero,
                                child: ListTile(
                                  onTap: () {
                                    Navigator.push(context, MaterialPageRoute(
                                      builder: (_) => GuruSubmissionDetail(
                                        submission: sub, 
                                        quiz: widget.quiz,
                                        token: widget.token,
                                      )
                                    ));
                                  },
                                  leading: Container(
                                    width: 46,
                                    height: 46,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: color.withAlpha(20),
                                      border: Border.all(color: color.withAlpha(80), width: 1.5),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      '$scorePercent%',
                                      style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900,
                                        color: color),
                                    ),
                                  ),
                                  title: Text(
                                    sub.studentName,
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppTheme.textLight),
                                  ),
                                  subtitle: Text(
                                    'Skor: ${sub.score}/${sub.totalPoints} • Pelanggaran: ${sub.violations}',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt,
                                      fontWeight: FontWeight.w600),
                                  ),
                                  trailing: sub.autoSubmitted
                                      ? Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: AppTheme.error.withAlpha(20),
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(color: AppTheme.error.withAlpha(80)),
                                          ),
                                          child: Text(
                                            'AUTO',
                                            style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w900,
                                              color: AppTheme.error),
                                          ),
                                        )
                                      : const Icon(LucideIcons.chevronRight, size: 16),
                                ),
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
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.success.withAlpha(isDark ? 55 : 30), width: 1.2),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Theme.of(context).dividerColor),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Icon(LucideIcons.trendingUp, color: AppTheme.success, size: 20),
                        const SizedBox(height: 8),
                        Text('Rata-Rata', style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800, color: isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt)),
                        const SizedBox(height: 4),
                        Text('$avgScore%', style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w900, color: AppTheme.success)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.success.withAlpha(isDark ? 55 : 30), width: 1.2),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Theme.of(context).dividerColor),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Icon(LucideIcons.checkCircle, color: AppTheme.success, size: 20),
                        const SizedBox(height: 8),
                        Text('Lulus (≥70)', style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800, color: isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt)),
                        const SizedBox(height: 4),
                        Text('$passed', style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w900, color: AppTheme.success)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Distribusi Kelulusan', 
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900, color: isDark ? Colors.white : AppTheme.textLight),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                sections: [
                  PieChartSectionData(
                    color: AppTheme.success,
                    value: passed.toDouble(),
                    title: passed > 0 ? '$passed' : '',
                    radius: 46,
                    titleStyle: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  PieChartSectionData(
                    color: AppTheme.error,
                    value: failed.toDouble(),
                    title: failed > 0 ? '$failed' : '',
                    radius: 46,
                    titleStyle: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.white),
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
                  Container(
                    width: 12, height: 12, 
                    decoration: BoxDecoration(color: AppTheme.success, borderRadius: BorderRadius.circular(4)),
                  ),
                  const SizedBox(width: 6),
                  Text('Lulus', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700, color: isDark ? Colors.white70 : AppTheme.textLight)),
                ],
              ),
              const SizedBox(width: 24),
              Row(
                children: [
                  Container(
                    width: 12, height: 12, 
                    decoration: BoxDecoration(color: AppTheme.error, borderRadius: BorderRadius.circular(4)),
                  ),
                  const SizedBox(width: 6),
                  Text('Tidak Lulus', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700, color: isDark ? Colors.white70 : AppTheme.textLight)),
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
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: Theme.of(context).dividerColor, width: 1.2),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).dividerColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Icon(LucideIcons.activity, color: AppTheme.error, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Live Monitor: ${widget.quiz.title}',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900, color: isDark ? Colors.white : AppTheme.textLight),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.success.withAlpha(20),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.success.withAlpha(80)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8, height: 8,
                        decoration: const BoxDecoration(color: AppTheme.success, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'LIVE', 
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppTheme.success, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading && _violations.isEmpty
                ? const Center(child: CircularProgressIndicator(color: AppTheme.error))
                : _violations.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: AppTheme.success.withAlpha(20),
                                shape: BoxShape.circle,
                                border: Border.all(color: AppTheme.success.withAlpha(80)),
                              ),
                              child: const Icon(LucideIcons.shieldCheck, size: 36, color: AppTheme.success),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Belum ada pelanggaran', 
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : AppTheme.textLight),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        itemCount: _violations.length,
                        itemBuilder: (ctx, idx) {
                          final v = _violations[idx];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppTheme.error.withAlpha(isDark ? 55 : 30), width: 1.2),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surface,
                                  borderRadius: BorderRadius.circular(15),
                                  border: Border.all(color: Theme.of(context).dividerColor),
                                ),
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(LucideIcons.alertTriangle, color: AppTheme.error, size: 20),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            v['studentName'] ?? 'Unknown',
                                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900, color: isDark ? Colors.white : AppTheme.textLight),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            v['reason'] ?? 'Pelanggaran terdeteksi',
                                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: isDark ? Colors.white70 : AppTheme.textLight, fontWeight: FontWeight.w500),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      v['timestamp'] != null 
                                          ? DateFormat('HH:mm:ss').format(DateTime.parse(v['timestamp']).toLocal())
                                          : '-',
                                      style: Theme.of(context).textTheme.labelLarge?.copyWith(color: isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt, fontWeight: FontWeight.w800),
                                    ),
                                  ],
                                ),
                              ),
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
