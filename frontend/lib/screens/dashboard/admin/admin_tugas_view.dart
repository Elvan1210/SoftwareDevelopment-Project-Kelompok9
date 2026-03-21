import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../config/api_config.dart';

class AdminTugasView extends StatefulWidget {
  final String token;
  const AdminTugasView({super.key, required this.token});

  @override
  State<AdminTugasView> createState() => _AdminTugasViewState();
}

class _AdminTugasViewState extends State<AdminTugasView> {
  List<dynamic> _tugasList = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchTugas();
  }

  Future<void> _fetchTugas() async {
    setState(() => _isLoading = true);
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/api/tugas'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      if (res.statusCode == 200) {
        setState(() => _tugasList = jsonDecode(res.body));
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _deleteTugas(String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Tugas'),
        content: const Text('Yakin ingin menghapus tugas ini?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red), onPressed: () => Navigator.pop(ctx, true), child: const Text('Hapus', style: TextStyle(color: Colors.white))),
        ],
      ),
    );
    if (ok == true) {
      await http.delete(Uri.parse('$baseUrl/api/tugas/$id'), headers: {'Authorization': 'Bearer ${widget.token}'});
      _fetchTugas();
    }
  }

  List<dynamic> get _filtered => _searchQuery.isEmpty
      ? _tugasList
      : _tugasList.where((t) => (t['judul'] ?? '').toString().toLowerCase().contains(_searchQuery.toLowerCase()) || (t['guru_nama'] ?? '').toString().toLowerCase().contains(_searchQuery.toLowerCase())).toList();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            onChanged: (v) => setState(() => _searchQuery = v),
            decoration: InputDecoration(
              hintText: 'Cari tugas...',
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
                  ? Center(child: Text('Belum ada tugas.', style: TextStyle(color: Colors.grey.shade500)))
                  : RefreshIndicator(
                      onRefresh: _fetchTugas,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                        itemCount: _filtered.length,
                        itemBuilder: (_, i) {
                          final t = _filtered[i];
                          return Card(
                            elevation: 1,
                            margin: const EdgeInsets.only(bottom: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              leading: CircleAvatar(backgroundColor: Colors.blue.shade50, child: Icon(Icons.assignment, color: Colors.blue.shade700, size: 20)),
                              title: Text(t['judul'] ?? '-', style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Guru: ${t['guru_nama'] ?? '-'}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                                  Text('Deadline: ${t['deadline'] ?? '-'} • Kelas: ${t['kelas'] ?? t['mapel'] ?? '-'}', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                                ],
                              ),
                              trailing: IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () => _deleteTugas(t['id'])),
                              isThreeLine: true,
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
