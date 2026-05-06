import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../config/theme.dart';
import '../../../widgets/app_shell.dart';
import '../../../services/quiz_service.dart';
import '../../../models/quiz_model.dart';

class GuruQuizCreateScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String token;
  final dynamic teamData;
  final Quiz? existingQuiz;

  const GuruQuizCreateScreen({
    super.key,
    required this.userData,
    required this.token,
    required this.teamData,
    this.existingQuiz,
  });

  @override
  State<GuruQuizCreateScreen> createState() => _GuruQuizCreateScreenState();
}

class _GuruQuizCreateScreenState extends State<GuruQuizCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _durationCtrl = TextEditingController(text: '60');
  final _maxViolationsCtrl = TextEditingController(text: '5');
  bool _isSecureMode = true;
  bool _isActive = true;
  bool _isSaving = false;

  final List<_QuestionForm> _questions = [];

  bool get isEditing => widget.existingQuiz != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      final q = widget.existingQuiz!;
      _titleCtrl.text = q.title;
      _descCtrl.text = q.description;
      _durationCtrl.text = q.durationMinutes.toString();
      _maxViolationsCtrl.text = q.maxViolations.toString();
      _isSecureMode = q.isSecureMode;
      _isActive = q.isActive;

      for (final question in q.questions) {
        _questions.add(_QuestionForm.fromModel(question));
      }
    }

    if (_questions.isEmpty) {
      _addQuestion();
    }
  }

  void _addQuestion() {
    setState(() {
      _questions.add(_QuestionForm());
    });
  }

  void _removeQuestion(int index) {
    if (_questions.length <= 1) return;
    setState(() {
      _questions.removeAt(index);
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    for (int i = 0; i < _questions.length; i++) {
      final q = _questions[i];
      if (q.questionCtrl.text.trim().isEmpty) {
        _showError('Soal ${i + 1} belum diisi');
        return;
      }
      final filledOptions = q.optionCtrls.where((c) => c.text.trim().isNotEmpty).length;
      if (filledOptions < 2) {
        _showError('Soal ${i + 1} harus memiliki minimal 2 opsi jawaban');
        return;
      }
    }

    setState(() => _isSaving = true);

    final questions = _questions.asMap().entries.map((entry) {
      final i = entry.key;
      final q = entry.value;
      final opts = q.optionCtrls
          .where((c) => c.text.trim().isNotEmpty)
          .map((c) => c.text.trim())
          .toList();
      return {
        'id': 'q_$i',
        'question': q.questionCtrl.text.trim(),
        'options': opts,
        'correctAnswer': q.correctAnswer.clamp(0, opts.length - 1),
        'points': int.tryParse(q.pointsCtrl.text) ?? 10,
      };
    }).toList();

    final quizData = {
      'title': _titleCtrl.text.trim(),
      'description': _descCtrl.text.trim(),
      'subject': 'Umum', // Hardcoded fallback for backend
      'createdBy': widget.userData['id']?.toString() ?? widget.userData['_id']?.toString() ?? '',
      'createdByName': widget.userData['nama'] ?? 'Guru',
      'kelasId': widget.teamData['id']?.toString() ?? '',
      'questions': questions,
      'durationMinutes': int.tryParse(_durationCtrl.text) ?? 60,
      'maxViolations': int.tryParse(_maxViolationsCtrl.text) ?? 5,
      'isSecureMode': _isSecureMode,
      'isActive': _isActive,
    };

    Map<String, dynamic> result;
    if (isEditing) {
      result = await QuizService.updateQuiz(
        token: widget.token,
        quizId: widget.existingQuiz!.id,
        quizData: quizData,
      );
    } else {
      result = await QuizService.createQuiz(
        token: widget.token,
        quizData: quizData,
      );
    }

    if (mounted) {
      setState(() => _isSaving = false);
      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEditing ? 'Kuis berhasil diupdate!' : 'Kuis berhasil dibuat!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        Navigator.pop(context, true);
      } else {
        _showError(result['message'] ?? 'Gagal menyimpan kuis');
      }
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _durationCtrl.dispose();
    _maxViolationsCtrl.dispose();
    for (final q in _questions) {
      q.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AppShell(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: const Icon(LucideIcons.arrowLeft),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            isEditing ? 'Edit Kuis' : 'Buat Kuis Baru',
            style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: -0.5),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _save,
                icon: _isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(LucideIcons.save, size: 18),
                label: Text(
                  _isSaving ? 'Menyimpan...' : 'Simpan',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.tealDeep,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              // ── Quiz Info Section ──────────────────────────────────
              const _SectionLabel(label: 'INFORMASI KUIS', icon: LucideIcons.info),
              const SizedBox(height: 12),

              _buildField('Judul Kuis', _titleCtrl, 'Masukkan judul kuis', LucideIcons.type, theme, isDark),
              const SizedBox(height: 14),
              _buildField('Deskripsi', _descCtrl, 'Deskripsi singkat kuis', LucideIcons.alignLeft, theme, isDark),
              const SizedBox(height: 24),

              // ── Settings Section ──────────────────────────────────
              const _SectionLabel(label: 'PENGATURAN UJIAN', icon: LucideIcons.settings),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _buildField('Durasi (menit)', _durationCtrl, '60', LucideIcons.clock, theme, isDark,
                        isNumber: true),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _buildField('Max Pelanggaran', _maxViolationsCtrl, '5', LucideIcons.alertTriangle, theme, isDark,
                        isNumber: true),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Secure Mode Toggle
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface.withAlpha(isDark ? 200 : 255),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _isSecureMode ? AppTheme.tealDeep.withAlpha(60) : theme.colorScheme.onSurface.withAlpha(20),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isSecureMode ? LucideIcons.shieldCheck : LucideIcons.shieldOff,
                      color: _isSecureMode ? AppTheme.tealDeep : theme.colorScheme.onSurface.withAlpha(120),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Secure Exam Mode',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          Text(
                            'Fullscreen, anti-cheat, dan proteksi shortcut',
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.onSurface.withAlpha(120),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _isSecureMode,
                      onChanged: (v) => setState(() => _isSecureMode = v),
                      activeTrackColor: AppTheme.tealDeep,
                      activeThumbColor: Colors.white,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // Active Toggle
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface.withAlpha(isDark ? 200 : 255),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _isActive ? Colors.green.withAlpha(60) : theme.colorScheme.onSurface.withAlpha(20),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isActive ? LucideIcons.checkCircle : LucideIcons.xCircle,
                      color: _isActive ? Colors.green : theme.colorScheme.onSurface.withAlpha(120),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        'Kuis Aktif',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                    Switch(
                      value: _isActive,
                      onChanged: (v) => setState(() => _isActive = v),
                      activeTrackColor: Colors.green,
                      activeThumbColor: Colors.white,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // ── Questions Section ─────────────────────────────────
              Row(
                children: [
                  _SectionLabel(label: 'SOAL (${_questions.length})', icon: LucideIcons.helpCircle),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: _addQuestion,
                    icon: const Icon(LucideIcons.plusCircle, size: 18),
                    label: const Text('Tambah Soal', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: TextButton.styleFrom(foregroundColor: AppTheme.tealDeep),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              ...List.generate(_questions.length, (i) {
                return _QuestionCard(
                  index: i,
                  form: _questions[i],
                  isDark: isDark,
                  theme: theme,
                  onRemove: _questions.length > 1 ? () => _removeQuestion(i) : null,
                ).animate(delay: (50 * i).ms)
                  .fadeIn(duration: 300.ms)
                  .slideY(begin: 0.03);
              }),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController ctrl, String hint, IconData icon,
      ThemeData theme, bool isDark, {bool isNumber = false}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      validator: (v) => (v == null || v.trim().isEmpty) ? '$label wajib diisi' : null,
      style: TextStyle(fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 20),
        filled: true,
        fillColor: theme.colorScheme.surface.withAlpha(isDark ? 200 : 255),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: theme.colorScheme.onSurface.withAlpha(20)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: theme.colorScheme.onSurface.withAlpha(20)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppTheme.tealDeep, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}

// ── Section Label ───────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  final IconData icon;

  const _SectionLabel({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.tealDeep),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.0,
            color: AppTheme.tealDeep,
          ),
        ),
      ],
    );
  }
}

// ── Question Form Data ──────────────────────────────────────────────────────

class _QuestionForm {
  final TextEditingController questionCtrl;
  final List<TextEditingController> optionCtrls;
  final TextEditingController pointsCtrl;
  int correctAnswer;

  _QuestionForm()
      : questionCtrl = TextEditingController(),
        optionCtrls = List.generate(4, (_) => TextEditingController()),
        pointsCtrl = TextEditingController(text: '10'),
        correctAnswer = 0;

  factory _QuestionForm.fromModel(QuizQuestion q) {
    final form = _QuestionForm();
    form.questionCtrl.text = q.question;
    form.pointsCtrl.text = q.points.toString();
    form.correctAnswer = q.correctAnswer;
    for (int i = 0; i < q.options.length && i < form.optionCtrls.length; i++) {
      form.optionCtrls[i].text = q.options[i];
    }
    // Add more controllers if needed
    while (form.optionCtrls.length < q.options.length) {
      form.optionCtrls.add(TextEditingController(text: q.options[form.optionCtrls.length]));
    }
    return form;
  }

  void dispose() {
    questionCtrl.dispose();
    for (final c in optionCtrls) {
      c.dispose();
    }
    pointsCtrl.dispose();
  }
}

// ── Question Card Widget ────────────────────────────────────────────────────

class _QuestionCard extends StatefulWidget {
  final int index;
  final _QuestionForm form;
  final bool isDark;
  final ThemeData theme;
  final VoidCallback? onRemove;

  const _QuestionCard({
    required this.index,
    required this.form,
    required this.isDark,
    required this.theme,
    this.onRemove,
  });

  @override
  State<_QuestionCard> createState() => _QuestionCardState();
}

class _QuestionCardState extends State<_QuestionCard> {
  void _addOption() {
    if (widget.form.optionCtrls.length < 6) {
      setState(() {
        widget.form.optionCtrls.add(TextEditingController());
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final form = widget.form;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: widget.theme.colorScheme.surface.withAlpha(widget.isDark ? 200 : 255),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: widget.isDark ? Colors.white.withAlpha(15) : Colors.black.withAlpha(8),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(widget.isDark ? 40 : 6),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.tealDeep.withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Soal ${widget.index + 1}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    color: AppTheme.tealDeep,
                  ),
                ),
              ),
              const Spacer(),
              SizedBox(
                width: 80,
                child: TextFormField(
                  controller: form.pointsCtrl,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  decoration: InputDecoration(
                    labelText: 'Poin',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              if (widget.onRemove != null) ...[
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(LucideIcons.trash2, size: 18, color: Colors.red),
                  onPressed: widget.onRemove,
                  tooltip: 'Hapus soal',
                ),
              ],
            ],
          ),

          const SizedBox(height: 14),

          // Question text
          TextFormField(
            controller: form.questionCtrl,
            maxLines: 3,
            style: TextStyle(fontWeight: FontWeight.w600, color: widget.theme.colorScheme.onSurface),
            decoration: InputDecoration(
              hintText: 'Tulis pertanyaan di sini...',
              filled: true,
              fillColor: widget.theme.colorScheme.surface.withAlpha(widget.isDark ? 150 : 240),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: widget.theme.colorScheme.onSurface.withAlpha(20)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: widget.theme.colorScheme.onSurface.withAlpha(20)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppTheme.tealDeep, width: 2),
              ),
            ),
          ),

          const SizedBox(height: 14),

          // Options
          Text(
            'OPSI JAWABAN (tap radio untuk jawaban benar)',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: widget.theme.colorScheme.onSurface.withAlpha(120),
            ),
          ),
          const SizedBox(height: 8),

          ...List.generate(form.optionCtrls.length, (oi) {
            final isCorrect = form.correctAnswer == oi;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Radio<int>.adaptive(
                    value: oi,
                    groupValue: form.correctAnswer,
                    onChanged: (v) => setState(() => form.correctAnswer = v ?? 0),
                    activeColor: Colors.green,
                  ),
                  Expanded(
                    child: TextFormField(
                      controller: form.optionCtrls[oi],
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: widget.theme.colorScheme.onSurface,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Opsi ${String.fromCharCode(65 + oi)}',
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        filled: true,
                        fillColor: isCorrect
                            ? Colors.green.withAlpha(widget.isDark ? 20 : 10)
                            : widget.theme.colorScheme.surface.withAlpha(widget.isDark ? 150 : 240),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: isCorrect ? Colors.green.withAlpha(80) : widget.theme.colorScheme.onSurface.withAlpha(15),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: isCorrect ? Colors.green.withAlpha(80) : widget.theme.colorScheme.onSurface.withAlpha(15),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppTheme.tealDeep, width: 2),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),

          if (form.optionCtrls.length < 6)
            TextButton.icon(
              onPressed: _addOption,
              icon: const Icon(LucideIcons.plusCircle, size: 16),
              label: const Text('Tambah Opsi', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.tealDeep.withAlpha(180),
              ),
            ),
        ],
      ),
    );
  }
}
