import 'package:flutter/material.dart';
import '../../../widgets/confirm_delete.dart';
import '../../../config/api_config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../services/notifikasi_service.dart';

class GuruMateriView extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String token;
  const GuruMateriView({super.key, required this.userData, required this.token});

  @override
  State<GuruMateriView> createState() => _GuruMateriViewState();
}

class _GuruMateriViewState extends State<GuruMateriView> {
  List<dynamic> _materiList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMateri();
  }

  Future<void> _fetchMateri() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/materi'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      if (response.statusCode == 200) {
        List data = jsonDecode(response.body);
        setState(() {
          _materiList = data
              .where((m) => m['guru_id'] == widget.userData['id'])
              .toList();
        });
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _deleteMateri(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Materi'),
        content: const Text('Yakin ingin menghapus materi ini?'),
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
          Uri.parse('$baseUrl/api/materi/$id'),
          headers: {'Authorization': 'Bearer ${widget.token}'},
        );
        _fetchMateri();
      } catch (e) {
        debugPrint('Error: $e');
      }
    }
  }

  void _showMateriForm([Map<String, dynamic>? materi]) {
    final isEditing = materi != null;
    final judulCtrl = TextEditingController(text: isEditing ? materi['judul'] : '');
    final mapelCtrl = TextEditingController(text: isEditing ? materi['mapel'] : widget.userData['kelas'] ?? '');
    final kelasCtrl = TextEditingController(text: isEditing ? (materi['kelas'] ?? '') : '');
    final deskripsiCtrl = TextEditingController(text: isEditing ? (materi['deskripsi'] ?? '') : '');
    final linkCtrl = TextEditingController(text: isEditing ? (materi['link'] ?? '') : '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEditing ? 'Edit Materi' : 'Tambah Materi Baru'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: judulCtrl,
                decoration: const InputDecoration(
                  labelText: 'Judul Materi *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: mapelCtrl,
                decoration: const InputDecoration(
                  labelText: 'Mata Pelajaran *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: kelasCtrl,
                decoration: const InputDecoration(
                  labelText: 'Kelas (cth: XII IPA 1)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: deskripsiCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Deskripsi / Isi Materi',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: linkCtrl,
                decoration: const InputDecoration(
                  labelText: 'Link Materi / Google Drive (opsional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.link),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              if (judulCtrl.text.isEmpty || mapelCtrl.text.isEmpty) return;
              final body = {
                'judul': judulCtrl.text,
                'mapel': mapelCtrl.text,
                'kelas': kelasCtrl.text,
                'deskripsi': deskripsiCtrl.text,
                'link': linkCtrl.text,
                'guru_id': widget.userData['id'],
                'guru_nama': widget.userData['nama'],
                'tanggal': DateTime.now().toIso8601String(),
              };
              final headers = {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer ${widget.token}',
              };
              try {
                if (isEditing) {
                  await http.put(
                    Uri.parse('$baseUrl/api/materi/${materi['id']}'),
                    headers: headers,
                    body: jsonEncode(body),
                  );
                } else {
                  await http.post(
                    Uri.parse('$baseUrl/api/materi'),
                    headers: headers,
                    body: jsonEncode(body),
                  );
                  // Kirim Notifikasi
                  NotifikasiService.kirimNotifikasi(
                    judul: 'Materi Baru: ${judulCtrl.text}',
                    pesan: 'Materi baru telah ditambahkan oleh ${widget.userData['nama']} untuk mapel ${mapelCtrl.text}',
                    token: widget.token,
                    targetRole: 'Siswa',
                    targetKelas: kelasCtrl.text.isNotEmpty ? kelasCtrl.text : null,
                  );
                }
                if (ctx.mounted) Navigator.pop(ctx);
                _fetchMateri();
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
        onPressed: () => _showMateriForm(),
        backgroundColor: Colors.teal.shade700,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Tambah Materi', style: TextStyle(color: Colors.white)),
      ),
      body: _materiList.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.menu_book_outlined, size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text('Belum ada materi.', style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
                  const SizedBox(height: 8),
                  Text('Tekan tombol + untuk tambah materi baru', style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _fetchMateri,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
                itemCount: _materiList.length,
                itemBuilder: (context, index) {
                  final m = _materiList[index];
                  final colors = [Colors.teal, Colors.blue, Colors.purple, Colors.orange, Colors.green];
                  final color = colors[index % colors.length];
                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
                      leading: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: color.shade50,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.menu_book, color: color.shade700, size: 26),
                      ),
                      title: Text(m['judul'] ?? '-', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text('${m['mapel'] ?? '-'} • ${m['kelas'] ?? 'Semua Kelas'}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                          if ((m['deskripsi'] ?? '').toString().isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(m['deskripsi'], style: TextStyle(fontSize: 12, color: Colors.grey.shade500), maxLines: 1, overflow: TextOverflow.ellipsis),
                          ],
                          if ((m['link'] ?? '').toString().isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.link, size: 12, color: Colors.blue.shade600),
                                const SizedBox(width: 4),
                                Text('Ada link materi', style: TextStyle(fontSize: 11, color: Colors.blue.shade600)),
                              ],
                            ),
                          ],
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(icon: const Icon(Icons.edit, color: Colors.orange), onPressed: () => _showMateriForm(m)),
                          IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () async { if (await confirmDelete(context, pesan: 'Yakin hapus materi ini?')) _deleteMateri(m['id']); }),
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
