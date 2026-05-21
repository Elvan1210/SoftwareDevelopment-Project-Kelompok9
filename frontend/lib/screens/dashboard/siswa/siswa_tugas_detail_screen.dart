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
import '../../../widgets/neo_brutalism.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

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
            // ✅ FIX: Pastikan files dibaca sebagai List<String> dengan aman
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

  // ✅ FIX UTAMA: Upload file dengan penanganan Flutter Web yang benar
  Future<void> _pickAndUploadFile() async {
    fp.FilePickerResult? result = await fp.FilePicker.platform.pickFiles(
      type: fp.FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf', 'doc', 'docx'],
      allowMultiple: true,
      withData: true, // Wajib true untuk Flutter Web
    );

    if (result == null || result.files.isEmpty) return;

    setState(() => _isUploading = true);

    for (final file in result.files) {
      // ✅ FIX: Di Flutter Web, gunakan file.bytes langsung
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Tambah Link',
            style: TextStyle(fontWeight: FontWeight.w900)),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
            labelText: 'https://...',
            border: OutlineInputBorder(),
            prefixIcon: Icon(LucideIcons.link),
          ),
          keyboardType: TextInputType.url,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Batal',
                style: TextStyle(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withAlpha(160))),
          ),
          PremiumElevatedButton(
            color: AppTheme.warning,
            textColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            radius: 10,
            onPressed: () {
              final link = ctrl.text.trim();
              if (link.isNotEmpty &&
                  (link.startsWith('http://') || link.startsWith('https://'))) {
                setState(() => _attachments.add(link));
                Navigator.pop(ctx);
              } else {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(
                    content: Text('Masukkan link yang valid (https://...)'),
                    backgroundColor: AppTheme.warning,
                  ),
                );
              }
            },
            child: const Text('Tambah'),
          ),
        ],
      ),
    );
  }

  void _removeFile(int index) => setState(() => _attachments.removeAt(index));

  IconData _getFileIcon(String url) {
    final lower = url.toLowerCase();
    if (lower.contains('.pdf') || lower.contains('/raw/')) {
      return LucideIcons.fileText;
    }
    if (lower.contains('.jpg') ||
        lower.contains('.jpeg') ||
        lower.contains('.png')) {
      return LucideIcons.image;
    }
    if (lower.contains('.doc')) return LucideIcons.fileText;
    return LucideIcons.link;
  }

  Color _getFileColor(String url) {
    final lower = url.toLowerCase();
    if (lower.contains('.pdf') || lower.contains('/raw/')) {
      return AppTheme.error;
    }
    if (lower.contains('.jpg') ||
        lower.contains('.jpeg') ||
        lower.contains('.png')) {
      return AppTheme.success;
    }
    if (lower.contains('.doc')) return AppTheme.info;
    return AppTheme.primary;
  }

  String _getFileLabel(String url) {
    final lower = url.toLowerCase();
    if (lower.contains('.pdf') || lower.contains('/raw/')) return 'File PDF';
    if (lower.contains('.jpg') ||
        lower.contains('.jpeg') ||
        lower.contains('.png')) {
      return 'Foto/Gambar';
    }
    if (lower.contains('.doc')) return 'File Word';
    try {
      return Uri.parse(url).host;
    } catch (_) {
      return 'Link';
    }
  }

  // ✅ FIX: Buka file dengan benar di Flutter Web (tidak pakai externalApplication)
  Future<void> _openFile(String url) async {
    String finalUrl = url;
    // Wrap PDF dengan Google Docs Viewer
    if (url.toLowerCase().contains('.pdf') || url.contains('/raw/')) {
      finalUrl =
          'https://docs.google.com/viewer?url=${Uri.encodeComponent(url)}';
    }
    final uri = Uri.parse(finalUrl);
    if (await canLaunchUrl(uri)) {
      // Di Flutter Web, gunakan platformDefault agar buka tab baru
      await launchUrl(uri, mode: LaunchMode.platformDefault);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Tidak bisa membuka file'),
              backgroundColor: AppTheme.error),
        );
      }
    }
  }

  Future<void> _turnIn() async {
    if (_attachments.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tambahkan file atau link terlebih dahulu!'),
          backgroundColor: AppTheme.warning,
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
        'files': _attachments, // List URL Cloudinary yang valid
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
          pesan:
              '${widget.userData['nama']} telah mengumpulkan tugas "${widget.tugas['judul']}"',
          token: widget.token,
          targetUserId: widget.tugas['guru_id'],
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tugas berhasil dikumpulkan!'),
              backgroundColor: AppTheme.success,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal mengirim: ${response.statusCode}'),
              backgroundColor: AppTheme.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error),
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
            const SnackBar(
              content: Text('Pengumpulan dibatalkan'),
              backgroundColor: AppTheme.warning,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error jaringan: $e'),
              backgroundColor: AppTheme.error),
        );
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.secondary;

    return AppShell(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Detail Penugasan',
              style: TextStyle(fontWeight: FontWeight.w900)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            if (!_isLoading)
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: _isTurnedIn
                    ? GestureDetector(
                        onTap: _undoTurnIn,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).scaffoldBackgroundColor,
                            border: Border.all(color: AppTheme.error, width: 2),
                            boxShadow: const [BoxShadow(color: AppTheme.error, offset: Offset(3, 3))],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(LucideIcons.undo, size: 18, color: AppTheme.error),
                              SizedBox(width: 6),
                              Text('Batalkan', style: TextStyle(fontWeight: FontWeight.w900, color: AppTheme.error)),
                            ],
                          ),
                        ),
                      )
                    : _isPastDeadline
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppTheme.error,
                              border: Border.all(
                                  color: Theme.of(context).colorScheme.onSurface, width: 2),
                              boxShadow: [BoxShadow(color: Theme.of(context).colorScheme.onSurface, offset: const Offset(3, 3))],
                            ),
                            child: const Text('TERLEWAT',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                          )
                        : GestureDetector(
                            onTap: _isUploading ? null : _turnIn,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppTheme.warning,
                                border: Border.all(color: Theme.of(context).colorScheme.onSurface, width: 2),
                                boxShadow: [BoxShadow(color: Theme.of(context).colorScheme.onSurface, offset: const Offset(3, 3))],
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.send_rounded, size: 18, color: Colors.white),
                                  SizedBox(width: 6),
                                  Text('TURN IN', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.5)),
                                ],
                              ),
                            ),
                          ),
              ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: Breakpoints.screenPadding(
                    MediaQuery.of(context).size.width),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ─── Info Tugas ───────────────────────────────────────
                    NeoCard(
                      color: primaryColor.withAlpha(20),
                      borderColor: primaryColor,
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              NeoIconBox(
                                  icon: LucideIcons.clipboardList,
                                  iconColor: primaryColor,
                                  backgroundColor: primaryColor.withAlpha(50),
                                  borderColor: primaryColor,
                                ),
                              const SizedBox(width: 20),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.tugas['judul'] ?? 'Task',
                                      style: const TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w900,
                                          height: 1.1),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Jatuh tempo: $_formattedDeadline',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: _isPastDeadline
                                            ? AppTheme.error
                                            : primaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 40),
                          _buildInfoRow(LucideIcons.userCircle, 'Pengajar',
                              widget.tugas['guru_nama'] ?? 'Guru'),
                          const SizedBox(height: 12),
                          _buildInfoRow(LucideIcons.bookOpen, 'Mata Pelajaran',
                              widget.tugas['mapel'] ?? '-'),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ─── Deskripsi ────────────────────────────────────────
                    if ((widget.tugas['deskripsi'] ?? '').isNotEmpty) ...[
                      const NeoSectionHeader(title: 'Instruksi'),
                      const SizedBox(height: 12),
                      NeoCard(
                        padding: const EdgeInsets.all(24),
                        child: Text(widget.tugas['deskripsi'],
                            style: const TextStyle(fontSize: 16, height: 1.6, fontWeight: FontWeight.w500)),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // ─── Lampiran Guru ────────────────────────────────────
                    if (widget.tugas['link'] != null &&
                        widget.tugas['link'].toString().isNotEmpty) ...[
                      const NeoSectionHeader(title: 'Lampiran Soal'),
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: () => _openFile(widget.tugas['link'].toString()),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: primaryColor.withAlpha(20),
                            border:
                                Border.all(color: primaryColor, width: 2),
                            boxShadow: [BoxShadow(color: primaryColor, offset: const Offset(4, 4))],
                          ),
                          child: Row(
                            children: [
                              Icon(LucideIcons.file,
                                  color: primaryColor, size: 32),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Buka Lampiran Soal',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: primaryColor)),
                                    Text('Ketuk untuk membuka',
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                                .withValues(alpha: 0.65))),
                                  ],
                                ),
                              ),
                              Icon(LucideIcons.externalLink,
                                  color: primaryColor, size: 18),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // ─── Pekerjaan Saya ───────────────────────────────────
                    Row(
                      children: [
                        const Expanded(child: NeoSectionHeader(title: 'Pekerjaan Saya')),
                        if (_nilaiSiswa != null)
                          NeoBadge(
                            label: 'NILAI: $_nilaiSiswa',
                            color: AppTheme.success,
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    NeoCard(
                      color: (_isTurnedIn ? AppTheme.success : AppTheme.warning).withAlpha(20),
                      borderColor: _isTurnedIn ? AppTheme.success : AppTheme.warning,
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          // Status badge
                          if (_isTurnedIn)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: AppTheme.success.withAlpha(30),
                                border: Border.all(color: AppTheme.success, width: 2),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(LucideIcons.checkCircle,
                                      color: AppTheme.success, size: 18),
                                  SizedBox(width: 8),
                                  Text('Sudah Dikumpulkan',
                                      style: TextStyle(
                                          color: AppTheme.success,
                                          fontWeight: FontWeight.w800)),
                                ],
                              ),
                            ),

                          // Daftar file/link
                          if (_attachments.isEmpty && !_isUploading)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 24),
                              child: Center(
                                child: Text(
                                    'Belum ada file atau link ditambahkan',
                                    style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withValues(alpha: 0.65))),
                              ),
                            ),

                          ..._attachments.asMap().entries.map((entry) {
                            final i = entry.key;
                            final url = entry.value;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surface,
                                border: Border.all(color: Theme.of(context).colorScheme.onSurface, width: 1.5),
                                boxShadow: [BoxShadow(color: Theme.of(context).colorScheme.onSurface, offset: const Offset(3, 3))],
                              ),
                              child: ListTile(
                                leading: Icon(_getFileIcon(url),
                                    color: _getFileColor(url)),
                                title: Text(_getFileLabel(url),
                                    style:
                                        const TextStyle(fontWeight: FontWeight.w700)),
                                subtitle: Text(url,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 11)),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(LucideIcons.externalLink,
                                          size: 18),
                                      onPressed: () => _openFile(url),
                                      tooltip: 'Buka',
                                    ),
                                    if (!_isTurnedIn)
                                      IconButton(
                                        icon: const Icon(LucideIcons.x,
                                            color: AppTheme.error, size: 18),
                                        onPressed: () => _removeFile(i),
                                        tooltip: 'Hapus',
                                      ),
                                  ],
                                ),
                              ),
                            );
                          }),

                          // Loading indicator saat upload
                          if (_isUploading)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2)),
                                  const SizedBox(width: 12),
                                  Text('Mengunggah file...',
                                      style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withValues(alpha: 0.65))),
                                ],
                              ),
                            ),

                          // Tombol tambah (hanya kalau belum Turn In)
                          if (!_isTurnedIn) ...[
                            const SizedBox(height: 16),
                            GestureDetector(
                              onTap: _isUploading ? null : _pickAndUploadFile,
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 24, horizontal: 16),
                                decoration: BoxDecoration(
                                  color: AppTheme.primary.withAlpha(30),
                                  border: Border.all(color: AppTheme.primary, width: 2),
                                ),
                                child: Column(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: (Theme.of(context).brightness ==
                                                    Brightness.dark
                                                ? AppTheme.primary
                                                : AppTheme.primary)
                                            .withAlpha(20),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        LucideIcons.uploadCloud,
                                        color: Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? const Color(0xFF9EAAFF)
                                            : AppTheme.primary,
                                        size: 28,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Unggah Tugas Anda',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w800,
                                            color:
                                                Theme.of(context).brightness ==
                                                        Brightness.dark
                                                    ? Colors.white
                                                    : AppTheme.textLight,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Mendukung PDF, Word, JPG, atau Link website',
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.w500,
                                            color:
                                                Theme.of(context).brightness ==
                                                        Brightness.dark
                                                    ? AppTheme.textMutedDk
                                                    : AppTheme.textMutedLt,
                                          ),
                                    ),
                                    const SizedBox(height: 18),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        NeoButton(
                                          onTap: _isUploading ? () {} : _pickAndUploadFile,
                                          text: 'PILIH FILE',
                                        ),
                                        const SizedBox(width: 12),
                                        GestureDetector(
                                          onTap: _showAddLinkDialog,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                            constraints: const BoxConstraints(minHeight: 40),
                                            decoration: BoxDecoration(
                                              color: Theme.of(context).scaffoldBackgroundColor,
                                              border: Border.all(color: AppTheme.primary, width: 2),
                                              boxShadow: const [BoxShadow(color: AppTheme.primary, offset: Offset(3, 3))],
                                            ),
                                            child: Center(
                                              child: Text('TAMBAH LINK', style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                                fontWeight: FontWeight.w800, color: AppTheme.primary, letterSpacing: 0.5)),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // ─── Feedback ─────────────────────────────────────────
                    if (_feedbackSiswa != null && _feedbackSiswa!.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      const NeoSectionHeader(title: 'Feedback Pengajar'),
                      const SizedBox(height: 12),
                      NeoCard(
                        color: AppTheme.info.withAlpha(20),
                        borderColor: AppTheme.info,
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(LucideIcons.messageSquare, color: Color(0xFF76AFB8)),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(_feedbackSiswa!,
                                style: const TextStyle(fontSize: 15, fontStyle: FontStyle.italic)),
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
        Icon(icon, size: 18, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65)),
        const SizedBox(width: 12),
        Text(
          '$label: ',
          style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withAlpha(160),
              fontWeight: FontWeight.w500),
        ),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w700),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
