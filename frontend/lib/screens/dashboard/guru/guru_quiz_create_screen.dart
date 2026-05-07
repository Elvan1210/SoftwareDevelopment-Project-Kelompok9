import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../../../config/theme.dart';
import '../../../widgets/app_shell.dart';
import '../../../services/quiz_service.dart';
import '../../../services/upload_service.dart';
import '../../../services/notifikasi_service.dart';
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
  
  bool _isSecureMode = true;
  bool _isActive = true;
  bool _isScheduled = false;
  bool _shuffleQuestions = false;
  bool _shuffleOptions = false;
  
  DateTime? _scheduledAt;
  DateTime? _closedAt;
  
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
      _isSecureMode = q.isSecureMode;
      _isActive = q.isActive;
      _isScheduled = q.isScheduled;
      _shuffleQuestions = q.shuffleQuestions;
      _shuffleOptions = q.shuffleOptions;
      _scheduledAt = q.scheduledAt;
      _closedAt = q.closedAt;

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

  Future<void> _pickSchedule() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _scheduledAt ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null) return;

    if (!mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_scheduledAt ?? DateTime.now()),
    );
    if (time == null) return;

    setState(() {
      _scheduledAt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
      _isScheduled = true;
      _isActive = false;
    });
  }

  Future<void> _pickCloseTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _closedAt ?? _scheduledAt ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null) return;

    if (!mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_closedAt ?? _scheduledAt ?? DateTime.now()),
    );
    if (time == null) return;

    setState(() {
      _closedAt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isScheduled && _scheduledAt == null) {
      _showError('Jadwal rilis otomatis harus diatur');
      return;
    }

    for (int i = 0; i < _questions.length; i++) {
      final q = _questions[i];
      if (q.questionCtrl.text.trim().isEmpty) {
        _showError('Soal ${i + 1} belum diisi');
        return;
      }
      
      if (q.questionType != 'essay') {
        final filledOptions = q.optionCtrls.where((c) => c.text.trim().isNotEmpty).length;
        if (filledOptions < 2) {
          _showError('Soal ${i + 1} harus memiliki minimal 2 opsi jawaban');
          return;
        }
        if (q.correctAnswers.isEmpty) {
          _showError('Soal ${i + 1} harus memiliki minimal 1 jawaban benar');
          return;
        }
      }
    }

    setState(() => _isSaving = true);

    final questions = _questions.asMap().entries.map((entry) {
      final i = entry.key;
      final q = entry.value;
      
      List<String> opts = [];
      if (q.questionType != 'essay') {
        opts = q.optionCtrls
            .where((c) => c.text.trim().isNotEmpty)
            .map((c) => c.text.trim())
            .toList();
      }

      return {
        'id': 'q_$i',
        'questionType': q.questionType,
        'question': q.questionCtrl.text.trim(),
        'options': opts,
        'correctAnswers': q.questionType == 'essay' ? [] : q.correctAnswers.where((ans) => ans < opts.length).toList(),
        'points': int.tryParse(q.pointsCtrl.text) ?? 10,
        'imageUrl': q.imageUrl,
      };
    }).toList();

    final quizData = {
      'title': _titleCtrl.text.trim(),
      'description': _descCtrl.text.trim(),
      'subject': 'Umum',
      'createdBy': widget.userData['id']?.toString() ?? widget.userData['_id']?.toString() ?? '',
      'createdByName': widget.userData['nama'] ?? 'Guru',
      'kelasId': widget.teamData['id']?.toString() ?? '',
      'questions': questions,
      'durationMinutes': int.tryParse(_durationCtrl.text) ?? 60,
      'maxViolations': 5, // Default fallback for backward compatibility
      'isSecureMode': _isSecureMode,
      'isActive': _isActive,
      'isScheduled': _isScheduled,
      'shuffleQuestions': _shuffleQuestions,
      'shuffleOptions': _shuffleOptions,
      'scheduledAt': _scheduledAt?.toIso8601String(),
      'closedAt': _closedAt?.toIso8601String(),
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
        if (!isEditing) {
          if (_isActive) {
            NotifikasiService.kirimNotifikasi(
              judul: 'Kuis Baru: ${_titleCtrl.text.trim()}',
              pesan: 'Ujian baru telah ditambahkan ke kelas Anda. Silakan cek menu Ujian!',
              token: widget.token,
              targetKelas: widget.teamData['id']?.toString(),
            );
          } else if (_isScheduled && _scheduledAt != null) {
            NotifikasiService.kirimNotifikasi(
              judul: 'Ujian Dijadwalkan: ${_titleCtrl.text.trim()}',
              pesan: 'Ujian akan dimulai pada ${DateFormat('dd MMM yyyy, HH:mm').format(_scheduledAt!)}.',
              token: widget.token,
              targetKelas: widget.teamData['id']?.toString(),
            );
          }
        }

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
              const _SectionLabel(label: 'INFORMASI KUIS', icon: LucideIcons.info),
              const SizedBox(height: 12),

              _buildField('Judul Kuis', _titleCtrl, 'Masukkan judul kuis', LucideIcons.type, theme, isDark),
              const SizedBox(height: 14),
              _buildField('Deskripsi', _descCtrl, 'Deskripsi singkat kuis', LucideIcons.alignLeft, theme, isDark),
              const SizedBox(height: 24),

              const _SectionLabel(label: 'PENGATURAN UJIAN', icon: LucideIcons.settings),
              const SizedBox(height: 12),

              _buildField('Durasi (menit)', _durationCtrl, '60', LucideIcons.clock, theme, isDark,
                  isNumber: true),

              const SizedBox(height: 16),

              _buildToggleCard(
                title: 'Batas Waktu (Jam Tutup)',
                subtitle: _closedAt != null ? 'Tutup pada: ${DateFormat('dd MMM yyyy HH:mm').format(_closedAt!)}' : 'Ujian otomatis di-submit jika lewat batas waktu',
                icon: LucideIcons.timerOff,
                value: _closedAt != null,
                onChanged: (v) {
                  if (v) {
                    _pickCloseTime();
                  } else {
                    setState(() => _closedAt = null);
                  }
                },
                theme: theme,
                isDark: isDark,
                extraAction: _closedAt != null ? IconButton(
                  icon: const Icon(LucideIcons.edit2, size: 16),
                  onPressed: _pickCloseTime,
                ) : null,
              ),

              const SizedBox(height: 10),

              _buildToggleCard(
                title: 'Secure Exam Mode',
                subtitle: 'Fullscreen, anti-cheat, dan proteksi shortcut',
                icon: _isSecureMode ? LucideIcons.shieldCheck : LucideIcons.shieldOff,
                value: _isSecureMode,
                onChanged: (v) => setState(() => _isSecureMode = v),
                theme: theme,
                isDark: isDark,
              ),

              const SizedBox(height: 10),

              _buildToggleCard(
                title: 'Rilis Otomatis (Terjadwal)',
                subtitle: _scheduledAt != null ? 'Terjadwal: ${DateFormat('dd MMM yyyy HH:mm').format(_scheduledAt!)}' : 'Tentukan jadwal kuis dirilis',
                icon: LucideIcons.calendar,
                value: _isScheduled,
                onChanged: (v) {
                  setState(() => _isScheduled = v);
                  if (v) _pickSchedule();
                },
                theme: theme,
                isDark: isDark,
                extraAction: _isScheduled && _scheduledAt != null ? IconButton(
                  icon: const Icon(LucideIcons.edit2, size: 16),
                  onPressed: _pickSchedule,
                ) : null,
              ),

              const SizedBox(height: 10),

              _buildToggleCard(
                title: 'Acak Urutan Soal',
                subtitle: 'Soal akan ditampilkan acak ke setiap siswa',
                icon: LucideIcons.shuffle,
                value: _shuffleQuestions,
                onChanged: (v) => setState(() => _shuffleQuestions = v),
                theme: theme,
                isDark: isDark,
              ),

              const SizedBox(height: 10),

              _buildToggleCard(
                title: 'Acak Opsi Jawaban',
                subtitle: 'Pilihan ganda akan diacak urutannya',
                icon: LucideIcons.listOrdered,
                value: _shuffleOptions,
                onChanged: (v) => setState(() => _shuffleOptions = v),
                theme: theme,
                isDark: isDark,
              ),

              const SizedBox(height: 10),

              _buildToggleCard(
                title: 'Kuis Aktif Sekarang',
                subtitle: 'Siswa dapat melihat dan mengerjakan kuis ini',
                icon: _isActive ? LucideIcons.checkCircle : LucideIcons.xCircle,
                value: _isActive,
                onChanged: (v) {
                  setState(() {
                    _isActive = v;
                    if (v) _isScheduled = false;
                  });
                },
                theme: theme,
                isDark: isDark,
                activeColor: Colors.green,
              ),

              const SizedBox(height: 28),

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
                  token: widget.token,
                  onRemove: _questions.length > 1 ? () => _removeQuestion(i) : null,
                  onUpdate: () => setState(() {}),
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

  Widget _buildToggleCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
    required ThemeData theme,
    required bool isDark,
    Color activeColor = AppTheme.tealDeep,
    Widget? extraAction,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withAlpha(isDark ? 200 : 255),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: value ? activeColor.withAlpha(60) : theme.colorScheme.onSurface.withAlpha(20),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: value ? activeColor : theme.colorScheme.onSurface.withAlpha(120),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface.withAlpha(120),
                  ),
                ),
              ],
            ),
          ),
          if (extraAction != null) extraAction,
          Switch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: activeColor,
            activeThumbColor: Colors.white,
          ),
        ],
      ),
    );
  }

  Widget _buildField(String label, TextEditingController ctrl, String hint, IconData icon,
      ThemeData theme, bool isDark, {bool isNumber = false}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      inputFormatters: isNumber ? [FilteringTextInputFormatter.digitsOnly] : null,
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

class _QuestionForm {
  final TextEditingController questionCtrl;
  final List<TextEditingController> optionCtrls;
  final TextEditingController pointsCtrl;
  List<int> correctAnswers;
  String questionType;
  String? imageUrl;

  _QuestionForm()
      : questionCtrl = TextEditingController(),
        optionCtrls = List.generate(4, (_) => TextEditingController()),
        pointsCtrl = TextEditingController(text: '10'),
        correctAnswers = [0],
        questionType = 'multipleChoice';

  factory _QuestionForm.fromModel(QuizQuestion q) {
    final form = _QuestionForm();
    form.questionCtrl.text = q.question;
    form.pointsCtrl.text = q.points.toString();
    form.correctAnswers = List.from(q.correctAnswers);
    form.questionType = q.questionType;
    form.imageUrl = q.imageUrl;
    
    form.optionCtrls.clear();
    for (int i = 0; i < q.options.length; i++) {
      form.optionCtrls.add(TextEditingController(text: q.options[i]));
    }
    
    if (q.questionType != 'essay') {
      while (form.optionCtrls.length < 2) {
        form.optionCtrls.add(TextEditingController());
      }
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

class _QuestionCard extends StatefulWidget {
  final int index;
  final _QuestionForm form;
  final bool isDark;
  final ThemeData theme;
  final String token;
  final VoidCallback? onRemove;
  final VoidCallback onUpdate;

  const _QuestionCard({
    required this.index,
    required this.form,
    required this.isDark,
    required this.theme,
    required this.token,
    this.onRemove,
    required this.onUpdate,
  });

  @override
  State<_QuestionCard> createState() => _QuestionCardState();
}

class _QuestionCardState extends State<_QuestionCard> {
  bool _isUploading = false;

  void _addOption() {
    if (widget.form.optionCtrls.length < 6) {
      setState(() {
        widget.form.optionCtrls.add(TextEditingController());
      });
      widget.onUpdate();
    }
  }

  void _removeOption(int index) {
    if (widget.form.optionCtrls.length > 2) {
      setState(() {
        widget.form.optionCtrls[index].dispose();
        widget.form.optionCtrls.removeAt(index);
        
        List<int> newAnswers = [];
        for (int ans in widget.form.correctAnswers) {
          if (ans < index) {
            newAnswers.add(ans);
          } else if (ans > index) {
            newAnswers.add(ans - 1);
          }
        }
        if (newAnswers.isEmpty) {
          newAnswers.add(0);
        }
        widget.form.correctAnswers = newAnswers;
      });
      widget.onUpdate();
    }
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final xFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (xFile == null) return;

    setState(() => _isUploading = true);

    try {
      final bytes = await xFile.readAsBytes();
      final url = await UploadService.uploadFile(
        fileBytes: bytes,
        fileName: xFile.name,
        token: widget.token,
      );

      if (url != null && mounted) {
        setState(() {
          widget.form.imageUrl = url;
          _isUploading = false;
        });
        widget.onUpdate();
      } else {
        if (mounted) {
          setState(() => _isUploading = false);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal upload gambar')));
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _removeImage() {
    setState(() {
      widget.form.imageUrl = null;
    });
    widget.onUpdate();
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
              const SizedBox(width: 12),
              
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: widget.theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: widget.theme.colorScheme.onSurface.withAlpha(30)),
                    ),
                    child: DropdownButton<String>(
                      value: form.questionType,
                      isExpanded: true,
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: widget.theme.colorScheme.onSurface),
                      items: const [
                        DropdownMenuItem(value: 'multipleChoice', child: Text('Pilihan Ganda')),
                        DropdownMenuItem(value: 'multipleAnswer', child: Text('Pilihan Ganda (Banyak Jawaban)')),
                        DropdownMenuItem(value: 'complexCheckbox', child: Text('Pilihan Ganda Kompleks')),
                        DropdownMenuItem(value: 'essay', child: Text('Essay / Uraian')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            form.questionType = val;
                            if (val == 'multipleChoice') {
                              form.correctAnswers = form.correctAnswers.isNotEmpty ? [form.correctAnswers.first] : [0];
                            }
                            if (val != 'essay' && form.optionCtrls.isEmpty) {
                              form.optionCtrls.addAll([TextEditingController(), TextEditingController()]);
                            }
                          });
                          widget.onUpdate();
                        }
                      },
                    ),
                  ),
                ),
              ),
              
              const SizedBox(width: 12),
              SizedBox(
                width: 80,
                child: TextFormField(
                  controller: form.pointsCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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

          const SizedBox(height: 10),

          if (form.imageUrl != null)
            Stack(
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 250),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      form.imageUrl!,
                      width: double.infinity,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: InkWell(
                    onTap: _removeImage,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                      child: const Icon(LucideIcons.x, size: 14, color: Colors.white),
                    ),
                  ),
                ),
              ],
            )
          else
            OutlinedButton.icon(
              onPressed: _isUploading ? null : _pickAndUploadImage,
              icon: _isUploading 
                ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(LucideIcons.image, size: 16),
              label: Text(_isUploading ? 'Mengupload...' : 'Sisipkan Gambar', style: const TextStyle(fontSize: 12)),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),

          const SizedBox(height: 14),

          if (form.questionType != 'essay') ...[
            Text(
              form.questionType == 'multipleChoice' 
                  ? 'OPSI JAWABAN (Pilih satu jawaban benar)'
                  : 'OPSI JAWABAN (Pilih semua jawaban benar)',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: widget.theme.colorScheme.onSurface.withAlpha(120),
              ),
            ),
            const SizedBox(height: 8),

            ...List.generate(form.optionCtrls.length, (oi) {
              final isCorrect = form.correctAnswers.contains(oi);
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    if (form.questionType == 'multipleChoice')
                      Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: InkWell(
                          onTap: () {
                            setState(() => form.correctAnswers = [oi]);
                            widget.onUpdate();
                          },
                          child: Icon(
                            form.correctAnswers.isNotEmpty && form.correctAnswers.first == oi
                                ? LucideIcons.checkCircle2
                                : LucideIcons.circle,
                            color: form.correctAnswers.isNotEmpty && form.correctAnswers.first == oi
                                ? Colors.green
                                : widget.theme.colorScheme.onSurface.withAlpha(100),
                          ),
                        ),
                      )
                    else
                      Checkbox(
                        value: isCorrect,
                        onChanged: (v) {
                          setState(() {
                            if (v == true) {
                              form.correctAnswers.add(oi);
                            } else {
                              form.correctAnswers.remove(oi);
                            }
                          });
                          widget.onUpdate();
                        },
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
                    if (form.optionCtrls.length > 2)
                      IconButton(
                        icon: const Icon(LucideIcons.x, size: 18, color: Colors.red),
                        onPressed: () => _removeOption(oi),
                        visualDensity: VisualDensity.compact,
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
          ] else ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: widget.theme.colorScheme.surface.withAlpha(widget.isDark ? 150 : 240),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: widget.theme.colorScheme.onSurface.withAlpha(20)),
              ),
              child: const Row(
                children: [
                  Icon(LucideIcons.alignLeft, size: 16, color: Colors.grey),
                  SizedBox(width: 10),
                  Text('Siswa akan menjawab berupa teks uraian', style: TextStyle(color: Colors.grey, fontSize: 13)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
