import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../config/api_config.dart';
import '../../../widgets/app_shell.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'guru_team_detail_layout.dart';

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
  List<dynamic> _kelasList = [];

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
    setState(() => _isLoading = true);
    await Future.wait([
      _fetchStats(),
      _fetchKelasGuru(),
    ]);
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
    } catch (e) {
      debugPrint('Error fetch kelas: $e');
    }
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
        _totalTugas = d.where((t) => t['guru_id'].toString() == widget.userData['id'].toString()).length;
      }
      if (results[1].statusCode == 200) {
        final dec = jsonDecode(results[1].body);
        List d = dec is List ? dec : [];
        _totalMateri = d.where((m) => m['guru_id'].toString() == widget.userData['id'].toString()).length;
      }
      if (results[2].statusCode == 200) {
        final dec = jsonDecode(results[2].body);
        List d = dec is List ? dec : [];
        _totalNilai = d.where((n) => n['guru_id'].toString() == widget.userData['id'].toString()).length;
      }
      if (results[3].statusCode == 200) {
        final dec = jsonDecode(results[3].body);
        List d = dec is List ? dec : [];
        _totalPengumuman = d.where((p) => p['guru_id'].toString() == widget.userData['id'].toString()).length;
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    // Name and Role are now in Navbar

    if (_isLoading) {
      return AppShell(child: _buildSkeleton());
    }

    return AppShell(
      child: RefreshIndicator(
        onRefresh: _fetchInitialData,
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
                      // ── Hero Greeting is now in Navbar ──

                      // ── Your Classes Grid ──────────────────────
                      const SectionHeader(
                        title: 'Kelas Ampuan',
                        subtitle: 'Kelola materi, tugas, dan nilai siswa',
                        action: null,
                      ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.05, curve: Curves.easeOutQuart),
                      const SizedBox(height: 16),
                      _buildClassGrid(w, theme, isDark),
                      const SizedBox(height: 32),

                      // ── Stats Section ──────────────────────────
                      const SectionHeader(
                        title: 'Statistik Konten',
                        subtitle: 'Ringkasan distribusi pembelajaran kamu',
                      ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.05, curve: Curves.easeOutQuart),
                      const SizedBox(height: 16),
                      _buildStatGrid(w),
                      const SizedBox(height: 32),

                      // Chart
                      const SectionHeader(
                        title: 'Grafik Aktivitas',
                        subtitle: 'Visualisasi kontribusi mengajar',
                      ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.05, curve: Curves.easeOutQuart),
                      const SizedBox(height: 16),
                      _buildChart(theme, isDark),
                      const SizedBox(height: 24),
                    ]),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildClassGrid(double w, ThemeData theme, bool isDark) {
    if (_kelasList.isEmpty) {
      return const EmptyState(
        icon: Icons.grid_view_rounded,
        message: 'Kamu belum ditugaskan ke kelas manapun.',
        color: Colors.teal,
      );
    }

    final crossCount = w > 1200 ? 4 : (w > 800 ? 3 : (w > 500 ? 2 : 1));
    
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossCount,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.6,
      ),
      itemCount: _kelasList.length,
      itemBuilder: (ctx, i) {
        final k = _kelasList[i];
        return _GuruClassCard(kelas: k)
            .animate(delay: (200 + i * 80).ms)
            .fadeIn(duration: 400.ms)
            .scale(begin: const Offset(0.9, 0.9), curve: Curves.elasticOut, duration: 800.ms);
      },
    );
  }

  Widget _buildStatGrid(double w) {
    final stats = [
      _StatData(Icons.assignment_outlined, 'Tugas Dibuat', '$_totalTugas', AppTheme.getAdaptiveTeal(context)),
      _StatData(Icons.menu_book_outlined, 'Materi Dibuat', '$_totalMateri', const Color(0xFFF27F33)),
      _StatData(Icons.grade_outlined, 'Nilai Input', '$_totalNilai', const Color(0xFF76AFB8)),
      _StatData(Icons.campaign_outlined, 'Pengumuman', '$_totalPengumuman', AppTheme.primaryTeal),
    ];

    final crossCount = w > 1100 ? 4 : (w > 600 ? 2 : 1);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossCount,
        childAspectRatio: w > 1100 ? 2.5 : 2.0,

        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: stats.length,
      itemBuilder: (_, i) {
        final s = stats[i];
        return StatCard(icon: s.icon, label: s.label, value: s.value, color: s.color)
            .animate(delay: (300 + i * 100).ms)
            .fadeIn(duration: 400.ms)
            .scale(begin: const Offset(0.8, 0.8), curve: Curves.elasticOut, duration: 800.ms)
            .slideY(begin: 0.2, curve: Curves.easeOutCubic);
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
      AppTheme.getAdaptiveTeal(context),
      const Color(0xFFF27F33),
      const Color(0xFF76AFB8),
      AppTheme.getAdaptiveTeal(context),
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
    ).animate(delay: 600.ms).fadeIn(duration: 600.ms).scale(begin: const Offset(0.95, 0.95), curve: Curves.easeOutBack).slideY(begin: 0.1, curve: Curves.easeOutQuart);
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

class _GuruClassCard extends StatelessWidget {
  final dynamic kelas;
  const _GuruClassCard({required this.kelas});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = Color(int.parse(kelas['warna_card'] ?? '4282032886'));
    
    String initials = "??";
    final nama = (kelas['nama_kelas'] as String? ?? "").trim();
    if (nama.isNotEmpty) {
      final parts = nama.split(' ');
      if (parts.length >= 2) {
        initials = (parts[0][0] + parts[1][0]).toUpperCase();
      } else {
        initials = parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
      }
    }

    return PremiumCard(
      accentColor: color,
      padding: EdgeInsets.zero,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => GuruTeamDetailLayout(
              userData: (context.findAncestorStateOfType<_GuruDashboardViewState>()!).widget.userData,
              token: (context.findAncestorStateOfType<_GuruDashboardViewState>()!).widget.token,
              teamData: kelas,
            ),
          ),
        );
      },
      child: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                   Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(initials, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${kelas['kode_kelas'] ?? ''}',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: color),
                        ),
                        Text(
                          kelas['nama_kelas'] ?? '-',
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, height: 1.2),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${(kelas['siswa_ids'] as List?)?.length ?? 0} Siswa Terdaftar',
                          style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurface.withAlpha(120)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: theme.dividerColor.withAlpha(30))),
            ),
            child: Row(
              children: [
                _buildMiniIcon(Icons.assignment_outlined),
                const SizedBox(width: 12),
                _buildMiniIcon(Icons.menu_book_outlined),
                const SizedBox(width: 12),
                _buildMiniIcon(Icons.grade_outlined),
                const Spacer(),
                const Icon(Icons.settings_outlined, size: 14, color: Colors.grey),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniIcon(IconData icon) {
    return Icon(icon, size: 14, color: Colors.grey);
  }
}

// ─── Sub Widgets ─────────────────────────────────────────────────────────────

class _StatData {
  final IconData icon;
  final String label, value;
  final Color color;
  const _StatData(this.icon, this.label, this.value, this.color);
}

class SectionHeader extends StatelessWidget {
  final String title, subtitle;
  final Widget? action;
  const SectionHeader({super.key, required this.title, required this.subtitle, this.action});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900, letterSpacing: -0.5)),
            const SizedBox(height: 4),
            Text(subtitle, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withAlpha(120), fontWeight: FontWeight.w500)),
          ],
        ),
        if (action != null) action!,
      ],
    );
  }
}
