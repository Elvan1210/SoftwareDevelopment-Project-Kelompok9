import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../config/api_config.dart';
import '../../../widgets/app_shell.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SiswaPengumumanView extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String token;
  const SiswaPengumumanView({super.key, required this.userData, required this.token});

  @override
  State<SiswaPengumumanView> createState() => _SiswaPengumumanViewState();
}

class _SiswaPengumumanViewState extends State<SiswaPengumumanView> {
  List<dynamic> _pengumumanList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPengumuman();
  }

  Future<void> _fetchPengumuman() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/pengumuman'), headers: {'Authorization': 'Bearer ${widget.token}'});
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        setState(() => _pengumumanList = decoded is List ? decoded : []);
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return AppShell(child: _buildSkeleton());
    }
    
    return AppShell(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: _pengumumanList.isEmpty
            ? const EmptyState(
                icon: Icons.campaign_rounded,
                message: 'Belum ada pengumuman masuk.',
                color: Color(0xFFF59E0B))
            : RefreshIndicator(
                onRefresh: _fetchPengumuman,
                child: LayoutBuilder(
                  builder: (ctx, c) {
                    final w = c.maxWidth;
                    final padding = Breakpoints.screenPadding(w);
                    
                    return ListView.builder(
                      padding: padding,
                      itemCount: _pengumumanList.length,
                      itemBuilder: (context, index) {
                        final p = _pengumumanList[index];
                        return _PengumumanCard(pengumuman: p)
                            .animate(delay: (index * 60).ms).fadeIn(duration: 400.ms).slideY(begin: 0.1, curve: Curves.easeOutQuart);
                      },
                    );
                  },
                ),
              ),
      ),
    );
  }

  Widget _buildSkeleton() {
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: 5,
      itemBuilder: (_, __) => const Padding(
        padding: EdgeInsets.only(bottom: 16),
        child: SkeletonLoader(height: 120, radius: 24),
      ),
    );
  }
}

class _PengumumanCard extends StatelessWidget {
  final Map<String, dynamic> pengumuman;
  const _PengumumanCard({required this.pengumuman});

  @override
  Widget build(BuildContext context) {
    const Color accent = Color(0xFFF59E0B);
    final theme = Theme.of(context);

    return PremiumCard(
      accentColor: accent,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: accent.withAlpha(20),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.campaign_rounded, color: accent, size: 24),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        pengumuman['judul'] ?? '-',
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: -0.5),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (pengumuman['tanggal'] != null)
                      Text(
                        pengumuman['tanggal'],
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface.withAlpha(120)),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  pengumuman['isi'] ?? '-',
                  style: TextStyle(fontSize: 14, height: 1.6, color: theme.colorScheme.onSurface.withAlpha(180)),
                ),
                if (pengumuman['author'] != null) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(Icons.person_pin_rounded, size: 14, color: theme.colorScheme.onSurface.withAlpha(100)),
                      const SizedBox(width: 6),
                      Text(
                        'Oleh: ${pengumuman['author']}',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: theme.colorScheme.onSurface.withAlpha(150)),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
