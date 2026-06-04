import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../config/api_config.dart';
import '../../../widgets/app_shell.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'siswa_tugas_detail_screen.dart';

// ── Design tokens ────────────────────────────────────────────────────────────
const Color _ink = Color(0xFF001E2B);
const Color _inkMuted = Color(0xFF4B6459);
const Color _primary = Color(0xFF3D6754);
const Color _primaryLight = Color(0xFFC0E5CB);
const Color _secondaryLight = Color(0xFFB7EDE7);
const Color _tertiaryLight = Color(0xFFFFD1C0);
const Color _skyLight = Color(0xFFC1E8FF);
const Color _white = Colors.white;
const Color _errorRed = Color(0xFFD32F2F);
const Color _successGreen = Color(0xFF2E7D52);

class SiswaTugasView extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String token;
  final dynamic teamData;
  final bool isGlobal;

  const SiswaTugasView({
    super.key,
    required this.userData,
    required this.token,
    this.teamData,
    this.isGlobal = false,
  });

  @override
  State<SiswaTugasView> createState() => _SiswaTugasViewState();
}

class _SiswaTugasViewState extends State<SiswaTugasView> {
  List<dynamic> _tugasList = [];
  bool _isLoading = true;
  String _selectedFilter = 'Semua';

  final List<String> _filters = ['Semua', 'Belum', 'Selesai'];

  @override
  void initState() {
    super.initState();
    _fetchAll();
  }

  // ── Fetch tugas + pengumpulan, lalu merge status sudah_kumpul ───────────
  Future<void> _fetchAll() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      String tugasUrl = '$baseUrl/api/tugas';
      if (!widget.isGlobal && widget.teamData != null) {
        tugasUrl += '?kelas_id=${widget.teamData['id']}';
      }

      final results = await Future.wait([
        http.get(Uri.parse(tugasUrl),
            headers: {'Authorization': 'Bearer ${widget.token}'}),
        http.get(Uri.parse('$baseUrl/api/pengumpulan'),
            headers: {'Authorization': 'Bearer ${widget.token}'}),
      ]);

      if (results[0].statusCode == 200) {
        final List tugasList =
            (jsonDecode(results[0].body) is List) ? jsonDecode(results[0].body) : [];

        Set<String> submittedTugasIds = {};
        if (results[1].statusCode == 200) {
          final List pengumpulanList =
              (jsonDecode(results[1].body) is List) ? jsonDecode(results[1].body) : [];
          final siswId = widget.userData['id']?.toString() ?? '';
          submittedTugasIds = pengumpulanList
              .where((p) => p['siswa_id']?.toString() == siswId)
              .map((p) => p['tugas_id']?.toString() ?? '')
              .toSet();
        }

        // Merge flag sudah_kumpul berdasarkan data pengumpulan
        final merged = tugasList.map((t) {
          final id = (t['id'] ?? '').toString();
          return {
            ...Map<String, dynamic>.from(t),
            'sudah_kumpul': submittedTugasIds.contains(id),
          };
        }).toList();

        if (mounted) setState(() => _tugasList = merged);
      }
    } catch (e) {
      debugPrint('Error fetchAll: $e');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  List<dynamic> get _filtered {
    return _tugasList.where((t) {
      final isDone = t['sudah_kumpul'] == true;
      if (_selectedFilter == 'Semua') return true;
      if (_selectedFilter == 'Belum') return !isDone;
      if (_selectedFilter == 'Selesai') return isDone;
      return true;
    }).toList();
  }

  void _openDetail(dynamic tugas) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SiswaTugasDetailScreen(
          tugas: tugas,
          token: widget.token,
          userData: widget.userData,
        ),
      ),
    ).then((_) => _fetchAll());
  }

  // ── Count helpers ─────────────────────────────────────────────────────────
  int get _doneCount => _tugasList.where((t) => t['sudah_kumpul'] == true).length;
  int get _totalCount => _tugasList.length;

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return _buildSkeleton();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: LayoutBuilder(
        builder: (ctx, constraints) {
          final isDesktop = constraints.maxWidth >= 768;
          final hPad = isDesktop ? 40.0 : 16.0;

          return RefreshIndicator(
            onRefresh: _fetchAll,
            color: _primary,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics()),
              slivers: [
                // ── HEADER ──────────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(hPad, 36, hPad, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Label pill
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 5),
                          decoration: BoxDecoration(
                            color: _primaryLight,
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(color: _ink, width: 2),
                            boxShadow: const [
                              BoxShadow(color: _ink, offset: Offset(2, 2))
                            ],
                          ),
                          child: Text(
                            'TUGAS KELAS',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                              color: _primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Daftar\nTugas',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: isDesktop ? 52 : 40,
                            fontWeight: FontWeight.w900,
                            color: _ink,
                            letterSpacing: -2,
                            height: 1.05,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Progress bar
                        if (_totalCount > 0) ...[
                          Row(
                            children: [
                              Text(
                                '$_doneCount/$_totalCount selesai',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: _inkMuted,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '${(_doneCount / _totalCount * 100).round()}%',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                  color: _primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          LayoutBuilder(builder: (ctx, c) {
                            final frac = _doneCount / _totalCount;
                            return Container(
                              height: 10,
                              decoration: BoxDecoration(
                                color: _primaryLight,
                                borderRadius: BorderRadius.circular(100),
                                border: Border.all(color: _ink, width: 1.5),
                              ),
                              child: FractionallySizedBox(
                                widthFactor: frac,
                                alignment: Alignment.centerLeft,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: _primary,
                                    borderRadius: BorderRadius.circular(100),
                                  ),
                                ),
                              ),
                            );
                          }),
                          const SizedBox(height: 28),
                        ],

                        // Filter tabs
                        _buildFilterTabs(),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.08),
                ),

                // ── LIST ─────────────────────────────────────────────────
                if (_filtered.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: hPad),
                      child: _buildEmpty(),
                    ),
                  )
                else if (isDesktop)
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 80),
                    sliver: _buildDesktopGrid(),
                  )
                else
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 80),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (ctx, i) => Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: _TaskCardNeo(
                            tugas: _filtered[i],
                            index: i,
                            onTap: () => _openDetail(_filtered[i]),
                          )
                              .animate(delay: (i * 60).ms)
                              .fadeIn(duration: 350.ms)
                              .slideY(begin: 0.1),
                        ),
                        childCount: _filtered.length,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Desktop grid (2 columns) ──────────────────────────────────────────────
  Widget _buildDesktopGrid() {
    final List<Widget> pairs = [];
    for (int i = 0; i < _filtered.length; i += 2) {
      pairs.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _TaskCardNeo(
                    tugas: _filtered[i],
                    index: i,
                    onTap: () => _openDetail(_filtered[i]),
                  ).animate(delay: (i * 60).ms).fadeIn().slideY(begin: 0.1),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: i + 1 < _filtered.length
                      ? _TaskCardNeo(
                          tugas: _filtered[i + 1],
                          index: i + 1,
                          onTap: () => _openDetail(_filtered[i + 1]),
                        )
                          .animate(delay: ((i + 1) * 60).ms)
                          .fadeIn()
                          .slideY(begin: 0.1)
                      : const SizedBox(),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return SliverList(delegate: SliverChildListDelegate(pairs));
  }

  // ── Filter tabs ───────────────────────────────────────────────────────────
  Widget _buildFilterTabs() {
    // Count per filter
    final int totalAll = _tugasList.length;
    final int totalBelum =
        _tugasList.where((t) => t['sudah_kumpul'] != true).length;
    final int totalSelesai =
        _tugasList.where((t) => t['sudah_kumpul'] == true).length;
    final counts = {'Semua': totalAll, 'Belum': totalBelum, 'Selesai': totalSelesai};

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: _filters.map((f) {
          final isSelected = _selectedFilter == f;
          final count = counts[f] ?? 0;
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: GestureDetector(
              onTap: () => setState(() => _selectedFilter = f),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                transform: Matrix4.translationValues(
                    isSelected ? 2 : 0, isSelected ? 2 : 0, 0),
                decoration: BoxDecoration(
                  color: isSelected ? _primary : _white,
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: _ink, width: 2),
                  boxShadow: isSelected
                      ? []
                      : const [BoxShadow(color: _ink, offset: Offset(2, 2))],
                ),
                child: Row(
                  children: [
                    Text(
                      f.toUpperCase(),
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        letterSpacing: 0.6,
                        color: isSelected ? _white : _ink,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? _white.withValues(alpha: 0.25)
                            : _primaryLight,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        '$count',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                          color: isSelected ? _white : _primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Empty state ───────────────────────────────────────────────────────────
  Widget _buildEmpty() {
    final msg = _selectedFilter == 'Selesai'
        ? 'Belum ada tugas yang\ndiselesaikan.'
        : _selectedFilter == 'Belum'
            ? 'Semua tugas sudah\ndiselesaikan! 🎉'
            : 'Belum ada tugas\ndi kelas ini.';

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 40),
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 28),
        decoration: BoxDecoration(
          color: _white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _ink, width: 2),
          boxShadow: const [BoxShadow(color: _ink, offset: Offset(4, 4))],
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: _primaryLight,
              shape: BoxShape.circle,
              border: Border.all(color: _ink, width: 2),
            ),
            child: const Icon(LucideIcons.fileQuestion, color: _ink, size: 32),
          ),
          const SizedBox(height: 20),
          Text(
            msg,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w800, fontSize: 22, color: _ink),
          ),
          const SizedBox(height: 8),
          Text(
            'Tarik ke bawah untuk memuat ulang.',
            style: GoogleFonts.inter(
                fontSize: 14, color: _inkMuted, fontWeight: FontWeight.w500),
          ),
        ]),
      ),
    );
  }

  // ── Skeleton ──────────────────────────────────────────────────────────────
  Widget _buildSkeleton() {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SkeletonLoader(height: 20, width: 120, radius: 12),
            const SizedBox(height: 12),
            const SkeletonLoader(height: 56, width: 220, radius: 12),
            const SizedBox(height: 24),
            const SkeletonLoader(height: 12, radius: 12),
            const SizedBox(height: 24),
            const Row(
              children: [
                SkeletonLoader(height: 38, width: 90, radius: 100),
                SizedBox(width: 10),
                SkeletonLoader(height: 38, width: 90, radius: 100),
                SizedBox(width: 10),
                SkeletonLoader(height: 38, width: 90, radius: 100),
              ],
            ),
            const SizedBox(height: 32),
            Expanded(
              child: ListView.builder(
                itemCount: 3,
                itemBuilder: (_, __) => const Padding(
                  padding: EdgeInsets.only(bottom: 20),
                  child: SkeletonLoader(height: 180, radius: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Task Card Neo ─────────────────────────────────────────────────────────────
class _TaskCardNeo extends StatefulWidget {
  final dynamic tugas;
  final int index;
  final VoidCallback onTap;

  const _TaskCardNeo(
      {required this.tugas, required this.index, required this.onTap});

  @override
  State<_TaskCardNeo> createState() => _TaskCardNeoState();
}

class _TaskCardNeoState extends State<_TaskCardNeo> {
  bool _isPressed = false;
  bool _isHovering = false;

  static const _cardPalette = [
    _primaryLight,   // hijau pastel
    _secondaryLight, // teal pastel
    _tertiaryLight,  // peach pastel
    _skyLight,       // biru pastel
  ];

  String _formatDate(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    try {
      return DateFormat('dd MMM yyyy, HH:mm').format(DateTime.parse(iso));
    } catch (_) {
      return iso;
    }
  }

  bool _isOverdue(String? iso) {
    if (iso == null || iso.isEmpty) return false;
    try {
      return DateTime.parse(iso).isBefore(DateTime.now());
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDone = widget.tugas['sudah_kumpul'] == true;
    final deadline = widget.tugas['deadline']?.toString() ??
        widget.tugas['tenggat_waktu']?.toString();
    final hasDeadline = deadline != null && deadline.isNotEmpty;
    final isOverdue = !isDone && hasDeadline && _isOverdue(deadline);

    final guruNama = widget.tugas['guru_nama']?.toString() ?? 'Guru';
    final tipeTugas = widget.tugas['tipe_tugas']?.toString() ?? 'Individu';
    final bgColor = _cardPalette[widget.index % _cardPalette.length];

    // Status badge
    final Color badgeBg;
    final Color badgeText;
    final String badgeLabel;
    final IconData badgeIcon;

    if (isDone) {
      badgeBg = const Color(0xFFD1FAE5);
      badgeText = _successGreen;
      badgeLabel = 'Sudah Dikumpulkan';
      badgeIcon = LucideIcons.checkCircle;
    } else if (isOverdue) {
      badgeBg = const Color(0xFFFFE4E1);
      badgeText = _errorRed;
      badgeLabel = 'Terlewat';
      badgeIcon = LucideIcons.alertCircle;
    } else if (hasDeadline) {
      badgeBg = const Color(0xFFFFF3CD);
      badgeText = const Color(0xFFB45309);
      badgeLabel = 'Jatuh tempo: ${_formatDate(deadline)}';
      badgeIcon = LucideIcons.clock;
    } else {
      badgeBg = const Color(0xFFE5E7EB);
      badgeText = const Color(0xFF4B5563);
      badgeLabel = 'Tanpa Tenggat';
      badgeIcon = LucideIcons.info;
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOutCubic,
          transform: Matrix4.translationValues(
            _isPressed ? 2 : (_isHovering ? -2 : 0),
            _isPressed ? 2 : (_isHovering ? -2 : 0),
            0,
          ),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _ink, width: 2),
            boxShadow: [
              BoxShadow(
                color: _ink,
                offset: _isPressed
                    ? const Offset(2, 2)
                    : _isHovering
                        ? const Offset(6, 6)
                        : const Offset(4, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Row atas: ikon + judul + badge ──────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Ikon kotak
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: isDone ? _successGreen : _primary,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _ink, width: 2),
                        boxShadow: const [
                          BoxShadow(color: _ink, offset: Offset(2, 2))
                        ],
                      ),
                      child: Icon(
                        isDone
                            ? LucideIcons.clipboardCheck
                            : LucideIcons.clipboardList,
                        color: _white,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.tugas['judul'] ?? 'Tugas',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w900,
                              fontSize: 20,
                              height: 1.2,
                              color: _ink,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 10),
                          // Badge status
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              color: badgeBg,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: _ink, width: 1.5),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(badgeIcon,
                                    size: 13, color: badgeText),
                                const SizedBox(width: 5),
                                Flexible(
                                  child: Text(
                                    badgeLabel,
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12,
                                      color: badgeText,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // ── Divider ──────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  child: Container(
                    height: 1.5,
                    decoration: BoxDecoration(
                      color: _ink.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),

                // ── Info rows ─────────────────────────────────────────────
                _InfoRow(
                  icon: LucideIcons.userCircle,
                  label: 'Pengajar',
                  value: guruNama,
                ),
                const SizedBox(height: 10),
                _InfoRow(
                  icon: LucideIcons.users,
                  label: 'Tipe',
                  value: tipeTugas,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Info row helper ───────────────────────────────────────────────────────────
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: _inkMuted),
        const SizedBox(width: 10),
        Text(
          '$label: ',
          style: GoogleFonts.inter(
              fontSize: 14, fontWeight: FontWeight.w500, color: _inkMuted),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.inter(
                fontSize: 14, fontWeight: FontWeight.w800, color: _ink),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
