import 'dart:io' show Platform;
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../config/theme.dart';
import '../../../models/quiz_model.dart';
import '../../../services/exam/violation_service.dart';
import '../../../services/exam/timer_service.dart';
import '../../../services/exam/auto_save_service.dart';
import '../../../services/exam/secure_mode_service.dart';
import '../../../services/exam/focus_detection_service.dart';
import '../../../services/exam/keyboard_protection_service.dart';
import '../../../services/quiz_service.dart';
import 'package:google_fonts/google_fonts.dart';

class SiswaExamScreen extends StatefulWidget {
  final Quiz quiz;
  final Map<String, dynamic> userData;
  final String token;

  const SiswaExamScreen({
    super.key,
    required this.quiz,
    required this.userData,
    required this.token,
  });

  @override
  State<SiswaExamScreen> createState() => _SiswaExamScreenState();
}

class _SiswaExamScreenState extends State<SiswaExamScreen> {
  late final ViolationService _violationService;
  late final TimerService _timerService;
  late final AutoSaveService _autoSaveService;
  late final SecureModeService _secureModeService;
  late final FocusDetectionService _focusDetectionService;
  late final KeyboardProtectionService _keyboardProtection;

  final Map<String, dynamic> _answers = {};
  final Map<String, String> _essayAnswers = {};
  int _currentIndex = 0;
  bool _isSubmitting = false;
  bool _isSubmitted = false;
  bool _showViolationWarning = false;
  String _lastViolationMsg = '';
  final FocusNode _focusNode = FocusNode();

  List<int> _questionOrder = [];
  final Map<String, List<int>> _optionOrder = {};

  String get _studentId =>
      widget.userData['id']?.toString() ??
      widget.userData['_id']?.toString() ??
      '';

  @override
  void initState() {
    super.initState();

    _initShuffle();

    _violationService = ViolationService(
      maxViolations: 9999, 
      onMaxViolationsReached: () {},
    );
    _violationService.addListener(_onViolationChanged);

    int examDuration = widget.quiz.durationMinutes;
    if (widget.quiz.closedAt != null) {
      final diff = widget.quiz.closedAt!.difference(DateTime.now()).inMinutes;
      if (diff < examDuration) {
        examDuration = diff > 0 ? diff : 1;
      }
    }

    _timerService = TimerService(
      durationMinutes: examDuration,
      onTimeUp: () => _autoSubmit('Waktu habis'),
    );
    _timerService.addListener(() {
      if (mounted) setState(() {});
    });

    _autoSaveService = AutoSaveService(
      quizId: widget.quiz.id,
      studentId: _studentId,
      intervalSeconds: 10,
    );

    _secureModeService = SecureModeService(violationService: _violationService);

    _focusDetectionService = FocusDetectionService(
      violationService: _violationService,
      onFocusLost: () {
        if (mounted) _showWarning('Anda meninggalkan aplikasi!');
      },
      onFocusRegained: () {
        if (mounted) _recoverSecureMode();
      },
    );

    _keyboardProtection =
        KeyboardProtectionService(violationService: _violationService);

    _initExam();
  }

  void _initShuffle() {
    _questionOrder = List.generate(widget.quiz.questions.length, (i) => i);
    if (widget.quiz.shuffleQuestions) {
      _questionOrder.shuffle(Random(widget.quiz.id.hashCode));
    }

    for (var q in widget.quiz.questions) {
      List<int> oOrder = List.generate(q.options.length, (i) => i);
      if (widget.quiz.shuffleOptions) {
        oOrder.shuffle(Random(q.id.hashCode));
      }
      _optionOrder[q.id] = oOrder;
    }
  }

  Future<void> _initExam() async {
    final saved = await _autoSaveService.restore();
    if (saved.isNotEmpty) {
      setState(() {
        for (var entry in saved.entries) {
          final q = widget.quiz.questions.firstWhere((x) => x.id == entry.key,
              orElse: () => widget.quiz.questions.first);
          if (q.id == entry.key) {
            if (q.questionType == 'essay') {
              _essayAnswers[entry.key] = entry.value.toString();
            } else {
              _answers[entry.key] = entry.value;
            }
          }
        }
      });
    }

    if (widget.quiz.isSecureMode) {
      await _secureModeService.activate();
      _focusDetectionService.activate();
      _keyboardProtection.activate();

      if (!kIsWeb && !_isDesktop) {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      }
    }

    _timerService.start();
    _autoSaveService.start();
    _focusNode.requestFocus();
  }

  bool get _isDesktop =>
      !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);

  void _onViolationChanged() async {
    if (!mounted) return;
    setState(() {});
    if (_violationService.violations.isNotEmpty) {
      final last = _violationService.violations.last;
      _showWarning(last.description);
      final res = await QuizService.reportLiveViolation(
        token: widget.token,
        quizId: widget.quiz.id,
        reason: last.description,
      );
      if (res['autoSubmitTriggered'] == true) {
        if (mounted && !_isSubmitted && !_isSubmitting) {
          _autoSubmit('Batas pelanggaran terlampaui (3 kali)');
        }
      }
    }
  }

  void _showWarning(String msg) {
    setState(() {
      _showViolationWarning = true;
      _lastViolationMsg = msg;
    });
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showViolationWarning = false);
    });
  }

  void _recoverSecureMode() {
    if (!kIsWeb && !_isDesktop) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    }
    _focusNode.requestFocus();
  }

  void _selectAnswer(String questionId, dynamic answer, String type) {
    setState(() {
      if (type == 'essay') {
        _essayAnswers[questionId] = answer.toString();
        _autoSaveService.updateAnswer(questionId, answer.toString());
      } else {
        _answers[questionId] = answer;
        _autoSaveService.updateAnswer(questionId, answer);
      }
    });
  }

  Future<void> _autoSubmit(String reason) async {
    if (_isSubmitted) return;
    _showWarning('AUTO SUBMIT: $reason');
    await _submitExam(autoSubmitted: true);
  }

  Future<void> _submitExam({bool autoSubmitted = false}) async {
    if (_isSubmitted || _isSubmitting) return;
    setState(() => _isSubmitting = true);

    _autoSaveService.updateAllAnswers({..._answers, ..._essayAnswers});
    await _autoSaveService.forceSave();

    try {
      final result = await QuizService.submitAnswers(
        token: widget.token,
        quizId: widget.quiz.id,
        kelasId: widget.quiz.kelasId,
        answers: _answers,
        essayAnswers: _essayAnswers,
        violations: _violationService.violationCount,
        autoSubmitted: autoSubmitted,
        violationLog: _violationService.exportLog(),
      );

      if (result['success'] == true) {
        _timerService.stop();
        await _autoSaveService.clear();

        if (mounted) {
          setState(() { _isSubmitting = false; _isSubmitted = true; });
          _deactivateSecureMode();
          _showResultDialog(result, autoSubmitted);
        }
      } else {
        if (result['message'] != null && result['message'].toString().contains('Koneksi gagal')) {
           if (mounted) {
            setState(() => _isSubmitting = false);
            _showOfflineWarningDialog(); 
          }
        } else {
          if (mounted) {
            setState(() => _isSubmitting = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(result['message'] ?? 'Gagal menyimpan jawaban ke server.', style: GoogleFonts.poppins(fontWeight: FontWeight.bold))),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        _showOfflineWarningDialog();
      }
    }
  }

  void _showOfflineWarningDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: Theme.of(context).dividerColor, width: 1.2),
        ),
        title: Row(
          children: [
            const Icon(LucideIcons.wifiOff, color: AppTheme.error, size: 24),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Koneksi Terputus',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900, color: isDark ? Colors.white : AppTheme.textLight),
              ),
            ),
          ],
        ),
        content: Text(
          'Gagal mengirim jawaban karena tidak ada koneksi internet atau server sedang sibuk.\n\n'
          'Jangan panik! Seluruh jawaban Anda sudah tersimpan dengan aman di memori perangkat ini.\n\n'
          'Silakan cari koneksi Wi-Fi atau nyalakan data seluler, lalu tekan tombol Submit kembali.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.5, color: isDark ? Colors.white70 : AppTheme.textLight),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.indigoPrimary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: Text('Saya Mengerti', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showResultDialog(Map<String, dynamic> result, bool autoSubmitted) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final data = result['data'];
    final score = data?['data']?['score'] ?? data?['score'] ?? 0;
    final total = data?['data']?['totalPoints'] ?? data?['totalPoints'] ?? 0;
    final hasEssay = data?['data']?['hasEssay'] ?? data?['hasEssay'] ?? false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PopScope(
        canPop: false,
        child: Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: Theme.of(context).dividerColor, width: 1.2),
          ),
          backgroundColor: Theme.of(context).colorScheme.surface,
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: (result['success'] == true ? AppTheme.success : AppTheme.error).withAlpha(20),
                    shape: BoxShape.circle,
                    border: Border.all(color: (result['success'] == true ? AppTheme.success : AppTheme.error).withAlpha(80), width: 1.5),
                  ),
                  child: Icon(
                    result['success'] == true
                        ? LucideIcons.checkCircle
                        : LucideIcons.xCircle,
                    size: 44,
                    color: result['success'] == true ? AppTheme.success : AppTheme.error,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  autoSubmitted
                      ? 'Ujian Dihentikan Otomatis'
                      : 'Ujian Selesai!',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900, color: isDark ? Colors.white : AppTheme.textLight),
                ),
                const SizedBox(height: 8),
                if (result['success'] == true) ...[
                  if (hasEssay)
                    Text(
                      'Jawaban berhasil disimpan.\nNilai akhir menunggu penilaian guru untuk soal essay.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppTheme.warning, fontWeight: FontWeight.w600),
                    )
                  else
                    Text(
                      'Skor: $score / $total',
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w900,
                        color: AppTheme.indigoPrimary),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    'Pelanggaran: ${_violationService.violationCount}',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppTheme.error,
                      fontWeight: FontWeight.w700),
                  ),
                ] else
                  Text(
                    result['message'] ?? 'Gagal menyimpan jawaban',
                    style: GoogleFonts.poppins(color: AppTheme.error, fontWeight: FontWeight.w600),
                  ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.indigoPrimary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: Text('Kembali', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmSubmit() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    int answered = _answers.length + _essayAnswers.length;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: Theme.of(context).dividerColor, width: 1.2),
        ),
        title: Text(
          'Submit Jawaban?',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w900, color: isDark ? Colors.white : AppTheme.textLight),
        ),
        content: Text(
          'Dijawab: $answered/${widget.quiz.questions.length} soal.\nPelanggaran: ${_violationService.violationCount}',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: isDark ? Colors.white70 : AppTheme.textLight, fontWeight: FontWeight.w600),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Batal',
              style: GoogleFonts.poppins(color: isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt, fontWeight: FontWeight.bold),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _submitExam();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.success,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: Text('Submit', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _deactivateSecureMode() async {
    _focusDetectionService.deactivate();
    _keyboardProtection.deactivate();
    await _secureModeService.deactivate();
    if (!kIsWeb && !_isDesktop) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  @override
  void dispose() {
    _violationService.removeListener(_onViolationChanged);
    _timerService.dispose();
    _autoSaveService.dispose();
    _secureModeService.dispose();
    _focusDetectionService.dispose();
    _focusNode.dispose();
    if (!kIsWeb && !_isDesktop) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return PopScope(
      canPop: _isSubmitted,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !_isSubmitted) {
          _violationService.addViolation(
              'shortcut_attempt', 'Mencoba keluar dari ujian');
        }
      },
      child: KeyboardListener(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: (event) {
          if (widget.quiz.isSecureMode) {
            _keyboardProtection.handleKeyEvent(event);
          }
        },
        child: GestureDetector(
          onSecondaryTap: widget.quiz.isSecureMode
              ? () {
                  _violationService.recordRightClick();
                }
              : null,
          child: Scaffold(
            backgroundColor: isDark ? AppTheme.darkBg : Colors.grey.shade50,
            body: SafeArea(
              child: Column(
                children: [
                  _buildTopBar(theme, isDark),
                  if (_showViolationWarning) _buildWarningBanner(isDark),
                  Expanded(child: _buildQuestionArea(theme, isDark)),
                  _buildBottomNav(theme, isDark),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
            bottom: BorderSide(color: Theme.of(context).dividerColor, width: 1.2)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withAlpha(isDark ? 40 : 6), blurRadius: 8)
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.indigoPrimary.withAlpha(20),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.indigoPrimary.withAlpha(50)),
            ),
            child: const Icon(LucideIcons.shieldCheck, color: AppTheme.indigoPrimary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.quiz.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : AppTheme.textLight,
                    letterSpacing: -0.3),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Soal ${_currentIndex + 1} dari ${widget.quiz.questions.length}',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600,
                    color: isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt),
                ),
              ],
            ),
          ),
          _buildTimerChip(isDark),
          const SizedBox(width: 8),
          _buildViolationChip(isDark),
        ],
      ),
    );
  }

  Widget _buildTimerChip(bool isDark) {
    Color bg = AppTheme.success.withAlpha(20);
    Color fg = AppTheme.success;
    if (_timerService.isCritical) {
      bg = AppTheme.error.withAlpha(20);
      fg = AppTheme.error;
    } else if (_timerService.isWarning) {
      bg = AppTheme.orangeVivid.withAlpha(20);
      fg = AppTheme.orangeVivid;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: fg.withAlpha(80), width: 1.0)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.clock, size: 13, color: fg),
          const SizedBox(width: 6),
          Text(
            _timerService.formattedTime,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w900,
              color: fg,
              fontFeatures: [const FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViolationChip(bool isDark) {
    final count = _violationService.violationCount;
    final danger = count >= 3; 

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: (danger ? AppTheme.error : AppTheme.orangeVivid).withAlpha(20),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: (danger ? AppTheme.error : AppTheme.orangeVivid).withAlpha(80), width: 1.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.alertTriangle,
              size: 13, color: danger ? AppTheme.error : AppTheme.orangeVivid),
          const SizedBox(width: 5),
          Text(
            '$count',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w900,
              color: danger ? AppTheme.error : AppTheme.orangeVivid),
          ),
        ],
      ),
    );
  }

  Widget _buildWarningBanner(bool isDark) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppTheme.error,
        border: Border.all(color: Colors.black, width: 3),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Colors.black,
            offset: Offset(4, 4),
            blurRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.black, width: 2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(LucideIcons.siren, color: AppTheme.error, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PERINGATAN KECURANGAN!',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _lastViolationMsg,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate()
      .fadeIn(duration: 300.ms)
      .shake(hz: 8, curve: Curves.easeInOutCubic, duration: 500.ms)
      .shimmer(duration: 1.seconds, color: Colors.white.withAlpha(50));
  }

  Widget _buildQuestionArea(ThemeData theme, bool isDark) {
    if (widget.quiz.questions.isEmpty) {
      return Center(
        child: Text(
          'Tidak ada soal',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt),
        ),
      );
    }

    final qIndex = _questionOrder[_currentIndex];
    final q = widget.quiz.questions[qIndex];
    final selectedAnswer = _answers[q.id];
    final selectedEssay = _essayAnswers[q.id] ?? '';
    final oOrder = _optionOrder[q.id] ?? [];

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.success.withAlpha(20),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.success.withAlpha(60)),
            ),
            child: Text(
              'Soal ${_currentIndex + 1}  •  ${q.points} Poin',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w900,
                color: AppTheme.success),
            ),
          ),
          const SizedBox(height: 20),
          if (q.imageUrl != null) ...[
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 250),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  q.imageUrl!,
                  width: double.infinity,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 100,
                    color: Theme.of(context).colorScheme.surface,
                    child: Center(
                        child: Icon(LucideIcons.imageOff, color: isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
          SelectionContainer.disabled(
            child: Text(
              q.question,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : AppTheme.textLight,
                height: 1.5),
            ),
          ),
          const SizedBox(height: 24),
          if (q.questionType == 'essay') ...[
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              padding: const EdgeInsets.all(4),
              child: TextFormField(
                key: ValueKey(q.id),
                initialValue: selectedEssay,
                maxLines: 8,
                onChanged: (val) => _selectAnswer(q.id, val, 'essay'),
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: isDark ? Colors.white : AppTheme.textLight),
                decoration: InputDecoration(
                  hintText: 'Tulis jawaban uraian Anda di sini...',
                  hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(color: isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt),
                  filled: true,
                  fillColor: Colors.transparent,
                  border: InputBorder.none,
                ),
              ),
            ),
          ] else ...[
            ...List.generate(oOrder.length, (i) {
              final oi = oOrder[i];

              bool isSelected = false;
              if (q.questionType == 'multipleChoice' ||
                  q.questionType == 'multipleAnswer') {
                isSelected = selectedAnswer == oi;
              } else {
                isSelected =
                    (selectedAnswer is List) && selectedAnswer.contains(oi);
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      if (q.questionType == 'multipleChoice' ||
                          q.questionType == 'multipleAnswer') {
                        _selectAnswer(q.id, oi, q.questionType);
                      } else {
                        List<int> current = selectedAnswer is List
                            ? List<int>.from(selectedAnswer)
                            : [];
                        if (current.contains(oi)) {
                          current.remove(oi);
                        } else {
                          current.add(oi);
                        }
                        _selectAnswer(q.id, current, q.questionType);
                      }
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.indigoPrimary.withAlpha(isDark ? 55 : 30)
                              : Theme.of(context).dividerColor,
                          width: 1.2,
                        ),
                      ),
                      padding: const EdgeInsets.all(4),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.indigoPrimary.withAlpha(15)
                              : Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? AppTheme.indigoPrimary.withAlpha(60) : Colors.transparent,
                          ),
                        ),
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppTheme.indigoPrimary
                                    : Theme.of(context).dividerColor,
                                borderRadius: q.questionType == 'multipleChoice' ||
                                              q.questionType == 'multipleAnswer'
                                        ? BorderRadius.circular(16)
                                        : BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  String.fromCharCode(65 + i),
                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w900,
                                      color: isSelected
                                          ? Colors.white
                                          : isDark ? Colors.white70 : AppTheme.textLight),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: SelectionContainer.disabled(
                                child: Text(
                                  q.options[oi],
                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: isSelected
                                          ? FontWeight.w800
                                          : FontWeight.w600,
                                      color: isDark ? Colors.white : AppTheme.textLight),
                                ),
                              ),
                            ),
                            if (isSelected)
                              const Icon(LucideIcons.checkCircle, color: AppTheme.indigoPrimary, size: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
          const SizedBox(height: 24),
          _buildQuestionDots(isDark),
        ],
      ),
    );
  }

  Widget _buildQuestionDots(bool isDark) {
    return Center(
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: List.generate(widget.quiz.questions.length, (i) {
          final qIndex = _questionOrder[i];
          final q = widget.quiz.questions[qIndex];
          bool isAnswered = false;
          if (q.questionType == 'essay') {
            isAnswered = _essayAnswers.containsKey(q.id) &&
                _essayAnswers[q.id]!.trim().isNotEmpty;
          } else if (q.questionType == 'multipleChoice' ||
              q.questionType == 'multipleAnswer') {
            isAnswered = _answers.containsKey(q.id);
          } else {
            final ans = _answers[q.id];
            isAnswered = ans != null && (ans is List) && ans.isNotEmpty;
          }

          final isCurrent = i == _currentIndex;
          return GestureDetector(
            onTap: () => setState(() => _currentIndex = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: isCurrent ? 32 : 28,
              height: isCurrent ? 32 : 28,
              decoration: BoxDecoration(
                color: isCurrent
                    ? AppTheme.indigoPrimary
                    : isAnswered
                        ? AppTheme.success.withAlpha(isDark ? 30 : 15)
                        : Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isCurrent
                      ? AppTheme.indigoPrimary
                      : isAnswered
                          ? AppTheme.success.withAlpha(80)
                          : Theme.of(context).dividerColor,
                  width: isCurrent ? 2 : 1,
                ),
              ),
              child: Center(
                  child: Text(
                    '${i + 1}',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900,
                      color: isCurrent
                          ? Colors.white
                          : isAnswered
                              ? AppTheme.success
                              : isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt),
                  ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildBottomNav(ThemeData theme, bool isDark) {
    final total = widget.quiz.questions.length;

    int answeredCount = 0;
    for (var q in widget.quiz.questions) {
      if (q.questionType == 'essay') {
        if (_essayAnswers.containsKey(q.id) &&
            _essayAnswers[q.id]!.trim().isNotEmpty) {
          answeredCount++;
        }
      } else if (q.questionType == 'multipleChoice' ||
          q.questionType == 'multipleAnswer') {
        if (_answers.containsKey(q.id)) {
          answeredCount++;
        }
      } else {
        final ans = _answers[q.id];
        if (ans != null && (ans is List) && ans.isNotEmpty) {
          answeredCount++;
        }
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
            top: BorderSide(color: Theme.of(context).dividerColor, width: 1.2)),
      ),
      child: Row(
        children: [
          OutlinedButton.icon(
            onPressed: _currentIndex > 0
                ? () => setState(() => _currentIndex--)
                : null,
            icon: const Icon(LucideIcons.chevronLeft, size: 16),
            label: Text('Prev', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
            style: OutlinedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.surface,
              foregroundColor: isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt,
              side: BorderSide(color: Theme.of(context).colorScheme.surface, width: 1.0),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const Spacer(),
          Text(
            '$answeredCount/$total dijawab',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w800,
              color: isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt),
          ),
          const Spacer(),
          if (_currentIndex < total - 1)
            ElevatedButton.icon(
              onPressed: () => setState(() => _currentIndex++),
              icon: const Icon(LucideIcons.chevronRight, size: 16),
              label: Text('Next', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w800)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.indigoPrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            )
          else
            ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _confirmSubmit,
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(LucideIcons.send, size: 16),
              label: Text(_isSubmitting ? 'Mengirim...' : 'Submit', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w800)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.success,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            ),
        ],
      ),
    );
  }
}
