import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import '../../../config/api_config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import '../../../services/notifikasi_service.dart';
import '../../../config/theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── Comic-style design tokens ───────────────────────────────────────────────
const _kBorderRadius = 16.0;
const _kBorderWidth  = 2.2;
const _kShadowOffset = Offset(4, 4);

const _kNavy    = Color(0xFF1A1F3C);
const _kTeal    = Color(0xFF2A7C76);

const _kCoral   = Color(0xFFFF6B6B);
const _kAmber   = Color(0xFFFFA41B);
const _kIndigo  = Color(0xFF4F46E5);
const _kPurple  = Color(0xFF7C3AED);
const _kGreen   = Color(0xFF10B981);
const _kBorder  = Color(0xFF1A1F3C);

BoxDecoration _comicCard({
  Color bg = Colors.white,
  Color? borderColor,
  Color shadowColor = const Color(0x55000000),
  double radius = _kBorderRadius,
}) =>
    BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: borderColor ?? _kBorder, width: _kBorderWidth),
      boxShadow: [
        BoxShadow(
          color: shadowColor,
          offset: _kShadowOffset,
          blurRadius: 0,
        ),
      ],
    );
// ─────────────────────────────────────────────────────────────────────────────

class GuruTugasDetailScreen extends StatefulWidget {
  final Map<String, dynamic> tugas;
  final String token;
  const GuruTugasDetailScreen(
      {super.key, required this.tugas, required this.token});

  @override
  State<GuruTugasDetailScreen> createState() => _GuruTugasDetailScreenState();
}

class _GuruTugasDetailScreenState extends State<GuruTugasDetailScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  List<dynamic> _pengumpulanList = [];
  List<dynamic> _nilaiList = [];

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim =
        CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _fetchData();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final headers = {'Authorization': 'Bearer ${widget.token}'};
      final results = await Future.wait([
        http.get(Uri.parse('$baseUrl/api/pengumpulan'), headers: headers),
        http.get(Uri.parse('$baseUrl/api/nilai'), headers: headers),
      ]);
      if (results[0].statusCode == 200 && results[1].statusCode == 200) {
        final decP = jsonDecode(results[0].body);
        final decN = jsonDecode(results[1].body);
        setState(() {
          _pengumpulanList = (decP is List ? decP : [])
              .where((p) => p['tugas_id'] == widget.tugas['id'])
              .toList();
          _nilaiList = (decN is List ? decN : [])
              .where((n) => n['tugas_id'] == widget.tugas['id'])
              .toList();
        });
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
    if (mounted) {
      setState(() => _isLoading = false);
      _animCtrl.forward();
    }
  }

  String _formatDate(String? iso) {
    if (iso == null) return '-';
    try {
      return DateFormat('dd MMM yyyy, HH:mm').format(DateTime.parse(iso));
    } catch (_) {
      return iso;
    }
  }

  bool _isDeadlinePast() {
    try {
      return DateTime.now().isAfter(DateTime.parse(widget.tugas['deadline']));
    } catch (_) {
      return false;
    }
  }

  Color _scoreColor(int s) {
    if (s >= 85) return _kGreen;
    if (s >= 70) return _kTeal;
    if (s >= 55) return _kAmber;
    return _kCoral;
  }

  String _scoreLabel(int s) {
    if (s >= 90) return 'Sempurna ⭐';
    if (s >= 80) return 'Sangat Baik';
    if (s >= 70) return 'Baik';
    if (s >= 60) return 'Cukup';
    return 'Perlu Latihan';
  }

  // ─── Dialog Nilai ──────────────────────────────────────────────────────────
  void _showNilaiDialog(
      Map<String, dynamic> p, Map<String, dynamic>? existing) {
    final ctrl = TextEditingController(
        text: existing != null ? existing['nilai'].toString() : '');
    final fbCtrl = TextEditingController(
        text: existing != null ? existing['feedback']?.toString() ?? '' : '');

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: _kBorder, width: _kBorderWidth),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _kIndigo,
                      borderRadius: BorderRadius.circular(10),
                      border: const Border.fromBorderSide(
                          BorderSide(color: _kBorder, width: 1.5)),
                    ),
                    child: const Icon(LucideIcons.award,
                        color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    existing != null ? 'Edit Nilai' : 'Beri Nilai',
                    style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: _kNavy),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Siswa chip
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F4FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _kIndigo.withAlpha(80), width: 1.5),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: _kIndigo,
                      radius: 16,
                      child: Text(
                        (p['siswa_nama'] ?? 'S')
                            .substring(0, 1)
                            .toUpperCase(),
                        style: GoogleFonts.inter(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 14),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      p['siswa_nama'] ?? 'Siswa',
                      style: GoogleFonts.inter(
                          fontWeight: FontWeight.w800, color: _kNavy),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _comicTextField(ctrl, 'Nilai (0–100)', LucideIcons.award),
              const SizedBox(height: 12),
              _comicTextField(
                  fbCtrl, 'Feedback (opsional)', LucideIcons.messageSquare,
                  maxLines: 3),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text('Batal',
                        style: GoogleFonts.inter(
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 10),
                  _comicButton(
                    label: 'Simpan',
                    icon: LucideIcons.save,
                    bg: _kTeal,
                    onTap: () async {
                      if (ctrl.text.isEmpty) return;
                      final nilaiVal = int.tryParse(ctrl.text) ?? 0;
                      final body = {
                        'siswa_id': p['siswa_id'],
                        'siswa_nama': p['siswa_nama'],
                        'guru_id': widget.tugas['guru_id'],
                        'guru_nama': widget.tugas['guru_nama'],
                        'mapel': widget.tugas['mapel'] ??
                            widget.tugas['kelas'] ??
                            'Umum',
                        'tugas_id': widget.tugas['id'],
                        'tugas_judul': widget.tugas['judul'],
                        'kelas_id': widget.tugas['kelas_id'],
                        'nilai': nilaiVal,
                        'feedback': fbCtrl.text.trim(),
                        'waktu_dinilai': DateTime.now().toIso8601String(),
                      };
                      final headers = {
                        'Content-Type': 'application/json',
                        'Authorization': 'Bearer ${widget.token}'
                      };
                      try {
                        if (existing != null) {
                          await http.put(
                              Uri.parse(
                                  '$baseUrl/api/nilai/${existing['id']}'),
                              headers: headers,
                              body: jsonEncode(body));
                        } else {
                          await http.post(Uri.parse('$baseUrl/api/nilai'),
                              headers: headers, body: jsonEncode(body));
                          await http.put(
                              Uri.parse(
                                  '$baseUrl/api/pengumpulan/${p['id']}'),
                              headers: headers,
                              body: jsonEncode(
                                  {...p, 'status': 'Dinilai'}));
                          NotifikasiService.kirimNotifikasi(
                            judul: 'Nilai Tugas Keluar!',
                            pesan:
                                'Tugas "${widget.tugas['judul']}" kamu dapat nilai $nilaiVal dari ${widget.tugas['guru_nama']}',
                            token: widget.token,
                            targetUserId: p['siswa_id'],
                          );
                        }
                        if (ctx.mounted) Navigator.pop(ctx);
                        _fetchData();
                      } catch (e) {
                        debugPrint('Error saving nilai: $e');
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _comicTextField(
      TextEditingController ctrl, String label, IconData icon,
      {int maxLines = 1}) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType:
          maxLines == 1 ? TextInputType.number : TextInputType.multiline,
      style: GoogleFonts.inter(
          fontWeight: FontWeight.w700, color: _kNavy, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(
            color: Colors.grey.shade500,
            fontWeight: FontWeight.w600,
            fontSize: 13),
        prefixIcon: Icon(icon, size: 18, color: _kIndigo),
        filled: true,
        fillColor: const Color(0xFFF8F9FF),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _kBorder, width: 1.8),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _kIndigo, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }

  // ─── Main build ──────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isPast = _isDeadlinePast();
    final gradedCount = _nilaiList.length;
    final totalCount = _pengumpulanList.length;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF0F2FF),
        appBar: _appBar(),
        body: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(_kIndigo),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2FF),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── HERO HEADER ──────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 230,
            pinned: true,
            stretch: true,
            backgroundColor: _kNavy,
            elevation: 0,
            leading: Padding(
              padding: const EdgeInsets.all(10),
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(20),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: Colors.white.withAlpha(60), width: 1.5),
                  ),
                  child: const Icon(LucideIcons.arrowLeft,
                      color: Colors.white, size: 20),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax,
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Gradient background
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [_kNavy, Color(0xFF2D1B69), Color(0xFF4F46E5)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                  // Dot pattern overlay
                  Opacity(
                    opacity: 0.07,
                    child: CustomPaint(painter: _DotPatternPainter()),
                  ),
                  // Content
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 52, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // Badges row
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              _heroBadge(
                                label: isPast ? '⚠ TERLAMBAT' : '✓ AKTIF',
                                bg: isPast ? _kCoral : _kGreen,
                              ),
                              if (widget.tugas['kelas'] != null)
                                _heroBadge(
                                  label: widget.tugas['kelas'],
                                  bg: _kTeal,
                                ),
                              if (widget.tugas['mapel'] != null)
                                _heroBadge(
                                  label: widget.tugas['mapel'],
                                  bg: _kPurple,
                                ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          // Title
                          Text(
                            widget.tugas['judul'] ?? 'Tanpa Judul',
                            style: GoogleFonts.inter(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -0.5,
                              height: 1.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          if (widget.tugas['deadline'] != null)
                            Row(
                              children: [
                                const Icon(LucideIcons.clock,
                                    size: 13,
                                    color: Color(0xFFFFD166)),
                                const SizedBox(width: 6),
                                Text(
                                  'Tenggat: ${_formatDate(widget.tugas['deadline'])}',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFFFFD166),
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
            ),
          ),

          // ── BODY ─────────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 20, 18, 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── STAT CARDS ──────────────────────────────────────
                    Row(
                      children: [
                        _statCard(
                            label: 'Mengumpulkan',
                            value: '$totalCount',
                            icon: LucideIcons.users,
                            bg: const Color(0xFFE8F4FD),
                            iconColor: AppTheme.info,
                            borderColor: AppTheme.info),
                        const SizedBox(width: 10),
                        _statCard(
                            label: 'Dinilai',
                            value: '$gradedCount',
                            icon: LucideIcons.checkSquare,
                            bg: const Color(0xFFE6F9F3),
                            iconColor: _kGreen,
                            borderColor: _kGreen),
                        const SizedBox(width: 10),
                        _statCard(
                            label: 'Pending',
                            value: '${totalCount - gradedCount}',
                            icon: LucideIcons.clock,
                            bg: const Color(0xFFFFF8E8),
                            iconColor: _kAmber,
                            borderColor: _kAmber),
                      ],
                    ),
                    const SizedBox(height: 22),

                    // ── DESKRIPSI ────────────────────────────────────────
                    _sectionHeader('DESKRIPSI TUGAS', LucideIcons.fileText,
                        _kIndigo),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      decoration: _comicCard(
                        bg: Colors.white,
                        borderColor: _kIndigo,
                        shadowColor: _kIndigo.withAlpha(80),
                      ),
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.tugas['judul'] ?? 'Tanpa Judul',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: _kNavy,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            height: 3,
                            width: 40,
                            decoration: BoxDecoration(
                              color: _kIndigo,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            widget.tugas['deskripsi'] ??
                                'Tidak ada deskripsi.',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              height: 1.65,
                              color: const Color(0xFF4B5563),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (widget.tugas['kelas'] != null ||
                              widget.tugas['mapel'] != null) ...[
                            const SizedBox(height: 14),
                            Wrap(
                              spacing: 8,
                              children: [
                                if (widget.tugas['kelas'] != null)
                                  _boldBadge(
                                      widget.tugas['kelas'], _kTeal),
                                if (widget.tugas['mapel'] != null)
                                  _boldBadge(
                                      widget.tugas['mapel'], _kPurple),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),

                    // ── LAMPIRAN ─────────────────────────────────────────
                    if (widget.tugas['link'] != null &&
                        widget.tugas['link'].toString().isNotEmpty) ...[
                      const SizedBox(height: 22),
                      _sectionHeader('LAMPIRAN MATERI / SOAL',
                          LucideIcons.paperclip, _kTeal),
                      const SizedBox(height: 12),
                      _lampiranCard(),
                    ],

                    // ── STATUS PENGUMPULAN ────────────────────────────────
                    const SizedBox(height: 22),
                    _sectionHeader('STATUS PENGUMPULAN SISWA',
                        LucideIcons.clipboardCheck, _kCoral),
                    const SizedBox(height: 12),

                    if (_pengumpulanList.isEmpty)
                      _emptyState()
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _pengumpulanList.length,
                        itemBuilder: (_, i) =>
                            _pengumpulanCard(_pengumpulanList[i]),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Widgets ─────────────────────────────────────────────────────────────

  AppBar _appBar() => AppBar(
        backgroundColor: _kNavy,
        elevation: 0,
        title: Text('Detail Tugas',
            style: GoogleFonts.inter(
                color: Colors.white, fontWeight: FontWeight.w800)),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      );

  Widget _heroBadge({required String label, required Color bg}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withAlpha(80), width: 1.2),
          boxShadow: [
            BoxShadow(
                color: bg.withAlpha(120),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: 0.3,
          ),
        ),
      );

  Widget _sectionHeader(String title, IconData icon, Color color) => Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(9),
              border:
                  const Border.fromBorderSide(BorderSide(color: _kBorder, width: 1.8)),
              boxShadow: [
                BoxShadow(
                    color: color.withAlpha(100),
                    offset: const Offset(2, 2),
                    blurRadius: 0)
              ],
            ),
            child: Icon(icon, size: 14, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: color,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              height: 2,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                    colors: [color.withAlpha(160), Colors.transparent]),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ],
      );

  Widget _statCard({
    required String label,
    required String value,
    required IconData icon,
    required Color bg,
    required Color iconColor,
    required Color borderColor,
  }) =>
      Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor, width: _kBorderWidth),
            boxShadow: [
              BoxShadow(
                  color: borderColor.withAlpha(80),
                  offset: const Offset(3, 3),
                  blurRadius: 0)
            ],
          ),
          child: Column(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(height: 6),
              Text(
                value,
                style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: iconColor,
                    height: 1),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: iconColor),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );

  Widget _boldBadge(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          border:
              const Border.fromBorderSide(BorderSide(color: _kBorder, width: 1.5)),
          boxShadow: [
            BoxShadow(
                color: color.withAlpha(100),
                offset: const Offset(2, 2),
                blurRadius: 0)
          ],
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
              fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white),
        ),
      );

  Widget _lampiranCard() => GestureDetector(
        onTap: () async {
          String raw = widget.tugas['link'].toString();
          if (raw.toLowerCase().contains('.pdf') || raw.contains('/raw/')) {
            raw =
                'https://docs.google.com/viewer?url=${Uri.encodeComponent(raw)}';
          }
          final url = Uri.parse(raw);
          if (await canLaunchUrl(url)) {
            await launchUrl(url, mode: LaunchMode.externalApplication);
          } else if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Gagal membuka file!')),
            );
          }
        },
        child: Container(
          decoration: _comicCard(
            bg: const Color(0xFFE8F4FD),
            borderColor: AppTheme.info,
            shadowColor: AppTheme.info.withAlpha(120),
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.info,
                  borderRadius: BorderRadius.circular(12),
                  border: const Border.fromBorderSide(
                      BorderSide(color: _kBorder, width: 1.5)),
                  boxShadow: [
                    BoxShadow(
                        color: AppTheme.info.withAlpha(100),
                        offset: const Offset(2, 2),
                        blurRadius: 0)
                  ],
                ),
                child: const Icon(LucideIcons.fileText,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Buka File Lampiran',
                      style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.info),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Ketuk untuk mengunduh / melihat',
                      style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.info.withAlpha(180)),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.info,
                  borderRadius: BorderRadius.circular(8),
                  border: const Border.fromBorderSide(
                      BorderSide(color: _kBorder, width: 1.2)),
                ),
                child: const Icon(LucideIcons.externalLink,
                    color: Colors.white, size: 14),
              ),
            ],
          ),
        ),
      );

  Widget _emptyState() => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        decoration: _comicCard(
          bg: Colors.white,
          borderColor: Colors.grey.shade300,
          shadowColor: Colors.grey.withAlpha(60),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade300, width: 2),
              ),
              child: Icon(LucideIcons.inbox,
                  color: Colors.grey.shade400, size: 32),
            ),
            const SizedBox(height: 14),
            Text(
              'Belum Ada Pengumpulan',
              style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: Colors.grey.shade600),
            ),
            const SizedBox(height: 5),
            Text(
              'Belum ada siswa yang mengumpulkan tugas ini.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );

  Widget _pengumpulanCard(Map<String, dynamic> p) {
    Map<String, dynamic>? existing;
    try {
      existing = _nilaiList.firstWhere(
          (n) => n['siswa_id'] == p['siswa_id'] && n['tugas_id'] == widget.tugas['id']);
    } catch (_) {
      existing = null;
    }
    final isGraded = existing != null;
    final List<dynamic> files = p['files'] ?? [];
    final accent = isGraded ? _kGreen : _kIndigo;
    final int? score = existing != null ? existing['nilai'] as int? : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: _comicCard(
        bg: Colors.white,
        borderColor: accent,
        shadowColor: accent.withAlpha(100),
      ),
      child: Column(
        children: [
          // ── Card header strip ──────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: accent,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(_kBorderRadius - 2),
                topRight: Radius.circular(_kBorderRadius - 2),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // Avatar
                CircleAvatar(
                  backgroundColor: Colors.white.withAlpha(30),
                  radius: 20,
                  child: Text(
                    (p['siswa_nama'] ?? 'S').substring(0, 1).toUpperCase(),
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        fontSize: 16),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p['siswa_nama'] ?? 'Siswa',
                        style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: Colors.white),
                      ),
                      Row(
                        children: [
                          const Icon(LucideIcons.clock,
                              size: 11, color: Colors.white70),
                          const SizedBox(width: 4),
                          Text(
                            _formatDate(p['waktu_pengumpulan']),
                            style: GoogleFonts.inter(
                                fontSize: 11,
                                color: Colors.white70,
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Status pill
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: Colors.white.withAlpha(180), width: 1.5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isGraded
                            ? LucideIcons.checkCircle
                            : LucideIcons.clock,
                        size: 12,
                        color: accent,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isGraded ? 'Dinilai' : 'Diserahkan',
                        style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: accent),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Card body ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // File jawaban
                Text(
                  'FILE JAWABAN',
                  style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: Colors.grey.shade500,
                      letterSpacing: 1.2),
                ),
                const SizedBox(height: 8),
                if (files.isEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: Colors.grey.shade200, width: 1.5),
                    ),
                    child: Row(
                      children: [
                        Icon(LucideIcons.fileMinus,
                            size: 14, color: Colors.grey.shade400),
                        const SizedBox(width: 8),
                        Text(
                          'Tidak ada file jawaban',
                          style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.grey.shade400,
                              fontStyle: FontStyle.italic),
                        ),
                      ],
                    ),
                  )
                else
                  ...files.asMap().entries.map((e) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: GestureDetector(
                          onTap: () async {
                            final url = Uri.parse(e.value.toString());
                            if (await canLaunchUrl(url)) {
                              await launchUrl(url,
                                  mode: LaunchMode.externalApplication);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: accent.withAlpha(12),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: accent.withAlpha(80), width: 1.5),
                            ),
                            child: Row(
                              children: [
                                Icon(LucideIcons.paperclip,
                                    size: 14, color: accent),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Buka Lampiran ${e.key + 1}',
                                    style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: accent,
                                        fontWeight: FontWeight.w700),
                                  ),
                                ),
                                Icon(LucideIcons.externalLink,
                                    size: 12,
                                    color: accent.withAlpha(180)),
                              ],
                            ),
                          ),
                        ),
                      )),

                const SizedBox(height: 14),
                Divider(color: Colors.grey.shade200, height: 1, thickness: 1),
                const SizedBox(height: 14),

                // Nilai + Tombol
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (isGraded && score != null) ...[
                      // Score box
                      Container(
                        width: 68,
                        height: 68,
                        decoration: BoxDecoration(
                          color: _scoreColor(score),
                          borderRadius: BorderRadius.circular(14),
                          border: const Border.fromBorderSide(
                              BorderSide(color: _kBorder, width: 2)),
                          boxShadow: [
                            BoxShadow(
                                color: _scoreColor(score).withAlpha(120),
                                offset: const Offset(3, 3),
                                blurRadius: 0)
                          ],
                        ),
                        child: Center(
                          child: Text(
                            '$score',
                            style: GoogleFonts.inter(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _scoreLabel(score),
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                color: _scoreColor(score),
                              ),
                            ),
                            if (existing['feedback'] != null &&
                                existing['feedback']
                                    .toString()
                                    .isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                '"${existing['feedback']}"',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.grey.shade500,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                    ] else
                      const Spacer(),
                    // Action button
                    _comicButton(
                      label: isGraded ? 'Edit Nilai' : 'Beri Nilai →',
                      icon: isGraded ? LucideIcons.edit2 : LucideIcons.checkSquare,
                      bg: isGraded ? _kGreen : _kTeal,
                      onTap: () => _showNilaiDialog(p, existing),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _comicButton({
    required String label,
    required IconData icon,
    required Color bg,
    required VoidCallback onTap,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
            border: const Border.fromBorderSide(
                BorderSide(color: _kBorder, width: 1.8)),
            boxShadow: [
              BoxShadow(
                  color: bg.withAlpha(150),
                  offset: const Offset(3, 3),
                  blurRadius: 0)
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: Colors.white),
              const SizedBox(width: 7),
              Text(
                label,
                style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: Colors.white),
              ),
            ],
          ),
        ),
      );
}

// ─── Dot pattern painter ──────────────────────────────────────────────────────
class _DotPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const spacing = 20.0;
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.5
      ..style = PaintingStyle.fill;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.5, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DotPatternPainter _) => false;
}
