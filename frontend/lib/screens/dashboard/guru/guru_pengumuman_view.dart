import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../../widgets/confirm_delete.dart';
import '../../../widgets/app_shell.dart';
import '../../../config/api_config.dart';
import '../../../config/theme.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../services/notifikasi_service.dart';
import '../../../utils/date_utils.dart';

// ─── Kategori config ──────────────────────────────────────────────────────────
class _KategoriConfig {
  final String label;
  final IconData icon;
  final Color color;
  final Color colorEnd;
  const _KategoriConfig({required this.label, required this.icon, required this.color, required this.colorEnd});
}

const _kategoriMap = {
  'Semua': _KategoriConfig(label: 'Semua', icon: LucideIcons.layoutGrid, color: AppTheme.indigoPrimary, colorEnd: AppTheme.purpleSecondary),
  'Ujian': _KategoriConfig(label: 'Ujian', icon: LucideIcons.clipboardList, color: AppTheme.amber, colorEnd: Color(0xFFF97316)),
  'Libur': _KategoriConfig(label: 'Libur', icon: LucideIcons.palmtree, color: AppTheme.emerald, colorEnd: Color(0xFF059669)),
  'Seminar': _KategoriConfig(label: 'Seminar', icon: LucideIcons.presentation, color: AppTheme.sky, colorEnd: Color(0xFF0EA5E9)),
  'Umum': _KategoriConfig(label: 'Umum', icon: LucideIcons.megaphone, color: AppTheme.purpleSecondary, colorEnd: AppTheme.purpleLight),
};

_KategoriConfig _getKategori(String? judul, [String? kategoriField]) {
  if (kategoriField != null && _kategoriMap.containsKey(kategoriField)) {
    return _kategoriMap[kategoriField]!;
  }
  if (judul == null) return _kategoriMap['Umum']!;
  final low = judul.toLowerCase();
  if (low.contains('libur')) return _kategoriMap['Libur']!;
  if (low.contains('ujian') || low.contains('ulangan') || low.contains('uts') || low.contains('uas')) return _kategoriMap['Ujian']!;
  if (low.contains('seminar') || low.contains('webinar') || low.contains('workshop')) return _kategoriMap['Seminar']!;
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
  String _search = '';
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
    if (await confirmDelete(context, pesan: 'Hapus pengumuman ini?')) {
      try {
        final res = await http.delete(
          Uri.parse('$baseUrl/api/pengumuman/$id'),
          headers: {'Authorization': 'Bearer ${widget.token}'},
        );
        if (res.statusCode == 200 && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Pengumuman dihapus.', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            backgroundColor: AppTheme.emerald,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ));
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
    final tanggalStr = DateFormat('dd MMM yyyy').format(DateTime.now());

    showDialog(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return StatefulBuilder(
          builder: (ctx, setFormState) => Dialog(
          backgroundColor: isDark ? AppTheme.darkCard : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: SizedBox(
              width: 520,
              child: SingleChildScrollView(
                child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [AppTheme.amber, Color(0xFFF97316)]),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(LucideIcons.megaphone, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Text(
                      isEditing ? 'Edit Pengumuman' : 'Buat Pengumuman Baru',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w800, fontSize: 18,
                          color: isDark ? Colors.white : AppTheme.textLight),
                    ),
                  ]),
                  const SizedBox(height: 24),
                  _FormField(controller: judulCtrl, label: 'Judul Pengumuman', icon: LucideIcons.type, isDark: isDark),
                  const SizedBox(height: 16),
                  _FormField(controller: isiCtrl, label: 'Isi Pengumuman', icon: LucideIcons.alignLeft, isDark: isDark, maxLines: 5),
                  const SizedBox(height: 16),
                  Text('Kategori', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700,
                      color: isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ['Umum', 'Ujian', 'Libur', 'Seminar'].map((k) {
                      final cfg = _kategoriMap[k]!;
                      final sel = formKategori == k;
                      return GestureDetector(
                        onTap: () => setFormState(() => formKategori = k),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            gradient: sel ? LinearGradient(colors: [cfg.color, cfg.colorEnd]) : null,
                            color: sel ? null : (isDark ? AppTheme.darkBg : const Color(0xFFF5F5FF)),
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(color: sel ? Colors.transparent : cfg.color.withAlpha(80)),
                            boxShadow: sel ? [BoxShadow(color: cfg.color.withAlpha(70), blurRadius: 8, offset: const Offset(0, 3))] : [],
                          ),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(cfg.icon, size: 13, color: sel ? Colors.white : cfg.color),
                            const SizedBox(width: 6),
                            Text(k, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700,
                                color: sel ? Colors.white : cfg.color)),
                          ]),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 28),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text('Batal', style: GoogleFonts.poppins(color: isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt)),
                      ),
                      const SizedBox(width: 10),
                      _GradientButton(
                        label: isEditing ? 'Simpan' : 'Terbitkan',
                        onPressed: () async {
                          if (judulCtrl.text.isEmpty || isiCtrl.text.isEmpty) return;
                          final body = {
                            'judul': judulCtrl.text,
                            'isi': isiCtrl.text,
                            'tanggal': isEditing ? (pengumuman['tanggal'] ?? tanggalStr) : tanggalStr,
                            'guru_id': widget.userData['id'],
                            'author': widget.userData['nama'],
                            'kategori': formKategori,
                          };
                          final headers = {'Content-Type': 'application/json', 'Authorization': 'Bearer ${widget.token}'};
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
                      ),
                    ],
                  ),
                ],
              ),
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
      list = list.where((p) => _getKategori(p['judul']?.toString(), p['kategori']?.toString()).label == _selectedKategori).toList();
    }
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      list = list.where((p) =>
        (p['judul'] ?? '').toLowerCase().contains(q) ||
        (p['isi'] ?? '').toLowerCase().contains(q)
      ).toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return AppShell(child: ListView.builder(
        padding: const EdgeInsets.all(24),
        itemCount: 5,
        itemBuilder: (_, __) => const Padding(
          padding: EdgeInsets.only(bottom: 16),
          child: SkeletonLoader(height: 120, radius: 20),
        ),
      ));
    }

    return AppShell(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        floatingActionButton: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [AppTheme.amber, Color(0xFFF97316)]),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: AppTheme.amber.withAlpha(100), blurRadius: 20, offset: const Offset(0, 8))],
          ),
          child: FloatingActionButton.extended(
            onPressed: () => _showPengumumanForm(),
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            elevation: 0,
            icon: const Icon(LucideIcons.megaphone, size: 18),
            label: Text('Buat Baru', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
          ),
        ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.3),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: _SearchBar(
                isDark: isDark,
                onChanged: (v) => setState(() => _search = v),
              ).animate().fadeIn().slideY(begin: -0.1),
            ),
            const SizedBox(height: 12),
            // Category chips
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: SizedBox(
              height: 46,
              child: ListView(
                clipBehavior: Clip.none,
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: _kategoriMap.keys.map((k) {
                  final cfg = _kategoriMap[k]!;
                  final selected = _selectedKategori == k;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedKategori = k),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: selected ? LinearGradient(colors: [cfg.color, cfg.colorEnd]) : null,
                          color: selected ? null : (isDark ? AppTheme.darkCard : Colors.white),
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(color: selected ? Colors.transparent : cfg.color.withAlpha(isDark ? 80 : 60)),
                          boxShadow: selected
                              ? [BoxShadow(color: cfg.color.withAlpha(80), blurRadius: 10, offset: const Offset(0, 4))]
                              : [],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(cfg.icon, size: 13, color: selected ? Colors.white : cfg.color),
                            const SizedBox(width: 6),
                            Text(cfg.label, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700,
                                color: selected ? Colors.white : cfg.color)),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            ).animate().fadeIn(delay: 80.ms),
            const SizedBox(height: 12),
            Expanded(
              child: _filtered.isEmpty
                  ? const EmptyState(icon: LucideIcons.megaphone, message: 'Belum ada pengumuman.', color: AppTheme.amber)
                  : RefreshIndicator(
                      onRefresh: _fetchPengumuman,
                      color: AppTheme.amber,
                      child: LayoutBuilder(builder: (ctx, c) {
                        final padding = Breakpoints.screenPadding(c.maxWidth);
                        return ListView.builder(
                          padding: padding.copyWith(bottom: 100),
                          itemCount: _filtered.length,
                          itemBuilder: (ctx, i) {
                            final p = _filtered[i];
                            return _GuruPengumumanCard(
                              pengumuman: p,
                              isDark: isDark,
                              onEdit: () => _showPengumumanForm(p),
                              onDelete: () => _deletePengumuman(p['id'].toString()),
                            ).animate(delay: (i * 60).ms).fadeIn(duration: 400.ms)
                                .slideY(begin: 0.08, curve: Curves.easeOutQuart);
                          },
                        );
                      }),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Form Field ───────────────────────────────────────────────────────────────
class _FormField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool isDark;
  final int maxLines;
  const _FormField({required this.controller, required this.label, required this.icon, required this.isDark, this.maxLines = 1});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkBg : const Color(0xFFF9F9FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: GoogleFonts.poppins(fontSize: 14, color: isDark ? Colors.white : AppTheme.textLight),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.poppins(fontSize: 13, color: isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt),
          prefixIcon: Icon(icon, size: 18, color: isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}

// ─── Gradient Button ──────────────────────────────────────────────────────────
class _GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  const _GradientButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppTheme.amber, Color(0xFFF97316)]),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: AppTheme.amber.withAlpha(80), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent, shadowColor: Colors.transparent,
          foregroundColor: Colors.white, elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 24),
        ),
        child: Text(label, style: GoogleFonts.poppins(fontWeight: FontWeight.w800)),
      ),
    );
  }
}

// ─── Search Bar ───────────────────────────────────────────────────────────────
class _SearchBar extends StatelessWidget {
  final bool isDark;
  final ValueChanged<String> onChanged;
  const _SearchBar({required this.isDark, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: EdgeInsets.zero,
      child: TextField(
        onChanged: onChanged,
        style: GoogleFonts.poppins(fontSize: 14, color: isDark ? Colors.white : AppTheme.textLight),
        decoration: InputDecoration(
          hintText: 'Cari pengumuman...',
          hintStyle: GoogleFonts.poppins(fontSize: 13, color: isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt),
          prefixIcon: Icon(LucideIcons.search, size: 18, color: isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}

// ─── Guru Card ────────────────────────────────────────────────────────────────
class _GuruPengumumanCard extends StatelessWidget {
  final dynamic pengumuman;
  final bool isDark;
  final VoidCallback onEdit, onDelete;
  const _GuruPengumumanCard({required this.pengumuman, required this.isDark, required this.onEdit, required this.onDelete});

  String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    final parsed = DateTime.tryParse(raw);
    if (parsed != null) return DateFormat('dd MMM yyyy').format(parsed);
    return raw;
  }

  @override
  Widget build(BuildContext context) {
    final tanggal = _formatDate(pengumuman['tanggal']?.toString());
    final author = pengumuman['author']?.toString();
    final cfg = _getKategori(pengumuman['judul']?.toString());

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cfg.color.withAlpha(isDark ? 55 : 35)),
        boxShadow: [
          BoxShadow(color: cfg.color.withAlpha(isDark ? 30 : 12), blurRadius: 18, offset: const Offset(0, 6)),
          BoxShadow(color: Colors.black.withAlpha(isDark ? 60 : 8), blurRadius: 14, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top band ──
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                cfg.color.withAlpha(isDark ? 45 : 28),
                cfg.colorEnd.withAlpha(isDark ? 20 : 10),
              ]),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(19)),
              border: Border(bottom: BorderSide(color: cfg.color.withAlpha(isDark ? 40 : 25))),
            ),
            child: Row(children: [
              // Icon box bold
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [cfg.color, cfg.colorEnd], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(11),
                  boxShadow: [BoxShadow(color: cfg.color.withAlpha(100), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Icon(cfg.icon, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: cfg.color.withAlpha(isDark ? 40 : 22),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(cfg.label.toUpperCase(),
                          style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.w800, color: cfg.color, letterSpacing: 0.8)),
                    ),
                    const SizedBox(height: 3),
                    Text(pengumuman['judul'] ?? '-',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w800, fontSize: 14, letterSpacing: -0.3,
                            color: isDark ? Colors.white : AppTheme.textLight),
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              if (tanggal.isNotEmpty) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: cfg.color.withAlpha(isDark ? 35 : 20),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(tanggal, style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w700, color: cfg.color)),
                ),
              ],
            ]),
          ),

          // ── Body ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(pengumuman['isi'] ?? '-',
                  style: GoogleFonts.poppins(fontSize: 13, height: 1.7,
                      color: isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt),
                  maxLines: 4, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 12),
              Divider(height: 1, color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
              const SizedBox(height: 12),
              Row(children: [
                if (author != null) ...[
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: AppTheme.indigoPrimary.withAlpha(isDark ? 35 : 20),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: const Icon(LucideIcons.user, size: 11, color: AppTheme.indigoPrimary),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text('Oleh: $author',
                        style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.indigoPrimary),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                  const SizedBox(width: 8),
                ],
                _ActionButton(icon: LucideIcons.edit2, label: 'Edit', color: AppTheme.indigoPrimary, isDark: isDark, onTap: onEdit),
                const SizedBox(width: 8),
                _ActionButton(icon: LucideIcons.trash2, label: 'Hapus', color: AppTheme.rose, isDark: isDark, onTap: onDelete),
              ]),
            ]),
          ),
        ],
      ),
    );
  }
}

// ─── Action Button ────────────────────────────────────────────────────────────
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;
  const _ActionButton({required this.icon, required this.label, required this.color, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withAlpha(isDark ? 30 : 15),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: color.withAlpha(isDark ? 60 : 40)),
        ),
        child: Row(children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
          Text(label, style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
        ]),
      ),
    );
  }
}
