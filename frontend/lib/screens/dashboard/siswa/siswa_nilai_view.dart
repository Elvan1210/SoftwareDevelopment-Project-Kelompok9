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
          Uri.parse('$baseUrl/api/nilai?siswa_id=$sid'),
          headers: {'Authorization': 'Bearer ${widget.token}'});
      if (response.statusCode == 200) {
        final dec = jsonDecode(response.body);
        List all = dec is List ? dec : [];
        setState(() {
          _nilaiList = all.where((n) {
             final nKid = n['kelas_id'];
             // Jika data punya kelas_id, pastikan sesuai
             if (nKid != null) return nKid.toString() == widget.teamData['id'].toString();
             // Jika data lawas (tidak ada kelas_id), tampilkan saja sebagai fallback
             return true;
          }).toList();
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

  String _formatDate(String? isoDate) {
    if (isoDate == null) return '-';
    try {
      final date = DateTime.parse(isoDate);
      return '${date.day}-${date.month}-${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return isoDate;
    }
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
                  final padding = Breakpoints.screenPadding(c.maxWidth);
                  return ListView.builder(
                    padding: EdgeInsets.only(
                      left: padding.left, 
                      right: padding.right, 
                      top: padding.top, 
                      bottom: 100, // Extend behind nav bar
                    ),
                    physics: const BouncingScrollPhysics(),
                    itemCount: _nilaiList.length,
                    itemBuilder: (_, i) {
                      final n = _nilaiList[i];
                      final color = _gradeColor(n['nilai']);
                      final valStr = n['nilai']?.toString() ?? '-';
                      final val = double.tryParse(valStr) ?? 0;

                      return RepaintBoundary(
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppTheme.lightBorder, width: 1.2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(12),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Top Section: Icon & Title
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: color.withAlpha(25),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(LucideIcons.award, color: color, size: 20),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          n['tugas_judul'] ?? 'Tugas Kelas',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 16,
                                            color: AppTheme.textLight,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          n['guru_nama'] != null ? 'Dinilai oleh ${n['guru_nama']}' : 'Dinilai oleh Guru',
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
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: color.withAlpha(20),
                                      borderRadius: BorderRadius.circular(100),
                                      border: Border.all(color: color.withAlpha(50)),
                                    ),
                                    child: Text(
                                      val >= 80 ? 'Lulus' : (val >= 60 ? 'Cukup' : 'Gagal'),
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 12,
                                        color: color,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              
                              // Middle Section: Score
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text(
                                    val.toStringAsFixed(0),
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 36,
                                      color: color,
                                      letterSpacing: -1,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Text(
                                    '/ 100',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      color: AppTheme.textMutedLt,
                                    ),
                                  ),
                                  const Spacer(),
                                  if (n['waktu_dinilai'] != null)
                                    Row(
                                      children: [
                                        const Icon(LucideIcons.calendar, size: 12, color: AppTheme.textMutedLt),
                                        const SizedBox(width: 4),
                                        Text(
                                          _formatDate(n['waktu_dinilai']),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 11,
                                            color: AppTheme.textMutedLt,
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                              
                              // Bottom Section: Feedback
                              if (n['feedback'] != null && n['feedback'].toString().isNotEmpty) ...[
                                const SizedBox(height: 16),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppTheme.indigoPrimary.withAlpha(15),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: AppTheme.indigoPrimary.withAlpha(30)),
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Icon(LucideIcons.messageSquare, size: 14, color: AppTheme.indigoPrimary),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          n['feedback'],
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w500,
                                            fontSize: 13,
                                            color: AppTheme.textLight,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
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
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: 4,
      itemBuilder: (_, i) => const Padding(
        padding: EdgeInsets.only(bottom: 16),
        child: SkeletonLoader(height: 140, radius: 20),
      ),
    );
  }
}
