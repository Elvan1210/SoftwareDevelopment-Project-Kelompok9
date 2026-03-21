import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class GuruDashboardView extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String token;
  const GuruDashboardView({super.key, required this.userData, required this.token});

  @override
  State<GuruDashboardView> createState() => _GuruDashboardViewState();
}

class _GuruDashboardViewState extends State<GuruDashboardView> {
  int _totalTugas = 0;
  int _totalMateri = 0;
  int _totalNilai = 0;
  int _totalPengumuman = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    try {
      final headers = {'Authorization': 'Bearer ${widget.token}'};
      final results = await Future.wait([
        http.get(Uri.parse('http://localhost:3000/api/tugas'), headers: headers),
        http.get(Uri.parse('http://localhost:3000/api/materi'), headers: headers),
        http.get(Uri.parse('http://localhost:3000/api/nilai'), headers: headers),
        http.get(Uri.parse('http://localhost:3000/api/pengumuman'), headers: headers),
      ]);

      if (results[0].statusCode == 200) {
        List data = jsonDecode(results[0].body);
        _totalTugas = data.where((t) => t['guru_id'] == widget.userData['id']).length;
      }
      if (results[1].statusCode == 200) {
        List data = jsonDecode(results[1].body);
        _totalMateri = data.where((m) => m['guru_id'] == widget.userData['id']).length;
      }
      if (results[2].statusCode == 200) {
        List data = jsonDecode(results[2].body);
        _totalNilai = data.where((n) => n['guru_id'] == widget.userData['id']).length;
      }
      if (results[3].statusCode == 200) {
        List data = jsonDecode(results[3].body);
        _totalPengumuman = data.where((p) => p['guru_id'] == widget.userData['id']).length;
      }
    } catch (e) {
      debugPrint("Error: $e");
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sapaan
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.purple.shade100,
                child: Text(
                  (widget.userData['nama'] ?? 'G').substring(0, 1).toUpperCase(),
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.purple.shade700),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Selamat datang,', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                  Text(widget.userData['nama'] ?? 'Guru', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),

          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: Colors.purple.shade50, borderRadius: BorderRadius.circular(8)),
            child: Text('Mata Pelajaran: ${widget.userData['kelas'] ?? '-'}',
                style: TextStyle(fontSize: 13, color: Colors.purple.shade700, fontWeight: FontWeight.w600)),
          ),

          const SizedBox(height: 24),
          const Text('Ringkasan Aktivitas', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 14),

          // Stats grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              _statCard('Tugas Dibuat', _totalTugas, Icons.assignment, Colors.blue.shade700),
              _statCard('Materi Dibuat', _totalMateri, Icons.menu_book, Colors.teal.shade700),
              _statCard('Nilai Diinput', _totalNilai, Icons.grade, Colors.orange.shade700),
              _statCard('Pengumuman', _totalPengumuman, Icons.campaign, Colors.purple.shade700),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statCard(String label, int count, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('$count', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: color)),
              Text(label, style: TextStyle(fontSize: 11, color: color.withOpacity(0.8))),
            ],
          ),
        ],
      ),
    );
  }
}