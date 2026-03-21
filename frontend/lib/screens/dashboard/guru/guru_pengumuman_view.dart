import 'package:flutter/material.dart';
import '../../../widgets/confirm_delete.dart';
import '../../../config/api_config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class GuruPengumumanView extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String token;
  const GuruPengumumanView({super.key, required this.userData, required this.token});

  @override
  State<GuruPengumumanView> createState() => _GuruPengumumanViewState();
}

class _GuruPengumumanViewState extends State<GuruPengumumanView> {
  List<dynamic> _pengumumanList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPengumuman();
  }

  Future<void> _fetchPengumuman() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/pengumuman'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      if (response.statusCode == 200) {
        setState(() => _pengumumanList = jsonDecode(response.body));
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _deletePengumuman(String id) async {
    try {
      await http.delete(
        Uri.parse('$baseUrl/api/pengumuman/$id'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      _fetchPengumuman();
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  void _showPengumumanForm([Map<String, dynamic>? pengumuman]) {
    final isEditing = pengumuman != null;
    final judulCtrl = TextEditingController(text: isEditing ? pengumuman['judul'] : '');
    final isiCtrl = TextEditingController(text: isEditing ? pengumuman['isi'] : '');
    final now = DateTime.now();
    final tanggalStr = '${now.day} ${['Jan','Feb','Mar','Apr','Mei','Jun','Jul','Agu','Sep','Okt','Nov','Des'][now.month - 1]} ${now.year}';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEditing ? 'Edit Pengumuman' : 'Buat Pengumuman Baru'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: judulCtrl, decoration: const InputDecoration(labelText: 'Judul Pengumuman', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(
              controller: isiCtrl,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Isi Pengumuman', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              if (judulCtrl.text.isEmpty || isiCtrl.text.isEmpty) return;
              final body = {
                'judul': judulCtrl.text,
                'isi': isiCtrl.text,
                'tanggal': isEditing ? (pengumuman['tanggal'] ?? tanggalStr) : tanggalStr,
                'guru_id': widget.userData['id'],
                'guru_nama': widget.userData['nama'],
              };
              final headers = {'Content-Type': 'application/json', 'Authorization': 'Bearer ${widget.token}'};
              try {
                if (isEditing) {
                  await http.put(Uri.parse('$baseUrl/api/pengumuman/${pengumuman['id']}'), headers: headers, body: jsonEncode(body));
                } else {
                  await http.post(Uri.parse('$baseUrl/api/pengumuman'), headers: headers, body: jsonEncode(body));
                }
                if (ctx.mounted) Navigator.pop(ctx);
                _fetchPengumuman();
              } catch (e) {
                debugPrint('Error saving: $e');
              }
            },
            child: const Text('Kirim'),
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
        onPressed: () => _showPengumumanForm(),
        backgroundColor: Colors.orange.shade700,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Buat Pengumuman', style: TextStyle(color: Colors.white)),
      ),
      body: _pengumumanList.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.campaign_outlined, size: 80, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text('Belum ada pengumuman.', style: TextStyle(color: Colors.grey.shade600)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
              itemCount: _pengumumanList.length,
              itemBuilder: (context, index) {
                final p = _pengumumanList[index];
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ExpansionTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8)),
                      child: Icon(Icons.campaign, color: Colors.orange.shade700),
                    ),
                    title: Text(p['judul'] ?? '-', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(p['tanggal'] ?? '', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(icon: const Icon(Icons.edit, color: Colors.orange, size: 20), onPressed: () => _showPengumumanForm(p)),
                        IconButton(icon: const Icon(Icons.delete, color: Colors.red, size: 20), onPressed: () async { if (await confirmDelete(context, pesan: 'Yakin hapus pengumuman ini?')) _deletePengumuman(p['id']); }),
                      ],
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Align(alignment: Alignment.centerLeft, child: Text(p['isi'] ?? '-')),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
