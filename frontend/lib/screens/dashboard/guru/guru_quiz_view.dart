import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(isDark ? 25 : 15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(80), width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, color: color, fontSize: 12),
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: color.withAlpha(isDark ? 30 : 20),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withAlpha(80), width: 1.2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, color: color, fontSize: 13),
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
          color: const Color(0xFFF8F9FC),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(20),
              blurRadius: 40,
              offset: const Offset(0, -10),
            ),
          ],
        ),
        child: Column(
          children: [
            // Drag handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFD1D5DB),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.success.withAlpha(20),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(LucideIcons.barChart2, color: AppTheme.success, size: 26),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hasil Kuis & Ujian',
                          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w900, color: AppTheme.textLight, fontSize: 20, letterSpacing: -0.5),
                        ),
                        Text(
                          widget.quiz.title,
                          style: GoogleFonts.plusJakartaSans(color: AppTheme.textMutedLt, fontWeight: FontWeight.w600, fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: _exportCsv,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppTheme.success,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.success.withAlpha(60),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(LucideIcons.download, color: Colors.white, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            'Export CSV',
                            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, color: Colors.white, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            TabBar(
              labelColor: AppTheme.indigoPrimary,
              unselectedLabelColor: AppTheme.textMutedLt,
              indicatorColor: AppTheme.indigoPrimary,
              indicatorWeight: 3,
              labelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 14),
              unselectedLabelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 14),
              tabs: const [
                Tab(text: 'Daftar Siswa'),
                Tab(text: 'Statistik'),
              ],
            ),
            const SizedBox(height: 10),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: Checkbox(
                        activeColor: AppTheme.indigoPrimary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        value: _filterByKelas,
                        onChanged: (val) {
                          setState(() => _filterByKelas = val ?? true);
                          _loadSubmissions();
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Hanya tampilkan siswa di kelas ini', 
                        style: GoogleFonts.plusJakartaSans(color: AppTheme.textMutedLt, fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          
          const Divider(height: 1, thickness: 1, color: Color(0xFFE5E7EB)),
          
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.success))
                : _submissions.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(LucideIcons.inbox, size: 48, color: AppTheme.textMutedLt.withAlpha(100)),
                            const SizedBox(height: 16),
                            Text(
                              'Belum Ada Hasil',
                              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 18, color: AppTheme.textLight),
                            ),
                            Text(
                              'Belum ada siswa yang menyelesaikan kuis ini.',
                              style: GoogleFonts.plusJakartaSans(color: AppTheme.textMutedLt, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      )
                    : TabBarView(
                        children: [
                          ListView.separated(
                            padding: const EdgeInsets.all(24),
                            itemCount: _submissions.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (ctx, i) {
                              final sub = _submissions[i];
                              final scorePercent = sub.totalPoints > 0
                                  ? (sub.score / sub.totalPoints * 100).round()
                                  : 0;
                              final pass = scorePercent >= 70;
                              final color = pass ? AppTheme.success : AppTheme.error;

                              return InkWell(
                                onTap: () {
                                  Navigator.push(context, MaterialPageRoute(
                                    builder: (_) => GuruSubmissionDetail(
                                      submission: sub, 
                                      quiz: widget.quiz,
                                      token: widget.token,
                                    )
                                  ));
                                },
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: const Color(0xFFE5E7EB)),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withAlpha(5),
                                        offset: const Offset(0, 4),
                                        blurRadius: 12,
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 50,
                                        height: 50,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: color.withAlpha(20),
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          '$scorePercent%',
                                          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w900, color: color, fontSize: 13),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              sub.studentName,
                                              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, color: AppTheme.textLight, fontSize: 15),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Skor: ${sub.score}/${sub.totalPoints} • Pelanggaran: ${sub.violations}',
                                              style: GoogleFonts.plusJakartaSans(color: AppTheme.textMutedLt, fontWeight: FontWeight.w600, fontSize: 12),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (sub.autoSubmitted) ...[
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: AppTheme.error.withAlpha(15),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            'AUTO',
                                            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w900, color: AppTheme.error, fontSize: 11),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                      ],
                                      const Icon(LucideIcons.chevronRight, size: 20, color: Color(0xFFD1D5DB)),
                                    ],
                                  ),
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
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withAlpha(5), offset: const Offset(0, 4), blurRadius: 12),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.indigoPrimary.withAlpha(15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(LucideIcons.trendingUp, color: AppTheme.indigoPrimary, size: 24),
                      ),
                      const SizedBox(height: 12),
                      Text('Rata-Rata', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: AppTheme.textMutedLt, fontSize: 13)),
                      const SizedBox(height: 4),
                      Text('$avgScore%', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w900, color: AppTheme.indigoPrimary, fontSize: 28)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withAlpha(5), offset: const Offset(0, 4), blurRadius: 12),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.success.withAlpha(15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(LucideIcons.checkCircle, color: AppTheme.success, size: 24),
                      ),
                      const SizedBox(height: 12),
                      Text('Lulus (≥70)', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: AppTheme.textMutedLt, fontSize: 13)),
                      const SizedBox(height: 4),
                      Text('$passed', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w900, color: AppTheme.success, fontSize: 28)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Text(
            'Distribusi Kelulusan', 
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w900, color: AppTheme.textLight, fontSize: 18),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFE5E7EB)),
              boxShadow: [
                BoxShadow(color: Colors.black.withAlpha(5), offset: const Offset(0, 4), blurRadius: 12),
              ],
            ),
            child: Column(
              children: [
                SizedBox(
                  height: 180,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 4,
                      centerSpaceRadius: 50,
                      sections: [
                        PieChartSectionData(
                          color: AppTheme.success,
                          value: passed.toDouble(),
                          title: passed > 0 ? '$passed' : '',
                          radius: 50,
                          titleStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 16),
                        ),
                        PieChartSectionData(
                          color: AppTheme.error,
                          value: failed.toDouble(),
                          title: failed > 0 ? '$failed' : '',
                          radius: 50,
                          titleStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 14, height: 14, 
                          decoration: const BoxDecoration(color: AppTheme.success, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 8),
                        Text('Lulus', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: AppTheme.textLight, fontSize: 14)),
                      ],
                    ),
                    const SizedBox(width: 32),
                    Row(
                      children: [
                        Container(
                          width: 14, height: 14, 
                          decoration: const BoxDecoration(color: AppTheme.error, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 8),
                        Text('Tidak Lulus', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: AppTheme.textLight, fontSize: 14)),
                      ],
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
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FC),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 40,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFD1D5DB),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          
          // Header Modern
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.indigoPrimary.withAlpha(20),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(LucideIcons.shieldAlert, color: AppTheme.indigoPrimary, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Live Cheating Monitor',
                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w900, color: AppTheme.textLight, fontSize: 20, letterSpacing: -0.5),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        widget.quiz.title,
                        style: GoogleFonts.plusJakartaSans(color: AppTheme.textMutedLt, fontWeight: FontWeight.w600, fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.error.withAlpha(15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.error.withAlpha(50), width: 1.5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8, height: 8,
                        decoration: const BoxDecoration(color: AppTheme.error, shape: BoxShape.circle),
                      ).animate(onPlay: (controller) => controller.repeat()).fade(duration: 800.ms),
                      const SizedBox(width: 8),
                      Text(
                        'RECORDING', 
                        style: GoogleFonts.plusJakartaSans(color: AppTheme.error, fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: 0.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Divider
          const Divider(height: 1, thickness: 1, color: Color(0xFFE5E7EB)),
          
          // Stats banner
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Pelanggaran',
                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: AppTheme.textMutedLt, fontSize: 13),
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${_violations.length}',
                          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w900, color: AppTheme.textLight, fontSize: 28, height: 1.1),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Tercatat',
                          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, color: AppTheme.textMutedLt, fontSize: 13, height: 1.6),
                        ),
                      ],
                    ),
                  ],
                ),
                Icon(LucideIcons.activity, color: AppTheme.textMutedLt.withAlpha(50), size: 48),
              ],
            ),
          ),
          
          const Divider(height: 1, thickness: 1, color: Color(0xFFE5E7EB)),

          // Content
          Expanded(
            child: _isLoading && _violations.isEmpty
                ? const Center(child: CircularProgressIndicator(color: AppTheme.indigoPrimary))
                : _violations.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: AppTheme.success.withAlpha(15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(LucideIcons.shieldCheck, size: 64, color: AppTheme.success),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Aman Terkendali!', 
                              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w900, fontSize: 22, color: AppTheme.textLight),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Belum ada kecurangan yang terdeteksi\nselama sesi ujian berlangsung.', 
                              textAlign: TextAlign.center,
                              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w500, fontSize: 14, color: AppTheme.textMutedLt),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.all(24),
                        itemCount: _violations.length,
                        itemBuilder: (ctx, idx) {
                          final v = _violations[idx];
                          final reasonStr = (v['reason'] ?? '').toString().toLowerCase();
                          final isSerious = reasonStr.contains('copy') || 
                                            reasonStr.contains('esc') ||
                                            reasonStr.contains('alt+tab') ||
                                            reasonStr.contains('window');
                          
                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: isSerious ? AppTheme.error.withAlpha(80) : const Color(0xFFE5E7EB), width: 1.5),
                              boxShadow: [
                                BoxShadow(
                                  color: (isSerious ? AppTheme.error : Colors.black).withAlpha(10),
                                  offset: const Offset(0, 4),
                                  blurRadius: 12,
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: IntrinsicHeight(
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    // Left color accent bar
                                    Container(
                                      width: 6,
                                      color: isSerious ? AppTheme.error : AppTheme.orangeVivid,
                                    ),
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Expanded(
                                                  child: Row(
                                                    children: [
                                                      Container(
                                                        padding: const EdgeInsets.all(6),
                                                        decoration: BoxDecoration(
                                                          color: AppTheme.indigoPrimary.withAlpha(15),
                                                          shape: BoxShape.circle,
                                                        ),
                                                        child: const Icon(LucideIcons.user, size: 14, color: AppTheme.indigoPrimary),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Expanded(
                                                        child: Text(
                                                          (v['studentName'] ?? 'Siswa Tidak Diketahui').toString(),
                                                          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, color: AppTheme.textLight, fontSize: 15),
                                                          maxLines: 1, overflow: TextOverflow.ellipsis,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFFF3F4F6),
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                  child: Text(
                                                    v['timestamp'] != null 
                                                        ? DateFormat('HH:mm:ss').format(DateTime.parse(v['timestamp']).toLocal())
                                                        : '-',
                                                    style: GoogleFonts.plusJakartaSans(color: AppTheme.textMutedLt, fontWeight: FontWeight.w700, fontSize: 11),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 12),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                              decoration: BoxDecoration(
                                                color: isSerious ? AppTheme.error.withAlpha(10) : AppTheme.orangeVivid.withAlpha(10),
                                                borderRadius: BorderRadius.circular(12),
                                                border: Border.all(color: isSerious ? AppTheme.error.withAlpha(30) : AppTheme.orangeVivid.withAlpha(30)),
                                              ),
                                              child: Row(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Icon(
                                                    isSerious ? LucideIcons.alertOctagon : LucideIcons.alertTriangle, 
                                                    color: isSerious ? AppTheme.error : AppTheme.orangeVivid, 
                                                    size: 18
                                                  ),
                                                  const SizedBox(width: 10),
                                                  Expanded(
                                                    child: Text(
                                                      v['reason'] ?? 'Pelanggaran tidak diketahui',
                                                      style: GoogleFonts.plusJakartaSans(color: isSerious ? AppTheme.error : AppTheme.orangeVivid, fontWeight: FontWeight.w700, fontSize: 13, height: 1.4),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ).animate().slideX(begin: 0.05, duration: 300.ms, curve: Curves.easeOutCubic).fadeIn();
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
