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
  String _searchQuery = '';

  String _formatDate(dynamic dateString) {
    if (dateString == null) return '';
    try {
      final date = DateTime.parse(dateString.toString());
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (e) {
      return dateString.toString().split('T')[0];
    }
  }

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

  Future<void> _openFile(String? url) async {
    if (url == null || url.isEmpty) return;
    if (url.startsWith('http://')) {
      url = url.replaceFirst('http://', 'https://');
    } else if (!url.startsWith('https://')) {
      url = 'https://$url';
    }
    final uri = Uri.parse(url);
    try {
      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
        webOnlyWindowName: '_blank',
      );
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
    final isDark = theme.brightness == Brightness.dark;
    final onSurface = isDark ? Colors.white : const Color(0xFF001E2B);
    final onSurfaceVariant = isDark ? Colors.white70 : const Color(0xFF414944);
    final outline = isDark ? Colors.white38 : const Color(0xFF717974);
    final surfaceContainerLow = isDark ? const Color(0xFF161B27) : const Color(0xFFE8F6FF);

    final cardColors = [
      const Color(0xFF3D6754),
      const Color(0xFF336763),
      const Color(0xFF8D4D33),
    ];
    final cardBgColors = [
      isDark ? const Color(0xFF161B27) : const Color(0xFFE8F6FF),
      isDark ? const Color(0xFF161B27) : const Color(0xFFDBF1FF),
      isDark ? const Color(0xFF161B27) : const Color(0xFFCEEDFF),
    ];

    List<dynamic> filteredMateri = _materiList.where((m) {
      final judul = (m['judul'] ?? '').toString().toLowerCase();
      final deskripsi = (m['deskripsi'] ?? '').toString().toLowerCase();
      final query = _searchQuery.toLowerCase();
      return judul.contains(query) || deskripsi.contains(query);
    }).toList();

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Header
                Text(
                  'Kelola Materi\nAnda',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 40,
                    height: 1.1,
                    letterSpacing: -1.5,
                    fontWeight: FontWeight.w800,
                    color: onSurface,
                  ),
                ).animate().fadeIn().slideX(begin: -0.1),
                const SizedBox(height: 24),
                
                // Button Buat Materi Baru
                GestureDetector(
                  onTap: () => _showMateriForm(),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3D6754),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: onSurface, width: 2),
                      boxShadow: [
                        BoxShadow(color: onSurface, offset: const Offset(4, 4)),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.add, color: Colors.white),
                        const SizedBox(width: 8),
                        Text(
                          'Buat Materi Baru',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ).animate().fadeIn().slideY(begin: 0.1),
                const SizedBox(height: 24),

                // Search Box
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: onSurface, width: 2),
                    boxShadow: [
                      BoxShadow(color: onSurface, offset: const Offset(4, 4)),
                    ],
                  ),
                  child: TextField(
                    onChanged: (val) => setState(() => _searchQuery = val),
                    style: GoogleFonts.inter(color: onSurface),
                    decoration: InputDecoration(
                      hintText: 'Cari materi berdasarkan judul...',
                      hintStyle: GoogleFonts.inter(color: outline),
                      prefixIcon: Icon(Icons.search, color: outline),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                  ),
                ).animate().fadeIn(delay: 100.ms),
                const SizedBox(height: 16),
              ]),
            ),
          ),

          // List of Materi
          if (_materiList.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index >= filteredMateri.length) return const SizedBox.shrink();
                    final m = filteredMateri[index];
                    final colorAccent = cardColors[index % cardColors.length];
                    final bgColor = cardBgColors[index % cardBgColors.length];
                    
                    return GestureDetector(
                      onTap: () => _showMateriDetail(m),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: onSurface, width: 2),
                          boxShadow: [
                            BoxShadow(color: onSurface, offset: const Offset(4, 4)),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(22),
                          child: Stack(
                            children: [
                              Positioned(
                                top: 0, bottom: 0, left: 0,
                                child: Container(width: 8, color: colorAccent),
                              ),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(24, 20, 16, 20),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: colorAccent,
                                                  borderRadius: BorderRadius.circular(100),
                                                  border: Border.all(color: onSurface, width: 1),
                                                ),
                                                child: Text(
                                                  'MATERI',
                                                  style: GoogleFonts.inter(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w700,
                                                    color: Colors.white,
                                                    letterSpacing: 0.5,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFFFD1C0),
                                                  borderRadius: BorderRadius.circular(100),
                                                  border: Border.all(color: onSurface, width: 1),
                                                ),
                                                child: Text(
                                                  m['kelas']?.toString().toUpperCase() ?? 'KELAS',
                                                  style: GoogleFonts.inter(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w700,
                                                    color: const Color(0xFF8E4F34),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                          Text(
                                            m['judul'] ?? '-',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 20,
                                              fontWeight: FontWeight.w700,
                                              color: onSurface,
                                              letterSpacing: -0.5,
                                            ),
                                          ),
                                          if (m['deskripsi'] != null && m['deskripsi'].toString().isNotEmpty) ...[
                                            const SizedBox(height: 6),
                                            Text(
                                              m['deskripsi'],
                                              style: GoogleFonts.inter(
                                                fontSize: 14,
                                                color: onSurfaceVariant,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              Icon(Icons.calendar_today_outlined, size: 14, color: onSurfaceVariant),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  'Ditambahkan pada ${_formatDate(m['created_at'])}',
                                                  style: GoogleFonts.inter(
                                                    fontSize: 14,
                                                    color: onSurfaceVariant,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    
                                    PopupMenuButton<String>(
                                      icon: Icon(Icons.more_vert, color: onSurfaceVariant),
                                      onSelected: (value) {
                                        if (value == 'open') _openFile(m['file_url']);
                                        if (value == 'edit') _showMateriForm(m);
                                        if (value == 'delete') _deleteMateri(m['id'].toString());
                                      },
                                      itemBuilder: (context) => [
                                        if (m['file_url'] != null && m['file_url'].toString().isNotEmpty)
                                          const PopupMenuItem(value: 'open', child: Text('Buka File')),
                                        const PopupMenuItem(value: 'edit', child: Text('Edit')),
                                        const PopupMenuItem(value: 'delete', child: Text('Hapus', style: TextStyle(color: Colors.red))),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ).animate(delay: (index * 50).ms).fadeIn().slideY(begin: 0.1, curve: Curves.easeOutQuart);
                  },
                  childCount: filteredMateri.length,
                ),
              ),
            ),

          // Add More Prompt (Empty state or bottom banner)
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            sliver: SliverToBoxAdapter(
              child: GestureDetector(
                onTap: () => _showMateriForm(),
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: surfaceContainerLow,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: onSurfaceVariant.withValues(alpha: 0.3), width: 2),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: onSurface, width: 2),
                          boxShadow: [
                            BoxShadow(color: onSurface, offset: const Offset(3, 3)),
                          ],
                        ),
                        child: Icon(Icons.library_add_outlined, color: onSurface, size: 28),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Butuh materi tambahan?',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Buat materi baru dan bagikan\nke ruang kelas Anda.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: 300.ms),
            ),
          ),
          
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }
}
