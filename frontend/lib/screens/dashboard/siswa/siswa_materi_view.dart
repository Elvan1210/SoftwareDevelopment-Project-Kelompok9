import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../config/api_config.dart';
import '../../../widgets/app_shell.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import '../../../config/theme.dart';
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
          // Neo-brutalist Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border.all(color: Theme.of(context).colorScheme.onSurface, width: 2),
                boxShadow: [BoxShadow(color: Theme.of(context).colorScheme.onSurface, offset: const Offset(4, 4), blurRadius: 0)],
              ),
              child: TextField(
                onChanged: (val) => setState(() => _searchQuery = val),
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600,
                  color: Theme.of(context).textTheme.bodyLarge!.color!),
                decoration: InputDecoration(
                  hintText: 'Cari materi pelajaran...',
                  hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600,
                    color: Theme.of(context).textTheme.bodyMedium!.color!,
                  ),
                  prefixIcon: Icon(
                    LucideIcons.search,
                    size: 18,
                    color: Theme.of(context).textTheme.bodyMedium!.color!,
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
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 480),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border.all(color: Theme.of(context).colorScheme.onSurface, width: 2),
            boxShadow: [BoxShadow(color: Theme.of(context).colorScheme.onSurface, offset: const Offset(6, 6))],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  border: Border(
                    bottom: BorderSide(color: Theme.of(context).colorScheme.onSurface, width: 2),
                  ),
                ),
                child: Text(
                  materi['judul'] ?? '-',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.5),
                  maxLines: 2, overflow: TextOverflow.ellipsis,
                ),
              ),
              // Content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (materi['mapel'] != null) ...[
                        Text('MATA PELAJARAN', style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w900, color: Theme.of(context).textTheme.bodyMedium!.color!, letterSpacing: 1.0)),
                        const SizedBox(height: 4),
                        Text(materi['mapel'], style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600, color: Theme.of(context).textTheme.bodyLarge!.color!)),
                        const SizedBox(height: 16),
                      ],
                      if (materi['deskripsi'] != null && materi['deskripsi'].toString().isNotEmpty) ...[
                        Text('DESKRIPSI', style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w900, color: Theme.of(context).textTheme.bodyMedium!.color!, letterSpacing: 1.0)),
                        const SizedBox(height: 4),
                        Text(materi['deskripsi'], style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          height: 1.5, fontWeight: FontWeight.w500, color: Theme.of(context).textTheme.bodyLarge!.color!)),
                        const SizedBox(height: 20),
                      ],
                      if (materi['file_url'] != null && materi['file_url'].toString().isNotEmpty)
                        GestureDetector(
                          onTap: () => _launchURL(materi['file_url']),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: AppTheme.primary,
                              border: Border.all(color: Theme.of(context).colorScheme.onSurface, width: 1.5),
                              boxShadow: [BoxShadow(color: Theme.of(context).colorScheme.onSurface, offset: const Offset(3, 3), blurRadius: 0)],
                            ),
                            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                              const Icon(LucideIcons.downloadCloud, color: Colors.white, size: 16),
                              const SizedBox(width: 8),
                              Text('BUKA FILE MATERI', style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.5)),
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
                  border: Border(top: BorderSide(color: Theme.of(context).colorScheme.onSurface, width: 2)),
                ),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(ctx),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Theme.of(context).colorScheme.onSurface, width: 1.5),
                        boxShadow: [BoxShadow(color: Theme.of(context).colorScheme.onSurface, offset: const Offset(2, 2))],
                      ),
                      child: Text('TUTUP', style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w900, color: Theme.of(context).textTheme.bodyLarge!.color!)),
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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showDetail(context),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border.all(color: Theme.of(context).colorScheme.onSurface, width: 2),
          boxShadow: [BoxShadow(color: Theme.of(context).colorScheme.onSurface, offset: const Offset(4, 4), blurRadius: 0)],
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
                    color: AppTheme.primary,
                    border: Border.all(color: Theme.of(context).colorScheme.onSurface, width: 1.5),
                    boxShadow: [BoxShadow(color: Theme.of(context).colorScheme.onSurface, offset: const Offset(2, 2), blurRadius: 0)],
                  ),
                  child: const Icon(LucideIcons.fileText, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    materi['mapel'] ?? '-',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900,
                      color: Theme.of(context).textTheme.bodyMedium!.color!,
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
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900,
                color: Theme.of(context).textTheme.bodyLarge!.color!,
                letterSpacing: -0.3),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Text(
              materi['deskripsi'] ?? '-',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.4,
                color: Theme.of(context).textTheme.bodyMedium!.color!,
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
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  side: BorderSide(color: Theme.of(context).colorScheme.onSurface, width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                ),
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
