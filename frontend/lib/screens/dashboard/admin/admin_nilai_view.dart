import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../config/api_config.dart';

class AdminNilaiView extends StatefulWidget {
  final String token;
  const AdminNilaiView({super.key, required this.token});

  @override
  State<AdminNilaiView> createState() => _AdminNilaiViewState();
}

class _AdminNilaiViewState extends State<AdminNilaiView> {
  List<dynamic> _nilaiList = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchNilai();
  }

  Future<void> _fetchNilai() async {
    setState(() => _isLoading = true);
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/api/nilai'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      if (res.statusCode == 200) {
        setState(() => _nilaiList = jsonDecode(res.body));
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  List<dynamic> get _filtered => _searchQuery.isEmpty
      ? _nilaiList
      : _nilaiList.where((n) => (n['siswa_nama'] ?? '').toString().toLowerCase().contains(_searchQuery.toLowerCase()) || (n['mapel'] ?? '').toString().toLowerCase().contains(_searchQuery.toLowerCase())).toList();

  Color _nilaiColor(int nilai) {
    if (nilai >= 85) return Colors.green.shade700;
    if (nilai >= 70) return Colors.blue.shade700;
    if (nilai >= 55) return Colors.orange.shade700;
    return Colors.red.shade700;
  }

  String _predikat(int nilai) {
    if (nilai >= 85) return 'A';
    if (nilai >= 70) return 'B';
    if (nilai >= 55) return 'C';
    if (nilai >= 40) return 'D';
    return 'E';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            onChanged: (v) => setState(() => _searchQuery = v),
            decoration: InputDecoration(
              hintText: 'Cari nama siswa atau mapel...',
              prefixIcon: const Icon(Icons.search),
              filled: true, fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
            ),
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filtered.isEmpty
                  ? Center(child: Text('Belum ada data nilai.', style: TextStyle(color: Colors.grey.shade500)))
                  : RefreshIndicator(
                      onRefresh: _fetchNilai,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                        itemCount: _filtered.length,
                        itemBuilder: (_, i) {
                          final n = _filtered[i];
                          final nilaiVal = int.tryParse(n['nilai']?.toString() ?? '0') ?? 0;
                          final color = _nilaiColor(nilaiVal);
                          return Card(
                            elevation: 1,
                            margin: const EdgeInsets.only(bottom: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: color.withOpacity(0.15),
                                child: Text(_predikat(nilaiVal), style: TextStyle(fontWeight: FontWeight.bold, color: color)),
                              ),
                              title: Text(n['siswa_nama'] ?? '-', style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('${n['mapel'] ?? '-'} • Guru: ${n['guru_nama'] ?? '-'}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                              trailing: Text('$nilaiVal', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
                            ),
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }
}
