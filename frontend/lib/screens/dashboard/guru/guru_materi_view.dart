import 'package:flutter/material.dart';
import '../../../services/upload_service.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../widgets/confirm_delete.dart';
import '../../../config/api_config.dart';
import '../../../widgets/app_shell.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:file_picker/file_picker.dart' as fp;
import 'package:lucide_icons/lucide_icons.dart';
import '../../../config/theme.dart';
import 'package:google_fonts/google_fonts.dart';

class GuruMateriView extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String token;
  final dynamic teamData;

  const GuruMateriView({
    super.key,
    required this.userData,
    required this.token,
    required this.teamData,
  });

  @override
  State<GuruMateriView> createState() => _GuruMateriViewState();
}

class _GuruMateriViewState extends State<GuruMateriView> {
  List<dynamic> _materiList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMateri();
  }

  Future<void> _fetchMateri() async {
    setState(() => _isLoading = true);
    try {
      final kelasId = widget.teamData['id'];
      final response = await http.get(
        Uri.parse('$baseUrl/api/materi?kelas_id=$kelasId'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      if (response.statusCode == 200) {
        final dec = jsonDecode(response.body);
        setState(() {
          _materiList = dec is List ? dec : [];
        });
      }
    } catch (e) {
      debugPrint('Error fetch materi: $e');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _deleteMateri(String id) async {
    if (await confirmDelete(context, pesan: 'Yakin hapus materi ini?')) {
      try {
        await http.delete(
          Uri.parse('$baseUrl/api/materi/$id'),
          headers: {'Authorization': 'Bearer ${widget.token}'},
        );
        _fetchMateri();
      } catch (e) {
        debugPrint('Error delete materi: $e');
      }
    }
  }

  void _showMateriForm([Map<String, dynamic>? materi]) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isEditing = materi != null;
    final judulCtrl = TextEditingController(text: isEditing ? materi['judul'] : '');
    final deskripsiCtrl = TextEditingController(text: isEditing ? materi['deskripsi'] ?? '' : '');
    final linkCtrl = TextEditingController(text: isEditing ? materi['file_url'] ?? '' : '');

    bool isUploading = false;
    String? selectedFileName = isEditing && materi['file_url'] != null ? 'File tersemat' : null;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            backgroundColor: isDark ? const Color(0xFF161B27) : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: BorderSide(color: isDark ? const Color(0xFF252D3D) : const Color(0xFFE5E7EB), width: 1.2),
            ),
            title: Text(
              isEditing ? 'Edit Materi' : 'Tambah Materi Baru', 
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w900,
                fontSize: 18,
                color: isDark ? Colors.white : AppTheme.textLight,
              ),
            ),
            content: SizedBox(
              width: 500,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppTextField(
                      controller: judulCtrl,
                      labelText: 'Judul Materi',
                      prefixIcon: LucideIcons.type,
                    ),
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF161D2B) : const Color(0xFFEEF2FF),
                        border: Border.all(color: isDark ? const Color(0xFF252D3D) : const Color(0xFFE5E7EB)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: TextField(
                        controller: deskripsiCtrl,
                        maxLines: 4,
                        style: GoogleFonts.plusJakartaSans(fontSize: 13, color: isDark ? Colors.white : AppTheme.textLight),
                        decoration: InputDecoration(
                          labelText: 'Deskripsi Singkat',
                          labelStyle: GoogleFonts.plusJakartaSans(fontSize: 12, color: isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt, fontWeight: FontWeight.w600),
                          prefixIcon: const Icon(LucideIcons.alignLeft, size: 18),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // --- AREA UPLOAD ---
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF161D2B) : const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: isDark ? const Color(0xFF252D3D) : const Color(0xFFE5E7EB), width: 1.2),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'LAMPIRAN MATERI (OPSIONAL)',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: isDark ? const Color(0xFF9EAAFF) : const Color(0xFF4C51BF),
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 10),
                          if (isUploading)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.all(12.0),
                                child: CircularProgressIndicator(strokeWidth: 3),
                              ),
                            )
                          else
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  fp.FilePickerResult? result = await fp.FilePicker.platform.pickFiles(
                                    type: fp.FileType.custom,
                                    allowedExtensions: ['pdf', 'jpg', 'png', 'doc', 'docx'],
                                    withData: true,
                                  );

                                  if (result != null && result.files.single.bytes != null) {
                                    setDialogState(() => isUploading = true);
                                    
                                    final file = result.files.single;
                                    String? url = await UploadService.uploadFile(
                                      fileBytes: file.bytes!,
                                      fileName: file.name,
                                      token: widget.token,
                                    );

                                    setDialogState(() {
                                      isUploading = false;
                                      if (url != null) {
                                        linkCtrl.text = url;
                                        selectedFileName = file.name;
                                      }
                                    });

                                    if (url == null && ctx.mounted) {
                                      ScaffoldMessenger.of(ctx).showSnackBar(
                                        const SnackBar(content: Text('Gagal upload file!'), backgroundColor: Colors.red)
                                      );
                                    }
                                  }
                                },
                                icon: const Icon(LucideIcons.uploadCloud, size: 16),
                                label: Text(
                                  selectedFileName ?? 'Pilih File (PDF/Gambar)',
                                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: isDark ? const Color(0xFF1B2C3F) : const Color(0xFFE0EEFF),
                                  foregroundColor: theme.primaryColor,
                                  side: BorderSide(color: isDark ? const Color(0xFF2E4663) : const Color(0xFF82B8FF), width: 1.0),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ),
                          const SizedBox(height: 12),
                          AppTextField(
                            controller: linkCtrl,
                            labelText: 'Link File / URL Cloudinary',
                            prefixIcon: LucideIcons.link,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  'Batal',
                  style: GoogleFonts.plusJakartaSans(
                    color: isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (judulCtrl.text.isEmpty) return;

                  final body = {
                    'judul': judulCtrl.text,
                    'deskripsi': deskripsiCtrl.text,
                    'file_url': linkCtrl.text, 
                    'kelas_id': widget.teamData['id'],
                    'kelas': widget.teamData['nama_kelas'],
                    'mapel': widget.teamData['mapel'] ?? '-',
                    'guru_id': widget.userData['id'],
                  };

                  final url = isEditing
                      ? '$baseUrl/api/materi/${materi['id']}'
                      : '$baseUrl/api/materi';

                  final res = isEditing
                      ? await http.put(Uri.parse(url),
                          headers: {
                            'Content-Type': 'application/json',
                            'Authorization': 'Bearer ${widget.token}'
                          },
                          body: jsonEncode(body))
                      : await http.post(Uri.parse(url),
                          headers: {
                            'Content-Type': 'application/json',
                            'Authorization': 'Bearer ${widget.token}'
                          },
                          body: jsonEncode(body));

                  if (res.statusCode == 200 || res.statusCode == 201) {
                    if (ctx.mounted) Navigator.pop(ctx);
                    _fetchMateri();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.secondary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                child: Text('Simpan Materi', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
              )
            ],
          );
        },
      ),
    );
  }

  Future<void> _openFile(String? url) async {
    if (url == null || url.isEmpty) return;
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      debugPrint("Gagal buka URL");
    }
  }

  void _showMateriDetail(Map<String, dynamic> m) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    const accent = Color(0xFF76AFB8);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF161B27) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: isDark ? const Color(0xFF252D3D) : const Color(0xFFE5E7EB), width: 1.2),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.primaryColor.withAlpha(20),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(LucideIcons.bookOpen, color: theme.primaryColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                m['judul'] ?? '-',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  color: isDark ? Colors.white : AppTheme.textLight,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (m['deskripsi'] != null && m['deskripsi'].toString().isNotEmpty) ...[
                Text(
                  'Deskripsi',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                    color: isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  m['deskripsi'],
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white70 : AppTheme.textLight,
                  ),
                ),
                const SizedBox(height: 16),
              ],
              if (m['file_url'] != null && m['file_url'].toString().isNotEmpty)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _openFile(m['file_url']),
                    icon: const Icon(LucideIcons.externalLink, size: 14),
                    label: Text(
                      'Buka File Materi',
                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: isDark ? const Color(0xFF1B3539) : const Color(0xFFE6F5F7),
                      foregroundColor: accent,
                      side: BorderSide(
                        color: isDark ? const Color(0xFF28565C) : const Color(0xFF9AD5DE),
                        width: 1.0,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Tutup',
              style: GoogleFonts.plusJakartaSans(
                color: isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          OutlinedButton.icon(
            onPressed: () { Navigator.pop(ctx); _showMateriForm(m); },
            icon: const Icon(LucideIcons.edit2, size: 12),
            label: const Text(
              'Edit',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
            ),
            style: OutlinedButton.styleFrom(
              backgroundColor: isDark ? const Color(0xFF2E243F) : const Color(0xFFF3E8FF),
              foregroundColor: Colors.purple,
              side: BorderSide(color: isDark ? const Color(0xFF4C3A66) : const Color(0xFFC084FC), width: 1.0),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: AppFAB(
        onPressed: () => _showMateriForm(),
        icon: LucideIcons.plusCircle,
        label: 'Materi Baru',
      ),
      body: _materiList.isEmpty
          ? EmptyState(
              icon: LucideIcons.bookOpen,
              message: 'Belum ada materi untuk kelas ini.',
              color: theme.primaryColor,
            )
          : ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: _materiList.length,
              itemBuilder: (_, i) {
                final m = _materiList[i];
                return GestureDetector(
                  onTap: () => _showMateriDetail(m),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E2538) : Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: theme.primaryColor.withAlpha(isDark ? 55 : 30),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(isDark ? 60 : 8),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF161D2B) : const Color(0xFFEEF2FF),
                          borderRadius: BorderRadius.circular(19),
                          border: Border.all(
                            color: isDark ? const Color(0xFF2D3A54) : const Color(0xFFE5E7EB),
                            width: 1.0,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: theme.primaryColor.withAlpha(20),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(LucideIcons.bookOpen, color: theme.primaryColor, size: 22),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    m['judul'] ?? '-',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 15,
                                      color: isDark ? Colors.white : AppTheme.textLight,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    m['deskripsi'] ?? (m['kelas'] ?? '-'),
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      color: isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                OutlinedButton(
                                  onPressed: () => _openFile(m['file_url']),
                                  style: OutlinedButton.styleFrom(
                                    backgroundColor: isDark ? const Color(0xFF1B3B2B) : const Color(0xFFE6F4EA),
                                    foregroundColor: Colors.green,
                                    side: BorderSide(color: isDark ? const Color(0xFF2E5C3E) : const Color(0xFF82C793), width: 1.0),
                                    padding: const EdgeInsets.all(10),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: const Icon(LucideIcons.externalLink, size: 14),
                                ),
                                const SizedBox(width: 8),
                                OutlinedButton(
                                  onPressed: () => _deleteMateri(m['id'].toString()),
                                  style: OutlinedButton.styleFrom(
                                    backgroundColor: isDark ? const Color(0xFF3D1B1B) : const Color(0xFFFCE8E8),
                                    foregroundColor: Colors.red,
                                    side: BorderSide(color: isDark ? const Color(0xFF5C2E2E) : const Color(0xFFECA3A3), width: 1.0),
                                    padding: const EdgeInsets.all(10),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: const Icon(LucideIcons.trash2, size: 14),
                                ),
                              ],
                            ),
                          ],       
                        ),
                      ),
                    ),
                  ),
                ).animate(delay: (i * 50).ms).fadeIn().slideY(begin: 0.1, curve: Curves.easeOutQuart);
              },
            ),
    );
  }
}
