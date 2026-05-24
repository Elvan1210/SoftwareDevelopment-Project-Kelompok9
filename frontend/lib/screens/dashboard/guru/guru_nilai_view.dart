import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../widgets/confirm_delete.dart';
import '../../../widgets/app_shell.dart';
import '../../../config/theme.dart';
import '../../../config/api_config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../widgets/neo_brutalism.dart';

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

      if (responses[0].statusCode == 200) {
        final dec = jsonDecode(responses[0].body);
        List data = dec is List ? dec : [];
        
        for (var n in data) {
          if (n['guru_id'].toString() != widget.userData['id'].toString()) continue;

          if (n['tugas_id'] != null) {
            final tId = n['tugas_id'].toString();
            if (tugasMap.containsKey(tId)) {
              n['tipe'] = 'Assignment';
              n['isManual'] = false;
              n['mapel'] = tugasMap[tId] ?? n['tugas_judul'] ?? n['mapel'] ?? 'Tugas';
              n['tanggal'] = n['waktu_dinilai'] ?? n['tanggal'];
              allNilai.add(n);
            }
          } else {
            if (kelasId.isNotEmpty && n['kelas_id']?.toString() == kelasId) {
              n['tipe'] = n['tipe'] ?? 'Lainnya';
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

      if (responses[2].statusCode == 200) {
        final decQuiz = jsonDecode(responses[2].body);
        final listQuiz = decQuiz['data'] is List ? decQuiz['data'] : [];
        
        if (listQuiz.isNotEmpty) {
          final quizReqs = listQuiz.map((q) => http.get(Uri.parse('$baseUrl/api/quiz/${q['_id']}/submissions'), headers: headers));
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
        if (mounted) Navigator.pop(context);
      } catch (e) {
        debugPrint('Error: $e');
      }
    }
  }

  void _showNilaiForm([Map<String, dynamic>? nilai]) {
    final isEditing = nilai != null;
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
          backgroundColor: Theme.of(context).colorScheme.surface,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
            side: BorderSide(color: Theme.of(context).dividerColor, width: 1.2),
          ),
          title: Text(
            isEditing ? 'Edit Nilai' : 'Input Nilai Siswa',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900, color: isDark ? Colors.white : AppTheme.textLight),
          ),
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
                    dropdownColor: Theme.of(context).colorScheme.surface,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : AppTheme.textLight),
                    decoration: InputDecoration(
                      labelText: 'Pilih Siswa',
                      labelStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                      prefixIcon: Icon(LucideIcons.user, size: 18, color: isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.zero,
                        borderSide: BorderSide(color: Theme.of(context).dividerColor, width: 1.2),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.zero,
                        borderSide: BorderSide(color: Theme.of(context).dividerColor, width: 1.2),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderRadius: BorderRadius.zero,
                        borderSide: BorderSide(color: AppTheme.indigoPrimary, width: 2),
                      ),
                    ),
                    hint: Text('Pilih siswa...', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt)),
                    items: _userList.map<DropdownMenuItem<String>>((u) {
                      return DropdownMenuItem<String>(
                        value: u['id'].toString(),
                        child: Text(u['nama'] ?? '-'),
                      );
                    }).toList(),
                    onChanged: (val) => setDialogState(() => selectedSiswaId = val),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  _buildFormInput('Judul / Topik', mapelCtrl, LucideIcons.bookOpen, isDark),
                  
                  const SizedBox(height: 16),
                  
                  _buildFormInput('Nilai (0-100)', nilaiCtrl, LucideIcons.award, isDark, isNumber: true),
                  
                  const SizedBox(height: 16),
                  
                  _buildFormInput('Keterangan / Catatan', keteranganCtrl, LucideIcons.messageSquare, isDark, isMultiLine: true),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Batal',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt,
                ),
              ),
            ),
            GestureDetector(
              onTap: () async {
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
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: const BoxDecoration(
                  color: AppTheme.indigoPrimary,
                ),
                child: Text(
                  isEditing ? 'SIMPAN' : 'SIMPAN NILAI',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w900, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormInput(
    String label,
    TextEditingController ctrl,
    IconData icon,
    bool isDark, {
    bool isNumber = false,
    bool isMultiLine = false,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: isNumber ? TextInputType.number : (isMultiLine ? TextInputType.multiline : TextInputType.text),
      maxLines: isMultiLine ? 3 : 1,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700,
        color: isDark ? Colors.white : AppTheme.textLight),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
        prefixIcon: Icon(icon, size: 18, color: isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: Theme.of(context).dividerColor, width: 1.2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: Theme.of(context).dividerColor, width: 1.2),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: AppTheme.indigoPrimary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
    String activeFilter = 'Semua';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final filteredNilai = activeFilter == 'Semua' 
              ? nilaiSiswa 
              : nilaiSiswa.where((n) {
                  final tipe = n['tipe'] ?? 'Lainnya';
                  return tipe == activeFilter;
                }).toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.zero),
                border: Border(
                  top: BorderSide(color: Theme.of(context).dividerColor, width: 1.5),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: AppTheme.indigoPrimary.withAlpha(20),
                          radius: 24,
                          child: const Icon(LucideIcons.user, color: AppTheme.indigoPrimary),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                siswa['nama'] ?? '-', 
                                style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900, color: isDark ? Colors.white : AppTheme.textLight),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Rekapitulasi Nilai Siswa', 
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt, 
                                  fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(LucideIcons.x, size: 24, color: isDark ? Colors.white : AppTheme.textLight),
                          onPressed: () => Navigator.pop(ctx),
                        )
                      ],
                    ),
                  ),
                  
                  Container(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                    height: 56,
                    child: ListView(
                      clipBehavior: Clip.none,
                      scrollDirection: Axis.horizontal,
                      children: ['Semua', 'Assignment', 'Kuis', 'Lainnya'].map((k) {
                        final selected = activeFilter == k;
                        Color colorStart = AppTheme.indigoPrimary;
                        Color colorEnd = const Color(0xFF818CF8);
                        IconData icon = LucideIcons.layoutGrid;

                        if (k == 'Kuis') {
                          icon = LucideIcons.helpCircle;
                          colorStart = const Color(0xFFF59E0B);
                          colorEnd = const Color(0xFFFBBF24);
                        } else if (k == 'Assignment') {
                          icon = LucideIcons.clipboardList;
                          colorStart = const Color(0xFF10B981);
                          colorEnd = const Color(0xFF34D399);
                        } else if (k == 'Lainnya') {
                          icon = LucideIcons.fileText;
                          colorStart = const Color(0xFF6366F1);
                          colorEnd = const Color(0xFF818CF8);
                        }
                        
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () => setModalState(() => activeFilter = k),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                gradient: selected ? LinearGradient(colors: [colorStart, colorEnd]) : null,
                                color: selected ? null : (Theme.of(context).colorScheme.surface),
                                borderRadius: BorderRadius.zero,
                                border: Border.all(color: selected ? Colors.transparent : (Theme.of(context).dividerColor)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(icon, size: 13, color: selected ? Colors.white : colorStart),
                                  const SizedBox(width: 6),
                                  Text(
                                    k, 
                                    style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900,
                                      color: selected ? Colors.white : colorStart),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  Expanded(
                    child: filteredNilai.isEmpty
                        ? Center(
                            child: Text(
                              'Belum ada entri nilai.', 
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt,
                                fontWeight: FontWeight.bold),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(24),
                            itemCount: filteredNilai.length,
                            itemBuilder: (ctx, i) {
                              final n = filteredNilai[i];
                              final val = double.tryParse(n['nilai'].toString()) ?? 0;
                              final tipe = n['tipe'] ?? 'Lainnya';
                              
                              IconData iconData = LucideIcons.fileText;
                              Color colorStart = AppTheme.indigoPrimary;
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
                                colorStart = const Color(0xFF6366F1);
                                colorEnd = const Color(0xFF818CF8);
                              }
                              
                              String dateStr = '';
                              if (n['tanggal'] != null) {
                                dateStr = _formatDateStr(n['tanggal']);
                              }
                              
                              final colorScore = val >= 80 ? const Color(0xFF10B981) : (val >= 60 ? const Color(0xFFF59E0B) : const Color(0xFFEF4444));

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: NeoCard(
                                  color: Theme.of(context).colorScheme.surface,
                                  borderColor: colorStart,
                                  padding: EdgeInsets.zero,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
                                        decoration: BoxDecoration(
                                          color: colorStart.withAlpha(isDark ? 40 : 25),
                                          border: Border(bottom: BorderSide(color: colorStart, width: 2)),
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(colors: [colorStart, colorEnd]),
                                                borderRadius: BorderRadius.zero,
                                              ),
                                              child: Icon(iconData, color: Colors.white, size: 14),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: colorStart.withAlpha(isDark ? 30 : 15),
                                                      borderRadius: BorderRadius.zero,
                                                    ),
                                                    child: Text(
                                                      tipe.toUpperCase(),
                                                      style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w900, 
                                                        color: colorStart, 
                                                        letterSpacing: 0.5),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    n['mapel'] ?? '-',
                                                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w800, 
                                                      color: isDark ? Colors.white : AppTheme.textLight),
                                                    maxLines: 1, 
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ],
                                              ),
                                            ),
                                            if (dateStr.isNotEmpty) ...[
                                              const SizedBox(width: 8),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: colorStart.withAlpha(20),
                                                  borderRadius: BorderRadius.zero,
                                                ),
                                                child: Text(
                                                  dateStr, 
                                                  style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w800, 
                                                    color: colorStart),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      
                                      Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              crossAxisAlignment: CrossAxisAlignment.baseline,
                                              textBaseline: TextBaseline.alphabetic,
                                              children: [
                                                Text(
                                                  'Skor:', 
                                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold,
                                                    color: isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt),
                                                ),
                                                const SizedBox(width: 6),
                                                Text(
                                                  val.toStringAsFixed(0), 
                                                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w900, 
                                                    color: colorScore),
                                                ),
                                                Text(
                                                  ' / 100', 
                                                  style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold,
                                                    color: isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt),
                                                ),
                                              ],
                                            ),
                                            if (n['keterangan'] != null && n['keterangan'].toString().isNotEmpty) ...[
                                              const SizedBox(height: 6),
                                              Text(
                                                '${n['keterangan']}',
                                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600,
                                                  color: isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt),
                                                maxLines: 2, 
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                            
                                            if (n['isManual'] == true) ...[
                                              const SizedBox(height: 12),
                                              Divider(height: 1, color: Theme.of(context).dividerColor),
                                              const SizedBox(height: 12),
                                              Row(
                                                children: [
                                                  Icon(LucideIcons.pencil, size: 12, color: colorStart),
                                                  const SizedBox(width: 6),
                                                  Expanded(
                                                    child: Text(
                                                      'Input Manual', 
                                                      style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800, 
                                                        color: colorStart),
                                                    ),
                                                  ),
                                                  InkWell(
                                                    onTap: () {
                                                      Navigator.pop(ctx); 
                                                      _showNilaiForm(n);
                                                    },
                                                    borderRadius: BorderRadius.zero,
                                                    child: Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                                      decoration: BoxDecoration(
                                                        color: colorStart.withAlpha(20),
                                                        borderRadius: BorderRadius.zero,
                                                        border: Border.all(color: colorStart.withAlpha(50)),
                                                      ),
                                                      child: Row(
                                                        children: [
                                                          Icon(LucideIcons.edit3, size: 11, color: colorStart),
                                                          const SizedBox(width: 4),
                                                          Text(
                                                            'Edit', 
                                                            style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w900, color: colorStart),
                                                          ),
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
                                                    borderRadius: BorderRadius.zero,
                                                    child: Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                                      decoration: BoxDecoration(
                                                        color: AppTheme.error.withAlpha(20),
                                                        borderRadius: BorderRadius.zero,
                                                        border: Border.all(color: AppTheme.error.withAlpha(50)),
                                                      ),
                                                      child: Row(
                                                        children: [
                                                          const Icon(LucideIcons.trash2, size: 11, color: AppTheme.error),
                                                          const SizedBox(width: 4),
                                                          Text(
                                                            'Hapus', 
                                                            style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w900, color: AppTheme.error),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return AppShell(child: _buildSkeleton());
    }

    final filteredUsers = _searchQuery.isEmpty 
      ? _userList 
      : _userList.where((u) => (u['nama'] ?? '').toString().toLowerCase().contains(_searchQuery.toLowerCase())).toList();

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

    return AppShell(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showNilaiForm(),
          backgroundColor: AppTheme.indigoPrimary,
          foregroundColor: Colors.white,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          icon: const Icon(LucideIcons.plusCircle, size: 18),
          label: Text('Input Nilai', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w800)),
        ),
        body: _userList.isEmpty
            ? const EmptyState(
                icon: LucideIcons.users,
                message: 'Belum ada siswa\ndi kelas ini.',
                color: Color(0xFF10B981))
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        border: Border.all(color: Theme.of(context).colorScheme.onSurface, width: 2),
                        boxShadow: [BoxShadow(color: Theme.of(context).colorScheme.onSurface, offset: const Offset(4, 4), blurRadius: 0)],
                      ),
                      child: TextField(
                        onChanged: (val) => setState(() => _searchQuery = val),
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppTheme.textLight),
                        decoration: InputDecoration(
                          hintText: 'Cari nama siswa...',
                          hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(color: isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt),
                          prefixIcon: Icon(LucideIcons.search, size: 18, color: isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                      ),
                    ).animate().fadeIn().slideY(begin: -0.1),
                  ),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: _fetchData,
                      child: filteredUsers.isEmpty 
                        ? Center(
                            child: Text(
                              'Siswa tidak ditemukan.', 
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt,
                                fontWeight: FontWeight.bold),
                            ),
                          )
                        : LayoutBuilder(
                            builder: (ctx, c) {
                              final w = c.maxWidth;
                              final padding = Breakpoints.screenPadding(w);
                              final crossCount = w >= Breakpoints.tablet
                                  ? 3
                                  : (w >= Breakpoints.mobile ? 2 : 1);

                              return GridView.builder(
                                padding: padding.copyWith(top: 8, bottom: 100),
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: crossCount,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                  childAspectRatio: crossCount == 1 ? 2.5 : 1.6,
                                ),
                                itemCount: filteredUsers.length,
                                itemBuilder: (_, i) {
                                  final siswa = filteredUsers[i];
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
                ],
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
      children: List.generate(6, (_) => const SkeletonLoader()),
    );
  }
}

class _GuruRekapCard extends StatelessWidget {
  final dynamic siswa;
  final double avg;
  final int count;
  final VoidCallback onTap;

  const _GuruRekapCard({
    required this.siswa,
    required this.avg,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = avg >= 80
        ? const Color(0xFF10B981)
        : (avg >= 60 ? const Color(0xFFF59E0B) : const Color(0xFFEF4444));
    final borderColor = count == 0
        ? Theme.of(context).colorScheme.onSurface
        : color;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border.all(
            color: Theme.of(context).colorScheme.onSurface,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.onSurface,
              offset: const Offset(4, 4),
              blurRadius: 0,
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
                    color: AppTheme.indigoPrimary.withAlpha(20),
                    border: Border.all(color: Theme.of(context).colorScheme.onSurface, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).colorScheme.onSurface,
                        offset: const Offset(2, 2),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: const Icon(LucideIcons.user, color: AppTheme.indigoPrimary, size: 14),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    siswa['nama'] ?? '-',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : AppTheme.textLight,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(LucideIcons.chevronRight, size: 16,
                    color: isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      count == 0 ? '-' : avg.toStringAsFixed(1),
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: count == 0
                            ? (isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt)
                            : borderColor,
                        letterSpacing: -1,
                      ),
                    ),
                    if (count > 0) ...[
                      const SizedBox(width: 4),
                      Text(
                        'rata-rata',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt,
                        ),
                      ),
                    ],
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: count == 0
                        ? Theme.of(context).colorScheme.onSurface.withAlpha(20)
                        : borderColor.withAlpha(20),
                    border: Border.all(
                      color: count == 0
                          ? Theme.of(context).colorScheme.onSurface
                          : borderColor,
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    count == 0 ? 'BELUM ADA' : '$count NILAI',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: count == 0
                          ? (isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt)
                          : borderColor,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
