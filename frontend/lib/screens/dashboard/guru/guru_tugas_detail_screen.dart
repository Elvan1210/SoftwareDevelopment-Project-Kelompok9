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
                  NotifikasiService.kirimNotifikasi(
                    judul: 'Nilai Tugas Keluar!',
                    pesan: 'Tugas "${widget.tugas['judul']}" kamu dapat nilai $nilaiVal dari ${widget.tugas['guru_nama']}',
                    token: widget.token,
                    targetUserId: pengumpulan['siswa_id'],
                  );
                  // Pilihan opsional: update API pengumpulan agar statusnya 'Dinilai'
                  // Karena struktur db kita bebas, kita bisa pass saja update statusnya:
                  await http.put(
                    Uri.parse('$baseUrl/api/pengumpulan/${pengumpulan['id']}'), 
                    headers: headers, 
                    body: jsonEncode({
                      ...pengumpulan,
                      'status': 'Dinilai'
                    })
                  );
                  // Kirim Notifikasi Nilai
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
        appBar: AppBar(title: const Text('Hasil Pengumpulan')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Hasil Pengumpulan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(widget.tugas['judul'] ?? 'Tugas', style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
      body: _pengumpulanList.isEmpty
          ? const Center(child: Text('Belum ada siswa yang mengumpulkan tugas ini.', style: TextStyle(fontSize: 16)))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _pengumpulanList.length,
              itemBuilder: (context, index) {
                final p = _pengumpulanList[index];
                final List<dynamic> files = p['files'] ?? [];
                
                // Cari apakah sudah ada nilai untuk siswa ini di tugas ini
                Map<String, dynamic>? existingNilai;
                try {
                  existingNilai = _nilaiList.firstWhere((n) => n['siswa_id'] == p['siswa_id'] && n['tugas_id'] == widget.tugas['id']);
                } catch (e) {
                  existingNilai = null;
                }

                final isGraded = existingNilai != null;

                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 16),
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
                                Text(p['siswa_nama'] ?? 'Siswa Tidak Diketahui', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
                        const Text('File Terlampir:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        const SizedBox(height: 8),
                        if (files.isEmpty)
                          const Text('- Tidak ada file', style: TextStyle(fontStyle: FontStyle.italic))
                        else
                          ...files.map((file) => Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Row(
                                  children: [
                                    const Icon(Icons.attachment, size: 16, color: Colors.grey),
                                    const SizedBox(width: 8),
                                    Expanded(child: Text(file.toString(), style: const TextStyle(color: Colors.blue))),
                                  ],
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
    );
  }
}