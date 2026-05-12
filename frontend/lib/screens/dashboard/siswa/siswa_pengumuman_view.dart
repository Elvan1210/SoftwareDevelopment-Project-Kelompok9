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
  String _search  = '';
  Set<String> _readIds = {};
  bool _showRead = false;

  @override
  void initState() {
    super.initState();
    _loadAndFetch();
  }

  Future<void> _loadAndFetch() async {
    final prefs = await SharedPreferences.getInstance();
    final list  = prefs.getStringList('read_pengumuman_${widget.userData['id']}') ?? [];
    _readIds = list.toSet();
    await _fetchPengumuman();
  }

  Future<void> _markRead(String id) async {
    setState(() => _readIds.add(id));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'read_pengumuman_${widget.userData['id']}',
      _readIds.toList(),
    );
  }

  Future<void> _markAllRead() async {
    final allIds = _pengumumanList.map((p) => p['id']?.toString() ?? '').toSet();
    setState(() => _readIds.addAll(allIds));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'read_pengumuman_${widget.userData['id']}',
      _readIds.toList(),
    );
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
        setState(() => _pengumumanList = decoded is List ? decoded : []);
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  List<dynamic> get _filtered {
    final base = _showRead
        ? _pengumumanList
        : _pengumumanList.where((p) => !_readIds.contains(p['id']?.toString())).toList();
    if (_search.isEmpty) return base;
    final q = _search.toLowerCase();
    return base.where((p) {
      return (p['judul'] ?? '').toLowerCase().contains(q) ||
             (p['isi']   ?? '').toLowerCase().contains(q);
    }).toList();
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
          final w       = c.maxWidth;
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
                      // ── Header ────────────────────────────────────
                      _Header(isDark: isDark, count: _filtered.length,
                        unread: _pengumumanList.where((p) => !_readIds.contains(p['id']?.toString())).length,
                        showRead: _showRead,
                        onToggleRead: () => setState(() => _showRead = !_showRead),
                        onMarkAll: _markAllRead,
                      ).animate().fadeIn(duration: 400.ms),
                      const SizedBox(height: 16),

                      // ── Search Bar ────────────────────────────────
                      _SearchBar(
                        isDark: isDark,
                        onChanged: (v) => setState(() => _search = v),
                      ).animate().fadeIn(delay: 100.ms).slideY(begin: -0.05),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),

              // ── List ──────────────────────────────────────────────
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
              width: 48, height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.amber, Color(0xFFF97316)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(color: AppTheme.amber.withAlpha(100), blurRadius: 16, offset: const Offset(0, 6)),
                ],
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
        // Action row
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
                    Icon(LucideIcons.checkCheck, size: 12, color: AppTheme.emerald),
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
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 40 : 6),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        onChanged: onChanged,
        style: GoogleFonts.poppins(fontSize: 14,
          color: isDark ? Colors.white : AppTheme.textLight),
        decoration: InputDecoration(
          hintText: 'Cari pengumuman...',
          hintStyle: GoogleFonts.poppins(fontSize: 13,
            color: isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt),
          prefixIcon: Icon(LucideIcons.search, size: 18,
            color: isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt),
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
    final author  = pengumuman['author']?.toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.amber.withAlpha(isDark ? 45 : 30),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 60 : 8),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top colored band ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.amber.withAlpha(isDark ? 35 : 20),
                  AppTheme.amber.withAlpha(isDark ? 15 : 8),
                ],
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(19)),
              border: Border(bottom: BorderSide(
                color: AppTheme.amber.withAlpha(isDark ? 40 : 25),
              )),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.amber, Color(0xFFF97316)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(color: AppTheme.amber.withAlpha(80), blurRadius: 8, offset: const Offset(0, 3)),
                    ],
                  ),
                  child: const Icon(LucideIcons.megaphone, color: Colors.white, size: 16),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    pengumuman['judul'] ?? '-',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      letterSpacing: -0.3,
                      color: isDark ? Colors.white : AppTheme.textLight,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (tanggal.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.amber.withAlpha(isDark ? 35 : 20),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      tanggal,
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.amber,
                      ),
                    ),
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
                Text(
                  pengumuman['isi'] ?? '-',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    height: 1.7,
                    color: isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt,
                  ),
                ),
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
                        child: Icon(LucideIcons.user, size: 12, color: AppTheme.indigoPrimary),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Oleh: $author',
                        style: GoogleFonts.poppins(
                          fontSize: 12, fontWeight: FontWeight.w600,
                          color: AppTheme.indigoPrimary,
                        ),
                      ),
                    ],
                    const Spacer(),
                    // Mark as read button
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
                            Icon(LucideIcons.check, size: 11, color: AppTheme.emerald),
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
                        Text('Dibaca',
                            style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600,
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

