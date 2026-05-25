import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../config/api_config.dart';
import '../../../config/theme.dart';
import '../../../widgets/app_shell.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../utils/date_utils.dart';

class _KategoriConfig {
  final String label;
  final IconData icon;
  final Color color;
  final Color colorEnd;
  _KategoriConfig(
      {required this.label,
      required this.icon,
      required this.color,
      required this.colorEnd});
}

final _kategoriMap = {
  'Semua': _KategoriConfig(
      label: 'Semua',
      icon: LucideIcons.layoutGrid,
      color: AppTheme.indigoPrimary,
      colorEnd: AppTheme.primary),
  'Ujian': _KategoriConfig(
      label: 'Ujian',
      icon: LucideIcons.clipboardList,
      color: AppTheme.amber,
      colorEnd: const Color(0xFFF97316)),
  'Libur': _KategoriConfig(
      label: 'Libur',
      icon: LucideIcons.palmtree,
      color: AppTheme.emerald,
      colorEnd: const Color(0xFF059669)),
  'Seminar': _KategoriConfig(
      label: 'Seminar',
      icon: LucideIcons.presentation,
      color: AppTheme.sky,
      colorEnd: const Color(0xFF0EA5E9)),
  'Umum': _KategoriConfig(
      label: 'Umum',
      icon: LucideIcons.megaphone,
      color: const Color(0xFF8B5CF6),
      colorEnd: const Color(0xFF7C3AED)),
};

_KategoriConfig _getKategori(String? kategoriField) {
  if (kategoriField != null && _kategoriMap.containsKey(kategoriField)) {
    return _kategoriMap[kategoriField]!;
  }
  return _kategoriMap['Umum']!;
}

class SiswaPengumumanView extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String token;
  const SiswaPengumumanView(
      {super.key, required this.userData, required this.token});

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
    final list =
        prefs.getStringList('read_pengumuman_${widget.userData['id']}') ?? [];
    _readIds = list.toSet();
    await _fetchPengumuman();
  }

  Future<void> _markRead(String id) async {
    setState(() => _readIds.add(id));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        'read_pengumuman_${widget.userData['id']}', _readIds.toList());
  }

  Future<void> _markAllRead() async {
    final allIds =
        _pengumumanList.map((p) => p['id']?.toString() ?? '').toSet();
    setState(() => _readIds.addAll(allIds));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        'read_pengumuman_${widget.userData['id']}', _readIds.toList());
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
          final aDate =
              AppDateUtils.parseIndonesianDate(a['tanggal']?.toString() ?? '');
          final bDate =
              AppDateUtils.parseIndonesianDate(b['tanggal']?.toString() ?? '');
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
        : _pengumumanList
            .where((p) => !_readIds.contains(p['id']?.toString()))
            .toList();
    if (_selectedKategori != 'Semua') {
      base = base
          .where((p) =>
              _getKategori(p['kategori']?.toString()).label ==
              _selectedKategori)
          .toList();
    }
    if (_search.isEmpty) return base;
    final q = _search.toLowerCase();
    return base
        .where((p) =>
            (p['judul'] ?? '').toLowerCase().contains(q) ||
            (p['isi'] ?? '').toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return _skeleton();
    }

    return RefreshIndicator(
      onRefresh: _fetchPengumuman,
      color: AppTheme.amber,
      child: LayoutBuilder(builder: (ctx, c) {
        final w = c.maxWidth;
        final isWide = w >= 950;
        final padVal = isWide ? 40.0 : 24.0;
        final padding = EdgeInsets.symmetric(horizontal: padVal, vertical: 24);

        return CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: padding.copyWith(bottom: 0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Header(
                      isDark: isDark,
                      count: _filtered.length,
                      unread: _pengumumanList
                          .where((p) => !_readIds.contains(p['id']?.toString()))
                          .length,
                      showRead: _showRead,
                      onToggleRead: () =>
                          setState(() => _showRead = !_showRead),
                      onMarkAll: _markAllRead,
                    ).animate().fadeIn(duration: 400.ms),
                    const SizedBox(height: 18),
                    _SearchBar(
                      isDark: isDark,
                      onChanged: (v) => setState(() => _search = v),
                    ).animate().fadeIn(delay: 100.ms).slideY(begin: -0.05),
                    const SizedBox(height: 14),
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
                                onTap: () =>
                                    setState(() => _selectedKategori = k),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: selected
                                        ? cfg.color
                                        : cfg.color.withAlpha(20),
                                    borderRadius: BorderRadius.circular(100),
                                    border: Border.all(
                                      color: selected
                                          ? cfg.color
                                          : cfg.color.withAlpha(60),
                                      width: 1.2,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(cfg.icon,
                                          size: 13,
                                          color: selected
                                              ? Colors.white
                                              : cfg.color),
                                      const SizedBox(width: 6),
                                      Text(cfg.label,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyLarge
                                              ?.copyWith(
                                                  fontWeight: FontWeight.w700,
                                                  color: selected
                                                      ? Colors.white
                                                      : cfg.color)),
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
            _filtered.isEmpty
                ? SliverFillRemaining(
                    child: EmptyState(
                      icon: LucideIcons.megaphone,
                      message: _search.isEmpty
                          ? 'Belum ada pengumuman'
                          : 'Tidak ditemukan',
                      subtitle: _search.isEmpty
                          ? 'Nantikan pengumuman dari sekolah'
                          : 'Coba kata kunci lain',
                      color: AppTheme.amber,
                    ),
                  )
                : SliverPadding(
                    padding: padding.copyWith(top: 0),
                    sliver: SliverToBoxAdapter(
                      child: isWide
                          ? Wrap(
                              spacing: 16,
                              runSpacing: 16,
                              children: List.generate(_filtered.length, (i) {
                                final p = _filtered[i];
                                final isRead =
                                    _readIds.contains(p['id']?.toString());
                                final colCount = w >= 1200 ? 3 : 2;
                                final cardW =
                                    (w - padVal * 2 - (16 * (colCount - 1))) /
                                        colCount;

                                return SizedBox(
                                  width: cardW,
                                  child: _PengumumanDetailCard(
                                    pengumuman: p,
                                    isDark: isDark,
                                    index: i,
                                    isRead: isRead,
                                    onMarkRead: () =>
                                        _markRead(p['id']?.toString() ?? ''),
                                  ),
                                );
                              }),
                            )
                          : Column(
                              children: List.generate(_filtered.length, (i) {
                                final p = _filtered[i];
                                final isRead =
                                    _readIds.contains(p['id']?.toString());
                                return _PengumumanDetailCard(
                                  pengumuman: p,
                                  isDark: isDark,
                                  index: i,
                                  isRead: isRead,
                                  onMarkRead: () =>
                                      _markRead(p['id']?.toString() ?? ''),
                                );
                              }),
                            ),
                    ),
                  ),
          ],
        );
      }),
    );
  }

  Widget _skeleton() {
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth;
      final isWide = w >= 950;
      final padVal = isWide ? 40.0 : 24.0;
      final padding = EdgeInsets.symmetric(horizontal: padVal, vertical: 24);

      return SingleChildScrollView(
        padding: padding,
        child: isWide
            ? Wrap(
                spacing: 16,
                runSpacing: 16,
                children: List.generate(4, (index) {
                  final colCount = w >= 1200 ? 3 : 2;
                  final cardW =
                      (w - padVal * 2 - (16 * (colCount - 1))) / colCount;
                  return SkeletonLoader(width: cardW, height: 180, radius: 24);
                }),
              )
            : Column(
                children: List.generate(
                    4,
                    (_) => const Padding(
                          padding: EdgeInsets.only(bottom: 16),
                          child: SkeletonLoader(height: 180, radius: 24),
                        )),
              ),
      );
    });
  }
}

class _Header extends StatelessWidget {
  final bool isDark;
  final int count;
  final int unread;
  final bool showRead;
  final VoidCallback onToggleRead;
  final VoidCallback onMarkAll;
  const _Header(
      {required this.isDark,
      required this.count,
      required this.unread,
      required this.showRead,
      required this.onToggleRead,
      required this.onMarkAll});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // Icon box — rounded amber container, no black border/shadow
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.amber,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.amber.withAlpha(60),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(LucideIcons.megaphone,
                  color: Colors.white, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Pengumuman Sekolah',
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                          color: AppTheme.textLight)),
                  const SizedBox(height: 2),
                  Text(
                      unread > 0
                          ? '$unread belum dibaca'
                          : 'Semua sudah dibaca',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textMutedLt)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            if (unread > 0)
              GestureDetector(
                onTap: onMarkAll,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  constraints: const BoxConstraints(minHeight: 44),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppTheme.emerald,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.emerald.withAlpha(60),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(LucideIcons.checkCheck,
                          size: 14, color: Colors.white),
                      const SizedBox(width: 6),
                      Text('Tandai Semua Dibaca',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white)),
                    ],
                  ),
                ),
              ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onToggleRead,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                constraints: const BoxConstraints(minHeight: 44),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withAlpha(15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppTheme.primary.withAlpha(60), width: 1.2),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(showRead ? LucideIcons.eyeOff : LucideIcons.eye,
                        size: 14, color: AppTheme.primary),
                    const SizedBox(width: 6),
                    Text(showRead ? 'Sembunyikan Dibaca' : 'Tampilkan Semua',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primary)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SearchBar extends StatelessWidget {
  final bool isDark;
  final ValueChanged<String> onChanged;
  const _SearchBar({required this.isDark, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 48),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.lightBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(15),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        onChanged: onChanged,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppTheme.textLight, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          hintText: 'Cari pengumuman...',
          hintStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.textMutedLt, fontWeight: FontWeight.w500),
          prefixIcon: const Icon(LucideIcons.search,
              size: 16, color: AppTheme.textMutedLt),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}

class _PengumumanDetailCard extends StatelessWidget {
  final dynamic pengumuman;
  final bool isDark;
  final int index;
  final bool isRead;
  final VoidCallback onMarkRead;
  const _PengumumanDetailCard({
    required this.pengumuman,
    required this.isDark,
    required this.index,
    required this.isRead,
    required this.onMarkRead,
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
    final cfg = _getKategori(pengumuman['kategori']?.toString());

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.lightBorder, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(15),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Colored header band — rounded top corners only
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: cfg.color,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  // Icon box — rounded, colored bg, white icon
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(30),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(cfg.icon, color: Colors.white, size: 14),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Kategori pill label
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(30),
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Text(cfg.label.toUpperCase(),
                              style: Theme.of(context)
                                  .textTheme
                                  .labelLarge
                                  ?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                      letterSpacing: 0.8)),
                        ),
                        const SizedBox(height: 6),
                        Text(pengumuman['judul'] ?? '-',
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  if (tanggal.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    // Date chip — pill, white background
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(30),
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(
                            color: Colors.white.withAlpha(60), width: 1),
                      ),
                      child: Text(tanggal,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white)),
                    ),
                  ],
                ],
              ),
            ),
            // Body content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(pengumuman['isi'] ?? '-',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          height: 1.6,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textMutedLt)),
                  const SizedBox(height: 16),
                  const Divider(
                      height: 1,
                      color: AppTheme.lightBorder,
                      thickness: 1),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (author != null) ...[
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withAlpha(15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(LucideIcons.user,
                              size: 10, color: AppTheme.primary),
                        ),
                        const SizedBox(width: 8),
                        Text('Oleh: $author',
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textLight)),
                      ],
                      const Spacer(),
                      if (!isRead)
                        GestureDetector(
                          onTap: onMarkRead,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            constraints: const BoxConstraints(minHeight: 44),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppTheme.emerald,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.emerald.withAlpha(60),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                              const Icon(LucideIcons.check,
                                  size: 14, color: Colors.white),
                              const SizedBox(width: 6),
                              Text('Tandai Dibaca',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white)),
                            ]),
                          ),
                        )
                      else
                        Container(
                          constraints: const BoxConstraints(minHeight: 44),
                          alignment: Alignment.center,
                          child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                            const Icon(LucideIcons.checkCheck,
                                size: 14, color: AppTheme.emerald),
                            const SizedBox(width: 6),
                            Text('Dibaca',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.emerald)),
                          ]),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    )
        .animate(delay: (index * 60).ms)
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.08, curve: Curves.easeOutQuart);
  }
}
