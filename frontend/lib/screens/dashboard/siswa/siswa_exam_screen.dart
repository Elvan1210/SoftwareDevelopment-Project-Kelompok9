import 'dart:io' show Platform;
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/quiz_model.dart';
import '../../../services/exam/violation_service.dart';
import '../../../services/exam/timer_service.dart';
import '../../../services/exam/auto_save_service.dart';
import '../../../services/exam/secure_mode_service.dart';
import '../../../services/exam/focus_detection_service.dart';
import '../../../services/exam/keyboard_protection_service.dart';
import '../../../services/quiz_service.dart';

// ─── Tailwind Neo-Brutalist Tokens ─────────────────────────────────────────
const Color _primary = Color(0xFF3D6754);
const Color _primaryContainer = Color(0xFFB7E5CD);
const Color _onPrimaryContainer = Color(0xFF3E6855);
const Color _tertiary = Color(0xFF8D4D33);
const Color _secondaryContainer = Color(0xFFB7EDE7);
const Color _onTertiary = Color(0xFFFFFFFF);
const Color _tertiaryContainer = Color(0xFFFFD1C0);
const Color _onTertiaryContainer = Color(0xFF8E4F34);
const Color _surfaceContainerHighest = Color(0xFFC1E8FF);
const Color _surfaceContainerHigh = Color(0xFFCEEDFF);
const Color _surfaceContainerLow = Color(0xFFE8F6FF);
const Color _surfaceContainer = Color(0xFFDBF1FF);
const Color _surface = Color(0xFFF4FAFF);
const Color _background = Color(0xFFF4FAFF);
const Color _onBackground = Color(0xFF001E2B);
const Color _onSurfaceVariant = Color(0xFF414944);
const Color _error = Color(0xFFBA1A1A);
const Color _errorContainer = Color(0xFFFFDAD6);

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

class _SiswaExamScreenState extends State<SiswaExamScreen> with WidgetsBindingObserver {
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
    WidgetsBinding.instance.addObserver(this);
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

    final _timerPersistKey = 'exam_timer_${widget.quiz.id}_$_studentId';

    _timerService = TimerService(
      durationMinutes: examDuration,
      onTimeUp: () => _autoSubmit('Waktu habis'),
      persistKey: _timerPersistKey,
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
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showAutoSaveNotification();
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

    // Cek apakah ada sisa waktu tersimpan (jika app pernah dibuka sebelumnya)
    final _timerPersistKey = 'exam_timer_${widget.quiz.id}_$_studentId';
    final savedRemaining = await TimerService.getSavedRemainingSeconds(_timerPersistKey);
    if (savedRemaining != null && savedRemaining < _timerService.totalSeconds) {
      _timerService.setRemainingSeconds(savedRemaining);
      debugPrint('⏱️ [ExamScreen] Restored timer: $savedRemaining seconds remaining');
    }

    // Cek pelanggaran yang tersimpan
    await _violationService.restorePersisted(widget.quiz.id);

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

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      if (_answers.isNotEmpty || _essayAnswers.isNotEmpty) {
        _showAutoSaveNotification();
      }
    }
  }

  void _showAutoSaveNotification() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(LucideIcons.save, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Jawabanmu telah aman tersimpan dengan fitur Autosave!',
                style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF10B981), // kGreen
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFF1A1F3C), width: 2), // kNavy
        ),
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.all(20),
      ),
    );
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
        await TimerService.clearPersistedTimer('exam_timer_${widget.quiz.id}_$_studentId');
        await ViolationService.clearPersisted(widget.quiz.id);

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
              SnackBar(content: Text(result['message'] ?? 'Gagal menyimpan jawaban ke server.', style: GoogleFonts.inter(fontWeight: FontWeight.bold))),
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
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: _onBackground, width: 2),
        ),
        title: Row(
          children: [
            const Icon(LucideIcons.wifiOff, color: _error, size: 24),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Koneksi Terputus',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, color: _onBackground, fontSize: 20),
              ),
            ),
          ],
        ),
        content: Text(
          'Gagal mengirim jawaban karena tidak ada koneksi internet atau server sedang sibuk.\n\n'
          'Jangan panik! Seluruh jawaban Anda sudah tersimpan dengan aman di memori perangkat ini.\n\n'
          'Silakan cari koneksi Wi-Fi atau nyalakan data seluler, lalu tekan tombol Submit kembali.',
          style: GoogleFonts.inter(height: 1.5, color: _onSurfaceVariant, fontSize: 14),
        ),
        actions: [
          _NeoButton(
            text: 'Saya Mengerti',
            color: _primaryContainer,
            textColor: _onBackground,
            onTap: () => Navigator.pop(ctx),
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
    final success = result['success'] == true;

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: const Color(0x99001E2B), // on-background/60
      builder: (ctx) => PopScope(
        canPop: false,
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(24),
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 384), // max-w-sm
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24), // rounded-3xl
              border: Border.all(color: _onBackground, width: 3), // border-[3px]
              boxShadow: const [BoxShadow(color: _onBackground, offset: Offset(10, 10))], // modal-shadow
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Celebration Icon Top
                Transform.translate(
                  offset: const Offset(0, -64), // -mt-16
                  child: Transform.rotate(
                    angle: 0.05, // rotate-3
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: success ? _primaryContainer : _errorContainer,
                        borderRadius: BorderRadius.circular(16), // rounded-2xl
                        border: Border.all(color: _onBackground, width: 3), // border-[3px]
                        boxShadow: const [BoxShadow(color: _onBackground, offset: Offset(6, 6))],
                      ),
                      child: Center(
                        child: Transform.rotate(
                          angle: -0.05, // -rotate-3
                          child: Icon(
                            success ? Icons.celebration : Icons.error_outline,
                            color: _onBackground,
                            size: 40,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Transform.translate(
                  offset: const Offset(0, -40), // Pull up text to compensate for icon
                  child: Column(
                    children: [
                      Text(
                        autoSubmitted ? 'Ujian Dihentikan' : (success ? 'Ujian Selesai!' : 'Terjadi Kesalahan'),
                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 32, color: _onBackground), // headline-lg
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        success ? 'Jawaban berhasil disimpan.' : (result['message'] ?? 'Gagal menyimpan jawaban.'),
                        style: GoogleFonts.inter(fontWeight: FontWeight.w400, fontSize: 16, color: _onSurfaceVariant), // body-md
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      if (success) ...[
                        if (hasEssay)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: _surfaceContainerLow,
                              borderRadius: BorderRadius.circular(16), // rounded-2xl
                              border: Border.all(color: _onBackground, width: 2), // border-2
                              boxShadow: const [BoxShadow(color: _onBackground, offset: Offset(4, 4))],
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.info, color: _primary, size: 24),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Nilai akhir menunggu penilaian guru untuk soal essay',
                                    style: GoogleFonts.inter(fontWeight: FontWeight.w400, fontSize: 14, color: _onSurfaceVariant, height: 1.2), // body-sm leading-tight
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: _surfaceContainerLow,
                              borderRadius: BorderRadius.circular(16), // rounded-2xl
                              border: Border.all(color: _onBackground, width: 2), // border-2
                              boxShadow: const [BoxShadow(color: _onBackground, offset: Offset(4, 4))],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('Skor: ', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16, color: _onSurfaceVariant)),
                                Text('$score / $total', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 24, color: _primary)),
                              ],
                            ),
                          ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _surfaceContainerLow,
                            borderRadius: BorderRadius.circular(16), // rounded-2xl
                            border: Border.all(color: _onBackground, width: 2), // border-2
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.gpp_maybe, color: _error, size: 24),
                              const SizedBox(width: 12),
                              Text(
                                'Pelanggaran: ${_violationService.violationCount}',
                                style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16, color: _onSurfaceVariant), // font-body-md font-bold
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 32),
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(ctx);
                          Navigator.pop(context);
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: _primaryContainer,
                            borderRadius: BorderRadius.circular(16), // rounded-2xl
                            border: Border.all(color: _onBackground, width: 2), // custom-button border-2
                            boxShadow: const [BoxShadow(color: _onBackground, offset: Offset(4, 4))],
                          ),
                          child: Center(
                            child: Text(
                              'OK / Kembali',
                              style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 18, color: _onPrimaryContainer), // font-bold text-lg
                            ),
                          ),
                        ),
                      ),
                    ],
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
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 400),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _onBackground, width: 2),
            boxShadow: const [BoxShadow(color: _onBackground, offset: Offset(4, 4))],
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Kumpulkan Jawaban?',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 24, color: _onBackground),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              _buildStatRow('Jumlah Terjawab', '$answered / ${widget.quiz.questions.length} Soal'),
              const SizedBox(height: 12),
              _buildStatRow('Total Pelanggaran', '${_violationService.violationCount}'),
              const SizedBox(height: 24),
              Text('Pastikan semua jawaban sudah benar sebelum mengumpulkan. Tindakan ini tidak dapat dibatalkan.',
                style: GoogleFonts.inter(fontSize: 14, color: _onSurfaceVariant, height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              _NeoButton(
                text: 'Kumpulkan Sekarang',
                color: _primaryContainer,
                textColor: _onBackground,
                width: double.infinity,
                onTap: () {
                  Navigator.pop(ctx);
                  _submitExam();
                },
              ),
              const SizedBox(height: 12),
              _NeoButton(
                text: 'Periksa Kembali',
                color: Colors.white,
                textColor: _onBackground,
                width: double.infinity,
                onTap: () => Navigator.pop(ctx),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _onBackground, width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 16, color: _onBackground)),
          Text(value, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: _onBackground)),
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
    WidgetsBinding.instance.removeObserver(this);
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
            backgroundColor: _background,
            body: SafeArea(
              child: Column(
                children: [
                  _buildHeader(),
                  if (_showViolationWarning) _buildWarningBanner(),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.only(top: 24, left: 16, right: 16, bottom: 40),
                      child: Column(
                        children: [
                          _buildViolationBadge(),
                          const SizedBox(height: 24),
                          _buildQuestionCard(),
                        ],
                      ),
                    ),
                  ),
                  _buildBottomNav(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 80,
      width: double.infinity,
      decoration: const BoxDecoration(
        color: _surface,
        border: Border(bottom: BorderSide(color: _onBackground, width: 1)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.quiz.title,
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                    color: _onBackground,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          _buildTimerCard(),
        ],
      ),
    );
  }

  Widget _buildTimerCard() {
    bool isCritical = _timerService.isCritical;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isCritical ? _errorContainer : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _onBackground, width: 1),
        boxShadow: const [BoxShadow(color: _onBackground, offset: Offset(4, 4))],
      ),
      child: Row(
        children: [
          Icon(Icons.timer, color: isCritical ? _error : _primary, size: 20),
          const SizedBox(width: 8),
          Text(
            _timerService.formattedTime,
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w700,
              fontSize: 20,
              color: isCritical ? _error : _onBackground,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViolationBadge() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: _error,
          border: Border.all(color: _onBackground, width: 1),
          boxShadow: const [BoxShadow(color: _onBackground, offset: Offset(2, 2))],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.gpp_maybe, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              'Pelanggaran: ${_violationService.violationCount}',
              style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 12, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWarningBanner() {
    return Container(
      width: double.infinity,
      color: _error,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Text(
            _lastViolationMsg.toUpperCase(),
            style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 14, color: Colors.white),
          ),
        ],
      ),
    ).animate()
      .fadeIn(duration: 300.ms)
      .shake(hz: 8, curve: Curves.easeInOutCubic, duration: 500.ms);
  }

  Widget _buildQuestionCard() {
    if (widget.quiz.questions.isEmpty) return const SizedBox();

    final qIndex = _questionOrder[_currentIndex];
    final q = widget.quiz.questions[qIndex];
    final selectedAnswer = _answers[q.id];
    final selectedEssay = _essayAnswers[q.id] ?? '';
    final oOrder = _optionOrder[q.id] ?? [];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _onBackground, width: 1),
        boxShadow: const [BoxShadow(color: _onBackground, offset: Offset(4, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Soal ${_currentIndex + 1}',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 20, color: _onBackground),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: _tertiaryContainer,
                  border: Border.all(color: _onBackground, width: 1),
                ),
                child: Text(
                  '${q.points} Poin',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 12, color: _onTertiaryContainer),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (q.imageUrl != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                q.imageUrl!,
                width: double.infinity,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 24),
          ],
          Text(
            q.question,
            style: GoogleFonts.inter(fontWeight: FontWeight.w400, fontSize: 16, height: 1.6, color: _onBackground),
          ),
          const SizedBox(height: 24),
          if (q.questionType == 'essay') ...[
            TextFormField(
              key: ValueKey(q.id),
              initialValue: selectedEssay,
              maxLines: 8,
              onChanged: (val) => _selectAnswer(q.id, val, 'essay'),
              style: GoogleFonts.inter(fontSize: 16, color: _onBackground),
              decoration: InputDecoration(
                hintText: 'Tulis jawaban Anda di sini...',
                hintStyle: GoogleFonts.inter(color: _onSurfaceVariant),
                filled: true,
                fillColor: _surfaceContainerLow,
                border: const OutlineInputBorder(
                  borderSide: BorderSide(color: _onBackground, width: 1),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: _onBackground, width: 2),
                ),
              ),
            ),
          ] else ...[
            ...List.generate(oOrder.length, (i) {
              final oi = oOrder[i];
              bool isSelected = false;
              if (q.questionType == 'multipleChoice' || q.questionType == 'multipleAnswer') {
                isSelected = selectedAnswer == oi;
              } else {
                isSelected = (selectedAnswer is List) && selectedAnswer.contains(oi);
              }

              final letters = ['A', 'B', 'C', 'D', 'E'];
              final letter = i < letters.length ? letters[i] : (i+1).toString();

              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _OptionButton(
                  letter: letter,
                  text: q.options[oi],
                  isSelected: isSelected,
                  onTap: () {
                    if (q.questionType == 'multipleChoice') {
                      _selectAnswer(q.id, oi, 'multipleChoice');
                    } else {
                      List current = [];
                      if (selectedAnswer is List) current = List.from(selectedAnswer);
                      if (current.contains(oi)) {
                        current.remove(oi);
                      } else {
                        current.add(oi);
                      }
                      _selectAnswer(q.id, current, 'multipleAnswer');
                    }
                  },
                ),
              );
            }),
          ]
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    int answeredCount = _answers.length + _essayAnswers.length;
    double progress = widget.quiz.questions.isEmpty ? 0 : answeredCount / widget.quiz.questions.length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: _surface,
        border: Border(top: BorderSide(color: _onBackground, width: 1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              _NeoButtonIcon(
                icon: Icons.chevron_left,
                color: _surfaceContainerHighest,
                onTap: _currentIndex > 0
                    ? () => setState(() => _currentIndex--)
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      '$answeredCount / ${widget.quiz.questions.length} Soal Terjawab',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 12, color: _onSurfaceVariant),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      height: 8,
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: _onBackground,
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: progress,
                        child: Container(
                          decoration: const BoxDecoration(
                            color: _primaryContainer,
                            border: Border(right: BorderSide(color: _onBackground, width: 1)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              if (_currentIndex < widget.quiz.questions.length - 1)
                _NeoButtonTextIcon(
                  text: 'Next',
                  icon: Icons.chevron_right,
                  color: _primaryContainer,
                  textColor: _onPrimaryContainer,
                  onTap: () => setState(() => _currentIndex++),
                )
              else
                _NeoButtonTextIcon(
                  text: 'Submit',
                  icon: Icons.send,
                  color: _primary,
                  textColor: Colors.white,
                  onTap: _confirmSubmit,
                ),
            ],
          ),
          const SizedBox(height: 16),
          _NeoButton(
            text: 'Daftar Soal',
            icon: Icons.grid_view,
            color: _secondaryContainer,
            textColor: _onBackground,
            width: double.infinity,
            onTap: _showQuestionGrid,
          ),
        ],
      ),
    );
  }

  void _showQuestionGrid() {
    showDialog(
      context: context,
      barrierColor: const Color(0xB2073446), // rgba(7, 52, 70, 0.7)
      builder: (ctx) {
        return _QuestionGridModal(
          quiz: widget.quiz,
          currentIndex: _currentIndex,
          answers: _answers,
          essayAnswers: _essayAnswers,
          questionOrder: _questionOrder,
          onSelectQuestion: (index) {
            setState(() => _currentIndex = index);
            Navigator.pop(ctx);
          },
        );
      },
    );
  }
}

class _QuestionGridModal extends StatelessWidget {
  final Quiz quiz;
  final int currentIndex;
  final Map<String, dynamic> answers;
  final Map<String, String> essayAnswers;
  final List<int> questionOrder;
  final Function(int) onSelectQuestion;

  const _QuestionGridModal({
    required this.quiz,
    required this.currentIndex,
    required this.answers,
    required this.essayAnswers,
    required this.questionOrder,
    required this.onSelectQuestion,
  });

  @override
  Widget build(BuildContext context) {
    int answeredCount = answers.length + essayAnswers.length;
    double progress = quiz.questions.isEmpty ? 0 : answeredCount / quiz.questions.length;
    int progressPercent = (progress * 100).round();

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 448, maxHeight: 795),
        decoration: BoxDecoration(
          color: Colors.white, // surface-container-lowest
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _onBackground, width: 2),
          boxShadow: const [BoxShadow(color: _onBackground, offset: Offset(4, 4))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.only(left: 24, right: 24, top: 32, bottom: 16),
                  decoration: const BoxDecoration(
                    color: _surface,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
                    border: Border(bottom: BorderSide(color: _onBackground, width: 2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Daftar Soal',
                            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 28, color: _onBackground),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: _surfaceContainerHigh,
                                border: Border.all(color: _onBackground, width: 2),
                              ),
                              child: const Center(child: Icon(Icons.close, color: _onBackground)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        quiz.title,
                        style: GoogleFonts.inter(fontWeight: FontWeight.w400, fontSize: 14, color: _onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: -10,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: _tertiary,
                      border: Border.all(color: _onBackground, width: 2),
                    ),
                    child: Text(
                      'UJIAN AKTIF',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 12, color: _onTertiary),
                    ),
                  ),
                ),
              ],
            ),
            // Grid Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 5,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: quiz.questions.length,
                      itemBuilder: (ctx, i) {
                        final qId = quiz.questions[questionOrder[i]].id;
                        final isAnswered = answers.containsKey(qId) || (essayAnswers.containsKey(qId) && essayAnswers[qId]!.isNotEmpty);
                        final isCurrent = i == currentIndex;

                        return GestureDetector(
                          onTap: () => onSelectQuestion(i),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isCurrent 
                                  ? _tertiaryContainer 
                                  : (isAnswered ? _primaryContainer : _surfaceContainerLow),
                              border: Border.all(color: _onBackground, width: isCurrent ? 4 : 2),
                              boxShadow: isAnswered && !isCurrent
                                  ? const [BoxShadow(color: _onBackground, offset: Offset(2, 2))]
                                  : null,
                            ),
                            child: Center(
                              child: Text(
                                '${i + 1}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 20,
                                  color: isCurrent 
                                      ? _onTertiaryContainer 
                                      : (isAnswered ? _onPrimaryContainer : _onSurfaceVariant),
                                ),
                              ),
                            ).animate(target: isCurrent ? 1 : 0).shimmer(duration: 1000.ms),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 32),
                    // Progress Section
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _onBackground, width: 2),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('PROGRESS PENGERJAAN', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 12, color: _onSurfaceVariant)),
                              Text('$progressPercent%', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 12, color: _onBackground)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Container(
                            height: 12,
                            width: double.infinity,
                            padding: const EdgeInsets.all(1),
                            decoration: BoxDecoration(
                              color: _onBackground,
                              border: Border.all(color: _onBackground, width: 2),
                            ),
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: progress,
                              child: Container(color: _primaryContainer),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Legend & Footer
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: _surface,
                border: Border(top: BorderSide(color: _onBackground, width: 2)),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(10)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildLegend(color: _primaryContainer, label: 'Terjawab', hasShadow: true),
                      _buildLegend(color: _surfaceContainerLow, label: 'Belum', hasShadow: false),
                      _buildLegend(color: _tertiaryContainer, label: 'Aktif', hasBorder: true),
                    ],
                  ),
                  const SizedBox(height: 24),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: _primary,
                        border: Border.all(color: _onBackground, width: 2),
                        boxShadow: const [BoxShadow(color: _onBackground, offset: Offset(4, 4))],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Kembali ke Soal', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 20, color: Colors.white)),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_right_alt, color: Colors.white),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend({required Color color, required String label, bool hasShadow = false, bool hasBorder = false}) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            border: Border.all(color: _onBackground, width: hasBorder ? 3 : 2),
            boxShadow: hasShadow ? const [BoxShadow(color: _onBackground, offset: Offset(2, 2))] : null,
          ),
        ),
        const SizedBox(width: 8),
        Text(label.toUpperCase(), style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 12, color: _onSurfaceVariant)),
      ],
    );
  }
}

// ─── Shared Components ──────────────────────────────────────────────────

class _OptionButton extends StatefulWidget {
  final String letter;
  final String text;
  final bool isSelected;
  final VoidCallback onTap;

  const _OptionButton({
    required this.letter,
    required this.text,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_OptionButton> createState() => _OptionButtonState();
}

class _OptionButtonState extends State<_OptionButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        transform: Matrix4.translationValues(
          widget.isSelected || _isPressed ? 2 : 0,
          widget.isSelected || _isPressed ? 2 : 0,
          0,
        ),
        decoration: BoxDecoration(
          color: widget.isSelected ? _primaryContainer : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _onBackground, width: 1),
          boxShadow: widget.isSelected || _isPressed
              ? const [BoxShadow(color: _onBackground, offset: Offset(2, 2))]
              : const [BoxShadow(color: _onBackground, offset: Offset(4, 4))],
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: widget.isSelected ? _primaryContainer : _surfaceContainerLow,
                border: Border.all(color: _onBackground, width: 1),
              ),
              child: Center(
                child: Text(
                  widget.letter,
                  style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16, color: _onBackground),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                widget.text,
                style: GoogleFonts.inter(fontWeight: FontWeight.w400, fontSize: 16, color: _onBackground),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NeoButton extends StatefulWidget {
  final String text;
  final IconData? icon;
  final Color color;
  final Color textColor;
  final double? width;
  final VoidCallback onTap;

  const _NeoButton({
    required this.text,
    this.icon,
    required this.color,
    required this.textColor,
    this.width,
    required this.onTap,
  });

  @override
  State<_NeoButton> createState() => _NeoButtonState();
}

class _NeoButtonState extends State<_NeoButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        width: widget.width,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        transform: Matrix4.translationValues(
          _isPressed ? 2 : 0,
          _isPressed ? 2 : 0,
          0,
        ),
        decoration: BoxDecoration(
          color: widget.color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _onBackground, width: 1),
          boxShadow: _isPressed
              ? const []
              : const [BoxShadow(color: _onBackground, offset: Offset(4, 4))],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (widget.icon != null) ...[
              Icon(widget.icon, size: 20, color: widget.textColor),
              const SizedBox(width: 8),
            ],
            Text(
              widget.text,
              style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14, color: widget.textColor),
            ),
          ],
        ),
      ),
    );
  }
}

class _NeoButtonIcon extends StatefulWidget {
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _NeoButtonIcon({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  State<_NeoButtonIcon> createState() => _NeoButtonIconState();
}

class _NeoButtonIconState extends State<_NeoButtonIcon> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.onTap == null;

    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => {if (!isDisabled) setState(() => _isPressed = true)},
      onTapUp: (_) => {if (!isDisabled) setState(() => _isPressed = false)},
      onTapCancel: () => {if (!isDisabled) setState(() => _isPressed = false)},
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        width: 48,
        height: 48,
        transform: Matrix4.translationValues(
          _isPressed || isDisabled ? 2 : 0,
          _isPressed || isDisabled ? 2 : 0,
          0,
        ),
        decoration: BoxDecoration(
          color: isDisabled ? Colors.grey.shade300 : widget.color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _onBackground, width: 1),
          boxShadow: _isPressed || isDisabled
              ? const []
              : const [BoxShadow(color: _onBackground, offset: Offset(4, 4))],
        ),
        child: Center(
          child: Icon(widget.icon, color: isDisabled ? Colors.grey.shade500 : _onBackground, size: 24),
        ),
      ),
    );
  }
}

class _NeoButtonTextIcon extends StatefulWidget {
  final String text;
  final IconData icon;
  final Color color;
  final Color textColor;
  final VoidCallback onTap;

  const _NeoButtonTextIcon({
    required this.text,
    required this.icon,
    required this.color,
    required this.textColor,
    required this.onTap,
  });

  @override
  State<_NeoButtonTextIcon> createState() => _NeoButtonTextIconState();
}

class _NeoButtonTextIconState extends State<_NeoButtonTextIcon> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        transform: Matrix4.translationValues(
          _isPressed ? 2 : 0,
          _isPressed ? 2 : 0,
          0,
        ),
        decoration: BoxDecoration(
          color: widget.color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _onBackground, width: 1),
          boxShadow: _isPressed
              ? const []
              : const [BoxShadow(color: _onBackground, offset: Offset(4, 4))],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.text,
              style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16, color: widget.textColor),
            ),
            const SizedBox(width: 8),
            Icon(widget.icon, color: widget.textColor, size: 24),
          ],
        ),
      ),
    );
  }
}
