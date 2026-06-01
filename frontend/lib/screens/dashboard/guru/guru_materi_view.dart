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
import 'package:lucide_icons_flutter/lucide_icons.dart';
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
            backgroundColor: Theme.of(context).colorScheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: BorderSide(color: Theme.of(context).dividerColor, width: 1.2),
            ),
            title: Text(
              isEditing ? 'Edit Materi' : 'Tambah Materi Baru', 
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : AppTheme.textLight),
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
                        color: Theme.of(context).colorScheme.surface,
                        border: Border.all(color: Theme.of(context).dividerColor),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: TextField(
                        controller: deskripsiCtrl,
                        maxLines: 4,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: isDark ? Colors.white : AppTheme.textLight),
                        decoration: InputDecoration(
                          labelText: 'Deskripsi Singkat',
                          labelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(color: isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt, fontWeight: FontWeight.w600),
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
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Theme.of(context).dividerColor, width: 1.2),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'LAMPIRAN MATERI (OPSIONAL)',
                            style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w900,
                              color: AppTheme.primary,
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
                                    allowedExtensions: const ['pdf', 'jpg', 'png', 'doc', 'docx'],
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
                                        const SnackBar(content: Text('Gagal upload file!'), backgroundColor: AppTheme.error)
                                      );
                                    }
                                  }
                                },
                                icon: const Icon(LucideIcons.uploadCloud, size: 16),
                                label: Text(
                                  selectedFileName ?? 'Pilih File (PDF/Gambar)',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: Theme.of(context).colorScheme.surface,
                                  foregroundColor: theme.primaryColor,
                                  side: BorderSide(color: Theme.of(context).colorScheme.surface, width: 1.0),
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
                  style: GoogleFonts.poppins(
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
                    'guru_id': widget.userData['id'],
                    'guru_nama': widget.userData['nama'] ?? 'Guru',
                    if (!isEditing) 'created_at': DateTime.now().toIso8601String(),
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
                child: Text('Simpan Materi', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
              )
            ],
          );
        },
      ),
    );
  }

  Future<void> _openFile(String? url) async {
    if (url == null || url.isEmpty) return;
    if (!url.startsWith('http')) url = 'https://$url';
    final uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint("Gagal buka URL: $e");
    }
  }

  void _showMateriDetail(Map<String, dynamic> m) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    const accent = Color(0xFF76AFB8);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: Theme.of(context).dividerColor, width: 1.2),
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
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : AppTheme.textLight),
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
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800,
                    color: isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt,
                    letterSpacing: 0.5),
                ),
                const SizedBox(height: 6),
                Text(
                  m['deskripsi'],
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.5,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white70 : AppTheme.textLight),
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
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.surface,
                      foregroundColor: accent,
                      side: BorderSide(
                        color: Theme.of(context).colorScheme.surface,
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
              style: GoogleFonts.poppins(
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
              backgroundColor: Theme.of(context).colorScheme.surface,
              foregroundColor: AppTheme.primary,
              side: BorderSide(color: Theme.of(context).colorScheme.surface, width: 1.0),
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

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: GestureDetector(
        onTap: () => _showMateriForm(),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          constraints: const BoxConstraints(minHeight: 44),
          decoration: BoxDecoration(
            color: AppTheme.primary,
            border: Border.all(color: Theme.of(context).colorScheme.onSurface, width: 2),
            boxShadow: [BoxShadow(color: Theme.of(context).colorScheme.onSurface, offset: const Offset(4, 4))],
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(LucideIcons.plusCircle, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text('MATERI BARU', style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.5,
            )),
          ]),
        ),
      ).animate().fadeIn().slideY(begin: 0.5),
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
                      color: Theme.of(context).colorScheme.surface,
                      border: Border.all(color: Theme.of(context).colorScheme.onSurface, width: 2),
                      boxShadow: [BoxShadow(color: Theme.of(context).colorScheme.onSurface, offset: const Offset(4, 4), blurRadius: 0)],
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.primary,
                            border: Border.all(color: Theme.of(context).colorScheme.onSurface, width: 1.5),
                            boxShadow: [BoxShadow(color: Theme.of(context).colorScheme.onSurface, offset: const Offset(2, 2), blurRadius: 0)],
                          ),
                          child: const Icon(LucideIcons.bookOpen, color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                m['judul'] ?? '-',
                                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: Theme.of(context).textTheme.bodyLarge!.color!),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                m['deskripsi'] ?? '-',
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: Theme.of(context).textTheme.bodyMedium!.color!,
                                  fontWeight: FontWeight.w600),
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
                            GestureDetector(
                              onTap: () => _openFile(m['file_url']),
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppTheme.emerald,
                                  border: Border.all(color: Theme.of(context).colorScheme.onSurface, width: 1.5),
                                  boxShadow: [BoxShadow(color: Theme.of(context).colorScheme.onSurface, offset: const Offset(2, 2), blurRadius: 0)],
                                ),
                                child: const Icon(LucideIcons.externalLink, color: Colors.white, size: 14),
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => _deleteMateri(m['id'].toString()),
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppTheme.rose,
                                  border: Border.all(color: Theme.of(context).colorScheme.onSurface, width: 1.5),
                                  boxShadow: [BoxShadow(color: Theme.of(context).colorScheme.onSurface, offset: const Offset(2, 2), blurRadius: 0)],
                                ),
                                child: const Icon(LucideIcons.trash2, color: Colors.white, size: 14),
                              ),
                            ),
                          ],
                        ),
                      ],       
                    ),
                  ),
                ).animate(delay: (i * 50).ms).fadeIn().slideY(begin: 0.1, curve: Curves.easeOutQuart);
              },
            ),
    );
  }
}
