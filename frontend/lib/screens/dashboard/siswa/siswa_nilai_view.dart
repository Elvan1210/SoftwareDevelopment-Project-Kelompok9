import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../widgets/app_shell.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../config/api_config.dart';
import '../../../config/theme.dart';




class SiswaNilaiView extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String token;
  final dynamic teamData;
  const SiswaNilaiView({super.key, required this.userData, required this.token, required this.teamData});

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
      final kid = Uri.encodeComponent(widget.teamData['id'].toString());
      final response = await http.get(
          Uri.parse('$baseUrl/api/nilai?siswa_id=$sid&kelas_id=$kid'),
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
      return _buildSkeleton();
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _nilaiList.isEmpty
          ? const EmptyState(
              icon: LucideIcons.award,
              message: 'Belum ada nilai\nyang diinput guru.',
              color: Color(0xFF76AFB8))
          : RefreshIndicator(
              onRefresh: _fetchNilai,
              color: AppTheme.primary,
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
                      childAspectRatio: crossCount == 1 ? 2.5 : 1.6,
                    ),
                    itemCount: _nilaiList.length,
                    itemBuilder: (_, i) {
                      final n = _nilaiList[i];
                      final color = _gradeColor(n['nilai']);
                      final valStr = n['nilai']?.toString() ?? '-';
                      final val = double.tryParse(valStr) ?? 0;

                      return RepaintBoundary(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.lightBorder, width: 1.2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(12),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: color.withAlpha(25),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(LucideIcons.award, color: color, size: 16),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      n['mapel'] ?? '-',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                        color: AppTheme.textLight,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.baseline,
                                        textBaseline: TextBaseline.alphabetic,
                                        children: [
                                          Text(
                                            val.toStringAsFixed(0),
                                            style: TextStyle(
                                              fontWeight: FontWeight.w900,
                                              fontSize: 28,
                                              color: color,
                                              letterSpacing: -1,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          const Text(
                                            '/ 100',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13,
                                              color: AppTheme.textMutedLt,
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (n['keterangan'] != null && n['keterangan'].toString().isNotEmpty)
                                        Text(
                                          n['keterangan'],
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 12,
                                            color: AppTheme.textMutedLt,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: color.withAlpha(20),
                                      borderRadius: BorderRadius.circular(100),
                                    ),
                                    child: Text(
                                      val >= 80 ? 'Lulus' : (val >= 60 ? 'Cukup' : 'Gagal'),
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 11,
                                        color: color,
                                      ),
                                    ),
                                  ),
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
    );
  }

  Widget _buildSkeleton() {
    return GridView.count(
      padding: const EdgeInsets.all(24),
      crossAxisCount: 2,
      childAspectRatio: 1.8,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: List.generate(6, (_) => const SkeletonLoader(radius: 16)),
    );
  }
}
