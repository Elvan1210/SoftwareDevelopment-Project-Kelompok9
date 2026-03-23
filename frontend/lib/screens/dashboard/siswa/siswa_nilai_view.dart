import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../config/api_config.dart';
import '../../../widgets/app_shell.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SiswaNilaiView extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String token;
  const SiswaNilaiView({super.key, required this.userData, required this.token});

  @override
  State<SiswaNilaiView> createState() => _SiswaNilaiViewState();
}

class _SiswaNilaiViewState extends State<SiswaNilaiView> {
  List<dynamic> _nilaiList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchNilai();
  }

  Future<void> _fetchNilai() async {
    setState(() => _isLoading = true);
    try {
      final sid = Uri.encodeComponent(widget.userData['id'].toString());
      final response = await http.get(
          Uri.parse('$baseUrl/api/nilai?siswa_id=$sid'),
          headers: {'Authorization': 'Bearer ${widget.token}'});
      if (response.statusCode == 200) {
        final dec = jsonDecode(response.body);
        setState(() {
          _nilaiList = dec is List ? dec : [];
        });
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Color _gradeColor(dynamic nilai) {
    final v = double.tryParse(nilai.toString()) ?? 0;
    if (v >= 80) return const Color(0xFF10B981);
    if (v >= 60) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return AppShell(
        child: _buildSkeleton(),
      );
    }

    return AppShell(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: _nilaiList.isEmpty
            ? const EmptyState(
                icon: Icons.workspace_premium_rounded,
                message: 'Belum ada nilai\nyang diinput guru.',
                color: Color(0xFF3B82F6))
            : RefreshIndicator(
                onRefresh: _fetchNilai,
                child: LayoutBuilder(
                  builder: (ctx, c) {
                    final crossCount = c.maxWidth > 900 ? 3 : (c.maxWidth > 500 ? 2 : 1);
                    final padding = Breakpoints.screenPadding(c.maxWidth);
                    return GridView.builder(
                      padding: padding,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossCount,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: crossCount == 1 ? 3.5 : 1.8,
                      ),
                      itemCount: _nilaiList.length,
                      itemBuilder: (_, i) {
                        final n = _nilaiList[i];
                        final color = _gradeColor(n['nilai']);
                        return RepaintBoundary(
                          child: PremiumCard(
                            accentColor: color,
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(color: color.withAlpha(20), borderRadius: BorderRadius.circular(10)),
                                      child: Icon(Icons.grade_rounded, color: color, size: 20),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(n['mapel'] ?? '-',
                                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(n['nilai']?.toString() ?? '-',
                                        style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: color, letterSpacing: -1)),
                                    if (n['keterangan'] != null && n['keterangan'].toString().isNotEmpty)
                                      Text(n['keterangan'],
                                          style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withAlpha(150)),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis),
                                  ],
                                ),
                              ],
                            ),
                          ).animate(delay: (i * 60).ms).fadeIn(duration: 400.ms).slideY(begin: 0.1, curve: Curves.easeOutQuart),
                        );
                      },
                    );
                  },
                ),
              ),
      ),
    );
  }

  Widget _buildSkeleton() {
    return GridView.count(
      padding: const EdgeInsets.all(24),
      crossAxisCount: 2,
      childAspectRatio: 1.8,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: List.generate(6, (_) => const SkeletonLoader(radius: 24)),
    );
  }
}
