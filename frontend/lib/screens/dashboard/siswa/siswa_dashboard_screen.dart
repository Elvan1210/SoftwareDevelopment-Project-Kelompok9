import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../config/api_config.dart';
import '../../../config/theme.dart';
import '../../../widgets/app_shell.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'siswa_tugas_detail_screen.dart';

class SiswaDashboardScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String token;
  const SiswaDashboardScreen(
      {super.key, required this.userData, required this.token});

  @override
  State<SiswaDashboardScreen> createState() => _SiswaDashboardScreenState();
}

class _SiswaDashboardScreenState extends State<SiswaDashboardScreen> {
  bool _isLoading = true;
  List<dynamic> _tugasList        = [];
  List<dynamic> _pengumumanList   = [];
  List<dynamic> _pengumpulanList  = [];
  List<dynamic> _kelasList        = [];
  Set<String>   _readIds          = {};

  @override
  void initState() {
    super.initState();
    _loadAndFetch();
  }

  Future<void> _loadAndFetch() async {
    final prefs = await SharedPreferences.getInstance();
    final list  = prefs.getStringList('read_pengumuman_${widget.userData['id']}') ?? [];
    _readIds = list.toSet();
    await _fetchData();
  }

  Future<void> _markRead(String id) async {
    setState(() => _readIds.add(id));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'read_pengumuman_${widget.userData['id']}',
      _readIds.toList(),
    );
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final headers  = {'Authorization': 'Bearer ${widget.token}'};
      final siswaId  = Uri.encodeComponent(widget.userData['id'].toString());

      final results = await Future.wait([
        http.get(Uri.parse('$baseUrl/api/kelas?siswa_id=$siswaId'), headers: headers),
        http.get(Uri.parse('$baseUrl/api/pengumuman'), headers: headers),
        http.get(Uri.parse('$baseUrl/api/pengumpulan?siswa_id=$siswaId'), headers: headers),
      ]);

      if (results[0].statusCode == 200) {
        final dec = jsonDecode(results[0].body);
        _kelasList = dec is List ? dec : [];
        List<dynamic> allTugas = [];
        for (var k in _kelasList) {
          final tResp = await http.get(
            Uri.parse('$baseUrl/api/tugas?kelas=${Uri.encodeComponent(k['nama_kelas'])}'),
            headers: headers,
          );
          if (tResp.statusCode == 200) {
            final tDec = jsonDecode(tResp.body);
            if (tDec is List) allTugas.addAll(tDec);
          }
        }
        _tugasList = allTugas;
      }
      if (results[1].statusCode == 200) {
        final dec = jsonDecode(results[1].body);
        _pengumumanList = dec is List ? dec : [];
      }
      if (results[2].statusCode == 200) {
        final dec = jsonDecode(results[2].body);
        _pengumpulanList = dec is List ? dec : [];
      }
    } catch (e) {
      debugPrint(e.toString());
    }
    if (mounted) setState(() => _isLoading = false);
  }

  // ── Stat computation ─────────────────────────────────────────────────────
  Map<String, int> get _stats {
    int lewat = 0, belum = 0, selesai = 0;
    for (var t in _tugasList) {
      if (_pengumpulanList.any((p) => p['tugas_id'].toString() == t['id'].toString())) {
        selesai++;
        continue;
      }
      final dl = DateTime.tryParse(t['deadline']?.toString() ?? '');
      if (dl != null && dl.isBefore(DateTime.now())) { lewat++; continue; }
      belum++;
    }
    return {'belum': belum, 'lewat': lewat, 'selesai': selesai};
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return AppShell(child: _skeleton());
    }

    final s      = _stats;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final name   = (widget.userData['nama'] ?? widget.userData['name'] ?? 'Siswa').toString().split(' ').first;

    return AppShell(
      child: RefreshIndicator(
        onRefresh: _fetchData,
        color: AppTheme.indigoPrimary,
        child: LayoutBuilder(builder: (ctx, c) {
          final w       = c.maxWidth;
          final padding = Breakpoints.screenPadding(w);
          final isWide  = w >= 800;

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: padding,
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // ── Greeting Banner ──────────────────────────────
                    _GreetingBanner(name: name, isDark: isDark, kelasList: _kelasList),
                    const SizedBox(height: 28),

                    // ── Stat Row ─────────────────────────────────────
                    _StatRow(stats: s, isWide: isWide),
                    const SizedBox(height: 36),

                    // ── Tugas Mendatang ───────────────────────────────
                    SectionHeader(
                      title: 'Tugas Mendatang',
                      subtitle: '${_tugasList.length} tugas aktif dari semua kelas',
                    ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.05, curve: Curves.easeOutQuart),
                    const SizedBox(height: 16),
                    _buildTugasSection(isDark),
                    const SizedBox(height: 36),

                    // ── Pengumuman ────────────────────────────────────
                    _buildPengumumanHeader(isDark),
                    const SizedBox(height: 12),
                    _buildPengumumanSection(isDark),
                    const SizedBox(height: 32),
                  ]),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  // ── Tugas Section ─────────────────────────────────────────────────────────
  Widget _buildTugasSection(bool isDark) {
    if (_tugasList.isEmpty) {
      return const _EmptyCard(
        icon: LucideIcons.clipboardCheck,
        message: 'Tidak ada tugas mendatang',
        subtitle: 'Semua tugas sudah dikumpulkan!',
        color: AppTheme.emerald,
      );
    }

    return Column(
      children: List.generate(_tugasList.length.clamp(0, 5), (i) {
        final t         = _tugasList[i];
        final submitted = _pengumpulanList.any((p) =>
            p['tugas_id'].toString() == t['id'].toString());
        final dl        = DateTime.tryParse(t['deadline']?.toString() ?? '');
        final isLate    = dl != null && dl.isBefore(DateTime.now()) && !submitted;

        return _TugasCard(
          tugas: t,
          submitted: submitted,
          isLate: isLate,
          deadline: dl,
          onTap: () => Navigator.push(context, MaterialPageRoute(
            builder: (_) => SiswaTugasDetailScreen(
              tugas: t, userData: widget.userData, token: widget.token,
            ),
          )),
        )
            .animate(delay: (300 + i * 70).ms)
            .fadeIn(duration: 400.ms)
            .slideY(begin: 0.08, curve: Curves.easeOutQuart);
      }),
    );
  }

  // ── Pengumuman Header ─────────────────────────────────────────────────────
  Widget _buildPengumumanHeader(bool isDark) {
    final unread = _pengumumanList.where((p) => !_readIds.contains(p['id']?.toString())).length;
    return Row(
      children: [
        Expanded(
          child: SectionHeader(
            title: 'Pengumuman Sekolah',
            subtitle: unread > 0 ? '$unread belum dibaca' : 'Semua sudah dibaca',
          ),
        ),
        if (unread > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.amber.withAlpha(isDark ? 40 : 25),
              borderRadius: BorderRadius.circular(100),
              border: Border.all(color: AppTheme.amber.withAlpha(isDark ? 80 : 50)),
            ),
            child: Text('$unread baru',
                style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.amber)),
          ).animate().fadeIn(delay: 300.ms),
      ],
    ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.05, curve: Curves.easeOutQuart);
  }

  // ── Pengumuman Section (horizontal scroll) ────────────────────────────────
  Widget _buildPengumumanSection(bool isDark) {
    final unread = _pengumumanList.where((p) => !_readIds.contains(p['id']?.toString())).toList();
    if (_pengumumanList.isEmpty) {
      return const _EmptyCard(
        icon: LucideIcons.megaphone,
        message: 'Belum ada pengumuman',
        subtitle: 'Pantau terus ya!',
        color: AppTheme.amber,
      );
    }
    if (unread.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
        ),
        child: Row(children: [
          const Icon(LucideIcons.checkCircle2, color: AppTheme.emerald, size: 20),
          const SizedBox(width: 12),
          Text('Semua pengumuman sudah dibaca!',
              style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600,
                  color: AppTheme.emerald)),
        ]),
      );
    }
    return SizedBox(
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: unread.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (ctx, i) {
          final p = unread[i];
          return _PengumumanChipCard(
            pengumuman: p,
            isDark: isDark,
            onMarkRead: () => _markRead(p['id']?.toString() ?? ''),
          ).animate(delay: (i * 60).ms).fadeIn(duration: 350.ms);
        },
      ),
    );
  }

  // ── Skeleton ──────────────────────────────────────────────────────────────
  Widget _skeleton() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      child: Column(children: [
        const SkeletonLoader(height: 120, radius: 24),
        const SizedBox(height: 20),
        Row(children: List.generate(3, (_) => const Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: 10),
            child: SkeletonLoader(height: 90, radius: 18),
          ),
        ))),
        const SizedBox(height: 24),
        ...List.generate(4, (_) => const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: SkeletonLoader(height: 88, radius: 20),
        )),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Greeting Banner
// ═══════════════════════════════════════════════════════════════════════════
class _GreetingBanner extends StatelessWidget {
  final String name;
  final bool isDark;
  final List<dynamic> kelasList;
  const _GreetingBanner({required this.name, required this.isDark, required this.kelasList});

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Selamat Pagi';
    if (h < 15) return 'Selamat Siang';
    if (h < 18) return 'Selamat Sore';
    return 'Selamat Malam';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B27) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? const Color(0xFF252D3D) : const Color(0xFFE5E7EB),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 90 : 10),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: AppTheme.indigoPrimary.withAlpha(isDark ? 20 : 10),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // A beautiful ambient tag
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.indigoPrimary.withAlpha(isDark ? 30 : 15),
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(
                          color: AppTheme.indigoPrimary.withAlpha(isDark ? 60 : 30),
                          width: 1.0,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _greeting.contains('Pagi')
                                ? LucideIcons.sun
                                : (_greeting.contains('Siang') || _greeting.contains('Sore')
                                    ? LucideIcons.cloudSun
                                    : LucideIcons.moon),
                            size: 12,
                            color: AppTheme.indigoPrimary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _greeting.toUpperCase(),
                            style: GoogleFonts.poppins(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.indigoPrimary,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      name,
                      style: GoogleFonts.poppins(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : AppTheme.textLight,
                        letterSpacing: -0.8,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Terdaftar di ${kelasList.length} kelas aktif hari ini.',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.indigoPrimary, AppTheme.purpleSecondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.indigoPrimary.withAlpha(120),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(Icons.school_rounded, color: Colors.white, size: 32),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(height: 1, thickness: 1),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Selamat belajar & tingkatkan prestasimu! ✨',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              PremiumElevatedButton(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: Colors.transparent,
                    builder: (ctx) => _MotivationalSheet(isDark: isDark),
                  );
                },
                color: AppTheme.indigoPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                radius: 12,
                child: Text('Motivasi Hari Ini', style: GoogleFonts.poppins(fontWeight: FontWeight.w800, fontSize: 11)),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.05);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Motivational Bottom Sheet
// ─────────────────────────────────────────────────────────────────────────────
class _MotivationalSheet extends StatelessWidget {
  final bool isDark;
  const _MotivationalSheet({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder, width: 1.5),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: (isDark ? Colors.white : AppTheme.textLight).withAlpha(40),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.indigoPrimary.withAlpha(isDark ? 40 : 20),
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.sparkles, color: AppTheme.indigoPrimary, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quotes of the Day',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : AppTheme.textLight,
                      ),
                    ),
                    Text(
                      'Inspirasi belajar harianmu',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkCard : const Color(0xFFF8F9FC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
            ),
            child: Text(
              '"Pendidikan adalah senjata paling mematikan di dunia, karena dengan pendidikan, Anda dapat mengubah dunia."\n\n— Nelson Mandela',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                height: 1.6,
                color: isDark ? Colors.white : AppTheme.textLight,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: PremiumElevatedButton(
              onPressed: () => Navigator.pop(context),
              color: AppTheme.indigoPrimary,
              child: const Text('Siap Belajar! 🚀'),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Stat Row
// ═══════════════════════════════════════════════════════════════════════════
class _StatRow extends StatelessWidget {
  final Map<String, int> stats;
  final bool isWide;
  const _StatRow({required this.stats, required this.isWide});

  @override
  Widget build(BuildContext context) {
    final items = [
      _StatItem(LucideIcons.clipboardList, 'Belum Dikumpul', stats['belum'] ?? 0, [AppTheme.amber, const Color(0xFFD97706)]),
      _StatItem(LucideIcons.alertTriangle, 'Lewat Deadline', stats['lewat'] ?? 0, [AppTheme.rose, const Color(0xFFBE185D)]),
      _StatItem(LucideIcons.checkCircle2, 'Selesai', stats['selesai'] ?? 0, [AppTheme.emerald, const Color(0xFF059669)]),
    ];

    return Row(
      children: items.asMap().entries.map((e) {
        final item = e.value;
        final isLast = e.key == items.length - 1;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: isLast ? 0 : 12),
            child: CosmicStatCard(icon: item.icon, label: item.label, value: '${item.value}', gradient: item.gradient)
                .animate(delay: (100 + e.key * 80).ms)
                .fadeIn(duration: 400.ms)
                .scale(begin: const Offset(0.85, 0.85), curve: Curves.elasticOut, duration: 700.ms),
          ),
        );
      }).toList(),
    );
  }
}

class _StatItem {
  final IconData icon;
  final String label;
  final int value;
  final List<Color> gradient;
  const _StatItem(this.icon, this.label, this.value, this.gradient);
}


// ═══════════════════════════════════════════════════════════════════════════
// Tugas Card
// ═══════════════════════════════════════════════════════════════════════════
class _TugasCard extends StatelessWidget {
  final dynamic tugas;
  final bool submitted;
  final bool isLate;
  final DateTime? deadline;
  final VoidCallback onTap;
  const _TugasCard({
    required this.tugas,
    required this.submitted,
    required this.isLate,
    required this.deadline,
    required this.onTap,
  });

  Color get _statusColor {
    if (submitted) return AppTheme.emerald;
    if (isLate)   return AppTheme.rose;
    return AppTheme.amber;
  }

  String get _statusLabel {
    if (submitted) return 'Selesai';
    if (isLate)   return 'Terlambat';
    return 'Belum';
  }

  String _fmtDl() {
    if (deadline == null) return '-';
    final now  = DateTime.now();
    final diff = deadline!.difference(now);
    if (submitted) return DateFormat('dd MMM, HH:mm').format(deadline!);
    if (diff.isNegative) return 'Lewat ${diff.inDays.abs()}h';
    if (diff.inDays > 0)  return '${diff.inDays} hari lagi';
    if (diff.inHours > 0) return '${diff.inHours} jam lagi';
    return '< 1 jam';
  }

  @override
  Widget build(BuildContext context) {
    final isDark  = Theme.of(context).brightness == Brightness.dark;
    final accent  = _statusColor;

    return PremiumCard(
      onTap: onTap,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      accentColor: accent,
      child: Row(
        children: [
          // Left accent bar
          Container(
              width: 4,
              height: 52,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [accent, accent.withAlpha(120)],
                ),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 14),

            // Icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [accent.withAlpha(isDark ? 50 : 30), accent.withAlpha(isDark ? 25 : 15)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(LucideIcons.fileText, color: accent, size: 20),
            ),
            const SizedBox(width: 14),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tugas['judul'] ?? '-',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: isDark ? Colors.white : AppTheme.textLight,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(children: [
                    Icon(LucideIcons.bookOpen, size: 11,
                        color: isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt),
                    const SizedBox(width: 4),
                    Text(
                      tugas['mapel'] ?? '-',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt,
                      ),
                    ),
                  ]),
                ],
              ),
            ),

            // Right: deadline pill
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Status pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: accent.withAlpha(isDark ? 35 : 20),
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(color: accent.withAlpha(isDark ? 70 : 50)),
                  ),
                  child: Text(
                    _statusLabel,
                    style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.w800, color: accent),
                  ),
                ),
                const SizedBox(height: 6),
                Row(children: [
                  Icon(LucideIcons.clock, size: 10, color: accent.withAlpha(180)),
                  const SizedBox(width: 3),
                  Text(
                    _fmtDl(),
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: accent,
                    ),
                  ),
                ]),
              ],
            ),
            const SizedBox(width: 14),
            PremiumElevatedButton(
              onPressed: onTap,
              color: accent,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              radius: 10,
              child: Text(
                submitted ? 'Buka' : 'Kerjakan',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Pengumuman Chip Card (horizontal scroll, compact, with mark-as-read)
// ═══════════════════════════════════════════════════════════════════════════
class _PengumumanChipCard extends StatelessWidget {
  final dynamic pengumuman;
  final bool isDark;
  final VoidCallback onMarkRead;
  const _PengumumanChipCard({
    required this.pengumuman,
    required this.isDark,
    required this.onMarkRead,
  });

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      accentColor: AppTheme.amber,
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(14),
      child: SizedBox(
        width: 240,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.amber, Color(0xFFF97316)],
                  ),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(LucideIcons.megaphone, color: Colors.white, size: 14),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  pengumuman['judul'] ?? '-',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    color: isDark ? Colors.white : AppTheme.textLight,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Mark as read X button
              GestureDetector(
                onTap: onMarkRead,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkBorder : const Color(0xFFF5F5FF),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(LucideIcons.x, size: 12,
                      color: isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Text(
              pengumuman['isi'] ?? '-',
              style: GoogleFonts.poppins(
                fontSize: 11,
                height: 1.5,
                color: isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (pengumuman['tanggal'] != null) ...[
            const SizedBox(height: 6),
            Text(
              pengumuman['tanggal'].toString(),
              style: GoogleFonts.poppins(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: AppTheme.amber.withAlpha(isDark ? 200 : 160),
              ),
            ),
          ],
        ],
      ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Empty Card
// ═══════════════════════════════════════════════════════════════════════════
class _EmptyCard extends StatelessWidget {
  final IconData icon;
  final String message;
  final String subtitle;
  final Color color;
  const _EmptyCard({required this.icon, required this.message, required this.subtitle, required this.color});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GlassCard(
      radius: 18,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
      child: SizedBox(
        width: double.infinity,
        child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withAlpha(isDark ? 40 : 25),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 14),
          Text(message, style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 14,
            color: isDark ? Colors.white.withAlpha(200) : AppTheme.textLight)),
          const SizedBox(height: 4),
          Text(subtitle, style: GoogleFonts.poppins(fontSize: 12,
            color: isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt)),
        ],
      ),
      ),
    );
  }
}
