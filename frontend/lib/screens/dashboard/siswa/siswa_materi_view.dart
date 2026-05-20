import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../config/api_config.dart';
import '../../../widgets/app_shell.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import '../../../config/theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

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
        setState(() {
          _materiList = all; 
        });
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return _buildSkeleton();
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          // Glassmorphic Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E2538) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? const Color(0xFF252D3D) : const Color(0xFFE5E7EB),
                  width: 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(isDark ? 40 : 5),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                onChanged: (val) => setState(() => _searchQuery = val),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : AppTheme.textLight,
                ),
                decoration: InputDecoration(
                  hintText: 'Cari materi pelajaran...',
                  hintStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt,
                  ),
                  prefixIcon: Icon(
                    LucideIcons.search,
                    size: 18,
                    color: isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.2, curve: Curves.easeOutCubic),

          Expanded(
            child: _filtered.isEmpty
                ? EmptyState(
                    icon: LucideIcons.bookOpen,
                    message: _searchQuery.isEmpty ? 'Belum ada materi\ndi kelas ini.' : 'Materi tidak ditemukan.',
                    color: AppTheme.indigoPrimary,
                  )
                : RefreshIndicator(
                    onRefresh: _fetchMateri,
                    color: AppTheme.indigoPrimary,
                    child: LayoutBuilder(
                      builder: (ctx, c) {
                        final w = c.maxWidth;
                        final padding = Breakpoints.screenPadding(w);

                        return ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          padding: padding,
                          itemCount: _filtered.length,
                          itemBuilder: (_, i) {
                            final m = _filtered[i];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: _MateriCard(
                                materi: m,
                                isDark: isDark,
                              ).animate(delay: (i * 40).ms).fadeIn(duration: 400.ms).slideY(begin: 0.1, curve: Curves.easeOutQuart),
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

  Widget _buildSkeleton() {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: SkeletonLoader(height: 54, radius: 16),
        ),
        Expanded(
          child: GridView.count(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            crossAxisCount: 2,
            childAspectRatio: 1.3,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            children: List.generate(6, (_) => const SkeletonLoader(radius: 20)),
          ),
        ),
      ],
    );
  }
}

class _MateriCard extends StatelessWidget {
  final dynamic materi;
  final bool isDark;

  const _MateriCard({required this.materi, required this.isDark});

  void _showDetail(BuildContext context) {
    const accent = Color(0xFF76AFB8);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF161B27) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: isDark ? const Color(0xFF252D3D) : const Color(0xFFE5E7EB), width: 1.2),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: accent.withAlpha(20),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(LucideIcons.fileText, color: accent, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                materi['judul'] ?? '-',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  color: isDark ? Colors.white : AppTheme.textLight,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (materi['mapel'] != null) ...[
                Text(
                  'Mata Pelajaran',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                    color: isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  materi['mapel'],
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : AppTheme.textLight,
                  ),
                ),
                const SizedBox(height: 16),
              ],
              if (materi['deskripsi'] != null && materi['deskripsi'].toString().isNotEmpty) ...[
                Text(
                  'Deskripsi',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                    color: isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  materi['deskripsi'],
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white70 : AppTheme.textLight,
                  ),
                ),
                const SizedBox(height: 20),
              ],
              if (materi['file_url'] != null && materi['file_url'].toString().isNotEmpty)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _launchURL(materi['file_url']),
                    icon: const Icon(LucideIcons.downloadCloud, size: 16),
                    label: Text(
                      'Buka File Materi',
                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Tutup',
              style: GoogleFonts.plusJakartaSans(
                color: isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF76AFB8);

    return GestureDetector(
      onTap: () => _showDetail(context),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E2538) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: accent.withAlpha(isDark ? 55 : 30),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(isDark ? 60 : 8),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF161D2B) : const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(19),
              border: Border.all(
                color: isDark ? const Color(0xFF2D3A54) : const Color(0xFFE5E7EB),
                width: 1.0,
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: accent.withAlpha(20),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(LucideIcons.fileText, color: accent, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        materi['mapel'] ?? '-',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt,
                          letterSpacing: 0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  materi['judul'] ?? '-',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w900,
                    fontSize: 14.5,
                    color: isDark ? Colors.white : AppTheme.textLight,
                    letterSpacing: -0.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  materi['deskripsi'] ?? '-',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    height: 1.4,
                    color: isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _showDetail(context),
                    icon: const Icon(LucideIcons.eye, size: 14),
                    label: const Text(
                      'Lihat Detail',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                    ),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: isDark ? const Color(0xFF1B3539) : const Color(0xFFE6F5F7),
                      foregroundColor: accent,
                      side: BorderSide(
                        color: isDark ? const Color(0xFF28565C) : const Color(0xFF9AD5DE),
                        width: 1.0,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _launchURL(String? url) async {
    if (url == null || url.isEmpty) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
