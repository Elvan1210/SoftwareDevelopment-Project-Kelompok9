import '../../../config/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../config/api_config.dart';
import '../../../widgets/app_shell.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'guru_team_detail_layout.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';

// ── Palette ────────────────────────────────────────────────────────────────
class _P {
  static const bg = Color(0xFFF4FAFF);
  static const ink = Color(0xFF001E2B);
  static const primary = Color(0xFF3D6754);
  static const primCon = Color(0xFFB7E5CD);
  static const secondary = Color(0xFF336763);
  static const secCon = Color(0xFFB7EDE7);
  static const tertCon = Color(0xFFFFD1C0);
  static const surfHigh = Color(0xFFCEEDFF);
  static const surfLow = Color(0xFFE8F6FF);
  static const white = Color(0xFFFFFFFF);
  static const muted = Color(0xFF414944);
  static const outline = Color(0xFF717974);
  static const deepSlate = Color(0xFF305669);
}

const _kAsymmetric = BorderRadius.only(
  topLeft: Radius.circular(24),
  topRight: Radius.circular(4),
  bottomLeft: Radius.circular(4),
  bottomRight: Radius.circular(24),
);

class GuruDashboardView extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String token;
  final Function(int)? onNavigate;
  const GuruDashboardView({
    super.key,
    required this.userData,
    required this.token,
    this.onNavigate,
  });

  @override
  State<GuruDashboardView> createState() => _GuruDashboardViewState();
}

class _GuruDashboardViewState extends State<GuruDashboardView> {
  bool _isLoading = true;
  List<dynamic> _kelasList = [];
  int _totalMateri = 0, _totalPengumuman = 0;

  String get _greeting {
    final h = DateTime.now().hour;
    if (h >= 5 && h < 11) return 'Selamat pagi';
    if (h >= 11 && h < 15) return 'Selamat siang';
    if (h >= 15 && h < 18) return 'Selamat sore';
    return 'Selamat malam';
  }

  String get _todayDate {
    final now = DateTime.now();
    const days = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu'
    ];
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember'
    ];
    return '${days[now.weekday - 1]}, ${now.day} ${months[now.month - 1]} ${now.year}';
  }

  int get _totalSiswa => _kelasList.fold(
      0, (s, k) => s + ((k['siswa_ids'] as List?)?.length ?? 0));

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
    setState(() => _isLoading = true);
    await Future.wait([_fetchStats(), _fetchKelasGuru()]);
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _fetchKelasGuru() async {
    try {
      final h = {'Authorization': 'Bearer ${widget.token}'};
      final id = Uri.encodeComponent(widget.userData['id'].toString());
      final r = await http.get(Uri.parse('$baseUrl/api/kelas?guru_id=$id'),
          headers: h);
      if (r.statusCode == 200) {
        final dec = jsonDecode(r.body);
        _kelasList = dec is List ? dec : [];
      }
    } catch (e) {
      debugPrint('fetch kelas: $e');
    }
  }

  Future<void> _fetchStats() async {
    try {
      final h = {'Authorization': 'Bearer ${widget.token}'};
      final myId = widget.userData['id'].toString();
      final results = await Future.wait([
        http.get(Uri.parse('$baseUrl/api/materi'), headers: h),
        http.get(Uri.parse('$baseUrl/api/pengumuman'), headers: h),
      ]);
      if (results[0].statusCode == 200) {
        final d = jsonDecode(results[0].body) as List? ?? [];
        _totalMateri = d.where((m) => m['guru_id'].toString() == myId).length;
      }
      if (results[1].statusCode == 200) {
        final d = jsonDecode(results[1].body) as List? ?? [];
        _totalPengumuman =
            d.where((p) => p['guru_id'].toString() == myId).length;
      }
    } catch (e) {
      debugPrint('fetch stats: $e');
    }
  }

  // ── Navigate ke presensi ─────────────────────────────────────────────────
  void _goToPresensi() {
    if (_kelasList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Belum ada kelas ampuan')),
      );
      return;
    }
    if (_kelasList.length == 1) {
      _openPresensiKelas(_kelasList.first);
    } else {
      _showKelasPicker();
    }
  }

  void _openPresensiKelas(dynamic kelas) {
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => GuruTeamDetailLayout(
            userData: widget.userData,
            token: widget.token,
            teamData: kelas,
            initialTab: 'presensi', // ← pass tab presensi
          ),
        ));
  }

  void _showKelasPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: _P.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          border: Border(top: BorderSide(color: _P.ink)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pilih Kelas untuk Presensi',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700,
                  color: _P.ink)),
            const SizedBox(height: 16),
            ..._kelasList.map((k) => GestureDetector(
                  onTap: () {
                    Navigator.pop(ctx);
                    _openPresensiKelas(k);
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      border: Border.all(color: _P.ink),
                      color: _P.surfLow,
                    ),
                    child: Row(children: [
                      Expanded(
                          child: Text(
                        k['nama_kelas']?.toString() ?? '-',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700,
                          color: _P.ink),
                      )),
                      const Icon(LucideIcons.chevronRight,
                          size: 16, color: _P.outline),
                    ]),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  // ── Modal Pengumuman ──────────────────────────────────────────────────────
  void _showPengumumanModal() {
    showDialog(
      context: context,
      barrierColor: _P.ink.withAlpha(100),
      builder: (ctx) => _PengumumanModal(
        userData: widget.userData,
        token: widget.token,
        kelasList: _kelasList,
        onSuccess: () {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Pengumuman berhasil dikirim!',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            backgroundColor: _P.primary,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ));
          setState(() => _totalPengumuman++);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return _buildSkeleton();

    return RefreshIndicator(
      onRefresh: _fetchInitialData,
      color: _P.primary,
      child: LayoutBuilder(builder: (ctx, constraints) {
        final w = constraints.maxWidth;
        final isWide = w >= 950;
        final pad = isWide ? 40.0 : 24.0; // 24px margins on mobile

        if (isWide) {
          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(pad, 24, pad, 100),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildGreeting()
                        .animate()
                        .fadeIn(duration: 350.ms)
                        .slideY(begin: -0.04),
                    const SizedBox(height: 24),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left Column
                        Expanded(
                          flex: 5,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildRingkasanCard()
                                  .animate()
                                  .fadeIn(delay: 80.ms)
                                  .slideY(begin: 0.05),
                              const SizedBox(height: 20),
                              _buildPengumumanCard()
                                  .animate()
                                  .fadeIn(delay: 140.ms)
                                  .slideY(begin: 0.05),
                            ],
                          ),
                        ),
                        const SizedBox(width: 24),
                        // Right Column
                        Expanded(
                          flex: 5,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildJadwalCard()
                                  .animate()
                                  .fadeIn(delay: 200.ms)
                                  .slideY(begin: 0.05),
                              const SizedBox(height: 20),
                              _buildPresensiCard()
                                  .animate()
                                  .fadeIn(delay: 260.ms)
                                  .slideY(begin: 0.05),
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
              padding: EdgeInsets.fromLTRB(pad, 24, pad, 100),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // 1. Greeting
                  _buildGreeting()
                      .animate()
                      .fadeIn(duration: 350.ms)
                      .slideY(begin: -0.04),
                  const SizedBox(height: 20),

                  // 2. Ringkasan Kelas
                  _buildRingkasanCard()
                      .animate()
                      .fadeIn(delay: 80.ms)
                      .slideY(begin: 0.05),
                  const SizedBox(height: 16),

                  // 3. Pengumuman shortcut
                  _buildPengumumanCard()
                      .animate()
                      .fadeIn(delay: 140.ms)
                      .slideY(begin: 0.05),
                  const SizedBox(height: 16),

                  // 4. Jadwal Kelas (full width)
                  _buildJadwalCard()
                      .animate()
                      .fadeIn(delay: 200.ms)
                      .slideY(begin: 0.05),
                  const SizedBox(height: 16),

                  // 5. Presensi
                  _buildPresensiCard()
                      .animate()
                      .fadeIn(delay: 260.ms)
                      .slideY(begin: 0.05),
                ]),
              ),
            ),
          ],
        );
      }),
    );
  }

  // ── 1. Greeting ───────────────────────────────────────────────────────────
  Widget _buildGreeting() {
    final nama = widget.userData['nama']?.toString() ?? 'Guru';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$_greeting,',
            style: Theme.of(context).textTheme.displayLarge?.copyWith(fontWeight: FontWeight.w800,
              color: _P.ink,
              letterSpacing: -0.8,
              height: 1.15)),
        Text('Bpk/Ibu. $nama',
            style: Theme.of(context).textTheme.displayLarge?.copyWith(fontWeight: FontWeight.w800,
              color: _P.ink,
              letterSpacing: -0.8,
              height: 1.15)),
        const SizedBox(height: 4),
        Text('$_todayDate • ${_kelasList.length} Kelas aktif',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: _P.muted)),
      ],
    );
  }

  // ── 2. Ringkasan Kelas ────────────────────────────────────────────────────
  Widget _buildRingkasanCard() {
    return GestureDetector(
      onTap: () => widget.onNavigate?.call(1),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: _P.primCon,
          borderRadius: _kAsymmetric,
          border: Border.all(color: _P.ink),
        ),
        child: Stack(
          children: [
            Positioned(
                right: 0,
                top: 0,
                child: Icon(LucideIcons.users,
                    size: 80, color: _P.primary.withAlpha(30))),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _badge('RINGKASAN KELAS', dark: true),
              const SizedBox(height: 14),
              Text('$_totalSiswa Siswa Terdaftar',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(fontWeight: FontWeight.w800,
                    color: _P.ink,
                    letterSpacing: -1.2,
                    height: 1.1)),
              const SizedBox(height: 6),
              Text('$_totalMateri materi · $_totalPengumuman pengumuman',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: _P.primary)),
              const SizedBox(height: 18),
              _neoButton('LIHAT DATA KELAS',
                  icon: LucideIcons.arrowRight,
                  onTap: () => widget.onNavigate?.call(1)),
            ]),
          ],
        ),
      ),
    );
  }

  // ── 3. Pengumuman Shortcut ────────────────────────────────────────────────
  Widget _buildPengumumanCard() {
    return GestureDetector(
      onTap: _showPengumumanModal,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _P.secCon,
          borderRadius: _kAsymmetric,
          border: Border.all(color: _P.ink),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _P.secondary,
                border: Border.all(color: _P.ink),
              ),
              child:
                  const Icon(LucideIcons.megaphone, color: _P.white, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Buat Pengumuman',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700,
                          color: _P.ink)),
                    Text('Kirim ke kelas & channel yang kamu ajar',
                        style:
                            Theme.of(context).textTheme.bodyMedium?.copyWith(color: _P.muted)),
                  ]),
            ),
            const Icon(LucideIcons.chevronRight, size: 18, color: _P.outline),
          ],
        ),
      ),
    );
  }

  // ── 4. Jadwal Kelas (full width, taller) ──────────────────────────────────
  Widget _buildJadwalCard() {
    return Container(
      decoration: BoxDecoration(
        color: _P.white,
        borderRadius: _kAsymmetric,
        border: Border.all(color: _P.ink),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _badge('JADWAL', color: _P.tertCon),
                GestureDetector(
                  onTap: () => widget.onNavigate?.call(1),
                  child: Text('LIHAT SEMUA',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700,
                        color: _P.primary,
                        letterSpacing: 0.5)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
            child: Text('Kelas Ampuan',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700,
                  color: _P.ink)),
          ),
          const SizedBox(height: 14),
          if (_kelasList.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Text('Belum ada kelas',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: _P.outline)),
            )
          else
            ..._kelasList.asMap().entries.map((e) {
              final i = e.key;
              final k = e.value;
              final nama = k['nama_kelas']?.toString() ?? '-';
              final siswa = (k['siswa_ids'] as List?)?.length ?? 0;
              final isLast = i == _kelasList.length - 1;

              final colors = [
                _P.primary,
                _P.secondary,
                const Color(0xFF8D4D33),
                const Color(0xFF305669)
              ];
              final color = colors[i % colors.length];

              return GestureDetector(
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => GuruTeamDetailLayout(
                        userData: widget.userData,
                        token: widget.token,
                        teamData: k,
                      ),
                    )),
                child: Container(
                  margin: EdgeInsets.fromLTRB(20, 0, 20, isLast ? 20 : 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _P.bg,
                    border: Border(
                      left: BorderSide(color: color, width: 3),
                      top: const BorderSide(color: _P.ink, width: 0.5),
                      right: const BorderSide(color: _P.ink, width: 0.5),
                      bottom: const BorderSide(color: _P.ink, width: 0.5),
                    ),
                  ),
                  child: Row(children: [
                    Expanded(
                        child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nama,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700,
                            color: _P.ink),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Row(children: [
                          const Icon(LucideIcons.users, size: 12, color: _P.outline),
                          const SizedBox(width: 4),
                          Text('$siswa Siswa',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: _P.outline)),
                        ]),
                      ],
                    )),
                    const Icon(LucideIcons.chevronRight,
                        size: 16, color: _P.outline),
                  ]),
                ),
              ).animate(delay: (i * 50).ms).fadeIn().slideX(begin: 0.03);
            }),
        ],
      ),
    );
  }

  // ── 5. Presensi Card ──────────────────────────────────────────────────────
  Widget _buildPresensiCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _P.white,
        borderRadius: _kAsymmetric,
        border: Border.all(color: _P.ink),
      ),
      child: Row(
        children: [
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _badge('PRESENSI', color: _P.primCon),
              const SizedBox(height: 10),
              Text('Jurnal Kehadiran',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700,
                    color: _P.ink)),
              const SizedBox(height: 4),
              Text('Catat kehadiran siswa hari ini',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: _P.muted)),
            ]),
          ),
          GestureDetector(
            onTap: _goToPresensi,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              constraints: const BoxConstraints(minHeight: 44),
              decoration: BoxDecoration(
                color: _P.primCon,
                border: Border.all(color: _P.ink),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text('ISI PRESENSI',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700,
                      color: _P.ink,
                      letterSpacing: 0.5)),
                const SizedBox(width: 6),
                const Icon(LucideIcons.arrowRight, size: 14, color: _P.ink),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  Widget _badge(String text, {bool dark = false, Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: dark ? _P.ink : (color ?? _P.surfHigh),
        border: Border.all(color: _P.ink),
      ),
      child: Text(text,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700,
            color: dark ? _P.bg : _P.ink,
            letterSpacing: 0.8)),
    );
  }

  Widget _neoButton(String label,
      {required VoidCallback onTap, IconData? icon}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        constraints: const BoxConstraints(minHeight: 44),
        decoration: BoxDecoration(
          color: _P.bg,
          border: Border.all(color: _P.ink),
          boxShadow: const [
            BoxShadow(color: _P.deepSlate, offset: Offset(2, 2)),
          ],
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(label,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700,
                color: _P.ink,
                letterSpacing: 0.5)),
          if (icon != null) ...[
            const SizedBox(width: 8),
            Icon(icon, size: 14, color: _P.ink),
          ],
        ]),
      ),
    );
  }

  Widget _buildSkeleton() {
    return const SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(children: [
        SkeletonLoader(height: 80, radius: 4),
        SizedBox(height: 16),
        SkeletonLoader(height: 160, radius: 4),
        SizedBox(height: 16),
        SkeletonLoader(height: 70, radius: 4),
        SizedBox(height: 16),
        SkeletonLoader(height: 200, radius: 4),
        SizedBox(height: 16),
        SkeletonLoader(height: 80, radius: 4),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Modal Pengumuman
// ═══════════════════════════════════════════════════════════════════════════
class _PengumumanModal extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String token;
  final List<dynamic> kelasList;
  final VoidCallback onSuccess;

  const _PengumumanModal({
    required this.userData,
    required this.token,
    required this.kelasList,
    required this.onSuccess,
  });

  @override
  State<_PengumumanModal> createState() => _PengumumanModalState();
}

class _PengumumanModalState extends State<_PengumumanModal> {
  final _judulCtrl = TextEditingController();
  final _isiCtrl = TextEditingController();
  final Set<String> _selectedKelas = {};
  final Map<String, List<dynamic>> _channels = {};
  final Set<String> _selectedChannels = {};
  bool _isLoading = false;
  bool _isFetchingChannels = false;
  String _selectedKategori = '';
  bool _kategoriError = false;

  @override
  void dispose() {
    _judulCtrl.dispose();
    _isiCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchChannels(String kelasId) async {
    if (_channels.containsKey(kelasId)) return;
    setState(() => _isFetchingChannels = true);
    try {
      final h = {'Authorization': 'Bearer ${widget.token}'};
      final r = await http.get(
          Uri.parse('$baseUrl/api/channels?kelas_id=$kelasId'),
          headers: h);
      if (r.statusCode == 200) {
        final dec = jsonDecode(r.body);
        setState(() => _channels[kelasId] = dec is List ? dec : []);
      }
    } catch (e) {
      debugPrint('fetch channels: $e');
    }
    setState(() => _isFetchingChannels = false);
  }

  void _toggleKelas(String kelasId) {
    setState(() {
      if (_selectedKelas.contains(kelasId)) {
        _selectedKelas.remove(kelasId);
        // Hapus channel dari kelas ini dari selection
        final ch = _channels[kelasId] ?? [];
        for (final c in ch) {
          _selectedChannels.remove(c['id'].toString());
        }
      } else {
        _selectedKelas.add(kelasId);
        _fetchChannels(kelasId);
      }
    });
  }

  Future<void> _submit() async {
    if (_judulCtrl.text.trim().isEmpty || _isiCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Judul dan isi wajib diisi')));
      return;
    }
    if (_selectedKategori.isEmpty) {
      setState(() => _kategoriError = true);
      return;
    }

    if (_selectedKelas.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Pilih minimal 1 kelas')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final h = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${widget.token}',
      };
      final body = jsonEncode({
        'judul': _judulCtrl.text.trim(),
        'isi': _isiCtrl.text.trim(),
        'kategori': _selectedKategori,
        'guru_id': widget.userData['id'],
        'nama_guru': widget.userData['nama'],
        'author': widget.userData['nama'],
        'tanggal': DateTime.now().toIso8601String(),
        'kelas_ids': _selectedKelas.toList(),
        'channel_ids': _selectedChannels.toList(),
      });

      final r = await http.post(
        Uri.parse('$baseUrl/api/pengumuman'),
        headers: h,
        body: body,
      );

      if (r.statusCode == 201) {
        if (mounted) {
          Navigator.pop(context);
          widget.onSuccess();
        }
      } else {
        final err = jsonDecode(r.body);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(err['message'] ?? 'Gagal mengirim'),
            backgroundColor: AppTheme.error,
          ));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error));
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        decoration: BoxDecoration(
          color: _P.white,
          borderRadius: _kAsymmetric,
          border: Border.all(color: _P.deepSlate),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: _P.deepSlate)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Buat Pengumuman Baru',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700,
                        color: _P.deepSlate)),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(LucideIcons.x,
                        size: 20, color: _P.deepSlate),
                  ),
                ],
              ),
            ),

            // Body
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Judul
                    _label('Judul Pengumuman'),
                    const SizedBox(height: 6),
                    _field(_judulCtrl,
                        'Contoh: Jadwal ulangan tengah semester...'),
                    const SizedBox(height: 16),

                    // Isi
                    _label('Isi Pengumuman'),
                    const SizedBox(height: 6),
                    _field(_isiCtrl, 'Tulis pesan pengumuman Anda di sini...',
                        maxLines: 4),
                    const SizedBox(height: 16),
// ── Kategori ──
                    _label('Kategori'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: ['Umum', 'Ujian', 'Libur', 'Seminar'].map((k) {
                        final cfgMap = {
                          'Umum': (_P.secondary, LucideIcons.megaphone),
                          'Ujian': (
                            const Color(0xFFF59E0B),
                            LucideIcons.clipboardList
                          ),
                          'Libur': (
                            const Color(0xFF10B981),
                            LucideIcons.palmtree
                          ),
                          'Seminar': (
                            const Color(0xFF38BDF8),
                            LucideIcons.presentation
                          ),
                        };
                        final cfg = cfgMap[k]!;
                        final sel = _selectedKategori == k;
                        return GestureDetector(
                          onTap: () => setState(() {
                            _selectedKategori = k;
                            _kategoriError = false;
                          }),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 7),
                            decoration: BoxDecoration(
                              color: sel ? cfg.$1 : _P.surfLow,
                              border: Border.all(
                                color: _kategoriError && !sel
                                    ? AppTheme.error
                                    : _P.deepSlate,
                              ),
                            ),
                            child:
                                Row(mainAxisSize: MainAxisSize.min, children: [
                              Icon(cfg.$2,
                                  size: 12, color: sel ? _P.white : cfg.$1),
                              const SizedBox(width: 6),
                              Text(k,
                                  style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700,
                                    color: sel ? _P.white : _P.ink)),
                            ]),
                          ),
                        );
                      }).toList(),
                    ),
                    if (_kategoriError) ...[
                      const SizedBox(height: 4),
                      Text('Pilih kategori dulu',
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppTheme.error)),
                    ],
                    const SizedBox(height: 20),
                    const SizedBox(height: 20),

                    // Pilih Kelas
                    _label('Pilih Kelas'),
                    const SizedBox(height: 8),
                    ...widget.kelasList.map((k) {
                      final id = k['id']?.toString() ?? '';
                      final nama = k['nama_kelas']?.toString() ?? '-';
                      final selected = _selectedKelas.contains(id);

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onTap: () => _toggleKelas(id),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 6),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: selected ? _P.primCon : _P.white,
                                border: Border.all(
                                  color: selected ? _P.primary : _P.deepSlate,
                                  width: selected ? 1.5 : 1,
                                ),
                              ),
                              child: Row(children: [
                                Container(
                                  width: 18,
                                  height: 18,
                                  decoration: BoxDecoration(
                                    color: selected ? _P.primary : _P.white,
                                    border: Border.all(
                                      color:
                                          selected ? _P.primary : _P.deepSlate,
                                    ),
                                  ),
                                  child: selected
                                      ? const Icon(Icons.check,
                                          size: 12, color: _P.white)
                                      : null,
                                ),
                                const SizedBox(width: 10),
                                Text(nama,
                                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600,
                                      color: _P.ink)),
                              ]),
                            ),
                          ),

                          // Channels untuk kelas ini
                          if (selected) ...[
                            if (_isFetchingChannels)
                              const Padding(
                                padding: EdgeInsets.only(left: 16, bottom: 8),
                                child: SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: _P.primary),
                                ),
                              )
                            else if (_channels[id] != null) ...[
                              Padding(
                                padding:
                                    const EdgeInsets.only(left: 16, bottom: 6),
                                child: Text('Pilih Channel:',
                                    style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700,
                                      color: _P.muted)),
                              ),
                              _buildChannelCheckbox(
                                id: 'general_$id', 
                                label: '# General',
                              ),
                              ...(_channels[id] ?? [])
                                  .map((c) => _buildChannelCheckbox(
                                        id: c['id'].toString(),
                                        label:
                                            '# ${c['nama_channel'] ?? 'Channel'}',
                                      )),
                              const SizedBox(height: 6),
                            ],
                          ],
                        ],
                      );
                    }),
                  ],
                ),
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: _P.surfLow,
                border: Border(top: BorderSide(color: _P.deepSlate)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: _P.white,
                        border: Border.all(color: _P.deepSlate),
                        boxShadow: const [
                          BoxShadow(color: _P.deepSlate, offset: Offset(2, 2)),
                        ],
                      ),
                      child: Text('BATAL',
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700,
                            color: _P.ink,
                            letterSpacing: 0.5)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: _isLoading ? null : _submit,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: _P.primCon,
                        border: Border.all(color: _P.deepSlate),
                        boxShadow: const [
                          BoxShadow(color: _P.deepSlate, offset: Offset(2, 2)),
                        ],
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: _P.primary))
                          : Row(mainAxisSize: MainAxisSize.min, children: [
                              Text('Kirim Pengumuman',
                                  style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700,
                                    color: _P.ink,
                                    letterSpacing: 0.3)),
                              const SizedBox(width: 8),
                              const Icon(LucideIcons.send,
                                  size: 13, color: _P.ink),
                            ]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChannelCheckbox({required String id, required String label}) {
    final selected = _selectedChannels.contains(id);
    return GestureDetector(
      onTap: () => setState(() {
        if (selected) {
          _selectedChannels.remove(id);
        } else {
          _selectedChannels.add(id);
        }
      }),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 0, 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? _P.primCon.withAlpha(150) : _P.white,
          border:
              Border.all(color: selected ? _P.primary : _P.outline, width: 0.8),
        ),
        child: Row(children: [
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: selected ? _P.primary : _P.white,
              border: Border.all(color: selected ? _P.primary : _P.outline),
            ),
            child: selected
                ? const Icon(Icons.check, size: 10, color: _P.white)
                : null,
          ),
          const SizedBox(width: 8),
          Text(label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: _P.ink,
                fontWeight: FontWeight.w500)),
        ]),
      ),
    );
  }

  Widget _label(String text) => Text(text,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700,
        color: _P.deepSlate,
        letterSpacing: 0.5));

  Widget _field(TextEditingController ctrl, String hint, {int maxLines = 1}) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: _P.ink),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(color: _P.outline),
        filled: true,
        fillColor: _P.white,
        contentPadding: const EdgeInsets.all(14),
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: _P.deepSlate),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: _P.deepSlate),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: _P.primary, width: 1.5),
        ),
      ),
    );
  }
}
