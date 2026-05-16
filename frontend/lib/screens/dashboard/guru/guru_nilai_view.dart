import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../widgets/confirm_delete.dart';
import '../../../widgets/app_shell.dart';
import '../../../config/api_config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:lucide_icons/lucide_icons.dart';

class GuruNilaiView extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String token;
  final dynamic teamData;
  const GuruNilaiView(
      {super.key,
      required this.userData,
      required this.token,
      required this.teamData});

  @override
  State<GuruNilaiView> createState() => _GuruNilaiViewState();
}

class _GuruNilaiViewState extends State<GuruNilaiView> {
  List<dynamic> _nilaiList = [];
  List<dynamic> _userList = [];
  bool _isLoading = true;

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

      final responses = await Future.wait([
        http.get(Uri.parse('$baseUrl/api/nilai'), headers: headers),
        if (kelasId.isNotEmpty)
          http.get(Uri.parse('$baseUrl/api/kelas/$kelasId/members'), headers: headers)
        else
          Future.value(http.Response('[]', 200)),
        http.get(Uri.parse('$baseUrl/api/quizzes?kelasId=$kelasId'), headers: headers),
        http.get(Uri.parse('$baseUrl/api/tugas?kelas_id=$kelasId'), headers: headers),
      ]);
      
      List<dynamic> allNilai = [];

      // Parse Tugas to filter assignments by this class
      final Map<String, String> tugasMap = {};
      if (responses[3].statusCode == 200) {
        final decTugas = jsonDecode(responses[3].body);
        final listTugas = decTugas is List ? decTugas : [];
        for (var t in listTugas) {
          if (t['kelas_id']?.toString() == kelasId || t['kelas'] == widget.teamData['nama_kelas']) {
            tugasMap[t['id'].toString()] = t['judul'] ?? 'Tugas';
          }
        }
      }

      // 1. Parse Nilai Manual (Lainnya) & Tugas (Assignment)
      if (responses[0].statusCode == 200) {
        final dec = jsonDecode(responses[0].body);
        List data = dec is List ? dec : [];
        
        for (var n in data) {
          if (n['guru_id'].toString() != widget.userData['id'].toString()) continue;

          if (n['tugas_id'] != null) {
            // Assignment: Only include if the tugas belongs to this class
            final tId = n['tugas_id'].toString();
            if (tugasMap.containsKey(tId)) {
              n['tipe'] = 'Assignment';
              n['isManual'] = false;
              n['mapel'] = tugasMap[tId] ?? n['tugas_judul'] ?? n['mapel'] ?? 'Tugas';
              n['tanggal'] = n['waktu_dinilai'] ?? n['tanggal'];
              allNilai.add(n);
            }
          } else {
            // Manual Grade: Only include if kelas_id matches
            if (kelasId.isNotEmpty && n['kelas_id']?.toString() == kelasId) {
              n['tipe'] = n['tipe'] ?? 'Lainnya'; // Enforce type
              n['isManual'] = true;
              allNilai.add(n);
            } else if (kelasId.isEmpty) {
              n['tipe'] = n['tipe'] ?? 'Lainnya';
              n['isManual'] = true;
              allNilai.add(n);
            }
          }
        }
      }

      // 2. Parse Quiz Submissions
      if (responses[2].statusCode == 200) {
        final decQuiz = jsonDecode(responses[2].body);
        final listQuiz = decQuiz['data'] is List ? decQuiz['data'] : [];
        
        if (listQuiz.isNotEmpty) {
          final quizReqs = listQuiz.map((q) => http.get(Uri.parse('$baseUrl/api/quizzes/${q['_id']}/submissions'), headers: headers));
          final quizResps = await Future.wait(quizReqs);
          
          for (int i = 0; i < listQuiz.length; i++) {
            final q = listQuiz[i];
            final r = quizResps[i];
            if (r.statusCode == 200) {
              final subDec = jsonDecode(r.body);
              final subs = subDec['data'] is List ? subDec['data'] : [];
              for (var s in subs) {
                final score = s['score'] ?? 0;
                final total = s['totalPoints'] ?? 100;
                final finalScore = total > 0 ? (score / total) * 100 : 0;
                allNilai.add({
                  'id': s['_id'],
                  'siswa_id': s['studentId'],
                  'mapel': q['title'] ?? 'Kuis',
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

      // Sort all from newest to oldest
      allNilai.sort((a, b) {
        final dA = DateTime.tryParse(a['tanggal']?.toString() ?? '') ?? DateTime(2000);
        final dB = DateTime.tryParse(b['tanggal']?.toString() ?? '') ?? DateTime(2000);
        return dB.compareTo(dA);
      });
      
      _nilaiList = allNilai;

      // Parse Users (Class Members)
      if (responses[1].statusCode == 200) {
        final dec = jsonDecode(responses[1].body);
        List users = dec is List ? dec : [];
        _userList = users.toList();
      }
    } catch (e) {
      debugPrint('Error: $e');
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
        if (mounted) Navigator.pop(context); // Close detail dialog if open
      } catch (e) {
        debugPrint('Error: $e');
      }
    }
  }

  void _showNilaiForm([Map<String, dynamic>? nilai]) {
    final isEditing = nilai != null;
    String? selectedSiswaId = isEditing ? nilai['siswa_id'].toString() : null;
    final mapelCtrl = TextEditingController(
        text: isEditing ? nilai['mapel'] : widget.userData['kelas'] ?? '');
    final nilaiCtrl = TextEditingController(
        text: isEditing ? nilai['nilai']?.toString() : '');
    final keteranganCtrl =
        TextEditingController(text: isEditing ? nilai['keterangan'] : '');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(isEditing ? 'Edit Nilai' : 'Input Nilai Siswa',
              style: const TextStyle(fontWeight: FontWeight.w900)),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: selectedSiswaId,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'Pilih Siswa',
                      prefixIcon: const Icon(LucideIcons.user),
                      fillColor:
                          Theme.of(context).colorScheme.surface.withAlpha(50),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                    ),
                    hint: const Text('Pilih siswa...'),
                    items: _userList.map<DropdownMenuItem<String>>((u) {
                      return DropdownMenuItem<String>(
                          value: u['id'].toString(),
                          child: Text(u['nama'] ?? '-'));
                    }).toList(),
                    onChanged: (val) =>
                        setDialogState(() => selectedSiswaId = val),
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                      controller: mapelCtrl,
                      labelText: 'Judul / Topik',
                      prefixIcon: LucideIcons.bookOpen),
                  const SizedBox(height: 16),
                  AppTextField(
                      controller: nilaiCtrl,
                      labelText: 'Nilai (0-100)',
                      prefixIcon: LucideIcons.award,
                      keyboardType: TextInputType.number),
                  const SizedBox(height: 16),
                  AppTextField(
                      controller: keteranganCtrl,
                      labelText: 'Keterangan / Catatan',
                      prefixIcon: LucideIcons.messageSquare,
                      keyboardType: TextInputType.multiline),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Batal')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              onPressed: () async {
                if (selectedSiswaId == null || nilaiCtrl.text.isEmpty) return;
                final siswa = _userList
                    .firstWhere((u) => u['id'].toString() == selectedSiswaId);
                
                final body = {
                  'siswa_id': selectedSiswaId,
                  'siswa_nama': siswa['nama'],
                  'mapel': mapelCtrl.text,
                  'nilai': double.tryParse(nilaiCtrl.text) ?? 0,
                  'keterangan': keteranganCtrl.text,
                  'tipe': 'Lainnya',
                  'guru_id': widget.userData['id'],
                  'kelas_id': widget.teamData['id'],
                  if (!isEditing) 'tanggal': DateTime.now().toIso8601String(),
                };

                final url = isEditing
                    ? '$baseUrl/api/nilai/${nilai['id']}'
                    : '$baseUrl/api/nilai';
                final response = await (isEditing
                    ? http.put(Uri.parse(url),
                        headers: {
                          'Content-Type': 'application/json',
                          'Authorization': 'Bearer ${widget.token}'
                        },
                        body: jsonEncode(body))
                    : http.post(Uri.parse(url),
                        headers: {
                          'Content-Type': 'application/json',
                          'Authorization': 'Bearer ${widget.token}'
                        },
                        body: jsonEncode(body)));

                if (response.statusCode == 200 || response.statusCode == 201) {
                  if (ctx.mounted) Navigator.pop(ctx);
                  _fetchData();
                }
              },
              child: Text(isEditing ? 'Simpan' : 'Simpan Nilai',
                  style: const TextStyle(fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateStr(String raw) {
    try {
      final dt = DateTime.parse(raw);
      final listHari = ['Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];
      final listBulan = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
      
      final hari = listHari[dt.weekday % 7];
      final tanggal = dt.day;
      final bulan = listBulan[dt.month - 1];
      final tahun = dt.year;
      final jam = dt.hour.toString().padLeft(2, '0');
      final menit = dt.minute.toString().padLeft(2, '0');
      
      return '$hari, $tanggal $bulan $tahun, $jam:$menit';
    } catch (_) {
      return raw;
    }
  }

  void _showStudentDetail(dynamic siswa, List<dynamic> nilaiSiswa) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        
        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E2C) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: theme.dividerColor.withAlpha(50))),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: theme.primaryColor.withAlpha(30),
                      radius: 24,
                      child: Icon(LucideIcons.user, color: theme.primaryColor),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(siswa['nama'] ?? '-', style: GoogleFonts.poppins(fontWeight: FontWeight.w800, fontSize: 18)),
                          const SizedBox(height: 2),
                          Text('Detail Nilai Siswa', style: TextStyle(color: theme.textTheme.bodySmall?.color, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.x, size: 28),
                      onPressed: () => Navigator.pop(ctx),
                    )
                  ],
                ),
              ),
              // List Nilai
              Expanded(
                child: nilaiSiswa.isEmpty
                    ? Center(child: Text('Belum ada nilai yang diinput.', style: TextStyle(color: theme.colorScheme.onSurface.withAlpha(150))))
                    : ListView.separated(
                        padding: const EdgeInsets.all(24),
                        itemCount: nilaiSiswa.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 16),
                        itemBuilder: (ctx, i) {
                          final n = nilaiSiswa[i];
                          final val = double.tryParse(n['nilai'].toString()) ?? 0;
                          final tipe = n['tipe'] ?? 'Lainnya';
                          
                          IconData iconData = LucideIcons.fileText;
                          Color colorStart = theme.colorScheme.primary;
                          Color colorEnd = const Color(0xFF818CF8);
                          
                          if (tipe == 'Kuis') {
                            iconData = LucideIcons.helpCircle;
                            colorStart = const Color(0xFFF59E0B);
                            colorEnd = const Color(0xFFFBBF24);
                          } else if (tipe == 'Assignment') {
                            iconData = LucideIcons.clipboardList;
                            colorStart = const Color(0xFF10B981);
                            colorEnd = const Color(0xFF34D399);
                          } else {
                            colorStart = const Color(0xFF6366F1); // Indigo for Lainnya
                            colorEnd = const Color(0xFF818CF8);
                          }
                          
                          String dateStr = '';
                          if (n['tanggal'] != null) {
                            dateStr = _formatDateStr(n['tanggal']);
                          }
                          
                          final colorScore = val >= 80 ? const Color(0xFF10B981) : (val >= 60 ? const Color(0xFFF59E0B) : const Color(0xFFEF4444));

                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E1E2C) : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: colorStart.withAlpha(isDark ? 55 : 35)),
                              boxShadow: [
                                BoxShadow(color: colorStart.withAlpha(isDark ? 30 : 12), blurRadius: 18, offset: const Offset(0, 6)),
                                BoxShadow(color: Colors.black.withAlpha(isDark ? 60 : 8), blurRadius: 14, offset: const Offset(0, 4)),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // ── Top band ──
                                Container(
                                  padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(colors: [
                                      colorStart.withAlpha(isDark ? 45 : 28),
                                      colorEnd.withAlpha(isDark ? 20 : 10),
                                    ]),
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(19)),
                                    border: Border(bottom: BorderSide(color: colorStart.withAlpha(isDark ? 40 : 25))),
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      // Icon box
                                      Container(
                                        padding: const EdgeInsets.all(9),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(colors: [colorStart, colorEnd], begin: Alignment.topLeft, end: Alignment.bottomRight),
                                          borderRadius: BorderRadius.circular(11),
                                          boxShadow: [BoxShadow(color: colorStart.withAlpha(100), blurRadius: 10, offset: const Offset(0, 4))],
                                        ),
                                        child: Icon(iconData, color: Colors.white, size: 16),
                                      ),
                                      const SizedBox(width: 12),
                                      // Category & Title
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: colorStart.withAlpha(isDark ? 40 : 22),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(tipe.toUpperCase(),
                                                  style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.w800, color: colorStart, letterSpacing: 0.8)),
                                            ),
                                            const SizedBox(height: 3),
                                            Text(n['mapel'] ?? '-',
                                                style: GoogleFonts.poppins(fontWeight: FontWeight.w800, fontSize: 14, letterSpacing: -0.3,
                                                    color: isDark ? Colors.white : const Color(0xFF1E293B)),
                                                maxLines: 2, overflow: TextOverflow.ellipsis),
                                          ],
                                        ),
                                      ),
                                      // Date
                                      if (dateStr.isNotEmpty) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: colorStart.withAlpha(isDark ? 35 : 20),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(dateStr, style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w700, color: colorStart)),
                                        ),
                                      ],
                                    ]
                                  )
                                ),
                                
                                // ── Body ──
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.baseline,
                                        textBaseline: TextBaseline.alphabetic,
                                        children: [
                                          Text('Skor:', style: GoogleFonts.poppins(fontSize: 13, color: isDark ? Colors.white70 : Colors.black54)),
                                          const SizedBox(width: 8),
                                          Text(val.toStringAsFixed(0), style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w900, color: colorScore)),
                                          const Text(' / 100', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey)),
                                        ],
                                      ),
                                      if (n['keterangan'] != null && n['keterangan'].toString().isNotEmpty) ...[
                                        const SizedBox(height: 8),
                                        Text('${n['keterangan']}',
                                            style: GoogleFonts.poppins(fontSize: 13, height: 1.7,
                                                color: isDark ? Colors.white60 : Colors.black87),
                                            maxLines: 4, overflow: TextOverflow.ellipsis),
                                      ],
                                      
                                      if (n['isManual'] == true) ...[
                                        const SizedBox(height: 12),
                                        Divider(height: 1, color: isDark ? Colors.white10 : Colors.black12),
                                        const SizedBox(height: 12),
                                        Row(
                                          children: [
                                            Icon(LucideIcons.user, size: 14, color: colorStart.withAlpha(200)),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text('Input Manual', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: colorStart)),
                                            ),
                                            InkWell(
                                              onTap: () {
                                                Navigator.pop(ctx); 
                                                _showNilaiForm(n);
                                              },
                                              borderRadius: BorderRadius.circular(8),
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                decoration: BoxDecoration(
                                                  color: colorStart.withAlpha(25),
                                                  borderRadius: BorderRadius.circular(8),
                                                  border: Border.all(color: colorStart.withAlpha(50)),
                                                ),
                                                child: Row(
                                                  children: [
                                                    Icon(LucideIcons.edit2, size: 12, color: colorStart),
                                                    const SizedBox(width: 4),
                                                    Text('Edit', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w700, color: colorStart)),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            InkWell(
                                              onTap: () {
                                                Navigator.pop(ctx);
                                                _deleteNilai(n['id'].toString());
                                              },
                                              borderRadius: BorderRadius.circular(8),
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                decoration: BoxDecoration(
                                                  color: Colors.red.withAlpha(25),
                                                  borderRadius: BorderRadius.circular(8),
                                                  border: Border.all(color: Colors.red.withAlpha(50)),
                                                ),
                                                child: Row(
                                                  children: [
                                                    const Icon(LucideIcons.trash, size: 12, color: Colors.red),
                                                    const SizedBox(width: 4),
                                                    Text('Hapus', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.red)),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ]
                                        )
                                      ]
                                    ]
                                  )
                                )
                              ]
                            )
                          );
                        },
                      ),
              )
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return AppShell(child: _buildSkeleton());
    }

    // Grouping by student
    final Map<String, List<dynamic>> groupedNilai = {};
    for (var u in _userList) {
      groupedNilai[u['id'].toString()] = [];
    }
    for (var n in _nilaiList) {
      final sId = n['siswa_id']?.toString();
      if (sId != null && groupedNilai.containsKey(sId)) {
        groupedNilai[sId]!.add(n);
      }
    }

    return AppShell(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        floatingActionButton: AppFAB(
          onPressed: () => _showNilaiForm(),
          icon: LucideIcons.lineChart,
          label: 'Input Nilai',
        ),
        body: _userList.isEmpty
            ? const EmptyState(
                icon: LucideIcons.users,
                message: 'Belum ada siswa\ndi kelas ini.',
                color: Color(0xFF10B981))
            : RefreshIndicator(
                onRefresh: _fetchData,
                child: LayoutBuilder(
                  builder: (ctx, c) {
                    final w = c.maxWidth;
                    final padding = Breakpoints.screenPadding(w);
                    final crossCount = w >= Breakpoints.tablet
                        ? 3
                        : (w >= Breakpoints.mobile ? 2 : 1);

                    return GridView.builder(
                      padding: padding,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossCount,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: crossCount == 1 ? 2.5 : 1.8,
                      ),
                      itemCount: _userList.length,
                      itemBuilder: (_, i) {
                        final siswa = _userList[i];
                        final sId = siswa['id'].toString();
                        final nList = groupedNilai[sId] ?? [];
                        
                        double avg = 0;
                        if (nList.isNotEmpty) {
                          double sum = 0;
                          for (var n in nList) {
                            sum += double.tryParse(n['nilai'].toString()) ?? 0;
                          }
                          avg = sum / nList.length;
                        }

                        return _GuruRekapCard(
                          siswa: siswa,
                          avg: avg,
                          count: nList.length,
                          onTap: () => _showStudentDetail(siswa, nList),
                        )
                            .animate(delay: (i * 30).ms)
                            .fadeIn(duration: 400.ms)
                            .slideY(begin: 0.1, curve: Curves.easeOutQuart);
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

class _GuruRekapCard extends StatelessWidget {
  final dynamic siswa;
  final double avg;
  final int count;
  final VoidCallback onTap;

  const _GuruRekapCard(
      {required this.siswa, required this.avg, required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = avg >= 80
        ? const Color(0xFF10B981)
        : (avg >= 60 ? const Color(0xFFF59E0B) : const Color(0xFFEF4444));
    
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
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
                    decoration: BoxDecoration(
                        color: theme.primaryColor.withAlpha(isDark ? 40 : 25), shape: BoxShape.circle),
                    child: Icon(LucideIcons.user, color: theme.primaryColor, size: 16)),
                const SizedBox(width: 10),
                Expanded(
                    child: Text(siswa['nama'] ?? '-',
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w800, fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis)),
                Icon(LucideIcons.chevronRight, size: 18, color: theme.colorScheme.onSurface.withAlpha(100))
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(count == 0 ? '-' : avg.toStringAsFixed(1),
                        style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: count == 0 ? theme.disabledColor : color,
                            letterSpacing: -1)),
                    if (count > 0)
                      Padding(
                          padding: const EdgeInsets.only(bottom: 6, left: 4),
                          child: Text('avg',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: theme.colorScheme.onSurface.withAlpha(120)))),
                  ],
                ),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: count == 0 ? theme.disabledColor.withAlpha(30) : color.withAlpha(20),
                    borderRadius: BorderRadius.circular(8)
                  ),
                  child: Text(count == 0 ? 'Belum ada nilai' : '$count Entri Nilai',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: count == 0 ? theme.disabledColor : color)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
