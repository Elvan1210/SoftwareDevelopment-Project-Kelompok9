import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import '../../../config/api_config.dart';
import '../../../config/theme.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart' as fp;
import '../../../services/notifikasi_service.dart';
import '../../../services/upload_service.dart';
import '../../../widgets/app_shell.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';

const _kNavy   = Color(0xFF1A1F3C);
const _kTeal   = Color(0xFF2A7C76);
const _kCoral  = Color(0xFFFF6B6B);
const _kAmber  = Color(0xFFFFA41B);
const _kIndigo = Color(0xFF4F46E5);
const _kGreen  = Color(0xFF10B981);
const _kBorder = Color(0xFF1A1F3C);

BoxDecoration _comicCard({
  Color bg = Colors.white,
  Color? borderColor,
  Color shadowColor = const Color(0x55000000),
  double radius = 16,
}) =>
    BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: borderColor ?? _kBorder, width: 2.2),
      boxShadow: [
        BoxShadow(color: shadowColor, offset: const Offset(4, 4), blurRadius: 0),
      ],
    );

class SiswaTugasDetailScreen extends StatefulWidget {
  final Map<String, dynamic> tugas;
  final Map<String, dynamic> userData;
  final String token;

  const SiswaTugasDetailScreen({
    super.key,
    required this.tugas,
    required this.userData,
    required this.token,
  });

  @override
  State<SiswaTugasDetailScreen> createState() => _SiswaTugasDetailScreenState();
}

class _SiswaTugasDetailScreenState extends State<SiswaTugasDetailScreen> {
  bool _isLoading = true;
  bool _isUploading = false;
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
        if (dt.isBefore(DateTime.now())) _isPastDeadline = true;
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
        final List allPengumpulan = jsonDecode(responses[0].body) is List
            ? jsonDecode(responses[0].body)
            : [];
        final List allNilai = jsonDecode(responses[1].body) is List
            ? jsonDecode(responses[1].body)
            : [];

        final submission = allPengumpulan
            .where((p) =>
                p['tugas_id'] == widget.tugas['id'] &&
                p['siswa_id'] == widget.userData['id'])
            .toList();
        final nilaiMilikSiswa = allNilai
            .where((n) =>
                n['tugas_id'] == widget.tugas['id'] &&
                n['siswa_id'] == widget.userData['id'])
            .toList();

        setState(() {
          if (submission.isNotEmpty) {
            _isTurnedIn = true;
            _pengumpulanId = submission[0]['id'];
            final rawFiles = submission[0]['files'];
            if (rawFiles is List) {
              _attachments = rawFiles.map((e) => e.toString()).toList();
            } else {
              _attachments = [];
            }
          }
          if (nilaiMilikSiswa.isNotEmpty) {
            _nilaiSiswa = nilaiMilikSiswa[0]['nilai'];
            _feedbackSiswa = nilaiMilikSiswa[0]['feedback'];
          }
        });
      }
    } catch (e) {
      debugPrint('Error Check Status: $e');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _pickAndUploadFile() async {
    fp.FilePickerResult? result = await fp.FilePicker.platform.pickFiles(
      type: fp.FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf', 'doc', 'docx'],
      allowMultiple: true,
      withData: true, 
    );

    if (result == null || result.files.isEmpty) return;

    setState(() => _isUploading = true);

    for (final file in result.files) {
      final bytes = file.bytes;
      if (bytes == null || bytes.isEmpty) {
        debugPrint('File bytes kosong untuk: ${file.name}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal membaca file: ${file.name}'),
              backgroundColor: AppTheme.error,
            ),
          );
        }
        continue;
      }

      debugPrint('Uploading: ${file.name}, size: ${bytes.length} bytes');

      final url = await UploadService.uploadFile(
        fileBytes: bytes,
        fileName: file.name,
        token: widget.token,
      );

      if (url != null && url.isNotEmpty) {
        debugPrint('Upload sukses: $url');
        setState(() => _attachments.add(url));
      } else {
        debugPrint('Upload gagal untuk: ${file.name}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal upload: ${file.name}'),
              backgroundColor: AppTheme.error,
            ),
          );
        }
      }
    }

    setState(() => _isUploading = false);
  }

  void _showAddLinkDialog() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: _kBorder, width: 2.2),
        ),
        title: Text('Tambah Link', style: GoogleFonts.inter(fontWeight: FontWeight.w900, color: _kNavy)),
        content: TextField(
          controller: ctrl,
          decoration: InputDecoration(
            labelText: 'https://...',
            labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.grey.shade500),
            border: const OutlineInputBorder(
              borderSide: BorderSide(color: _kBorder, width: 1.5),
            ),
            focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: _kIndigo, width: 2.2),
            ),
            prefixIcon: const Icon(LucideIcons.link, color: _kIndigo),
          ),
          keyboardType: TextInputType.url,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Batal', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: Colors.grey.shade600)),
          ),
          GestureDetector(
            onTap: () {
              final link = ctrl.text.trim();
              if (link.isNotEmpty && (link.startsWith('http://') || link.startsWith('https://'))) {
                setState(() => _attachments.add(link));
                Navigator.pop(ctx);
              } else {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Masukkan link yang valid (https://...)'), backgroundColor: _kAmber),
                );
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _kAmber,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _kBorder, width: 1.8),
                boxShadow: [BoxShadow(color: _kAmber.withAlpha(120), offset: const Offset(2, 2))],
              ),
              child: Text('Tambah', style: GoogleFonts.inter(fontWeight: FontWeight.w900, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  void _removeFile(int index) => setState(() => _attachments.removeAt(index));

  IconData _getFileIcon(String url) {
    final lower = url.toLowerCase();
    if (lower.contains('.pdf') || lower.contains('/raw/')) return LucideIcons.fileText;
    if (lower.contains('.jpg') || lower.contains('.jpeg') || lower.contains('.png')) return LucideIcons.image;
    if (lower.contains('.doc')) return LucideIcons.fileText;
    return LucideIcons.link;
  }

  Color _getFileColor(String url) {
    final lower = url.toLowerCase();
    if (lower.contains('.pdf') || lower.contains('/raw/')) return _kCoral;
    if (lower.contains('.jpg') || lower.contains('.jpeg') || lower.contains('.png')) return _kGreen;
    if (lower.contains('.doc')) return _kTeal;
    return _kIndigo;
  }

  String _getFileLabel(String url) {
    final lower = url.toLowerCase();
    if (lower.contains('.pdf') || lower.contains('/raw/')) return 'File PDF';
    if (lower.contains('.jpg') || lower.contains('.jpeg') || lower.contains('.png')) return 'Foto/Gambar';
    if (lower.contains('.doc')) return 'File Word';
    try {
      return Uri.parse(url).host;
    } catch (_) {
      return 'Link';
    }
  }

  Future<void> _openFile(String url) async {
    String finalUrl = url;
    if (url.toLowerCase().contains('.pdf') || url.contains('/raw/')) {
      finalUrl = 'https://docs.google.com/viewer?url=${Uri.encodeComponent(url)}';
    }
    final uri = Uri.parse(finalUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.platformDefault);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak bisa membuka file'), backgroundColor: AppTheme.error),
        );
      }
    }
  }

  Future<void> _turnIn() async {
    if (_attachments.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tambahkan file atau link terlebih dahulu!'),
          backgroundColor: _kAmber,
        ),
      );
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
        'status': 'Diserahkan',
      };

      debugPrint('Turn in body: ${jsonEncode(body)}');

      final response = await http.post(
        Uri.parse('$baseUrl/api/pengumpulan'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
        body: jsonEncode(body),
      );

      debugPrint('Turn in response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 201) {
        final resData = jsonDecode(response.body);
        setState(() {
          _isTurnedIn = true;
          _pengumpulanId = resData['id'];
        });
        NotifikasiService.kirimNotifikasi(
          judul: 'Tugas Dikumpulkan!',
          pesan: '${widget.userData['nama']} telah mengumpulkan tugas "${widget.tugas['judul']}"',
          token: widget.token,
          targetUserId: widget.tugas['guru_id'],
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tugas berhasil dikumpulkan!'), backgroundColor: _kGreen),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal mengirim: ${response.statusCode}'), backgroundColor: _kCoral),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: _kCoral),
        );
      }
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
          _attachments = [];
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pengumpulan dibatalkan'), backgroundColor: _kAmber),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error jaringan: $e'), backgroundColor: _kCoral),
        );
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text('Detail Penugasan', style: GoogleFonts.inter(fontWeight: FontWeight.w900, color: _kNavy)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _kNavy),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            if (!_isLoading)
              Padding(
                padding: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
                child: _isTurnedIn
                    ? GestureDetector(
                        onTap: _undoTurnIn,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _kCoral, width: 2),
                            boxShadow: [BoxShadow(color: _kCoral.withAlpha(80), offset: const Offset(2, 2))],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(LucideIcons.undo, size: 16, color: _kCoral),
                              const SizedBox(width: 6),
                              Text('Batalkan', style: GoogleFonts.inter(fontWeight: FontWeight.w900, color: _kCoral)),
                            ],
                          ),
                        ),
                      )
                    : _isPastDeadline
                        ? Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: _kCoral,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: _kBorder, width: 2),
                              boxShadow: const [BoxShadow(color: Color(0x55000000), offset: Offset(2, 2))],
                            ),
                            child: Text('TERLEWAT', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                          )
                        : GestureDetector(
                            onTap: _isUploading ? null : _turnIn,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: _kAmber,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: _kBorder, width: 2),
                                boxShadow: const [BoxShadow(color: Color(0x55000000), offset: Offset(2, 2))],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.send_rounded, size: 16, color: Colors.white),
                                  const SizedBox(width: 6),
                                  Text('TURN IN', style: GoogleFonts.inter(fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.5)),
                                ],
                              ),
                            ),
                          ),
              ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: _kIndigo))
            : SingleChildScrollView(
                padding: Breakpoints.screenPadding(MediaQuery.of(context).size.width),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Info Tugas
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: _comicCard(bg: _kIndigo.withAlpha(15), borderColor: _kIndigo, shadowColor: _kIndigo.withAlpha(60)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: _kIndigo,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: _kBorder, width: 1.8),
                                  boxShadow: [BoxShadow(color: _kIndigo.withAlpha(100), offset: const Offset(3, 3))],
                                ),
                                child: const Icon(LucideIcons.clipboardList, color: Colors.white, size: 24),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.tugas['judul'] ?? 'Task',
                                      style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w900, color: _kNavy, height: 1.1),
                                    ),
                                    const SizedBox(height: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: _isPastDeadline ? _kCoral.withAlpha(30) : _kTeal.withAlpha(30),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: _isPastDeadline ? _kCoral : _kTeal, width: 1.2),
                                      ),
                                      child: Text(
                                        'Jatuh tempo: $_formattedDeadline',
                                        style: GoogleFonts.inter(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 11,
                                          color: _isPastDeadline ? _kCoral : _kTeal,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 32, color: Colors.black12, thickness: 1.5),
                          _buildInfoRow(LucideIcons.userCircle, 'Pengajar', widget.tugas['guru_nama'] ?? 'Guru'),
                          const SizedBox(height: 12),
                          _buildInfoRow(LucideIcons.bookOpen, 'Mata Pelajaran', widget.tugas['mapel'] ?? '-'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    if ((widget.tugas['deskripsi'] ?? '').isNotEmpty) ...[
                      _comicSectionHeader('INSTRUKSI', LucideIcons.fileText, _kNavy),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: _comicCard(bg: Colors.white, borderColor: _kNavy, shadowColor: const Color(0x33000000)),
                        child: Text(widget.tugas['deskripsi'],
                            style: GoogleFonts.inter(fontSize: 15, height: 1.6, fontWeight: FontWeight.w500, color: _kNavy)),
                      ),
                      const SizedBox(height: 24),
                    ],

                    if (widget.tugas['link'] != null && widget.tugas['link'].toString().isNotEmpty) ...[
                      _comicSectionHeader('LAMPIRAN SOAL', LucideIcons.paperclip, _kTeal),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: () => _openFile(widget.tugas['link'].toString()),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: _comicCard(bg: _kTeal.withAlpha(20), borderColor: _kTeal, shadowColor: _kTeal.withAlpha(80)),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: _kTeal, width: 2),
                                ),
                                child: const Icon(LucideIcons.fileText, color: _kTeal, size: 24),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Buka Lampiran Soal',
                                        style: GoogleFonts.inter(fontWeight: FontWeight.w900, color: _kTeal, fontSize: 14)),
                                    Text('Ketuk untuk membuka',
                                        style: GoogleFonts.inter(fontSize: 12, color: _kTeal.withAlpha(180), fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                              const Icon(LucideIcons.externalLink, color: _kTeal, size: 20),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    Row(
                      children: [
                        Expanded(child: _comicSectionHeader('PEKERJAAN SAYA', LucideIcons.folder, _kIndigo)),
                        if (_nilaiSiswa != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _kGreen,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: _kBorder, width: 1.8),
                              boxShadow: const [BoxShadow(color: Color(0x55000000), offset: Offset(2, 2))],
                            ),
                            child: Text('NILAI: $_nilaiSiswa',
                              style: GoogleFonts.inter(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 12)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: _comicCard(
                        bg: (_isTurnedIn ? _kGreen : _kAmber).withAlpha(15),
                        borderColor: _isTurnedIn ? _kGreen : _kAmber,
                        shadowColor: (_isTurnedIn ? _kGreen : _kAmber).withAlpha(60),
                      ),
                      child: Column(
                        children: [
                          if (_isTurnedIn)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: _kGreen,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: _kBorder, width: 2),
                                boxShadow: [BoxShadow(color: _kGreen.withAlpha(80), offset: const Offset(2, 2))],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(LucideIcons.checkCircle, color: Colors.white, size: 18),
                                  const SizedBox(width: 8),
                                  Text('Sudah Dikumpulkan',
                                      style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13)),
                                ],
                              ),
                            ),
                          
                          if (_attachments.isEmpty && !_isUploading)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 24),
                              child: Center(
                                child: Text('Belum ada file atau link ditambahkan',
                                    style: GoogleFonts.inter(color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
                              ),
                            ),
                            
                          ..._attachments.asMap().entries.map((entry) {
                            final i = entry.key;
                            final url = entry.value;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: _kNavy, width: 1.8),
                                boxShadow: const [BoxShadow(color: Color(0x33000000), offset: Offset(3, 3))],
                              ),
                              child: ListTile(
                                leading: Icon(_getFileIcon(url), color: _getFileColor(url)),
                                title: Text(_getFileLabel(url), style: GoogleFonts.inter(fontWeight: FontWeight.w800, color: _kNavy, fontSize: 13)),
                                subtitle: Text(url, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade500)),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(LucideIcons.externalLink, size: 18, color: _kNavy),
                                      onPressed: () => _openFile(url),
                                    ),
                                    if (!_isTurnedIn)
                                      IconButton(
                                        icon: const Icon(LucideIcons.x, color: _kCoral, size: 18),
                                        onPressed: () => _removeFile(i),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          }),

                          if (_isUploading)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5, color: _kIndigo)),
                                  const SizedBox(width: 12),
                                  Text('Mengunggah file...', style: GoogleFonts.inter(color: _kNavy, fontWeight: FontWeight.w700)),
                                ],
                              ),
                            ),
                          
                          if (!_isTurnedIn) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: _kIndigo, width: 2),
                              ),
                              child: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: _kIndigo.withAlpha(20),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(LucideIcons.uploadCloud, color: _kIndigo, size: 28),
                                  ),
                                  const SizedBox(height: 12),
                                  Text('Unggah Tugas Anda', style: GoogleFonts.inter(fontWeight: FontWeight.w900, color: _kNavy, fontSize: 15)),
                                  const SizedBox(height: 4),
                                  Text('Mendukung PDF, Word, JPG, atau Link website',
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.inter(fontWeight: FontWeight.w500, color: Colors.grey.shade500, fontSize: 11)),
                                  const SizedBox(height: 18),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: _isUploading ? null : _pickAndUploadFile,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(vertical: 12),
                                            decoration: BoxDecoration(
                                              color: _kIndigo,
                                              borderRadius: BorderRadius.circular(10),
                                              border: Border.all(color: _kBorder, width: 1.8),
                                              boxShadow: const [BoxShadow(color: Color(0x55000000), offset: Offset(2, 2))],
                                            ),
                                            child: Center(
                                              child: Text('PILIH FILE', style: GoogleFonts.inter(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 12)),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: _showAddLinkDialog,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(vertical: 12),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius: BorderRadius.circular(10),
                                              border: Border.all(color: _kIndigo, width: 2),
                                              boxShadow: [BoxShadow(color: _kIndigo.withAlpha(60), offset: const Offset(2, 2))],
                                            ),
                                            child: Center(
                                              child: Text('TAMBAH LINK', style: GoogleFonts.inter(fontWeight: FontWeight.w900, color: _kIndigo, fontSize: 12)),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    if (_feedbackSiswa != null && _feedbackSiswa!.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      _comicSectionHeader('FEEDBACK PENGAJAR', LucideIcons.messageSquare, _kTeal),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: _comicCard(bg: const Color(0xFFE6F9F3), borderColor: _kTeal, shadowColor: _kTeal.withAlpha(80)),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(LucideIcons.messageSquare, color: _kTeal, size: 20),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(_feedbackSiswa!,
                                style: GoogleFonts.inter(fontSize: 14, fontStyle: FontStyle.italic, fontWeight: FontWeight.w600, color: _kNavy, height: 1.5)),
                            ),
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
        Icon(icon, size: 16, color: Colors.grey.shade500),
        const SizedBox(width: 10),
        Text('$label:', style: GoogleFonts.inter(color: Colors.grey.shade600, fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(width: 6),
        Flexible(
          child: Text(value, style: GoogleFonts.inter(fontWeight: FontWeight.w900, color: _kNavy, fontSize: 13),
              maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }

  Widget _comicSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _kBorder, width: 1.5),
            boxShadow: [BoxShadow(color: color.withAlpha(100), offset: const Offset(2, 2))],
          ),
          child: Icon(icon, size: 14, color: Colors.white),
        ),
        const SizedBox(width: 10),
        Text(title, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w900, color: color, letterSpacing: 1.2)),
      ],
    );
  }
}
