import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../widgets/confirm_delete.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../config/api_config.dart';
import '../../../widgets/app_shell.dart';
import 'package:url_launcher/url_launcher.dart';

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
          (m['guru_nama'] ?? '').toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (m['mapel'] ?? '').toString().toLowerCase().contains(_searchQuery.toLowerCase())).toList();

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
              child: AppTextField(
                hintText: 'Cari materi, guru, atau mapel...',
                prefixIcon: Icons.search_rounded,
                onChanged: (val) => setState(() => _searchQuery = val),
              ).animate().fadeIn().slideY(begin: -0.1),
            ),

            Expanded(
              child: _filtered.isEmpty
                  ? const EmptyState(icon: Icons.library_books_rounded, message: 'Tidak ada materi ditemukan.', color: Colors.teal)
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
    const accent = Colors.teal;
    final theme = Theme.of(context);

    return PremiumCard(
      accentColor: accent,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: accent.withAlpha(20), shape: BoxShape.circle), child: const Icon(Icons.school_rounded, color: accent, size: 20)),
              const SizedBox(width: 12),
              Expanded(child: Text(materi['mapel'] ?? '-', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis)),
              IconButton(onPressed: onDelete, icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20)),
            ],
          ),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Text(materi['judul'] ?? '-', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: -0.3), maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text('Oleh: ${materi['guru_nama'] ?? '-'}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: theme.colorScheme.onSurface.withAlpha(150)), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text('Kelas: ${materi['kelas'] ?? 'Semua'}', style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withAlpha(120)), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _launchURL(materi['file_url'] ?? materi['link']),
              style: OutlinedButton.styleFrom(foregroundColor: accent, side: BorderSide(color: accent.withAlpha(80)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              icon: const Icon(Icons.open_in_new_rounded, size: 16),
              label: const Text('Buka', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _launchURL(String? url) async {
    if (url == null || url.isEmpty) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }
}

