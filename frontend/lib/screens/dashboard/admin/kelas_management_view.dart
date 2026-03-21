import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../widgets/confirm_delete.dart';
import '../../../config/api_config.dart';
import '../../../widgets/app_shell.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class KelasManagementView extends StatefulWidget {
  final String token;
  const KelasManagementView({super.key, required this.token});

  @override
  State<KelasManagementView> createState() => _KelasManagementViewState();
}

class _KelasManagementViewState extends State<KelasManagementView> {
  List<dynamic> _kelasList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchKelas();
  }

  Future<void> _fetchKelas() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/kelas'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      if (response.statusCode == 200) {
        final dec = jsonDecode(response.body);
        setState(() => _kelasList = dec is List ? dec : []);
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _deleteKelas(String id) async {
    if (await confirmDelete(context, pesan: 'Yakin ingin menghapus kelas ini?')) {
      try {
        await http.delete(
          Uri.parse('$baseUrl/api/kelas/$id'),
          headers: {'Authorization': 'Bearer ${widget.token}'},
        );
        _fetchKelas();
      } catch (e) {
        debugPrint('Error: $e');
      }
    }
  }

  void _showKelasForm([Map<String, dynamic>? kelas]) {
    final isEditing = kelas != null;
    final namaCtrl = TextEditingController(text: isEditing ? kelas['nama_kelas'] : '');
    final waliCtrl = TextEditingController(text: isEditing ? kelas['wali_kelas'] : '');
    final jurusanCtrl = TextEditingController(text: isEditing ? kelas['jurusan'] : '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(isEditing ? 'Edit Kelas' : 'Tambah Kelas Baru', style: const TextStyle(fontWeight: FontWeight.w900)),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                AntigravityTextField(controller: namaCtrl, labelText: 'Nama Kelas (cth: XII IPA 1)', prefixIcon: Icons.class_outlined),
                const SizedBox(height: 16),
                AntigravityTextField(controller: waliCtrl, labelText: 'Wali Kelas', prefixIcon: Icons.person_outline_rounded),
                const SizedBox(height: 16),
                AntigravityTextField(controller: jurusanCtrl, labelText: 'Jurusan (cth: IPA)', prefixIcon: Icons.history_edu_rounded),
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
              if (namaCtrl.text.isEmpty) return;
              final body = {
                'nama_kelas': namaCtrl.text,
                'wali_kelas': waliCtrl.text,
                'jurusan': jurusanCtrl.text,
              };
              final headers = {'Content-Type': 'application/json', 'Authorization': 'Bearer ${widget.token}'};
              try {
                if (isEditing) {
                  await http.put(Uri.parse('$baseUrl/api/kelas/${kelas['id']}'), headers: headers, body: jsonEncode(body));
                } else {
                  await http.post(Uri.parse('$baseUrl/api/kelas'), headers: headers, body: jsonEncode(body));
                }
                if (ctx.mounted) Navigator.pop(ctx);
                _fetchKelas();
              } catch (e) {
                debugPrint('Error saving: $e');
              }
            },
            child: const Text('Simpan Kelas', style: TextStyle(fontWeight: FontWeight.w800)),
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
          onPressed: () => _showKelasForm(),
          icon: Icons.add_business_rounded,
          label: 'Tambah Kelas',
        ),
        body: _kelasList.isEmpty
            ? const EmptyState(icon: Icons.class_outlined, message: 'Belum ada data kelas.', color: Colors.blue)
            : RefreshIndicator(
                onRefresh: _fetchKelas,
                child: LayoutBuilder(
                  builder: (ctx, c) {
                    final w = c.maxWidth;
                    final padding = Breakpoints.screenPadding(w);
                    final crossCount = w >= Breakpoints.tablet ? 3 : (w >= Breakpoints.mobile ? 2 : 1);

                    return GridView.builder(
                      padding: padding,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossCount,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: crossCount == 1 ? 3.5 : 1.4,
                      ),
                      itemCount: _kelasList.length,
                      itemBuilder: (context, index) {
                        final k = _kelasList[index];
                        return _KelasCard(
                          kelas: k,
                          onEdit: () => _showKelasForm(k),
                          onDelete: () => _deleteKelas(k['id'].toString()),
                        ).animate(delay: (index * 40).ms).fadeIn(duration: 400.ms).slideY(begin: 0.1, curve: Curves.easeOutQuart);
                      },
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
      childAspectRatio: 1.4,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: List.generate(6, (_) => const SkeletonLoader(radius: 24)),
    );
  }
}

class _KelasCard extends StatelessWidget {
  final dynamic kelas;
  final VoidCallback onEdit, onDelete;

  const _KelasCard({required this.kelas, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const accent = Color(0xFF3B82F6);

    return PremiumCard(
      accentColor: accent,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: accent.withAlpha(20), shape: BoxShape.circle),
                child: const Icon(Icons.class_rounded, color: accent, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(kelas['nama_kelas'] ?? '-', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(kelas['jurusan'] ?? '-', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: accent, letterSpacing: 1)),
                  ],
                ),
              ),
              PopupMenuButton(
                icon: Icon(Icons.more_vert_rounded, size: 20, color: theme.colorScheme.onSurface.withAlpha(100)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                itemBuilder: (_) => [
                  PopupMenuItem(onTap: onEdit, child: const Row(children: [Icon(Icons.edit_outlined, size: 20), SizedBox(width: 12), Text('Edit')])),
                  PopupMenuItem(onTap: onDelete, child: const Row(children: [Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20), SizedBox(width: 12), Text('Hapus', style: TextStyle(color: Colors.red))])),
                ],
              ),
            ],
          ),
          const Spacer(),
          Row(
            children: [
              Icon(Icons.person_pin_rounded, size: 14, color: theme.colorScheme.onSurface.withAlpha(100)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Wali: ${kelas['wali_kelas'] ?? '-'}',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: theme.colorScheme.onSurface.withAlpha(150)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
