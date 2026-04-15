import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../config/api_config.dart';
import '../../../widgets/app_shell.dart';
import 'package:lucide_icons/lucide_icons.dart';

class AdminNilaiView extends StatefulWidget {
  final String token;
  const AdminNilaiView({super.key, required this.token});

  @override
  State<AdminNilaiView> createState() => _AdminNilaiViewState();
}

class _AdminNilaiViewState extends State<AdminNilaiView> {
  List<dynamic> _nilaiList = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchNilai();
  }

  Future<void> _fetchNilai() async {
    setState(() => _isLoading = true);
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/api/nilai'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      if (res.statusCode == 200) {
        final dec = jsonDecode(res.body);
        setState(() => _nilaiList = dec is List ? dec : []);
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  List<dynamic> get _filtered => _searchQuery.isEmpty
      ? _nilaiList
      : _nilaiList.where((n) =>
          (n['siswa_nama'] ?? '').toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (n['mapel'] ?? '').toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (n['guru_nama'] ?? '').toString().toLowerCase().contains(_searchQuery.toLowerCase())).toList();

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
                hintText: 'Cari siswa, mapel, atau guru...',
                prefixIcon: LucideIcons.search,
                onChanged: (val) => setState(() => _searchQuery = val),
              ).animate().fadeIn().slideY(begin: -0.1),
            ),

            Expanded(
              child: _filtered.isEmpty
                  ? EmptyState(icon: LucideIcons.award, message: 'Tidak ada data nilai.', color: Theme.of(context).primaryColor)
                  : RefreshIndicator(
                      onRefresh: _fetchNilai,
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
                              childAspectRatio: crossCount == 1 ? 2.0 : 1.6,
                            ),
                            itemCount: _filtered.length,
                            itemBuilder: (_, i) {
                              final n = _filtered[i];
                              return _AdminNilaiCard(
                                nilai: n,
                              ).animate(delay: (i * 40).ms).fadeIn(duration: 400.ms).slideY(begin: 0.1, curve: Curves.easeOutQuart);
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
            childAspectRatio: 1.6,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            children: List.generate(6, (_) => const SkeletonLoader(radius: 24)),
          ),
        ),
      ],
    );
  }
}

class _AdminNilaiCard extends StatelessWidget {
  final dynamic nilai;
  const _AdminNilaiCard({required this.nilai});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final val = double.tryParse(nilai['nilai'].toString()) ?? 0;
    final color = val >= 80 ? const Color(0xFF10B981) : (val >= 60 ? Colors.orange : Colors.red);

    return PremiumCard(
      accentColor: color,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withAlpha(20), shape: BoxShape.circle), child: Icon(LucideIcons.user, color: color, size: 16)),
              const SizedBox(width: 10),
              Expanded(child: Text(nilai['siswa_nama'] ?? '-', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis)),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(val.toStringAsFixed(0), style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: color, letterSpacing: -1)),
                  const Padding(padding: EdgeInsets.only(bottom: 5, left: 4), child: Text('pts', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.grey))),
                ],
              ),
              const SizedBox(height: 2),
              Text(nilai['mapel'] ?? '-', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
              Text('Guru: ${nilai['guru_nama'] ?? '-'}', style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurface.withAlpha(120))),
            ],
          ),
        ],
      ),
    );
  }
}

