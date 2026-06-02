import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../config/api_config.dart';
import '../../../widgets/app_shell.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'siswa_tugas_detail_screen.dart';

// --- Tailwind Neo-Brutalist Tokens -----------------------------------------
const Color _onSurface = Color(0xFF001E2B);
const Color _onSurfaceVariant = Color(0xFF414944);
const Color _primary = Color(0xFF3D6754);
const Color _primaryContainer = Color(0xFFB7E5CD);
const Color _onPrimaryContainer = Color(0xFF3E6855);
const Color _secondaryContainer = Color(0xFFB7EDE7);
const Color _onSecondaryContainer = Color(0xFF3A6D69);
const Color _tertiaryContainer = Color(0xFFFFD1C0);
const Color _onTertiaryContainer = Color(0xFF8E4F34);
const Color _surfaceContainerHighest = Color(0xFFC1E8FF);
const Color _surface = Color(0xFFF4FAFF);
const Color _onBackground = Color(0xFF001E2B);

class SiswaTugasView extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String token;
  final dynamic teamData; 
  final bool isGlobal; 

  const SiswaTugasView({
    super.key,
    required this.userData,
    required this.token,
    this.teamData,
    this.isGlobal = false,
  });

  @override
  State<SiswaTugasView> createState() => _SiswaTugasViewState();
}

class _SiswaTugasViewState extends State<SiswaTugasView> {
  List<dynamic> _tugasList = [];
  bool _isLoading = true;
  String _selectedFilter = 'Semua';

  final List<String> _filters = ['Semua', 'Belum', 'Selesai'];

  @override
  void initState() {
    super.initState();
    _fetchTugas();
  }

  Future<void> _fetchTugas() async {
    setState(() => _isLoading = true);
    try {
      String url = '$baseUrl/api/tugas';
      if (!widget.isGlobal && widget.teamData != null) {
        url += '?kelas_id=${widget.teamData['id']}';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      if (response.statusCode == 200) {
        final dec = jsonDecode(response.body);
        List all = dec is List ? dec : [];
        setState(() => _tugasList = all);
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  List<dynamic> get _filtered {
    return _tugasList.where((t) {
      final isDone = t['sudah_kumpul'] == true || t['status'] == 'selesai';
      if (_selectedFilter == 'Semua') return true;
      if (_selectedFilter == 'Belum') return !isDone;
      if (_selectedFilter == 'Selesai') return isDone;
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return _buildSkeleton();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: LayoutBuilder(
        builder: (ctx, constraints) {
          final isDesktop = constraints.maxWidth >= 768;

          return RefreshIndicator(
            onRefresh: _fetchTugas,
            color: _primary,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.only(
                left: isDesktop ? 40 : 16,
                right: isDesktop ? 40 : 16,
                top: 32,
                bottom: 100,
              ),
              children: [
                // -- Headline -------------------------------------------
                Padding(
                  padding: const EdgeInsets.only(bottom: 32),
                  child: Text(
                    'Daftar Tugas',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: isDesktop ? 48 : 36,
                      fontWeight: FontWeight.w800,
                      color: _onBackground,
                      letterSpacing: -1.92,
                      height: 1.1,
                    ),
                  ),
                ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1),

                // -- Filter Tabs ----------------------------------------------
                Padding(
                  padding: const EdgeInsets.only(bottom: 40),
                  child: _buildFilterTabs(),
                ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.05),

                // -- Assignment Grid -------------------------------------------
                if (_filtered.isEmpty)
                  _buildEmpty()
                else
                  _buildGrid(isDesktop),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterTabs() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: _filters.map((f) {
          final isSelected = _selectedFilter == f;
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => setState(() => _selectedFilter = f),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                transform: Matrix4.translationValues(
                  isSelected ? 2 : 0,
                  isSelected ? 2 : 0,
                  0,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? _primary : _surface,
                  borderRadius: BorderRadius.circular(9999),
                  border: Border.all(color: _onSurface, width: 2),
                  boxShadow: isSelected ? [] : const [BoxShadow(color: _onSurface, offset: Offset(2, 2))],
                ),
                child: Text(
                  f.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    letterSpacing: 0.6,
                    color: isSelected ? Colors.white : _onSurface,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildGrid(bool isDesktop) {
    if (!isDesktop) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: List.generate(_filtered.length, (i) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: _TaskCardNeo(
              tugas: _filtered[i],
              index: i,
              onTap: () => _openDetail(_filtered[i]),
            ),
          );
        }),
      );
    } else {
      List<Widget> rows = [];
      for (int i = 0; i < _filtered.length; i += 2) {
        Widget left = Expanded(
          child: _TaskCardNeo(
            tugas: _filtered[i],
            index: i,
            onTap: () => _openDetail(_filtered[i]),
          ),
        );
        Widget right = (i + 1 < _filtered.length)
            ? Expanded(
                child: _TaskCardNeo(
                  tugas: _filtered[i + 1],
                  index: i + 1,
                  onTap: () => _openDetail(_filtered[i + 1]),
                ),
              )
            : const Expanded(child: SizedBox());
        
        rows.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [left, const SizedBox(width: 24), right],
              ),
            ),
          ),
        );
      }
      return Column(children: rows);
    }
  }

  void _openDetail(dynamic tugas) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SiswaTugasDetailScreen(
          tugas: tugas,
          token: widget.token,
          userData: widget.userData,
        ),
      ),
    ).then((_) => _fetchTugas());
  }

  Widget _buildEmpty() {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _onSurface, width: 2),
          boxShadow: const [BoxShadow(color: _onSurface, offset: Offset(4, 4))],
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _surfaceContainerHighest,
              shape: BoxShape.circle,
              border: Border.all(color: _onSurface, width: 2),
            ),
            child: const Icon(LucideIcons.fileQuestion, color: _onSurface, size: 32),
          ),
          const SizedBox(height: 20),
          Text(
            'Belum ada tugas.',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 24, color: _onSurface),
          ),
          const SizedBox(height: 8),
          Text(
            'Hore! Kamu tidak punya tugas yang\nharus dikerjakan saat ini.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 16, color: _onSurfaceVariant, fontWeight: FontWeight.w400),
          ),
        ]),
      ),
    );
  }

  Widget _buildSkeleton() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SkeletonLoader(height: 60, width: 200),
          const SizedBox(height: 40),
          const Row(
            children: [
              SkeletonLoader(height: 40, width: 100, radius: 20),
              SizedBox(width: 12),
              SkeletonLoader(height: 40, width: 100, radius: 20),
            ],
          ),
          const SizedBox(height: 40),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 24,
              crossAxisSpacing: 24,
              childAspectRatio: 2,
              children: List.generate(4, (_) => const SkeletonLoader(height: 160, radius: 12)),
            ),
          ),
        ],
      ),
    );
  }
}

// -- Task Card Neo -----------------------------------------------------------
class _TaskCardNeo extends StatefulWidget {
  final dynamic tugas;
  final int index;
  final VoidCallback onTap;

  const _TaskCardNeo({required this.tugas, required this.index, required this.onTap});

  @override
  State<_TaskCardNeo> createState() => _TaskCardNeoState();
}

class _TaskCardNeoState extends State<_TaskCardNeo> {
  bool _isPressed = false;

  String _formatDate(String? iso) {
    if (iso == null || iso.isEmpty) return 'Tanpa Tenggat';
    try {
      return DateFormat('dd MMM yyyy, HH:mm').format(DateTime.parse(iso));
    } catch (_) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgColors = [
      _primaryContainer,
      _secondaryContainer,
      _tertiaryContainer,
      _surfaceContainerHighest
    ];
    final fgColors = [
      _onPrimaryContainer,
      _onSecondaryContainer,
      _onTertiaryContainer,
      _onSurfaceVariant
    ];

    final colorIdx = widget.index % bgColors.length;
    final bgColor = bgColors[colorIdx];
    final fgColor = fgColors[colorIdx];

    final isDone = widget.tugas['sudah_kumpul'] == true || widget.tugas['status'] == 'selesai';
    final hasDeadline = widget.tugas['tenggat_waktu'] != null && widget.tugas['tenggat_waktu'].toString().isNotEmpty;

    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(
          _isPressed ? 2 : 0,
          _isPressed ? 2 : 0,
          0,
        ),
        constraints: const BoxConstraints(minHeight: 160),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _onSurface, width: 2),
          boxShadow: _isPressed 
              ? const [BoxShadow(color: _onSurface, offset: Offset(2, 2))]
              : const [BoxShadow(color: _onSurface, offset: Offset(4, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (widget.tugas['kategori'] ?? 'UMUM').toString().toUpperCase(),
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                    letterSpacing: 1.2,
                    color: fgColor.withAlpha(178),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.tugas['judul'] ?? 'Tugas',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w600,
                    fontSize: 20,
                    height: 1.2,
                    color: _onBackground,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (isDone)
              Row(
                children: [
                  const Icon(Icons.check_circle, color: _primary, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    'Sudah Dikumpulkan',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14, color: _onBackground),
                  ),
                ],
              )
            else if (!hasDeadline)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: _surface.withAlpha(128),
                  borderRadius: BorderRadius.circular(9999),
                  border: Border.all(color: _onBackground.withAlpha(51), width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.info_outline, size: 14, color: _onBackground),
                    const SizedBox(width: 4),
                    Text(
                      'Tanpa Tenggat',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 11, color: _onBackground),
                    ),
                  ],
                ),
              )
            else
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 18, color: _onBackground),
                  const SizedBox(width: 8),
                  Text(
                    _formatDate(widget.tugas['tenggat_waktu']),
                    style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14, color: _onBackground),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
