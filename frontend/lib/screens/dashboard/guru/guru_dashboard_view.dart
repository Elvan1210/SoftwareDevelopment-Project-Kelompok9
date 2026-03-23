import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../config/api_config.dart';
import '../../../widgets/app_shell.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class GuruDashboardView extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String token;
  const GuruDashboardView(
      {super.key, required this.userData, required this.token});

  @override
  State<GuruDashboardView> createState() => _GuruDashboardViewState();
}

class _GuruDashboardViewState extends State<GuruDashboardView> {
  int _totalTugas = 0, _totalMateri = 0, _totalNilai = 0, _totalPengumuman = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchStats();
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
      if (results[0].statusCode == 200) {
        final dec = jsonDecode(results[0].body);
        List d = dec is List ? dec : [];
        _totalTugas = d.where((t) => t['guru_id'] == widget.userData['id']).length;
      }
      if (results[1].statusCode == 200) {
        final dec = jsonDecode(results[1].body);
        List d = dec is List ? dec : [];
        _totalMateri = d.where((m) => m['guru_id'] == widget.userData['id']).length;
      }
      if (results[2].statusCode == 200) {
        final dec = jsonDecode(results[2].body);
        List d = dec is List ? dec : [];
        _totalNilai = d.where((n) => n['guru_id'] == widget.userData['id']).length;
      }
      if (results[3].statusCode == 200) {
        final dec = jsonDecode(results[3].body);
        List d = dec is List ? dec : [];
        _totalPengumuman = d.where((p) => p['guru_id'] == widget.userData['id']).length;
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final nama = widget.userData['nama'] ?? 'Guru';
    final kelas = widget.userData['kelas'] ?? '-';
    final initials = nama.trim().split(' ').map((e) => e[0]).take(2).join().toUpperCase();

    if (_isLoading) {
      return AppShell(child: _buildSkeleton());
    }

    return AppShell(
      child: RefreshIndicator(
        onRefresh: _fetchStats,
        child: LayoutBuilder(
          builder: (ctx, constraints) {
            final w = constraints.maxWidth;
            final padding = Breakpoints.screenPadding(w);
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: padding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hero Greeting
                  _HeroGreeting(
                    initials: initials,
                    nama: nama,
                    kelas: kelas,
                    isDark: isDark,
                    primaryColor: const Color(0xFF10B981),
                    role: 'Guru',
                  ),
                  const SizedBox(height: 28),

                  // Stat Cards
                  _buildStatGrid(w),
                  const SizedBox(height: 32),

                  // Chart
                  const SectionHeader(
                    title: 'Ringkasan Aktivitas',
                    subtitle: 'Semua kontribusi kamu di platform',
                  ).animate().fadeIn(delay: 300.ms),
                  const SizedBox(height: 16),
                  _buildChart(theme, isDark),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatGrid(double w) {
    final stats = [
      _StatData(Icons.assignment_outlined, 'Tugas Dibuat', '$_totalTugas', const Color(0xFF3B82F6)),
      _StatData(Icons.menu_book_outlined, 'Materi Dibuat', '$_totalMateri', const Color(0xFF10B981)),
      _StatData(Icons.grade_outlined, 'Nilai Input', '$_totalNilai', const Color(0xFF8B5CF6)),
      _StatData(Icons.campaign_outlined, 'Pengumuman', '$_totalPengumuman', const Color(0xFFF59E0B)),
    ];

    final crossCount = w > 800 ? 4 : 2;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossCount,
        childAspectRatio: w > 800 ? 1.6 : 1.5,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: stats.length,
      itemBuilder: (_, i) {
        final s = stats[i];
        return StatCard(icon: s.icon, label: s.label, value: s.value, color: s.color)
            .animate(delay: (200 + i * 80).ms)
            .fadeIn(duration: 400.ms)
            .slideY(begin: 0.15, curve: Curves.easeOutQuart);
      },
    );
  }

  Widget _buildChart(ThemeData theme, bool isDark) {
    final vals = [
      _totalTugas.toDouble(),
      _totalMateri.toDouble(),
      _totalNilai.toDouble(),
      _totalPengumuman.toDouble(),
    ];
    final maxVal = vals.reduce((a, b) => a > b ? a : b);
    final maxY = (maxVal * 1.15).clamp(5.0, 1000.0);
    final colors = [
      const Color(0xFF3B82F6),
      const Color(0xFF10B981),
      const Color(0xFF8B5CF6),
      const Color(0xFFF59E0B),
    ];
    final labels = ['Tugas', 'Materi', 'Nilai', 'Pengumuman'];

    return PremiumCard(
      padding: const EdgeInsets.fromLTRB(16, 24, 24, 16),
      child: SizedBox(
        height: 200,
        child: RepaintBoundary(
          child: BarChart(
            BarChartData(
              maxY: maxY,
              barTouchData: BarTouchData(enabled: true),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (v, _) {
                      if (v.toInt() >= labels.length) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(labels[v.toInt()],
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onSurface.withAlpha(150))),
                      );
                    },
                    reservedSize: 32,
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: (maxY / 4).clamp(1.0, 1000.0),
                    getTitlesWidget: (v, _) => Text(
                      v.toInt().toString(),
                      style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withAlpha(120)),
                    ),
                    reservedSize: 28,
                  ),
                ),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (v) => FlLine(
                  color: theme.colorScheme.onSurface.withAlpha(20),
                  strokeWidth: 1,
                ),
              ),
              borderData: FlBorderData(show: false),
              barGroups: List.generate(4, (i) {
                return BarChartGroupData(x: i, barRods: [
                  BarChartRodData(
                    toY: vals[i],
                    color: colors[i],
                    width: 32,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                    backDrawRodData: BackgroundBarChartRodData(
                      show: true,
                      toY: maxY,
                      color: colors[i].withAlpha(15),
                    ),
                  ),
                ]);
              }),
            ),
          ),
        ),
      ),
    ).animate(delay: 400.ms).fadeIn(duration: 600.ms).slideY(begin: 0.1, curve: Curves.easeOutQuart);
  }

  Widget _buildSkeleton() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      child: Column(children: [
        const SkeletonLoader(height: 100, radius: 24),
        const SizedBox(height: 24),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          childAspectRatio: 1.5,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: List.generate(4, (_) => const SkeletonLoader(radius: 24)),
        ),
        const SizedBox(height: 24),
        const SkeletonLoader(height: 220, radius: 24),
      ]),
    );
  }
}

// ─── Sub Widgets ─────────────────────────────────────────────────────────────

class _StatData {
  final IconData icon;
  final String label, value;
  final Color color;
  const _StatData(this.icon, this.label, this.value, this.color);
}

class _HeroGreeting extends StatelessWidget {
  final String initials, nama, kelas, role;
  final bool isDark;
  final Color primaryColor;

  const _HeroGreeting({
    required this.initials,
    required this.nama,
    required this.kelas,
    required this.isDark,
    required this.primaryColor,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: PremiumCard(
        accentColor: primaryColor,
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryColor, primaryColor.withAlpha(180)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: primaryColor.withAlpha(80), blurRadius: 20, offset: const Offset(0, 8))],
              ),
              child: Center(
                child: Text(initials,
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white)),
              ),
            ).animate().scale(delay: 100.ms, curve: Curves.easeOutBack),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Halo, $role 👋',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
                          letterSpacing: 0.5)),
                  const SizedBox(height: 4),
                  Text(nama,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: primaryColor.withAlpha(20),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text('Mapel $kelas',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: primaryColor)),
                  ),
                ],
              ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.1),
            ),
          ],
        ),
      ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.05),
    );
  }
}