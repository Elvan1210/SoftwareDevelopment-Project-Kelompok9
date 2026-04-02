import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../config/theme.dart';
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
    _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
    setState(() => _isLoading = true);
    await _fetchKelas();
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _fetchKelas() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/kelas'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      if (response.statusCode == 200) {
        final dec = jsonDecode(response.body);
        _kelasList = dec is List ? dec : [];
      }
    } catch (e) {
      debugPrint('Error fetching kelas: $e');
    }
  }

  Future<void> _deleteKelas(String id) async {
    if (await confirmDelete(context, pesan: 'Yakin ingin menghapus kelas ini?')) {
      try {
        await http.delete(
          Uri.parse('$baseUrl/api/kelas/$id'),
          headers: {'Authorization': 'Bearer ${widget.token}'},
        );
        _fetchKelas();
        setState(() {});
      } catch (e) {
        debugPrint('Error: $e');
      }
    }
  }

  void _showKelasForm([Map<String, dynamic>? kelas]) {
    final isEditing = kelas != null;
    final namaCtrl = TextEditingController(text: isEditing ? kelas['nama_kelas'] : '');
    final kodeCtrl = TextEditingController(text: isEditing ? (kelas['kode_kelas'] ?? '') : '');
    final mapelCtrl = TextEditingController(text: isEditing ? (kelas['mapel'] ?? '') : '');
    final tahunAjaranCtrl = TextEditingController(text: isEditing ? (kelas['tahun_ajaran'] ?? '') : '');
    
    // Antigravity Strict Colors
    final List<Color> cardColors = [
      AppTheme.getAdaptiveTeal(context), // Deep Teal
      const Color(0xFFF27F33), // Orange
      const Color(0xFF76AFB8), // Light Teal
    ];
    Color selectedColor = isEditing && kelas['warna_card'] != null 
        ? Color(int.parse(kelas['warna_card'])) 
        : cardColors[(_kelasList.length) % cardColors.length];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Text(isEditing ? 'Edit Kelas Virtual' : 'Buat Tim/Kelas Baru', style: const TextStyle(fontWeight: FontWeight.w900)),
            content: SizedBox(
              width: 500,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.getAdaptiveTeal(context).withAlpha(20),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.getAdaptiveTeal(context).withAlpha(50)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: AppTheme.getAdaptiveTeal(context), size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Kode Akses untuk bergabung (join code) akan digenerate secara otomatis setelah tim ini disimpan.',
                              style: TextStyle(fontSize: 12, color: AppTheme.getAdaptiveTeal(context), fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    AppTextField(controller: kodeCtrl, labelText: 'Kode Kelas (cth: GN2526)', prefixIcon: Icons.qr_code_rounded),
                    const SizedBox(height: 16),
                    AppTextField(controller: namaCtrl, labelText: 'Nama Tim (cth: Sistem Operasi (A))', prefixIcon: Icons.class_outlined),
                    const SizedBox(height: 16),
                    AppTextField(controller: mapelCtrl, labelText: 'Mata Pelajaran', prefixIcon: Icons.subject_rounded),
                    const SizedBox(height: 16),
                    AppTextField(controller: tahunAjaranCtrl, labelText: 'Tahun Ajaran (cth: 2024/2025 Ganjil)', prefixIcon: Icons.calendar_today_rounded),
                    const SizedBox(height: 16),
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
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                onPressed: () async {
                  if (namaCtrl.text.isEmpty) return;
                  
                  final Map<String, dynamic> body = {
                    'nama_kelas': namaCtrl.text,
                    'kode_kelas': kodeCtrl.text,
                    'mapel': mapelCtrl.text,
                    'tahun_ajaran': tahunAjaranCtrl.text,
                    'warna_card': selectedColor.toARGB32().toString(),
                  };

                  if (!isEditing) {
                    body['siswa_ids'] = [];
                  }
                  
                  final headers = {'Content-Type': 'application/json', 'Authorization': 'Bearer ${widget.token}'};
                  try {
                    if (isEditing) {
                      await http.put(Uri.parse('$baseUrl/api/kelas/${kelas['id']}'), headers: headers, body: jsonEncode(body));
                    } else {
                      await http.post(Uri.parse('$baseUrl/api/kelas'), headers: headers, body: jsonEncode(body));
                    }
                    if (ctx.mounted) Navigator.pop(ctx);
                    _fetchKelas().then((_) => setState(() {}));
                  } catch (e) {
                    debugPrint('Error saving: $e');
                  }
                },
                child: const Text('Simpan & Generate Kode', style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ],
          );
        }
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return AppShell(child: _buildSkeleton());

    return AppShell(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        floatingActionButton: AppFAB(
          onPressed: () => _showKelasForm(),
          icon: Icons.add_rounded,
          label: 'Buat Tim/Kelas',
        ),
        body: _kelasList.isEmpty
            ? EmptyState(icon: Icons.grid_view_rounded, message: 'Belum ada tim/kelas virtual.', color: AppTheme.getAdaptiveTeal(context))
            : RepaintBoundary(
                child: RefreshIndicator(
                  onRefresh: () async {
                    await _fetchKelas();
                    setState(() {});
                  },
                  child: LayoutBuilder(
                    builder: (ctx, c) {
                      final w = c.maxWidth;
                      final padding = Breakpoints.screenPadding(w);
                      final crossCount = w >= Breakpoints.desktop ? 4 : (w >= Breakpoints.tablet ? 3 : (w >= Breakpoints.mobile ? 2 : 1));

                      return CustomScrollView(
                        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                        slivers: [
                          SliverPadding(
                            padding: padding,
                            sliver: SliverGrid(
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossCount,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                childAspectRatio: 1.5,
                              ),
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  final k = _kelasList[index];
                                  return _TeamsClassCard(
                                    kelas: k,
                                    onEdit: () => _showKelasForm(k),
                                    onDelete: () => _deleteKelas(k['id'].toString()),
                                  ).animate(delay: (index * 40).ms).fadeIn(duration: 400.ms).slideY(begin: 0.1, curve: Curves.easeOutQuart);
                                },
                                childCount: _kelasList.length,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildSkeleton() {
    return GridView.count(
      padding: const EdgeInsets.all(24),
      crossAxisCount: 2,
      childAspectRatio: 1.5,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: List.generate(6, (_) => const SkeletonLoader(radius: 20)),
    );
  }
}

class _TeamsClassCard extends StatelessWidget {
  final dynamic kelas;
  final VoidCallback onEdit, onDelete;

  const _TeamsClassCard({required this.kelas, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = Color(int.parse(kelas['warna_card'] ?? '0xFF075864'));
    
    // Get initials for the box
    String initials = "??";
    final nama = (kelas['nama_kelas'] as String? ?? "").trim();
    if (nama.isNotEmpty) {
      final parts = nama.split(' ');
      if (parts.length >= 2) {
        initials = (parts[0][0] + parts[1][0]).toUpperCase();
      } else {
        initials = parts[0].substring(0, parts.length > 1 ? 2 : 1).toUpperCase();
      }
    }
    
    if (initials == "??" && nama.isNotEmpty) {
      initials = nama.substring(0, nama.length >= 2 ? 2 : 1).toUpperCase();
    }

    return PremiumCard(
      accentColor: color,
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 12, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: color.withAlpha(80), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: Center(
                      child: Text(initials, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 24)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${kelas['kode_kelas'] ?? ''} - ${kelas['nama_kelas'] ?? '-'}',
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, height: 1.2),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF76AFB8).withAlpha(20),
                                border: Border.all(color: const Color(0xFF76AFB8).withAlpha(50)),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.vpn_key_rounded, size: 14, color: Color(0xFF76AFB8)),
                                  const SizedBox(width: 6),
                                  Text(
                                    kelas['kode_akses'] ?? 'Generating...',
                                    style: const TextStyle(
                                      fontSize: 12, 
                                      fontWeight: FontWeight.bold, 
                                      letterSpacing: 1.2,
                                      color: Color(0xFF76AFB8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 4),
                            if (kelas['kode_akses'] != null)
                              InkWell(
                                onTap: () {
                                  Clipboard.setData(ClipboardData(text: kelas['kode_akses']));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Kode akses "${kelas['kode_akses']}" berhasil disalin! 📋'),
                                      backgroundColor: AppTheme.getAdaptiveTeal(context),
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                },
                                borderRadius: BorderRadius.circular(6),
                                child: Padding(
                                  padding: const EdgeInsets.all(4),
                                  child: Icon(
                                    Icons.copy_rounded,
                                    size: 14,
                                    color: const Color(0xFF76AFB8).withAlpha(180),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.history_rounded, size: 10, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              'TA: ${kelas['tahun_ajaran'] ?? '-'}',
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.grey),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Guru: ${kelas['guru_nama'] ?? 'Belum ada'}',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface.withAlpha(150)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  
                  PopupMenuButton(
                    icon: Icon(Icons.more_horiz_rounded, size: 20, color: theme.colorScheme.onSurface.withAlpha(100)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    itemBuilder: (_) => [
                      PopupMenuItem(onTap: onEdit, child: const Row(children: [Icon(Icons.edit_outlined, size: 18), SizedBox(width: 12), Text('Edit Kelas')])),
                      PopupMenuItem(onTap: onDelete, child: const Row(children: [Icon(Icons.delete_outline_rounded, color: Colors.red, size: 18), SizedBox(width: 12), Text('Hapus', style: TextStyle(color: Colors.red))])),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: theme.dividerColor.withAlpha(50))),
            ),
            child: Row(
              children: [
                _buildMiniIcon(Icons.assignment_outlined),
                const SizedBox(width: 16),
                _buildMiniIcon(Icons.backpack_outlined),
                const SizedBox(width: 16),
                _buildMiniIcon(Icons.assignment_ind_outlined),
                const Spacer(),
                Text('${(kelas['siswa_ids'] as List?)?.length ?? 0} Siswa', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniIcon(IconData icon) {
    return Icon(icon, size: 16, color: Colors.grey.shade600);
  }
}
