import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../config/theme.dart';
import '../../../widgets/app_shell.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../config/api_config.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                            color: isDark ? const Color(0xFF1E2538) : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: color.withAlpha(isDark ? 55 : 30),
                              width: 1.2,
                            ),
                          ),
                          padding: const EdgeInsets.all(4),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF161D2B) : const Color(0xFFEEF2FF),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: color.withAlpha(20),
                                width: 1.0,
                              ),
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
                                        color: color.withAlpha(20),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: color.withAlpha(50)),
                                      ),
                                      child: Icon(LucideIcons.award, color: color, size: 16),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        n['mapel'] ?? '-',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w800,
                                          color: isDark ? Colors.white : AppTheme.textLight,
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
                                              style: GoogleFonts.plusJakartaSans(
                                                fontSize: 28,
                                                fontWeight: FontWeight.w900,
                                                color: color,
                                                letterSpacing: -1,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '/ 100',
                                              style: GoogleFonts.plusJakartaSans(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                color: isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt,
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (n['keterangan'] != null && n['keterangan'].toString().isNotEmpty)
                                          Text(
                                            n['keterangan'],
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                      ],
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: color.withAlpha(20),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        val >= 80 ? 'LULUS' : (val >= 60 ? 'CUKUP' : 'GAGAL'),
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w900,
                                          color: color,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
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
      children: List.generate(6, (_) => const SkeletonLoader(radius: 24)),
    );
  }
}
