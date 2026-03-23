import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../config/api_config.dart';
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
  List<dynamic> _tugasList = [];
  List<dynamic> _pengumumanList = [];
  List<dynamic> _pengumpulanList = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final headers = {'Authorization': 'Bearer ${widget.token}'};
      final results = await Future.wait([
        http.get(Uri.parse('$baseUrl/api/tugas'), headers: headers),
        http.get(Uri.parse('$baseUrl/api/pengumuman'), headers: headers),
        http.get(Uri.parse('$baseUrl/api/pengumpulan'), headers: headers),
      ]);
      if (results[0].statusCode == 200) {
        final dec = jsonDecode(results[0].body);
        List all = dec is List ? dec : [];
        _tugasList = all
            .where((t) =>
                t['mapel'] == widget.userData['kelas'] ||
                t['kelas'] == widget.userData['kelas'])
            .toList();
      }
      if (results[1].statusCode == 200) {
        final dec = jsonDecode(results[1].body);
        _pengumumanList = dec is List ? dec : [];
      }
      if (results[2].statusCode == 200) {
        final dec = jsonDecode(results[2].body);
        List all = dec is List ? dec : [];
        _pengumpulanList = all.where((p) => p['siswa_id'] == widget.userData['id']).toList();
      }
    } catch (e) {
      debugPrint(e.toString());
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final nama = widget.userData['nama'] ?? 'Siswa';
    final kelas = widget.userData['kelas'] ?? '-';
    final initials = nama.trim().split(' ').map((e) => e[0]).take(2).join().toUpperCase();

    if (_isLoading) {
      return AppShell(
        child: _buildSkeleton(theme),
      );
    }

    return AppShell(
      child: RefreshIndicator(
        onRefresh: _fetchData,
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
                  // ── Hero Greeting ──────────────────────────
                  _HeroGreeting(
                    initials: initials,
                    nama: nama,
                    kelas: kelas,
                    isDark: isDark,
                    primaryColor: theme.primaryColor,
                  ),
                  const SizedBox(height: 28),

                  // ── Stat Cards ─────────────────────────────
                  _buildStatCards(w, theme, isDark),
                  const SizedBox(height: 32),

                  // ── Tugas Section ──────────────────────────
                  SectionHeader(
                    title: 'Tugas Aktif',
                    subtitle: '${_tugasList.length} tugas di kelasmu',
                    action: null,
                  ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),
                  const SizedBox(height: 16),
                  _buildTugasSection(theme, isDark),
                  const SizedBox(height: 32),

                  // ── Pengumuman Section ─────────────────────
                  const SectionHeader(
                    title: 'Pengumuman',
                    subtitle: 'Info terbaru untuk kamu',
                  ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),
                  const SizedBox(height: 16),
                  _buildPengumumanSection(theme, isDark),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatCards(double w, ThemeData theme, bool isDark) {
    int totalTugas = _tugasList.length;
    int selesai = _tugasList.where((t) => _pengumpulanList.any((p) => p['tugas_id'].toString() == t['id'].toString())).length;
    int belum = totalTugas - selesai;
    int pengumumanLength = _pengumumanList.length;

    final stats = [
      _StatData(Icons.assignment_outlined, 'Total Tugas', totalTugas.toString(), const Color(0xFF3B82F6)),
      _StatData(Icons.pending_actions_outlined, 'Belum Dikumpul', belum.toString(), const Color(0xFFF59E0B)),
      _StatData(Icons.campaign_outlined, 'Pengumuman', pengumumanLength.toString(), const Color(0xFF10B981)),
      _StatData(Icons.task_alt_outlined, 'Selesai', selesai.toString(), const Color(0xFF8B5CF6)),
    ];

    final crossCount = w > 800 ? 4 : (w > 500 ? 2 : 2);

    return RepaintBoundary(
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossCount,
          childAspectRatio: w > 800 ? 1.6 : 1.5,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: stats.length,
        itemBuilder: (ctx, i) {
          final s = stats[i];
          return StatCard(
            icon: s.icon,
            label: s.label,
            value: s.value,
            color: s.color,
          )
              .animate(delay: (200 + i * 80).ms)
              .fadeIn(duration: 400.ms)
              .slideY(begin: 0.15, curve: Curves.easeOutQuart);
        },
      ),
    );
  }

  Widget _buildTugasSection(ThemeData theme, bool isDark) {
    if (_tugasList.isEmpty) {
      return const EmptyState(
        icon: Icons.assignment_turned_in_outlined,
        message: 'Tidak ada tugas aktif\ndi kelasmu.',
        color: Color(0xFF3B82F6),
      );
    }
    return RepaintBoundary(
      child: Column(
        children: List.generate(
          _tugasList.length.clamp(0, 5),
          (i) {
            final t = _tugasList[i];
            return _TugasCard(
              tugas: t,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SiswaTugasDetailScreen(
                    tugas: t,
                    userData: widget.userData,
                    token: widget.token,
                  ),
                ),
              ),
            )
                .animate(delay: (300 + i * 80).ms)
                .fadeIn(duration: 400.ms)
                .slideX(begin: -0.05, curve: Curves.easeOutQuart);
          },
        ),
      ),
    );
  }

  Widget _buildPengumumanSection(ThemeData theme, bool isDark) {
    if (_pengumumanList.isEmpty) {
      return const EmptyState(
        icon: Icons.campaign_outlined,
        message: 'Belum ada pengumuman.',
        color: Color(0xFF10B981),
      );
    }
    return Column(
      children: List.generate(
        _pengumumanList.length.clamp(0, 3),
        (i) {
          final p = _pengumumanList[i];
          return _PengumumanCard(pengumuman: p)
              .animate(delay: (400 + i * 80).ms)
              .fadeIn(duration: 400.ms)
              .slideX(begin: -0.05, curve: Curves.easeOutQuart);
        },
      ),
    );
  }

  Widget _buildSkeleton(ThemeData theme) {
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
        ...List.generate(3, (_) => const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: SkeletonLoader(height: 80, radius: 20),
        )),
      ]),
    );
  }
}

// ── Sub Widgets ─────────────────────────────────────────────────────────────

class _StatData {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _StatData(this.icon, this.label, this.value, this.color);
}

class _HeroGreeting extends StatelessWidget {
  final String initials, nama, kelas;
  final bool isDark;
  final Color primaryColor;

  const _HeroGreeting({
    required this.initials,
    required this.nama,
    required this.kelas,
    required this.isDark,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: PremiumCard(
        accentColor: primaryColor,
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            // Avatar
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
                  Text('Selamat datang 👋',
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
                    child: Text('Kelas $kelas',
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

class _TugasCard extends StatelessWidget {
  final dynamic tugas;
  final VoidCallback onTap;

  const _TugasCard({required this.tugas, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const color = Color(0xFF3B82F6);

    return PremiumCard(
      onTap: onTap,
      accentColor: color,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.assignment_outlined, color: color, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tugas['judul'] ?? '-',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text('Mapel: ${tugas['mapel'] ?? '-'}',
                    style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withAlpha(150))),
              ],
            ),
          ),
          if (tugas['deadline'] != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withAlpha(20),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(tugas['deadline'],
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFFF59E0B))),
            ),
          const SizedBox(width: 8),
          Icon(Icons.chevron_right_rounded, color: theme.colorScheme.onSurface.withAlpha(100)),
        ],
      ),
    );
  }
}

class _PengumumanCard extends StatelessWidget {
  final dynamic pengumuman;
  const _PengumumanCard({required this.pengumuman});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const color = Color(0xFF10B981);

    return PremiumCard(
      accentColor: color,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.campaign_rounded, color: color, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(pengumuman['judul'] ?? '-',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 6),
                Text(pengumuman['isi'] ?? '-',
                    style: TextStyle(fontSize: 13, height: 1.5, color: theme.colorScheme.onSurface.withAlpha(170)),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                if (pengumuman['tanggal'] != null) ...[
                  const SizedBox(height: 8),
                  Text(pengumuman['tanggal'],
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface.withAlpha(120))),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
