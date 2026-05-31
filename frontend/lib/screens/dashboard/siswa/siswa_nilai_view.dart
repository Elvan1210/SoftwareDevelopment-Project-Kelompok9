import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../widgets/app_shell.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../config/api_config.dart';

// --- Tailwind Neo-Brutalist Tokens ---
const Color _onSurface = Color(0xFF001E2B);
const Color _onSurfaceVariant = Color(0xFF414944);
const Color _primary = Color(0xFF3D6754);
const Color _primaryContainer = Color(0xFFB7E5CD);
const Color _secondaryContainer = Color(0xFFB7EDE7);
const Color _tertiaryContainer = Color(0xFFFFD1C0);
const Color _surfaceContainerHighest = Color(0xFFC1E8FF);
const Color _surface = Color(0xFFF4FAFF);
const Color _onBackground = Color(0xFF001E2B);

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
              'judul': isManual ? (n['judul'] ?? 'Input Manual') : (n['tugas_judul'] ?? 'Tugas Kelas'),
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

  String _formatDate(String? isoDate) {
    if (isoDate == null) return '-';
    try {
      final date = DateTime.parse(isoDate);
      final listBulan = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
      return '${date.day} ${listBulan[date.month - 1]} ${date.year}, ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
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
      body: LayoutBuilder(
        builder: (ctx, constraints) {
          final isDesktop = constraints.maxWidth >= 768;

          return RefreshIndicator(
            onRefresh: _fetchNilai,
            color: _primary,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.only(
                left: isDesktop ? 40 : 16,
                right: isDesktop ? 40 : 16,
                top: 32,
                bottom: 100,
              ),
              children: [
                // Headline
                Padding(
                  padding: const EdgeInsets.only(bottom: 32),
                  child: Text(
                    'Nilai Kamu',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: isDesktop ? 48 : 36,
                      fontWeight: FontWeight.w800,
                      color: _onBackground,
                      letterSpacing: -1.92,
                      height: 1.1,
                    ),
                  ),
                ).animate().fadeIn().slideY(begin: -0.1),

                // Filters
                Padding(
                  padding: const EdgeInsets.only(bottom: 40),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    clipBehavior: Clip.none,
                    child: Row(
                      children: [
                        _buildFilterChip('Semua'),
                        const SizedBox(width: 12),
                        _buildFilterChip('Assignment'),
                        const SizedBox(width: 12),
                        _buildFilterChip('Kuis'),
                        const SizedBox(width: 12),
                        _buildFilterChip('Penilaian Mandiri'),
                      ],
                    ),
                  ),
                ).animate().fadeIn().slideX(begin: -0.05),

                if (filteredList.isEmpty)
                  _buildEmpty()
                else
                  _buildList(filteredList, isDesktop),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;
    return GestureDetector(
      onTap: () {
        if (_selectedFilter != label) {
          setState(() => _selectedFilter = label);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        transform: Matrix4.translationValues(
          isSelected ? 2 : 0,
          isSelected ? 2 : 0,
          0,
        ),
        decoration: BoxDecoration(
          color: isSelected ? _primary : _surface,
          borderRadius: BorderRadius.circular(9999),
          border: Border.all(color: _onSurface, width: 2),
          boxShadow: isSelected ? [] : const [BoxShadow(color: _onSurface, offset: Offset(2, 2))],
        ),
        child: Text(
          label.toUpperCase(),
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            fontSize: 12,
            letterSpacing: 0.6,
            color: isSelected ? Colors.white : _onSurface,
          ),
        ),
      ),
    );
  }

  Widget _buildList(List<dynamic> list, bool isDesktop) {
    return Column(
      children: List.generate(list.length, (i) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: _GradeCardNeo(
            nilai: list[i],
            index: i,
            formatDate: _formatDate,
          ),
        );
      }),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _onSurface, width: 2),
          boxShadow: const [BoxShadow(color: _onSurface, offset: Offset(4, 4))],
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _surfaceContainerHighest,
              shape: BoxShape.circle,
              border: Border.all(color: _onSurface, width: 2),
            ),
            child: const Icon(LucideIcons.award, color: _onSurface, size: 32),
          ),
          const SizedBox(height: 20),
          Text(
            'Belum ada $_selectedFilter',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 24, color: _onSurface),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Belum ada penilaian yang masuk untuk kategori ini.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 16, color: _onSurfaceVariant, fontWeight: FontWeight.w400),
          ),
        ]),
      ),
    );
  }

  Widget _buildSkeleton() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SkeletonLoader(height: 60, width: 200),
          const SizedBox(height: 40),
          const Row(
            children: [
              SkeletonLoader(height: 40, width: 100, radius: 20),
              SizedBox(width: 12),
              SkeletonLoader(height: 40, width: 100, radius: 20),
            ],
          ),
          const SizedBox(height: 40),
          Expanded(
            child: ListView.builder(
              itemCount: 4,
              itemBuilder: (context, index) => const Padding(
                padding: EdgeInsets.only(bottom: 24),
                child: SkeletonLoader(height: 160, radius: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GradeCardNeo extends StatelessWidget {
  final dynamic nilai;
  final int index;
  final String Function(String?) formatDate;

  const _GradeCardNeo({required this.nilai, required this.index, required this.formatDate});

  @override
  Widget build(BuildContext context) {
    final bgColors = [
      _primaryContainer,
      _secondaryContainer,
      _tertiaryContainer,
      _surfaceContainerHighest
    ];
    final colorIdx = index % bgColors.length;
    final bgColor = bgColors[colorIdx];

    final valStr = nilai['nilai']?.toString() ?? '-';
    final val = double.tryParse(valStr) ?? 0;
    
    // Status color
    Color statusColor = const Color(0xFFEF4444); // Red
    if (val >= 80) {
      statusColor = const Color(0xFF10B981); // Green
    } else if (val >= 60) {
      statusColor = const Color(0xFFF59E0B); // Orange
    }

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _onSurface, width: 2),
        boxShadow: const [BoxShadow(color: _onSurface, offset: Offset(4, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              border: const Border(bottom: BorderSide(color: _onSurface, width: 2)),
              color: Colors.white.withAlpha(128),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: _onSurface, width: 1.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    nilai['type'] == 'Kuis' ? LucideIcons.laptop : LucideIcons.clipboardList,
                    color: _onSurface,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _onSurface,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          (nilai['type'] ?? 'TUGAS').toString().toUpperCase(),
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700,
                            fontSize: 10,
                            letterSpacing: 1.2,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        (nilai['judul'] ?? 'Tidak Ada Judul').toString(),
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                          height: 1.2,
                          color: _onBackground,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (nilai['waktu'] != null)
                  Text(
                    formatDate(nilai['waktu']),
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      color: _onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),

          // Body
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dinilai Oleh:',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                          color: _onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        nilai['guru_nama'] != null ? '${nilai['guru_nama']}' : 'Sistem / Guru',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: _onBackground,
                        ),
                      ),
                      if (nilai['feedback'] != null && nilai['feedback'].toString().isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: _onSurface, width: 1.5),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(LucideIcons.messageSquareQuote, size: 16, color: _onSurfaceVariant),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '"${nilai['feedback']}"',
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 13,
                                    color: _onSurfaceVariant,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ]
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: statusColor, width: 2),
                      ),
                      child: Text(
                        val >= 80 ? 'LULUS' : (val >= 60 ? 'CUKUP' : 'GAGAL'),
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                          color: statusColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          val.toStringAsFixed(0),
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w900,
                            fontSize: 48,
                            height: 1,
                            letterSpacing: -2,
                            color: _onBackground,
                          ),
                        ),
                        Text(
                          '/100',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: _onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
