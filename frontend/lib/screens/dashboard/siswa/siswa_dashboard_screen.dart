import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../config/api_config.dart';
import '../../../widgets/app_shell.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'siswa_tugas_detail_screen.dart';
import 'siswa_team_detail_layout.dart';

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
  List<dynamic> _kelasList = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final headers = {'Authorization': 'Bearer ${widget.token}'};
      final siswaId = Uri.encodeComponent(widget.userData['id'].toString());
      
      final results = await Future.wait([
        http.get(Uri.parse('$baseUrl/api/kelas?siswa_id=$siswaId'), headers: headers),
        http.get(Uri.parse('$baseUrl/api/pengumuman'), headers: headers),
        http.get(Uri.parse('$baseUrl/api/pengumpulan?siswa_id=$siswaId'), headers: headers),
      ]);

      if (results[0].statusCode == 200) {
        final dec = jsonDecode(results[0].body);
        _kelasList = dec is List ? dec : [];
        
        // Fetch all tugas for all joined classes
        List<dynamic> allTugas = [];
        for (var k in _kelasList) {
           final tResp = await http.get(Uri.parse('$baseUrl/api/tugas?kelas=${Uri.encodeComponent(k['nama_kelas'])}'), headers: headers);
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    // Name and Role are now in Navbar

    if (_isLoading) {
      return AppShell(child: _buildSkeleton(theme));
    }

    return AppShell(
      child: RefreshIndicator(
        onRefresh: _fetchData,
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
                        title: 'Kelas Kamu',
                        subtitle: 'Akses cepat ke materi & tugas mata pelajaran',
                        action: null,
                      ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.05, curve: Curves.easeOutQuart),
                      const SizedBox(height: 16),
                      _buildClassGrid(w, theme, isDark),
                      const SizedBox(height: 32),
                      // ── Stat Cards ─────────────────────────────

                      _buildStatCards(w, theme, isDark),
                      const SizedBox(height: 40),

                      // ── Tugas Section ──────────────────────────
                      SectionHeader(
                        title: 'Tugas Mendatang',
                        subtitle: '${_tugasList.length} tugas aktif dari semua kelas',
                        action: null,
                      ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.05, curve: Curves.easeOutQuart),
                      const SizedBox(height: 16),
                      _buildTugasSection(theme, isDark),
                      const SizedBox(height: 32),

                      // ── Pengumuman Section ─────────────────────
                      const SectionHeader(
                        title: 'Pengumuman',
                        subtitle: 'Info terbaru untuk kamu',
                      ).animate().fadeIn(delay: 400.ms).slideX(begin: -0.05, curve: Curves.easeOutQuart),
                      const SizedBox(height: 16),
                      _buildPengumumanSection(theme, isDark),
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
        message: 'Kamu belum terdaftar di kelas manapun.\nHubungi Admin.',
        color: Colors.blueGrey,
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
        return _SiswaClassCard(kelas: k)
            .animate(delay: (200 + i * 80).ms)
            .fadeIn(duration: 400.ms)
            .scale(begin: const Offset(0.9, 0.9), curve: Curves.elasticOut, duration: 800.ms);
      },
    );
  }

  Widget _buildStatCards(double w, ThemeData theme, bool isDark) {
    int lewatDeadline = 0;
    int belum = 0;
    int selesai = 0;

    for (var t in _tugasList) {
      if (_pengumpulanList.any((p) => p['tugas_id'].toString() == t['id'].toString())) {
        selesai++;
        continue;
      }
      final dlStr = t['deadline'];
      if (dlStr != null && dlStr.toString().isNotEmpty) {
        final dl = DateTime.tryParse(dlStr.toString());
        if (dl != null && dl.isBefore(DateTime.now())) {
          lewatDeadline++;
          continue;
        }
      }
      belum++;
    }

    final stats = [
      _StatData(Icons.pending_actions_outlined, 'Belum Dikumpul', belum.toString(), const Color(0xFFF27F33)),
      _StatData(Icons.warning_amber_rounded, 'Lewat Deadline', lewatDeadline.toString(), Colors.redAccent),
      _StatData(Icons.task_alt_outlined, 'Selesai', selesai.toString(), const Color(0xFF10B981)),
    ];

    final crossCount = w > 800 ? 3 : 1;

    return RepaintBoundary(
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossCount,
          childAspectRatio: w > 800 ? 2.5 : 2.0,
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
              .animate(delay: (300 + i * 100).ms)
              .fadeIn(duration: 400.ms)
              .scale(begin: const Offset(0.8, 0.8), curve: Curves.elasticOut, duration: 800.ms)
              .slideY(begin: 0.2, curve: Curves.easeOutCubic);
        },
      ),
    );
  }


  Widget _buildTugasSection(ThemeData theme, bool isDark) {
    if (_tugasList.isEmpty) {
      return const EmptyState(
        icon: Icons.assignment_turned_in_outlined,
        message: 'Tidak ada tugas aktif\ndi kelasmu.',
        color: Color(0xFF76AFB8),
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
                .animate(delay: (400 + i * 80).ms)
                .fadeIn(duration: 400.ms)
                .slideX(begin: -0.1, curve: Curves.easeOutQuart);
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
              .animate(delay: (500 + i * 80).ms)
              .fadeIn(duration: 400.ms)
              .slideX(begin: -0.1, curve: Curves.easeOutQuart);
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



class _TugasCard extends StatelessWidget {
  final dynamic tugas;
  final VoidCallback onTap;

  const _TugasCard({required this.tugas, required this.onTap});

  String _formatDeadline(String? dl) {
    if (dl == null || dl.isEmpty) return '-';
    final parsed = DateTime.tryParse(dl);
    if (parsed != null) {
      return DateFormat('dd MMM yyyy, HH:mm').format(parsed);
    }
    return dl;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = AppTheme.getAdaptiveTeal(context);

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
            child: Icon(Icons.assignment_outlined, color: color, size: 22),
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
                color: const Color(0xFFF27F33).withAlpha(20),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(_formatDeadline(tugas['deadline']),
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFFF27F33))),
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
    final color = AppTheme.getAdaptiveTeal(context);

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
            child: Icon(Icons.campaign_rounded, color: color, size: 22),
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

class _SiswaClassCard extends StatelessWidget {
  final dynamic kelas;
  const _SiswaClassCard({required this.kelas});

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
            builder: (_) => SiswaTeamDetailLayout(
              userData: (context.findAncestorStateOfType<_SiswaDashboardScreenState>()!).widget.userData,
              token: (context.findAncestorStateOfType<_SiswaDashboardScreenState>()!).widget.token,
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
                          'Guru: ${kelas['guru_nama'] ?? '-'}',
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
            child: const Row(
              children: [
                Icon(Icons.assignment_outlined, size: 14, color: Colors.grey),
                SizedBox(width: 12),
                Icon(Icons.folder_open_outlined, size: 14, color: Colors.grey),
                Spacer(),
                Icon(Icons.chevron_right_rounded, size: 16, color: Colors.grey),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

