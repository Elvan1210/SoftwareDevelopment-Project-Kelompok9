import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../widgets/confirm_delete.dart';

import '../../../config/api_config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';

// ── Neo-Brutalist Tokens ──────────────────────────────────────────────────────
const Color _ink = Color(0xFF001E2B);
const Color _inkMuted = Color(0xFF4B6459);
const Color _primary = Color(0xFF3D6754);
const Color _primaryLight = Color(0xFFB7E5CD);
const Color _surface = Color(0xFFF4FAFF);
const Color _white = Colors.white;
const Color _errorBg = Color(0xFFFFDAD6);
const Color _errorFg = Color(0xFF93000A);

// Score color helpers
Color _scoreColor(double val) {
  if (val >= 80) return const Color(0xFF2E7D52);
  if (val >= 60) return const Color(0xFFB45309);
  return const Color(0xFFD32F2F);
}

Color _scoreBg(double val) {
  if (val >= 80) return const Color(0xFFD1FAE5);
  if (val >= 60) return const Color(0xFFFFF3CD);
  return const Color(0xFFFFE4E1);
}

// Type palette
Map<String, Color> _typeColor(String tipe) {
  switch (tipe) {
    case 'Kuis':
      return {'start': const Color(0xFFF59E0B), 'bg': const Color(0xFFFFF3CD)};
    case 'Assignment':
      return {'start': const Color(0xFF10B981), 'bg': const Color(0xFFD1FAE5)};
    default:
      return {'start': const Color(0xFF6366F1), 'bg': const Color(0xFFEDE9FE)};
  }
}

class GuruNilaiView extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String token;
  final dynamic teamData;
  const GuruNilaiView({
    super.key,
    required this.userData,
    required this.token,
    required this.teamData,
  });

  @override
  State<GuruNilaiView> createState() => _GuruNilaiViewState();
}

class _GuruNilaiViewState extends State<GuruNilaiView> {
  List<dynamic> _nilaiList = [];
  List<dynamic> _userList = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final headers = {'Authorization': 'Bearer ${widget.token}'};
      final kelasId = widget.teamData['id']?.toString() ?? '';
      final guruId = widget.userData['id']?.toString() ?? '';

      final responses = await Future.wait([
        http.get(Uri.parse('$baseUrl/api/nilai'), headers: headers),
        if (kelasId.isNotEmpty)
          http.get(Uri.parse('$baseUrl/api/kelas/$kelasId/members'), headers: headers)
        else
          Future.value(http.Response('[]', 200)),
        http.get(Uri.parse('$baseUrl/api/quiz?kelasId=$kelasId'), headers: headers),
        http.get(Uri.parse('$baseUrl/api/tugas?kelas_id=$kelasId'), headers: headers),
      ]);

      List<dynamic> allNilai = [];

      // Build tugas map for this class
      final Map<String, String> tugasMap = {};
      if (responses[3].statusCode == 200) {
        final decTugas = jsonDecode(responses[3].body);
        final listTugas = decTugas is List ? decTugas : [];
        for (var t in listTugas) {
          tugasMap[t['id'].toString()] = t['judul'] ?? 'Tugas';
        }
      }

      // Process manual/tugas nilai
      // BUG FIX: was != (inverting the filter), should be ==
      if (responses[0].statusCode == 200) {
        final dec = jsonDecode(responses[0].body);
        List data = dec is List ? dec : [];

        for (var n in data) {
          // Only show nilai from THIS guru
          if (n['guru_id']?.toString() != guruId) continue;

          if (n['tugas_id'] != null) {
            final tId = n['tugas_id'].toString();
            // Accept if tugas is in this class OR if kelas_id matches
            final inClass = tugasMap.containsKey(tId) ||
                n['kelas_id']?.toString() == kelasId;
            if (inClass) {
              n['tipe'] = 'Assignment';
              n['isManual'] = false;
              n['judul'] = tugasMap[tId] ?? n['tugas_judul'] ?? n['judul'] ?? 'Tugas';
              n['tanggal'] = n['waktu_dinilai'] ?? n['tanggal'];
              allNilai.add(Map<String, dynamic>.from(n));
            }
          } else {
            // Manual nilai — match kelas_id
            final inClass = kelasId.isEmpty ||
                n['kelas_id']?.toString() == kelasId;
            if (inClass) {
              n['tipe'] = n['tipe'] ?? 'Lainnya';
              n['isManual'] = true;
              allNilai.add(Map<String, dynamic>.from(n));
            }
          }
        }
      }

      // Process quiz nilai
      if (responses[2].statusCode == 200) {
        final decQuiz = jsonDecode(responses[2].body);
        final listQuiz = decQuiz['data'] is List ? decQuiz['data'] : [];

        if (listQuiz.isNotEmpty) {
          final quizReqs = listQuiz.map((q) => http.get(
              Uri.parse('$baseUrl/api/quiz/${q['_id']}/submissions'),
              headers: headers));
          final quizResps = await Future.wait(quizReqs);

          for (int i = 0; i < listQuiz.length; i++) {
            final q = listQuiz[i];
            final r = quizResps[i];
            if (r.statusCode == 200) {
              final subDec = jsonDecode(r.body);
              final subs = subDec['data'] is List ? subDec['data'] : [];
              for (var s in subs) {
                final score = (s['score'] ?? 0).toDouble();
                final total = (s['totalPoints'] ?? 100).toDouble();
                final finalScore = total > 0 ? (score / total) * 100 : 0.0;
                allNilai.add({
                  'id': s['_id'],
                  'siswa_id': s['studentId'],
                  'judul': q['title'] ?? 'Kuis',
                  'nilai': finalScore,
                  'keterangan': 'Otomatis dari kuis',
                  'tipe': 'Kuis',
                  'tanggal': s['submittedAt'],
                  'isManual': false,
                });
              }
            }
          }
        }
      }

      allNilai.sort((a, b) {
        final dA = DateTime.tryParse(a['tanggal']?.toString() ?? '') ?? DateTime(2000);
        final dB = DateTime.tryParse(b['tanggal']?.toString() ?? '') ?? DateTime(2000);
        return dB.compareTo(dA);
      });

      _nilaiList = allNilai;

      if (responses[1].statusCode == 200) {
        final dec = jsonDecode(responses[1].body);
        List users = dec is List ? dec : [];
        _userList = users.toList();
      }
    } catch (e) {
      debugPrint('Error fetchData: $e');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _deleteNilai(String id) async {
    if (await confirmDelete(context, pesan: 'Hapus data nilai ini?')) {
      try {
        await http.delete(
          Uri.parse('$baseUrl/api/nilai/$id'),
          headers: {'Authorization': 'Bearer ${widget.token}'},
        );
        _fetchData();
        if (mounted) Navigator.pop(context);
      } catch (e) {
        debugPrint('Error: $e');
      }
    }
  }

  void _showNilaiForm([Map<String, dynamic>? nilai]) {
    final isEditing = nilai != null;
    String? selectedSiswaId = isEditing ? nilai['siswa_id'].toString() : null;
    final judulCtrl = TextEditingController(text: isEditing ? nilai['judul'] : '');
    final nilaiCtrl = TextEditingController(
        text: isEditing ? nilai['nilai']?.toString() : '');
    final keteranganCtrl =
        TextEditingController(text: isEditing ? nilai['keterangan'] : '');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(20),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 520),
            decoration: BoxDecoration(
              color: _white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _ink, width: 2),
              boxShadow: const [BoxShadow(color: _ink, offset: Offset(6, 6))],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 20, 20, 20),
                  decoration: const BoxDecoration(
                    color: _primaryLight,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(18)),
                    border: Border(
                        bottom: BorderSide(color: _ink, width: 2)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _primary,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: _ink, width: 2),
                        ),
                        child: const Icon(LucideIcons.clipboardEdit,
                            color: _white, size: 20),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          isEditing ? 'Edit Nilai' : 'Input Nilai Siswa',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w900,
                            fontSize: 22,
                            color: _ink,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(ctx),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: _white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: _ink, width: 2),
                          ),
                          child: const Icon(LucideIcons.x,
                              size: 16, color: _ink),
                        ),
                      ),
                    ],
                  ),
                ),

                // Body
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Dropdown pilih siswa
                        _fieldLabel('Pilih Siswa'),
                        const SizedBox(height: 6),
                        Container(
                          decoration: BoxDecoration(
                            color: _white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: _ink, width: 2),
                            boxShadow: const [
                              BoxShadow(color: _ink, offset: Offset(3, 3))
                            ],
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: selectedSiswaId,
                              hint: Padding(
                                padding: const EdgeInsets.only(left: 14),
                                child: Text('Pilih siswa...',
                                    style: GoogleFonts.inter(
                                        color: _inkMuted, fontSize: 15)),
                              ),
                              isExpanded: true,
                              dropdownColor: _white,
                              borderRadius: BorderRadius.circular(10),
                              icon: const Padding(
                                padding: EdgeInsets.only(right: 12),
                                child: Icon(Icons.expand_more, color: _ink),
                              ),
                              style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                  color: _ink),
                              items: _userList
                                  .map<DropdownMenuItem<String>>((u) {
                                return DropdownMenuItem<String>(
                                  value: u['id'].toString(),
                                  child: Padding(
                                    padding: const EdgeInsets.only(left: 14),
                                    child: Text(u['nama'] ?? '-'),
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) =>
                                  setDialogState(() => selectedSiswaId = val),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        _fieldLabel('Judul / Topik'),
                        const SizedBox(height: 6),
                        _neoTextField(judulCtrl, 'Contoh: UH Bab 3',
                            LucideIcons.bookOpen),

                        const SizedBox(height: 16),
                        _fieldLabel('Nilai (0–100)'),
                        const SizedBox(height: 6),
                        _neoTextField(nilaiCtrl, 'Masukkan angka 0-100',
                            LucideIcons.award,
                            isNumber: true),

                        const SizedBox(height: 16),
                        _fieldLabel('Keterangan (opsional)'),
                        const SizedBox(height: 6),
                        _neoTextField(keteranganCtrl, 'Catatan tambahan...',
                            LucideIcons.messageSquare,
                            isMultiLine: true),
                      ],
                    ),
                  ),
                ),

                // Footer buttons
                Container(
                  padding:
                      const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Row(
                    children: [
                      // Batal
                      Expanded(
                        child: _NeoBtn(
                          label: 'Batal',
                          bgColor: _white,
                          fgColor: _ink,
                          onTap: () => Navigator.pop(ctx),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Simpan
                      Expanded(
                        child: _NeoBtn(
                          label: isEditing ? 'Simpan' : 'Simpan Nilai',
                          bgColor: _primary,
                          fgColor: _white,
                          icon: LucideIcons.check,
                          onTap: () async {
                            if (selectedSiswaId == null ||
                                nilaiCtrl.text.isEmpty) { return; }
                            final siswa = _userList.firstWhere(
                                (u) =>
                                    u['id'].toString() == selectedSiswaId,
                                orElse: () => {});
                            final body = {
                              'siswa_id': selectedSiswaId,
                              'siswa_nama': siswa['nama'] ?? '-',
                              'judul': judulCtrl.text,
                              'nilai':
                                  double.tryParse(nilaiCtrl.text) ?? 0,
                              'keterangan': keteranganCtrl.text,
                              'tipe': 'Lainnya',
                              'guru_id': widget.userData['id'],
                              'kelas_id': widget.teamData['id'],
                              if (!isEditing)
                                'tanggal': DateTime.now().toIso8601String(),
                            };

                            final url = isEditing
                                ? '$baseUrl/api/nilai/${nilai['id']}'
                                : '$baseUrl/api/nilai';
                            final response = await (isEditing
                                ? http.put(Uri.parse(url),
                                    headers: {
                                      'Content-Type': 'application/json',
                                      'Authorization':
                                          'Bearer ${widget.token}'
                                    },
                                    body: jsonEncode(body))
                                : http.post(Uri.parse(url),
                                    headers: {
                                      'Content-Type': 'application/json',
                                      'Authorization':
                                          'Bearer ${widget.token}'
                                    },
                                    body: jsonEncode(body)));

                            if (response.statusCode == 200 ||
                                response.statusCode == 201) {
                              if (ctx.mounted) Navigator.pop(ctx);
                              _fetchData();
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _fieldLabel(String text) => Text(
        text,
        style: GoogleFonts.inter(
            fontWeight: FontWeight.w800, fontSize: 13, color: _ink),
      );

  Widget _neoTextField(
    TextEditingController ctrl,
    String hint,
    IconData icon, {
    bool isNumber = false,
    bool isMultiLine = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _ink, width: 2),
        boxShadow: const [BoxShadow(color: _ink, offset: Offset(3, 3))],
      ),
      child: TextField(
        controller: ctrl,
        keyboardType: isNumber
            ? TextInputType.number
            : (isMultiLine ? TextInputType.multiline : TextInputType.text),
        maxLines: isMultiLine ? 3 : 1,
        style: GoogleFonts.inter(
            fontWeight: FontWeight.w700, fontSize: 15, color: _ink),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.inter(color: _inkMuted, fontSize: 14),
          prefixIcon: Icon(icon, size: 18, color: _inkMuted),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        ),
      ),
    );
  }

  String _formatDateStr(String raw) {
    try {
      final dt = DateTime.parse(raw);
      const listHari = [
        'Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'
      ];
      const listBulan = [
        'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
        'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
      ];
      return '${listHari[dt.weekday % 7]}, ${dt.day} ${listBulan[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return raw;
    }
  }

  void _showStudentDetail(dynamic siswa, List<dynamic> nilaiSiswa) {
    String activeFilter = 'Semua';
    final filters = ['Semua', 'Assignment', 'Kuis', 'Lainnya'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final filtered = activeFilter == 'Semua'
              ? nilaiSiswa
              : nilaiSiswa
                  .where((n) => (n['tipe'] ?? 'Lainnya') == activeFilter)
                  .toList();

          double avg = 0;
          if (filtered.isNotEmpty) {
            avg = filtered.fold(
                    0.0,
                    (sum, n) =>
                        sum + (double.tryParse(n['nilai'].toString()) ?? 0)) /
                filtered.length;
          }

          return Container(
            height: MediaQuery.of(context).size.height * 0.88,
            decoration: const BoxDecoration(
              color: _surface,
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(24)),
              border: Border(
                  top: BorderSide(color: _ink, width: 2),
                  left: BorderSide(color: _ink, width: 2),
                  right: BorderSide(color: _ink, width: 2)),
            ),
            child: Column(
              children: [
                // Drag handle
                const SizedBox(height: 12),
                Container(
                  width: 48,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _ink.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 12),

                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: _primaryLight,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: _ink, width: 2),
                            ),
                            child: const Icon(LucideIcons.user,
                                color: _primary, size: 22),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  siswa['nama'] ?? '-',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 20,
                                    color: _ink,
                                  ),
                                ),
                                Text(
                                  'Rekapitulasi Nilai',
                                  style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: _inkMuted,
                                      fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                          if (filtered.isNotEmpty) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: _scoreBg(avg),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: _ink, width: 2),
                                boxShadow: const [
                                  BoxShadow(color: _ink, offset: Offset(2, 2))
                                ],
                              ),
                              child: Text(
                                'Rata-rata: ${avg.toStringAsFixed(1)}',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 13,
                                  color: _scoreColor(avg),
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(width: 10),
                          GestureDetector(
                            onTap: () => Navigator.pop(ctx),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: _errorBg,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: _ink, width: 2),
                              ),
                              child: const Icon(LucideIcons.x,
                                  size: 18, color: _errorFg),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Filter chips
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          children: filters.map((f) {
                            final sel = activeFilter == f;
                            final tc = _typeColor(f);
                            final chipColor = sel
                                ? (tc['start'] ?? _primary)
                                : _white;
                            final txtColor = sel ? _white : _ink;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: GestureDetector(
                                onTap: () =>
                                    setModalState(() => activeFilter = f),
                                child: AnimatedContainer(
                                  duration:
                                      const Duration(milliseconds: 180),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: chipColor,
                                    borderRadius:
                                        BorderRadius.circular(100),
                                    border:
                                        Border.all(color: _ink, width: 2),
                                    boxShadow: sel
                                        ? []
                                        : const [
                                            BoxShadow(
                                                color: _ink,
                                                offset: Offset(2, 2))
                                          ],
                                  ),
                                  child: Text(f,
                                      style: GoogleFonts.inter(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 12,
                                          color: txtColor)),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),

                Container(height: 2, color: _ink.withValues(alpha: 0.1)),

                // List nilai
                Expanded(
                  child: filtered.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                  color: _primaryLight,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: _ink, width: 2),
                                ),
                                child: const Icon(LucideIcons.inbox,
                                    color: _primary, size: 28),
                              ),
                              const SizedBox(height: 14),
                              Text('Belum ada nilai.',
                                  style: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 18,
                                      color: _ink)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                          itemCount: filtered.length,
                          itemBuilder: (ctx, i) {
                            final n = filtered[i];
                            final val =
                                double.tryParse(n['nilai'].toString()) ??
                                    0;
                            final tipe = n['tipe'] ?? 'Lainnya';
                            final tc = _typeColor(tipe);
                            final accentColor = tc['start']!;
                            final accentBg = tc['bg']!;

                            IconData iconData = LucideIcons.fileText;
                            if (tipe == 'Kuis') {
                              iconData = LucideIcons.helpCircle;
                            } else if (tipe == 'Assignment') {
                              iconData = LucideIcons.clipboardList;
                            }

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: _white,
                                  borderRadius: BorderRadius.circular(14),
                                  border:
                                      Border.all(color: _ink, width: 2),
                                  boxShadow: const [
                                    BoxShadow(
                                        color: _ink,
                                        offset: Offset(3, 3))
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    // Card header
                                    Container(
                                      padding: const EdgeInsets.fromLTRB(
                                          14, 10, 14, 10),
                                      decoration: BoxDecoration(
                                        color: accentBg,
                                        borderRadius:
                                            const BorderRadius.vertical(
                                                top: Radius.circular(12)),
                                        border: const Border(
                                            bottom: BorderSide(
                                                color: _ink, width: 1.5)),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            padding:
                                                const EdgeInsets.all(7),
                                            decoration: BoxDecoration(
                                              color: accentColor,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Icon(iconData,
                                                color: _white, size: 13),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  tipe.toUpperCase(),
                                                  style: GoogleFonts.inter(
                                                    fontWeight:
                                                        FontWeight.w900,
                                                    fontSize: 10,
                                                    color: accentColor,
                                                    letterSpacing: 0.8,
                                                  ),
                                                ),
                                                Text(
                                                  n['judul'] ?? '-',
                                                  style:
                                                      GoogleFonts.plusJakartaSans(
                                                    fontWeight:
                                                        FontWeight.w800,
                                                    fontSize: 14,
                                                    color: _ink,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (n['tanggal'] != null) ...[
                                            Text(
                                              _formatDateStr(
                                                  n['tanggal'].toString()),
                                              style: GoogleFonts.inter(
                                                fontSize: 11,
                                                color: _inkMuted,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    // Card body
                                    Padding(
                                      padding: const EdgeInsets.all(14),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment
                                                          .baseline,
                                                  textBaseline:
                                                      TextBaseline.alphabetic,
                                                  children: [
                                                    Text(
                                                      val.toStringAsFixed(0),
                                                      style: GoogleFonts
                                                          .plusJakartaSans(
                                                        fontWeight:
                                                            FontWeight.w900,
                                                        fontSize: 36,
                                                        color:
                                                            _scoreColor(val),
                                                        height: 1,
                                                      ),
                                                    ),
                                                    Text(' / 100',
                                                        style: GoogleFonts.inter(
                                                            fontSize: 13,
                                                            color: _inkMuted,
                                                            fontWeight:
                                                                FontWeight
                                                                    .w600)),
                                                  ],
                                                ),
                                                if (n['keterangan'] !=
                                                        null &&
                                                    n['keterangan']
                                                        .toString()
                                                        .isNotEmpty) ...[
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    n['keterangan'],
                                                    style: GoogleFonts.inter(
                                                        fontSize: 12,
                                                        color: _inkMuted,
                                                        fontWeight: FontWeight
                                                            .w500),
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                          // Score badge
                                          Container(
                                            padding:
                                                const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 8),
                                            decoration: BoxDecoration(
                                              color: _scoreBg(val),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              border: Border.all(
                                                  color: _ink, width: 1.5),
                                            ),
                                            child: Text(
                                              val >= 80
                                                  ? 'Bagus 🎉'
                                                  : val >= 60
                                                      ? 'Cukup'
                                                      : 'Perlu\nPerbaikan',
                                              textAlign: TextAlign.center,
                                              style: GoogleFonts.inter(
                                                fontWeight: FontWeight.w900,
                                                fontSize: 11,
                                                color: _scoreColor(val),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Edit/Delete (manual only)
                                    if (n['isManual'] == true)
                                      Container(
                                        padding: const EdgeInsets.fromLTRB(
                                            14, 0, 14, 12),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          children: [
                                            _SmallBtn(
                                              label: 'Edit',
                                              icon: LucideIcons.pencil,
                                              color: _primary,
                                              bgColor: _primaryLight,
                                              onTap: () {
                                                Navigator.pop(ctx);
                                                _showNilaiForm(
                                                    Map<String,
                                                            dynamic>.from(n));
                                              },
                                            ),
                                            const SizedBox(width: 8),
                                            _SmallBtn(
                                              label: 'Hapus',
                                              icon: LucideIcons.trash2,
                                              color: _errorFg,
                                              bgColor: _errorBg,
                                              onTap: () {
                                                Navigator.pop(ctx);
                                                _deleteNilai(
                                                    n['id'].toString());
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ).animate(delay: (i * 40).ms).fadeIn(duration: 300.ms).slideY(begin: 0.05),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return _buildSkeleton();

    final filteredUsers = _searchQuery.isEmpty
        ? _userList
        : _userList
            .where((u) => (u['nama'] ?? '')
                .toString()
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()))
            .toList();

    final Map<String, List<dynamic>> groupedNilai = {};
    for (var u in filteredUsers) {
      groupedNilai[u['id'].toString()] = [];
    }
    for (var n in _nilaiList) {
      final sId = n['siswa_id']?.toString();
      if (sId != null && groupedNilai.containsKey(sId)) {
        groupedNilai[sId]!.add(n);
      }
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: _NeoFAB(
        label: 'Input Nilai',
        icon: LucideIcons.plusCircle,
        onTap: () => _showNilaiForm(),
      ),
      body: _userList.isEmpty
          ? _buildEmpty()
          : Column(
              children: [
                // Search bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: _white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _ink, width: 2),
                      boxShadow: const [
                        BoxShadow(color: _ink, offset: Offset(4, 4))
                      ],
                    ),
                    child: TextField(
                      onChanged: (val) =>
                          setState(() => _searchQuery = val),
                      style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700, color: _ink),
                      decoration: InputDecoration(
                        hintText: 'Cari nama siswa...',
                        hintStyle:
                            GoogleFonts.inter(color: _inkMuted, fontSize: 15),
                        prefixIcon: const Icon(LucideIcons.search,
                            size: 18, color: _inkMuted),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                      ),
                    ),
                  ).animate().fadeIn().slideY(begin: -0.1),
                ),

                // Stats row
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                  child: Row(
                    children: [
                      _StatChip(
                          label: 'Siswa',
                          value: '${_userList.length}',
                          icon: LucideIcons.users),
                      const SizedBox(width: 10),
                      _StatChip(
                          label: 'Total Nilai',
                          value: '${_nilaiList.length}',
                          icon: LucideIcons.clipboardList),
                    ],
                  ).animate().fadeIn(delay: 100.ms),
                ),

                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _fetchData,
                    color: _primary,
                    child: filteredUsers.isEmpty
                        ? Center(
                            child: Text('Siswa tidak ditemukan.',
                                style: GoogleFonts.inter(
                                    color: _inkMuted,
                                    fontWeight: FontWeight.w600)))
                        : LayoutBuilder(
                            builder: (ctx, c) {
                              final w = c.maxWidth;
                              final crossCount = w >= 900
                                  ? 3
                                  : (w >= 600 ? 2 : 1);

                              return GridView.builder(
                                padding: const EdgeInsets.fromLTRB(
                                    20, 0, 20, 100),
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: crossCount,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                  childAspectRatio:
                                      crossCount == 1 ? 2.4 : 1.5,
                                ),
                                itemCount: filteredUsers.length,
                                itemBuilder: (_, i) {
                                  final siswa = filteredUsers[i];
                                  final sId = siswa['id'].toString();
                                  final nList = groupedNilai[sId] ?? [];
                                  double avg = 0;
                                  if (nList.isNotEmpty) {
                                    avg = nList.fold(
                                            0.0,
                                            (s, n) =>
                                                s +
                                                (double.tryParse(
                                                        n['nilai'].toString()) ??
                                                    0)) /
                                        nList.length;
                                  }

                                  return _RekapCard(
                                    siswa: siswa,
                                    avg: avg,
                                    count: nList.length,
                                    onTap: () =>
                                        _showStudentDetail(siswa, nList),
                                  )
                                      .animate(delay: (i * 35).ms)
                                      .fadeIn(duration: 350.ms)
                                      .slideY(
                                          begin: 0.1,
                                          curve: Curves.easeOutQuart);
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

  Widget _buildEmpty() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: _white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _ink, width: 2),
          boxShadow: const [BoxShadow(color: _ink, offset: Offset(4, 4))],
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: _primaryLight,
              shape: BoxShape.circle,
              border: Border.all(color: _ink, width: 2),
            ),
            child: const Icon(LucideIcons.users, color: _primary, size: 30),
          ),
          const SizedBox(height: 16),
          Text('Belum ada siswa\ndi kelas ini.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800, fontSize: 20, color: _ink)),
        ]),
      ),
    );
  }

  Widget _buildSkeleton() {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 52,
              decoration: BoxDecoration(
                color: _white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _ink, width: 2),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                childAspectRatio: 1.5,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: List.generate(
                    6,
                    (_) => Container(
                          decoration: BoxDecoration(
                            color: _white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: _ink, width: 2),
                          ),
                        )),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Rekap Card ────────────────────────────────────────────────────────────────
class _RekapCard extends StatefulWidget {
  final dynamic siswa;
  final double avg;
  final int count;
  final VoidCallback onTap;

  const _RekapCard({
    required this.siswa,
    required this.avg,
    required this.count,
    required this.onTap,
  });

  @override
  State<_RekapCard> createState() => _RekapCardState();
}

class _RekapCardState extends State<_RekapCard> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final hasData = widget.count > 0;
    final accent = hasData ? _scoreColor(widget.avg) : _inkMuted;
    final accentBg = hasData ? _scoreBg(widget.avg) : const Color(0xFFF0F4F8);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          transform: Matrix4.translationValues(
            _isPressed ? 2 : (_isHovered ? -2 : 0),
            _isPressed ? 2 : (_isHovered ? -2 : 0),
            0,
          ),
          decoration: BoxDecoration(
            color: _white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _ink, width: 2),
            boxShadow: [
              BoxShadow(
                color: _ink,
                offset: _isPressed
                    ? const Offset(2, 2)
                    : (_isHovered ? const Offset(6, 6) : const Offset(4, 4)),
              )
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Nama siswa + icon
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _primaryLight,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _ink, width: 2),
                    ),
                    child:
                        const Icon(LucideIcons.user, color: _primary, size: 14),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.siswa['nama'] ?? '-',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: _ink,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(LucideIcons.chevronRight,
                      size: 16, color: _inkMuted),
                ],
              ),

              // Score + count
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        hasData ? widget.avg.toStringAsFixed(1) : '-',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w900,
                          fontSize: 36,
                          color: accent,
                          letterSpacing: -1,
                          height: 1,
                        ),
                      ),
                      if (hasData)
                        Text(' rata-rata',
                            style: GoogleFonts.inter(
                                fontSize: 11,
                                color: _inkMuted,
                                fontWeight: FontWeight.w500)),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: accentBg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _ink, width: 1.5),
                    ),
                    child: Text(
                      hasData ? '${widget.count} NILAI' : 'BELUM ADA',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w900,
                        fontSize: 11,
                        color: accent,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Small action button ───────────────────────────────────────────────────────
class _SmallBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final VoidCallback onTap;

  const _SmallBtn(
      {required this.label,
      required this.icon,
      required this.color,
      required this.bgColor,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _ink, width: 1.5),
          boxShadow: const [BoxShadow(color: _ink, offset: Offset(2, 2))],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 5),
            Text(label,
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.w800, fontSize: 12, color: color)),
          ],
        ),
      ),
    );
  }
}

// ── Neo FAB ───────────────────────────────────────────────────────────────────
class _NeoFAB extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _NeoFAB(
      {required this.label, required this.icon, required this.onTap});

  @override
  State<_NeoFAB> createState() => _NeoFABState();
}

class _NeoFABState extends State<_NeoFAB> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        transform: Matrix4.translationValues(
            _isPressed ? 2 : 0, _isPressed ? 2 : 0, 0),
        padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: _primary,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _ink, width: 2),
          boxShadow: _isPressed
              ? const [BoxShadow(color: _ink, offset: Offset(2, 2))]
              : const [BoxShadow(color: _ink, offset: Offset(4, 4))],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(widget.icon, color: _white, size: 18),
            const SizedBox(width: 10),
            Text(widget.label,
                style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: _white)),
          ],
        ),
      ),
    );
  }
}

// ── Stat chip ─────────────────────────────────────────────────────────────────
class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatChip(
      {required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: _primaryLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _ink, width: 2),
        boxShadow: const [BoxShadow(color: _ink, offset: Offset(2, 2))],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: _primary),
          const SizedBox(width: 7),
          Text('$label: ',
              style: GoogleFonts.inter(
                  fontSize: 13, color: _inkMuted, fontWeight: FontWeight.w600)),
          Text(value,
              style: GoogleFonts.inter(
                  fontSize: 13,
                  color: _ink,
                  fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

// ── Neo Button ────────────────────────────────────────────────────────────────
class _NeoBtn extends StatefulWidget {
  final String label;
  final Color bgColor;
  final Color fgColor;
  final IconData? icon;
  final VoidCallback? onTap;

  const _NeoBtn(
      {required this.label,
      required this.bgColor,
      required this.fgColor,
      this.icon,
      this.onTap});

  @override
  State<_NeoBtn> createState() => _NeoBtnState();
}

class _NeoBtnState extends State<_NeoBtn> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) =>
          {if (widget.onTap != null) setState(() => _isPressed = true)},
      onTapUp: (_) =>
          {if (widget.onTap != null) setState(() => _isPressed = false)},
      onTapCancel: () =>
          {if (widget.onTap != null) setState(() => _isPressed = false)},
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        transform: Matrix4.translationValues(
            _isPressed ? 2 : 0, _isPressed ? 2 : 0, 0),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: widget.onTap == null
              ? Colors.grey.shade300
              : widget.bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _ink, width: 2),
          boxShadow: _isPressed || widget.onTap == null
              ? []
              : const [BoxShadow(color: _ink, offset: Offset(3, 3))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (widget.icon != null) ...[
              Icon(widget.icon, color: widget.fgColor, size: 16),
              const SizedBox(width: 8),
            ],
            Text(widget.label,
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    color: widget.fgColor)),
          ],
        ),
      ),
    );
  }
}
