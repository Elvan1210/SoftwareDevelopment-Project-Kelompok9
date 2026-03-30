import 'package:flutter/material.dart';
import '../../../config/api_config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import '../../../services/notifikasi_service.dart';
import '../../../widgets/app_shell.dart';
import '../../../config/theme.dart';

class SiswaTugasDetailScreen extends StatefulWidget {
  final Map<String, dynamic> tugas;
  final Map<String, dynamic> userData;
  final String token;

  const SiswaTugasDetailScreen({super.key, required this.tugas, required this.userData, required this.token});

  @override
  State<SiswaTugasDetailScreen> createState() => _SiswaTugasDetailScreenState();
}

class _SiswaTugasDetailScreenState extends State<SiswaTugasDetailScreen> {
  bool _isLoading = true;
  bool _isTurnedIn = false;
  String? _pengumpulanId;
  int? _nilaiSiswa;
  String? _feedbackSiswa;
  bool _isPastDeadline = false;
  String _formattedDeadline = '';
  List<String> _attachments = [];

  @override
  void initState() {
    super.initState();
    _checkSubmissionStatus();
    _formattedDeadline = widget.tugas['deadline'] ?? '-';
    if (widget.tugas['deadline'] != null) {
      final dt = DateTime.tryParse(widget.tugas['deadline']);
      if (dt != null) {
        _formattedDeadline = DateFormat('dd MMM yyyy, HH:mm').format(dt);
        if (dt.isBefore(DateTime.now())) {
          _isPastDeadline = true;
        }
      }
    }
  }

  Future<void> _checkSubmissionStatus() async {
    setState(() => _isLoading = true);
    try {
      final responses = await Future.wait([
        http.get(
          Uri.parse('$baseUrl/api/pengumpulan'),
          headers: {'Authorization': 'Bearer ${widget.token}'},
        ),
        http.get(
          Uri.parse('$baseUrl/api/nilai'),
          headers: {'Authorization': 'Bearer ${widget.token}'},
        ),
      ]);

      if (responses[0].statusCode == 200 && responses[1].statusCode == 200) {
        final decAllPengumpulan = jsonDecode(responses[0].body);
        List allPengumpulan = decAllPengumpulan is List ? decAllPengumpulan : [];
        final decAllNilai = jsonDecode(responses[1].body);
        List allNilai = decAllNilai is List ? decAllNilai : [];

        var submission = allPengumpulan.where((p) => p['tugas_id'] == widget.tugas['id'] && p['siswa_id'] == widget.userData['id']).toList();
        var nilaiMilikSiswa = allNilai.where((n) => n['tugas_id'] == widget.tugas['id'] && n['siswa_id'] == widget.userData['id']).toList();

        setState(() {
          if (submission.isNotEmpty) {
            _isTurnedIn = true;
            _pengumpulanId = submission[0]['id'];
            _attachments = List<String>.from(submission[0]['files'] ?? []);
          }
          if (nilaiMilikSiswa.isNotEmpty) {
            _nilaiSiswa = nilaiMilikSiswa[0]['nilai'];
            _feedbackSiswa = nilaiMilikSiswa[0]['feedback'];
          }
        });
      }
    } catch (e) {
      debugPrint("Error Check Status: $e");
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _pickFiles() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(allowMultiple: true);
    if (result != null) {
      setState(() {
        for (var file in result.files) {
          if (!_attachments.contains(file.name)) {
            _attachments.add(file.name);
          }
        }
      });
    }
  }

  void _removeFile(int index) {
    setState(() {
      _attachments.removeAt(index);
    });
  }

  Future<void> _turnIn() async {
    if (_attachments.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pilih file terlebih dahulu sebelum Turn In!'), backgroundColor: Colors.orange));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final body = {
        'tugas_id': widget.tugas['id'],
        'siswa_id': widget.userData['id'],
        'siswa_nama': widget.userData['nama'],
        'files': _attachments,
        'waktu_pengumpulan': DateTime.now().toIso8601String(),
        'status': 'Diserahkan'
      };
      final response = await http.post(
        Uri.parse('$baseUrl/api/pengumpulan'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer ${widget.token}'},
        body: jsonEncode(body)
      );

      if (response.statusCode == 201) {
        final resData = jsonDecode(response.body);
        setState(() {
          _isTurnedIn = true;
          _pengumpulanId = resData['id'];
        });
        
        // Kirim notifikasi ke Guru
        NotifikasiService.kirimNotifikasi(
          judul: 'Tugas Dikumpulkan!',
          pesan: '${widget.userData['nama']} telah mengumpulkan tugas "${widget.tugas['judul']}"',
          token: widget.token,
          targetUserId: widget.tugas['guru_id'],
        );

        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tugas berhasil dikumpulkan!'), backgroundColor: Colors.green));
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal mengirim: ${response.statusCode} - ${response.body}'), backgroundColor: Colors.red));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error Server/Koneksi: $e'), backgroundColor: Colors.red));
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _undoTurnIn() async {
    if (_pengumpulanId == null) return;
    setState(() => _isLoading = true);
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/api/pengumpulan/$_pengumpulanId'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      if (response.statusCode == 200) {
        setState(() {
          _isTurnedIn = false;
          _pengumpulanId = null;
        });
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pengumpulan dibatalkan'), backgroundColor: Colors.orange));
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal membatalkan: ${response.body}'), backgroundColor: Colors.red));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error jaringan: $e'), backgroundColor: Colors.red));
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = AppTheme.getAdaptiveTeal(context);

    return AppShell(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Detail Penugasan', style: TextStyle(fontWeight: FontWeight.w900)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            if (!_isLoading) 
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: _isTurnedIn
                    ? OutlinedButton.icon(
                        onPressed: _undoTurnIn,
                        icon: const Icon(Icons.undo_rounded, size: 18),
                        label: const Text('Batalkan'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      )
                    : _isPastDeadline
                        ? Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(color: Colors.red.withAlpha(30), borderRadius: BorderRadius.circular(12)),
                            child: const Text('Terlewat', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                          )
                        : ElevatedButton.icon(
                            onPressed: _turnIn,
                            icon: const Icon(Icons.send_rounded, size: 18),
                            label: const Text('Turn In'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.accentOrange,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                          ),
              ),
          ],
        ),
        body: SingleChildScrollView(
          padding: Breakpoints.screenPadding(MediaQuery.of(context).size.width),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── Task Info Card ──────────────────────────────────────────
              PremiumCard(
                accentColor: primaryColor,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: primaryColor.withAlpha(30), borderRadius: BorderRadius.circular(16)),
                          child: Icon(Icons.assignment_rounded, color: primaryColor, size: 28),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(widget.tugas['judul'] ?? 'Task', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, height: 1.1)),
                              const SizedBox(height: 4),
                              Text('Jatuh tempo: $_formattedDeadline', style: TextStyle(fontWeight: FontWeight.w600, color: _isPastDeadline ? Colors.red : primaryColor)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 40),
                    _buildInfoRow(Icons.account_circle_outlined, 'Pengajar', widget.tugas['guru_nama'] ?? 'Guru'),
                    const SizedBox(height: 12),
                    _buildInfoRow(Icons.book_outlined, 'Mata Pelajaran', widget.tugas['mapel'] ?? '-'),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ─── Description Section ─────────────────────────────────────
              if ((widget.tugas['deskripsi'] ?? '').isNotEmpty) ...[
                const SectionHeader(title: 'Instruksi'),
                const SizedBox(height: 12),
                PremiumCard(
                  padding: const EdgeInsets.all(24),
                  child: Text(widget.tugas['deskripsi'], style: const TextStyle(fontSize: 16, height: 1.6)),
                ),
                const SizedBox(height: 24),
              ],

              // ─── Submission Area ─────────────────────────────────────────
              Row(
                children: [
                  const Expanded(child: SectionHeader(title: 'Pekerjaan Saya')),
                  if (_nilaiSiswa != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(color: Colors.green.withAlpha(30), borderRadius: BorderRadius.circular(12)),
                      child: Text('Nilai: $_nilaiSiswa', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w900)),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              
              PremiumCard(
                accentColor: _isTurnedIn ? Colors.green : AppTheme.accentOrange,
                padding: const EdgeInsets.all(8),
                child: Column(
                  children: [
                    if (_attachments.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(32.0),
                        child: EmptyState(icon: Icons.upload_file_rounded, message: 'Belum ada file yang diunggah'),
                      ),
                    
                    ...List.generate(_attachments.length, (index) {
                      return ListTile(
                        leading: const Icon(Icons.insert_drive_file_rounded, color: AppTheme.secondaryTeal),
                        title: Text(_attachments[index], style: const TextStyle(fontWeight: FontWeight.w600)),
                        trailing: !_isTurnedIn 
                          ? IconButton(icon: const Icon(Icons.close_rounded, color: Colors.red), onPressed: () => _removeFile(index))
                          : null,
                      );
                    }),

                    if (!_isTurnedIn)
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: InkWell(
                          onTap: _pickFiles,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: theme.primaryColor.withAlpha(15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_circle_outline_rounded, color: theme.primaryColor),
                                const SizedBox(width: 12),
                                Text('Unggah Materi', style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.w800)),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // ─── Feedback Area ───────────────────────────────────────────
              if (_feedbackSiswa != null && _feedbackSiswa!.isNotEmpty) ...[
                const SizedBox(height: 24),
                const SectionHeader(title: 'Feedback Pengajar'),
                const SizedBox(height: 12),
                PremiumCard(
                  accentColor: Colors.blue,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.chat_bubble_outline_rounded, color: Colors.blue),
                      const SizedBox(width: 16),
                      Expanded(child: Text(_feedbackSiswa!, style: const TextStyle(fontSize: 15, fontStyle: FontStyle.italic))),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey),
        const SizedBox(width: 12),
        Text('$label: ', style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    );
  }
}
