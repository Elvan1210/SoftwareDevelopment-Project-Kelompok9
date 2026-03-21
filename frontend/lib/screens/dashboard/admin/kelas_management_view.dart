import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class KelasManagementView extends StatefulWidget {
  final String token;
  const KelasManagementView({super.key, required this.token});

  @override
  State<KelasManagementView> createState() => _KelasManagementViewState();
}

class _KelasManagementViewState extends State<KelasManagementView> {
  List<dynamic> _kelasList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchKelas();
  }

  Future<void> _fetchKelas() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('http://localhost:3000/api/kelas'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      if (response.statusCode == 200) {
        setState(() => _kelasList = jsonDecode(response.body));
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _deleteKelas(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Kelas'),
        content: const Text('Apakah Anda yakin ingin menghapus kelas ini?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await http.delete(
          Uri.parse('http://localhost:3000/api/kelas/$id'),
          headers: {'Authorization': 'Bearer ${widget.token}'},
        );
        _fetchKelas();
      } catch (e) {
        debugPrint('Error: $e');
      }
    }
  }

  void _showKelasForm([Map<String, dynamic>? kelas]) {
    final isEditing = kelas != null;
    final namaCtrl = TextEditingController(text: isEditing ? kelas['nama_kelas'] : '');
    final waliCtrl = TextEditingController(text: isEditing ? kelas['wali_kelas'] : '');
    final jurusanCtrl = TextEditingController(text: isEditing ? kelas['jurusan'] : '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEditing ? 'Edit Kelas' : 'Tambah Kelas Baru'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: namaCtrl, decoration: const InputDecoration(labelText: 'Nama Kelas (cth: XII IPA 1)', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: waliCtrl, decoration: const InputDecoration(labelText: 'Wali Kelas', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: jurusanCtrl, decoration: const InputDecoration(labelText: 'Jurusan (cth: IPA)', border: OutlineInputBorder())),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              if (namaCtrl.text.isEmpty) return;
              final body = {
                'nama_kelas': namaCtrl.text,
                'wali_kelas': waliCtrl.text,
                'jurusan': jurusanCtrl.text,
              };
              final headers = {'Content-Type': 'application/json', 'Authorization': 'Bearer ${widget.token}'};
              try {
                if (isEditing) {
                  await http.put(Uri.parse('http://localhost:3000/api/kelas/${kelas['id']}'), headers: headers, body: jsonEncode(body));
                } else {
                  await http.post(Uri.parse('http://localhost:3000/api/kelas'), headers: headers, body: jsonEncode(body));
                }
                if (ctx.mounted) Navigator.pop(ctx);
                _fetchKelas();
              } catch (e) {
                debugPrint('Error saving: $e');
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showKelasForm(),
        backgroundColor: Colors.blue.shade800,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Tambah Kelas', style: TextStyle(color: Colors.white)),
      ),
      body: _kelasList.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.class_outlined, size: 80, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text('Belum ada data kelas.', style: TextStyle(color: Colors.grey.shade600)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
              itemCount: _kelasList.length,
              itemBuilder: (context, index) {
                final k = _kelasList[index];
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue.shade50,
                      child: Icon(Icons.class_, color: Colors.blue.shade800),
                    ),
                    title: Text(k['nama_kelas'] ?? '-', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Wali: ${k['wali_kelas'] ?? '-'} • ${k['jurusan'] ?? '-'}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(icon: const Icon(Icons.edit, color: Colors.orange), onPressed: () => _showKelasForm(k)),
                        IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteKelas(k['id'])),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
