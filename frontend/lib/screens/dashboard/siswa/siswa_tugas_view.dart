import '../../../config/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../config/api_config.dart';
import '../../../widgets/app_shell.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'siswa_tugas_detail_screen.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';





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
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(color: Theme.of(context).colorScheme.onSurface, width: 2),
        boxShadow: [BoxShadow(color: Theme.of(context).colorScheme.onSurface, offset: const Offset(4, 4), blurRadius: 0)],
      ),
      child: TabBar(
        controller: _tabController,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        indicator: BoxDecoration(
          color: AppTheme.primary,
          border: Border.all(color: Theme.of(context).colorScheme.onSurface, width: 2),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: isDark ? Colors.white70 : Theme.of(context).colorScheme.onSurface,
        labelStyle: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900, letterSpacing: 0.3),
        unselectedLabelStyle: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
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
                    padding: const EdgeInsets.fromLTRB(4, 24, 4, 12),
                    child: Row(
                      children: [
                        Text(
                          key.toUpperCase(),
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w900,
                            color: AppTheme.primary,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Divider(
                            color: Theme.of(context).dividerColor,
                            height: 1,
                            thickness: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  LayoutBuilder(
                    builder: (ctx, constraints) {
                      final cw = constraints.maxWidth;
                      final isWide = cw >= 750;
                      if (isWide) {
                        return Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          children: List.generate(items.length, (j) {
                            final t = items[j];
                            final cardW = (cw - 16) / 2;
                            return SizedBox(
                              width: cardW,
                              child: _TugasCard(
                                tugas: t,
                                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SiswaTugasDetailScreen(tugas: t, userData: userData, token: token))),
                              ).animate(delay: (j * 50).ms).fadeIn(duration: 400.ms).slideY(begin: 0.1, curve: Curves.easeOutQuart),
                            );
                          }),
                        );
                      } else {
                        return Column(
                          children: List.generate(items.length, (j) {
                            final t = items[j];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _TugasCard(
                                tugas: t,
                                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SiswaTugasDetailScreen(tugas: t, userData: userData, token: token))),
                              ).animate(delay: (j * 50).ms).fadeIn(duration: 400.ms).slideY(begin: 0.1, curve: Curves.easeOutQuart),
                            );
                          }),
                        );
                      }
                    }
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

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border.all(color: Theme.of(context).colorScheme.onSurface, width: 2),
          boxShadow: [BoxShadow(color: Theme.of(context).colorScheme.onSurface, offset: const Offset(4, 4), blurRadius: 0)],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.primary,
                border: Border.all(color: Theme.of(context).colorScheme.onSurface, width: 1.5),
                boxShadow: [BoxShadow(color: Theme.of(context).colorScheme.onSurface, offset: const Offset(2, 2), blurRadius: 0)],
              ),
              child: const Icon(LucideIcons.clipboardList, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    tugas['judul'] ?? '-',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900,
                      color: Theme.of(context).textTheme.bodyLarge!.color!,
                      letterSpacing: -0.3),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Mapel: ${tugas['mapel'] ?? '-'}',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700,
                      color: Theme.of(context).textTheme.bodyMedium!.color!,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (tugas['deadline'] != null && tugas['deadline'].toString().isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFDE68A),
                  border: Border.all(color: Theme.of(context).colorScheme.onSurface, width: 1.5),
                  boxShadow: [BoxShadow(color: Theme.of(context).colorScheme.onSurface, offset: const Offset(2, 2), blurRadius: 0)],
                ),
                child: Text(
                  _formatDeadline(tugas['deadline']),
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900,
                    color: Theme.of(context).colorScheme.onSurface,
                    letterSpacing: 0.2),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 12),
            ],
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border.all(color: Theme.of(context).colorScheme.onSurface, width: 1.5),
                boxShadow: [BoxShadow(color: Theme.of(context).colorScheme.onSurface, offset: const Offset(2, 2), blurRadius: 0)],
              ),
              child: Icon(
                LucideIcons.chevronRight,
                color: Theme.of(context).textTheme.bodyLarge!.color!,
                size: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
