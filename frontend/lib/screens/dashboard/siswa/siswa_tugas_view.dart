import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../config/api_config.dart';
import '../../../widgets/app_shell.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'siswa_tugas_detail_screen.dart';

class SiswaTugasView extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String token;
  const SiswaTugasView({super.key, required this.userData, required this.token});

  @override
  State<SiswaTugasView> createState() => _SiswaTugasViewState();
}

class _SiswaTugasViewState extends State<SiswaTugasView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _allTugas = [];
  List<dynamic> _pengumpulan = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final headers = {'Authorization': 'Bearer ${widget.token}'};
      final resTugas = await http.get(Uri.parse('$baseUrl/api/tugas'), headers: headers);
      final resPengumpulan = await http.get(Uri.parse('$baseUrl/api/pengumpulan'), headers: headers);

      if (resTugas.statusCode == 200) {
        final dec = jsonDecode(resTugas.body);
        List all = dec is List ? dec : [];
        setState(() {
          _allTugas = all.where((t) => t['kelas'] == widget.userData['kelas'] || t['mapel'] == widget.userData['kelas']).toList();
        });
      }
      if (resPengumpulan.statusCode == 200) {
        final dec = jsonDecode(resPengumpulan.body);
        List all = dec is List ? dec : [];
        setState(() {
          _pengumpulan = all.where((p) => p['siswa_id'] == widget.userData['id']).toList();
        });
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  bool _sudahDikumpulkan(String tugasId) {
    return _pengumpulan.any((p) => p['tugas_id'].toString() == tugasId.toString());
  }

  List<dynamic> get _tugasBelum => _allTugas.where((t) => !_sudahDikumpulkan(t['id'].toString())).toList();
  List<dynamic> get _tugasSelesai => _allTugas.where((t) => _sudahDikumpulkan(t['id'].toString())).toList();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_isLoading) {
      return AppShell(child: _buildSkeleton());
    }

    return AppShell(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(
          children: [
            // ── Premium Tab Bar ────────────────────────────────────
            _buildTabBar(theme, isDark),

            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _TugasList(
                    tugasList: _allTugas,
                    userData: widget.userData,
                    token: widget.token,
                    onRefresh: _fetchData,
                    statusLabel: 'Semua',
                  ),
                  _TugasList(
                    tugasList: _tugasBelum,
                    userData: widget.userData,
                    token: widget.token,
                    onRefresh: _fetchData,
                    statusLabel: 'Belum Selesai',
                  ),
                  _TugasList(
                    tugasList: _tugasSelesai,
                    userData: widget.userData,
                    token: widget.token,
                    onRefresh: _fetchData,
                    statusLabel: 'Selesai',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar(ThemeData theme, bool isDark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withAlpha(isDark ? 100 : 200),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: theme.colorScheme.onSurface.withAlpha(20)),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 20, offset: const Offset(0, 10))
        ],
      ),
      child: TabBar(
        controller: _tabController,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(100),
          color: theme.primaryColor,
          boxShadow: [
            BoxShadow(color: theme.primaryColor.withAlpha(80), blurRadius: 10, offset: const Offset(0, 4))
          ],
        ),
        labelColor: Colors.white,
        unselectedLabelColor: theme.colorScheme.onSurface.withAlpha(150),
        labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 0.3),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        tabs: const [
          Tab(text: 'Semua'),
          Tab(text: 'Belum'),
          Tab(text: 'Selesai'),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.2, curve: Curves.easeOutCubic);
  }

  Widget _buildSkeleton() {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(24),
          child: SkeletonLoader(height: 50, radius: 100),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: 5,
            itemBuilder: (_, __) => const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: SkeletonLoader(height: 80, radius: 24),
            ),
          ),
        ),
      ],
    );
  }
}

class _TugasList extends StatelessWidget {
  final List<dynamic> tugasList;
  final Map<String, dynamic> userData;
  final String token;
  final Future<void> Function() onRefresh;
  final String statusLabel;

  const _TugasList({
    required this.tugasList,
    required this.userData,
    required this.token,
    required this.onRefresh,
    required this.statusLabel,
  });

  @override
  Widget build(BuildContext context) {
    if (tugasList.isEmpty) {
      return EmptyState(
        icon: Icons.assignment_turned_in_outlined,
        message: 'Tidak ada tugas\n$statusLabel.',
        color: const Color(0xFF3B82F6),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: LayoutBuilder(
        builder: (ctx, c) {
          final w = c.maxWidth;
          final padding = Breakpoints.screenPadding(w);
          final crossCount = w >= Breakpoints.tablet ? 2 : 1;

          return GridView.builder(
            padding: padding,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossCount,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: crossCount == 1 ? 3.8 : 2.0,
            ),
            itemCount: tugasList.length,
            itemBuilder: (_, i) {
              final t = tugasList[i];
              return _TugasCard(
                tugas: t,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SiswaTugasDetailScreen(
                      tugas: t,
                      userData: userData,
                      token: token,
                    ),
                  ),
                ),
              ).animate(delay: (i * 50).ms).fadeIn(duration: 400.ms).slideY(begin: 0.1, curve: Curves.easeOutQuart);
            },
          );
        },
      ),
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
    const accent = Color(0xFF3B82F6);

    return PremiumCard(
      onTap: onTap,
      accentColor: accent,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: accent.withAlpha(20),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.assignment_outlined, color: accent, size: 22),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(tugas['judul'] ?? '-',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, letterSpacing: -0.3),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text('Mapel: ${tugas['mapel'] ?? '-'}',
                    style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface.withAlpha(150))),
              ],
            ),
          ),
          if (tugas['deadline'] != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withAlpha(20),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(tugas['deadline'],
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFFF59E0B))),
            ),
          const SizedBox(width: 12),
          Icon(Icons.chevron_right_rounded, color: theme.colorScheme.onSurface.withAlpha(100)),
        ],
      ),
    );
  }
}
