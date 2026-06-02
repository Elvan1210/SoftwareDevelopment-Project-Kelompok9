import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../../widgets/confirm_delete.dart';
import '../../../widgets/app_shell.dart';
import '../../../config/api_config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../services/notifikasi_service.dart';
import '../../../utils/date_utils.dart';

// --- NEO-BRUTALIST CONSTANTS ---
const Color _kPrimary = Color(0xFF4F46E5); // Indigo/Purple for main actions
const Color _kBgColor = Color(0xFFF4F7F6); // Ice-Blue background
const BorderSide _kBorder2 = BorderSide(color: Colors.black, width: 2.0);
const BoxShadow _kHardShadow = BoxShadow(color: Colors.black, offset: Offset(4, 4), blurRadius: 0);

class _KategoriConfig {
  final String label;
  final IconData icon;
  final Color color;
  const _KategoriConfig({
    required this.label,
    required this.icon,
    required this.color,
  });
}

const _kategoriMap = {
  'Semua': _KategoriConfig(
    label: 'Semua',
    icon: LucideIcons.layoutGrid,
    color: _kPrimary,
  ),
  'Ujian': _KategoriConfig(
    label: 'Ujian',
    icon: LucideIcons.clipboardList,
    color: Color(0xFFF59E0B), // Orange
  ),
  'Libur': _KategoriConfig(
    label: 'Libur',
    icon: LucideIcons.palmtree,
    color: Color(0xFF10B981), // Green
  ),
  'Seminar': _KategoriConfig(
    label: 'Seminar',
    icon: LucideIcons.presentation,
    color: Color(0xFF3B82F6), // Blue
  ),
  'Umum': _KategoriConfig(
    label: 'Umum',
    icon: LucideIcons.megaphone,
    color: Color(0xFF8B5CF6), // Purple
  ),
};

_KategoriConfig _getKategori(String? kategoriField) {
  if (kategoriField != null && _kategoriMap.containsKey(kategoriField)) {
    return _kategoriMap[kategoriField]!;
  }
  return _kategoriMap['Umum']!;
}

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
  String _searchQuery = '';
  String _selectedKategori = 'Semua';

  @override
  void initState() {
    super.initState();
    _fetchPengumuman();
  }

  Future<void> _fetchPengumuman() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/pengumuman'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        List<dynamic> list = decoded is List ? decoded : [];
        list.sort((a, b) {
          final aDate = AppDateUtils.parseIndonesianDate(a['tanggal']?.toString() ?? '');
          final bDate = AppDateUtils.parseIndonesianDate(b['tanggal']?.toString() ?? '');
          return bDate.compareTo(aDate);
        });
        setState(() => _pengumumanList = list);
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _deletePengumuman(String id) async {
    if (await confirmDelete(context, pesan: 'Yakin hapus pengumuman ini?')) {
      try {
        final res = await http.delete(
          Uri.parse('$baseUrl/api/pengumuman/$id'),
          headers: {'Authorization': 'Bearer ${widget.token}'},
        );
        if (res.statusCode == 200 && mounted) {
          _fetchPengumuman();
        }
      } catch (e) {
        debugPrint('Error: $e');
      }
    }
  }

  void _showPengumumanForm([Map<String, dynamic>? pengumuman]) {
    final isEditing = pengumuman != null;
    final judulCtrl = TextEditingController(text: isEditing ? pengumuman['judul'] : '');
    final isiCtrl = TextEditingController(text: isEditing ? pengumuman['isi'] : '');
    String formKategori = pengumuman?['kategori']?.toString() ?? 'Umum';
    bool kategoriError = false;
    final now = DateTime.now();
    final tanggalStr = DateFormat('dd MMM yyyy').format(now);

    showDialog(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final bgCol = isDark ? const Color(0xFF1E1E1E) : Colors.white;
        final textCol = isDark ? Colors.white : Colors.black;

        return StatefulBuilder(
          builder: (ctx, setFormState) => Dialog(
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Container(
              width: 500,
              decoration: BoxDecoration(
                color: bgCol,
                border: const Border.fromBorderSide(_kBorder2),
                boxShadow: const [_kHardShadow],
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // HEADER
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                      decoration: const BoxDecoration(
                        color: _kPrimary,
                        border: Border(bottom: _kBorder2),
                      ),
                      child: Row(
                        children: [
                          const Icon(LucideIcons.megaphone, color: Colors.white, size: 20),
                          const SizedBox(width: 12),
                          Text(
                            isEditing ? 'EDIT PENGUMUMAN' : 'BUAT PENGUMUMAN BARU',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // BODY
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('JUDUL PENGUMUMAN', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w800, color: textCol)),
                          const SizedBox(height: 8),
                          _NeoTextField(controller: judulCtrl, hint: 'Masukkan judul...', isDark: isDark),
                          const SizedBox(height: 16),
                          
                          Text('KATEGORI', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w800, color: textCol)),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: ['Umum', 'Ujian', 'Libur', 'Seminar'].map((k) {
                              final sel = formKategori == k;
                              final cfg = _kategoriMap[k]!;
                              return GestureDetector(
                                onTap: () => setFormState(() {
                                  formKategori = k;
                                  kategoriError = false;
                                }),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: sel ? cfg.color : (isDark ? Colors.black54 : Colors.white),
                                    border: const Border.fromBorderSide(_kBorder2),
                                    boxShadow: sel ? const [BoxShadow(color: Colors.black, offset: Offset(2, 2))] : [],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(cfg.icon, size: 14, color: sel ? Colors.white : textCol),
                                      const SizedBox(width: 6),
                                      Text(
                                        k,
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w800,
                                          color: sel ? Colors.white : textCol,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          if (kategoriError)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text('Pilih kategori terlebih dahulu!', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red)),
                            ),
                          const SizedBox(height: 16),
                          
                          Text('ISI PENGUMUMAN', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w800, color: textCol)),
                          const SizedBox(height: 8),
                          _NeoTextField(controller: isiCtrl, hint: 'Masukkan isi pengumuman...', isDark: isDark, maxLines: 5),
                        ],
                      ),
                    ),
                    
                    // FOOTER BUTTONS
                    Container(
                      decoration: const BoxDecoration(
                        border: Border(top: BorderSide(color: Colors.black, width: 2.0)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () => Navigator.pop(ctx),
                              child: Container(
                                height: 60,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  border: Border(right: BorderSide(color: Colors.black, width: 2.0)),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  'Batal',
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 15,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                if (judulCtrl.text.isEmpty || isiCtrl.text.isEmpty) return;
                                if (formKategori.isEmpty) {
                                  setFormState(() => kategoriError = true);
                                  return;
                                }
                                final body = {
                                  'judul': judulCtrl.text,
                                  'isi': isiCtrl.text,
                                  'tanggal': isEditing ? (pengumuman['tanggal'] ?? tanggalStr) : tanggalStr,
                                  'guru_id': widget.userData['id'],
                                  'author': widget.userData['nama'],
                                  'kategori': formKategori,
                                };
                                final headers = {
                                  'Content-Type': 'application/json',
                                  'Authorization': 'Bearer ${widget.token}',
                                };
                                try {
                                  if (isEditing) {
                                    await http.put(Uri.parse('$baseUrl/api/pengumuman/${pengumuman['id']}'), headers: headers, body: jsonEncode(body));
                                  } else {
                                    await http.post(Uri.parse('$baseUrl/api/pengumuman'), headers: headers, body: jsonEncode(body));
                                    NotifikasiService.kirimNotifikasi(
                                      judul: 'Pengumuman: ${judulCtrl.text}',
                                      pesan: isiCtrl.text,
                                      token: widget.token,
                                      targetRole: 'Siswa',
                                    );
                                  }
                                  if (ctx.mounted) Navigator.pop(ctx);
                                  _fetchPengumuman();
                                } catch (e) {
                                  debugPrint('Error saving: $e');
                                }
                              },
                              child: Container(
                                height: 60,
                                decoration: const BoxDecoration(color: _kPrimary),
                                alignment: Alignment.center,
                                child: Text(
                                  isEditing ? 'Simpan' : 'Terbitkan',
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 15,
                                    color: Colors.white,
                                  ),
                                ),
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
      },
    );
  }

  List<dynamic> get _filtered {
    var list = _pengumumanList;
    if (_selectedKategori != 'Semua') {
      list = list.where((p) {
        final cfg = _getKategori(p['kategori']?.toString());
        return cfg.label == _selectedKategori;
      }).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((p) =>
        (p['judul'] ?? '').toString().toLowerCase().contains(q) ||
        (p['isi'] ?? '').toString().toLowerCase().contains(q)
      ).toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgCol = isDark ? const Color(0xFF121212) : _kBgColor;
    final textCol = isDark ? Colors.white : Colors.black;

    if (_isLoading) {
      return const AppShell(
        child: Center(child: CircularProgressIndicator(color: _kPrimary)),
      );
    }

    return AppShell(
      fullWidth: true,
      child: Scaffold(
        backgroundColor: bgCol,
        floatingActionButton: Container(
          decoration: const BoxDecoration(
            color: _kPrimary,
            border: Border.fromBorderSide(_kBorder2),
            boxShadow: [_kHardShadow],
          ),
          child: FloatingActionButton.extended(
            onPressed: () => _showPengumumanForm(),
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            icon: const Icon(LucideIcons.megaphone, size: 18),
            label: Text('Buat Baru', style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 14)),
          ),
        ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.3),
        
        body: RefreshIndicator(
          onRefresh: _fetchPengumuman,
          color: _kPrimary,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // SEARCH BAR
                      Container(
                        decoration: BoxDecoration(
                          color: isDark ? Colors.black54 : Colors.white,
                          border: const Border.fromBorderSide(_kBorder2),
                        ),
                        child: TextField(
                          onChanged: (v) => setState(() => _searchQuery = v),
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: textCol,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Cari pengumuman...',
                            hintStyle: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white54 : Colors.black38,
                              fontSize: 15,
                            ),
                            prefixIcon: Icon(LucideIcons.search, color: textCol),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // KATEGORI TABS
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        clipBehavior: Clip.none,
                        child: Row(
                          children: _kategoriMap.keys.map((k) {
                            final selected = _selectedKategori == k;
                            final cfg = _kategoriMap[k]!;
                            return Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: GestureDetector(
                                onTap: () => setState(() => _selectedKategori = k),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: selected ? _kPrimary : (isDark ? Colors.black54 : Colors.white),
                                    border: const Border.fromBorderSide(_kBorder2),
                                    boxShadow: selected ? const [BoxShadow(color: Colors.black, offset: Offset(3, 3))] : [],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(cfg.icon, size: 14, color: selected ? Colors.white : (isDark ? Colors.white : cfg.color)),
                                      const SizedBox(width: 8),
                                      Text(
                                        cfg.label,
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w900,
                                          color: selected ? Colors.white : textCol,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // GRID LAYOUT
              if (_filtered.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Text(
                      'Belum ada pengumuman.',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: textCol.withAlpha(150),
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
                  sliver: SliverLayoutBuilder(
                    builder: (BuildContext context, SliverConstraints constraints) {
                      int crossAxisCount = constraints.crossAxisExtent > 800 ? 3 : (constraints.crossAxisExtent > 500 ? 2 : 1);
                      return SliverGrid(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 24,
                          mainAxisSpacing: 24,
                          mainAxisExtent: 220, // Fixed height for consistency
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final p = _filtered[index];
                            return _GuruPengumumanCard(
                              pengumuman: p,
                              isDark: isDark,
                              onEdit: () => _showPengumumanForm(p),
                              onDelete: () => _deletePengumuman(p['id'].toString()),
                            ).animate(delay: (index * 50).ms).fadeIn(duration: 300.ms).slideY(begin: 0.1);
                          },
                          childCount: _filtered.length,
                        ),
                      );
                    }
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── WIDGETS ──

class _NeoTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool isDark;
  final int maxLines;

  const _NeoTextField({
    required this.controller,
    required this.hint,
    required this.isDark,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.black54 : Colors.white,
        border: const Border.fromBorderSide(_kBorder2),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: GoogleFonts.inter(
          fontWeight: FontWeight.w700,
          fontSize: 14,
          color: isDark ? Colors.white : Colors.black,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white54 : Colors.black38,
            fontSize: 14,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: InputBorder.none,
          isDense: true,
        ),
      ),
    );
  }
}

class _GuruPengumumanCard extends StatelessWidget {
  final dynamic pengumuman;
  final bool isDark;
  final VoidCallback onEdit, onDelete;

  const _GuruPengumumanCard({
    required this.pengumuman,
    required this.isDark,
    required this.onEdit,
    required this.onDelete,
  });

  String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    final parsed = DateTime.tryParse(raw);
    if (parsed != null) return DateFormat('dd MMM yyyy').format(parsed);
    return raw;
  }

  @override
  Widget build(BuildContext context) {
    final tanggal = _formatDate(pengumuman['tanggal']?.toString());
    final author = pengumuman['author']?.toString() ?? pengumuman['guru_nama']?.toString() ?? '-';
    final cfg = _getKategori(pengumuman['kategori']?.toString());
    
    final bgCol = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textCol = isDark ? Colors.white : Colors.black;

    return Container(
      decoration: BoxDecoration(
        color: bgCol,
        border: const Border.fromBorderSide(_kBorder2),
        boxShadow: const [_kHardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HEADER BLOCK (Colored)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: cfg.color,
              border: const Border(bottom: _kBorder2),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(cfg.icon, color: Colors.white, size: 18),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cfg.label.toUpperCase(),
                        style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.0),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        pengumuman['judul'] ?? '-',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.white),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (tanggal.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Text(
                    tanggal,
                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white.withAlpha(200)),
                  ),
                ],
              ],
            ),
          ),
          
          // BODY BLOCK
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                pengumuman['isi'] ?? '-',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : Colors.black87,
                  height: 1.5,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          
          // DIVIDER
          Container(height: 2, color: Colors.black),
          
          // FOOTER SECTION
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // AUTHOR
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: _kPrimary,
                    border: Border.all(color: Colors.black, width: 1.5),
                  ),
                  child: const Icon(LucideIcons.user, size: 12, color: Colors.white),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Oleh: $author',
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w800, color: textCol),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                
                // ACTIONS
                GestureDetector(
                  onTap: onEdit,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6), // Blue Edit
                      border: Border.all(color: Colors.black, width: 2.0),
                    ),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.edit2, size: 12, color: Colors.white),
                        const SizedBox(width: 4),
                        Text('Edit', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.white)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onDelete,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444), // Red Delete
                      border: Border.all(color: Colors.black, width: 2.0),
                    ),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.trash, size: 12, color: Colors.white),
                        const SizedBox(width: 4),
                        Text('Hapus', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.white)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
