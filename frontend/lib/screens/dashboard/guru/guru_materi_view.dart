import 'package:flutter/material.dart';
import '../../../services/upload_service.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../widgets/confirm_delete.dart';
import '../../../config/api_config.dart';
import '../../../widgets/app_shell.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/link.dart';
import 'package:file_picker/file_picker.dart' as fp;
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../config/theme.dart';
import 'package:google_fonts/google_fonts.dart';

// --- Tailwind Neo-Brutalist Tokens -----------------------------------------
const Color _onSurface = Color(0xFF001E2B);
const Color _onSurfaceVariant = Color(0xFF414944);
const Color _primary = Color(0xFF3D6754);
const Color _primaryContainer = Color(0xFFB7E5CD);
const Color _onPrimaryContainer = Color(0xFF3E6855);
const Color _secondaryContainer = Color(0xFFB7EDE7);
const Color _onSecondaryContainer = Color(0xFF3A6D69);
const Color _tertiaryContainer = Color(0xFFFFD1C0);
const Color _onTertiaryContainer = Color(0xFF8E4F34);
const Color _surfaceContainerLowest = Color(0xFFFFFFFF);
const Color _surfaceContainerHighest = Color(0xFFC1E8FF);
const Color _outlineVariant = Color(0xFFC1C8C2);
const Color _primaryFixed = Color(0xFFBFEDD5);
const Color _onPrimaryFixed = Color(0xFF002115);

BorderRadius get _asymmetricRadius => const BorderRadius.only(
      topLeft: Radius.circular(4),
      topRight: Radius.circular(16),
      bottomRight: Radius.circular(4),
      bottomLeft: Radius.circular(16),
    );

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
  String _searchQuery = '';

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

    final onSurface = isDark ? Colors.white : const Color(0xFF001E2B);
    final onSurfaceVariant = isDark ? Colors.white70 : const Color(0xFF414944);
    final primaryContainer = isDark ? const Color(0xFF161B27) : const Color(0xFFB7E5CD);

    showDialog(
      context: context,
      barrierColor: onSurface.withValues(alpha: 0.4),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.all(24),
            child: Container(
              width: 500,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border.all(color: onSurface, width: 2),
                boxShadow: [
                  BoxShadow(color: onSurface, offset: const Offset(4, 4)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // HEADER
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: primaryContainer,
                      border: Border(bottom: BorderSide(color: onSurface, width: 2)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isEditing ? 'EDIT MATERI' : 'BUAT MATERI BARU',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: onSurface,
                            letterSpacing: -0.5,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(ctx),
                          child: Icon(Icons.close, color: onSurface, size: 24),
                        ),
                      ],
                    ),
                  ),

                  // BODY
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Judul Materi
                          Text(
                            'JUDUL MATERI',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: onSurface,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: judulCtrl,
                            style: GoogleFonts.inter(color: onSurface),
                            decoration: InputDecoration(
                              hintText: 'Masukkan judul materi...',
                              hintStyle: GoogleFonts.inter(color: onSurfaceVariant),
                              filled: true,
                              fillColor: Theme.of(context).colorScheme.surface,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.zero,
                                borderSide: BorderSide(color: onSurface, width: 2),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.zero,
                                borderSide: BorderSide(color: onSurface, width: 2),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.zero,
                                borderSide: BorderSide(color: onSurface, width: 2),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Deskripsi
                          Text(
                            'DESKRIPSI SINGKAT',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: onSurface,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: deskripsiCtrl,
                            maxLines: 3,
                            style: GoogleFonts.inter(color: onSurface),
                            decoration: InputDecoration(
                              hintText: 'Jelaskan isi materi secara ringkas...',
                              hintStyle: GoogleFonts.inter(color: onSurfaceVariant),
                              filled: true,
                              fillColor: Theme.of(context).colorScheme.surface,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.zero,
                                borderSide: BorderSide(color: onSurface, width: 2),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.zero,
                                borderSide: BorderSide(color: onSurface, width: 2),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.zero,
                                borderSide: BorderSide(color: onSurface, width: 2),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Lampiran
                          Row(
                            children: [
                              Text(
                                'LAMPIRAN MATERI',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: onSurface,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Divider(color: onSurfaceVariant.withValues(alpha: 0.2), thickness: 1),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          
                          if (isUploading)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.all(24.0),
                                child: CircularProgressIndicator(),
                              ),
                            )
                          else
                            Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () async {
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
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 20),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.surface,
                                        border: Border.all(color: onSurface, width: 2),
                                        boxShadow: [
                                          BoxShadow(color: onSurface, offset: const Offset(2, 2)),
                                        ],
                                      ),
                                      child: Column(
                                        children: [
                                          Icon(Icons.upload_file, color: onSurface, size: 32),
                                          const SizedBox(height: 8),
                                          Text(
                                            'UPLOAD FILE',
                                            style: GoogleFonts.inter(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: onSurface,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      // Optional cloud logic
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 20),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.surface,
                                        border: Border.all(color: onSurface, width: 2),
                                        boxShadow: [
                                          BoxShadow(color: onSurface, offset: const Offset(2, 2)),
                                        ],
                                      ),
                                      child: Column(
                                        children: [
                                          Icon(Icons.cloud_done_outlined, color: onSurface, size: 32),
                                          const SizedBox(height: 8),
                                          Text(
                                            'CLOUD LINK',
                                            style: GoogleFonts.inter(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: onSurface,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          
                          if (selectedFileName != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Text('File terpilih: $selectedFileName', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF3D6754), fontWeight: FontWeight.bold)),
                            ),

                          const SizedBox(height: 12),
                          TextField(
                            controller: linkCtrl,
                            style: GoogleFonts.inter(color: onSurface),
                            decoration: InputDecoration(
                              hintText: 'Atau masukkan Link / URL File...',
                              hintStyle: GoogleFonts.inter(color: onSurfaceVariant),
                              filled: true,
                              fillColor: Theme.of(context).colorScheme.surface,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.zero,
                                borderSide: BorderSide(color: onSurface, width: 2),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.zero,
                                borderSide: BorderSide(color: onSurface, width: 2),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.zero,
                                borderSide: BorderSide(color: onSurface, width: 2),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // FOOTER
                  Container(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: () async {
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
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF3D6754),
                              border: Border.all(color: onSurface, width: 2),
                              boxShadow: [
                                BoxShadow(color: onSurface, offset: const Offset(4, 4)),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'SIMPAN MATERI',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.save, color: Colors.white, size: 20),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        GestureDetector(
                          onTap: () => Navigator.pop(ctx),
                          child: Text(
                            'BATAL',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: onSurfaceVariant,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmpty() {
    final isEmpty = _searchQuery.isEmpty;
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: _asymmetricRadius,
          border: Border.all(color: _onSurface, width: 2),
          boxShadow: const [BoxShadow(color: _onSurface, offset: Offset(4, 4), blurRadius: 0)],
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _surfaceContainerHighest,
              shape: BoxShape.circle,
              border: Border.all(color: _onSurface, width: 2),
            ),
            child: const Icon(LucideIcons.bookOpen, color: _onSurface, size: 28),
          ),
          const SizedBox(height: 14),
          Text(
            isEmpty ? 'Belum ada materi\ndi kelas ini.' : 'Materi tidak ditemukan.',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 18, color: _onSurface),
          ),
          const SizedBox(height: 6),
          Text(
            isEmpty ? 'Ayo tambahkan materi baru.' : 'Coba kata kunci lain.',
            style: GoogleFonts.inter(fontSize: 14, color: _onSurfaceVariant, fontWeight: FontWeight.w500),
          ),
        ]),
      ),
    );
  }

  Widget _buildSkeleton() {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: SkeletonLoader(height: 52, radius: 4),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: 5,
            itemBuilder: (_, __) => const Padding(
              padding: EdgeInsets.only(bottom: 24),
              child: SkeletonLoader(height: 180, radius: 16),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildSkeleton();
    }

    List<dynamic> filteredMateri = _materiList.where((m) {
      final judul = (m['judul'] ?? '').toString().toLowerCase();
      final deskripsi = (m['deskripsi'] ?? '').toString().toLowerCase();
      final query = _searchQuery.toLowerCase();
      return judul.contains(query) || deskripsi.contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: _onSurface, width: 2),
                boxShadow: const [
                  BoxShadow(color: _onSurface, offset: Offset(4, 4), blurRadius: 0),
                ],
              ),
              child: TextField(
                onChanged: (val) => setState(() => _searchQuery = val),
                style: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 16, color: _onSurface),
                decoration: InputDecoration(
                  hintText: 'Cari materi...',
                  hintStyle: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 16, color: _onSurfaceVariant),
                  prefixIcon: const Icon(LucideIcons.search, size: 20, color: _onSurface),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
              ),
            ),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1, curve: Curves.easeOutCubic),

          Expanded(
            child: filteredMateri.isEmpty
                ? _buildEmpty()
                : RefreshIndicator(
                    onRefresh: _fetchMateri,
                    color: _primary,
                    child: LayoutBuilder(
                      builder: (ctx, c) {
                        final w = c.maxWidth;
                        final padding = Breakpoints.screenPadding(w);
                        return ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          padding: EdgeInsets.only(
                            left: padding.left > 16 ? padding.left : 16,
                            right: padding.right > 16 ? padding.right : 16,
                            top: 16,
                            bottom: 100,
                          ),
                          itemCount: filteredMateri.length + 1,
                          itemBuilder: (_, i) {
                            if (i == 0) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 24),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                      margin: const EdgeInsets.only(bottom: 8),
                                      decoration: BoxDecoration(
                                        color: _tertiaryContainer,
                                        borderRadius: _asymmetricRadius,
                                        border: Border.all(color: _onSurface, width: 2),
                                        boxShadow: const [BoxShadow(color: _onSurface, offset: Offset(2, 2))],
                                      ),
                                      child: Text(
                                        'KELOLA MATERI',
                                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: _onTertiaryContainer, letterSpacing: 1.2),
                                      ),
                                    ),
                                    Text(
                                      'Materi Pembelajaran',
                                      style: GoogleFonts.plusJakartaSans(fontSize: 28, fontWeight: FontWeight.w800, color: _onSurface, height: 1.2),
                                    ),
                                    const SizedBox(height: 24),
                                    GestureDetector(
                                      onTap: () => _showMateriForm(),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                                        decoration: BoxDecoration(
                                          color: _primary,
                                          borderRadius: _asymmetricRadius,
                                          border: Border.all(color: _onSurface, width: 2),
                                          boxShadow: const [
                                            BoxShadow(color: _onSurface, offset: Offset(3, 3)),
                                          ],
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.add, color: Colors.white, size: 20),
                                            const SizedBox(width: 8),
                                            Text(
                                              'BUAT MATERI BARU',
                                              style: GoogleFonts.plusJakartaSans(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ).animate().fadeIn().slideY(begin: 0.1),
                                  ],
                                ),
                              ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.1);
                            }

                            final m = filteredMateri[i - 1];
                            final colorsList = [
                              {'bg': _secondaryContainer, 'text': _onSecondaryContainer},
                              {'bg': _tertiaryContainer, 'text': _onTertiaryContainer},
                              {'bg': _primaryFixed, 'text': _onPrimaryFixed},
                              {'bg': _surfaceContainerHighest, 'text': _onSurface},
                            ];
                            final colorPair = colorsList[(i - 1) % colorsList.length];

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 24),
                              child: _MateriCardNeo(
                                materi: m,
                                profileBgColor: colorPair['bg'] as Color,
                                profileTextColor: colorPair['text'] as Color,
                                onEdit: () => _showMateriForm(m),
                                onDelete: () => _deleteMateri(m['id'].toString()),
                              )
                                  .animate(delay: ((i - 1) * 50).ms)
                                  .fadeIn(duration: 400.ms)
                                  .slideY(begin: 0.1, curve: Curves.easeOutQuart),
                            );
                          },
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _MateriCardNeo extends StatefulWidget {
  final dynamic materi;
  final Color profileBgColor;
  final Color profileTextColor;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _MateriCardNeo({
    required this.materi,
    required this.profileBgColor,
    required this.profileTextColor,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_MateriCardNeo> createState() => _MateriCardNeoState();
}

class _MateriCardNeoState extends State<_MateriCardNeo> {
  bool _isHovering = false;

  String _formatUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('http://')) {
      return url.replaceFirst('http://', 'https://');
    } else if (!url.startsWith('https://')) {
      return 'https://$url';
    }
    return url;
  }

  void _showDetail(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: _onSurface.withValues(alpha: 0.2),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 512),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: _surfaceContainerLowest,
            borderRadius: _asymmetricRadius,
            border: Border.all(color: _onSurface, width: 2),
            boxShadow: const [BoxShadow(color: _onSurface, offset: Offset(4, 4), blurRadius: 0)],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: _secondaryContainer,
                          borderRadius: _asymmetricRadius,
                          border: Border.all(color: _onSurface, width: 2),
                          boxShadow: const [BoxShadow(color: _onSurface, offset: Offset(2, 2))],
                        ),
                        child: Text(
                          'DETAIL MATERI',
                          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: _onSecondaryContainer, letterSpacing: 1.2),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.materi['judul'] ?? '-',
                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 32, color: _onSurface, height: 1.2, letterSpacing: -0.5),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (widget.materi['deskripsi'] != null && widget.materi['deskripsi'].toString().isNotEmpty) ...[
                            Text(
                              'DESKRIPSI LENGKAP',
                              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: _primary, letterSpacing: 0.5),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              widget.materi['deskripsi'],
                              style: GoogleFonts.inter(height: 1.6, fontWeight: FontWeight.w400, fontSize: 16, color: _onSurfaceVariant),
                            ),
                            const SizedBox(height: 16),
                          ],
                          
                          if (widget.materi['file_url'] != null && widget.materi['file_url'].toString().isNotEmpty) ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.only(top: 16),
                              decoration: const BoxDecoration(
                                border: Border(top: BorderSide(color: _outlineVariant)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'LINK MATERI',
                                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: _primary, letterSpacing: 0.5),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Link(
                                        uri: Uri.parse(_formatUrl(widget.materi['file_url'])),
                                        target: LinkTarget.blank,
                                        builder: (context, followLink) => _NeoModalButton(
                                          label: 'Buka',
                                          icon: Icons.open_in_new,
                                          onTap: followLink,
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
                  ),
                ],
              ),
              
              Positioned(
                top: -16,
                right: -16,
                child: IconButton(
                  icon: const Icon(Icons.close, color: _onSurface, size: 28),
                  onPressed: () => Navigator.pop(ctx),
                  splashRadius: 24,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getInitials(String name) {
    List<String> names = name.trim().split(' ');
    if (names.isEmpty) return '??';
    if (names.length == 1) return names[0].substring(0, names[0].length >= 2 ? 2 : 1).toUpperCase();
    return '${names[0][0]}${names[names.length - 1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final guruNama = widget.materi['guru_nama'] ?? 'Guru Tidak Diketahui';
    final initials = _getInitials(guruNama);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        onTap: () => _showDetail(context),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          transform: Matrix4.translationValues(
            _isHovering ? -2 : 0,
            _isHovering ? -2 : 0,
            0,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: _asymmetricRadius,
            border: Border.all(color: _onSurface, width: 2),
            boxShadow: [
              BoxShadow(
                color: _onSurface,
                offset: _isHovering ? const Offset(6, 6) : const Offset(4, 4),
              )
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        widget.materi['judul'] ?? '-',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                          fontSize: 20,
                          color: _onSurface,
                          height: 1.2,
                        ),
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: _onSurfaceVariant, size: 24),
                      onSelected: (val) {
                        if (val == 'edit') widget.onEdit();
                        if (val == 'delete') widget.onDelete();
                      },
                      itemBuilder: (ctx) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Text('Edit Materi', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('Hapus', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if ((widget.materi['deskripsi'] ?? '').isNotEmpty)
                  Text(
                    widget.materi['deskripsi'],
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: _onSurfaceVariant,
                      height: 1.5,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.only(top: 16),
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: _outlineVariant)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: widget.profileBgColor,
                                shape: BoxShape.circle,
                                border: Border.all(color: _onSurface, width: 1.5),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                initials,
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                  color: widget.profileTextColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Guru: $guruNama',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: _onSurface,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: _primaryContainer,
                          border: Border.all(color: _onSurface, width: 2),
                          boxShadow: const [BoxShadow(color: _onSurface, offset: Offset(2, 2))],
                        ),
                        child: Text(
                          'Lihat Detail',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _onPrimaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NeoModalButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  const _NeoModalButton({required this.label, required this.icon, this.onTap});

  @override
  State<_NeoModalButton> createState() => _NeoModalButtonState();
}

class _NeoModalButtonState extends State<_NeoModalButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        transform: Matrix4.translationValues(
          _isPressed ? 2 : 0,
          _isPressed ? 2 : 0,
          0,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: _primaryContainer,
          border: Border.all(color: _onSurface, width: 2),
          boxShadow: _isPressed ? [] : const [BoxShadow(color: _onSurface, offset: Offset(2, 2))],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(widget.icon, color: _onSurface, size: 20),
            const SizedBox(width: 8),
            Text(
              widget.label,
              style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 12, color: _onPrimaryContainer),
            ),
          ],
        ),
      ),
    );
  }
}
