import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../config/api_config.dart';
import '../../../widgets/app_shell.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

// ─── Comic tokens ─────────────────────────────────────────────────────────
const _kNavy   = Color(0xFF1A1F3C);
const _kTeal   = Color(0xFF2A7C76);
const _kIndigo = Color(0xFF4F46E5);
const _kBorder = Color(0xFF1A1F3C);

BoxDecoration _comicCard({
  Color bg = Colors.white,
  Color? borderColor,
  Color shadowColor = const Color(0x55000000),
  double radius = 16,
}) =>
    BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: borderColor ?? _kBorder, width: 2.2),
      boxShadow: [
        BoxShadow(color: shadowColor, offset: const Offset(4, 4), blurRadius: 0),
      ],
    );


class SiswaMateriView extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String token;
  final dynamic teamData;

  const SiswaMateriView({
    super.key,
    required this.userData,
    required this.token,
    required this.teamData,
  });

  @override
  State<SiswaMateriView> createState() => _SiswaMateriViewState();
}

class _SiswaMateriViewState extends State<SiswaMateriView> {
  List<dynamic> _materiList = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchMateri();
  }

  Future<void> _fetchMateri() async {
    setState(() => _isLoading = true);
    try {
      final kelasId = widget.teamData['id'];
      final response = await http.get(
        Uri.parse('$baseUrl/api/materi?kelas_id=$kelasId'),
        headers: {'Authorization': 'Bearer ${widget.token}'}
      );
      if (response.statusCode == 200) {
        final dec = jsonDecode(response.body);
        List all = dec is List ? dec : [];
        setState(() => _materiList = all);
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  List<dynamic> get _filtered {
    if (_searchQuery.isEmpty) return _materiList;
    return _materiList.where((m) {
      final text = ("${m['judul']} ${m['mapel']} ${m['deskripsi']}").toLowerCase();
      return text.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildSkeleton();
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          // ── Comic Search Bar ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _kIndigo, width: 2.2),
                boxShadow: [
                  BoxShadow(color: _kIndigo.withAlpha(80), offset: const Offset(4, 4), blurRadius: 0),
                ],
              ),
              child: TextField(
                onChanged: (val) => setState(() => _searchQuery = val),
                style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14, color: _kNavy),
                decoration: InputDecoration(
                  hintText: 'Cari materi pelajaran...',
                  hintStyle: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 14, color: Colors.grey.shade400),
                  prefixIcon: const Icon(LucideIcons.search, size: 18, color: _kIndigo),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.2, curve: Curves.easeOutCubic),

          Expanded(
            child: _filtered.isEmpty
                ? _buildEmpty()
                : RefreshIndicator(
                    onRefresh: _fetchMateri,
                    color: _kIndigo,
                    child: LayoutBuilder(
                      builder: (ctx, c) {
                        final w = c.maxWidth;
                        final padding = Breakpoints.screenPadding(w);
                        return ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          padding: EdgeInsets.only(
                            left: padding.left,
                            right: padding.right,
                            top: 12,
                            bottom: 100,
                          ),
                          itemCount: _filtered.length,
                          itemBuilder: (_, i) {
                            final m = _filtered[i];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: _MateriCard(materi: m)
                                  .animate(delay: (i * 50).ms)
                                  .fadeIn(duration: 400.ms)
                                  .slideY(begin: 0.1, curve: Curves.easeOutQuart),
                            );
                          },
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    final isEmpty = _searchQuery.isEmpty;
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
        decoration: _comicCard(
          bg: Colors.white,
          borderColor: Colors.grey.shade300,
          shadowColor: Colors.grey.withAlpha(60),
        ),
        child: Column(children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _kIndigo.withAlpha(20),
              shape: BoxShape.circle,
              border: Border.all(color: _kIndigo.withAlpha(80), width: 2),
            ),
            child: const Icon(LucideIcons.bookOpen, color: _kIndigo, size: 28),
          ),
          const SizedBox(height: 14),
          Text(
            isEmpty ? 'Belum ada materi\ndi kelas ini.' : 'Materi tidak ditemukan.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 15, color: _kNavy),
          ),
          const SizedBox(height: 6),
          Text(
            isEmpty ? 'Tunggu guru menambahkan materi.' : 'Coba kata kunci lain.',
            style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
          ),
        ]),
      ),
    );
  }

  Widget _buildSkeleton() {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: SkeletonLoader(height: 52, radius: 14),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: 5,
            itemBuilder: (_, __) => const Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: SkeletonLoader(height: 110, radius: 16),
            ),
          ),
        ),
      ],
    );
  }
}

class _MateriCard extends StatelessWidget {
  final dynamic materi;
  const _MateriCard({required this.materi});

  String _formatDate(String? iso) {
    if (iso == null) return '-';
    try {
      return DateFormat('dd MMM yyyy').format(DateTime.parse(iso));
    } catch (_) {
      return iso;
    }
  }

  Future<void> _launchURL(String? url) async {
    if (url == null || url.isEmpty) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showDetail(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withAlpha(60),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 480),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _kBorder, width: 2.2),
            boxShadow: const [BoxShadow(color: Color(0x55000000), offset: Offset(6, 6), blurRadius: 0)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header strip
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_kNavy, Color(0xFF2D1B69), _kIndigo],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(17),
                    topRight: Radius.circular(17),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(25),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withAlpha(60), width: 1.2),
                      ),
                      child: Text('MATERI PELAJARAN',
                        style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w900, color: const Color(0xFFFFD166), letterSpacing: 1.2)),
                    ),
                    const SizedBox(height: 8),
                    Text(materi['judul'] ?? '-',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 17, color: Colors.white),
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              // Content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (materi['guru_nama'] != null) ...[
                        _detailRow(LucideIcons.userCheck, 'Guru', materi['guru_nama'], _kTeal),
                        const SizedBox(height: 14),
                      ],
                      if (materi['created_at'] != null) ...[
                        _detailRow(LucideIcons.calendar, 'Dibuat', _formatDate(materi['created_at']), _kIndigo),
                        const SizedBox(height: 14),
                      ],
                      if (materi['deskripsi'] != null && materi['deskripsi'].toString().isNotEmpty) ...[
                        Text('DESKRIPSI',
                          style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey.shade400, letterSpacing: 1.2)),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0F2FF),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _kIndigo.withAlpha(60), width: 1.5),
                          ),
                          child: Text(materi['deskripsi'],
                            style: GoogleFonts.inter(height: 1.6, fontWeight: FontWeight.w500, fontSize: 13, color: _kNavy)),
                        ),
                        const SizedBox(height: 18),
                      ],
                      if (materi['file_url'] != null && materi['file_url'].toString().isNotEmpty)
                        GestureDetector(
                          onTap: () => _launchURL(materi['file_url']),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: _kTeal,
                              borderRadius: BorderRadius.circular(12),
                              border: const Border.fromBorderSide(BorderSide(color: _kBorder, width: 1.8)),
                              boxShadow: [BoxShadow(color: _kTeal.withAlpha(120), offset: const Offset(3, 3), blurRadius: 0)],
                            ),
                            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                              const Icon(LucideIcons.downloadCloud, color: Colors.white, size: 16),
                              const SizedBox(width: 8),
                              Text('Buka File Materi',
                                style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 13, color: Colors.white)),
                            ]),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              // Footer
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: Colors.grey.shade200, width: 1.0)),
                ),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(ctx),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade300, width: 1.5),
                      ),
                      child: Text('Tutup',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.grey.shade600)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value, Color color) {
    return Row(children: [
      Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withAlpha(80), width: 1.2),
        ),
        child: Icon(icon, size: 14, color: color),
      ),
      const SizedBox(width: 10),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: GoogleFonts.inter(fontSize: 10, color: Colors.grey.shade400, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
        Text(value, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w800, color: _kNavy)),
      ]),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showDetail(context),
      child: Container(
        decoration: _comicCard(bg: Colors.white, borderColor: _kTeal, shadowColor: _kTeal.withAlpha(80)),
        child: Column(
          children: [
            // Header strip
            Container(
              decoration: const BoxDecoration(
                color: _kTeal,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(13), topRight: Radius.circular(13)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white.withAlpha(60), width: 1),
                  ),
                  child: const Icon(LucideIcons.fileText, color: Colors.white, size: 14),
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(
                  materi['guru_nama'] != null ? '${materi['guru_nama']}' : 'Guru',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 12, color: Colors.white70),
                  maxLines: 1, overflow: TextOverflow.ellipsis)),
                if (materi['created_at'] != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(30),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(_formatDate(materi['created_at']),
                      style: GoogleFonts.inter(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w700)),
                  ),
              ]),
            ),
            // Body
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(materi['judul'] ?? '-',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 16, color: _kNavy, letterSpacing: -0.2),
                  maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 6),
                Container(height: 2, width: 32,
                  decoration: BoxDecoration(color: _kTeal, borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 8),
                if ((materi['deskripsi'] ?? '').isNotEmpty)
                  Text(materi['deskripsi'],
                    style: GoogleFonts.inter(height: 1.5, color: Colors.grey.shade500, fontWeight: FontWeight.w500, fontSize: 13),
                    maxLines: 2, overflow: TextOverflow.ellipsis),
                if (materi['file_url'] != null && materi['file_url'].toString().isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Row(children: [
                    const Icon(LucideIcons.paperclip, size: 12, color: _kTeal),
                    const SizedBox(width: 5),
                    Text('Ada lampiran file',
                      style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: _kTeal)),
                  ]),
                ],
              ]),
            ),
          ],
        ),
      ),
    );
  }
}
