import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../config/api_config.dart';
import '../../../widgets/app_shell.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';

class SiswaMateriView extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String token;
  final dynamic teamData; // TAMBAHAN: Menerima konteks kelas saat ini

  const SiswaMateriView({
    super.key, 
    required this.userData, 
    required this.token,
    required this.teamData, // Wajib diisi
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
      // UBAHAN: Fetch HANYA materi dari kelas ini berdasarkan ID-nya
      final kelasId = widget.teamData['id'];
      final response = await http.get(
        Uri.parse('$baseUrl/api/materi?kelas_id=$kelasId'), 
        headers: {'Authorization': 'Bearer ${widget.token}'}
      );
      
      if (response.statusCode == 200) {
        final dec = jsonDecode(response.body);
        List all = dec is List ? dec : [];
        setState(() {
          // UBAHAN: Tidak perlu difilter secara manual lagi, semua data yang masuk sudah pasti milik kelas ini
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
    if (_isLoading) {
      return _buildSkeleton();
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
            // ── Antigravity Search Bar ──────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: AppTextField(
                hintText: 'Cari materi pelajaran...',
                prefixIcon: Icons.search_rounded,
                onChanged: (val) => setState(() => _searchQuery = val),
              ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.2, curve: Curves.easeOutCubic),
            ),

            Expanded(
  child: _filtered.isEmpty
      ? EmptyState(
          icon: Icons.library_books_rounded,
          message: _searchQuery.isEmpty ? 'Belum ada materi\ndi kelas ini.' : 'Materi tidak ditemukan.',
          color: const Color(0xFF10B981))
      : RefreshIndicator(
          onRefresh: _fetchMateri,
          child: LayoutBuilder(
            builder: (ctx, c) {
              final w = c.maxWidth;
              final padding = Breakpoints.screenPadding(w);

              return ListView.builder(
                padding: padding,
                itemCount: _filtered.length,
                itemBuilder: (_, i) {
                  final m = _filtered[i];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _MateriCard(
                      materi: m,
                      isDark: Theme.of(context).brightness == Brightness.dark,
                    ).animate(delay: (i * 40).ms).fadeIn(duration: 400.ms).slideY(begin: 0.1, curve: Curves.easeOutQuart),
                  );
                },
              );
            },
          ),
        ),
),
      ],),);               
      }
              
  }

  Widget _buildSkeleton() {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(24),
          child: SkeletonLoader(height: 56, radius: 16),
        ),
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


class _MateriCard extends StatelessWidget {
  final dynamic materi;
  final bool isDark;

  const _MateriCard({required this.materi, required this.isDark});

  void _showDetail(BuildContext context) {
    const accent = Color(0xFF76AFB8);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const Icon(Icons.description_outlined, color: accent),
            const SizedBox(width: 12),
            Expanded(
              child: Text(materi['judul'] ?? '-',
                  style: const TextStyle(fontWeight: FontWeight.w900)),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (materi['mapel'] != null) ...[
                const Text('Mata Pelajaran',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                const SizedBox(height: 4),
                Text(materi['mapel'],
                    style: const TextStyle(fontSize: 14)),
                const SizedBox(height: 16),
              ],
              if (materi['deskripsi'] != null &&
                  materi['deskripsi'].toString().isNotEmpty) ...[
                const Text('Deskripsi',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                const SizedBox(height: 4),
                Text(materi['deskripsi'],
                    style: const TextStyle(fontSize: 14, height: 1.6)),
                const SizedBox(height: 16),
              ],
              if (materi['file_url'] != null &&
                  materi['file_url'].toString().isNotEmpty)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => _launchURL(materi['file_url']),
                    icon: const Icon(Icons.download_rounded, size: 18),
                    label: const Text('Buka File Materi',
                        style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF76AFB8);
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => _showDetail(context), // ← card bisa diklik
      child: PremiumCard(
        accentColor: accent,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: accent.withAlpha(20),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.description_outlined, color: accent, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(materi['mapel'] ?? '-',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800,
                          color: theme.colorScheme.onSurface.withAlpha(160), letterSpacing: 0.5),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(materi['judul'] ?? '-',
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: -0.3),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(materi['deskripsi'] ?? '-',
                style: TextStyle(fontSize: 12, height: 1.4,
                color: theme.colorScheme.onSurface.withAlpha(160)),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
                ],
                ),
                const SizedBox(height: 8),
                SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showDetail(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent.withAlpha(isDark ? 50 : 30),
                  foregroundColor: accent,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                icon: const Icon(Icons.open_in_new_rounded, size: 16),
                label: const Text('Lihat Detail',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
              ),
            ),
          ],
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



