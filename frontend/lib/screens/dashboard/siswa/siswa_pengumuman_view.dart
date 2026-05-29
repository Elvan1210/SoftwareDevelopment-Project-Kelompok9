import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../config/api_config.dart';
import '../../../widgets/app_shell.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

// --- Tailwind Neo-Brutalist Tokens -----------------------------------------
const Color _onSurface = Color(0xFF001E2B);
const Color _onSurfaceVariant = Color(0xFF414944);
const Color _primary = Color(0xFF3D6754);
const Color _primaryContainer = Color(0xFFB7E5CD);
const Color _onPrimaryContainer = Color(0xFF3E6855);
const Color _secondary = Color(0xFF336763);
const Color _onSecondary = Color(0xFFFFFFFF);
const Color _secondaryContainer = Color(0xFFB7EDE7);
const Color _onSecondaryContainer = Color(0xFF3A6D69);
const Color _tertiaryContainer = Color(0xFFFFD1C0);
const Color _onTertiaryContainer = Color(0xFF8E4F34);
const Color _surfaceContainerLow = Color(0xFFE8F6FF);
const Color _outline = Color(0xFF717974);
const Color _outlineVariant = Color(0xFFC1C8C2);
const Color _background = Color(0xFFF4FAFF);

class SiswaPengumumanView extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String token;
  final dynamic teamData; // if accessed from a team/class dashboard
  final bool isGlobal; // true if accessed from main sidebar, false if from class dashboard

  const SiswaPengumumanView({
    super.key,
    required this.userData,
    required this.token,
    this.teamData,
    this.isGlobal = false,
  });

  @override
  State<SiswaPengumumanView> createState() => _SiswaPengumumanViewState();
}

class _SiswaPengumumanViewState extends State<SiswaPengumumanView> {
  List<dynamic> _pengumumanList = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedFilter = 'SEMUA';

  final List<String> _filters = ['SEMUA', 'UJIAN', 'LIBUR', 'SEMINAR', 'INFO'];

  @override
  void initState() {
    super.initState();
    _fetchPengumuman();
  }

  Future<void> _fetchPengumuman() async {
    setState(() => _isLoading = true);
    try {
      String url = '$baseUrl/api/pengumuman';
      if (!widget.isGlobal && widget.teamData != null) {
        url += '?kelas_id=${widget.teamData['id']}';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      if (response.statusCode == 200) {
        final dec = jsonDecode(response.body);
        List all = dec is List ? dec : [];
        setState(() => _pengumumanList = all);
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  List<dynamic> get _filtered {
    return _pengumumanList.where((p) {
      final text = ("${p['judul']} ${p['isi']} ${p['kategori']}").toLowerCase();
      final matchesSearch = _searchQuery.isEmpty || text.contains(_searchQuery.toLowerCase());
      final matchesFilter = _selectedFilter == 'SEMUA' || 
          (p['kategori']?.toString().toUpperCase() ?? 'INFO') == _selectedFilter;
      return matchesSearch && matchesFilter;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return _buildSkeleton();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: LayoutBuilder(
        builder: (ctx, constraints) {
          final isDesktop = constraints.maxWidth >= 768;
          final padding = Breakpoints.screenPadding(constraints.maxWidth);

          return RefreshIndicator(
            onRefresh: _fetchPengumuman,
            color: _primary,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.only(
                left: isDesktop ? 40 : 16,
                right: isDesktop ? 40 : 16,
                top: 32,
                bottom: 100,
              ),
              children: [
                // -- Header Section -------------------------------------------
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pengumuman',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: isDesktop ? 48 : 36,
                        fontWeight: FontWeight.w800,
                        color: _onSurface,
                        letterSpacing: -1.92,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Informasi akademik, jadwal kegiatan, dan berita penting lewat MyPSKD.',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w400,
                        color: _onSurfaceVariant,
                        height: 1.6,
                      ),
                    ),
                  ],
                ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1),
                const SizedBox(height: 40),

                // -- Search & Filter Bento Module ------------------------------
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: _onSurface, width: 1),
                    boxShadow: const [BoxShadow(color: _onSurface, offset: Offset(4, 4))],
                  ),
                  child: isDesktop 
                      ? Row(
                          children: [
                            Expanded(child: _buildSearchInput()),
                            const SizedBox(width: 16),
                            _buildFilterChips(),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSearchInput(),
                            const SizedBox(height: 16),
                            _buildFilterChips(),
                          ],
                        ),
                ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.05),
                const SizedBox(height: 32),

                // -- Utility Buttons -------------------------------------------
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _buildUtilityBtn(Icons.done_all, 'Tandai Semua Dibaca'),
                    const SizedBox(width: 16),
                    _buildUtilityBtn(Icons.visibility_off, 'Sembunyikan'),
                  ],
                ).animate().fadeIn(duration: 400.ms),
                const SizedBox(height: 32),

                // -- Bento Grid List -------------------------------------------
                if (_filtered.isEmpty)
                  _buildEmpty()
                else
                  _buildGrid(isDesktop),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchInput() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _onSurface, width: 1),
      ),
      child: TextField(
        onChanged: (val) => setState(() => _searchQuery = val),
        style: GoogleFonts.inter(fontWeight: FontWeight.w400, fontSize: 16, color: _onSurface),
        decoration: InputDecoration(
          hintText: 'Cari informasi atau pengumuman...',
          hintStyle: GoogleFonts.inter(fontWeight: FontWeight.w400, fontSize: 16, color: _outline),
          prefixIcon: const Icon(Icons.search, size: 24, color: _onSurfaceVariant),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _filters.map((f) {
          final isSelected = _selectedFilter == f;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () => setState(() => _selectedFilter = f),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  color: isSelected ? _onSurface : Colors.white,
                  border: Border.all(color: _onSurface, width: 1),
                ),
                child: Text(
                  f,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    letterSpacing: 0.6,
                    color: isSelected ? _background : _onSurface,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildUtilityBtn(IconData icon, String label) {
    return _NeoHoverButton(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: _onSurface, width: 1),
          boxShadow: const [BoxShadow(color: _onSurface, offset: Offset(4, 4))],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: _onSurface),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 12, letterSpacing: 0.6, color: _onSurface),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrid(bool isDesktop) {
    if (isDesktop) {
      return LayoutBuilder(
        builder: (ctx, constraints) {
          final totalWidth = constraints.maxWidth;
          final gap = 20.0;
          final colWidth = (totalWidth - (2 * gap)) / 12;

          List<Widget> rows = [];
          for (int i = 0; i < _filtered.length; i++) {
            if (i == 0) {
              // Big Hero Card (span 8) + optionally Side Card 1 (span 4)
              Widget hero = SizedBox(
                width: (colWidth * 8) + (gap * 7),
                child: _HeroCard(data: _filtered[i]),
              );
              if (_filtered.length > 1) {
                Widget side = SizedBox(
                  width: (colWidth * 4) + (gap * 3),
                  child: _SideCard(data: _filtered[i + 1]),
                );
                rows.add(Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [hero, const SizedBox(width: 20), side]));
                i++; // skip next since we rendered it
              } else {
                rows.add(Row(children: [hero]));
              }
            } else {
              // Row of 3 Side Cards (span 4 each)
              List<Widget> rowItems = [];
              for (int j = 0; j < 3; j++) {
                if (i + j < _filtered.length) {
                  rowItems.add(
                    SizedBox(
                      width: (colWidth * 4) + (gap * 3),
                      child: _SideCard(data: _filtered[i + j]),
                    ),
                  );
                  if (j < 2) rowItems.add(const SizedBox(width: 20));
                }
              }
              rows.add(Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: rowItems));
              i += 2; // advance loop
            }
            rows.add(const SizedBox(height: 20));
          }
          return Column(children: rows);
        },
      );
    } else {
      // Mobile: everything is full width
      return Column(
        children: List.generate(_filtered.length, (i) {
          final item = _filtered[i];
          return Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: i == 0 ? _HeroCard(data: item) : _SideCard(data: item),
          );
        }),
      );
    }
  }

  Widget _buildEmpty() {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: _onSurface, width: 1),
          boxShadow: const [BoxShadow(color: _onSurface, offset: Offset(4, 4))],
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _surfaceContainerLow,
              shape: BoxShape.circle,
              border: Border.all(color: _onSurface, width: 1),
            ),
            child: const Icon(LucideIcons.bellOff, color: _onSurface, size: 32),
          ),
          const SizedBox(height: 20),
          Text(
            'Belum ada pengumuman.',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 24, color: _onSurface),
          ),
          const SizedBox(height: 8),
          Text(
            'Pengumuman dan informasi terbaru akan muncul di sini.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 16, color: _onSurfaceVariant, fontWeight: FontWeight.w400),
          ),
        ]),
      ),
    );
  }

  Widget _buildSkeleton() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SkeletonLoader(height: 60, width: 300),
          const SizedBox(height: 40),
          const SkeletonLoader(height: 100),
          const SizedBox(height: 40),
          const SkeletonLoader(height: 250),
        ],
      ),
    );
  }
}

// -- Hero Card (Span 8) ---------------------------------------------------
class _HeroCard extends StatelessWidget {
  final dynamic data;
  const _HeroCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final cat = (data['kategori']?.toString().toUpperCase() ?? 'INFO');
    final date = _formatDate(data['created_at']);
    
    return _NeoHoverCard(
      child: Container(
        padding: const EdgeInsets.all(32), // p-8
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: _onSurface, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: _secondary,
                border: Border.all(color: _onSurface, width: 1),
              ),
              child: Text(
                cat,
                style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 12, letterSpacing: 0.6, color: _onSecondary),
              ),
            ),
            Text(
              data['judul'] ?? 'Tanpa Judul',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 24, height: 1.3, color: _onSurface),
            ),
            const SizedBox(height: 16),
            Text(
              data['isi'] ?? '',
              style: GoogleFonts.inter(fontWeight: FontWeight.w400, fontSize: 16, height: 1.6, color: _onSurfaceVariant),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.only(top: 24),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: _outlineVariant)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.person, size: 18, color: _outline),
                      const SizedBox(width: 8),
                      Text(
                        'Oleh: Admin Sekolah',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 12, letterSpacing: 0.6, color: _outline),
                      ),
                    ],
                  ),
                  Text(
                    date,
                    style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 12, letterSpacing: 0.6, color: _outline),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -- Side Card (Span 4) ---------------------------------------------------
class _SideCard extends StatelessWidget {
  final dynamic data;
  const _SideCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final cat = (data['kategori']?.toString().toUpperCase() ?? 'INFO');
    final date = _formatDate(data['created_at']);
    
    Color bg = Colors.white;
    Color badgeBg = _primaryContainer;
    Color badgeText = _onPrimaryContainer;

    if (cat == 'LIBUR') {
      badgeBg = _tertiaryContainer;
      badgeText = _onTertiaryContainer;
    } else if (cat == 'SEMINAR') {
      bg = _secondaryContainer;
      badgeBg = _secondary;
      badgeText = _onSecondary;
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        _NeoHoverCard(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32), // p-8
            decoration: BoxDecoration(
              color: bg,
              border: Border.all(color: _onSurface, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  date,
                  style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 12, letterSpacing: 0.6, color: _outline),
                ),
                const SizedBox(height: 16),
                Text(
                  data['judul'] ?? 'Tanpa Judul',
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 20, height: 1.4, color: _onSurface),
                ),
                const SizedBox(height: 16),
                Text(
                  data['isi'] ?? '',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w400, fontSize: 14, height: 1.5, color: cat == 'SEMINAR' ? _onSecondaryContainer.withAlpha(204) : _onSurfaceVariant),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
        Positioned(
          top: -12,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: badgeBg,
              border: Border.all(color: _onSurface, width: 1),
            ),
            child: Text(
              cat,
              style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 12, letterSpacing: 0.6, color: badgeText),
            ),
          ),
        ),
      ],
    );
  }
}

// -- Hover Components -------------------------------------------------------
class _NeoHoverCard extends StatefulWidget {
  final Widget child;
  const _NeoHoverCard({required this.child});
  @override
  State<_NeoHoverCard> createState() => _NeoHoverCardState();
}

class _NeoHoverCardState extends State<_NeoHoverCard> {
  bool _isPressed = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        transform: Matrix4.translationValues(
          _isPressed ? 2 : 0,
          _isPressed ? 2 : 0,
          0,
        ),
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: _onSurface,
              offset: _isPressed ? const Offset(2, 2) : const Offset(4, 4),
              blurRadius: 0,
            )
          ],
        ),
        child: widget.child,
      ),
    );
  }
}

class _NeoHoverButton extends StatefulWidget {
  final Widget child;
  const _NeoHoverButton({required this.child});
  @override
  State<_NeoHoverButton> createState() => _NeoHoverButtonState();
}

class _NeoHoverButtonState extends State<_NeoHoverButton> {
  bool _isHover = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHover = true),
      onExit: (_) => setState(() => _isHover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        transform: Matrix4.translationValues(
          _isHover ? 1 : 0,
          _isHover ? 1 : 0,
          0,
        ),
        child: widget.child,
      ),
    );
  }
}

String _formatDate(String? iso) {
  if (iso == null) return '-';
  try {
    return DateFormat('dd MMM yyyy').format(DateTime.parse(iso)).toUpperCase();
  } catch (_) {
    return iso.toUpperCase();
  }
}
