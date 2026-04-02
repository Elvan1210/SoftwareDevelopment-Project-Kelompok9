import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import '../../../config/api_config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import '../../../services/notifikasi_service.dart';

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
    final ctrl = TextEditingController(text: existingNilai != null ? existingNilai['nilai'].toString() : '');
    final feedbackCtrl = TextEditingController(text: existingNilai != null ? existingNilai['feedback']?.toString() ?? '' : '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existingNilai != null ? 'Edit Nilai' : 'Beri Nilai'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Siswa: ${pengumpulan['siswa_nama']}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Nilai (0-100)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: feedbackCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Komentar / Feedback Opsional',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, foregroundColor: Colors.white),
            child: const Text('Simpan'),
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
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detail Tugas')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Tugas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ==========================================
            // BAGIAN 1: INFORMASI SOAL / TUGAS
            // ==========================================
            Text(
              widget.tugas['judul'] ?? 'Tanpa Judul',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            if (widget.tugas['deadline'] != null)
              Row(
                children: [
                  const Icon(Icons.timer_outlined, size: 16, color: Colors.orange),
                  const SizedBox(width: 8),
                  Text(
                    'Tenggat: ${_formatDate(widget.tugas['deadline'])}',
                    style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            const SizedBox(height: 16),
            Text(
              widget.tugas['deskripsi'] ?? 'Tidak ada deskripsi detail.',
              style: const TextStyle(fontSize: 15, height: 1.5),
            ),

            // ==========================================
            // BAGIAN 2: KARTU LAMPIRAN FILE GURU
            // ==========================================
            if (widget.tugas['link'] != null && widget.tugas['link'].toString().isNotEmpty) ...[
              const SizedBox(height: 24),
              const Text('Lampiran Materi/Soal:', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
              const SizedBox(height: 8),
              InkWell(
                onTap: () async {
                  String rawUrl = widget.tugas['link'].toString();
                  
                  // Kalau PDF, buka via Google Docs Viewer biar bisa preview
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
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF76AFB8).withAlpha(25),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF76AFB8).withAlpha(80)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.insert_drive_file_rounded, color: Color(0xFF76AFB8), size: 36),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Buka File Lampiran', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF76AFB8))),
                            Text('Ketuk untuk mengunduh/melihat', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ),
                      Icon(Icons.open_in_new_rounded, color: Color(0xFF76AFB8), size: 20),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 32),
            const Divider(thickness: 1.5),
            const SizedBox(height: 16),

            // ==========================================
            // BAGIAN 3: DAFTAR MURID YANG KUMPUL
            // ==========================================
            const Text(
              'Status Pengumpulan Siswa',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 16),

            if (_pengumpulanList.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12)
                ),
                child: const Text('Belum ada siswa yang mengumpulkan tugas ini.', style: TextStyle(color: Colors.grey)),
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

                  return Card(
                    elevation: 1,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const CircleAvatar(
                                    backgroundColor: Colors.blue,
                                    radius: 16,
                                    child: Icon(Icons.person, size: 16, color: Colors.white),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(p['siswa_nama'] ?? 'Siswa', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isGraded ? Colors.green.shade50 : Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  isGraded ? 'Dinilai' : 'Diserahkan',
                                  style: TextStyle(color: isGraded ? Colors.green.shade700 : Colors.blue.shade700, fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text('Waktu: ${_formatDate(p['waktu_pengumpulan'])}', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                          const Divider(height: 24),
                          const Text('File Jawaban:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          const SizedBox(height: 8),
                          if (files.isEmpty)
                            const Text('- Tidak ada file', style: TextStyle(fontStyle: FontStyle.italic, fontSize: 13))
                          else
                            ...files.map((file) => Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: InkWell(
                                    onTap: () async {
                                      // 🔥 FIX: Ambil URL langsung tanpa _fixCloudinaryUrl
                                      final url = Uri.parse(file.toString());
                                      if (await canLaunchUrl(url)) {
                                        // 🔥 FIX: Paksa buka di browser bawaan HP
                                        await launchUrl(url, mode: LaunchMode.externalApplication);
                                      }
                                    },
                                    child: const Row(
                                      children: [
                                        Icon(Icons.attachment, size: 16, color: Colors.blue),
                                        SizedBox(width: 8),
                                        Expanded(child: Text('Buka File Jawaban', style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline))),
                                      ],
                                    ),
                                  ),
                                )),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              isGraded
                                  ? Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Nilai: ${existingNilai['nilai']}',
                                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green.shade700),
                                        ),
                                        if (existingNilai['feedback'] != null && existingNilai['feedback'].toString().isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 4.0),
                                            child: Text('"${existingNilai['feedback']}"', style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey, fontSize: 12)),
                                          )
                                      ],
                                    )
                                  : const SizedBox.shrink(),
                              ElevatedButton.icon(
                                onPressed: () => _showNilaiDialog(p, existingNilai),
                                icon: Icon(isGraded ? Icons.edit : Icons.grade, size: 18),
                                label: Text(isGraded ? 'Edit Nilai' : 'Beri Nilai'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isGraded ? Colors.orange.shade600 : Colors.purple.shade600,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ],
                          )
                        ],
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