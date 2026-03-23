import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../widgets/confirm_delete.dart';
import '../../../widgets/app_shell.dart';
import '../../../config/api_config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'guru_tugas_detail_screen.dart';
import '../../../services/notifikasi_service.dart';

class GuruTugasView extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String token;
  const GuruTugasView({super.key, required this.userData, required this.token});

  @override
  State<GuruTugasView> createState() => _GuruTugasViewState();
}

class _GuruTugasViewState extends State<GuruTugasView> {
  List<dynamic> _tugasList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTugas();
  }

  Future<void> _fetchTugas() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/tugas'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      if (response.statusCode == 200) {
        final dec = jsonDecode(response.body);
        List data = dec is List ? dec : [];
        setState(() {
          _tugasList = data.where((t) => t['guru_id'].toString() == widget.userData['id'].toString()).toList();
        });
      }
    } catch (e) {
      debugPrint("Error: $e");
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _deleteTugas(String id) async {
    if (await confirmDelete(context, pesan: 'Yakin ingin hapus tugas ini?')) {
      try {
        await http.delete(
          Uri.parse('$baseUrl/api/tugas/$id'),
          headers: {'Authorization': 'Bearer ${widget.token}'},
        );
        _fetchTugas();
      } catch (e) {
        debugPrint("Error: $e");
      }
    }
  }

  void _showTugasForm([Map<String, dynamic>? tugas]) {
    final isEditing = tugas != null;
    final judulCtrl = TextEditingController(text: isEditing ? tugas['judul'] : '');
    final deskripsiCtrl = TextEditingController(text: isEditing ? (tugas['deskripsi'] ?? '') : '');
    final deadlineCtrl = TextEditingController(text: isEditing ? (tugas['deadline'] ?? '') : '');
    final linkCtrl = TextEditingController(text: isEditing ? (tugas['link'] ?? '') : '');
    final kelasCtrl = TextEditingController(text: isEditing ? (tugas['kelas'] ?? '') : (widget.userData['kelas'] ?? ''));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(isEditing ? 'Edit Tugas' : 'Buat Tugas Baru', style: const TextStyle(fontWeight: FontWeight.w900)),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                AntigravityTextField(controller: judulCtrl, labelText: 'Judul Tugas', prefixIcon: Icons.title_rounded),
                const SizedBox(height: 16),
                AntigravityTextField(controller: deskripsiCtrl, labelText: 'Deskripsi Detail', prefixIcon: Icons.description_outlined, keyboardType: TextInputType.multiline),
                const SizedBox(height: 16),
                AntigravityTextField(controller: deadlineCtrl, labelText: 'Deadline (Contoh: 24 Mar 2026)', prefixIcon: Icons.calendar_today_rounded),
                const SizedBox(height: 16),
                AntigravityTextField(controller: linkCtrl, labelText: 'Link Pendukung (Opsional)', prefixIcon: Icons.link_rounded),
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
              final body = {
                'judul': judulCtrl.text,
                'deskripsi': deskripsiCtrl.text,
                'deadline': deadlineCtrl.text,
                'link': linkCtrl.text,
                'mapel': widget.userData['kelas'] ?? '-',
                'kelas': kelasCtrl.text,
                'guru_id': widget.userData['id'],
              };

              final url = isEditing ? '$baseUrl/api/tugas/${tugas['id']}' : '$baseUrl/api/tugas';
              final response = await (isEditing
                  ? http.put(Uri.parse(url), headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer ${widget.token}'}, body: jsonEncode(body))
                  : http.post(Uri.parse(url), headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer ${widget.token}'}, body: jsonEncode(body)));

              if (response.statusCode == 200 || response.statusCode == 201) {
                if (!isEditing) {
                  NotifikasiService.kirimNotifikasi(
                    judul: 'Tugas Baru', 
                    pesan: 'Guru ${widget.userData['nama']} membuat tugas: ${judulCtrl.text}',
                    token: widget.token,
                    targetKelas: kelasCtrl.text,
                    targetRole: 'Siswa',
                  );
                }
                if (ctx.mounted) Navigator.pop(ctx);
                _fetchTugas();
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
          onPressed: () => _showTugasForm(),
          icon: Icons.add_task_rounded,
          label: 'Buat Tugas',
        ),
        body: _tugasList.isEmpty
            ? const EmptyState(icon: Icons.assignment_outlined, message: 'Belum ada tugas yang kamu buat.', color: Color(0xFF3B82F6))
            : RefreshIndicator(
                onRefresh: _fetchTugas,
                child: LayoutBuilder(
                  builder: (ctx, c) {
                    final w = c.maxWidth;
                    final padding = Breakpoints.screenPadding(w);
                    final crossCount = w >= Breakpoints.tablet ? 2 : 1;

                    return RepaintBoundary(
                      child: GridView.builder(
                        padding: padding,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossCount,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: crossCount == 1 ? 3.5 : 2.2,
                        ),
                        itemCount: _tugasList.length,
                        itemBuilder: (_, i) {
                          final t = _tugasList[i];
                          return _GuruTugasCard(
                            tugas: t,
                            onEdit: () => _showTugasForm(t),
                            onDelete: () => _deleteTugas(t['id'].toString()),
                            onDetail: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => GuruTugasDetailScreen(tugas: t, token: widget.token),
                              ),
                            ),
                          ).animate(delay: (i * 50).ms).fadeIn(duration: 400.ms).slideY(begin: 0.1, curve: Curves.easeOutQuart);
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
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: 5,
      itemBuilder: (_, __) => const Padding(
        padding: EdgeInsets.only(bottom: 12),
        child: SkeletonLoader(height: 90, radius: 24),
      ),
    );
  }
}

class _GuruTugasCard extends StatelessWidget {
  final dynamic tugas;
  final VoidCallback onEdit, onDelete, onDetail;

  const _GuruTugasCard({required this.tugas, required this.onEdit, required this.onDelete, required this.onDetail});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const accent = Color(0xFF3B82F6);

    return PremiumCard(
      accentColor: accent,
      padding: const EdgeInsets.all(20),
      onTap: onDetail,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: accent.withAlpha(20), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.assignment_rounded, color: accent, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tugas['judul'] ?? '-', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text('Kelas: ${tugas['kelas'] ?? '-'}', style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withAlpha(150))),
                  ],
                ),
              ),
              PopupMenuButton(
                onSelected: (val) {
                  if (val == 'edit') onEdit();
                  if (val == 'delete') onDelete();
                },
                icon: Icon(Icons.more_vert_rounded, color: theme.colorScheme.onSurface.withAlpha(100)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_outlined, size: 20), SizedBox(width: 12), Text('Edit')])),
                  const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20), SizedBox(width: 12), Text('Hapus', style: TextStyle(color: Colors.red))])),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (tugas['deadline'] != null)
                Row(
                  children: [
                    Icon(Icons.timer_outlined, size: 14, color: const Color(0xFFF59E0B).withAlpha(180)),
                    const SizedBox(width: 6),
                    Text(tugas['deadline'], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFFF59E0B))),
                  ],
                ),
              Text('Detail >', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: accent.withAlpha(200))),
            ],
          ),
        ],
      ),
    );
  }
}