import 'package:flutter/material.dart';
import '../../../services/upload_service.dart';
import '../../../config/theme.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../widgets/confirm_delete.dart';
import '../../../config/api_config.dart';
import '../../../widgets/app_shell.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:file_picker/file_picker.dart';

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
                        prefixIcon: Icons.title_rounded),
                    const SizedBox(height: 16),
                    AppTextField(
                        controller: deskripsiCtrl,
                        labelText: 'Deskripsi Singkat',
                        prefixIcon: Icons.description_outlined,
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
                                backgroundColor: const Color(0xFF76AFB8),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                              icon: const Icon(Icons.cloud_upload_outlined),
                              label: Text(selectedFileName ?? 'Pilih File (PDF/Gambar)'),
                            ),
                          const SizedBox(height: 12),
                          AppTextField(
                            controller: linkCtrl,
                            labelText: 'Link File / URL Cloudinary',
                            prefixIcon: Icons.link_rounded,
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
                  backgroundColor: const Color(0xFFF27F33),
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
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF76AFB8),
        onPressed: () => _showMateriForm(),
        icon: const Icon(Icons.add_circle_outline, color: Colors.white),
        label: const Text('Materi Baru', style: TextStyle(color: Colors.white)),
      ),
      body: _materiList.isEmpty
          ? const Center(child: Text("Belum ada materi untuk kelas ini."))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _materiList.length,
              itemBuilder: (_, i) {
                final m = _materiList[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF76AFB8).withAlpha(30),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.menu_book_rounded, color: Color(0xFF76AFB8)),
                    ),
                    title: Text(m['judul'] ?? '-', 
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(m['deskripsi'] ?? (m['kelas'] ?? '-'), 
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                            icon: const Icon(Icons.open_in_new, color: Colors.blue),
                            onPressed: () => _openFile(m['file_url'])),
                        IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () => _deleteMateri(m['id'].toString())),
                      ],
                    ),
                  ),
                ).animate().fadeIn(delay: (i * 50).ms).slideX();
              },
            ),
    );
  }
}