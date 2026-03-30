import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../config/api_config.dart';
import '../../../widgets/app_shell.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AdminDashboardView extends StatefulWidget {
  final String token;
  const AdminDashboardView({super.key, required this.token});

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
                    // ── Hero Banner is now in Navbar ──

                    // ── Quick Actions (Top Emphasized) ──
                    _buildQuickActions(theme, isDark),
                    const SizedBox(height: 24),

                    _buildStatGrid(w),
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

  Widget _buildStatGrid(double w) {
    final stats = [
      _StatData(Icons.school_outlined, 'Total Siswa', '$_totalSiswa', AppTheme.getAdaptiveTeal(context)),
      _StatData(Icons.person_outlined, 'Total Guru', '$_totalGuru', const Color(0xFFF27F33)),
      _StatData(Icons.class_outlined, 'Total Kelas', '$_totalKelas', const Color(0xFF76AFB8)),
      _StatData(Icons.book_outlined, 'Mata Pelajaran', '$_totalMapel', AppTheme.primaryTeal),
    ];
    final crossCount = w > 1100 ? 4 : (w > 600 ? 2 : 1);
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossCount,
        childAspectRatio: w > 1100 ? 2.5 : 2.0, // Flatter/smaller aspect ratio
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: stats.length,
      itemBuilder: (_, i) {
        final s = stats[i];
        return StatCard(icon: s.icon, label: s.label, value: s.value, color: s.color)
            .animate(delay: (100 + i * 80).ms)
            .fadeIn(duration: 400.ms)
            ..scale(begin: const Offset(0.8, 0.8), curve: Curves.elasticOut, duration: 800.ms)
            .slideY(begin: 0.2, curve: Curves.easeOutCubic);
      },
    );
  }

  Widget _buildQuickActions(ThemeData theme, bool isDark) {
    return PremiumCard(
      padding: const EdgeInsets.all(24),
      accentColor: theme.primaryColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Aksi Cepat', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: theme.colorScheme.onSurface)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: theme.primaryColor.withAlpha(20), borderRadius: BorderRadius.circular(100)),
                child: Text('ADMIN ONLY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: theme.primaryColor)),
              )
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: _actionBtn(Icons.person_add_outlined, 'Tambah User', Colors.blue)),
              const SizedBox(width: 12),
              Expanded(child: _actionBtn(Icons.add_business_outlined, 'Buka Kelas', Colors.purple)),
              const SizedBox(width: 12),
              Expanded(child: _actionBtn(Icons.campaign_outlined, 'Broadcast', Colors.orange)),
              const SizedBox(width: 12),
              Expanded(child: _actionBtn(Icons.settings_suggest_outlined, 'Preferensi', Colors.teal)),
            ],
          ),
        ],
      ),
    ).animate(delay: 200.ms).fadeIn().slideY(begin: -0.1);
  }

  Widget _actionBtn(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(30)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800), textAlign: TextAlign.center),
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
          color: AppTheme.getAdaptiveTeal(context),
          title: 'Siswa',
          radius: 60,
          titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
      PieChartSectionData(
          value: _totalGuru.toDouble(),
          color: const Color(0xFFF27F33),
          title: 'Guru',
          radius: 60,
          titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
    ];
    return PremiumCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Distribusi Pengguna',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: theme.colorScheme.onSurface)),
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
    ).animate(delay: 600.ms).fadeIn(duration: 600.ms).scale(begin: const Offset(0.95, 0.95), curve: Curves.easeOutBack).slideY(begin: 0.1, curve: Curves.easeOutQuart);
  }

  Widget _buildBarChart(ThemeData theme, bool isDark) {
    final values = [_totalSiswa.toDouble(), _totalGuru.toDouble(), _totalKelas.toDouble(), _totalMapel.toDouble()];
    final maxVal = values.reduce((curr, next) => curr > next ? curr : next);
    final maxY = (maxVal * 1.15).clamp(5.0, 1000.0);

    return PremiumCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Overview Angka',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: theme.colorScheme.onSurface)),
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
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface.withAlpha(150))),
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
                  getDrawingHorizontalLine: (_) => FlLine(color: theme.colorScheme.onSurface.withAlpha(20), strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                barGroups: [
                  _bar(0, _totalSiswa.toDouble(), AppTheme.getAdaptiveTeal(context), maxY, isDark),
                  _bar(1, _totalGuru.toDouble(), const Color(0xFFF27F33), maxY, isDark),
                  _bar(2, _totalKelas.toDouble(), const Color(0xFF76AFB8), maxY, isDark),
                  _bar(3, _totalMapel.toDouble(), AppTheme.getAdaptiveTeal(context), maxY, isDark),
                ],
              )),
            ),
          ),
        ],
      ),
    ).animate(delay: 700.ms).fadeIn(duration: 600.ms).scale(begin: const Offset(0.95, 0.95), curve: Curves.easeOutBack).slideY(begin: 0.1, curve: Curves.easeOutQuart);
  }

  BarChartGroupData _bar(int x, double y, Color color, double maxY, bool isDark) {
    return BarChartGroupData(x: x, barRods: [
      BarChartRodData(
        toY: y,
        color: color,
        width: 22,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
        backDrawRodData: BackgroundBarChartRodData(
          show: true,
          toY: maxY,
          color: color.withAlpha(isDark ? 5 : 8),
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
  const _StatData(this.icon, this.label, this.value, this.color);
}


// StatData and Chart logic remains below
