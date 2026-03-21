import 'package:flutter/material.dart';
import '../../../widgets/confirm_delete.dart';
import '../../../config/api_config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class GuruNilaiView extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String token;
  const GuruNilaiView({super.key, required this.userData, required this.token});

  @override
  State<GuruNilaiView> createState() => _GuruNilaiViewState();
}

class _GuruNilaiViewState extends State<GuruNilaiView> {
  List<dynamic> _nilaiList = [];
  List<dynamic> _userList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final headers = {'Authorization': 'Bearer ${widget.token}'};
      final resNilai = await http.get(Uri.parse('$baseUrl/api/nilai'), headers: headers);
      final resUsers = await http.get(Uri.parse('$baseUrl/api/users'), headers: headers);

      if (resNilai.statusCode == 200) {
        List data = jsonDecode(resNilai.body);
        setState(() {
          _nilaiList = data.where((n) => n['guru_id'] == widget.userData['id']).toList();
        });
      }
      if (resUsers.statusCode == 200) {
        List users = jsonDecode(resUsers.body);
        setState(() {
          _userList = users.where((u) => u['role'] == 'Siswa').toList();
        });
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _deleteNilai(String id) async {
    try {
      await http.delete(
        Uri.parse('$baseUrl/api/nilai/$id'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      _fetchData();
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  void _showNilaiForm([Map<String, dynamic>? nilai]) {
    final isEditing = nilai != null;
    String? selectedSiswaId = isEditing ? nilai['siswa_id'] : null;
    String? selectedSiswaName = isEditing ? nilai['siswa_nama'] : null;
    final mapelCtrl = TextEditingController(text: isEditing ? nilai['mapel'] : widget.userData['kelas'] ?? '');
    final nilaiCtrl = TextEditingController(text: isEditing ? nilai['nilai']?.toString() : '');
    final keteranganCtrl = TextEditingController(text: isEditing ? nilai['keterangan'] : '');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(isEditing ? 'Edit Nilai' : 'Input Nilai Siswa'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedSiswaId,
                  decoration: const InputDecoration(labelText: 'Pilih Siswa', border: OutlineInputBorder()),
                  items: _userList.map<DropdownMenuItem<String>>((u) {
                    return DropdownMenuItem<String>(value: u['id'], child: Text(u['nama'] ?? '-'));
                  }).toList(),
                  onChanged: (val) => setDialogState(() {
                    selectedSiswaId = val;
                    selectedSiswaName = _userList.firstWhere((u) => u['id'] == val, orElse: () => {})['nama'];
                  }),
                ),
                const SizedBox(height: 12),
                TextField(controller: mapelCtrl, decoration: const InputDecoration(labelText: 'Mata Pelajaran', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(controller: nilaiCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Nilai (0-100)', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(controller: keteranganCtrl, decoration: const InputDecoration(labelText: 'Keterangan (opsional)', border: OutlineInputBorder())),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
            ElevatedButton(
              onPressed: () async {
                if (selectedSiswaId == null || nilaiCtrl.text.isEmpty) return;
                final body = {
                  'siswa_id': selectedSiswaId,
                  'siswa_nama': selectedSiswaName,
                  'guru_id': widget.userData['id'],
                  'mapel': mapelCtrl.text,
                  'nilai': double.tryParse(nilaiCtrl.text) ?? 0,
                  'keterangan': keteranganCtrl.text,
                };
                final headers = {'Content-Type': 'application/json', 'Authorization': 'Bearer ${widget.token}'};
                try {
                  if (isEditing) {
                    await http.put(Uri.parse('$baseUrl/api/nilai/${nilai['id']}'), headers: headers, body: jsonEncode(body));
                  } else {
                    await http.post(Uri.parse('$baseUrl/api/nilai'), headers: headers, body: jsonEncode(body));
                  }
                  if (ctx.mounted) Navigator.pop(ctx);
                  _fetchData();
                } catch (e) {
                  debugPrint('Error saving: $e');
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showNilaiForm(),
        backgroundColor: Colors.blue.shade800,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Input Nilai', style: TextStyle(color: Colors.white)),
      ),
      body: _nilaiList.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.grade_outlined, size: 80, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text('Belum ada nilai yang diinput.', style: TextStyle(color: Colors.grey.shade600)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
              itemCount: _nilaiList.length,
              itemBuilder: (context, index) {
                final n = _nilaiList[index];
                final nilai = (n['nilai'] is String ? double.tryParse(n['nilai']) : n['nilai']?.toDouble()) ?? 0;
                Color color = nilai >= 85 ? Colors.green.shade700 : nilai >= 75 ? Colors.blue.shade700 : nilai >= 65 ? Colors.orange.shade700 : Colors.red.shade700;
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: color.withOpacity(0.1),
                      child: Text('${n['nilai'] ?? '-'}', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                    title: Text(n['siswa_nama'] ?? 'Siswa', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${n['mapel'] ?? '-'} • ${n['keterangan'] ?? ''}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(icon: const Icon(Icons.edit, color: Colors.orange), onPressed: () => _showNilaiForm(n)),
                        IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () async { if (await confirmDelete(context, pesan: 'Yakin hapus nilai ini?')) _deleteNilai(n['id']); }),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
