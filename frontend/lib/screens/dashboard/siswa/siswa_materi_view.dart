import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../config/api_config.dart';
import '../../../widgets/app_shell.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';

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
const Color _surfaceContainerLowest = Color(0xFFFFFFFF);
const Color _surfaceContainerHighest = Color(0xFFC1E8FF);
const Color _outlineVariant = Color(0xFFC1C8C2);
const Color _primaryFixed = Color(0xFFBFEDD5);
const Color _onPrimaryFixed = Color(0xFF002115);

BorderRadius get _asymmetricRadius => const BorderRadius.only(
      topLeft: Radius.circular(4),
      topRight: Radius.circular(16),
      bottomRight: Radius.circular(4),
      bottomLeft: Radius.circular(16),
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
      final text = ("${m['judul']} ${m['deskripsi']}").toLowerCase();
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
          // -- Neo Search Bar -------------------------------------------
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: _onSurface, width: 2),
                boxShadow: const [
                  BoxShadow(color: _onSurface, offset: Offset(4, 4), blurRadius: 0),
                ],
              ),
              child: TextField(
                onChanged: (val) => setState(() => _searchQuery = val),
                style: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 16, color: _onSurface),
                decoration: InputDecoration(
                  hintText: 'Cari materi...',
                  hintStyle: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 16, color: _onSurfaceVariant),
                  prefixIcon: const Icon(LucideIcons.search, size: 20, color: _onSurface),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
              ),
            ),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1, curve: Curves.easeOutCubic),

          Expanded(
            child: _filtered.isEmpty
                ? _buildEmpty()
                : RefreshIndicator(
                    onRefresh: _fetchMateri,
                    color: _primary,
                    child: LayoutBuilder(
                      builder: (ctx, c) {
                        final w = c.maxWidth;
                        final padding = Breakpoints.screenPadding(w);
                        return ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          padding: EdgeInsets.only(
                            left: padding.left > 16 ? padding.left : 16,
                            right: padding.right > 16 ? padding.right : 16,
                            top: 16,
                            bottom: 100,
                          ),
                          itemCount: _filtered.length + 1, // +1 for the header
                          itemBuilder: (_, i) {
                            if (i == 0) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 24),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                      margin: const EdgeInsets.only(bottom: 8),
                                      decoration: BoxDecoration(
                                        color: _tertiaryContainer,
                                        borderRadius: _asymmetricRadius,
                                        border: Border.all(color: _onSurface, width: 2),
                                        boxShadow: const [BoxShadow(color: _onSurface, offset: Offset(2, 2))],
                                      ),
                                      child: Text(
                                        'DAFTAR MATERI',
                                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: _onTertiaryContainer, letterSpacing: 1.2),
                                      ),
                                    ),
                                    Text(
                                      'Materi Pembelajaran',
                                      style: GoogleFonts.plusJakartaSans(fontSize: 28, fontWeight: FontWeight.w800, color: _onSurface, height: 1.2),
                                    ),
                                  ],
                                ),
                              ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.1);
                            }

                            final m = _filtered[i - 1];
                            final colorsList = [
                              {'bg': _secondaryContainer, 'text': _onSecondaryContainer},
                              {'bg': _tertiaryContainer, 'text': _onTertiaryContainer},
                              {'bg': _primaryFixed, 'text': _onPrimaryFixed},
                              {'bg': _surfaceContainerHighest, 'text': _onSurface},
                            ];
                            final colorPair = colorsList[(i - 1) % colorsList.length];

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 24),
                              child: _MateriCardNeo(
                                materi: m,
                                profileBgColor: colorPair['bg']!,
                                profileTextColor: colorPair['text']!,
                              )
                                  .animate(delay: ((i - 1) * 50).ms)
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
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: _asymmetricRadius,
          border: Border.all(color: _onSurface, width: 2),
          boxShadow: const [BoxShadow(color: _onSurface, offset: Offset(4, 4), blurRadius: 0)],
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _surfaceContainerHighest,
              shape: BoxShape.circle,
              border: Border.all(color: _onSurface, width: 2),
            ),
            child: const Icon(LucideIcons.bookOpen, color: _onSurface, size: 28),
          ),
          const SizedBox(height: 14),
          Text(
            isEmpty ? 'Belum ada materi\ndi kelas ini.' : 'Materi tidak ditemukan.',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 18, color: _onSurface),
          ),
          const SizedBox(height: 6),
          Text(
            isEmpty ? 'Tunggu guru menambahkan materi.' : 'Coba kata kunci lain.',
            style: GoogleFonts.inter(fontSize: 14, color: _onSurfaceVariant, fontWeight: FontWeight.w500),
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
          child: SkeletonLoader(height: 52, radius: 4),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: 5,
            itemBuilder: (_, __) => const Padding(
              padding: EdgeInsets.only(bottom: 24),
              child: SkeletonLoader(height: 180, radius: 16),
            ),
          ),
        ),
      ],
    );
  }
}

class _MateriCardNeo extends StatefulWidget {
  final dynamic materi;
  final Color profileBgColor;
  final Color profileTextColor;

  const _MateriCardNeo({
    required this.materi,
    required this.profileBgColor,
    required this.profileTextColor,
  });

  @override
  State<_MateriCardNeo> createState() => _MateriCardNeoState();
}

class _MateriCardNeoState extends State<_MateriCardNeo> {
  bool _isHovering = false;

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
      barrierColor: _onSurface.withAlpha(51), // 20% opacity backdrop
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 512), // max-w-lg
          padding: const EdgeInsets.all(32), // p-8
          decoration: BoxDecoration(
            color: _surfaceContainerLowest,
            borderRadius: _asymmetricRadius,
            border: Border.all(color: _onSurface, width: 2),
            boxShadow: const [BoxShadow(color: _onSurface, offset: Offset(4, 4), blurRadius: 0)],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Section
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: _secondaryContainer,
                          borderRadius: _asymmetricRadius,
                          border: Border.all(color: _onSurface, width: 2),
                          boxShadow: const [BoxShadow(color: _onSurface, offset: Offset(2, 2))],
                        ),
                        child: Text(
                          'DETAIL MATERI',
                          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: _onSecondaryContainer, letterSpacing: 1.2),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.materi['judul'] ?? '-',
                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 32, color: _onSurface, height: 1.2, letterSpacing: -0.5),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Content Section
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (widget.materi['deskripsi'] != null && widget.materi['deskripsi'].toString().isNotEmpty) ...[
                            Text(
                              'DESKRIPSI LENGKAP',
                              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: _primary, letterSpacing: 0.5),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              widget.materi['deskripsi'],
                              style: GoogleFonts.inter(height: 1.6, fontWeight: FontWeight.w400, fontSize: 16, color: _onSurfaceVariant),
                            ),
                            const SizedBox(height: 16),
                          ],
                          
                          if (widget.materi['file_url'] != null && widget.materi['file_url'].toString().isNotEmpty) ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.only(top: 16),
                              decoration: const BoxDecoration(
                                border: Border(top: BorderSide(color: _outlineVariant)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'LINK MATERI',
                                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: _primary, letterSpacing: 0.5),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      GestureDetector(
                                        onTap: () => _launchURL(widget.materi['file_url']),
                                        child: const _NeoModalButton(
                                          label: 'Buka',
                                          icon: Icons.open_in_new,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              
              // Close Icon
              Positioned(
                top: -16,
                right: -16,
                child: IconButton(
                  icon: const Icon(Icons.close, color: _onSurface, size: 28),
                  onPressed: () => Navigator.pop(ctx),
                  splashRadius: 24,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getInitials(String name) {
    List<String> names = name.trim().split(' ');
    if (names.isEmpty) return '??';
    if (names.length == 1) return names[0].substring(0, names[0].length >= 2 ? 2 : 1).toUpperCase();
    return '${names[0][0]}${names[names.length - 1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final guruNama = widget.materi['guru_nama'] ?? 'Guru Tidak Diketahui';
    final initials = _getInitials(guruNama);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        onTap: () => _showDetail(context),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          transform: Matrix4.translationValues(
            _isHovering ? -2 : 0,
            _isHovering ? -2 : 0,
            0,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: _asymmetricRadius,
            border: Border.all(color: _onSurface, width: 2),
            boxShadow: [
              BoxShadow(
                color: _onSurface,
                offset: _isHovering ? const Offset(6, 6) : const Offset(4, 4),
              )
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.materi['judul'] ?? '-',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                    color: _onSurface,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                if ((widget.materi['deskripsi'] ?? '').isNotEmpty)
                  Text(
                    widget.materi['deskripsi'],
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: _onSurfaceVariant,
                      height: 1.5,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.only(top: 16),
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: _outlineVariant)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: widget.profileBgColor,
                                shape: BoxShape.circle,
                                border: Border.all(color: _onSurface, width: 1.5),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                initials,
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                  color: widget.profileTextColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Guru: $guruNama',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: _onSurface,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: _primaryContainer,
                          border: Border.all(color: _onSurface, width: 2),
                          boxShadow: const [BoxShadow(color: _onSurface, offset: Offset(2, 2))],
                        ),
                        child: Text(
                          'Lihat Detail',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _onPrimaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NeoModalButton extends StatefulWidget {
  final String label;
  final IconData icon;

  const _NeoModalButton({required this.label, required this.icon});

  @override
  State<_NeoModalButton> createState() => _NeoModalButtonState();
}

class _NeoModalButtonState extends State<_NeoModalButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        transform: Matrix4.translationValues(
          _isPressed ? 2 : 0,
          _isPressed ? 2 : 0,
          0,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: _primaryContainer,
          border: Border.all(color: _onSurface, width: 2),
          boxShadow: _isPressed ? [] : const [BoxShadow(color: _onSurface, offset: Offset(2, 2))],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(widget.icon, color: _onSurface, size: 20),
            const SizedBox(width: 8),
            Text(
              widget.label,
              style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 12, color: _onPrimaryContainer),
            ),
          ],
        ),
      ),
    );
  }
}
