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
  int _currentPage = 1;
  static const int _itemsPerPage = 6;

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
          Uri.parse('$baseUrl/api/quiz/my-submissions?kelasId=$kid'),
          headers: {'Authorization': 'Bearer ${widget.token}'});
          
      final responses = await Future.wait([tugasReq, quizReq]);
      
      List<dynamic> combined = [];
      
      // Proses Tugas / Penilaian Mandiri
      if (responses[0].statusCode == 200) {
        final dec = jsonDecode(responses[0].body);
        List allTugas = dec is List ? dec : [];
        for (var n in allTugas) {
          final nKid = n['kelas_id'];
          if (nKid == null || nKid.toString() == kid) {
            final isManual = n['tugas_id'] == null;
            combined.add({
              'id': n['id']?.toString() ?? UniqueKey().toString(),
              'type': isManual ? 'Penilaian Mandiri' : 'Assignment',
              'judul': isManual ? (n['mapel'] ?? 'Input Manual') : (n['tugas_judul'] ?? 'Tugas Kelas'),
              'guru_nama': n['guru_nama'],
              'nilai': n['nilai'],
              'waktu': n['waktu_dinilai'] ?? n['tanggal'],
              'feedback': n['keterangan'] ?? n['feedback']
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
      } else if (responses[1].statusCode == 404) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('API Kuis belum aktif. Tolong RESTART server backend (Node.js).',
                style: TextStyle(fontWeight: FontWeight.w700)),
              backgroundColor: Colors.red,
            )
          );
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

    final totalItems = filteredList.length;
    final totalPages = (totalItems / _itemsPerPage).ceil();
    if (_currentPage > totalPages && totalPages > 0) {
      _currentPage = totalPages;
    }
    
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = (startIndex + _itemsPerPage > totalItems) ? totalItems : (startIndex + _itemsPerPage);
    final pagedList = filteredList.isNotEmpty ? filteredList.sublist(startIndex, endIndex) : [];

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          // Filter Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              child: Row(
                children: [
                  _buildFilterChip('Semua'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Assignment'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Kuis'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Penilaian Mandiri'),
                ],
              ),
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
                    child: Column(
                      children: [
                        Expanded(
                          child: LayoutBuilder(
                            builder: (ctx, c) {
                              final isWeb = c.maxWidth > 700;
                              return isWeb 
                                ? _buildGridView(pagedList) 
                                : _buildListView(pagedList);
                            },
                          ),
                        ),
                        if (totalPages > 1) _buildPagination(totalPages),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPagination(int totalPages) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(LucideIcons.chevronLeft),
            color: _currentPage > 1 ? AppTheme.indigoPrimary : AppTheme.textMutedLt.withAlpha(100),
            onPressed: _currentPage > 1 ? () => setState(() => _currentPage--) : null,
          ),
          const SizedBox(width: 8),
          ...List.generate(totalPages, (index) {
            final page = index + 1;
            final isSelected = page == _currentPage;
            return GestureDetector(
              onTap: () => setState(() => _currentPage = page),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.indigoPrimary : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? AppTheme.indigoPrimary : AppTheme.lightBorder,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  page.toString(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : AppTheme.textLight,
                  ),
                ),
              ),
            );
          }),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(LucideIcons.chevronRight),
            color: _currentPage < totalPages ? AppTheme.indigoPrimary : AppTheme.textMutedLt.withAlpha(100),
            onPressed: _currentPage < totalPages ? () => setState(() => _currentPage++) : null,
          ),
        ],
      ),
    );
  }
  
  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;
    return GestureDetector(
      onTap: () {
        if (_selectedFilter != label) {
          setState(() {
            _selectedFilter = label;
            _currentPage = 1; // Reset ke halaman 1 saat ganti filter
          });
        }
      },
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
      padding: const EdgeInsets.only(left: 24, right: 24, top: 10, bottom: 20),
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

  Widget _buildListView(List<dynamic> list) {
    return ListView.builder(
      padding: const EdgeInsets.only(left: 24, right: 24, top: 10, bottom: 20),
      physics: const BouncingScrollPhysics(),
      itemCount: list.length,
      itemBuilder: (_, i) => Container(
        height: 380, // Fix layout error from unbounded height for Spacer
        padding: const EdgeInsets.only(bottom: 16),
        child: _buildCard(list[i], i),
      ),
    );
  }

  Widget _buildCard(dynamic n, int i, {bool isPage = false}) {
    final color = _gradeColor(n['nilai']);
    final valStr = n['nilai']?.toString() ?? '-';
    final val = double.tryParse(valStr) ?? 0;
    final isKuis = n['type'] == 'Kuis';
    final isManual = n['type'] == 'Penilaian Mandiri';
    
    Color badgeColor = AppTheme.orangeVivid;
    if (isKuis) badgeColor = AppTheme.indigoPrimary;
    if (isManual) badgeColor = const Color(0xFF6366F1);
    
    IconData cardIcon = LucideIcons.clipboardList;
    if (isKuis) cardIcon = LucideIcons.laptop;
    if (isManual) cardIcon = LucideIcons.fileText;

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
                  child: Icon(cardIcon, color: color, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (n['judul'] ?? 'Tidak Ada Judul').toString(),
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
                    color: badgeColor.withAlpha(20),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    (n['type'] ?? 'TUGAS').toString().toUpperCase(),
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                      letterSpacing: 0.5,
                      color: badgeColor,
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
