import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SiswaNilaiView extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String token;
  const SiswaNilaiView({super.key, required this.userData, required this.token});

  @override
  State<SiswaNilaiView> createState() => _SiswaNilaiViewState();
}

class _SiswaNilaiViewState extends State<SiswaNilaiView> {
  List<dynamic> _nilaiList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchNilai();
  }

  Future<void> _fetchNilai() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('http://localhost:3000/api/nilai'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      if (response.statusCode == 200) {
        List data = jsonDecode(response.body);
        setState(() {
          _nilaiList = data
              .where((n) => n['siswa_id'] == widget.userData['id'])
              .toList();
        });
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Color _getNilaiColor(dynamic nilai) {
    final n = (nilai is String ? double.tryParse(nilai) : nilai?.toDouble()) ?? 0;
    if (n >= 85) return Colors.green.shade700;
    if (n >= 75) return Colors.blue.shade700;
    if (n >= 65) return Colors.orange.shade700;
    return Colors.red.shade700;
  }

  String _getPredikat(dynamic nilai) {
    final n = (nilai is String ? double.tryParse(nilai) : nilai?.toDouble()) ?? 0;
    if (n >= 90) return 'A';
    if (n >= 80) return 'B';
    if (n >= 70) return 'C';
    if (n >= 60) return 'D';
    return 'E';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Nilai Saya', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black87,
        automaticallyImplyLeading: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _nilaiList.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.grade_outlined, size: 80, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text('Belum ada nilai yang diinput.', style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchNilai,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _nilaiList.length,
                    itemBuilder: (context, index) {
                      final n = _nilaiList[index];
                      final color = _getNilaiColor(n['nilai']);
                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: Text(
                                    _getPredikat(n['nilai']),
                                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: color),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(n['mapel'] ?? 'Mata Pelajaran', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                    const SizedBox(height: 4),
                                    Text(n['keterangan'] ?? '', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                                  ],
                                ),
                              ),
                              Text(
                                '${n['nilai'] ?? '-'}',
                                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
