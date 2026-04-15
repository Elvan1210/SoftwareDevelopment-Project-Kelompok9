import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import '../../../config/api_config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import '../../../services/notifikasi_service.dart';
import '../../../services/upload_service.dart';
import '../../../widgets/app_shell.dart';
import 'package:lucide_icons/lucide_icons.dart';

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
        final List allPengumpulan =
            jsonDecode(responses[0].body) is List ? jsonDecode(responses[0].body) : [];
        final List allNilai =
            jsonDecode(responses[1].body) is List ? jsonDecode(responses[1].body) : [];

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
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
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
              backgroundColor: Colors.red,
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
              backgroundColor: Colors.red,
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
        title: const Text('Tambah Link', style: TextStyle(fontWeight: FontWeight.w900)),
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
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFB84A24),
              foregroundColor: Colors.white,
            ),
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
                    backgroundColor: Colors.orange,
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
    if (lower.contains('.pdf') || lower.contains('/raw/')) return LucideIcons.fileText;
    if (lower.contains('.jpg') || lower.contains('.jpeg') || lower.contains('.png')) {
      return LucideIcons.image;
    }
    if (lower.contains('.doc')) return LucideIcons.fileText;
    return LucideIcons.link;
  }

  Color _getFileColor(String url) {
    final lower = url.toLowerCase();
    if (lower.contains('.pdf') || lower.contains('/raw/')) return Colors.red;
    if (lower.contains('.jpg') || lower.contains('.jpeg') || lower.contains('.png')) {
      return Colors.green;
    }
    if (lower.contains('.doc')) return Colors.blue;
    return Colors.purple;
  }

  String _getFileLabel(String url) {
    final lower = url.toLowerCase();
    if (lower.contains('.pdf') || lower.contains('/raw/')) return 'File PDF';
    if (lower.contains('.jpg') || lower.contains('.jpeg') || lower.contains('.png')) {
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
      finalUrl = 'https://docs.google.com/viewer?url=${Uri.encodeComponent(url)}';
    }
    final uri = Uri.parse(finalUrl);
    if (await canLaunchUrl(uri)) {
      // Di Flutter Web, gunakan platformDefault agar buka tab baru
      await launchUrl(uri, mode: LaunchMode.platformDefault);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak bisa membuka file'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _turnIn() async {
    if (_attachments.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tambahkan file atau link terlebih dahulu!'),
          backgroundColor: Colors.orange,
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
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal mengirim: ${response.statusCode}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
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
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error jaringan: $e'), backgroundColor: Colors.red),
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
                    ? OutlinedButton.icon(
                        onPressed: _undoTurnIn,
                        icon: const Icon(LucideIcons.undo, size: 18),
                        label: const Text('Batalkan'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      )
                    : _isPastDeadline
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.red.withAlpha(30),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text('Terlewat',
                                style: TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold)),
                          )
                        : ElevatedButton.icon(
                            onPressed: _isUploading ? null : _turnIn,
                            icon: const Icon(Icons.send_rounded, size: 18),
                            label: const Text('Turn In'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFB84A24),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
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
                      PremiumCard(
                        accentColor: primaryColor,
                        padding: const EdgeInsets.all(24),
                        child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: primaryColor.withAlpha(30),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Icon(LucideIcons.clipboardList,
                                    color: primaryColor, size: 28),
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
                                            ? Colors.red
                                            : primaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 40),
                          _buildInfoRow(LucideIcons.userCircle,
                              'Pengajar', widget.tugas['guru_nama'] ?? 'Guru'),
                          const SizedBox(height: 12),
                          _buildInfoRow(LucideIcons.bookOpen, 'Mata Pelajaran',
                              widget.tugas['mapel'] ?? '-'),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ─── Deskripsi ────────────────────────────────────────
                    if ((widget.tugas['deskripsi'] ?? '').isNotEmpty) ...[
                      const SectionHeader(title: 'Instruksi'),
                      const SizedBox(height: 12),
                      PremiumCard(
                        padding: const EdgeInsets.all(24),
                        child: Text(widget.tugas['deskripsi'],
                            style: const TextStyle(fontSize: 16, height: 1.6)),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // ─── Lampiran Guru ────────────────────────────────────
                    if (widget.tugas['link'] != null &&
                        widget.tugas['link'].toString().isNotEmpty) ...[
                      const SectionHeader(title: 'Lampiran Soal'),
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: () =>
                            _openFile(widget.tugas['link'].toString()),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: primaryColor.withAlpha(20),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: primaryColor.withAlpha(80)),
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
                                            color: Colors.grey.shade600)),
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
                        const Expanded(
                            child: SectionHeader(title: 'Pekerjaan Saya')),
                        if (_nilaiSiswa != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.green.withAlpha(30),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Nilai: $_nilaiSiswa',
                              style: const TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.w900),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    PremiumCard(
                      accentColor:
                          _isTurnedIn ? Colors.green : const Color(0xFFB84A24),
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          // Status badge
                          if (_isTurnedIn)
                            Container(
                              width: double.infinity,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 10),
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.green.withAlpha(20),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(LucideIcons.checkCircle,
                                      color: Colors.green, size: 18),
                                  SizedBox(width: 8),
                                  Text('Sudah Dikumpulkan',
                                      style: TextStyle(
                                          color: Colors.green,
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
                                    style: TextStyle(color: Colors.grey.shade600)),
                              ),
                            ),

                          ..._attachments.asMap().entries.map((entry) {
                            final i = entry.key;
                            final url = entry.value;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: _getFileColor(url).withAlpha(15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: _getFileColor(url).withAlpha(50)),
                              ),
                              child: ListTile(
                                leading: Icon(_getFileIcon(url),
                                    color: _getFileColor(url)),
                                title: Text(_getFileLabel(url),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700)),
                                subtitle: Text(url,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style:
                                        const TextStyle(fontSize: 11)),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                          LucideIcons.externalLink,
                                          size: 18),
                                      onPressed: () => _openFile(url),
                                      tooltip: 'Buka',
                                    ),
                                    if (!_isTurnedIn)
                                      IconButton(
                                        icon: const Icon(
                                            LucideIcons.x,
                                            color: Colors.red,
                                            size: 18),
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
                                      style: TextStyle(color: Colors.grey.shade600)),
                                ],
                              ),
                            ),

                          // Tombol tambah (hanya kalau belum Turn In)
                          if (!_isTurnedIn) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _isUploading
                                        ? null
                                        : _pickAndUploadFile,
                                    icon: const Icon(
                                        LucideIcons.uploadCloud,
                                        size: 18),
                                    label: const Text('File / Foto'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: primaryColor,
                                      side: BorderSide(color: primaryColor),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12)),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 14),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _showAddLinkDialog,
                                    icon: const Icon(LucideIcons.link,
                                        size: 18),
                                    label: const Text('Tambah Link'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.purple,
                                      side: const BorderSide(
                                          color: Colors.purple),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12)),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 14),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),

                    // ─── Feedback ─────────────────────────────────────────
                    if (_feedbackSiswa != null &&
                        _feedbackSiswa!.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      const SectionHeader(title: 'Feedback Pengajar'),
                      const SizedBox(height: 12),
                      PremiumCard(
                        accentColor: Colors.blue,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(LucideIcons.messageSquare,
                                color: Colors.blue),
                            const SizedBox(width: 16),
                            Expanded(
                                child: Text(_feedbackSiswa!,
                                    style: const TextStyle(
                                        fontSize: 15,
                                        fontStyle: FontStyle.italic))),
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
        Text(
          '$label: ',
          style: const TextStyle(color: Color(0xFF595959), fontWeight: FontWeight.w500),
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