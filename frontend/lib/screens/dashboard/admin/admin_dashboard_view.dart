import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:ui';

import '../../../config/api_config.dart';

// ─── Neo-Brutalist Design Tokens ──────────────────────────────────────────────
const Color _kBgPage      = Color(0xFFF0F4F0); // Ice-blue / off-white
const Color _kBgPageDark  = Color(0xFF0D1A14);
const Color _kPrimary     = Color(0xFF2E5343); // Dark forest green

// Pastel Action Colors
const Color _kPastelGreen  = Color(0xFFB7D8CE);
const Color _kPastelBlue   = Color(0xFFB5C4E0);
const Color _kPastelOrange = Color(0xFFEEC9A3);

const _kBorder2 = BorderSide(color: Colors.black, width: 2.0);
const _kHardShadow = [
  BoxShadow(color: Colors.black, offset: Offset(4, 4), blurRadius: 0),
];
const _kSmallShadow = [
  BoxShadow(color: Colors.black, offset: Offset(2, 2), blurRadius: 0),
];
// ─────────────────────────────────────────────────────────────────────────────

class AdminDashboardView extends StatefulWidget {
  final String token;
  final Function(int)? onNavigate;
  const AdminDashboardView({super.key, required this.token, this.onNavigate});

  @override
  State<AdminDashboardView> createState() => _AdminDashboardViewState();
}

class _AdminDashboardViewState extends State<AdminDashboardView> {
  int _totalSiswa = 0, _totalGuru = 0, _totalKelas = 0, _totalAdmin = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    setState(() => _isLoading = true);
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
        _totalGuru  = users.where((u) => u['role'] == 'Guru').length;
        _totalAdmin = users.where((u) => u['role'] == 'Admin').length;
      }
      
      if (results[1].statusCode == 200) {
        final dec = jsonDecode(results[1].body);
        _totalKelas = dec is List ? dec.length : 0;
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: isDark ? _kBgPageDark : _kBgPage,
        body: const Center(child: CircularProgressIndicator(color: _kPrimary)),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? _kBgPageDark : _kBgPage,
      body: RefreshIndicator(
        onRefresh: _fetchStats,
        color: _kPrimary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── 1. Typography & Header ──
              Text(
                'SISTEM ADMINISTRASI',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                  color: isDark ? Colors.white70 : const Color(0xFF555555),
                ),
              ).animate().fadeIn().slideX(begin: -0.1),
              const SizedBox(height: 4),
              Text(
                'Selamat Datang,\nAdmin!',
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                  letterSpacing: -1.0,
                  color: isDark ? Colors.white : _kPrimary,
                ),
              ).animate(delay: 50.ms).fadeIn().slideX(begin: -0.1),
              const SizedBox(height: 28),

              // ── 2. Aksi Cepat Row ──
              _buildQuickActions(isDark),
              const SizedBox(height: 28),

              // ── 3. Statistics Grid ──
              _buildStatGrid(isDark),
              const SizedBox(height: 28),

              // ── 4. Populasi Pengguna ──
              _buildPopulationChart(isDark),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // ── 2. Aksi Cepat (Quick Action) Row ──
  Widget _buildQuickActions(bool isDark) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = (constraints.maxWidth - 28) / 3;
        final cardW = w > 140.0 ? w : 140.0;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          child: Row(
            children: [
              SizedBox(
                width: cardW,
                child: _ActionCard(
                  label: 'Tambah\nUser Baru',
                  color: _kPastelGreen,
                  icon: Icons.person_add_alt_1_rounded,
                  isDark: isDark,
                  onTap: () => widget.onNavigate?.call(1),
                ).animate(delay: 100.ms).fadeIn().slideY(begin: 0.1),
              ),
              const SizedBox(width: 14),
              SizedBox(
                width: cardW,
                child: _ActionCard(
                  label: 'Kelola\nData Kelas',
                  color: _kPastelBlue,
                  icon: Icons.class_outlined,
                  isDark: isDark,
                  onTap: () => widget.onNavigate?.call(2),
                ).animate(delay: 150.ms).fadeIn().slideY(begin: 0.1),
              ),
              const SizedBox(width: 14),
              SizedBox(
                width: cardW,
                child: _ActionCard(
                  label: 'Kirim\nBroadcast',
                  color: _kPastelOrange,
                  icon: Icons.campaign_rounded,
                  isDark: isDark,
                  onTap: () => widget.onNavigate?.call(6),
                ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.1),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── 3. Statistics Grid ──
  Widget _buildStatGrid(bool isDark) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = (constraints.maxWidth - 14) / 2; // 2 columns with 14 spacing
        return Column(
          children: [
            Row(
              children: [
                // TOTAL SISWA
                SizedBox(
                  width: w,
                  child: _StatCard(
                    title: 'TOTAL SISWA',
                    value: '$_totalSiswa',
                    isDark: isDark,
                    progressBar: true,
                  ),
                ).animate(delay: 250.ms).fadeIn().scale(begin: const Offset(0.95, 0.95)),
                const SizedBox(width: 14),
                // TOTAL GURU
                SizedBox(
                  width: w,
                  child: _StatCard(
                    title: 'TOTAL GURU',
                    value: '$_totalGuru',
                    isDark: isDark,
                  ),
                ).animate(delay: 300.ms).fadeIn().scale(begin: const Offset(0.95, 0.95)),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                // KELAS AKTIF (Dashed Border)
                SizedBox(
                  width: w,
                  child: _DashedStatCard(
                    title: 'KELAS AKTIF',
                    value: '$_totalKelas',
                    subtitle: 'Semua Jenjang',
                    isDark: isDark,
                  ),
                ).animate(delay: 350.ms).fadeIn().scale(begin: const Offset(0.95, 0.95)),
                const SizedBox(width: 14),
                // MATA PELAJARAN
                SizedBox(
                  width: w,
                  child: _StatCard(
                    title: 'MATA PELAJARAN',
                    value: '18', // Static as per mockup
                    valueColor: const Color(0xFFD36B41), // Orange-ish text
                    isDark: isDark,
                  ),
                ).animate(delay: 400.ms).fadeIn().scale(begin: const Offset(0.95, 0.95)),
              ],
            ),
          ],
        );
      },
    );
  }

  // ── 4. Populasi Pengguna (Donut Chart) ──
  Widget _buildPopulationChart(bool isDark) {
    final bg = isDark ? const Color(0xFF1A2E24) : Colors.white;
    final total = _totalSiswa + _totalGuru + _totalAdmin;
    final pSiswa = total == 0 ? 0 : (_totalSiswa / total * 100).round();
    final pGuru  = total == 0 ? 0 : (_totalGuru / total * 100).round();
    final pAdmin = total == 0 ? 0 : (_totalAdmin / total * 100).round();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: bg,
        border: const Border.fromBorderSide(_kBorder2),
        boxShadow: _kHardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Populasi Pengguna',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : _kPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 30),
          
          // Donut Chart
          SizedBox(
            height: 180,
            child: Stack(
              children: [
                PieChart(
                  PieChartData(
                    sectionsSpace: 0,
                    centerSpaceRadius: 55,
                    startDegreeOffset: -90,
                    sections: [
                      if (total == 0)
                        PieChartSectionData(
                          value: 100,
                          color: Colors.grey.shade300,
                          radius: 20,
                          showTitle: false,
                        )
                      else ...[
                        PieChartSectionData(
                          value: _totalSiswa.toDouble(),
                          color: _kPrimary,
                          radius: 24,
                          showTitle: false,
                          borderSide: const BorderSide(color: Colors.black, width: 2),
                        ),
                        PieChartSectionData(
                          value: _totalGuru.toDouble(),
                          color: _kPastelGreen,
                          radius: 24,
                          showTitle: false,
                          borderSide: const BorderSide(color: Colors.black, width: 2),
                        ),
                        PieChartSectionData(
                          value: _totalAdmin.toDouble(),
                          color: const Color(0xFF9E5D42), // Brownish
                          radius: 24,
                          showTitle: false,
                          borderSide: const BorderSide(color: Colors.black, width: 2),
                        ),
                      ],
                    ],
                  ),
                ),
                // Center text
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '100%',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      Text(
                        'TOTAL',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white54 : Colors.black54,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 34),

          // Legend List
          _ChartLegendRow(
            label: 'Siswa',
            percent: '$pSiswa%',
            color: _kPrimary,
            isDark: isDark,
          ),
          const SizedBox(height: 12),
          _ChartLegendRow(
            label: 'Guru',
            percent: '$pGuru%',
            color: _kPastelGreen,
            isDark: isDark,
          ),
          const SizedBox(height: 12),
          _ChartLegendRow(
            label: 'Admin',
            percent: '$pAdmin%',
            color: const Color(0xFFF9E8DE), // Light peach background for admin row in mockup
            indicatorColor: const Color(0xFF9E5D42),
            isDark: isDark,
          ),
        ],
      ),
    ).animate(delay: 450.ms).fadeIn().slideY(begin: 0.1);
  }
}


// ═══════════════════════════════════════════════════════════════════════════
// WIDGETS
// ═══════════════════════════════════════════════════════════════════════════

class _ActionCard extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  final bool isDark;
  final VoidCallback? onTap;

  const _ActionCard({
    required this.label,
    required this.color,
    required this.icon,
    required this.isDark,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 130,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color,
          border: const Border.fromBorderSide(_kBorder2),
          boxShadow: _kHardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border.fromBorderSide(_kBorder2),
              ),
              child: Icon(icon, size: 16, color: Colors.black),
            ),
            const Spacer(),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.black,
                height: 1.2,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color? valueColor;
  final bool isDark;
  final bool progressBar;

  const _StatCard({
    required this.title,
    required this.value,
    this.valueColor,
    required this.isDark,
    this.progressBar = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? const Color(0xFF1A2E24) : Colors.white;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        border: const Border.fromBorderSide(_kBorder2),
        boxShadow: _kHardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white70 : Colors.black,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 28,
              fontWeight: FontWeight.w300,
              color: valueColor ?? (isDark ? Colors.white : _kPrimary),
              height: 1.0,
              letterSpacing: -1.0,
            ),
          ),
          if (progressBar) ...[
            const SizedBox(height: 12),
            Container(
              height: 10,
              width: double.infinity,
              decoration: BoxDecoration(
                border: const Border.fromBorderSide(BorderSide(color: Colors.black, width: 1.5)),
                borderRadius: BorderRadius.circular(10), // slight pill shape for progress bar
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 7,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: _kPrimary,
                        borderRadius: BorderRadius.only(topLeft: Radius.circular(8), bottomLeft: Radius.circular(8)),
                      ),
                    ),
                  ),
                  Expanded(flex: 3, child: Container()),
                ],
              ),
            ),
          ] else
            const SizedBox(height: 22),
        ],
      ),
    );
  }
}


class _DashedStatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final bool isDark;

  const _DashedStatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? const Color(0xFF13231B) : const Color(0xFFE8F1F5); // slightly different bg in mockup
    return CustomPaint(
      painter: _DashedRectPainter(color: Colors.black, strokeWidth: 2, dashWidth: 5, dashSpace: 4),
      child: Container(
        padding: const EdgeInsets.all(16),
        color: bg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white70 : Colors.black,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 28,
                fontWeight: FontWeight.w300,
                color: isDark ? Colors.white : _kPrimary,
                height: 1.0,
                letterSpacing: -1.0,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white54 : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashedRectPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashWidth;
  final double dashSpace;

  _DashedRectPainter({
    required this.color,
    required this.strokeWidth,
    required this.dashWidth,
    required this.dashSpace,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    Path dashPath = Path();
    for (PathMetric measurePath in path.computeMetrics()) {
      double distance = 0;
      while (distance < measurePath.length) {
        dashPath.addPath(
          measurePath.extractPath(distance, distance + dashWidth),
          Offset.zero,
        );
        distance += dashWidth + dashSpace;
      }
    }
    canvas.drawPath(dashPath, paint);
    
    // Draw hard shadow behind dashed border manually
    final shadowPaint = Paint()
      ..color = Colors.black
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
    
    Path shadowPath = Path();
    for (PathMetric measurePath in path.computeMetrics()) {
      double distance = 0;
      while (distance < measurePath.length) {
        shadowPath.addPath(
          measurePath.extractPath(distance, distance + dashWidth),
          const Offset(4, 4), // hard shadow offset
        );
        distance += dashWidth + dashSpace;
      }
    }
    canvas.drawPath(shadowPath, shadowPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ChartLegendRow extends StatelessWidget {
  final String label;
  final String percent;
  final Color color;
  final Color? indicatorColor;
  final bool isDark;

  const _ChartLegendRow({
    required this.label,
    required this.percent,
    required this.color,
    this.indicatorColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isDark 
        ? Color.lerp(const Color(0xFF1A2E24), color, 0.2)! 
        : Color.lerp(Colors.white, color, 0.15)!;
        
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor, // Solid light tint of the color
        border: const Border.fromBorderSide(_kBorder2),
        boxShadow: _kSmallShadow,
        borderRadius: BorderRadius.circular(8), // Capsule-like but sharp enough
      ),
      child: Row(
        children: [
          Container(
            width: 14,
            height: 14,
            color: indicatorColor ?? color, // Square indicator
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const Spacer(),
          Text(
            percent,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
