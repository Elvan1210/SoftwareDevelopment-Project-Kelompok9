import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../config/api_config.dart';
import '../../../widgets/app_shell.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'guru_team_detail_layout.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../config/theme.dart';

class GuruDashboardView extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String token;
  final Function(int)? onNavigate;
  const GuruDashboardView({super.key, required this.userData, required this.token, this.onNavigate});

  @override
  State<GuruDashboardView> createState() => _GuruDashboardViewState();
}

class _GuruDashboardViewState extends State<GuruDashboardView> {
  int _totalTugas = 0, _totalMateri = 0, _totalNilai = 0, _totalPengumuman = 0;
  bool _isLoading = true;
  List<dynamic> _kelasList = [];

  // ── Helpers ────────────────────────────────────────────────────────────────
  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour >= 5  && hour < 11) return 'Selamat pagi';
    if (hour >= 11 && hour < 15) return 'Selamat siang';
    if (hour >= 15 && hour < 18) return 'Selamat sore';
    return 'Selamat malam';
  }

  String get _subtitle {
    final hour = DateTime.now().hour;
    if (hour >= 5  && hour < 11) return 'Semoga hari ini penuh inspirasi dalam mendidik.';
    if (hour >= 11 && hour < 15) return 'Tetap semangat mengajar, Bpk/Ibu!';
    if (hour >= 15 && hour < 18) return 'Semoga hari ini penuh inspirasi dalam mendidik.';
    return 'Terima kasih atas dedikasi mengajar hari ini.';
  }

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
    setState(() => _isLoading = true);
    await Future.wait([_fetchStats(), _fetchKelasGuru()]);
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _fetchKelasGuru() async {
    try {
      final headers = {'Authorization': 'Bearer ${widget.token}'};
      final guruId = Uri.encodeComponent(widget.userData['id'].toString());
      final resp = await http.get(Uri.parse('$baseUrl/api/kelas?guru_id=$guruId'), headers: headers);
      if (resp.statusCode == 200) {
        final dec = jsonDecode(resp.body);
        _kelasList = dec is List ? dec : [];
      }
    } catch (e) { debugPrint('Error fetch kelas: $e'); }
  }

  Future<void> _fetchStats() async {
    try {
      final headers = {'Authorization': 'Bearer ${widget.token}'};
      final results = await Future.wait([
        http.get(Uri.parse('$baseUrl/api/tugas'), headers: headers),
        http.get(Uri.parse('$baseUrl/api/materi'), headers: headers),
        http.get(Uri.parse('$baseUrl/api/nilai'), headers: headers),
        http.get(Uri.parse('$baseUrl/api/pengumuman'), headers: headers),
      ]);
      final myId = widget.userData['id'].toString();
      if (results[0].statusCode == 200) {
        final d = jsonDecode(results[0].body) as List? ?? [];
        _totalTugas = d.where((t) => t['guru_id'].toString() == myId).length;
      }
      if (results[1].statusCode == 200) {
        final d = jsonDecode(results[1].body) as List? ?? [];
        _totalMateri = d.where((m) => m['guru_id'].toString() == myId).length;
      }
      if (results[2].statusCode == 200) {
        final d = jsonDecode(results[2].body) as List? ?? [];
        _totalNilai = d.where((n) => n['guru_id'].toString() == myId).length;
      }
      if (results[3].statusCode == 200) {
        final d = jsonDecode(results[3].body) as List? ?? [];
        _totalPengumuman = d.where((p) => p['guru_id'].toString() == myId).length;
      }
    } catch (e) { debugPrint('Error: $e'); }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (_isLoading) return AppShell(child: _buildSkeleton());

    return AppShell(
      child: RefreshIndicator(
        onRefresh: _fetchInitialData,
        color: AppTheme.primary,
        child: LayoutBuilder(builder: (ctx, constraints) {
          final w = constraints.maxWidth;
          final hPad = w >= Breakpoints.tablet ? 40.0 : 20.0;

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: EdgeInsets.fromLTRB(hPad, 20, hPad, 40),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([

                    // 1. Greeting
                    _buildGreeting(isDark)
                        .animate().fadeIn(duration: 350.ms).slideY(begin: -0.04),
                    const SizedBox(height: 20),

                    // 2. Stat chips
                    _buildStatChips(isDark)
                        .animate().fadeIn(delay: 80.ms),
                    const SizedBox(height: 28),

                    // 3. Aksi Cepat
                    _buildSectionLabel('AKSI CEPAT', isDark)
                        .animate().fadeIn(delay: 120.ms),
                    const SizedBox(height: 12),
                    _buildQuickActions(w, isDark)
                        .animate().fadeIn(delay: 150.ms),
                    const SizedBox(height: 28),

                    // 4. Kelas Ampuan
                    _buildRowHeader('KELAS AMPUAN', 'LIHAT SEMUA', isDark)
                        .animate().fadeIn(delay: 200.ms),
                    const SizedBox(height: 12),
                    _buildClassGrid(w, isDark)
                        .animate().fadeIn(delay: 230.ms),
                    const SizedBox(height: 28),

                    // 5. Grafik
                    _buildSectionLabel('GRAFIK AKTIVITAS', isDark)
                        .animate().fadeIn(delay: 280.ms),
                    const SizedBox(height: 12),
                    _buildChart(isDark)
                        .animate().fadeIn(delay: 310.ms),

                  ]),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  // ── 1. Greeting ────────────────────────────────────────────────────────────
  Widget _buildGreeting(bool isDark) {
  final nama = widget.userData['nama']?.toString() ?? 'Guru';
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        '$_greeting,',
        style: GoogleFonts.poppins(
          fontSize: 28, fontWeight: FontWeight.w700,
          color: isDark ? AppTheme.textDark : AppTheme.textPrimary,
          letterSpacing: -0.5, height: 1.1,
        ),
      ),
      Text(
        'Bpk/Ibu. $nama',
        style: GoogleFonts.poppins(
          fontSize: 28, fontWeight: FontWeight.w700,
          color: isDark ? AppTheme.textDark : AppTheme.textPrimary,
          letterSpacing: -0.5, height: 1.1,
        ),
      ),
      const SizedBox(height: 6),
      Text(
        _subtitle,
        style: GoogleFonts.poppins(
          fontSize: 13, fontWeight: FontWeight.w400,
          color: isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt,
          height: 1.4,
        ),
      ),
    ],
  );
}

  // ── 2. Stat chips ──────────────────────────────────────────────────────────
  Widget _buildStatChips(bool isDark) {
    final stats = [
      ('TUGAS', '$_totalTugas'),
      ('MATERI', '$_totalMateri'),
      ('NILAI', '$_totalNilai'),
      ('PENGUMUMAN', '$_totalPengumuman'),
    ];

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: stats.map((s) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkCard : AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              s.$1,
              style: GoogleFonts.inter(
                fontSize: 11, fontWeight: FontWeight.w700,
                color: isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              s.$2.padLeft(2, '0'),
              style: GoogleFonts.poppins(
                fontSize: 15, fontWeight: FontWeight.w800,
                color: isDark ? AppTheme.textDark : AppTheme.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
      )).toList(),
    );
  }

  // ── 3. Quick Actions ───────────────────────────────────────────────────────
  Widget _buildQuickActions(double w, bool isDark) {
    final actions = [
      _ActionData(LucideIcons.clipboardList, 'Buat Tugas'),
      _ActionData(LucideIcons.bookOpen, 'Tambah Materi'),
      _ActionData(LucideIcons.userCheck, 'Isi Presensi'),
      _ActionData(LucideIcons.megaphone, 'Buat Pengumuman'),
    ];

    final crossCount = w >= Breakpoints.tablet ? 4 : 2;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossCount,
        childAspectRatio: 1.1,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: actions.length,
      itemBuilder: (_, i) {
        final a = actions[i];
        return _buildActionCard(a, isDark)
            .animate(delay: (i * 50).ms)
            .fadeIn(duration: 300.ms)
            .scale(begin: const Offset(0.95, 0.95), curve: Curves.easeOutBack);
      },
    );
  }

  Widget _buildActionCard(_ActionData a, bool isDark) {
    return GestureDetector(
      onTap: () {
        final navMap = {
        'Buat Tugas': 1,        // → Teams/Kelas
        'Tambah Materi': 1,     // → Teams/Kelas
        'Isi Presensi': 1,      // → Teams/Kelas
        'Buat Pengumuman': 3,   // → Pengumuman
  };
      widget.onNavigate?.call(navMap[a.label] ?? 0);
  },
       // navigate ke screen terkait
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkCard : AppTheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: AppTheme.primary.withAlpha(isDark ? 40 : 20),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(a.icon, color: AppTheme.primary, size: 22),
            ),
            const SizedBox(height: 10),
            Text(
              a.label,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 12, fontWeight: FontWeight.w700,
                color: isDark ? AppTheme.textDark : AppTheme.textPrimary,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Row / Section headers ──────────────────────────────────────────────────
  Widget _buildSectionLabel(String label, bool isDark) {
    return Text(
      label,
      style: GoogleFonts.notoSerif(
        fontSize: 11, fontWeight: FontWeight.w700,
        color: isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt,
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _buildRowHeader(String title, String? action, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: GoogleFonts.notoSerif(
          fontSize: 11, fontWeight: FontWeight.w700,
          color: isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt,
          letterSpacing: 0.8,
        )),
        if (action != null)
          Text(action, style: GoogleFonts.inter(
            fontSize: 11, fontWeight: FontWeight.w700,
            color: AppTheme.primary, letterSpacing: 0.5,
          )),
      ],
    );
  }

  // ── 4. Class Grid ──────────────────────────────────────────────────────────
  Widget _buildClassGrid(double w, bool isDark) {
    if (_kelasList.isEmpty) {
      return Container(
        height: 100,
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkCard : AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
        ),
        child: Center(child: Text('Belum ada kelas ampuan',
          style: GoogleFonts.inter(
            color: isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt,
          ),
        )),
      );
    }

    final crossCount = w >= Breakpoints.tablet ? 3 : 2;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossCount,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: crossCount == 2 ? 0.9 : 1.1,
      ),
      itemCount: _kelasList.length,
      itemBuilder: (ctx, i) {
        final k = _kelasList[i];
        return _GuruClassCard(kelas: k, isDark: isDark)
            .animate(delay: (i * 60).ms)
            .fadeIn(duration: 300.ms)
            .slideY(begin: 0.06, curve: Curves.easeOutQuart);
      },
    );
  }

  // ── 5. Chart ───────────────────────────────────────────────────────────────
  Widget _buildChart(bool isDark) {
    final vals = [_totalTugas.toDouble(), _totalMateri.toDouble(), _totalNilai.toDouble(), _totalPengumuman.toDouble()];
    final maxVal = vals.reduce((a, b) => a > b ? a : b);
    final maxY = (maxVal * 1.2).clamp(5.0, 1000.0);
    final labels = ['Tugas', 'Materi', 'Nilai', 'Pengumuman'];

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 18, 16, 12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
      ),
      child: SizedBox(
        height: 160,
        child: RepaintBoundary(child: BarChart(BarChartData(
          maxY: maxY,
          barTouchData: BarTouchData(enabled: true),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(sideTitles: SideTitles(
              showTitles: true, reservedSize: 28,
              getTitlesWidget: (v, _) {
                if (v.toInt() >= labels.length) return const SizedBox.shrink();
                return Padding(padding: const EdgeInsets.only(top: 6),
                  child: Text(labels[v.toInt()], style: GoogleFonts.inter(
                    fontSize: 10, fontWeight: FontWeight.w600,
                    color: isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt,
                  )));
              },
            )),
            leftTitles: AxisTitles(sideTitles: SideTitles(
              showTitles: true, reservedSize: 22,
              interval: (maxY / 4).clamp(1.0, 1000.0),
              getTitlesWidget: (v, _) => Text(v.toInt().toString(),
                style: GoogleFonts.inter(fontSize: 10,
                    color: isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt)),
            )),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            show: true, drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => FlLine(
              color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder, strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(4, (i) => BarChartGroupData(x: i, barRods: [
            BarChartRodData(
              toY: vals[i], color: AppTheme.primary, width: 24,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(7)),
              backDrawRodData: BackgroundBarChartRodData(
                show: true, toY: maxY, color: AppTheme.primary.withAlpha(12),
              ),
            ),
          ])),
        ))),
      ),
    );
  }

  Widget _buildSkeleton() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(children: [
        const SkeletonLoader(height: 80, radius: 12),
        const SizedBox(height: 16),
        const SkeletonLoader(height: 44, radius: 20),
        const SizedBox(height: 24),
        GridView.count(
          shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2, childAspectRatio: 1.1,
          crossAxisSpacing: 12, mainAxisSpacing: 12,
          children: List.generate(4, (_) => const SkeletonLoader(radius: 18)),
        ),
        const SizedBox(height: 24),
        GridView.count(
          shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2, childAspectRatio: 0.9,
          crossAxisSpacing: 12, mainAxisSpacing: 12,
          children: List.generate(4, (_) => const SkeletonLoader(radius: 16)),
        ),
      ]),
    );
  }
}

// ── Class Card ────────────────────────────────────────────────────────────────
class _GuruClassCard extends StatelessWidget {
  final dynamic kelas;
  final bool isDark;
  const _GuruClassCard({required this.kelas, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final color = Color(int.parse(kelas['warna_card'] ?? '4282032886'));
    final nama = (kelas['nama_kelas'] as String? ?? '').trim();
    final kodeKelas = kelas['kode_kelas']?.toString() ?? '';
    final siswaCount = (kelas['siswa_ids'] as List?)?.length ?? 0;

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(
        builder: (_) => GuruTeamDetailLayout(
          userData: context.findAncestorStateOfType<_GuruDashboardViewState>()!.widget.userData,
          token: context.findAncestorStateOfType<_GuruDashboardViewState>()!.widget.token,
          teamData: kelas,
        ),
      )),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkCard : AppTheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
          ),
        ),
        child: Column(
          children: [
            // Left accent bar via top band
            Container(
              height: 4,
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Kode kelas label
                    if (kodeKelas.isNotEmpty)
                      Text(kodeKelas,
                        style: GoogleFonts.inter(
                          fontSize: 10, fontWeight: FontWeight.w700,
                          color: color, letterSpacing: 0.5,
                        ),
                      ),
                    const SizedBox(height: 4),
                    // Nama kelas — big
                    Expanded(
                      child: Text(nama,
                        style: GoogleFonts.poppins(
                          fontSize: 16, fontWeight: FontWeight.w800,
                          color: isDark ? AppTheme.textDark : AppTheme.textPrimary,
                          height: 1.2, letterSpacing: -0.3,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Siswa count
                    Row(children: [
                      Icon(LucideIcons.users, size: 12,
                          color: isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt),
                      const SizedBox(width: 5),
                      Text('$siswaCount Siswa',
                        style: GoogleFonts.inter(
                          fontSize: 11, fontWeight: FontWeight.w600,
                          color: isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt,
                        ),
                      ),
                    ]),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatData {
  final IconData icon;
  final String label, value;
  const _StatData(this.icon, this.label, this.value);
}

class _ActionData {
  final IconData icon;
  final String label;
  const _ActionData(this.icon, this.label);
}