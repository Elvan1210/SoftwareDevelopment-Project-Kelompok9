
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../widgets/confirm_delete.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../config/api_config.dart';
import '../../../widgets/app_shell.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminMateriView extends StatefulWidget {
  final String token;
  const AdminMateriView({super.key, required this.token});

  @override
  State<AdminMateriView> createState() => _AdminMateriViewState();
}

class _AdminMateriViewState extends State<AdminMateriView> {
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
      final res = await http.get(
        Uri.parse('$baseUrl/api/materi'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      if (res.statusCode == 200) {
        final dec = jsonDecode(res.body);
        setState(() => _materiList = dec is List ? dec : []);
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _deleteMateri(String id) async {
    if (await confirmDelete(context, pesan: 'Hapus materi ini secara permanen?')) {
      try {
        await http.delete(Uri.parse('$baseUrl/api/materi/$id'), headers: {'Authorization': 'Bearer ${widget.token}'});
        _fetchMateri();
      } catch (e) {
        debugPrint('Error: $e');
      }
    }
  }

  List<dynamic> get _filtered => _searchQuery.isEmpty
      ? _materiList
      : _materiList.where((m) =>
          (m['judul'] ?? '').toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (m['guru_nama'] ?? '').toString().toLowerCase().contains(_searchQuery.toLowerCase())).toList();

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildSkeleton();
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
        body: Column(
          children: [
            // ── Admin Explorer Header ──────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.black, width: 2),
                  boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(4, 4))],
                ),
                child: TextField(
                  onChanged: (val) => setState(() => _searchQuery = val),
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.black),
                  decoration: InputDecoration(
                    hintText: 'Cari materi atau guru...',
                    hintStyle: GoogleFonts.inter(color: Colors.black54, fontWeight: FontWeight.w600),
                    prefixIcon: const Icon(LucideIcons.search, color: Colors.black),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                ),
              ).animate().fadeIn().slideY(begin: -0.1),
            ),

            Expanded(
              child: _filtered.isEmpty
                  ? EmptyState(icon: LucideIcons.bookOpen, message: 'Tidak ada materi ditemukan.', color: Theme.of(context).primaryColor)
                  : RefreshIndicator(
                      onRefresh: _fetchMateri,
                      child: LayoutBuilder(
                        builder: (ctx, c) {
                          final w = c.maxWidth;
                          final padding = Breakpoints.screenPadding(w);
                          final crossCount = w >= Breakpoints.tablet ? 3 : (w >= Breakpoints.mobile ? 2 : 1);

                          return GridView.builder(
                            padding: padding,
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossCount,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: crossCount == 1 ? 2.0 : 1.4,
                            ),
                            itemCount: _filtered.length,
                            itemBuilder: (_, i) {
                              final m = _filtered[i];
                                return _AdminMateriCard(
                                  materi: m,
                                  onDelete: () => _deleteMateri(m['id'].toString()),
                                ).animate(delay: (i * 40).ms).fadeIn(duration: 400.ms).scale(begin: const Offset(0.95, 0.95), curve: Curves.easeOutBack).slideY(begin: 0.1, curve: Curves.easeOutQuart);
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
        const Padding(padding: EdgeInsets.all(24), child: SkeletonLoader(height: 56, radius: 16)),
        Expanded(
          child: GridView.count(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            crossAxisCount: 2,
            childAspectRatio: 1.4,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            children: List.generate(6, (_) => const SkeletonLoader(radius: 24)),
          ),
        ),
      ],
    );
  }
}

class _AdminMateriCard extends StatelessWidget {
  final dynamic materi;
  final VoidCallback onDelete;

  const _AdminMateriCard({required this.materi, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black, width: 2),
        boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(4, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFC1E8FF), // Pastel blue
                  border: Border.all(color: Colors.black, width: 1.5),
                  boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(2, 2))],
                ),
                child: const Icon(LucideIcons.graduationCap, color: Colors.black, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Materi',
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 13, color: Colors.black),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              GestureDetector(
                onTap: onDelete,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444), // Red
                    border: Border.all(color: Colors.black, width: 1.5),
                    boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(2, 2))],
                  ),
                  child: const Icon(LucideIcons.trash, color: Colors.white, size: 16),
                ),
              ),
            ],
          ),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                Text(
                  materi['judul'] ?? '-',
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: -0.5, color: Colors.black),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  'Oleh: ${materi['guru_nama'] ?? '-'}',
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.black87),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: GestureDetector(
              onTap: () => _launchURL(materi['file_url'] ?? materi['link']),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFB7E5CD), // Pastel green
                  border: Border.all(color: Colors.black, width: 2),
                  boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(3, 3))],
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(LucideIcons.externalLink, color: Colors.black, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Buka Materi',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 13, color: Colors.black, letterSpacing: 0.5),
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

  Future<void> _launchURL(String? url) async {
    if (url == null || url.isEmpty) return;
    
    String finalUrl = url;
    if (url.startsWith('/')) {
      finalUrl = '$baseUrl$url';
    } else if (url.startsWith('http://')) {
      finalUrl = url.replaceFirst('http://', 'https://');
    } else if (!url.startsWith('https://')) {
      finalUrl = 'https://$url';
    }
    
    final uri = Uri.parse(finalUrl);
    try {
      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
        webOnlyWindowName: '_blank',
      );
    } catch (_) {}
  }
}
