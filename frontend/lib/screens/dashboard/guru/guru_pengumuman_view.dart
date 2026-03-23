import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../widgets/confirm_delete.dart';
import '../../../widgets/app_shell.dart';
import '../../../config/api_config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../services/notifikasi_service.dart';

class GuruPengumumanView extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String token;
  const GuruPengumumanView({super.key, required this.userData, required this.token});

  @override
  State<GuruPengumumanView> createState() => _GuruPengumumanViewState();
}

class _GuruPengumumanViewState extends State<GuruPengumumanView> {
  List<dynamic> _pengumumanList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPengumuman();
  }

  Future<void> _fetchPengumuman() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/pengumuman'), headers: {'Authorization': 'Bearer ${widget.token}'});
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        setState(() => _pengumumanList = decoded is List ? decoded : []);
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _deletePengumuman(String id) async {
    if (await confirmDelete(context, pesan: 'Hapus pengumuman ini?')) {
      try {
        await http.delete(Uri.parse('$baseUrl/api/pengumuman/$id'), headers: {'Authorization': 'Bearer ${widget.token}'});
        _fetchPengumuman();
      } catch (e) {
        debugPrint('Error: $e');
      }
    }
  }

  void _showPengumumanForm([Map<String, dynamic>? pengumuman]) {
    final isEditing = pengumuman != null;
    final judulCtrl = TextEditingController(text: isEditing ? pengumuman['judul'] : '');
    final isiCtrl = TextEditingController(text: isEditing ? pengumuman['isi'] : '');
    final now = DateTime.now();
    final tanggalStr = '${now.day} ${['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'][now.month - 1]} ${now.year}';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(isEditing ? 'Edit Pengumuman' : 'Buat Pengumuman Baru', style: const TextStyle(fontWeight: FontWeight.w900)),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                AntigravityTextField(controller: judulCtrl, labelText: 'Judul Pengumuman', prefixIcon: Icons.campaign_rounded),
                const SizedBox(height: 16),
                AntigravityTextField(controller: isiCtrl, labelText: 'Isi Pengumuman', prefixIcon: Icons.description_outlined, keyboardType: TextInputType.multiline),
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
              if (judulCtrl.text.isEmpty || isiCtrl.text.isEmpty) return;
              final body = {
                'judul': judulCtrl.text,
                'isi': isiCtrl.text,
                'tanggal': isEditing ? (pengumuman['tanggal'] ?? tanggalStr) : tanggalStr,
                'guru_id': widget.userData['id'],
                'author': widget.userData['nama'],
              };
              final headers = {'Content-Type': 'application/json', 'Authorization': 'Bearer ${widget.token}'};
              try {
                if (isEditing) {
                  await http.put(Uri.parse('$baseUrl/api/pengumuman/${pengumuman['id']}'), headers: headers, body: jsonEncode(body));
                } else {
                  await http.post(Uri.parse('$baseUrl/api/pengumuman'), headers: headers, body: jsonEncode(body));
                  NotifikasiService.kirimNotifikasi(judul: 'Pengumuman: ${judulCtrl.text}', pesan: isiCtrl.text, token: widget.token, targetRole: 'Siswa');
                }
                if (ctx.mounted) Navigator.pop(ctx);
                _fetchPengumuman();
              } catch (e) {
                debugPrint('Error saving: $e');
              }
            },
            child: Text(isEditing ? 'Simpan' : 'Terbitkan', style: const TextStyle(fontWeight: FontWeight.w800)),
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
          onPressed: () => _showPengumumanForm(),
          icon: Icons.campaign_rounded,
          label: 'Buat Baru',
        ),
        body: _pengumumanList.isEmpty
            ? const EmptyState(icon: Icons.campaign_rounded, message: 'Belum ada pengumuman masuk.', color: Color(0xFFF59E0B))
            : RefreshIndicator(
                onRefresh: _fetchPengumuman,
                child: LayoutBuilder(
                  builder: (ctx, c) {
                    final w = c.maxWidth;
                    final padding = Breakpoints.screenPadding(w);

                    return ListView.builder(
                      padding: padding,
                      itemCount: _pengumumanList.length,
                      itemBuilder: (context, index) {
                        final p = _pengumumanList[index];
                        return _GuruPengumumanCard(
                          pengumuman: p,
                          onEdit: () => _showPengumumanForm(p),
                          onDelete: () => _deletePengumuman(p['id'].toString()),
                        ).animate(delay: (index * 60).ms).fadeIn(duration: 400.ms).slideY(begin: 0.1, curve: Curves.easeOutQuart);
                      },
                    );
                  },
                ),
              ),
      ),
    );
  }

  Widget _buildSkeleton() {
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: 5,
      itemBuilder: (_, __) => const Padding(
        padding: EdgeInsets.only(bottom: 16),
        child: SkeletonLoader(height: 120, radius: 24),
      ),
    );
  }
}

class _GuruPengumumanCard extends StatelessWidget {
  final Map<String, dynamic> pengumuman;
  final VoidCallback onEdit, onDelete;
  const _GuruPengumumanCard({required this.pengumuman, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    const Color accent = Color(0xFFF59E0B);
    final theme = Theme.of(context);

    return PremiumCard(
      accentColor: accent,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: accent.withAlpha(20), borderRadius: BorderRadius.circular(16)),
            child: const Icon(Icons.campaign_rounded, color: accent, size: 24),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(pengumuman['judul'] ?? '-', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: -0.5), maxLines: 1, overflow: TextOverflow.ellipsis)),
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
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
                if (pengumuman['tanggal'] != null)
                  Text(pengumuman['tanggal'], style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: theme.colorScheme.onSurface.withAlpha(120))),
                const SizedBox(height: 12),
                Text(pengumuman['isi'] ?? '-', style: TextStyle(fontSize: 14, height: 1.6, color: theme.colorScheme.onSurface.withAlpha(180))),
                if (pengumuman['author'] != null) ...[
                  const SizedBox(height: 16),
                  Text('Oleh: ${pengumuman['author']}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: theme.colorScheme.onSurface.withAlpha(150))),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
