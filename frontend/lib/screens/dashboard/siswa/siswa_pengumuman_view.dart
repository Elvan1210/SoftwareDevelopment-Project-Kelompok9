import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../config/api_config.dart';
import '../../../config/theme.dart';
import '../../../widgets/app_shell.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
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

class SiswaPengumumanView extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String token;
  const SiswaPengumumanView({super.key, required this.userData, required this.token});

  @override
  State<SiswaPengumumanView> createState() => _SiswaPengumumanViewState();
}

class _SiswaPengumumanViewState extends State<SiswaPengumumanView> {
  List<dynamic> _pengumumanList = [];
  bool _isLoading = true;
  String _search = '';
  Set<String> _readIds = {};
  bool _showRead = false;
  String _selectedKategori = 'Semua';

  @override
  void initState() {
    super.initState();
    _loadAndFetch();
  }

  Future<void> _loadAndFetch() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('read_pengumuman_${widget.userData['id']}') ?? [];
    _readIds = list.toSet();
    await _fetchPengumuman();
  }

  Future<void> _markRead(String id) async {
    setState(() => _readIds.add(id));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('read_pengumuman_${widget.userData['id']}', _readIds.toList());
  }

  Future<void> _markAllRead() async {
    final allIds = _pengumumanList.map((p) => p['id']?.toString() ?? '').toSet();
    setState(() => _readIds.addAll(allIds));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('read_pengumuman_${widget.userData['id']}', _readIds.toList());
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

  List<dynamic> get _filtered {
    var base = _showRead
        ? _pengumumanList
        : _pengumumanList.where((p) => !_readIds.contains(p['id']?.toString())).toList();
    if (_selectedKategori != 'Semua') {
      base = base.where((p) => _getKategori(p['judul']?.toString(), p['kategori']?.toString()).label == _selectedKategori).toList();
    }
    if (_search.isEmpty) return base;
    final q = _search.toLowerCase();
    return base.where((p) =>
      (p['judul'] ?? '').toLowerCase().contains(q) ||
      (p['isi'] ?? '').toLowerCase().contains(q)
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return AppShell(child: _skeleton());
    }

    return AppShell(
      child: RefreshIndicator(
        onRefresh: _fetchPengumuman,
        color: AppTheme.amber,
        child: LayoutBuilder(builder: (ctx, c) {
          final w = c.maxWidth;
          final padding = Breakpoints.screenPadding(w);

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: padding.copyWith(bottom: 0),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Header ──
                      _Header(
                        isDark: isDark,
                        count: _filtered.length,
                        unread: _pengumumanList.where((p) => !_readIds.contains(p['id']?.toString())).length,
                        showRead: _showRead,
                        onToggleRead: () => setState(() => _showRead = !_showRead),
                        onMarkAll: _markAllRead,
                      ).animate().fadeIn(duration: 400.ms),
                      const SizedBox(height: 16),

                      // ── Search Bar ──
                      _SearchBar(
                        isDark: isDark,
                        onChanged: (v) => setState(() => _search = v),
                      ).animate().fadeIn(delay: 100.ms).slideY(begin: -0.05),
                      const SizedBox(height: 12),

                      // ── Category chips ──
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: SizedBox(
                          height: 46,
                          child: ListView(
                            clipBehavior: Clip.none,
                            scrollDirection: Axis.horizontal,
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
                      ).animate().fadeIn(delay: 150.ms),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),

              // ── List ──
              _filtered.isEmpty
                  ? SliverFillRemaining(
                      child: EmptyState(
                        icon: LucideIcons.megaphone,
                        message: _search.isEmpty ? 'Belum ada pengumuman' : 'Tidak ditemukan',
                        subtitle: _search.isEmpty ? 'Nantikan pengumuman dari sekolah' : 'Coba kata kunci lain',
                        color: AppTheme.amber,
                      ),
                    )
                  : SliverPadding(
                      padding: padding.copyWith(top: 0),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, i) {
                            final p = _filtered[i];
                            final isRead = _readIds.contains(p['id']?.toString());
                            return _PengumumanDetailCard(
                              pengumuman: p,
                              isDark: isDark,
                              index: i,
                              isRead: isRead,
                              onMarkRead: () => _markRead(p['id']?.toString() ?? ''),
                            );
                          },
                          childCount: _filtered.length,
                        ),
                      ),
                    ),
            ],
          );
        }),
      ),
    );
  }

  Widget _skeleton() {
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: 5,
      itemBuilder: (_, __) => const Padding(
        padding: EdgeInsets.only(bottom: 16),
        child: SkeletonLoader(height: 140, radius: 20),
      ),
    );
  }
}

// ─── Header ──────────────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  final bool isDark;
  final int count;
  final int unread;
  final bool showRead;
  final VoidCallback onToggleRead;
  final VoidCallback onMarkAll;
  const _Header({required this.isDark, required this.count, required this.unread,
      required this.showRead, required this.onToggleRead, required this.onMarkAll});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppTheme.amber, Color(0xFFF97316)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: AppTheme.amber.withAlpha(100), blurRadius: 16, offset: const Offset(0, 6))],
              ),
              child: const Icon(LucideIcons.megaphone, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Pengumuman Sekolah',
                      style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w800,
                          letterSpacing: -0.5, color: isDark ? Colors.white : AppTheme.textLight)),
                  Text(unread > 0 ? '$unread belum dibaca' : 'Semua sudah dibaca',
                      style: GoogleFonts.poppins(fontSize: 12,
                          color: isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            if (unread > 0)
              GestureDetector(
                onTap: onMarkAll,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.emerald.withAlpha(isDark ? 35 : 20),
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(color: AppTheme.emerald.withAlpha(isDark ? 70 : 50)),
                  ),
                  child: Row(children: [
                    const Icon(LucideIcons.checkCheck, size: 12, color: AppTheme.emerald),
                    const SizedBox(width: 5),
                    Text('Tandai Semua Dibaca',
                        style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.emerald)),
                  ]),
                ),
              ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onToggleRead,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.indigoPrimary.withAlpha(isDark ? 35 : 20),
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: AppTheme.indigoPrimary.withAlpha(isDark ? 70 : 50)),
                ),
                child: Row(children: [
                  Icon(showRead ? LucideIcons.eyeOff : LucideIcons.eye, size: 12, color: AppTheme.indigoPrimary),
                  const SizedBox(width: 5),
                  Text(showRead ? 'Sembunyikan Dibaca' : 'Tampilkan Semua',
                      style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.indigoPrimary)),
                ]),
              ),
            ),
          ],
        ),
      ],
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

// ─── Pengumuman Detail Card ───────────────────────────────────────────────────
class _PengumumanDetailCard extends StatelessWidget {
  final dynamic pengumuman;
  final bool isDark;
  final int index;
  final bool isRead;
  final VoidCallback onMarkRead;
  const _PengumumanDetailCard({
    required this.pengumuman, required this.isDark,
    required this.index, required this.isRead, required this.onMarkRead,
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
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                cfg.color.withAlpha(isDark ? 45 : 28),
                cfg.colorEnd.withAlpha(isDark ? 20 : 10),
              ]),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(19)),
              border: Border(bottom: BorderSide(color: cfg.color.withAlpha(isDark ? 40 : 25))),
            ),
            child: Row(
              children: [
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
                          style: GoogleFonts.poppins(fontWeight: FontWeight.w800, fontSize: 15,
                              letterSpacing: -0.3, color: isDark ? Colors.white : AppTheme.textLight),
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
              ],
            ),
          ),

          // ── Body ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(pengumuman['isi'] ?? '-',
                    style: GoogleFonts.poppins(fontSize: 13, height: 1.7,
                        color: isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt)),
                const SizedBox(height: 14),
                Divider(height: 1, color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (author != null) ...[
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppTheme.indigoPrimary.withAlpha(isDark ? 40 : 20),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(LucideIcons.user, size: 12, color: AppTheme.indigoPrimary),
                      ),
                      const SizedBox(width: 8),
                      Text('Oleh: $author',
                          style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.indigoPrimary)),
                    ],
                    const Spacer(),
                    if (!isRead)
                      GestureDetector(
                        onTap: onMarkRead,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppTheme.emerald.withAlpha(isDark ? 35 : 20),
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(color: AppTheme.emerald.withAlpha(isDark ? 70 : 50)),
                          ),
                          child: Row(children: [
                            const Icon(LucideIcons.check, size: 11, color: AppTheme.emerald),
                            const SizedBox(width: 4),
                            Text('Tandai Dibaca',
                                style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.emerald)),
                          ]),
                        ),
                      )
                    else
                      Row(children: [
                        Icon(LucideIcons.checkCheck, size: 11, color: isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt),
                        const SizedBox(width: 4),
                        Text('Dibaca', style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600,
                            color: isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt)),
                      ]),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    )
        .animate(delay: (index * 60).ms)
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.08, curve: Curves.easeOutQuart);
  }
}
