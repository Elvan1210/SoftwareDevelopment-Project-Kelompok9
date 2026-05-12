import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
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

  @override
  void initState() {
    super.initState();
    _fetchData();
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
                    SectionHeader(
                      title: 'Pengumuman Sekolah',
                      subtitle: 'Info terbaru untuk kamu',
                    ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.05, curve: Curves.easeOutQuart),
                    const SizedBox(height: 16),
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
      return _EmptyCard(
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

  // ── Pengumuman Section ────────────────────────────────────────────────────
  Widget _buildPengumumanSection(bool isDark) {
    if (_pengumumanList.isEmpty) {
      return _EmptyCard(
        icon: LucideIcons.megaphone,
        message: 'Belum ada pengumuman',
        subtitle: 'Pantau terus ya!',
        color: AppTheme.amber,
      );
    }

    return Column(
      children: List.generate(_pengumumanList.length.clamp(0, 4), (i) {
        return _PengumumanCard(pengumuman: _pengumumanList[i])
            .animate(delay: (400 + i * 70).ms)
            .fadeIn(duration: 400.ms)
            .slideY(begin: 0.08, curve: Curves.easeOutQuart);
      }),
    );
  }

  // ── Skeleton ──────────────────────────────────────────────────────────────
  Widget _skeleton() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      child: Column(children: [
        const SkeletonLoader(height: 120, radius: 24),
        const SizedBox(height: 20),
        Row(children: List.generate(3, (_) => Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 10),
            child: const SkeletonLoader(height: 90, radius: 18),
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
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.indigoPrimary.withAlpha(isDark ? 60 : 35),
            AppTheme.purpleSecondary.withAlpha(isDark ? 40 : 20),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppTheme.indigoPrimary.withAlpha(isDark ? 60 : 40),
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$_greeting, $name! 👋',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : AppTheme.textLight,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Kamu terdaftar di ${kelasList.length} kelas aktif.',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.indigoPrimary, AppTheme.purpleSecondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.indigoPrimary.withAlpha(100),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(Icons.school_rounded, color: Colors.white, size: 28),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.05);
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final items = [
      _StatItem(LucideIcons.clipboardList, 'Belum Dikumpul', stats['belum'] ?? 0, AppTheme.amber),
      _StatItem(LucideIcons.alertTriangle, 'Lewat Deadline', stats['lewat'] ?? 0, AppTheme.rose),
      _StatItem(LucideIcons.checkCircle2, 'Selesai', stats['selesai'] ?? 0, AppTheme.emerald),
    ];

    return Row(
      children: items.asMap().entries.map((e) {
        final item = e.value;
        final isLast = e.key == items.length - 1;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: isLast ? 0 : 12),
            child: _StatMiniCard(item: item, isDark: isDark)
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
  final Color color;
  const _StatItem(this.icon, this.label, this.value, this.color);
}

class _StatMiniCard extends StatelessWidget {
  final _StatItem item;
  final bool isDark;
  const _StatMiniCard({required this.item, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: item.color.withAlpha(isDark ? 60 : 40),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: item.color.withAlpha(isDark ? 30 : 15),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [item.color.withAlpha(isDark ? 50 : 30), item.color.withAlpha(isDark ? 25 : 15)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(item.icon, size: 16, color: item.color),
          ),
          const SizedBox(height: 12),
          Text(
            '${item.value}',
            style: GoogleFonts.poppins(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
              color: isDark ? Colors.white : AppTheme.textLight,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            item.label,
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
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

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(isDark ? 60 : 8),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
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

            // Right: deadline pill + chevron
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
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
            const SizedBox(width: 8),
            Icon(LucideIcons.chevronRight,
                size: 16, color: (isDark ? Colors.white : AppTheme.textLight).withAlpha(80)),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Pengumuman Card (Dashboard preview)
// ═══════════════════════════════════════════════════════════════════════════
class _PengumumanCard extends StatelessWidget {
  final dynamic pengumuman;
  const _PengumumanCard({required this.pengumuman});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppTheme.amber.withAlpha(isDark ? 50 : 35),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 50 : 6),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.amber.withAlpha(isDark ? 60 : 35), AppTheme.amber.withAlpha(isDark ? 30 : 18)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(LucideIcons.megaphone, color: AppTheme.amber, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pengumuman['judul'] ?? '-',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: isDark ? Colors.white : AppTheme.textLight,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  pengumuman['isi'] ?? '-',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    height: 1.5,
                    color: isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (pengumuman['tanggal'] != null) ...[
                  const SizedBox(height: 8),
                  Row(children: [
                    Icon(LucideIcons.calendar, size: 10,
                        color: isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt),
                    const SizedBox(width: 4),
                    Text(
                      pengumuman['tanggal'].toString(),
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt,
                      ),
                    ),
                  ]),
                ],
              ],
            ),
          ),
        ],
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
      ),
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
    );
  }
}
