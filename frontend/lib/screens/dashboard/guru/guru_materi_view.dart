import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../widgets/confirm_delete.dart';
import '../../../config/api_config.dart';
import '../../../widgets/app_shell.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../services/notifikasi_service.dart';
import 'package:url_launcher/url_launcher.dart';

class GuruMateriView extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String token;
  final dynamic teamData; // TAMBAHAN: Menerima konteks kelas saat ini

  const GuruMateriView({
    super.key, 
    required this.userData, 
    required this.token,
    required this.teamData, // Wajib diisi
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
      // UBAHAN: Fetch hanya materi yang memiliki kelas_id sesuai dengan tim ini
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
      debugPrint('Error: $e');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _deleteMateri(String id) async {
    if (await confirmDelete(context, pesan: 'Yakin hapus materi ini?')) {
      try {
        await http.delete(Uri.parse('$baseUrl/api/materi/$id'), headers: {'Authorization': 'Bearer ${widget.token}'});
        _fetchMateri();
      } catch (e) {
        debugPrint('Error: $e');
      }
    }
  }

  void _showMateriForm([Map<String, dynamic>? materi]) {
    final isEditing = materi != null;
    final judulCtrl = TextEditingController(text: isEditing ? materi['judul'] : '');
    final deskripsiCtrl = TextEditingController(text: isEditing ? (materi['deskripsi'] ?? '') : '');
    final linkCtrl = TextEditingController(text: isEditing ? (materi['file_url'] ?? materi['link'] ?? '') : '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(isEditing ? 'Edit Materi' : 'Tambah Materi Baru', style: const TextStyle(fontWeight: FontWeight.w900)),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                // Info Kelas Otomatis
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: const Color(0xFF10B981).withAlpha(20), borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      const Icon(Icons.class_, color: Color(0xFF10B981), size: 20),
                      const SizedBox(width: 8),
                      Expanded(child: Text('Materi ini akan dibagikan ke kelas: ${widget.teamData['nama_kelas']}', style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 12))),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                AntigravityTextField(controller: judulCtrl, labelText: 'Judul Materi *', prefixIcon: Icons.title_rounded),
                const SizedBox(height: 16),
                AntigravityTextField(controller: deskripsiCtrl, labelText: 'Deskripsi / Isi Materi', prefixIcon: Icons.description_outlined, keyboardType: TextInputType.multiline),
                const SizedBox(height: 16),
                AntigravityTextField(controller: linkCtrl, labelText: 'Link Materi (Drive/YouTube)', prefixIcon: Icons.link_rounded),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: () async {
              if (judulCtrl.text.isEmpty) return;
              
              // UBAHAN: Sisipkan ID dan Nama Kelas secara otomatis
              final body = {
                'judul': judulCtrl.text,
                'mapel': widget.teamData['mapel'] ?? widget.userData['kelas'] ?? '-',
                'kelas': widget.teamData['nama_kelas'],
                'kelas_id': widget.teamData['id'],
                'deskripsi': deskripsiCtrl.text,
                'file_url': linkCtrl.text,
                'guru_id': widget.userData['id'],
              };

              final url = isEditing ? '$baseUrl/api/materi/${materi['id']}' : '$baseUrl/api/materi';
              final response = await (isEditing
                  ? http.put(Uri.parse(url), headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer ${widget.token}'}, body: jsonEncode(body))
                  : http.post(Uri.parse(url), headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer ${widget.token}'}, body: jsonEncode(body)));

              if (response.statusCode == 200 || response.statusCode == 201) {
                if (!isEditing) {
                  NotifikasiService.kirimNotifikasi(
                    judul: 'Materi Baru',
                    pesan: 'Materi baru: ${judulCtrl.text} diunggah di kelas ${widget.teamData['nama_kelas']}',
                    token: widget.token,
                    targetKelas: widget.teamData['nama_kelas'],
                    targetRole: 'Siswa',
                  );
                }
                if (ctx.mounted) Navigator.pop(ctx);
                _fetchMateri();
              }
            },
            child: Text(isEditing ? 'Simpan' : 'Tambah', style: const TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return AppShell(child: _buildSkeleton());
    }

    return AppShell(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        floatingActionButton: AntigravityFAB(
          onPressed: () => _showMateriForm(),
          icon: Icons.add_rounded,
          label: 'Materi Baru',
        ),
        body: _materiList.isEmpty
            ? const EmptyState(icon: Icons.library_books_rounded, message: 'Belum ada materi\ndi kelas ini.', color: Color(0xFF10B981))
            : RefreshIndicator(
                onRefresh: _fetchMateri,
                child: LayoutBuilder(
                  builder: (ctx, c) {
                    final w = c.maxWidth;
                    final padding = Breakpoints.screenPadding(w);
                    final crossCount = w >= Breakpoints.tablet ? 3 : (w >= Breakpoints.mobile ? 2 : 1);

                    return RepaintBoundary(
                      child: GridView.builder(
                        padding: padding,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossCount,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: crossCount == 1 ? 2.8 : 1.3,
                        ),
                        itemCount: _materiList.length,
                        itemBuilder: (_, i) {
                          final m = _materiList[i];
                          return _GuruMateriCard(
                            materi: m,
                            onEdit: () => _showMateriForm(m),
                            onDelete: () => _deleteMateri(m['id'].toString()),
                            onView: () => _launchURL(m['file_url'] ?? m['link']),
                          ).animate(delay: (i * 40).ms).fadeIn(duration: 400.ms).slideY(begin: 0.1, curve: Curves.easeOutQuart);
                        },
                      ),
                    );
                  },
                ),
              ),
      ),
    );
  }

  Widget _buildSkeleton() {
    return GridView.count(
      padding: const EdgeInsets.all(24),
      crossAxisCount: 2,
      childAspectRatio: 1.3,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: List.generate(6, (_) => const SkeletonLoader(radius: 24)),
    );
  }

  Future<void> _launchURL(String? url) async {
    if (url == null || url.isEmpty) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }
}

class _GuruMateriCard extends StatelessWidget {
  final dynamic materi;
  final VoidCallback onEdit, onDelete, onView;

  const _GuruMateriCard({required this.materi, required this.onEdit, required this.onDelete, required this.onView});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const accent = Color(0xFF10B981);

    return PremiumCard(
      accentColor: accent,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: accent.withAlpha(20), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.description_outlined, color: accent, size: 20)),
              const SizedBox(width: 12),
              Expanded(child: Text(materi['mapel'] ?? '-', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis)),
              IconButton(
                onPressed: () {
                  final renderBox = context.findRenderObject() as RenderBox;
                  final offset = renderBox.localToGlobal(Offset.zero);
                  showMenu(
                    context: context,
                    position: RelativeRect.fromLTRB(offset.dx + renderBox.size.width - 40, offset.dy, offset.dx + renderBox.size.width, offset.dy + 40),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    items: [
                      PopupMenuItem(onTap: onEdit, child: const Row(children: [Icon(Icons.edit_outlined, size: 20), SizedBox(width: 12), Text('Edit')])),
                      PopupMenuItem(onTap: onDelete, child: const Row(children: [Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20), SizedBox(width: 12), Text('Hapus', style: TextStyle(color: Colors.red))])),
                    ],
                  );
                },
                icon: Icon(Icons.more_vert_rounded, size: 20, color: theme.colorScheme.onSurface.withAlpha(100)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(materi['judul'] ?? '-', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: -0.3), maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Text('Kelas: ${materi['kelas'] ?? '-'}', style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withAlpha(150))),
            ]),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onView,
              style: OutlinedButton.styleFrom(
                foregroundColor: accent,
                side: BorderSide(color: accent.withAlpha(80)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.open_in_new_rounded, size: 16),
              label: const Text('Buka', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }
}