import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../config/api_config.dart';
import '../../../config/theme.dart';
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
  List<dynamic> _tugasList        = [];
  List<dynamic> _pengumumanList   = [];
  List<dynamic> _pengumpulanList  = [];
  List<dynamic> _kelasList        = [];
  Set<String>   _readIds          = {};

  @override
  void initState() {
    super.initState();
    _loadAndFetch();
  }

  Future<void> _loadAndFetch() async {
    final prefs = await SharedPreferences.getInstance();
    final list  = prefs.getStringList('read_pengumuman_${widget.userData['id']}') ?? [];
    _readIds = list.toSet();
    await _fetchData();
  }

  Future<void> _markRead(String id) async {
    setState(() => _readIds.add(id));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'read_pengumuman_${widget.userData['id']}',
      _readIds.toList(),
    );
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final headers  = {'Authorization': 'Bearer ${widget.token}'};
      final siswaId  = Uri.encodeComponent(widget.userData['id'].toString());

      final results = await Future.wait([
        http.get(Uri.parse('$baseUrl/api/kelas?siswa_id=$siswaId'), headers: headers),
        http.get(Uri.parse('$baseUrl/api/pengumuman'), headers: headers),
        http.get(Uri.parse('$baseUrl/api/pengumpulan?siswa_id=$siswaId'), headers: headers),
      ]);

      if (results[0].statusCode == 200) {
        final dec = jsonDecode(results[0].body);
        _kelasList = dec is List ? dec : [];
        List<dynamic> allTugas = [];
        for (var k in _kelasList) {
          final tResp = await http.get(
            Uri.parse('$baseUrl/api/tugas?kelas=${Uri.encodeComponent(k['nama_kelas'])}'),
            headers: headers,
          );
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

  // ── Stat computation ─────────────────────────────────────────────────────
  Map<String, int> get _stats {
    int lewat = 0, belum = 0, selesai = 0;
    for (var t in _tugasList) {
      if (_pengumpulanList.any((p) => p['tugas_id'].toString() == t['id'].toString())) {
        selesai++;
        continue;
      }
      final dl = DateTime.tryParse(t['deadline']?.toString() ?? '');
      if (dl != null && dl.isBefore(DateTime.now())) { lewat++; continue; }
      belum++;
    }
    return {'belum': belum, 'lewat': lewat, 'selesai': selesai};
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return AppShell(child: _skeleton());
    }

    final s      = _stats;
    final name   = (widget.userData['nama'] ?? widget.userData['name'] ?? 'Siswa').toString().split(' ').first;

    return AppShell(
      child: RefreshIndicator(
        onRefresh: _fetchData,
        color: AppTheme.indigoPrimary,
        child: LayoutBuilder(builder: (ctx, c) {
          final w       = c.maxWidth;
          final isWide  = w >= 950;
          final pad     = isWide ? 40.0 : 24.0;

          if (isWide) {
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
              padding: EdgeInsets.fromLTRB(pad, 24, pad, 120),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _GreetingBanner(name: name, kelasList: _kelasList),
                      const SizedBox(height: 24),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 5,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _StatRow(stats: s, isWide: isWide),
                                const SizedBox(height: 28),
                                SectionHeader(
                                  title: 'Tugas Mendatang',
                                  subtitle: '${_tugasList.length} tugas aktif dari semua kelas',
                                ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.05, curve: Curves.easeOutQuart),
                                const SizedBox(height: 16),
                                _buildTugasSection(),
                              ],
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            flex: 5,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildPengumumanHeader(),
                                const SizedBox(height: 16),
                                _buildPengumumanSectionWide(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: EdgeInsets.fromLTRB(pad, 24, pad, 120),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _GreetingBanner(name: name, kelasList: _kelasList),
                    const SizedBox(height: 24),
                    _StatRow(stats: s, isWide: isWide),
                    const SizedBox(height: 36),
                    SectionHeader(
                      title: 'Tugas Mendatang',
                      subtitle: '${_tugasList.length} tugas aktif dari semua kelas',
                    ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.05, curve: Curves.easeOutQuart),
                    const SizedBox(height: 16),
                    _buildTugasSection(),
                    const SizedBox(height: 36),
                    _buildPengumumanHeader(),
                    const SizedBox(height: 12),
                    _buildPengumumanSection(),
                    const SizedBox(height: 32),
                  ]),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  // ── Tugas Section ─────────────────────────────────────────────────────────
  Widget _buildTugasSection() {
    if (_tugasList.isEmpty) {
      return const _EmptyCard(
        icon: LucideIcons.clipboardCheck,
        message: 'Tidak ada tugas mendatang',
        subtitle: 'Semua tugas sudah dikumpulkan!',
        color: AppTheme.emerald,
      );
    }

    return Column(
      children: List.generate(_tugasList.length.clamp(0, 5), (i) {
        final t         = _tugasList[i];
        final submitted = _pengumpulanList.any((p) =>
            p['tugas_id'].toString() == t['id'].toString());
        final dl        = DateTime.tryParse(t['deadline']?.toString() ?? '');
        final isLate    = dl != null && dl.isBefore(DateTime.now()) && !submitted;

        return _TugasCard(
          tugas: t,
          submitted: submitted,
          isLate: isLate,
          deadline: dl,
          onTap: () => Navigator.push(context, MaterialPageRoute(
            builder: (_) => SiswaTugasDetailScreen(
              tugas: t, userData: widget.userData, token: widget.token,
            ),
          )),
        )
            .animate(delay: (300 + i * 70).ms)
            .fadeIn(duration: 400.ms)
            .slideY(begin: 0.08, curve: Curves.easeOutQuart);
      }),
    );
  }

  // ── Pengumuman Header ─────────────────────────────────────────────────────
  Widget _buildPengumumanHeader() {
    final unread = _pengumumanList.where((p) => !_readIds.contains(p['id']?.toString())).length;
    return Row(
      children: [
        Expanded(
          child: SectionHeader(
            title: 'Pengumuman Sekolah',
            subtitle: unread > 0 ? '$unread belum dibaca' : 'Semua sudah dibaca',
          ),
        ),
        if (unread > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.amber.withAlpha(25),
              borderRadius: BorderRadius.circular(100),
              border: Border.all(color: AppTheme.amber.withAlpha(50)),
            ),
            child: Text('$unread baru',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800, color: AppTheme.amber)),
          ).animate().fadeIn(delay: 300.ms),
      ],
    ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.05, curve: Curves.easeOutQuart);
  }

  // ── Pengumuman Section (horizontal scroll) ────────────────────────────────
  Widget _buildPengumumanSection() {
    final unread = _pengumumanList.where((p) => !_readIds.contains(p['id']?.toString())).toList();
    if (_pengumumanList.isEmpty) {
      return const _EmptyCard(
        icon: LucideIcons.megaphone,
        message: 'Belum ada pengumuman',
        subtitle: 'Pantau terus ya!',
        color: AppTheme.amber,
      );
    }
    if (unread.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.lightBorder, width: 1.2),
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Row(children: [
          const Icon(LucideIcons.checkCircle2, color: AppTheme.emerald, size: 20),
          const SizedBox(width: 12),
          Text('Semua pengumuman sudah dibaca!',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600,
                  color: AppTheme.emerald)),
        ]),
      );
    }
    return SizedBox(
      height: 140,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: unread.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (ctx, i) {
          final p = unread[i];
          return _PengumumanChipCard(
            pengumuman: p,
            onMarkRead: () => _markRead(p['id']?.toString() ?? ''),
          ).animate(delay: (i * 60).ms).fadeIn(duration: 350.ms);
        },
      ),
    );
  }

  // ── Pengumuman Section Wide (vertical list) ───────────────────────────────
  Widget _buildPengumumanSectionWide() {
    final unread = _pengumumanList.where((p) => !_readIds.contains(p['id']?.toString())).toList();
    if (_pengumumanList.isEmpty) {
      return const _EmptyCard(
        icon: LucideIcons.megaphone,
        message: 'Belum ada pengumuman',
        subtitle: 'Pantau terus ya!',
        color: AppTheme.amber,
      );
    }
    if (unread.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.lightBorder, width: 1.2),
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Row(children: [
          const Icon(LucideIcons.checkCircle2, color: AppTheme.emerald, size: 20),
          const SizedBox(width: 12),
          Text('Semua pengumuman sudah dibaca!',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600,
                  color: AppTheme.emerald)),
        ]),
      );
    }
    return Column(
      children: List.generate(unread.length, (i) {
        final p = unread[i];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _PengumumanVerticalCard(
            pengumuman: p,
            onMarkRead: () => _markRead(p['id']?.toString() ?? ''),
          ).animate(delay: (i * 60).ms).fadeIn(duration: 350.ms),
        );
      }),
    );
  }

  // ── Skeleton ──────────────────────────────────────────────────────────────
  Widget _skeleton() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      child: Column(children: [
        const SkeletonLoader(height: 120, radius: 24),
        const SizedBox(height: 20),
        Row(children: List.generate(3, (_) => const Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: 10),
            child: SkeletonLoader(height: 90, radius: 18),
          ),
        ))),
        const SizedBox(height: 24),
        ...List.generate(4, (_) => const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: SkeletonLoader(height: 88, radius: 20),
        )),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Greeting Banner — Premium Light Mode
// ═══════════════════════════════════════════════════════════════════════════
class _GreetingBanner extends StatelessWidget {
  final String name;
  final List<dynamic> kelasList;
  const _GreetingBanner({required this.name, required this.kelasList});

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Selamat Pagi';
    if (h < 15) return 'Selamat Siang';
    if (h < 18) return 'Selamat Sore';
    return 'Selamat Malam';
  }

  IconData get _greetingIcon {
    if (_greeting.contains('Pagi')) return LucideIcons.sun;
    if (_greeting.contains('Siang') || _greeting.contains('Sore')) return LucideIcons.cloudSun;
    return LucideIcons.moon;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.lightBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: AppTheme.indigoPrimary.withAlpha(15),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Time-of-day pill badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppTheme.indigoPrimary.withAlpha(15),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_greetingIcon, size: 12, color: AppTheme.indigoPrimary),
                          const SizedBox(width: 6),
                          Text(
                            _greeting.toUpperCase(),
                            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppTheme.indigoPrimary,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      name,
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: AppTheme.textLight,
                        letterSpacing: -0.8,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${kelasList.length} kelas aktif hari ini',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppTheme.textMutedLt),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Rounded indigo icon circle
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.indigoPrimary.withAlpha(15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.school_rounded, color: AppTheme.indigoPrimary, size: 32),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Divider(color: AppTheme.lightBorder, height: 1, thickness: 1),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Selamat belajar & tingkatkan prestasimu! ✨',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textMutedLt,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: Colors.transparent,
                    builder: (ctx) => const _MotivationalSheet(),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  constraints: const BoxConstraints(minHeight: 40),
                  decoration: BoxDecoration(
                    color: AppTheme.indigoPrimary,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.indigoPrimary.withAlpha(50),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    'Motivasi',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.05);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Motivational Bottom Sheet — Premium Light Mode
// ─────────────────────────────────────────────────────────────────────────────
class _MotivationalSheet extends StatelessWidget {
  const _MotivationalSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.lightBorder,
                borderRadius: BorderRadius.circular(100),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.indigoPrimary.withAlpha(15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(LucideIcons.sparkles, color: AppTheme.indigoPrimary, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quotes of the Day',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: AppTheme.textLight,
                      ),
                    ),
                    Text(
                      'Inspirasi belajar harianmu',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textMutedLt),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.indigoPrimary.withAlpha(10),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.indigoPrimary.withAlpha(30), width: 1.2),
            ),
            child: Text(
              '"Pendidikan adalah senjata paling mematikan di dunia, karena dengan pendidikan, Anda dapat mengubah dunia."\n\n— Nelson Mandela',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                height: 1.6,
                color: AppTheme.indigoPrimary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: AppTheme.indigoPrimary,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.indigoPrimary.withAlpha(50),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  'Siap Belajar! 🚀',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Stat Row — Premium Light Mode Cards
// ═══════════════════════════════════════════════════════════════════════════
class _StatRow extends StatelessWidget {
  final Map<String, int> stats;
  final bool isWide;
  const _StatRow({required this.stats, required this.isWide});

  @override
  Widget build(BuildContext context) {
    final items = [
      _StatItem(LucideIcons.clipboardList, 'Belum\nDikumpul', stats['belum'] ?? 0, AppTheme.amber, const Color(0xFFFFFBEB)),
      _StatItem(LucideIcons.alertTriangle, 'Lewat\nDeadline',  stats['lewat'] ?? 0, AppTheme.rose,  const Color(0xFFFFF1F2)),
      _StatItem(LucideIcons.checkCircle2,  'Selesai',          stats['selesai'] ?? 0, AppTheme.emerald, const Color(0xFFF0FDF4)),
    ];

    return Row(
      children: items.asMap().entries.map((e) {
        final item   = e.value;
        final isLast = e.key == items.length - 1;

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: isLast ? 0 : 10),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.lightBorder, width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(12),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: item.bgLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(item.icon, color: item.accent, size: 18),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${item.value}',
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: AppTheme.textLight,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.label,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: item.accent,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ).animate(delay: (100 + e.key * 80).ms)
              .fadeIn(duration: 350.ms)
              .slideY(begin: 0.08, curve: Curves.easeOut),
          ),
        );
      }).toList(),
    );
  }
}

class _StatItem {
  final IconData icon;
  final String label;
  final int value;
  final Color accent;
  final Color bgLight;
  _StatItem(this.icon, this.label, this.value, this.accent, this.bgLight);
}


// ═══════════════════════════════════════════════════════════════════════════
// Tugas Card — Premium Light Mode
// ═══════════════════════════════════════════════════════════════════════════
class _TugasCard extends StatelessWidget {
  final dynamic tugas;
  final bool submitted;
  final bool isLate;
  final DateTime? deadline;
  final VoidCallback onTap;
  const _TugasCard({
    required this.tugas,
    required this.submitted,
    required this.isLate,
    required this.deadline,
    required this.onTap,
  });

  Color get _statusColor {
    if (submitted) return AppTheme.emerald;
    if (isLate)   return AppTheme.rose;
    return AppTheme.amber;
  }

  String get _statusLabel {
    if (submitted) return 'Selesai';
    if (isLate)   return 'Terlambat';
    return 'Belum';
  }

  String _fmtDl() {
    if (deadline == null) return '-';
    final now  = DateTime.now();
    final diff = deadline!.difference(now);
    if (submitted) return DateFormat('dd MMM, HH:mm').format(deadline!);
    if (diff.isNegative) return 'Lewat ${diff.inDays.abs()}h';
    if (diff.inDays > 0)  return '${diff.inDays} hari lagi';
    if (diff.inHours > 0) return '${diff.inHours} jam lagi';
    return '< 1 jam';
  }

  @override
  Widget build(BuildContext context) {
    final accent = _statusColor;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.lightBorder, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(12),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Rounded icon container
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: accent.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(LucideIcons.fileText, color: accent, size: 20),
            ),
            const SizedBox(width: 14),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tugas['judul'] ?? '-',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textLight,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(children: [
                    const Icon(LucideIcons.bookOpen, size: 12, color: AppTheme.textMutedLt),
                    const SizedBox(width: 4),
                    Text(
                      tugas['mapel'] ?? '-',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textMutedLt),
                    ),
                  ]),
                ],
              ),
            ),

            // Right: status pill + deadline
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: accent.withAlpha(20),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    _statusLabel,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: accent,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Row(children: [
                  Icon(LucideIcons.clock, size: 11, color: accent.withAlpha(180)),
                  const SizedBox(width: 3),
                  Text(
                    _fmtDl(),
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: accent,
                    ),
                  ),
                ]),
              ],
            ),
            const SizedBox(width: 10),
            // Kerjakan button
            GestureDetector(
              onTap: onTap,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                constraints: const BoxConstraints(minHeight: 36),
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: accent.withAlpha(50),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Text(
                  submitted ? 'Buka' : 'Kerjakan',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Pengumuman Chip Card — Premium (horizontal scroll, compact)
// ═══════════════════════════════════════════════════════════════════════════
class _PengumumanChipCard extends StatelessWidget {
  final dynamic pengumuman;
  final VoidCallback onMarkRead;
  const _PengumumanChipCard({
    required this.pengumuman,
    required this.onMarkRead,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.lightBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(12),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.amber.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(LucideIcons.megaphone, color: AppTheme.amber, size: 12),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  pengumuman['judul'] ?? '-',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textLight,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Mark as read X button
              GestureDetector(
                onTap: onMarkRead,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppTheme.lightBorder.withAlpha(80),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(LucideIcons.x, size: 11, color: AppTheme.textMutedLt),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Text(
              pengumuman['isi'] ?? '-',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                height: 1.5,
                color: AppTheme.textMutedLt,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (pengumuman['tanggal'] != null) ...[
            const SizedBox(height: 6),
            Text(
              pengumuman['tanggal'].toString(),
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppTheme.amber.withAlpha(200),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Pengumuman Vertical Card — Premium
// ═══════════════════════════════════════════════════════════════════════════
class _PengumumanVerticalCard extends StatelessWidget {
  final dynamic pengumuman;
  final VoidCallback onMarkRead;
  const _PengumumanVerticalCard({
    required this.pengumuman,
    required this.onMarkRead,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.lightBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(12),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.amber.withAlpha(25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(LucideIcons.megaphone, color: AppTheme.amber, size: 14),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  pengumuman['judul'] ?? '-',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textLight,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onMarkRead,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  decoration: BoxDecoration(
                    color: AppTheme.lightBorder.withAlpha(80),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(LucideIcons.x, size: 13, color: AppTheme.textMutedLt),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            pengumuman['isi'] ?? '-',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              height: 1.5,
              color: AppTheme.textMutedLt,
            ),
          ),
          if (pengumuman['tanggal'] != null) ...[
            const SizedBox(height: 10),
            Text(
              pengumuman['tanggal'].toString(),
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppTheme.amber.withAlpha(200),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Empty Card — Premium Light Mode
// ═══════════════════════════════════════════════════════════════════════════
class _EmptyCard extends StatelessWidget {
  final IconData icon;
  final String message;
  final String subtitle;
  final Color color;
  const _EmptyCard({required this.icon, required this.message, required this.subtitle, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.lightBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withAlpha(20),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 14),
            Text(
              message,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppTheme.textLight,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textMutedLt),
            ),
          ],
        ),
      ),
    );
  }
}
