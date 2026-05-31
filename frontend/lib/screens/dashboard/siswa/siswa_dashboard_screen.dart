import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';
import '../../../config/api_config.dart';
import 'siswa_tugas_detail_screen.dart';

// Tailwind Colors Mapping
const Color _bgBackground = Color(0xFFF4FAFF);
const Color _bgPrimaryContainer = Color(0xFFB7E5CD);
const Color _bgErrorContainer = Color(0xFFFFDAD6);
const Color _bgTertiaryContainer = Color(0xFFFFD1C0);
const Color _bgSurfaceContainerHighest = Color(0xFFC1E8FF);
const Color _bgSurfaceContainerLow = Color(0xFFE8F6FF);
const Color _bgSurfaceContainerLowest = Color(0xFFFFFFFF);
const Color _primary = Color(0xFF3D6754);
const Color _secondary = Color(0xFF336763);
const Color _tertiary = Color(0xFF8D4D33);
const Color _onBackground = Color(0xFF001E2B);
const Color _onSurface = Color(0xFF001E2B);
const Color _onSurfaceVariant = Color(0xFF414944);
const Color _onPrimary = Color(0xFFFFFFFF);
const Color _onSecondary = Color(0xFFFFFFFF);
const Color _onErrorContainer = Color(0xFF93000A);
const Color _onTertiaryContainer = Color(0xFF8E4F34);
const Color _onTertiaryFixed = Color(0xFF370E00);
const Color _tertiaryFixedDim = Color(0xFFFFB598);
const Color _neutralSlate = Color(0xFF414944);
const Color _outlineVariant = Color(0xFFC1C8C2);

class SiswaDashboardScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String token;
  const SiswaDashboardScreen({
    super.key,
    required this.userData,
    required this.token,
  });

  @override
  State<SiswaDashboardScreen> createState() => _SiswaDashboardScreenState();
}

class _SiswaDashboardScreenState extends State<SiswaDashboardScreen> {
  bool _isLoading = true;
  List<dynamic> _tugasList = [];
  List<dynamic> _pengumumanList = [];
  List<dynamic> _pengumpulanList = [];
  List<dynamic> _kelasList = [];
  Set<String> _readIds = {};

  @override
  void initState() {
    super.initState();
    _loadAndFetch();
  }

  Future<void> _loadAndFetch() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('read_pengumuman_${widget.userData['id']}') ?? [];
    _readIds = list.toSet();
    await _fetchData();
  }

  Future<void> _markRead(String id) async {
    setState(() => _readIds.add(id));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('read_pengumuman_${widget.userData['id']}', _readIds.toList());
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
        List<dynamic> allTugas = [];
        
        // Fetch tugas in parallel for all classes
        final tugasFutures = _kelasList.map((k) {
          return http.get(
            Uri.parse('$baseUrl/api/tugas?kelas=${Uri.encodeComponent(k['nama_kelas'])}'),
            headers: headers,
          );
        });
        
        final tugasResponses = await Future.wait(tugasFutures);
        for (var tResp in tugasResponses) {
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

  Map<String, int> get _stats {
    int lewat = 0, belum = 0, selesai = 0;
    for (var t in _tugasList) {
      if (_pengumpulanList.any((p) => p['tugas_id'].toString() == t['id'].toString())) {
        selesai++;
        continue;
      }
      final dl = DateTime.tryParse(t['deadline']?.toString() ?? '');
      if (dl != null && dl.isBefore(DateTime.now())) {
        lewat++;
        continue;
      }
      belum++;
    }
    return {'belum': belum, 'lewat': lewat, 'selesai': selesai};
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: _primary));
    }

    final s = _stats;
    final name = widget.userData['nama'] ?? widget.userData['name'] ?? 'Siswa';
    final dateStr = DateFormat('EEEE, dd MMM yyyy', 'id_ID').format(DateTime.now());

    return Scaffold(
      backgroundColor: _bgBackground,
      body: RefreshIndicator(
        onRefresh: _fetchData,
        color: _primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Welcome Section
              _BentoCard(
                color: Colors.white,
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text.rich(
                      TextSpan(
                        text: 'Selamat siang, ',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: _onBackground,
                          height: 1.2,
                        ),
                        children: [
                          TextSpan(
                            text: name,
                            style: const TextStyle(color: _primary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined, size: 16, color: _onSurfaceVariant),
                        const SizedBox(width: 8),
                        Text(
                          dateStr,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            color: _onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Quotes of the Day
              InkWell(
                onTap: () {
                  showDialog(context: context, builder: (_) => const _QuoteDialog());
                },
                child: _BentoCard(
                  color: _bgPrimaryContainer,
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.format_quote_rounded, color: _onSurface),
                          const SizedBox(width: 12),
                          Text(
                            'QUOTES OF THE DAY',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                              color: _onSurface,
                            ),
                          ),
                        ],
                      ),
                      const Icon(Icons.arrow_forward_rounded, color: _onSurface),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Stats Row
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: _BentoCard(
                      color: Colors.white,
                      padding: const EdgeInsets.all(24),
                      borderWidth: 2,
                      borderColor: _primary,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${_kelasList.length} Kelas Aktif',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: _onBackground,
                            ),
                          ),
                          Container(
                            height: 48,
                            width: 48,
                            decoration: BoxDecoration(
                              color: _secondary,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: _neutralSlate),
                            ),
                            child: const Icon(Icons.school_rounded, color: _onSecondary),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _BentoCard(
                      color: _bgErrorContainer,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'BELUM KUMPUL',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: _onErrorContainer,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                '${s['belum']}'.padLeft(2, '0'),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 48,
                                  fontWeight: FontWeight.w800,
                                  color: _onErrorContainer,
                                  height: 1.1,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Tugas',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: _onErrorContainer.withAlpha(178),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _BentoCard(
                      color: _bgTertiaryContainer,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'LEWAT DEADLINE',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: _onTertiaryContainer,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                '${s['lewat']}'.padLeft(2, '0'),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 48,
                                  fontWeight: FontWeight.w800,
                                  color: _onTertiaryContainer,
                                  height: 1.1,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Tugas',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: _onTertiaryContainer.withAlpha(178),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Progress Card
              _BentoCard(
                color: _bgSurfaceContainerHighest,
                padding: const EdgeInsets.all(16),
                isDashed: true,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SELESAI',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _onSurfaceVariant,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text.rich(
                          TextSpan(
                            text: '${s['selesai']} ',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: _onSurface,
                            ),
                            children: [
                              TextSpan(
                                text: '/ ${_tugasList.length} Total',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w400,
                                  color: _onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Container(
                      width: 96,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _outlineVariant,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: _neutralSlate),
                      ),
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: _tugasList.isEmpty ? 0 : s['selesai']! / _tugasList.length,
                        child: Container(
                          decoration: BoxDecoration(
                            color: _primary,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Tugas Mendatang
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Tugas Mendatang',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: _onBackground,
                    ),
                  ),
                  InkWell(
                    onTap: () {}, // Navigate to full tasks view if needed
                    child: Container(
                      decoration: const BoxDecoration(
                        border: Border(bottom: BorderSide(color: _primary, width: 2)),
                      ),
                      child: Text(
                        'LIHAT SEMUA',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _primary,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ..._tugasList.take(5).map((t) {
                final submitted = _pengumpulanList.any((p) => p['tugas_id'].toString() == t['id'].toString());
                final dl = DateTime.tryParse(t['deadline']?.toString() ?? '');
                final isLate = dl != null && dl.isBefore(DateTime.now()) && !submitted;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    onTap: () => Navigator.push(context, MaterialPageRoute(
                      builder: (_) => SiswaTugasDetailScreen(tugas: t, userData: widget.userData, token: widget.token),
                    )),
                    child: _TugasBentoCard(
                      tugas: t,
                      submitted: submitted,
                      isLate: isLate,
                      deadline: dl,
                    ),
                  ),
                );
              }),
              const SizedBox(height: 12),

              // Pengumuman Sekolah
              _BentoCard(
                color: _bgSurfaceContainerLowest,
                borderWidth: 2,
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Pengumuman Sekolah',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: _onBackground,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _secondary,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: _neutralSlate),
                          ),
                          child: Text(
                            '${_pengumumanList.length} INFO',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: _onSecondary,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    ..._pengumumanList.take(5).map((p) => _PengumumanItem(
                          pengumuman: p,
                          isNew: !_readIds.contains(p['id'].toString()),
                          onMarkRead: () => _markRead(p['id'].toString()),
                        )),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _BentoCard extends StatelessWidget {
  final Widget child;
  final Color color;
  final EdgeInsetsGeometry padding;
  final double borderWidth;
  final Color? borderColor;
  final bool isDashed;

  const _BentoCard({
    required this.child,
    required this.color,
    this.padding = const EdgeInsets.all(0),
    this.borderWidth = 1.0,
    this.borderColor,
    this.isDashed = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(4),
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(4),
        ),
        border: Border.all(
          color: borderColor ?? _neutralSlate,
          width: borderWidth,
        ),
      ),
      child: child,
    );
  }
}

class _TugasBentoCard extends StatelessWidget {
  final dynamic tugas;
  final bool submitted;
  final bool isLate;
  final DateTime? deadline;

  const _TugasBentoCard({
    required this.tugas,
    required this.submitted,
    required this.isLate,
    required this.deadline,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        _BentoCard(
          color: Colors.white,
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _bgSurfaceContainerLow,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _neutralSlate),
                ),
                child: const Icon(Icons.description_outlined, color: _primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tugas['judul'] ?? '-',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _onBackground,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      deadline != null ? 'Deadline: ${DateFormat('dd MMM yyyy, HH:mm').format(deadline!)}' : '-',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: _onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Positioned(
          top: -10,
          right: 16, // Instead of left, matching punch out but preventing overlap with left content
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: submitted ? _primary : (isLate ? _onErrorContainer : _onTertiaryFixed),
              border: Border.all(color: _neutralSlate),
            ),
            child: Text(
              submitted ? 'SELESAI' : (isLate ? 'TERLAMBAT' : 'BELUM'),
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: submitted ? _onPrimary : (isLate ? _bgErrorContainer : _tertiaryFixedDim),
                letterSpacing: 1.2,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PengumumanItem extends StatelessWidget {
  final dynamic pengumuman;
  final bool isNew;
  final VoidCallback onMarkRead;

  const _PengumumanItem({
    required this.pengumuman,
    required this.isNew,
    required this.onMarkRead,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onMarkRead,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 24.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: isNew ? 8 : 4,
              height: 48,
              decoration: BoxDecoration(
                color: isNew ? _primary : _tertiary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isNew ? 'INFO BARU' : 'DIBACA',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _onSurfaceVariant,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    pengumuman['judul'] ?? '-',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _onSurface,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    pengumuman['isi'] ?? '-',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: _onSurfaceVariant,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuoteDialog extends StatelessWidget {
  const _QuoteDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: _BentoCard(
        color: Colors.white,
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: _onTertiaryFixed,
                    border: Border.all(color: _neutralSlate),
                  ),
                  child: Text(
                    'DAILY WISDOM',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _tertiaryFixedDim,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                InkWell(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close_rounded, color: _onSurfaceVariant),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              '"Pendidikan adalah senjata paling mematikan di dunia, karena dengan itu Anda bisa mengubah dunia."',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                fontStyle: FontStyle.italic,
                color: _onSurface,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 4,
              width: 48,
              decoration: BoxDecoration(
                color: _primary,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '� Nelson Mandela',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: _primary,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 32),
            Align(
              alignment: Alignment.centerRight,
              child: InkWell(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  decoration: BoxDecoration(
                    color: _bgSurfaceContainerLow,
                    border: Border.all(color: _neutralSlate),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'TUTUP',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _onSurface,
                      letterSpacing: 1.2,
                    ),
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
