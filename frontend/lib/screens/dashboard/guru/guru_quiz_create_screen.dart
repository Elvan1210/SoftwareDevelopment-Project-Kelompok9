import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../../../config/theme.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF001E2B) : const Color(0xFFF4FAFF), // surface
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => Navigator.pop(context),
          color: isDark ? Colors.white : const Color(0xFF001E2B),
        ),
      ),
      body: Form(
        key: _formKey,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              children: [
                // Header
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: const BoxDecoration(
                      color: Color(0xFF8D4D33), // tertiary
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(0),
                        topRight: Radius.circular(10),
                        bottomRight: Radius.circular(0),
                        bottomLeft: Radius.circular(10),
                      ),
                    ),
                    child: Text(
                      'MODUL GURU',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  isEditing ? 'Edit Kuis' : 'Buat Kuis Baru',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : const Color(0xFF001E2B),
                    height: 1.1,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Rancang pengalaman belajar yang menantang dan interaktif untuk siswa Anda.',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: isDark ? Colors.white70 : const Color(0xFF414944), // on-surface-variant
                  ),
                ),
                const SizedBox(height: 32),

                // Section 1: Identitas Kuis
                _NeoCard(
                  isDark: isDark,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(LucideIcons.edit3, color: isDark ? Colors.white : const Color(0xFF001E2B), size: 24),
                          const SizedBox(width: 12),
                          Text(
                            'Identitas Kuis',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : const Color(0xFF001E2B),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildNeoField(
                        label: 'JUDUL KUIS',
                        controller: _titleCtrl,
                        hint: 'Contoh: Dasar Algoritma Modern',
                        isDark: isDark,
                      ),
                      const SizedBox(height: 20),
                      _buildNeoField(
                        label: 'DESKRIPSI SINGKAT',
                        controller: _descCtrl,
                        hint: 'Jelaskan tujuan kuis ini kepada siswa...',
                        isDark: isDark,
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Section 2: Struktur Soal
                _NeoCard(
                  isDark: isDark,
                  backgroundColor: isDark ? const Color(0xFF073446) : const Color(0xFFE8F6FF), // surface-container-low
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Struktur Soal',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: isDark ? Colors.white : const Color(0xFF001E2B),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Tentukan jumlah soal untuk membuat template otomatis.',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: isDark ? Colors.white70 : const Color(0xFF414944),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Row(
                        children: [
                          Container(
                            width: 80,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF001E2B) : Colors.white,
                              border: Border.all(color: isDark ? Colors.white38 : Colors.black, width: 2),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('JUMLAH', style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.black54)),
                                TextFormField(
                                  controller: _jumlahSoalCtrl,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                  textAlign: TextAlign.center,
                                  onChanged: _onJumlahSoalChanged,
                                  style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: isDark ? Colors.white : Colors.black),
                                  decoration: const InputDecoration(
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                    border: InputBorder.none,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: () => _onJumlahSoalChanged(_jumlahSoalCtrl.text),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFB7E5CD), // primary-container
                                border: Border.all(color: Colors.black, width: 2),
                              ),
                              child: Text(
                                'GENERATE',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w900,
                                  color: Colors.black,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Settings Grid
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Pengaturan
                    _NeoCard(
                      isDark: isDark,
                      backgroundColor: isDark ? const Color(0xFF0F4D66) : const Color(0xFFC1E8FF), // surface-container-highest
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(LucideIcons.settings, color: isDark ? Colors.white : const Color(0xFF001E2B), size: 24),
                              const SizedBox(width: 12),
                              Text(
                                'Pengaturan',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? Colors.white : const Color(0xFF001E2B),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          _buildNeoSwitch(
                            title: 'Secure Exam',
                            subtitle: 'Cegah berpindah tab',
                            value: _isSecureMode,
                            onChanged: (v) => setState(() => _isSecureMode = v),
                            isDark: isDark,
                          ),
                          const Divider(color: Colors.black12, height: 24),
                          _buildNeoSwitch(
                            title: 'Acak Urutan Soal',
                            subtitle: 'Urutan pertanyaan berbeda tiap siswa',
                            value: _shuffleQuestions,
                            onChanged: (v) => setState(() => _shuffleQuestions = v),
                            isDark: isDark,
                          ),
                          const Divider(color: Colors.black12, height: 24),
                          _buildNeoSwitch(
                            title: 'Acak Opsi Jawaban',
                            subtitle: 'Urutan pilihan jawaban diacak',
                            value: _shuffleOptions,
                            onChanged: (v) => setState(() => _shuffleOptions = v),
                            isDark: isDark,
                          ),
                          const Divider(color: Colors.black12, height: 24),
                          _buildNeoSwitch(
                            title: 'Rilis Otomatis (Terjadwal)',
                            subtitle: 'Publikasi otomatis pada waktu tertentu',
                            value: _isScheduled,
                            onChanged: (v) {
                              setState(() => _isScheduled = v);
                              if (v && _scheduledAt == null) _pickSchedule();
                              if (v) _isActive = false; // Cannot be active now if scheduled
                            },
                            isDark: isDark,
                          ),
                          if (_isScheduled) ...[
                            const SizedBox(height: 12),
                            Container(
                              margin: const EdgeInsets.only(left: 12),
                              padding: const EdgeInsets.only(left: 16),
                              decoration: BoxDecoration(
                                border: Border(left: BorderSide(color: isDark ? Colors.white54 : const Color(0xFF3D6754), width: 2)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          _scheduledAt != null ? DateFormat('dd MMM yyyy, HH:mm').format(_scheduledAt!) : 'Belum diatur',
                                          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black),
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: _pickSchedule,
                                        style: TextButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                          minimumSize: Size.zero,
                                        ),
                                        child: Text('Ubah', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12, color: const Color(0xFF3D6754))),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const Divider(color: Colors.black12, height: 24),
                          _buildNeoSwitch(
                            title: 'Auto-Submit',
                            subtitle: 'Kirim saat deadline',
                            value: _closedAt != null,
                            onChanged: (v) {
                              if (v) {
                                _pickCloseTime();
                              } else {
                                setState(() => _closedAt = null);
                              }
                            },
                            isDark: isDark,
                          ),
                          const Divider(color: Colors.black12, height: 24),
                          _buildNeoSwitch(
                            title: 'Kuis Aktif Sekarang',
                            subtitle: 'Siswa dapat melihat kuis ini',
                            value: _isActive,
                            onChanged: (v) {
                              setState(() {
                                _isActive = v;
                                if (v) _isScheduled = false; // Disable schedule if forcing active now
                              });
                            },
                            isDark: isDark,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Jadwal & Waktu
                    _NeoCard(
                      isDark: isDark,
                      backgroundColor: isDark ? const Color(0xFF0F4D66) : const Color(0xFFDBF1FF), // surface-container
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(LucideIcons.calendarClock, color: isDark ? Colors.white : const Color(0xFF001E2B), size: 24),
                              const SizedBox(width: 12),
                              Text(
                                'Jadwal & Waktu',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? Colors.white : const Color(0xFF001E2B),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'DURASI PENGERJAAN',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.0,
                              color: isDark ? Colors.white70 : const Color(0xFF414944),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Stack(
                            alignment: Alignment.centerRight,
                            children: [
                              TextFormField(
                                controller: _durationCtrl,
                                keyboardType: TextInputType.number,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w800, color: isDark ? Colors.white : Colors.black),
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: isDark ? const Color(0xFF001E2B) : Colors.white,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: isDark ? Colors.white38 : Colors.black, width: 2)),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: isDark ? Colors.white38 : Colors.black, width: 2)),
                                  focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: Color(0xFF3D6754), width: 2)),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(right: 16),
                                child: Text('MENIT', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w900, color: isDark ? Colors.white70 : Colors.black54)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'BATAS WAKTU (DEADLINE)',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.0,
                              color: isDark ? Colors.white70 : const Color(0xFF414944),
                            ),
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: _pickCloseTime,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF001E2B) : Colors.white,
                                border: Border.all(color: isDark ? Colors.white38 : Colors.black, width: 2),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      _closedAt != null ? DateFormat('dd/MM/yyyy - HH:mm').format(_closedAt!) : 'Pilih batas waktu...',
                                      style: GoogleFonts.inter(
                                        fontSize: 16,
                                        color: _closedAt != null ? (isDark ? Colors.white : Colors.black) : (isDark ? Colors.white54 : Colors.black54),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(LucideIcons.calendar, size: 18, color: isDark ? Colors.white : Colors.black),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '*Kuis akan ditutup secara otomatis sesuai waktu di atas.',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontStyle: FontStyle.italic,
                              color: isDark ? Colors.white54 : const Color(0xFF717974), // outline
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Section 3: Questions
                ...List.generate(_questions.length, (i) {
                  return _QuestionCard(
                    index: i,
                    form: _questions[i],
                    isDark: isDark,
                    token: widget.token,
                    onRemove: _questions.length > 1 ? () => _removeQuestion(i) : null,
                    onUpdate: () => setState(() {}),
                  );
                }),
                
                const SizedBox(height: 24),

                // Save Action
                Center(
                  child: Column(
                    children: [
                      GestureDetector(
                        onTapDown: (_) => setState(() {}), // Implement full pushable later
                        onTap: _isSaving ? null : _save,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: 400,
                              height: 64,
                              color: isDark ? Colors.white38 : Colors.black,
                            ),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 100),
                              width: 400,
                              height: 64,
                              transform: Matrix4.translationValues(_isSaving ? 0 : -4, _isSaving ? 0 : -4, 0),
                              decoration: BoxDecoration(
                                color: const Color(0xFFB7E5CD), // primary-container
                                border: Border.all(color: Colors.black, width: 2),
                              ),
                              child: Center(
                                child: _isSaving
                                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 3))
                                    : Text(
                                        'Simpan & Terbitkan Kuis',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w800,
                                          color: const Color(0xFF001E2B),
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.cloudLightning, size: 16, color: isDark ? Colors.white70 : const Color(0xFF414944)),
                          const SizedBox(width: 8),
                          Text(
                            'DRAF TERAKHIR DISIMPAN PADA ${DateFormat('HH:mm').format(DateTime.now())}',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white70 : const Color(0xFF414944),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNeoField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required bool isDark,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
            color: isDark ? Colors.white70 : const Color(0xFF414944), // on-surface-variant
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          validator: (v) => (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
          style: GoogleFonts.inter(
            fontSize: 16,
            color: isDark ? Colors.white : Colors.black,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(color: isDark ? Colors.white38 : const Color(0xFFC1C8C2)),
            filled: true,
            fillColor: isDark ? const Color(0xFF001E2B) : const Color(0xFFF4FAFF),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: isDark ? Colors.white38 : Colors.black, width: 2)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: isDark ? Colors.white38 : Colors.black, width: 2)),
            focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: Color(0xFF3D6754), width: 2)),
          ),
        ),
      ],
    );
  }

  Widget _buildNeoSwitch({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required bool isDark,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: isDark ? Colors.white70 : const Color(0xFF414944),
                ),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: () => onChanged(!value),
          child: Container(
            width: 48,
            height: 24,
            decoration: BoxDecoration(
              color: value ? const Color(0xFF001E2B) : (isDark ? const Color(0xFF001E2B) : Colors.white),
              border: Border.all(color: isDark ? Colors.white38 : Colors.black, width: 1.5),
            ),
            child: Stack(
              children: [
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  left: value ? 24 : 2,
                  top: 2,
                  child: Container(
                    width: 17,
                    height: 17,
                    decoration: BoxDecoration(
                      color: value ? const Color(0xFFB7E5CD) : (isDark ? Colors.white54 : Colors.black),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _NeoCard extends StatelessWidget {
  final Widget child;
  final bool isDark;
  final Color? backgroundColor;

  const _NeoCard({required this.child, required this.isDark, this.backgroundColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: backgroundColor ?? (isDark ? const Color(0xFF001E2B) : Colors.white),
        border: Border.all(color: isDark ? Colors.white38 : const Color(0xFF001E2B), width: 2),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.white38 : const Color(0xFF001E2B),
            offset: const Offset(4, 4),
            blurRadius: 0,
          ),
        ],
      ),
      child: child,
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
  final String token;
  final VoidCallback? onRemove;
  final VoidCallback onUpdate;

  const _QuestionCard({
    required this.index,
    required this.form,
    required this.isDark,
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
    final isDark = widget.isDark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: _NeoCard(
        isDark: isDark,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Question Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(LucideIcons.gripVertical, size: 20, color: isDark ? Colors.white54 : const Color(0xFF717974)),
                    const SizedBox(width: 12),
                    Text(
                      'Pertanyaan #${widget.index + 1}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF001E2B),
                      ),
                    ),
                  ],
                ),
                if (widget.onRemove != null)
                  IconButton(
                    icon: const Icon(LucideIcons.trash2, color: Color(0xFFBA1A1A)),
                    onPressed: widget.onRemove,
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFFBA1A1A).withValues(alpha: 0.1),
                    ),
                  ),
              ],
            ),
            const Divider(color: Colors.black12, height: 32),
            
            // Type & Score
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('TIPE SOAL', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.0, color: isDark ? Colors.white70 : const Color(0xFF414944))),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF001E2B) : Colors.white,
                          border: Border.all(color: isDark ? Colors.white38 : Colors.black, width: 2),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: form.questionType,
                            isExpanded: true,
                            dropdownColor: isDark ? const Color(0xFF001E2B) : Colors.white,
                            style: GoogleFonts.inter(fontSize: 16, color: isDark ? Colors.white : Colors.black),
                            items: const [
                              DropdownMenuItem(value: 'multipleChoice', child: Text('Pilihan Ganda')),
                              DropdownMenuItem(value: 'multipleAnswer', child: Text('Pilihan Ganda Kompleks')),
                              DropdownMenuItem(value: 'essay', child: Text('Essay')),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  form.questionType = val;
                                  if (val == 'multipleChoice') {
                                    form.correctAnswers = form.correctAnswers.isNotEmpty ? [form.correctAnswers.first] : [0];
                                  }
                                });
                                widget.onUpdate();
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  flex: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('SKOR', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.0, color: isDark ? Colors.white70 : const Color(0xFF414944))),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: form.pointsCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(fontSize: 16, color: isDark ? Colors.white : Colors.black),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: isDark ? const Color(0xFF001E2B) : Colors.white,
                          contentPadding: const EdgeInsets.symmetric(vertical: 14),
                          border: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: isDark ? Colors.white38 : Colors.black, width: 2)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: isDark ? Colors.white38 : Colors.black, width: 2)),
                          focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: Color(0xFF3D6754), width: 2)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Content
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('KONTEN PERTANYAAN', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.0, color: isDark ? Colors.white70 : const Color(0xFF414944))),
                GestureDetector(
                  onTap: _isUploading ? null : _pickAndUploadImage,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF001E2B) : Colors.white,
                      border: Border.all(color: isDark ? Colors.white38 : Colors.black, width: 1.5),
                    ),
                    child: Row(
                      children: [
                        if (_isUploading)
                          const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF001E2B)))
                        else
                          Icon(LucideIcons.image, size: 14, color: isDark ? Colors.white : const Color(0xFF001E2B)),
                        const SizedBox(width: 6),
                        Text('INSERT GAMBAR', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF001E2B))),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: form.questionCtrl,
              maxLines: 3,
              style: GoogleFonts.inter(fontSize: 16, color: isDark ? Colors.white : Colors.black),
              decoration: InputDecoration(
                hintText: 'Ketik pertanyaan di sini...',
                hintStyle: GoogleFonts.inter(color: isDark ? Colors.white38 : const Color(0xFFC1C8C2)),
                filled: true,
                fillColor: isDark ? const Color(0xFF001E2B) : Colors.white,
                contentPadding: const EdgeInsets.all(16),
                border: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: isDark ? Colors.white38 : Colors.black, width: 2)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: isDark ? Colors.white38 : Colors.black, width: 2)),
                focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: Color(0xFF3D6754), width: 2)),
              ),
            ),
            if (form.imageUrl != null) ...[
              const SizedBox(height: 12),
              Stack(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF073446) : const Color(0xFFE8F6FF),
                      border: Border.all(color: isDark ? Colors.white38 : Colors.black, width: 1.5),
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 250),
                      child: Image.network(form.imageUrl!, fit: BoxFit.contain),
                    ),
                  ),
                  Positioned(
                    top: 16,
                    right: 16,
                    child: IconButton(
                      onPressed: _removeImage,
                      icon: const Icon(LucideIcons.trash2, color: Colors.white),
                      style: IconButton.styleFrom(backgroundColor: const Color(0xFFBA1A1A)),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 24),

            // Options
            if (form.questionType != 'essay') ...[
              Text('OPSI JAWABAN', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.0, color: isDark ? Colors.white70 : const Color(0xFF414944))),
              const SizedBox(height: 12),
              ...List.generate(form.optionCtrls.length, (oi) {
                final isCorrect = form.correctAnswers.contains(oi);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            if (form.questionType == 'multipleChoice') {
                              form.correctAnswers = [oi];
                            } else {
                              if (isCorrect) {
                                form.correctAnswers.remove(oi);
                              } else {
                                form.correctAnswers.add(oi);
                              }
                            }
                          });
                          widget.onUpdate();
                        },
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: form.questionType == 'multipleChoice' ? BoxShape.circle : BoxShape.rectangle,
                            border: Border.all(color: isCorrect ? const Color(0xFF3D6754) : (isDark ? Colors.white38 : const Color(0xFF717974)), width: 2),
                          ),
                          child: isCorrect ? Center(
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: const Color(0xFF3D6754),
                                shape: form.questionType == 'multipleChoice' ? BoxShape.circle : BoxShape.rectangle,
                              ),
                            ),
                          ) : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: form.optionCtrls[oi],
                          style: GoogleFonts.inter(fontSize: 16, color: isDark ? Colors.white : Colors.black),
                          decoration: InputDecoration(
                            hintText: 'Opsi ${oi + 1}',
                            hintStyle: GoogleFonts.inter(color: isDark ? Colors.white38 : const Color(0xFFC1C8C2)),
                            filled: true,
                            fillColor: isDark ? const Color(0xFF001E2B) : Colors.white,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: isCorrect ? const Color(0xFF3D6754) : (isDark ? Colors.white38 : Colors.black), width: isCorrect ? 2 : 1.5)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: isCorrect ? const Color(0xFF3D6754) : (isDark ? Colors.white38 : Colors.black), width: isCorrect ? 2 : 1.5)),
                            focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: Color(0xFF3D6754), width: 2)),
                          ),
                        ),
                      ),
                      if (form.optionCtrls.length > 2) ...[
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(LucideIcons.x, color: Color(0xFF717974)),
                          onPressed: () => _removeOption(oi),
                        ),
                      ],
                    ],
                  ),
                );
              }),
              if (form.optionCtrls.length < 6)
                GestureDetector(
                  onTap: _addOption,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(LucideIcons.plusCircle, size: 16, color: Color(0xFF3D6754)),
                        const SizedBox(width: 8),
                        Text('Tambah Opsi Baru', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF3D6754))),
                      ],
                    ),
                  ),
                ),
            ] else ...[
              Text('AREA JAWABAN SISWA', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.0, color: isDark ? Colors.white70 : const Color(0xFF414944))),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF073446) : const Color(0xFFE8F6FF), // surface-container-low
                  border: Border.all(color: isDark ? Colors.white38 : const Color(0xFFC1C8C2), width: 1.5, style: BorderStyle.none), // Dashed equivalent not natively supported easily without custom painter, using solid light
                ),
                child: Column(
                  children: [
                    Icon(LucideIcons.type, size: 40, color: isDark ? Colors.white38 : const Color(0xFFC1C8C2)),
                    const SizedBox(height: 8),
                    Text(
                      'Siswa akan diberikan area teks luas untuk mengetikkan jawaban Essay mereka di sini.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(fontSize: 14, fontStyle: FontStyle.italic, color: isDark ? Colors.white54 : const Color(0xFF717974)),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
