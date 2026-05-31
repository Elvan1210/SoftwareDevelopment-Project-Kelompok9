import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../services/quiz_service.dart';
import '../../../models/quiz_model.dart';
import 'siswa_exam_screen.dart';

// --- Tailwind Neo-Brutalist Tokens ---
const Color _onSurface = Color(0xFF001E2B);
const Color _onSurfaceVariant = Color(0xFF414944);
const Color _primary = Color(0xFF3D6754);
const Color _primaryContainer = Color(0xFFB7E5CD);
const Color _secondaryContainer = Color(0xFFB7EDE7);
const Color _tertiaryContainer = Color(0xFFFFD1C0);
const Color _surfaceContainerHighest = Color(0xFFC1E8FF);
const Color _surface = Color(0xFFF4FAFF);
const Color _onBackground = Color(0xFF001E2B);

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
  String _searchQuery = '';

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

    try {
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
              .where((q) => q.isActive || (q.isScheduled && q.scheduledAt != null))
              .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _startExam(Quiz quiz) {
    if (_submittedMap[quiz.id] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Anda sudah mengerjakan kuis ini', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
          backgroundColor: _onSurface,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _ExamStartDialogNeo(
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

  List<Quiz> get _filteredQuizzes {
    if (_searchQuery.isEmpty) return _quizzes;
    return _quizzes.where((q) {
      final qStr = q.title.toLowerCase() + q.subject.toLowerCase();
      return qStr.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: LayoutBuilder(
        builder: (ctx, constraints) {
          final isDesktop = constraints.maxWidth >= 768;

          return RefreshIndicator(
            onRefresh: _loadQuizzes,
            color: _primary,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.only(
                left: isDesktop ? 40 : 16,
                right: isDesktop ? 40 : 16,
                top: 32,
                bottom: 100,
              ),
              children: [
                _buildHeader(isDesktop),
                const SizedBox(height: 48),
                if (_isLoading)
                  _buildLoading(isDesktop)
                else if (_filteredQuizzes.isEmpty)
                  _buildEmpty()
                else
                  _buildGrid(isDesktop),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(bool isDesktop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isDesktop) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Daftar Kuis',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800,
                  fontSize: 48,
                  letterSpacing: -1.92,
                  color: _onSurface,
                  height: 1.1,
                ),
              ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1),
              _buildSearchBar().animate().fadeIn(duration: 400.ms).slideX(begin: 0.1),
            ],
          ),
        ] else ...[
          Text(
            'Daftar Kuis',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w800,
              fontSize: 36,
              letterSpacing: -1.44,
              color: _onSurface,
              height: 1.1,
            ),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1),
          const SizedBox(height: 24),
          _buildSearchBar().animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),
        ],
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      width: 384,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _onSurface, width: 2),
        borderRadius: BorderRadius.circular(999),
        boxShadow: const [BoxShadow(color: _onSurface, offset: Offset(2, 2))],
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          const Icon(LucideIcons.search, color: _onSurfaceVariant, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              style: GoogleFonts.inter(fontSize: 16, color: _onSurface),
              decoration: InputDecoration(
                hintText: 'Cari kuis atau materi...',
                hintStyle: GoogleFonts.inter(fontSize: 16, color: _onSurfaceVariant.withAlpha(153)),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(bool isDesktop) {
    if (!isDesktop) {
      return Column(
        children: _filteredQuizzes.asMap().entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: _QuizCardNeo(
              quiz: entry.value,
              index: entry.key,
              isSubmitted: _submittedMap[entry.value.id] ?? false,
              onStart: () => _startExam(entry.value),
            ),
          );
        }).toList(),
      );
    } else {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 400,
          mainAxisSpacing: 24,
          crossAxisSpacing: 24,
          mainAxisExtent: 380,
        ),
        itemCount: _filteredQuizzes.length,
        itemBuilder: (ctx, i) {
          final quiz = _filteredQuizzes[i];
          return _QuizCardNeo(
            quiz: quiz,
            index: i,
            isSubmitted: _submittedMap[quiz.id] ?? false,
            onStart: () => _startExam(quiz),
          );
        },
      );
    }
  }

  Widget _buildLoading(bool isDesktop) {
    return const Center(
      child: CircularProgressIndicator(color: _primary),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _onSurface, width: 2),
          boxShadow: const [BoxShadow(color: _onSurface, offset: Offset(4, 4))],
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _surfaceContainerHighest,
              shape: BoxShape.circle,
              border: Border.all(color: _onSurface, width: 2),
            ),
            child: const Icon(LucideIcons.clipboardCheck, color: _onSurface, size: 32),
          ),
          const SizedBox(height: 20),
          Text(
            'Belum ada kuis.',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 24, color: _onSurface),
          ),
          const SizedBox(height: 8),
          Text(
            'Kuis dari guru akan muncul di sini.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 16, color: _onSurfaceVariant, fontWeight: FontWeight.w400),
          ),
        ]),
      ),
    );
  }
}

class _QuizCardNeo extends StatefulWidget {
  final Quiz quiz;
  final int index;
  final bool isSubmitted;
  final VoidCallback onStart;

  const _QuizCardNeo({
    required this.quiz,
    required this.index,
    required this.isSubmitted,
    required this.onStart,
  });

  @override
  State<_QuizCardNeo> createState() => _QuizCardNeoState();
}

class _QuizCardNeoState extends State<_QuizCardNeo> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    bool isUpcoming = false;
    if (widget.quiz.isScheduled && widget.quiz.scheduledAt != null && !widget.quiz.isActive) {
      if (widget.quiz.scheduledAt!.isAfter(DateTime.now())) {
        isUpcoming = true;
      }
    }

    bool isClosed = false;
    if (widget.quiz.closedAt != null && DateTime.now().isAfter(widget.quiz.closedAt!)) {
      isClosed = true;
    }

    final bool isDisabled = isClosed || isUpcoming || widget.isSubmitted;
    
    final bgColors = [
      _primaryContainer,
      _secondaryContainer,
      _tertiaryContainer,
      _surfaceContainerHighest
    ];
    final colorIdx = widget.index % bgColors.length;
    final bgColor = isDisabled ? Colors.grey.shade100 : bgColors[colorIdx];

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(
          _isHovered && !isDisabled ? -2 : 0,
          _isHovered && !isDisabled ? -2 : 0,
          0,
        ),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _onSurface, width: 2),
          boxShadow: _isHovered && !isDisabled
              ? const [BoxShadow(color: _onSurface, offset: Offset(6, 6))]
              : const [BoxShadow(color: _onSurface, offset: Offset(4, 4))],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.quiz.isSecureMode) const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.quiz.subject.toUpperCase(),
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                                letterSpacing: 1.2,
                                color: _onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.quiz.title,
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w800,
                                fontSize: 24,
                                height: 1.2,
                                color: _onBackground,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: _onSurface, width: 1.5),
                        ),
                        child: Text(
                          isClosed ? 'DITUTUP' : (widget.isSubmitted ? 'SELESAI' : 'DIBUKA'),
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                            letterSpacing: 0.6,
                            color: _onBackground,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Text(
                      widget.quiz.description.isNotEmpty ? widget.quiz.description : 'Evaluasi kuis. Pastikan koneksi internet stabil.',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                        height: 1.5,
                        color: _onSurfaceVariant,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(LucideIcons.user, size: 16, color: _onSurfaceVariant),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget.quiz.createdByName,
                          style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: _onBackground),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(LucideIcons.fileText, size: 16, color: _onSurfaceVariant),
                      const SizedBox(width: 8),
                      Text(
                        '${widget.quiz.questions.length} Soal',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: _onBackground),
                      ),
                      const SizedBox(width: 24),
                      const Icon(LucideIcons.clock, size: 16, color: _onSurfaceVariant),
                      const SizedBox(width: 8),
                      Text(
                        '${widget.quiz.durationMinutes} Menit',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: _onBackground),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.only(top: 16),
                    decoration: BoxDecoration(
                      border: Border(top: BorderSide(color: _onSurface.withAlpha(50), width: 2)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'TOTAL POIN',
                              style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 12, color: _onSurfaceVariant),
                            ),
                            Text(
                              '${widget.quiz.totalPoints}',
                              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w900, fontSize: 24, color: _onBackground),
                            ),
                          ],
                        ),
                        _KerjakanButton(
                          isDisabled: isDisabled,
                          isSubmitted: widget.isSubmitted,
                          onTap: widget.onStart,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (widget.quiz.isSecureMode)
              Positioned(
                top: -12,
                left: 20,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: _onSurface, width: 2),
                    boxShadow: const [BoxShadow(color: _onSurface, offset: Offset(2, 2))],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.lock, color: Colors.white, size: 14),
                      const SizedBox(width: 8),
                      Text(
                        'SECURE EXAM',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 12, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _KerjakanButton extends StatefulWidget {
  final bool isDisabled;
  final bool isSubmitted;
  final VoidCallback onTap;

  const _KerjakanButton({
    required this.isDisabled,
    required this.isSubmitted,
    required this.onTap,
  });

  @override
  State<_KerjakanButton> createState() => _KerjakanButtonState();
}

class _KerjakanButtonState extends State<_KerjakanButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    if (widget.isDisabled) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _onSurface, width: 2),
        ),
        child: Text(
          widget.isSubmitted ? 'SELESAI' : 'TUTUP',
          style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 14, color: _onSurfaceVariant),
        ),
      );
    }

    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        transform: Matrix4.translationValues(
          _isPressed ? 2 : 0,
          _isPressed ? 2 : 0,
          0,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _onSurface, width: 2),
          boxShadow: _isPressed ? [] : const [BoxShadow(color: _onSurface, offset: Offset(2, 2))],
        ),
        child: Text(
          'KERJAKAN',
          style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 14, color: _onBackground),
        ),
      ),
    );
  }
}

// ─── Neo-Brutalist Exam Start Dialog ────────────────────────────────────────

class _ExamStartDialogNeo extends StatefulWidget {
  final Quiz quiz;
  final VoidCallback onStart;

  const _ExamStartDialogNeo({required this.quiz, required this.onStart});

  @override
  State<_ExamStartDialogNeo> createState() => _ExamStartDialogNeoState();
}

class _ExamStartDialogNeoState extends State<_ExamStartDialogNeo> {
  bool _isStartPressed = false;
  bool _isCancelPressed = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 512),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _onSurface, width: 2),
          boxShadow: const [BoxShadow(color: _onSurface, offset: Offset(8, 8))],
        ),
        padding: const EdgeInsets.all(32),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(width: 40),
                      Expanded(
                        child: Text(
                          'Mulai Ujian?',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w900,
                            fontSize: 32,
                            color: _onSurface,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(LucideIcons.x, color: _onSurface),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: _surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(9999),
                    border: Border.all(color: _onSurface, width: 2),
                  ),
                  child: Text(
                    '${widget.quiz.subject.toUpperCase()} - ${widget.quiz.title}',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: _onBackground,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            // Rules
            Text(
              'Peraturan Ujian',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w800,
                fontSize: 20,
                color: _onSurface,
              ),
            ),
            const SizedBox(height: 16),
            if (widget.quiz.isSecureMode) ...[
              _buildRule(Icons.fullscreen, 'Aplikasi akan masuk mode fullscreen', _primary),
              _buildRule(Icons.block, 'Dilarang pindah aplikasi (Alt + Tab)', const Color(0xFFEF4444)),
              _buildRule(Icons.content_copy, 'Dilarang copy, paste, dan klik kanan', _onSurfaceVariant),
              _buildRule(Icons.report, 'Setiap pelanggaran akan dicatat', const Color(0xFFF59E0B)),
            ] else ...[
              _buildRule(Icons.report, 'Ujian ini tidak menggunakan secure mode', _onSurfaceVariant),
            ],
            const SizedBox(height: 32),
            // Stats Grid
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _onSurface, width: 2),
                boxShadow: const [BoxShadow(color: _onSurface, offset: Offset(4, 4))],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('DURASI', style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 12, color: _onSurfaceVariant)),
                            Text('${widget.quiz.durationMinutes} Menit', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w900, fontSize: 20, color: _onSurface)),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('JUMLAH SOAL', style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 12, color: _onSurfaceVariant)),
                            Text('${widget.quiz.questions.length} Soal', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w900, fontSize: 20, color: _onSurface)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _onSurface, width: 1.5),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.save, size: 20, color: _primary),
                        const SizedBox(width: 12),
                        Text('Jawaban akan auto-save', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14, color: _primary)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            // Actions
            GestureDetector(
              onTap: widget.onStart,
              onTapDown: (_) => setState(() => _isStartPressed = true),
              onTapUp: (_) => setState(() => _isStartPressed = false),
              onTapCancel: () => setState(() => _isStartPressed = false),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 100),
                height: 56,
                transform: Matrix4.translationValues(
                  _isStartPressed ? 2 : 0,
                  _isStartPressed ? 2 : 0,
                  0,
                ),
                decoration: BoxDecoration(
                  color: _primary,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _onSurface, width: 2),
                  boxShadow: _isStartPressed
                      ? const []
                      : const [BoxShadow(color: _onSurface, offset: Offset(4, 4))],
                ),
                child: Center(
                  child: Text(
                    'MULAI SEKARANG',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 0.8, color: Colors.white),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              onTapDown: (_) => setState(() => _isCancelPressed = true),
              onTapUp: (_) => setState(() => _isCancelPressed = false),
              onTapCancel: () => setState(() => _isCancelPressed = false),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 100),
                height: 56,
                transform: Matrix4.translationValues(
                  _isCancelPressed ? 2 : 0,
                  _isCancelPressed ? 2 : 0,
                  0,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _onSurface, width: 2),
                  boxShadow: _isCancelPressed
                      ? const []
                      : const [BoxShadow(color: _onSurface, offset: Offset(2, 2))],
                ),
                child: Center(
                  child: Text(
                    'KEMBALI',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 16, letterSpacing: 0.8, color: _onSurface),
                  ),
                ),
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildRule(IconData icon, String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 24, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15, color: _onBackground),
            ),
          ),
        ],
      ),
    );
  }
}
