import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../../../config/theme.dart';
import '../../../widgets/app_shell.dart';
import '../../../services/quiz_service.dart';
import '../../../services/upload_service.dart';
import '../../../services/notifikasi_service.dart';
import '../../../models/quiz_model.dart';
import 'package:google_fonts/google_fonts.dart';

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
  final _jumlahSoalCtrl = TextEditingController(text: '1');
  
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
      _jumlahSoalCtrl.text = _questions.length.toString();
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

  void _onJumlahSoalChanged(String val) {
    final n = int.tryParse(val);
    if (n == null || n <= 0 || n > 50) return;
    
    setState(() {
      if (n > _questions.length) {
        for (int i = _questions.length; i < n; i++) {
          _questions.add(_QuestionForm());
        }
      } else if (n < _questions.length) {
        for (int i = _questions.length - 1; i >= n; i--) {
          _questions[i].dispose();
          _questions.removeAt(i);
        }
      }
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
        if (q.correctAnswers.where((ans) => ans < filledOptions).isEmpty) {
          _showError('Soal ${i + 1} harus memiliki minimal 1 jawaban benar yang merujuk ke opsi terisi');
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
      'maxViolations': 5, 
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
            content: Text(isEditing ? 'Kuis berhasil diupdate!' : 'Kuis berhasil dibuat!', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
            backgroundColor: AppTheme.success,
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
        content: Text(msg, style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  void dispose() {
    _jumlahSoalCtrl.dispose();
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
            style: GoogleFonts.poppins(fontWeight: FontWeight.w900, letterSpacing: -0.5),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
              child: PremiumElevatedButton(
                onPressed: _isSaving ? null : _save,
                icon: _isSaving ? null : LucideIcons.save,
                iconSize: 14,
                color: AppTheme.indigoPrimary,
                textColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                radius: 12,
                child: _isSaving
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(
                        'Simpan',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(24),
            children: [
              const _SectionLabel(label: 'INFORMASI KUIS', icon: LucideIcons.info),
              const SizedBox(height: 12),

              _buildField('Judul Ujian', _titleCtrl, 'Masukkan judul kuis', LucideIcons.type, theme, isDark),
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
                activeColor: AppTheme.success,
              ),

              const SizedBox(height: 28),

              Row(
                children: [
                  const _SectionLabel(label: 'DAFTAR SOAL UJIAN', icon: LucideIcons.helpCircle),
                  const Spacer(),
                  Container(
                    width: 90,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Theme.of(context).dividerColor),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: TextFormField(
                      controller: _jumlahSoalCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      textAlign: TextAlign.center,
                      onChanged: _onJumlahSoalChanged,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w800, color: isDark ? Colors.white : AppTheme.textLight),
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: 'Jml',
                        hintStyle: Theme.of(context).textTheme.labelLarge?.copyWith(color: isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('soal', style: GoogleFonts.poppins(fontWeight: FontWeight.w800, color: theme.colorScheme.onSurface.withAlpha(160))),
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
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _addQuestion,
                  icon: const Icon(LucideIcons.plusCircle, size: 16),
                  label: Text('Tambah Soal', style: GoogleFonts.poppins(fontWeight: FontWeight.w800)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.indigoPrimary,
                    side: const BorderSide(color: AppTheme.indigoPrimary, width: 1.2),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
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
    Color activeColor = AppTheme.indigoPrimary,
    Widget? extraAction,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: value ? activeColor.withAlpha(isDark ? 55 : 30) : Theme.of(context).dividerColor,
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: value ? activeColor.withAlpha(20) : Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 18,
              color: value ? activeColor : isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : AppTheme.textLight),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600,
                    color: isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt),
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
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700, color: isDark ? Colors.white : AppTheme.textLight),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
        hintText: hint,
        hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(color: isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt),
        prefixIcon: Icon(icon, size: 18, color: isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Theme.of(context).dividerColor, width: 1.2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Theme.of(context).dividerColor, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppTheme.indigoPrimary, width: 2),
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
        Icon(icon, size: 14, color: AppTheme.indigoPrimary),
        const SizedBox(width: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900,
            letterSpacing: 1.0,
            color: AppTheme.indigoPrimary),
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
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).dividerColor,
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.indigoPrimary.withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.indigoPrimary.withAlpha(50)),
                ),
                child: Text(
                  'Soal ${widget.index + 1}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w900,
                    color: AppTheme.indigoPrimary),
                ),
              ),
              const SizedBox(width: 12),
              
              Expanded(
                child: Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Theme.of(context).dividerColor),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: form.questionType,
                      isExpanded: true,
                      dropdownColor: Theme.of(context).colorScheme.surface,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800, color: widget.isDark ? Colors.white : AppTheme.textLight),
                      items: const [
                        DropdownMenuItem(value: 'multipleChoice', child: Text('Pilihan Ganda')),
                        DropdownMenuItem(value: 'multipleAnswer', child: Text('Pilihan Ganda (Banyak Jawaban)')),
                        DropdownMenuItem(value: 'complexCheckbox', child: Text('Pilihan Ganda (Kompleks)')),
                        DropdownMenuItem(value: 'essay', child: Text('Uraian')),
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
                width: 75,
                height: 40,
                child: TextFormField(
                  controller: form.pointsCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w900, color: widget.isDark ? Colors.white : AppTheme.textLight),
                  decoration: InputDecoration(
                    labelText: 'Poin',
                    labelStyle: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Theme.of(context).dividerColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Theme.of(context).dividerColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppTheme.indigoPrimary),
                    ),
                  ),
                ),
              ),
              if (widget.onRemove != null) ...[
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(LucideIcons.trash2, size: 18, color: AppTheme.error),
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
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700, color: widget.isDark ? Colors.white : AppTheme.textLight),
            decoration: InputDecoration(
              hintText: 'Tulis pertanyaan kuis di sini...',
              hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(color: widget.isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Theme.of(context).dividerColor, width: 1.2),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Theme.of(context).dividerColor, width: 1.2),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppTheme.indigoPrimary, width: 2),
              ),
            ),
          ),

          const SizedBox(height: 12),

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
                      decoration: const BoxDecoration(color: AppTheme.error, shape: BoxShape.circle),
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
                : const Icon(LucideIcons.image, size: 14),
              label: Text(
                _isUploading ? 'Mengupload...' : 'Sisipkan Gambar', 
                style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.indigoPrimary,
                side: const BorderSide(color: AppTheme.indigoPrimary, width: 1.0),
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
              style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
                color: widget.isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt),
            ),
            const SizedBox(height: 10),

            ...List.generate(form.optionCtrls.length, (oi) {
              final isCorrect = form.correctAnswers.contains(oi);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
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
                                ? AppTheme.success
                                : widget.theme.colorScheme.onSurface.withAlpha(160),
                            size: 22,
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
                        activeColor: AppTheme.success,
                      ),
                    Expanded(
                      child: TextFormField(
                        controller: form.optionCtrls[oi],
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700,
                          color: widget.isDark ? Colors.white : AppTheme.textLight),
                        decoration: InputDecoration(
                          hintText: 'Opsi ${String.fromCharCode(65 + oi)}',
                          hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(color: widget.isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          filled: true,
                          fillColor: isCorrect
                              ? AppTheme.success.withAlpha(widget.isDark ? 20 : 10)
                              : Theme.of(context).colorScheme.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: isCorrect ? AppTheme.success.withAlpha(160) : Theme.of(context).dividerColor,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: isCorrect ? AppTheme.success.withAlpha(160) : Theme.of(context).dividerColor,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: AppTheme.indigoPrimary, width: 2),
                          ),
                        ),
                      ),
                    ),
                    if (form.optionCtrls.length > 2)
                      IconButton(
                        icon: const Icon(LucideIcons.x, size: 16, color: AppTheme.error),
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
                icon: const Icon(LucideIcons.plusCircle, size: 14),
                label: Text('Tambah Opsi', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800)),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.indigoPrimary,
                ),
              ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: Row(
                children: [
                  Icon(LucideIcons.alignLeft, size: 15, color: (widget.isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Siswa akan menjawab berupa teks uraian / essay',
                      style: GoogleFonts.poppins(
                        color: (widget.isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
