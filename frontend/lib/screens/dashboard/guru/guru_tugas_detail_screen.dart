import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class GuruTugasDetailScreen extends StatefulWidget {
  final Map<String, dynamic> tugas;
  const GuruTugasDetailScreen({super.key, required this.tugas});

  @override
  State<GuruTugasDetailScreen> createState() => _GuruTugasDetailScreenState();
}

class _GuruTugasDetailScreenState extends State<GuruTugasDetailScreen> {
  bool _isLoading = true;
  List<dynamic> _pengumpulanList = [];

  @override
  void initState() {
    super.initState();
    _fetchPengumpulan();
  }

  Future<void> _fetchPengumpulan() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(Uri.parse('http://localhost:3000/api/pengumpulan'));
      if (response.statusCode == 200) {
        List allData = jsonDecode(response.body);
        setState(() {
          _pengumpulanList = allData.where((p) => p['tugas_id'] == widget.tugas['id']).toList();
        });
      }
    } catch (e) {
      debugPrint("Error Fetch Pengumpulan: $e");
    }
    if (mounted) setState(() => _isLoading = false);
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _pengumpulanList.isEmpty
              ? const Center(child: Text('Belum ada siswa yang mengumpulkan tugas ini.', style: TextStyle(fontSize: 16)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _pengumpulanList.length,
                  itemBuilder: (context, index) {
                    final p = _pengumpulanList[index];
                    final List<dynamic> files = p['files'] ?? [];

                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 16),
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
                                Text(
                                  'Diserahkan',
                                  style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.bold, fontSize: 12),
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
                            Align(
                              alignment: Alignment.centerRight,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Modul Penilaian Belum Tersedia')));
                                },
                                icon: const Icon(Icons.grade, size: 18),
                                label: const Text('Beri Nilai'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.purple.shade600,
                                  foregroundColor: Colors.white,
                                ),
                              ),
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