import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../config/api_config.dart';

class AdminMateriView extends StatefulWidget {
  final String token;
  const AdminMateriView({super.key, required this.token});

  @override
  State<AdminMateriView> createState() => _AdminMateriViewState();
}

class _AdminMateriViewState extends State<AdminMateriView> {
  List<dynamic> _materiList = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchMateri();
  }

  Future<void> _fetchMateri() async {
    setState(() => _isLoading = true);
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/api/materi'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      if (res.statusCode == 200) {
        setState(() => _materiList = jsonDecode(res.body));
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _deleteMateri(String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Materi'),
        content: const Text('Yakin ingin menghapus materi ini?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red), onPressed: () => Navigator.pop(ctx, true), child: const Text('Hapus', style: TextStyle(color: Colors.white))),
        ],
      ),
    );
    if (ok == true) {
      await http.delete(Uri.parse('$baseUrl/api/materi/$id'), headers: {'Authorization': 'Bearer ${widget.token}'});
      _fetchMateri();
    }
  }

  List<dynamic> get _filtered => _searchQuery.isEmpty
      ? _materiList
      : _materiList.where((m) => (m['judul'] ?? '').toString().toLowerCase().contains(_searchQuery.toLowerCase()) || (m['guru_nama'] ?? '').toString().toLowerCase().contains(_searchQuery.toLowerCase())).toList();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            onChanged: (v) => setState(() => _searchQuery = v),
            decoration: InputDecoration(
              hintText: 'Cari materi...',
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
                  ? Center(child: Text('Belum ada materi.', style: TextStyle(color: Colors.grey.shade500)))
                  : RefreshIndicator(
                      onRefresh: _fetchMateri,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                        itemCount: _filtered.length,
                        itemBuilder: (_, i) {
                          final m = _filtered[i];
                          return Card(
                            elevation: 1,
                            margin: const EdgeInsets.only(bottom: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              leading: CircleAvatar(backgroundColor: Colors.teal.shade50, child: Icon(Icons.menu_book, color: Colors.teal.shade700, size: 20)),
                              title: Text(m['judul'] ?? '-', style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('${m['mapel'] ?? '-'} • Guru: ${m['guru_nama'] ?? '-'} • Kelas: ${m['kelas'] ?? 'Semua'}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                              trailing: IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () => _deleteMateri(m['id'])),
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
