import 'package:flutter/material.dart';
import '../../../services/upload_service.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../widgets/confirm_delete.dart';
import '../../../config/api_config.dart';
import '../../../widgets/app_shell.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:file_picker/file_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';

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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Text(isEditing ? 'Edit Materi' : 'Tambah Materi Baru', 
              style: const TextStyle(fontWeight: FontWeight.bold)),
            content: SizedBox(
              width: 500,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppTextField(
                        controller: judulCtrl,
                        labelText: 'Judul Materi',
                        prefixIcon: LucideIcons.type),
                    const SizedBox(height: 16),
                    AppTextField(
                        controller: deskripsiCtrl,
                        labelText: 'Deskripsi Singkat',
                        prefixIcon: LucideIcons.alignLeft,
                        keyboardType: TextInputType.multiline),
                    const SizedBox(height: 20),
                    
                    // --- AREA UPLOAD ---
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.withAlpha(20),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.withAlpha(40)),
                      ),
                      child: Column(
                        children: [
                          if (isUploading)
                            const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: CircularProgressIndicator(),
                            )
                          else
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).primaryColor,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                              ),
                              onPressed: () async {
                                FilePickerResult? result = await FilePicker.platform.pickFiles(
                                  type: FileType.custom,
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
                              icon: const Icon(LucideIcons.uploadCloud),
                              label: Text(selectedFileName ?? 'Pilih File (PDF/Gambar)'),
                            ),
                          const SizedBox(height: 12),
                          AppTextField(
                            controller: linkCtrl,
                            labelText: 'Link File / URL Cloudinary',
                            prefixIcon: LucideIcons.link,
                            // Dibuat read-only jika ingin memaksa user lewat tombol upload
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  if (judulCtrl.text.isEmpty) return;

                  final body = {
                    'judul': judulCtrl.text,
                    'deskripsi': deskripsiCtrl.text,
                    'file_url': linkCtrl.text, // Pastikan field ini sesuai dengan backend
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
                child: const Text('Simpan Materi'),
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: AppFAB(
        onPressed: () => _showMateriForm(),
        icon: LucideIcons.plusCircle,
        label: 'Materi Baru',
      ),
      body: _materiList.isEmpty
          ? EmptyState(icon: LucideIcons.bookOpen, message: 'Belum ada materi untuk kelas ini.', color: Theme.of(context).primaryColor)
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _materiList.length,
              itemBuilder: (_, i) {
                final m = _materiList[i];
                return PremiumCard(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withAlpha(20),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(LucideIcons.bookOpen, color: Theme.of(context).primaryColor),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(m['judul'] ?? '-', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                            const SizedBox(height: 4),
                            Text(m['deskripsi'] ?? (m['kelas'] ?? '-'), style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withAlpha(150)), maxLines: 1, overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                              icon: Icon(LucideIcons.externalLink, color: Theme.of(context).colorScheme.secondary),
                              onPressed: () => _openFile(m['file_url'])),
                          IconButton(
                              icon: const Icon(LucideIcons.trash, color: Colors.red),
                              onPressed: () => _deleteMateri(m['id'].toString())),
                        ],
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: (i * 50).ms).slideX();
              },
            ),
    );
  }
}