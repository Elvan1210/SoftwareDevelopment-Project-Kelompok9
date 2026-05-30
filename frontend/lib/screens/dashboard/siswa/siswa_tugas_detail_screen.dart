import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import '../../../config/api_config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart' as fp;
import '../../../services/notifikasi_service.dart';
import '../../../services/upload_service.dart';
import '../../../widgets/app_shell.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';

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
const Color _error = Color(0xFFEF4444);

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
      if (bytes == null || bytes.isEmpty) continue;

      final url = await UploadService.uploadFile(
        fileBytes: bytes,
        fileName: file.name,
        token: widget.token,
      );

      if (url != null && url.isNotEmpty) {
        setState(() => _attachments.add(url));
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal upload: ${file.name}')),
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
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: _onSurface, width: 2),
        ),
        title: Text('Tambah Link', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, color: _onBackground)),
        content: TextField(
          controller: ctrl,
          decoration: InputDecoration(
            labelText: 'https://...',
            labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, color: _onSurfaceVariant),
            border: const OutlineInputBorder(borderSide: BorderSide(color: _onSurface, width: 1.5)),
            focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: _primary, width: 2)),
            prefixIcon: const Icon(LucideIcons.link, color: _onSurface),
          ),
          keyboardType: TextInputType.url,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Batal', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: _onSurfaceVariant)),
          ),
          _NeoButton(
            label: 'Tambah',
            color: _primary,
            textColor: Colors.white,
            onTap: () {
              final link = ctrl.text.trim();
              if (link.isNotEmpty && (link.startsWith('http://') || link.startsWith('https://'))) {
                setState(() => _attachments.add(link));
                Navigator.pop(ctx);
              } else {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Masukkan link yang valid (https://...)')),
                );
              }
            },
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
          const SnackBar(content: Text('Tidak bisa membuka file')),
        );
      }
    }
  }

  Future<void> _turnIn() async {
    if (_attachments.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tambahkan file atau link terlebih dahulu!')),
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

      final response = await http.post(
        Uri.parse('$baseUrl/api/pengumpulan'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
        body: jsonEncode(body),
      );

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
            const SnackBar(content: Text('Tugas berhasil dikumpulkan!')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
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
            const SnackBar(content: Text('Pengumpulan dibatalkan')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error jaringan: $e')),
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
          title: Text('Detail Penugasan', style: GoogleFonts.inter(fontWeight: FontWeight.w900, color: _onBackground)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: _onBackground),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            if (!_isLoading)
              Padding(
                padding: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
                child: _isTurnedIn
                    ? _NeoButton(
                        label: 'Batalkan',
                        color: _surface,
                        textColor: _error,
                        icon: LucideIcons.undo,
                        onTap: _undoTurnIn,
                      )
                    : _isPastDeadline
                        ? _NeoButton(
                            label: 'TERLEWAT',
                            color: _error,
                            textColor: Colors.white,
                            onTap: () {},
                          )
                        : _NeoButton(
                            label: 'TURN IN',
                            color: const Color(0xFFF59E0B),
                            textColor: Colors.white,
                            icon: Icons.send_rounded,
                            onTap: _isUploading ? null : _turnIn,
                          ),
              ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: _primary))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Info Tugas Card
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: _primaryContainer,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: _onSurface, width: 2),
                            boxShadow: const [BoxShadow(color: _onSurface, offset: Offset(4, 4))],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: _primary,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: _onSurface, width: 2),
                                    ),
                                    child: const Icon(LucideIcons.clipboardList, color: Colors.white, size: 24),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          widget.tugas['judul'] ?? 'Tugas',
                                          style: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.w900, color: _onBackground, height: 1.2),
                                        ),
                                        const SizedBox(height: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: _isPastDeadline ? _error.withAlpha(50) : _surface,
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: _onSurface, width: 1.5),
                                          ),
                                          child: Text(
                                            'Jatuh tempo: $_formattedDeadline',
                                            style: GoogleFonts.inter(
                                              fontWeight: FontWeight.w800,
                                              fontSize: 12,
                                              color: _isPastDeadline ? _error : _onBackground,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              Divider(height: 1, color: _onSurface.withAlpha(50), thickness: 2),
                              const SizedBox(height: 24),
                              _buildInfoRowNeo(LucideIcons.userCircle, 'Pengajar', widget.tugas['guru_nama'] ?? 'Guru'),
                              const SizedBox(height: 12),
                              _buildInfoRowNeo(LucideIcons.bookOpen, 'Mata Pelajaran', widget.tugas['mapel'] ?? '-'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),

                        if ((widget.tugas['deskripsi'] ?? '').isNotEmpty) ...[
                          Text('INSTRUKSI', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 16, color: _onBackground)),
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: _onSurface, width: 2),
                              boxShadow: const [BoxShadow(color: _onSurface, offset: Offset(4, 4))],
                            ),
                            child: Text(widget.tugas['deskripsi'],
                                style: GoogleFonts.inter(fontSize: 15, height: 1.6, fontWeight: FontWeight.w500, color: _onSurfaceVariant)),
                          ),
                          const SizedBox(height: 32),
                        ],

                        if (widget.tugas['link'] != null && widget.tugas['link'].toString().isNotEmpty) ...[
                          Text('LAMPIRAN SOAL', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 16, color: _onBackground)),
                          const SizedBox(height: 12),
                          GestureDetector(
                            onTap: () => _openFile(widget.tugas['link'].toString()),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: _surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: _onSurface, width: 2),
                                boxShadow: const [BoxShadow(color: _onSurface, offset: Offset(4, 4))],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: _onSurface, width: 2),
                                    ),
                                    child: const Icon(LucideIcons.fileText, color: _onSurface, size: 24),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Buka Lampiran Soal',
                                            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w900, color: _onBackground, fontSize: 16)),
                                        Text('Ketuk untuk membuka',
                                            style: GoogleFonts.inter(fontSize: 13, color: _onSurfaceVariant, fontWeight: FontWeight.w600)),
                                      ],
                                    ),
                                  ),
                                  const Icon(LucideIcons.externalLink, color: _onSurface, size: 20),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                        ],

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('PEKERJAAN SAYA', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 16, color: _onBackground)),
                            if (_nilaiSiswa != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981),
                                  borderRadius: BorderRadius.circular(100),
                                  border: Border.all(color: _onSurface, width: 2),
                                  boxShadow: const [BoxShadow(color: _onSurface, offset: Offset(2, 2))],
                                ),
                                child: Text('NILAI: $_nilaiSiswa',
                                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 14)),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: _isTurnedIn ? _secondaryContainer : _surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: _onSurface, width: 2),
                            boxShadow: const [BoxShadow(color: _onSurface, offset: Offset(4, 4))],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (_isTurnedIn)
                                Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  margin: const EdgeInsets.only(bottom: 20),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: _onSurface, width: 2),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(LucideIcons.checkCircle, color: Colors.white, size: 20),
                                      const SizedBox(width: 8),
                                      Text('Sudah Dikumpulkan',
                                          style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
                                    ],
                                  ),
                                ),
                              
                              if (_attachments.isEmpty && !_isUploading)
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 24),
                                  child: Center(
                                    child: Text('Belum ada file atau link ditambahkan',
                                        style: GoogleFonts.inter(color: _onSurfaceVariant, fontWeight: FontWeight.w600)),
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
                                    border: Border.all(color: _onSurface, width: 2),
                                  ),
                                  child: ListTile(
                                    leading: Icon(_getFileIcon(url), color: _onSurface),
                                    title: Text(_getFileLabel(url), style: GoogleFonts.inter(fontWeight: FontWeight.w800, color: _onBackground, fontSize: 14)),
                                    subtitle: Text(url, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontSize: 12, color: _onSurfaceVariant)),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(LucideIcons.externalLink, size: 20, color: _onSurface),
                                          onPressed: () => _openFile(url),
                                        ),
                                        if (!_isTurnedIn)
                                          IconButton(
                                            icon: const Icon(LucideIcons.x, color: _error, size: 20),
                                            onPressed: () => _removeFile(i),
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              }),

                              if (_isUploading)
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 24),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const CircularProgressIndicator(color: _primary),
                                      const SizedBox(width: 16),
                                      Text('Mengunggah file...', style: GoogleFonts.inter(color: _onBackground, fontWeight: FontWeight.w700)),
                                    ],
                                  ),
                                ),
                              
                              if (!_isTurnedIn) ...[
                                const SizedBox(height: 24),
                                Container(
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: _onSurface, width: 2),
                                  ),
                                  child: Column(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: _tertiaryContainer,
                                          shape: BoxShape.circle,
                                          border: Border.all(color: _onSurface, width: 2),
                                        ),
                                        child: const Icon(LucideIcons.uploadCloud, color: _onSurface, size: 32),
                                      ),
                                      const SizedBox(height: 16),
                                      Text('Unggah Tugas Anda', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w900, color: _onBackground, fontSize: 20)),
                                      const SizedBox(height: 8),
                                      Text('Mendukung PDF, Word, JPG, atau Link website',
                                          textAlign: TextAlign.center,
                                          style: GoogleFonts.inter(fontWeight: FontWeight.w500, color: _onSurfaceVariant, fontSize: 13)),
                                      const SizedBox(height: 24),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _NeoButton(
                                              label: 'PILIH FILE',
                                              color: _primary,
                                              textColor: Colors.white,
                                              onTap: _isUploading ? null : _pickAndUploadFile,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: _NeoButton(
                                              label: 'TAMBAH LINK',
                                              color: _surface,
                                              textColor: _onSurface,
                                              onTap: _showAddLinkDialog,
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
                          const SizedBox(height: 32),
                          Text('FEEDBACK PENGAJAR', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 16, color: _onBackground)),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: _tertiaryContainer,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: _onSurface, width: 2),
                              boxShadow: const [BoxShadow(color: _onSurface, offset: Offset(4, 4))],
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(LucideIcons.messageSquare, color: _onSurface, size: 24),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(_feedbackSiswa!,
                                    style: GoogleFonts.inter(fontSize: 16, fontStyle: FontStyle.italic, fontWeight: FontWeight.w600, color: _onBackground, height: 1.5)),
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
              ),
      ),
    );
  }

  Widget _buildInfoRowNeo(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: _onSurfaceVariant),
        const SizedBox(width: 12),
        Text('$label:', style: GoogleFonts.inter(color: _onSurfaceVariant, fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(value, style: GoogleFonts.inter(fontWeight: FontWeight.w900, color: _onBackground, fontSize: 14),
              maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}

class _NeoButton extends StatefulWidget {
  final String label;
  final Color color;
  final Color textColor;
  final IconData? icon;
  final VoidCallback? onTap;

  const _NeoButton({
    required this.label,
    required this.color,
    required this.textColor,
    this.icon,
    this.onTap,
  });

  @override
  State<_NeoButton> createState() => _NeoButtonState();
}

class _NeoButtonState extends State<_NeoButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) { if (widget.onTap != null) setState(() => _isPressed = true); },
      onTapUp: (_) { if (widget.onTap != null) setState(() => _isPressed = false); },
      onTapCancel: () { if (widget.onTap != null) setState(() => _isPressed = false); },
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        transform: Matrix4.translationValues(
          _isPressed ? 2 : 0,
          _isPressed ? 2 : 0,
          0,
        ),
        decoration: BoxDecoration(
          color: widget.onTap == null ? Colors.grey.shade300 : widget.color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _onSurface, width: 2),
          boxShadow: _isPressed || widget.onTap == null ? [] : const [BoxShadow(color: _onSurface, offset: Offset(2, 2))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (widget.icon != null) ...[
              Icon(widget.icon, color: widget.textColor, size: 18),
              const SizedBox(width: 8),
            ],
            Text(
              widget.label,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w900,
                color: widget.textColor,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
