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
  List<dynamic> _allNilai = [];
  bool _isLoading = true;
  String _selectedFilter = 'Semua';

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
      
      final tugasReq = http.get(
          Uri.parse('$baseUrl/api/nilai?siswa_id=$sid'),
          headers: {'Authorization': 'Bearer ${widget.token}'});
          
      final quizReq = http.get(
          Uri.parse('$baseUrl/api/quizzes/my-submissions?kelasId=$kid'),
          headers: {'Authorization': 'Bearer ${widget.token}'});
          
      final responses = await Future.wait([tugasReq, quizReq]);
      
      List<dynamic> combined = [];
      
      // Proses Tugas
      if (responses[0].statusCode == 200) {
        final dec = jsonDecode(responses[0].body);
        List allTugas = dec is List ? dec : [];
        for (var n in allTugas) {
          final nKid = n['kelas_id'];
          if (nKid == null || nKid.toString() == kid) {
            combined.add({
              'id': n['id']?.toString() ?? UniqueKey().toString(),
              'type': 'Tugas',
              'judul': n['tugas_judul'] ?? 'Tugas Kelas',
              'guru_nama': n['guru_nama'],
              'nilai': n['nilai'],
              'waktu': n['waktu_dinilai'],
              'feedback': n['feedback']
            });
          }
        }
      }
      
      // Proses Kuis
      if (responses[1].statusCode == 200) {
        final dec = jsonDecode(responses[1].body);
        List allQuizzes = dec['data'] is List ? dec['data'] : [];
        for (var q in allQuizzes) {
          final score = q['score'] ?? 0;
          final total = q['totalPoints'] ?? 1;
          final pct = total > 0 ? (score / total * 100) : 0;
          
          combined.add({
            'id': q['_id']?.toString() ?? UniqueKey().toString(),
            'type': 'Kuis',
            'judul': q['quizTitle'] ?? 'Kuis Kelas',
            'guru_nama': q['quizCreator'],
            'nilai': pct,
            'waktu': q['submittedAt'],
            'feedback': q['autoSubmitted'] == true ? 'Disubmit otomatis oleh sistem' : 'Disubmit oleh siswa'
          });
        }
      }
      
      // Sort berdasarkan waktu terbaru
      combined.sort((a, b) {
        final dA = a['waktu'] != null ? DateTime.tryParse(a['waktu'].toString()) : DateTime(0);
        final dB = b['waktu'] != null ? DateTime.tryParse(b['waktu'].toString()) : DateTime(0);
        final dateA = dA ?? DateTime(0);
        final dateB = dB ?? DateTime(0);
        return dateB.compareTo(dateA);
      });
      
      if (mounted) {
        setState(() {
          _allNilai = combined;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetch nilai: $e');
      if (mounted) setState(() => _isLoading = false);
    }
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
    if (_isLoading) return _buildSkeleton();

    final filteredList = _allNilai.where((n) {
      if (_selectedFilter == 'Semua') return true;
      return n['type'] == _selectedFilter;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          // Filter Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              children: [
                _buildFilterChip('Semua'),
                const SizedBox(width: 8),
                _buildFilterChip('Tugas'),
                const SizedBox(width: 8),
                _buildFilterChip('Kuis'),
              ],
            ),
          ),
          
          Expanded(
            child: filteredList.isEmpty
                ? EmptyState(
                    icon: LucideIcons.award,
                    message: 'Belum ada $_selectedFilter\nyang dinilai.',
                    color: const Color(0xFF76AFB8))
                : RefreshIndicator(
                    onRefresh: _fetchNilai,
                    color: AppTheme.primary,
                    child: LayoutBuilder(
                      builder: (ctx, c) {
                        final isWeb = c.maxWidth > 700;
                        
                        return isWeb 
                          ? _buildGridView(filteredList) 
                          : _buildPageView(filteredList);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.indigoPrimary : AppTheme.indigoPrimary.withAlpha(10),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: isSelected ? AppTheme.indigoPrimary : AppTheme.indigoPrimary.withAlpha(20)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            fontSize: 13,
            color: isSelected ? Colors.white : AppTheme.indigoPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildGridView(List<dynamic> list) {
    return GridView.builder(
      padding: const EdgeInsets.only(left: 24, right: 24, top: 10, bottom: 100),
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 400,
        mainAxisSpacing: 20,
        crossAxisSpacing: 20,
        childAspectRatio: 0.85,
      ),
      itemCount: list.length,
      itemBuilder: (_, i) => _buildCard(list[i], i),
    );
  }

  Widget _buildPageView(List<dynamic> list) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'Geser untuk melihat riwayat',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textMutedLt.withAlpha(180),
            ),
          ).animate().fadeIn(duration: 400.ms),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: PageView.builder(
            controller: PageController(viewportFraction: 0.88),
            physics: const BouncingScrollPhysics(),
            itemCount: list.length,
            itemBuilder: (_, i) => _buildCard(list[i], i, isPage: true),
          ),
        ),
        const SizedBox(height: 100), // Nav bar spacing
      ],
    );
  }

  Widget _buildCard(dynamic n, int i, {bool isPage = false}) {
    final color = _gradeColor(n['nilai']);
    final valStr = n['nilai']?.toString() ?? '-';
    final val = double.tryParse(valStr) ?? 0;
    final isKuis = n['type'] == 'Kuis';

    return RepaintBoundary(
      child: Container(
        margin: EdgeInsets.only(right: isPage ? 16 : 0, bottom: isPage ? 20 : 0, top: isPage ? 10 : 0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.lightBorder, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: color.withAlpha(20),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Section
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withAlpha(25),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(isKuis ? LucideIcons.laptop : LucideIcons.award, color: color, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        n['judul'],
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          color: AppTheme.textLight,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        n['guru_nama'] != null ? 'Oleh: ${n['guru_nama']}' : 'Dinilai oleh Guru',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: AppTheme.textMutedLt,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            // Badge Section
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isKuis ? AppTheme.indigoPrimary.withAlpha(20) : AppTheme.orangeVivid.withAlpha(20),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    isKuis ? 'KUIS' : 'TUGAS',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                      letterSpacing: 0.5,
                      color: isKuis ? AppTheme.indigoPrimary : AppTheme.orangeVivid,
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: color.withAlpha(20),
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(color: color.withAlpha(50)),
                  ),
                  child: Text(
                    val >= 80 ? 'Lulus' : (val >= 60 ? 'Cukup' : 'Gagal'),
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            
            // Score
            Center(
              child: Column(
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        val.toStringAsFixed(0),
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 72,
                          color: color,
                          letterSpacing: -2,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        '/ 100',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 20,
                          color: AppTheme.textMutedLt,
                        ),
                      ),
                    ],
                  ),
                  if (n['waktu'] != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.lightBg,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(LucideIcons.calendar, size: 14, color: AppTheme.textMutedLt),
                          const SizedBox(width: 6),
                          Text(
                            _formatDate(n['waktu']),
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                              color: AppTheme.textMutedLt,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ]
                ],
              ),
            ),
            const Spacer(),
            
            // Feedback
            if (n['feedback'] != null && n['feedback'].toString().isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.indigoPrimary.withAlpha(10),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.indigoPrimary.withAlpha(20)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(LucideIcons.messageSquareQuote, size: 18, color: AppTheme.indigoPrimary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '"${n['feedback']}"',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: AppTheme.indigoPrimary,
                          fontStyle: FontStyle.italic,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ).animate(delay: (i * 100).ms).scale(duration: 500.ms, curve: Curves.easeOutBack),
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
