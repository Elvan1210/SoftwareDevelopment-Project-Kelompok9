import 'package:flutter/material.dart';
import '../../../widgets/confirm_delete.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../config/api_config.dart';
import '../../../services/notifikasi_service.dart';

class AdminPengumumanView extends StatefulWidget {
  final String token;
  const AdminPengumumanView({super.key, required this.token});

  @override
  State<AdminPengumumanView> createState() => _AdminPengumumanViewState();
}

class _AdminPengumumanViewState extends State<AdminPengumumanView> {
  List<dynamic> _pengumumanList = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchPengumuman();
  }

  Future<void> _fetchPengumuman() async {
    setState(() => _isLoading = true);
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/api/pengumuman'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      if (res.statusCode == 200) {
        setState(() => _pengumumanList = jsonDecode(res.body));
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _deletePengumuman(String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Pengumuman'),
        content: const Text('Yakin ingin menghapus pengumuman ini?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red), onPressed: () => Navigator.pop(ctx, true), child: const Text('Hapus', style: TextStyle(color: Colors.white))),
        ],
      ),
    );
    if (ok == true) {
      await http.delete(Uri.parse('$baseUrl/api/pengumuman/$id'), headers: {'Authorization': 'Bearer ${widget.token}'});
      _fetchPengumuman();
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
        title: Text(isEditing ? 'Edit Pengumuman' : 'Buat Pengumuman (Admin)'),
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
                'guru_id': 'admin',
                'guru_nama': 'Administrator',
              };
              final headers = {'Content-Type': 'application/json', 'Authorization': 'Bearer ${widget.token}'};
              try {
                if (isEditing) {
                  await http.put(Uri.parse('$baseUrl/api/pengumuman/${pengumuman['id']}'), headers: headers, body: jsonEncode(body));
                } else {
                  await http.post(Uri.parse('$baseUrl/api/pengumuman'), headers: headers, body: jsonEncode(body));
                  NotifikasiService.kirimNotifikasi(
                    judul: 'Pengumuman Admin: ${judulCtrl.text}',
                    pesan: isiCtrl.text,
                    token: widget.token,
                    targetRole: 'Semua', 
                  );
                }
                if (ctx.mounted) Navigator.pop(ctx);
                _fetchPengumuman();
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

  List<dynamic> get _filtered => _searchQuery.isEmpty
      ? _pengumumanList
      : _pengumumanList.where((p) => (p['judul'] ?? '').toString().toLowerCase().contains(_searchQuery.toLowerCase()) || (p['isi'] ?? '').toString().toLowerCase().contains(_searchQuery.toLowerCase())).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showPengumumanForm(),
        backgroundColor: Colors.blue.shade800,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Buat Pengumuman', style: TextStyle(color: Colors.white)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: 'Cari pengumuman...',
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
                    ? Center(child: Text('Belum ada pengumuman.', style: TextStyle(color: Colors.grey.shade500)))
                    : RefreshIndicator(
                        onRefresh: _fetchPengumuman,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                          itemCount: _filtered.length,
                          itemBuilder: (_, i) {
                            final p = _filtered[i];
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
                                subtitle: Text('${p['tanggal'] ?? '-'} • Oleh: ${p['guru_nama'] ?? 'Unknown'}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(icon: const Icon(Icons.edit, color: Colors.blue, size: 20), onPressed: () => _showPengumumanForm(p)),
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
                      ),
          ),
        ],
      ),
    );
  }
}
