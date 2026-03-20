import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'guru_tugas_detail_screen.dart';

class GuruTugasView extends StatefulWidget {
  final Map<String, dynamic> userData;
  const GuruTugasView({super.key, required this.userData});

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
      final response = await http.get(Uri.parse('http://localhost:3000/api/tugas'));
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
      await http.delete(Uri.parse('http://localhost:3000/api/tugas/$id'));
      _fetchTugas();
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  void _showTugasForm([Map<String, dynamic>? tugas]) {
    final isEditing = tugas != null;
    final judulCtrl = TextEditingController(text: isEditing ? tugas['judul'] : '');
    final deadlineCtrl = TextEditingController(text: isEditing ? tugas['deadline'] : '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEditing ? 'Edit Tugas' : 'Buat Tugas Baru'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: judulCtrl, decoration: const InputDecoration(labelText: 'Judul Tugas')),
            TextField(controller: deadlineCtrl, decoration: const InputDecoration(labelText: 'Deadline (Contoh: 24 Mar 2026)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              final body = {
                'judul': judulCtrl.text,
                'deadline': deadlineCtrl.text,
                'guru_id': widget.userData['id'],
                'mapel': widget.userData['kelas'],
                'status': 'Aktif'
              };

              final url = isEditing 
                  ? Uri.parse('http://localhost:3000/api/tugas/${tugas['id']}')
                  : Uri.parse('http://localhost:3000/api/tugas');

              try {
                if (isEditing) {
                  await http.put(url, headers: {'Content-Type': 'application/json'}, body: jsonEncode(body));
                } else {
                  await http.post(url, headers: {'Content-Type': 'application/json'}, body: jsonEncode(body));
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showTugasForm(),
        backgroundColor: Colors.blue.shade800,
        child: const Icon(Icons.add, color: Colors.white),
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
                  child: ListTile(
                    leading: const Icon(Icons.assignment, color: Colors.blue, size: 36),
                    title: Text(t['judul'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Deadline: ${t['deadline']}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.visibility, color: Colors.green),
                          tooltip: 'Lihat Pengumpulan',
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => GuruTugasDetailScreen(tugas: t)));
                          },
                        ),
                        IconButton(icon: const Icon(Icons.edit, color: Colors.orange), onPressed: () => _showTugasForm(t)),
                        IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteTugas(t['id'])),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}