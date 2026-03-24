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
  List<dynamic> _guruList = [];
  List<dynamic> _siswaList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
    setState(() => _isLoading = true);
    await Future.wait([
      _fetchKelas(),
      _fetchUsers('Guru').then((val) => _guruList = val),
      _fetchUsers('Siswa').then((val) => _siswaList = val),
    ]);
    if (mounted) setState(() => _isLoading = false);
  }

  Future<List<dynamic>> _fetchUsers(String role) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/users?role=$role'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('Error fetching users: $e');
    }
    return [];
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
    
    String? selectedGuruId = isEditing ? kelas['guru_id'] : null;
    List<String> selectedSiswaIds = isEditing ? List<String>.from(kelas['siswa_ids'] ?? []) : [];
    
    // Default colors for Teams-like cards
    final List<Color> cardColors = [
      const Color(0xFF0078D4), // Teams Blue
      const Color(0xFFD83B01), // Orange
      const Color(0xFF008272), // Teal
      const Color(0xFF5C2D91), // Purple
      const Color(0xFFB4009E), // Pink
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
            title: Text(isEditing ? 'Edit Kelas Virtual' : 'Buat Kelas Baru', style: const TextStyle(fontWeight: FontWeight.w900)),
            content: SizedBox(
              width: 600,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 8),
                    AntigravityTextField(controller: kodeCtrl, labelText: 'Kode Kelas (cth: GN2526 - SI13038)', prefixIcon: Icons.qr_code_rounded),
                    const SizedBox(height: 16),
                    AntigravityTextField(controller: namaCtrl, labelText: 'Nama Kelas (cth: Sistem Operasi (A))', prefixIcon: Icons.class_outlined),
                    const SizedBox(height: 16),
                    AntigravityTextField(controller: mapelCtrl, labelText: 'Mata Pelajaran', prefixIcon: Icons.subject_rounded),
                    const SizedBox(height: 24),
                    
                    // Guru Selection
                    _buildSectionHeader('Assign Pengajar (Guru)', Icons.person_search_rounded),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: selectedGuruId,
                      decoration: _dropdownDecoration('Pilih Guru Pengajar'),
                      items: _guruList.map((g) => DropdownMenuItem<String>(
                        value: g['id'].toString(),
                        child: Text(g['nama'] ?? '-'),
                      )).toList(),
                      onChanged: (val) => setDialogState(() => selectedGuruId = val),
                    ),
                    const SizedBox(height: 24),

                    // Siswa Selection
                    _buildSectionHeader('Daftar Siswa (${selectedSiswaIds.length} terpilih)', Icons.group_add_rounded),
                    const SizedBox(height: 8),
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface.withAlpha(100),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: ListView.builder(
                        itemCount: _siswaList.length,
                        itemBuilder: (context, index) {
                          final s = _siswaList[index];
                          final id = s['id'].toString();
                          final isSelected = selectedSiswaIds.contains(id);
                          return CheckboxListTile(
                            dense: true,
                            title: Text(s['nama'] ?? '-', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                            subtitle: Text(s['kelas'] ?? '', style: const TextStyle(fontSize: 11)),
                            value: isSelected,
                            onChanged: (val) {
                              setDialogState(() {
                                if (val == true) selectedSiswaIds.add(id);
                                else selectedSiswaIds.remove(id);
                              });
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
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
                  if (namaCtrl.text.isEmpty || selectedGuruId == null) return;
                  
                  final guruObj = _guruList.firstWhere((g) => g['id'].toString() == selectedGuruId);
                  
                  final body = {
                    'nama_kelas': namaCtrl.text,
                    'kode_kelas': kodeCtrl.text,
                    'mapel': mapelCtrl.text,
                    'guru_id': selectedGuruId,
                    'guru_nama': guruObj['nama'],
                    'siswa_ids': selectedSiswaIds,
                    'warna_card': selectedColor.value.toString(),
                  };
                  
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
                child: const Text('Simpan Perubahan', style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ],
          );
        }
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.blueGrey),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.blueGrey)),
      ],
    );
  }

  InputDecoration _dropdownDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return AppShell(child: _buildSkeleton());

    return AppShell(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        floatingActionButton: AntigravityFAB(
          onPressed: () => _showKelasForm(),
          icon: Icons.add_rounded,
          label: 'Buat Kelas Teams',
        ),
        body: _kelasList.isEmpty
            ? const EmptyState(icon: Icons.grid_view_rounded, message: 'Belum ada kelas virtual.', color: Colors.blue)
            : RefreshIndicator(
                onRefresh: () async {
                  await _fetchKelas();
                  setState(() {});
                },
                child: LayoutBuilder(
                  builder: (ctx, c) {
                    final w = c.maxWidth;
                    final padding = Breakpoints.screenPadding(w);
                    final crossCount = w >= Breakpoints.desktop ? 4 : (w >= Breakpoints.tablet ? 3 : (w >= Breakpoints.mobile ? 2 : 1));

                    return GridView.builder(
                      padding: padding,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossCount,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1.6,
                      ),
                      itemCount: _kelasList.length,
                      itemBuilder: (context, index) {
                        final k = _kelasList[index];
                        return _TeamsClassCard(
                          kelas: k,
                          onEdit: () => _showKelasForm(k),
                          onDelete: () => _deleteKelas(k['id'].toString()),
                        ).animate(delay: (index * 40).ms).fadeIn(duration: 400.ms).scale(begin: const Offset(0.9, 0.9));
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
      childAspectRatio: 1.6,
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
    final color = Color(int.parse(kelas['warna_card'] ?? '0xFF3B82F6'));
    
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
    
    // If it fails or is short, just take first 2 chars
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
                  // The Square Icon
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
                  
                  // Text Content
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
                        const SizedBox(height: 4),
                        Text(
                          'Guru: ${kelas['guru_nama'] ?? '-'}',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface.withAlpha(150)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  
                  // Menu
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
          
          // Bottom Icons Bar
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
