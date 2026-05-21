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







const _kAsymSiswa = BorderRadius.only(
  topLeft: Radius.circular(24),
  topRight: Radius.circular(4),
  bottomLeft: Radius.circular(4),
  bottomRight: Radius.circular(24),
);

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
                      _GreetingBanner(name: name, isDark: isDark, kelasList: _kelasList),
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
                                _buildTugasSection(isDark),
                              ],
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            flex: 5,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildPengumumanHeader(isDark),
                                const SizedBox(height: 16),
                                _buildPengumumanSectionWide(isDark),
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
                    _GreetingBanner(name: name, isDark: isDark, kelasList: _kelasList),
                    const SizedBox(height: 24),
                    _StatRow(stats: s, isWide: isWide),
                    const SizedBox(height: 36),
                    SectionHeader(
                      title: 'Tugas Mendatang',
                      subtitle: '${_tugasList.length} tugas aktif dari semua kelas',
                    ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.05, curve: Curves.easeOutQuart),
                    const SizedBox(height: 16),
                    _buildTugasSection(isDark),
                    const SizedBox(height: 36),
                    _buildPengumumanHeader(isDark),
                    const SizedBox(height: 12),
                    _buildPengumumanSection(isDark),
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
  Widget _buildTugasSection(bool isDark) {
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
  Widget _buildPengumumanHeader(bool isDark) {
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
              color: AppTheme.amber.withAlpha(isDark ? 40 : 25),
              borderRadius: BorderRadius.circular(100),
              border: Border.all(color: AppTheme.amber.withAlpha(isDark ? 80 : 50)),
            ),
            child: Text('$unread baru',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800, color: AppTheme.amber)),
          ).animate().fadeIn(delay: 300.ms),
      ],
    ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.05, curve: Curves.easeOutQuart);
  }

  // ── Pengumuman Section (horizontal scroll) ────────────────────────────────
  Widget _buildPengumumanSection(bool isDark) {
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
          color: isDark ? AppTheme.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
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
      height: 135,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: unread.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (ctx, i) {
          final p = unread[i];
          return _PengumumanChipCard(
            pengumuman: p,
            isDark: isDark,
            onMarkRead: () => _markRead(p['id']?.toString() ?? ''),
          ).animate(delay: (i * 60).ms).fadeIn(duration: 350.ms);
        },
      ),
    );
  }

  // ── Pengumuman Section Wide (vertical list) ───────────────────────────────
  Widget _buildPengumumanSectionWide(bool isDark) {
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
          color: isDark ? AppTheme.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
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
            isDark: isDark,
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
// Greeting Banner — Neo-Brutalist
// ═══════════════════════════════════════════════════════════════════════════
class _GreetingBanner extends StatelessWidget {
  final String name;
  final bool isDark;
  final List<dynamic> kelasList;
  const _GreetingBanner({required this.name, required this.isDark, required this.kelasList});

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Selamat Pagi';
    if (h < 15) return 'Selamat Siang';
    if (h < 18) return 'Selamat Sore';
    return 'Selamat Malam';
  }

  @override
  Widget build(BuildContext context) {
    final bg          = Theme.of(context).scaffoldBackgroundColor;
    final borderColor = Theme.of(context).dividerColor;
    final textColor   = Theme.of(context).textTheme.bodyLarge!.color!;
    final mutedColor  = Theme.of(context).textTheme.bodyMedium!.color!;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: _kAsymSiswa,
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(color: borderColor.withAlpha(isDark ? 120 : 80), offset: const Offset(4, 4), blurRadius: 0),
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
                    // Time-of-day badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        border: Border.all(color: Theme.of(context).colorScheme.onSurface),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _greeting.contains('Pagi')
                                ? LucideIcons.sun
                                : (_greeting.contains('Siang') || _greeting.contains('Sore')
                                    ? LucideIcons.cloudSun
                                    : LucideIcons.moon),
                            size: 12,
                            color: AppTheme.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _greeting.toUpperCase(),
                            style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w800,
                              color: AppTheme.primary,
                              letterSpacing: 0.8),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      name,
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(fontWeight: FontWeight.w900,
                        color: textColor,
                        letterSpacing: -0.8,
                        height: 1.1),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${kelasList.length} kelas aktif hari ini',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: mutedColor),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Icon block — flat, no glow
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  border: Border.all(color: Theme.of(context).colorScheme.onSurface),
                ),
                child: const Icon(Icons.school_rounded, color: AppTheme.primary, size: 32),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(height: 1, color: Theme.of(context).dividerColor),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Selamat belajar & tingkatkan prestasimu! ✨',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600,
                    color: mutedColor),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: Colors.transparent,
                    builder: (ctx) => _MotivationalSheet(isDark: isDark),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  constraints: const BoxConstraints(minHeight: 40),
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    border: Border.all(color: Theme.of(context).colorScheme.onSurface),
                    boxShadow: [BoxShadow(color: Theme.of(context).colorScheme.onSurface, offset: const Offset(3, 3))],
                  ),
                  child: Text(
                    'MOTIVASI',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.5),
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
// Motivational Bottom Sheet — Neo-Brutalist
// ─────────────────────────────────────────────────────────────────────────────
class _MotivationalSheet extends StatelessWidget {
  final bool isDark;
  const _MotivationalSheet({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final bg          = Theme.of(context).scaffoldBackgroundColor;
    final borderColor = Theme.of(context).dividerColor;
    final textColor   = Theme.of(context).textTheme.bodyLarge!.color!;
    final mutedColor  = Theme.of(context).textTheme.bodyMedium!.color!;

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: bg,
        border: Border(top: BorderSide(color: borderColor, width: 2)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              color: borderColor.withAlpha(60),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  border: Border.all(color: Theme.of(context).colorScheme.onSurface),
                ),
                child: const Icon(LucideIcons.sparkles, color: AppTheme.primary, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quotes of the Day',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900,
                        color: textColor),
                    ),
                    Text(
                      'Inspirasi belajar harianmu',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: mutedColor),
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
              color: isDark ? const Color(0xFF251B45) : Theme.of(context).colorScheme.primaryContainer,
              border: Border.all(color: borderColor),
            ),
            child: Text(
              '"Pendidikan adalah senjata paling mematikan di dunia, karena dengan pendidikan, Anda dapat mengubah dunia."\n\n— Nelson Mandela',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600,
                height: 1.6,
                color: isDark ? Colors.white : AppTheme.primary,
                fontStyle: FontStyle.italic),
            ),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: AppTheme.primary,
                border: Border.all(color: Theme.of(context).colorScheme.onSurface),
                boxShadow: [BoxShadow(color: Theme.of(context).colorScheme.onSurface, offset: const Offset(4, 4))],
              ),
              child: Center(
                child: Text(
                  'SIAP BELAJAR! 🚀',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.5),
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
// Stat Row — Neo-Brutalist flat boxes
// ═══════════════════════════════════════════════════════════════════════════
class _StatRow extends StatelessWidget {
  final Map<String, int> stats;
  final bool isWide;
  const _StatRow({required this.stats, required this.isWide});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final items = [
      _StatItem(LucideIcons.clipboardList, 'Belum\nDikumpul', stats['belum'] ?? 0, AppTheme.amber, const Color(0xFFFFEFD5), const Color(0xFF7A5C00)),
      _StatItem(LucideIcons.alertTriangle, 'Lewat\nDeadline',  stats['lewat'] ?? 0, AppTheme.rose,  const Color(0xFFFFD5D5), const Color(0xFF8B0000)),
      _StatItem(LucideIcons.checkCircle2,  'Selesai',          stats['selesai'] ?? 0, AppTheme.emerald, const Color(0xFFB7E5CD), const Color(0xFF1B4332)),
    ];

    return Row(
      children: items.asMap().entries.map((e) {
        final item   = e.value;
        final isLast = e.key == items.length - 1;
        final bgCol  = isDark ? const Color(0xFF1A1040) : item.bgLight;
        final bdrCol = Theme.of(context).dividerColor;
        final txtCol = isDark ? item.accent : item.labelDark;

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: isLast ? 0 : 10),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: bgCol,
                border: Border.all(color: bdrCol),
                boxShadow: [BoxShadow(color: bdrCol, offset: const Offset(3, 3), blurRadius: 0)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(item.icon, color: item.accent, size: 20),
                  const SizedBox(height: 8),
                  Text(
                    '${item.value}',
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(fontWeight: FontWeight.w900,
                      color: txtCol,
                      height: 1.0),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.label,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700,
                      color: isDark ? item.accent.withAlpha(200) : item.labelDark,
                      letterSpacing: 0.3,
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
  final Color labelDark;
  _StatItem(this.icon, this.label, this.value, this.accent, this.bgLight, this.labelDark);
}


// ═══════════════════════════════════════════════════════════════════════════
// Tugas Card — Neo-Brutalist
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
    if (submitted) return 'SELESAI';
    if (isLate)   return 'TERLAMBAT';
    return 'BELUM';
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
    final isDark     = Theme.of(context).brightness == Brightness.dark;
    final accent     = _statusColor;
    final bg         = Theme.of(context).colorScheme.surface;
    final borderColor = Theme.of(context).dividerColor;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bg,
          border: Border(
            left: BorderSide(color: accent, width: 4),
            top: BorderSide(color: borderColor, width: 1),
            right: BorderSide(color: borderColor, width: 1),
            bottom: BorderSide(color: borderColor, width: 1),
          ),
          boxShadow: [BoxShadow(color: borderColor.withAlpha(isDark ? 100 : 60), offset: const Offset(3, 3), blurRadius: 0)],
        ),
        child: Row(
          children: [
            // Icon box
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: accent.withAlpha(isDark ? 50 : 30),
                border: Border.all(color: accent.withAlpha(isDark ? 120 : 80)),
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
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700,
                      color: Theme.of(context).textTheme.bodyLarge!.color!),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(children: [
                    Icon(LucideIcons.bookOpen, size: 12, color: Theme.of(context).textTheme.bodyMedium!.color!),
                    const SizedBox(width: 4),
                    Text(
                      tugas['mapel'] ?? '-',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).textTheme.bodyMedium!.color!,
                      ),
                    ),
                  ]),
                ],
              ),
            ),

            // Right: status + deadline
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: accent.withAlpha(isDark ? 40 : 25),
                    border: Border.all(color: accent),
                  ),
                  child: Text(
                    _statusLabel,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w800, color: accent, letterSpacing: 0.5),
                  ),
                ),
                const SizedBox(height: 6),
                Row(children: [
                  Icon(LucideIcons.clock, size: 11, color: accent.withAlpha(180)),
                  const SizedBox(width: 3),
                  Text(
                    _fmtDl(),
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700,
                      color: accent),
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
                  border: Border.all(color: borderColor),
                  boxShadow: [BoxShadow(color: borderColor, offset: const Offset(2, 2))],
                ),
                child: Text(
                  submitted ? 'BUKA' : 'KERJAKAN',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.3),
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
// Pengumuman Chip Card — Neo-Brutalist (horizontal scroll, compact)
// ═══════════════════════════════════════════════════════════════════════════
class _PengumumanChipCard extends StatelessWidget {
  final dynamic pengumuman;
  final bool isDark;
  final VoidCallback onMarkRead;
  const _PengumumanChipCard({
    required this.pengumuman,
    required this.isDark,
    required this.onMarkRead,
  });

  @override
  Widget build(BuildContext context) {
    final bg          = Theme.of(context).colorScheme.surface;
    final borderColor = Theme.of(context).dividerColor;

    return Container(
      width: 240,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        border: Border(
          left: const BorderSide(color: AppTheme.amber, width: 3),
          top: BorderSide(color: borderColor),
          right: BorderSide(color: borderColor),
          bottom: BorderSide(color: borderColor),
        ),
        boxShadow: [BoxShadow(color: borderColor.withAlpha(isDark ? 100 : 60), offset: const Offset(3, 3), blurRadius: 0)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.amber.withAlpha(isDark ? 50 : 30),
                  border: Border.all(color: AppTheme.amber),
                ),
                child: const Icon(LucideIcons.megaphone, color: AppTheme.amber, size: 12),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  pengumuman['judul'] ?? '-',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w800,
                    color: Theme.of(context).textTheme.bodyLarge!.color!),
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
                    color: isDark ? const Color(0xFF3D3270) : Theme.of(context).colorScheme.primaryContainer,
                    border: Border.all(color: borderColor),
                  ),
                  child: Icon(LucideIcons.x, size: 11, color: Theme.of(context).textTheme.bodyMedium!.color!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Text(
              pengumuman['isi'] ?? '-',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5,
                color: Theme.of(context).textTheme.bodyMedium!.color!,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (pengumuman['tanggal'] != null) ...[
            const SizedBox(height: 6),
            Text(
              pengumuman['tanggal'].toString(),
              style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700,
                color: AppTheme.amber.withAlpha(isDark ? 200 : 180),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Pengumuman Vertical Card — Neo-Brutalist
// ═══════════════════════════════════════════════════════════════════════════
class _PengumumanVerticalCard extends StatelessWidget {
  final dynamic pengumuman;
  final bool isDark;
  final VoidCallback onMarkRead;
  const _PengumumanVerticalCard({
    required this.pengumuman,
    required this.isDark,
    required this.onMarkRead,
  });

  @override
  Widget build(BuildContext context) {
    final bg          = Theme.of(context).colorScheme.surface;
    final borderColor = Theme.of(context).dividerColor;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        border: Border(
          left: const BorderSide(color: AppTheme.amber, width: 4),
          top: BorderSide(color: borderColor),
          right: BorderSide(color: borderColor),
          bottom: BorderSide(color: borderColor),
        ),
        boxShadow: [BoxShadow(color: borderColor.withAlpha(isDark ? 100 : 60), offset: const Offset(3, 3), blurRadius: 0)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.amber.withAlpha(isDark ? 50 : 30),
                  border: Border.all(color: AppTheme.amber),
                ),
                child: const Icon(LucideIcons.megaphone, color: AppTheme.amber, size: 14),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  pengumuman['judul'] ?? '-',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800,
                    color: Theme.of(context).textTheme.bodyLarge!.color!),
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
                    color: isDark ? const Color(0xFF3D3270) : Theme.of(context).colorScheme.primaryContainer,
                    border: Border.all(color: borderColor),
                  ),
                  child: Icon(LucideIcons.x, size: 13, color: Theme.of(context).textTheme.bodyMedium!.color!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            pengumuman['isi'] ?? '-',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(height: 1.5,
              color: Theme.of(context).textTheme.bodyMedium!.color!,
            ),
          ),
          if (pengumuman['tanggal'] != null) ...[
            const SizedBox(height: 10),
            Text(
              pengumuman['tanggal'].toString(),
              style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700,
                color: AppTheme.amber.withAlpha(isDark ? 200 : 180),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Empty Card — Neo-Brutalist
// ═══════════════════════════════════════════════════════════════════════════
class _EmptyCard extends StatelessWidget {
  final IconData icon;
  final String message;
  final String subtitle;
  final Color color;
  const _EmptyCard({required this.icon, required this.message, required this.subtitle, required this.color});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg          = Theme.of(context).scaffoldBackgroundColor;
    final borderColor = Theme.of(context).dividerColor;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: borderColor),
        boxShadow: [BoxShadow(color: borderColor.withAlpha(isDark ? 80 : 50), offset: const Offset(3, 3), blurRadius: 0)],
      ),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withAlpha(isDark ? 40 : 25),
                border: Border.all(color: color.withAlpha(isDark ? 100 : 60)),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 14),
            Text(message, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: isDark ? Colors.white.withAlpha(200) : Theme.of(context).colorScheme.onSurface)),
            const SizedBox(height: 4),
            Text(subtitle, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).textTheme.bodyMedium!.color!)),
          ],
        ),
      ),
    );
  }
}
