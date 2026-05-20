import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../config/api_config.dart';
import '../../../config/theme.dart';
import '../../../widgets/app_shell.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class AdminDashboardView extends StatefulWidget {
  final String token;
  final Function(int)? onNavigate;
  const AdminDashboardView({super.key, required this.token, this.onNavigate});

  @override
  State<AdminDashboardView> createState() => _AdminDashboardViewState();
}

class _AdminDashboardViewState extends State<AdminDashboardView> {
  int _totalSiswa = 0, _totalGuru = 0, _totalKelas = 0, _totalMapel = 0;
  bool _isLoading = true;
  List<dynamic> _kelasList = [];

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    try {
      final headers = {'Authorization': 'Bearer ${widget.token}'};
      final results = await Future.wait([
        http.get(Uri.parse('$baseUrl/api/users'), headers: headers),
        http.get(Uri.parse('$baseUrl/api/kelas'), headers: headers),
      ]);
      if (results[0].statusCode == 200) {
        final dec = jsonDecode(results[0].body);
        List users = dec is List ? dec : [];
        _totalSiswa = users.where((u) => u['role'] == 'Siswa').length;
        final gurus = users.where((u) => u['role'] == 'Guru').toList();
        _totalGuru = gurus.length;
        final mapels = <String>{};
        for (var g in gurus) {
          final m = (g['kelas'] ?? '').toString().trim();
          if (m.isNotEmpty && m != '-') mapels.add(m.toUpperCase());
        }
        _totalMapel = mapels.length;
      }
      if (results[1].statusCode == 200) {
        final dec = jsonDecode(results[1].body);
        _kelasList = dec is List ? dec : [];
        _totalKelas = _kelasList.length;
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

    if (_isLoading) {
      return _buildSkeleton();
    }

    return RefreshIndicator(
      onRefresh: _fetchStats,
      color: AppTheme.indigoPrimary,
      child: LayoutBuilder(
        builder: (ctx, constraints) {
          final w = constraints.maxWidth;
          final padding = Breakpoints.screenPadding(w);
          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: padding,
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildQuickActions(theme, isDark, w),
                    const SizedBox(height: 24),

                    _buildStatGrid(w, isDark),
                    const SizedBox(height: 32),

                    const SectionHeader(
                      title: 'Statistik Sekolah',
                      subtitle: 'Distribusi pengguna dan kelas',
                    ).animate().fadeIn(delay: 500.ms).slideX(begin: -0.05, curve: Curves.easeOutQuart),
                    const SizedBox(height: 16),

                    _buildChartsSection(theme, isDark, w),
                    const SizedBox(height: 24),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatGrid(double w, bool isDark) {
    final stats = [
      _StatData(LucideIcons.graduationCap, 'Total Siswa', '$_totalSiswa', AppTheme.tealDeep, const Color(0xFF0EA5E9)),
      _StatData(LucideIcons.user, 'Total Guru', '$_totalGuru', AppTheme.indigoPrimary, AppTheme.purpleSecondary),
      _StatData(LucideIcons.library, 'Total Kelas', '$_totalKelas', AppTheme.amber, const Color(0xFFF97316)),
      _StatData(LucideIcons.bookOpen, 'Mata Pelajaran', '$_totalMapel', AppTheme.rose, const Color(0xFFE11D48)),
    ];
    final crossCount = w > 1100 ? 4 : (w > 600 ? 2 : 1);
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossCount,
        childAspectRatio: w > 1100 ? 2.4 : (w > 600 ? 2.2 : 2.8),
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: stats.length,
      itemBuilder: (_, i) {
        final s = stats[i];
        return CosmicStatCard(icon: s.icon, label: s.label, value: s.value, gradient: [s.color, s.colorEnd])
            .animate(delay: (100 + i * 80).ms)
            .fadeIn(duration: 400.ms)
            .scale(begin: const Offset(0.8, 0.8), curve: Curves.elasticOut, duration: 800.ms)
            .slideY(begin: 0.2, curve: Curves.easeOutCubic);
      },
    );
  }

  Widget _buildQuickActions(ThemeData theme, bool isDark, double w) {
    final columns = w < 600 ? 2 : 4;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2538) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? const Color(0xFF2D3A54) : const Color(0xFFE5E7EB), width: 1.2),
      ),
      padding: const EdgeInsets.all(4),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF161D2B) : const Color(0xFFEEF2FF),
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Aksi Cepat', style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w900, color: isDark ? Colors.white : AppTheme.textLight)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: AppTheme.indigoPrimary.withAlpha(20), borderRadius: BorderRadius.circular(100)),
                  child: Text('ADMIN ONLY', style: GoogleFonts.plusJakartaSans(fontSize: 9, fontWeight: FontWeight.w900, color: AppTheme.indigoPrimary)),
                )
              ],
            ),
            const SizedBox(height: 20),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: columns,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: w < 600 ? 1.4 : 1.1,
              children: [
                _actionBtn(LucideIcons.userPlus, 'Tambah User', AppTheme.indigoPrimary, () {
                  if (widget.onNavigate != null) widget.onNavigate!(1);
                }, isDark),
                _actionBtn(LucideIcons.building2, 'Buka Kelas', AppTheme.tealDeep, () {
                  if (widget.onNavigate != null) widget.onNavigate!(2);
                }, isDark),
                _actionBtn(LucideIcons.megaphone, 'Broadcast', AppTheme.amber, () {
                  if (widget.onNavigate != null) widget.onNavigate!(7);
                }, isDark),
                _actionBtn(LucideIcons.settings, 'Preferensi', AppTheme.rose, () {
                  if (widget.onNavigate != null) widget.onNavigate!(8);
                }, isDark),
              ],
            ),
          ],
        ),
      ),
    ).animate(delay: 200.ms).fadeIn().slideY(begin: -0.1);
  }

  Widget _actionBtn(IconData icon, String label, Color color, VoidCallback onTap, bool isDark) {
    return PremiumCard(
      onTap: onTap,
      accentColor: color,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      radius: 16,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : AppTheme.textLight,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildChartsSection(ThemeData theme, bool isDark, double w) {
    final isWide = w > 700;
    final pieChart = _buildPieChart(theme, isDark);
    final barChart = _buildBarChart(theme, isDark);

    if (isWide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: pieChart),
          const SizedBox(width: 16),
          Expanded(child: barChart),
        ],
      );
    }
    return Column(children: [pieChart, const SizedBox(height: 16), barChart]);
  }

  Widget _buildPieChart(ThemeData theme, bool isDark) {
    final sections = [
      PieChartSectionData(
          value: _totalSiswa.toDouble(),
          color: AppTheme.indigoPrimary,
          title: 'Siswa',
          radius: 50,
          titleStyle: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white)),
      PieChartSectionData(
          value: _totalGuru.toDouble(),
          color: AppTheme.tealDeep,
          title: 'Guru',
          radius: 50,
          titleStyle: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white)),
    ];
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2538) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? const Color(0xFF2D3A54) : const Color(0xFFE5E7EB), width: 1.2),
      ),
      padding: const EdgeInsets.all(4),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF161D2B) : const Color(0xFFEEF2FF),
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Distribusi Pengguna',
                style: GoogleFonts.plusJakartaSans(fontSize: 14.5, fontWeight: FontWeight.w800, color: isDark ? Colors.white : AppTheme.textLight)),
            const SizedBox(height: 16),
            SizedBox(
              height: 180,
              child: RepaintBoundary(
                child: PieChart(PieChartData(
                  sections: sections,
                  sectionsSpace: 3,
                  centerSpaceRadius: 40,
                  pieTouchData: PieTouchData(enabled: true),
                )),
              ),
            ),
          ],
        ),
      ),
    ).animate(delay: 600.ms).fadeIn(duration: 600.ms).scale(begin: const Offset(0.95, 0.95), curve: Curves.easeOutBack).slideY(begin: 0.1, curve: Curves.easeOutQuart);
  }

  Widget _buildBarChart(ThemeData theme, bool isDark) {
    final values = [_totalSiswa.toDouble(), _totalGuru.toDouble(), _totalKelas.toDouble(), _totalMapel.toDouble()];
    final maxVal = values.reduce((curr, next) => curr > next ? curr : next);
    final maxY = (maxVal * 1.15).clamp(5.0, 1000.0);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2538) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? const Color(0xFF2D3A54) : const Color(0xFFE5E7EB), width: 1.2),
      ),
      padding: const EdgeInsets.all(4),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF161D2B) : const Color(0xFFEEF2FF),
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Overview Angka',
                style: GoogleFonts.plusJakartaSans(fontSize: 14.5, fontWeight: FontWeight.w800, color: isDark ? Colors.white : AppTheme.textLight)),
            const SizedBox(height: 16),
            SizedBox(
              height: 180,
              child: RepaintBoundary(
                child: BarChart(BarChartData(
                  maxY: maxY,
                  barTouchData: BarTouchData(enabled: true),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (v, _) {
                          final labels = ['Siswa', 'Guru', 'Kelas', 'Mapel'];
                          if (v.toInt() >= labels.length) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(labels[v.toInt()],
                                style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w800, color: isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt)),
                          );
                        },
                        reservedSize: 28,
                      ),
                    ),
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (_) => FlLine(color: isDark ? const Color(0xFF2D3A54) : const Color(0xFFE5E7EB), strokeWidth: 1),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: [
                    _bar(0, _totalSiswa.toDouble(), AppTheme.indigoPrimary, maxY, isDark),
                    _bar(1, _totalGuru.toDouble(), AppTheme.tealDeep, maxY, isDark),
                    _bar(2, _totalKelas.toDouble(), AppTheme.amber, maxY, isDark),
                    _bar(3, _totalMapel.toDouble(), AppTheme.rose, maxY, isDark),
                  ],
                )),
              ),
            ),
          ],
        ),
      ),
    ).animate(delay: 700.ms).fadeIn(duration: 600.ms).scale(begin: const Offset(0.95, 0.95), curve: Curves.easeOutBack).slideY(begin: 0.1, curve: Curves.easeOutQuart);
  }

  BarChartGroupData _bar(int x, double y, Color color, double maxY, bool isDark) {
    return BarChartGroupData(x: x, barRods: [
      BarChartRodData(
        toY: y,
        color: color,
        width: 18,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
        backDrawRodData: BackgroundBarChartRodData(
          show: true,
          toY: maxY,
          color: color.withAlpha(isDark ? 8 : 12),
        ),
      ),
    ]);
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

class _StatData {
  final IconData icon;
  final String label, value;
  final Color color;
  final Color colorEnd;
  const _StatData(this.icon, this.label, this.value, this.color, this.colorEnd);
}
