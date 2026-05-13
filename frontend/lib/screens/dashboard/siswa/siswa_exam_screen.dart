import 'dart:io' show Platform;
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../config/theme.dart';
import '../../../models/quiz_model.dart';
import '../../../services/exam/violation_service.dart';
import '../../../services/exam/timer_service.dart';
import '../../../services/exam/auto_save_service.dart';
import '../../../services/exam/secure_mode_service.dart';
import '../../../services/exam/focus_detection_service.dart';
import '../../../services/exam/keyboard_protection_service.dart';
import '../../../services/quiz_service.dart';

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
      maxViolations: 9999, // Removed max violations auto-submit
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

  void _onViolationChanged() {
    if (!mounted) return;
    setState(() {});
    if (_violationService.violations.isNotEmpty) {
      final last = _violationService.violations.last;
      _showWarning(last.typeLabel);
      QuizService.reportLiveViolation(
        token: widget.token,
        quizId: widget.quiz.id,
        reason: last.typeLabel,
      );
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

  // ==== LOGIKA OFFLINE YANG SUDAH DISESUAIKAN DENGAN QUIZ SERVICE ====
  Future<void> _submitExam({bool autoSubmitted = false}) async {
    if (_isSubmitted || _isSubmitting) return;
    setState(() => _isSubmitting = true);

    // 1. Amankan jawaban ke memori HP sebelum mencoba kirim
    _autoSaveService.updateAllAnswers({..._answers, ..._essayAnswers});
    await _autoSaveService.forceSave();

    try {
      // 2. Coba kirim data ke Server Firebase/Node.js
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
        // 3. Jika benar-benar berhasil terkirim, hentikan timer & hapus cache
        _timerService.stop();
        await _autoSaveService.clear();

        if (mounted) {
          setState(() { _isSubmitting = false; _isSubmitted = true; });
          _deactivateSecureMode();
          _showResultDialog(result, autoSubmitted);
        }
      } else {
        // CEK APAKAH INI ERROR OFFLINE ("Koneksi gagal") ATAU DITOLAK SERVER
        if (result['message'] != null && result['message'].toString().contains('Koneksi gagal')) {
           // MASUK KESINI JIKA HP OFFLINE
           if (mounted) {
            setState(() => _isSubmitting = false);
            _showOfflineWarningDialog(); // Munculkan pop-up besar
          }
        } else {
          // JIKA DITOLAK SERVER (Misal ujian sudah ditutup / validasi error)
          if (mounted) {
            setState(() => _isSubmitting = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(result['message'] ?? 'Gagal menyimpan jawaban ke server.')),
            );
          }
        }
      }
    } catch (e) {
      // Fallback jaga-jaga
      if (mounted) {
        setState(() => _isSubmitting = false);
        _showOfflineWarningDialog();
      }
    }
  }

  // ==== DIALOG PEMBERITAHUAN OFFLINE ====
  void _showOfflineWarningDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(LucideIcons.wifiOff, color: Colors.red),
            SizedBox(width: 10),
            Expanded(
              child: Text('Koneksi Terputus',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
            ),
          ],
        ),
        content: const Text(
          'Gagal mengirim jawaban karena tidak ada koneksi internet atau server sedang sibuk.\n\n'
          'Jangan panik! Seluruh jawaban Anda sudah tersimpan dengan aman di memori perangkat ini.\n\n'
          'Silakan cari koneksi Wi-Fi atau nyalakan data seluler, lalu tekan tombol Submit kembali.',
          style: TextStyle(height: 1.5),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.tealDeep,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Saya Mengerti',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showResultDialog(Map<String, dynamic> result, bool autoSubmitted) {
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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color:
                        (result['success'] == true ? Colors.green : Colors.red)
                            .withAlpha(20),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    result['success'] == true
                        ? LucideIcons.checkCircle
                        : LucideIcons.xCircle,
                    size: 48,
                    color:
                        result['success'] == true ? Colors.green : Colors.red,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  autoSubmitted
                      ? 'Ujian Dihentikan Otomatis'
                      : 'Ujian Selesai!',
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                if (result['success'] == true) ...[
                  if (hasEssay)
                    const Text(
                        'Jawaban berhasil disimpan.\nNilai akhir menunggu penilaian guru untuk soal essay.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: Colors.orange))
                  else
                    Text('Skor: $score / $total',
                        style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.tealDeep)),
                  const SizedBox(height: 8),
                  Text('Pelanggaran: ${_violationService.violationCount}',
                      style: TextStyle(
                          fontSize: 14, color: Colors.red.withAlpha(200))),
                ] else
                  Text(result['message'] ?? 'Gagal menyimpan jawaban',
                      style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.tealDeep,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Kembali',
                        style: TextStyle(fontWeight: FontWeight.bold)),
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
    int answered = _answers.length + _essayAnswers.length;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Submit Jawaban?',
            style: TextStyle(fontWeight: FontWeight.w900)),
        content: Text(
          'Dijawab: $answered/${widget.quiz.questions.length} soal.\nPelanggaran: ${_violationService.violationCount}',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _submitExam();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.tealDeep,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Submit',
                style: TextStyle(fontWeight: FontWeight.bold)),
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
            backgroundColor: isDark ? AppTheme.bgDarkest : Colors.grey.shade50,
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
        color: theme.colorScheme.surface.withAlpha(isDark ? 230 : 255),
        border: Border(
            bottom:
                BorderSide(color: theme.colorScheme.onSurface.withAlpha(15))),
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
              color: AppTheme.tealDeep.withAlpha(20),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(LucideIcons.shieldCheck,
                color: AppTheme.tealDeep, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.quiz.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        letterSpacing: -0.3),
                    overflow: TextOverflow.ellipsis),
                Text(
                    'Soal ${_currentIndex + 1} dari ${widget.quiz.questions.length}',
                    style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurface.withAlpha(160))),
              ],
            ),
          ),
          _buildTimerChip(isDark),
          const SizedBox(width: 10),
          _buildViolationChip(isDark),
        ],
      ),
    );
  }

  Widget _buildTimerChip(bool isDark) {
    Color bg = AppTheme.tealDeep.withAlpha(20);
    Color fg = AppTheme.tealDeep;
    if (_timerService.isCritical) {
      bg = Colors.red.withAlpha(20);
      fg = Colors.red;
    } else if (_timerService.isWarning) {
      bg = AppTheme.orangeVivid.withAlpha(20);
      fg = AppTheme.orangeVivid;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: fg.withAlpha(40))),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.clock, size: 14, color: fg),
          const SizedBox(width: 6),
          Text(_timerService.formattedTime,
              style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  color: fg,
                  fontFeatures: const [FontFeature.tabularFigures()])),
        ],
      ),
    );
  }

  Widget _buildViolationChip(bool isDark) {
    final count = _violationService.violationCount;
    final max = _violationService.maxViolations;
    final danger = count >= max - 1;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: (danger ? Colors.red : AppTheme.orangeVivid).withAlpha(20),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: (danger ? Colors.red : AppTheme.orangeVivid).withAlpha(40)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.alertTriangle,
              size: 14, color: danger ? Colors.red : AppTheme.orangeVivid),
          const SizedBox(width: 5),
          Text('$count/$max',
              style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  color: danger ? Colors.red : AppTheme.orangeVivid)),
        ],
      ),
    );
  }

  Widget _buildWarningBanner(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      color: Colors.red.withAlpha(isDark ? 40 : 20),
      child: Row(
        children: [
          const Icon(LucideIcons.alertOctagon, color: Colors.red, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text('⚠️ PELANGGARAN: $_lastViolationMsg',
                style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w700,
                    fontSize: 13)),
          ),
          Text('${_violationService.remainingViolations} sisa',
              style: TextStyle(
                  color: Colors.red.withAlpha(180),
                  fontWeight: FontWeight.w900,
                  fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildQuestionArea(ThemeData theme, bool isDark) {
    if (widget.quiz.questions.isEmpty) {
      return const Center(child: Text('Tidak ada soal'));
    }

    final qIndex = _questionOrder[_currentIndex];
    final q = widget.quiz.questions[qIndex];
    final selectedAnswer = _answers[q.id];
    final selectedEssay = _essayAnswers[q.id] ?? '';
    final oOrder = _optionOrder[q.id] ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.tealDeep.withAlpha(15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.tealDeep.withAlpha(30)),
            ),
            child: Text('Soal ${_currentIndex + 1}  •  ${q.points} poin',
                style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: AppTheme.tealDeep)),
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
                    color: (isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt),
                    child: Center(
                        child: Icon(LucideIcons.imageOff, color: (isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt))),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
          SelectionContainer.disabled(
            child: Text(q.question,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                    height: 1.5)),
          ),
          const SizedBox(height: 28),
          if (q.questionType == 'essay') ...[
            TextFormField(
              key: ValueKey(q.id),
              initialValue: selectedEssay,
              maxLines: 8,
              onChanged: (val) => _selectAnswer(q.id, val, 'essay'),
              style: TextStyle(color: theme.colorScheme.onSurface),
              decoration: InputDecoration(
                hintText: 'Tulis jawaban uraian Anda di sini...',
                filled: true,
                fillColor:
                    theme.colorScheme.surface.withAlpha(isDark ? 200 : 255),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                      color: theme.colorScheme.onSurface.withAlpha(20)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide:
                      const BorderSide(color: AppTheme.tealDeep, width: 2),
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
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.tealDeep.withAlpha(isDark ? 30 : 15)
                            : theme.colorScheme.surface
                                .withAlpha(isDark ? 200 : 255),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.tealDeep.withAlpha(100)
                              : theme.colorScheme.onSurface.withAlpha(20),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppTheme.tealDeep
                                  : theme.colorScheme.onSurface.withAlpha(15),
                              borderRadius:
                                  q.questionType == 'multipleChoice' ||
                                          q.questionType == 'multipleAnswer'
                                      ? BorderRadius.circular(18)
                                      : BorderRadius.circular(8),
                            ),
                            child: Center(
                                child: Text(
                              String.fromCharCode(65 + i),
                              style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 15,
                                  color: isSelected
                                      ? Colors.white
                                      : theme.colorScheme.onSurface
                                          .withAlpha(150)),
                            )),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: SelectionContainer.disabled(
                              child: Text(q.options[oi],
                                  style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: isSelected
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      color: theme.colorScheme.onSurface)),
                            ),
                          ),
                          if (isSelected)
                            const Icon(LucideIcons.checkCircle,
                                color: AppTheme.tealDeep, size: 22),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
          const SizedBox(height: 20),
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
                    ? AppTheme.tealDeep
                    : isAnswered
                        ? AppTheme.tealDeep.withAlpha(isDark ? 50 : 25)
                        : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isCurrent
                      ? AppTheme.tealDeep
                      : isAnswered
                          ? AppTheme.tealDeep.withAlpha(80)
                          : (isDark
                              ? Colors.white.withAlpha(160)
                              : Colors.black.withAlpha(15)),
                  width: isCurrent ? 2 : 1,
                ),
              ),
              child: Center(
                  child: Text('${i + 1}',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: isCurrent
                              ? Colors.white
                              : isAnswered
                                  ? AppTheme.tealDeep
                                  : (isDark
                                      ? Colors.white.withAlpha(160)
                                      : Colors.black.withAlpha(160))))),
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
        color: theme.colorScheme.surface.withAlpha(isDark ? 230 : 255),
        border: Border(
            top: BorderSide(color: theme.colorScheme.onSurface.withAlpha(15))),
      ),
      child: Row(
        children: [
          OutlinedButton.icon(
            onPressed: _currentIndex > 0
                ? () => setState(() => _currentIndex--)
                : null,
            icon: const Icon(LucideIcons.chevronLeft, size: 18),
            label: const Text('Prev',
                style: TextStyle(fontWeight: FontWeight.w700)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              side:
                  BorderSide(color: theme.colorScheme.onSurface.withAlpha(160)),
            ),
          ),
          const Spacer(),
          Text('$answeredCount/$total dijawab',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface.withAlpha(160))),
          const Spacer(),
          if (_currentIndex < total - 1)
            ElevatedButton.icon(
              onPressed: () => setState(() => _currentIndex++),
              icon: const Text('Next',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              label: const Icon(LucideIcons.chevronRight, size: 18),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.tealDeep,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            )
          else
            ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _confirmSubmit,
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(LucideIcons.send, size: 18),
              label: Text(_isSubmitting ? 'Mengirim...' : 'Submit',
                  style: const TextStyle(fontWeight: FontWeight.w800)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            ),
        ],
      ),
    );
  }
}