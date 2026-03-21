import 'package:flutter/material.dart';
import '../../../widgets/confirm_delete.dart';
import '../../../config/api_config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'guru_tugas_detail_screen.dart';
import '../../../services/notifikasi_service.dart';

class GuruTugasView extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String token;
  const GuruTugasView({super.key, required this.userData, required this.token});

  @override
  State<GuruTugasView> createState() => _GuruTugasViewState();
}

class _GuruTugasViewState extends State<GuruTugasView> {
  List<dynamic> _tugasList = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchTugas();
  }

  Future<void> _fetchTugas() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/tugas'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      if (response.statusCode == 200) {
        List data = jsonDecode(response.body);
        setState(() {
          _tugasList = data.where((t) => t['guru_id'] == widget.userData['id']).toList();
        });
      }
    } catch (e) {
      debugPrint("Error: $e");
    }
    setState(() => _isLoading = false);
  }

  Future<void> _deleteTugas(String id) async {
    try {
      await http.delete(
        Uri.parse('$baseUrl/api/tugas/$id'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      _fetchTugas();
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  void _showTugasForm([Map<String, dynamic>? tugas]) {
    final isEditing = tugas != null;
    final judulCtrl = TextEditingController(text: isEditing ? tugas['judul'] : '');
    final deskripsiCtrl = TextEditingController(text: isEditing ? (tugas['deskripsi'] ?? '') : '');
    final deadlineCtrl = TextEditingController(text: isEditing ? (tugas['deadline'] ?? '') : '');
    final linkCtrl = TextEditingController(text: isEditing ? (tugas['link'] ?? '') : '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEditing ? 'Edit Tugas' : 'Buat Tugas Baru'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: judulCtrl, decoration: const InputDecoration(labelText: 'Judul Tugas')),
              TextField(
                controller: deskripsiCtrl, 
                maxLines: 3, 
                decoration: const InputDecoration(labelText: 'Deskripsi Tugas'),
              ),
              TextField(controller: deadlineCtrl, decoration: const InputDecoration(labelText: 'Deadline (Contoh: 24 Mar 2026)')),
              TextField(controller: linkCtrl, decoration: const InputDecoration(labelText: 'Link Pendukung (Opsional)')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              final body = {
                'judul': judulCtrl.text,
                'deskripsi': deskripsiCtrl.text,
                'deadline': deadlineCtrl.text,
                'link': linkCtrl.text,
                'guru_id': widget.userData['id'],
                'guru_nama': widget.userData['nama'],
                'mapel': widget.userData['kelas'],
                'status': 'Aktif',
                'tanggal_dibuat': DateTime.now().toIso8601String()
              };

              final url = isEditing 
                  ? Uri.parse('$baseUrl/api/tugas/${tugas['id']}')
                  : Uri.parse('$baseUrl/api/tugas');
              final headers = {'Content-Type': 'application/json', 'Authorization': 'Bearer ${widget.token}'};
              try {
                if (isEditing) {
                  await http.put(url, headers: headers, body: jsonEncode(body));
                } else {
                  await http.post(url, headers: headers, body: jsonEncode(body));
                  // Kirim Notifikasi
                  NotifikasiService.kirimNotifikasi(
                    judul: 'Tugas Baru: ${judulCtrl.text}',
                    pesan: 'Tugas baru dari ${widget.userData['nama']} (Deadline: ${deadlineCtrl.text})',
                    token: widget.token,
                    targetRole: 'Siswa',
                    targetKelas: widget.userData['kelas'],
                  );
                }
                if (ctx.mounted) Navigator.pop(ctx);
                _fetchTugas();
              } catch (e) {
                debugPrint("Error saving: $e");
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
        onPressed: () => _showTugasForm(),
        backgroundColor: Colors.blue.shade800,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Tugas Baru', style: TextStyle(color: Colors.white)),
      ),
      body: _tugasList.isEmpty
          ? const Center(child: Text('Belum ada tugas yang Anda buat.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _tugasList.length,
              itemBuilder: (context, index) {
                final t = _tugasList[index];
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: const CircleAvatar(
                      backgroundColor: Colors.blue,
                      child: Icon(Icons.assignment, color: Colors.white),
                    ),
                    title: Text(t['judul'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          t['deskripsi'] ?? 'Tidak ada deskripsi',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.access_time, size: 14, color: Colors.red),
                            const SizedBox(width: 4),
                            Text('Deadline: ${t['deadline']}', style: const TextStyle(fontSize: 12, color: Colors.red, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.visibility, color: Colors.green),
                          tooltip: 'Lihat Pengumpulan',
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => GuruTugasDetailScreen(tugas: t, token: widget.token)));
                          },
                        ),
                        IconButton(icon: const Icon(Icons.edit, color: Colors.orange), onPressed: () => _showTugasForm(t)),
                        IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () async { if (await confirmDelete(context, pesan: 'Yakin hapus tugas ini?')) _deleteTugas(t['id']); }),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}