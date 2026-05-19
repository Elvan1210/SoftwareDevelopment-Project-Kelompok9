import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import '../../../config/api_config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import '../../../services/notifikasi_service.dart';
import '../../../config/theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

class GuruTugasDetailScreen extends StatefulWidget {
  final Map<String, dynamic> tugas;
  final String token;
  const GuruTugasDetailScreen({super.key, required this.tugas, required this.token});

  @override
  State<GuruTugasDetailScreen> createState() => _GuruTugasDetailScreenState();
}

class _GuruTugasDetailScreenState extends State<GuruTugasDetailScreen> {
  bool _isLoading = true;
  List<dynamic> _pengumpulanList = [];
  List<dynamic> _nilaiList = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final headers = {'Authorization': 'Bearer ${widget.token}'};
      final results = await Future.wait([
        http.get(Uri.parse('$baseUrl/api/pengumpulan'), headers: headers),
        http.get(Uri.parse('$baseUrl/api/nilai'), headers: headers),
      ]);

      if (results[0].statusCode == 200 && results[1].statusCode == 200) {
        final decAllPengumpulan = jsonDecode(results[0].body);
        List allPengumpulan = decAllPengumpulan is List ? decAllPengumpulan : [];
        final decAllNilai = jsonDecode(results[1].body);
        List allNilai = decAllNilai is List ? decAllNilai : [];

        setState(() {
          _pengumpulanList = allPengumpulan.where((p) => p['tugas_id'] == widget.tugas['id']).toList();
          _nilaiList = allNilai.where((n) => n['tugas_id'] == widget.tugas['id']).toList();
        });
      }
    } catch (e) {
      debugPrint("Error Fetch Data: $e");
    }
    if (mounted) setState(() => _isLoading = false);
  }

  void _showNilaiDialog(Map<String, dynamic> pengumpulan, Map<String, dynamic>? existingNilai) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final ctrl = TextEditingController(text: existingNilai != null ? existingNilai['nilai'].toString() : '');
    final feedbackCtrl = TextEditingController(text: existingNilai != null ? existingNilai['feedback']?.toString() ?? '' : '');
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF161B27) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: isDark ? const Color(0xFF252D3D) : const Color(0xFFE5E7EB), width: 1.2),
        ),
        title: Text(
          existingNilai != null ? 'Edit Nilai' : 'Beri Nilai',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w900,
            fontSize: 18,
            color: isDark ? Colors.white : AppTheme.textLight,
          ),
        ),
        content: SizedBox(
          width: MediaQuery.of(ctx).size.width * 0.9,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF161D2B) : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isDark ? const Color(0xFF2D3A54) : const Color(0xFFE5E7EB)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: theme.colorScheme.secondary.withAlpha(40),
                      radius: 16,
                      child: Icon(LucideIcons.user, size: 16, color: theme.colorScheme.secondary),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        pengumpulan['siswa_nama'] ?? 'Siswa',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          color: isDark ? Colors.white : AppTheme.textLight,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: ctrl,
                keyboardType: TextInputType.number,
                style: GoogleFonts.plusJakartaSans(fontSize: 13, color: isDark ? Colors.white : AppTheme.textLight, fontWeight: FontWeight.w700),
                decoration: InputDecoration(
                  labelText: 'Nilai (0-100)',
                  labelStyle: GoogleFonts.plusJakartaSans(fontSize: 12, color: isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt, fontWeight: FontWeight.w600),
                  prefixIcon: const Icon(LucideIcons.award, size: 18),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: isDark ? const Color(0xFF252D3D) : const Color(0xFFE5E7EB)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: isDark ? const Color(0xFF252D3D) : const Color(0xFFE5E7EB)),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF161D2B) : const Color(0xFFEEF2FF),
                  border: Border.all(color: isDark ? const Color(0xFF252D3D) : const Color(0xFFE5E7EB)),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: TextField(
                  controller: feedbackCtrl,
                  maxLines: 3,
                  style: GoogleFonts.plusJakartaSans(fontSize: 13, color: isDark ? Colors.white : AppTheme.textLight),
                  decoration: InputDecoration(
                    labelText: 'Komentar / Feedback Opsional',
                    labelStyle: GoogleFonts.plusJakartaSans(fontSize: 12, color: isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt, fontWeight: FontWeight.w600),
                    prefixIcon: const Icon(LucideIcons.messageCircle, size: 18),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Batal',
              style: GoogleFonts.plusJakartaSans(
                color: isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              if (ctrl.text.isEmpty) return;
              final nilaiVal = int.tryParse(ctrl.text) ?? 0;
              
              final body = {
                'siswa_id': pengumpulan['siswa_id'],
                'siswa_nama': pengumpulan['siswa_nama'],
                'guru_id': widget.tugas['guru_id'],
                'guru_nama': widget.tugas['guru_nama'],
                'mapel': widget.tugas['mapel'] ?? widget.tugas['kelas'] ?? 'Umum',
                'tugas_id': widget.tugas['id'],
                'tugas_judul': widget.tugas['judul'],
                'nilai': nilaiVal,
                'feedback': feedbackCtrl.text.trim(),
                'waktu_dinilai': DateTime.now().toIso8601String(),
              };

              final headers = {'Content-Type': 'application/json', 'Authorization': 'Bearer ${widget.token}'};
              
              try {
                if (existingNilai != null) {
                  await http.put(Uri.parse('$baseUrl/api/nilai/${existingNilai['id']}'), headers: headers, body: jsonEncode(body));
                } else {
                  await http.post(Uri.parse('$baseUrl/api/nilai'), headers: headers, body: jsonEncode(body));
                  
                  await http.put(
                    Uri.parse('$baseUrl/api/pengumpulan/${pengumpulan['id']}'), 
                    headers: headers, 
                    body: jsonEncode({
                      ...pengumpulan,
                      'status': 'Dinilai'
                    })
                  );
                  NotifikasiService.kirimNotifikasi(
                    judul: 'Nilai Tugas Keluar!',
                    pesan: 'Tugas "${widget.tugas['judul']}" kamu dapat nilai $nilaiVal dari ${widget.tugas['guru_nama']}',
                    token: widget.token,
                    targetUserId: pengumpulan['siswa_id'],
                  );
                }
                if (ctx.mounted) Navigator.pop(ctx);
                _fetchData(); 
              } catch (e) {
                debugPrint('Error saving nilai: $e');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.secondary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: Text('Simpan', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  String _formatDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      return DateFormat('dd MMM yyyy, HH:mm').format(date);
    } catch (e) {
      return isoDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = theme.colorScheme.secondary;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            'Detail Tugas',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? Colors.white : AppTheme.textLight),
          ),
          leading: IconButton(
            icon: Icon(LucideIcons.arrowLeft, color: isDark ? Colors.white : AppTheme.textLight),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Detail Tugas',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? Colors.white : AppTheme.textLight),
        ),
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: isDark ? Colors.white : AppTheme.textLight),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ==========================================
            // BAGIAN 1: INFORMASI SOAL / TUGAS (DOUBLE-BEZEL CONCENTRIC)
            // ==========================================
            Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E2538) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: accent.withAlpha(isDark ? 55 : 30),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(isDark ? 60 : 8),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF161D2B) : const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(19),
                    border: Border.all(
                      color: isDark ? const Color(0xFF2D3A54) : const Color(0xFFE5E7EB),
                      width: 1.0,
                    ),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: accent.withAlpha(isDark ? 25 : 15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: accent.withAlpha(isDark ? 60 : 40),
                                width: 1.0,
                              ),
                            ),
                            child: Icon(LucideIcons.clipboardList, color: accent, size: 24),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.tugas['judul'] ?? 'Tanpa Judul',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    color: isDark ? Colors.white : AppTheme.textLight,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                if (widget.tugas['deadline'] != null)
                                  Row(
                                    children: [
                                      Icon(
                                        LucideIcons.clock,
                                        size: 13,
                                        color: const Color(0xFFF59E0B).withAlpha(200),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Tenggat: ${_formatDate(widget.tugas['deadline'])}',
                                        style: GoogleFonts.plusJakartaSans(
                                          color: const Color(0xFFF59E0B),
                                          fontWeight: FontWeight.w800,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Divider(color: isDark ? const Color(0xFF2D3A54) : const Color(0xFFE5E7EB), height: 1),
                      const SizedBox(height: 16),
                      Text(
                        'Deskripsi Tugas',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                          color: isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.tugas['deskripsi'] ?? 'Tidak ada deskripsi detail.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          height: 1.5,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white70 : AppTheme.textLight,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ==========================================
            // BAGIAN 2: KARTU LAMPIRAN FILE GURU
            // ==========================================
            if (widget.tugas['link'] != null && widget.tugas['link'].toString().isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(
                'LAMPIRAN MATERI / SOAL',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: isDark ? const Color(0xFF9EAAFF) : const Color(0xFF4C51BF),
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () async {
                  String rawUrl = widget.tugas['link'].toString();
                  if (rawUrl.toLowerCase().contains('.pdf') || rawUrl.contains('/raw/')) {
                    rawUrl = 'https://docs.google.com/viewer?url=${Uri.encodeComponent(rawUrl)}';
                  }
                  final url = Uri.parse(rawUrl);
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  } else {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Gagal membuka file!'))
                      );
                    }
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E2538) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF76AFB8).withAlpha(isDark ? 55 : 30),
                      width: 1.2,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF161D2B) : const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: isDark ? const Color(0xFF2D3A54) : const Color(0xFFE5E7EB),
                          width: 1.0,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF76AFB8).withAlpha(20),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(LucideIcons.fileText, color: Color(0xFF76AFB8), size: 24),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Buka File Lampiran',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                    color: const Color(0xFF76AFB8),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Ketuk untuk mengunduh/melihat',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    color: isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(LucideIcons.externalLink, color: Color(0xFF76AFB8), size: 16),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 32),
            Row(
              children: [
                Text(
                  'STATUS PENGUMPULAN SISWA',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: isDark ? const Color(0xFF9EAAFF) : const Color(0xFF4C51BF),
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Divider(
                    color: isDark ? const Color(0xFF2D3A54) : const Color(0xFFE5E7EB),
                    height: 1,
                    thickness: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (_pengumpulanList.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E2538) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isDark ? const Color(0xFF2D3A54) : const Color(0xFFE5E7EB)),
                ),
                child: Column(
                  children: [
                    Icon(LucideIcons.inbox, color: isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt, size: 36),
                    const SizedBox(height: 12),
                    Text(
                      'Belum ada siswa yang mengumpulkan tugas ini.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        color: isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _pengumpulanList.length,
                itemBuilder: (context, index) {
                  final p = _pengumpulanList[index];
                  final List<dynamic> files = p['files'] ?? [];
                  
                  Map<String, dynamic>? existingNilai;
                  try {
                    existingNilai = _nilaiList.firstWhere((n) => n['siswa_id'] == p['siswa_id'] && n['tugas_id'] == widget.tugas['id']);
                  } catch (e) {
                    existingNilai = null;
                  }

                  final isGraded = existingNilai != null;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E2538) : Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: (isGraded ? Colors.green : accent).withAlpha(isDark ? 55 : 30),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(isDark ? 60 : 8),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF161D2B) : const Color(0xFFEEF2FF),
                          borderRadius: BorderRadius.circular(19),
                          border: Border.all(
                            color: isDark ? const Color(0xFF2D3A54) : const Color(0xFFE5E7EB),
                            width: 1.0,
                          ),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: (isGraded ? Colors.green : accent).withAlpha(20),
                                      radius: 18,
                                      child: Icon(
                                        LucideIcons.user,
                                        size: 16,
                                        color: isGraded ? Colors.green : accent,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      p['siswa_nama'] ?? 'Siswa',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 14.5,
                                        color: isDark ? Colors.white : AppTheme.textLight,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isGraded
                                        ? Colors.green.withAlpha(isDark ? 25 : 15)
                                        : accent.withAlpha(isDark ? 25 : 15),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isGraded
                                          ? Colors.green.withAlpha(isDark ? 60 : 40)
                                          : accent.withAlpha(isDark ? 60 : 40),
                                      width: 1.0,
                                    ),
                                  ),
                                  child: Text(
                                    isGraded ? 'Dinilai' : 'Diserahkan',
                                    style: GoogleFonts.plusJakartaSans(
                                      color: isGraded ? Colors.green : accent,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Diserahkan: ${_formatDate(p['waktu_pengumpulan'])}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Divider(color: isDark ? const Color(0xFF2D3A54) : const Color(0xFFE5E7EB), height: 1),
                            const SizedBox(height: 12),
                            Text(
                              'File Jawaban:',
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w800,
                                fontSize: 11,
                                color: isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (files.isEmpty)
                              Text(
                                '- Tidak ada file',
                                style: GoogleFonts.plusJakartaSans(
                                  fontStyle: FontStyle.italic,
                                  fontSize: 12,
                                  color: isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt,
                                ),
                              )
                            else
                              ...files.map((file) => Padding(
                                    padding: const EdgeInsets.only(bottom: 6),
                                    child: InkWell(
                                      onTap: () async {
                                        final url = Uri.parse(file.toString());
                                        if (await canLaunchUrl(url)) {
                                          await launchUrl(url, mode: LaunchMode.externalApplication);
                                        }
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: isDark ? const Color(0xFF141824) : const Color(0xFFF3F4F6),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: isDark ? const Color(0xFF222838) : const Color(0xFFE5E7EB)),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(LucideIcons.paperclip, size: 14, color: isGraded ? Colors.green : accent),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                'Buka Lampiran Jawaban',
                                                style: GoogleFonts.plusJakartaSans(
                                                  color: isGraded ? Colors.green : accent,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                  decoration: TextDecoration.underline,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  )),
                            const SizedBox(height: 12),
                            Divider(color: isDark ? const Color(0xFF2D3A54) : const Color(0xFFE5E7EB), height: 1),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                if (isGraded)
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: Colors.green.withAlpha(isDark ? 25 : 15),
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(color: Colors.green.withAlpha(isDark ? 60 : 40)),
                                          ),
                                          child: Text(
                                            'Nilai: ${existingNilai['nilai']}',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w900,
                                              color: Colors.green,
                                            ),
                                          ),
                                        ),
                                        if (existingNilai['feedback'] != null && existingNilai['feedback'].toString().isNotEmpty) ...[
                                          const SizedBox(height: 6),
                                          Text(
                                            '"${existingNilai['feedback']}"',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontStyle: FontStyle.italic,
                                              color: isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                const SizedBox(width: 12),
                                OutlinedButton.icon(
                                  onPressed: () => _showNilaiDialog(p, existingNilai),
                                  icon: Icon(isGraded ? LucideIcons.edit2 : LucideIcons.checkSquare, size: 14),
                                  label: Text(
                                    isGraded ? 'Edit Nilai' : 'Beri Nilai',
                                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    backgroundColor: isDark
                                        ? (isGraded ? const Color(0xFF1E3A24) : const Color(0xFF2E243F))
                                        : (isGraded ? const Color(0xFFE6F4EA) : const Color(0xFFF3E8FF)),
                                    foregroundColor: isGraded ? Colors.green : Colors.purple,
                                    side: BorderSide(
                                      color: isGraded
                                          ? (isDark ? const Color(0xFF2D5C39) : const Color(0xFF82C793))
                                          : (isDark ? const Color(0xFF4C3A66) : const Color(0xFFC084FC)),
                                      width: 1.0,
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}