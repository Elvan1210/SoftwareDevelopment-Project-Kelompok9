import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../config/api_config.dart';
import '../../../widgets/app_shell.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'siswa_tugas_detail_screen.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

class SiswaTugasView extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String token;
  final dynamic teamData; // TAMBAHAN: Menerima konteks kelas saat ini

  const SiswaTugasView({
    super.key, 
    required this.userData, 
    required this.token,
    required this.teamData, // Wajib diisi
  });

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
      final sid = Uri.encodeComponent(widget.userData['id'].toString());
      
      // UBAHAN: Ambil kelas_id spesifik
      final kelasId = widget.teamData['id'];

      // UBAHAN: Fetch hanya tugas milik kelas/tim ini saja!
      final resTugas = await http.get(Uri.parse('$baseUrl/api/tugas?kelas_id=$kelasId'), headers: headers);
      final resPengumpulan = await http.get(Uri.parse('$baseUrl/api/pengumpulan?siswa_id=$sid'), headers: headers);

      if (resTugas.statusCode == 200) {
        final dec = jsonDecode(resTugas.body);
        setState(() {
          _allTugas = dec is List ? dec : [];
        });
      }
      if (resPengumpulan.statusCode == 200) {
        final dec = jsonDecode(resPengumpulan.body);
        setState(() {
          _pengumpulan = dec is List ? dec : [];
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
      return _buildSkeleton();
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
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
        icon: LucideIcons.clipboardCheck,
        message: 'Tidak ada tugas\n$statusLabel.',
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: LayoutBuilder(
        builder: (ctx, c) {
          final w = c.maxWidth;
          final padding = Breakpoints.screenPadding(w);
          final crossCount = w >= Breakpoints.tablet ? 2 : 1;

          final sortedTasks = List<dynamic>.from(tugasList);
          sortedTasks.sort((a, b) {
            final dA = a['deadline'];
            final dB = b['deadline'];
            if (dA == null && dB == null) return 0;
            if (dA == null) return 1;
            if (dB == null) return -1;
            final dtA = DateTime.tryParse(dA);
            final dtB = DateTime.tryParse(dB);
            if (dtA != null && dtB != null) return dtA.compareTo(dtB);
            return dA.toString().compareTo(dB.toString());
          });

          final Map<String, List<dynamic>> groups = {};
          for (final t in sortedTasks) {
            String dateLabel = 'Tanpa Tenggat Waktu';
            if (t['deadline'] != null && t['deadline'].toString().isNotEmpty) {
              final dt = DateTime.tryParse(t['deadline']);
              if (dt != null) {
                dateLabel = DateFormat('MMM d, EEEE').format(dt);
              } else {
                dateLabel = t['deadline'];
              }
            }
            groups.putIfAbsent(dateLabel, () => []).add(t);
          }
          final groupKeys = groups.keys.toList();

          return ListView.builder(
            padding: padding,
            itemCount: groupKeys.length,
            itemBuilder: (_, i) {
              final key = groupKeys[i];
              final items = groups[key]!;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 24, 4, 16),
                    child: Text(key, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.grey.shade700)),
                  ),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossCount,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: crossCount == 1 ? 3.8 : 2.0,
                    ),
                    itemCount: items.length,
                    itemBuilder: (_, j) {
                      final t = items[j];
                      return _TugasCard(
                        tugas: t,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SiswaTugasDetailScreen(tugas: t, userData: userData, token: token))),
                      ).animate(delay: (j * 50).ms).fadeIn(duration: 400.ms).slideY(begin: 0.1, curve: Curves.easeOutQuart);
                    },
                  ),
                  const SizedBox(height: 20),
                  if (i < groupKeys.length - 1) const Divider(color: Colors.white24, height: 1),
                ],
              );
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
            child: const Icon(LucideIcons.clipboardList, color: accent, size: 22),
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
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withAlpha(20),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  _formatDeadline(tugas['deadline']),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFF59E0B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          const SizedBox(width: 8),
          Icon(LucideIcons.chevronRight, color: theme.colorScheme.onSurface.withAlpha(100)),
        ],
      ),
    );
  }
}
