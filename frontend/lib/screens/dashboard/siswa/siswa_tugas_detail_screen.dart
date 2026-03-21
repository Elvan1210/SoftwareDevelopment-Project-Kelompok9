import 'package:flutter/material.dart';
import '../../../config/api_config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:file_picker/file_picker.dart';

class SiswaTugasDetailScreen extends StatefulWidget {
  final Map<String, dynamic> tugas;
  final Map<String, dynamic> userData;
  final String token;

  const SiswaTugasDetailScreen({super.key, required this.tugas, required this.userData, required this.token});

  @override
  State<SiswaTugasDetailScreen> createState() => _SiswaTugasDetailScreenState();
}

class _SiswaTugasDetailScreenState extends State<SiswaTugasDetailScreen> {
  bool _isLoading = true;
  bool _isTurnedIn = false;
  String? _pengumpulanId;
  List<String> _attachments = [];

  @override
  void initState() {
    super.initState();
    _checkSubmissionStatus();
  }

  Future<void> _checkSubmissionStatus() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/pengumpulan'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      if (response.statusCode == 200) {
        List allData = jsonDecode(response.body);
        var submission = allData.where((p) => p['tugas_id'] == widget.tugas['id'] && p['siswa_id'] == widget.userData['id']).toList();

        if (submission.isNotEmpty) {
          setState(() {
            _isTurnedIn = true;
            _pengumpulanId = submission[0]['id'];
            _attachments = List<String>.from(submission[0]['files'] ?? []);
          });
        }
      }
    } catch (e) {
      debugPrint("Error Check Status: $e");
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _pickFiles() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(allowMultiple: true);
    if (result != null) {
      setState(() {
        for (var file in result.files) {
          if (!_attachments.contains(file.name)) {
            _attachments.add(file.name);
          }
        }
      });
    }
  }

  void _removeFile(int index) {
    setState(() {
      _attachments.removeAt(index);
    });
  }

  Future<void> _turnIn() async {
    if (_attachments.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pilih file terlebih dahulu sebelum Turn In!'), backgroundColor: Colors.orange));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final body = {
        'tugas_id': widget.tugas['id'],
        'siswa_id': widget.userData['id'],
        'siswa_nama': widget.userData['nama'],
        'files': _attachments,
        'waktu_pengumpulan': DateTime.now().toIso8601String(),
      };
      final response = await http.post(
        Uri.parse('$baseUrl/api/pengumpulan'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer ${widget.token}'},
        body: jsonEncode(body)
      );

      if (response.statusCode == 201) {
        final resData = jsonDecode(response.body);
        setState(() {
          _isTurnedIn = true;
          _pengumpulanId = resData['id'];
        });
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tugas berhasil dikumpulkan!'), backgroundColor: Colors.green));
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal mengirim: ${response.statusCode} - ${response.body}'), backgroundColor: Colors.red));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error Server/Koneksi: $e'), backgroundColor: Colors.red));
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _undoTurnIn() async {
    if (_pengumpulanId == null) return;
    setState(() => _isLoading = true);
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/api/pengumpulan/$_pengumpulanId'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      if (response.statusCode == 200) {
        setState(() {
          _isTurnedIn = false;
          _pengumpulanId = null;
        });
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pengumpulan dibatalkan'), backgroundColor: Colors.orange));
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal membatalkan: ${response.body}'), backgroundColor: Colors.red));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error jaringan: $e'), backgroundColor: Colors.red));
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Colors.deepPurple.shade700;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Tugas', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 1,
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: _isLoading
              ? const Center(child: Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))))
              : _isTurnedIn
                  ? OutlinedButton(
                      onPressed: _undoTurnIn,
                      style: OutlinedButton.styleFrom(side: BorderSide(color: primaryColor)),
                      child: Text('Undo turn in', style: TextStyle(color: primaryColor)),
                    )
                  : ElevatedButton(
                      onPressed: _turnIn,
                      style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
                      child: const Text('Turn in', style: TextStyle(color: Colors.white)),
                    ),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.tugas['judul'] ?? 'Tanpa Judul', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Jatuh tempo: ${widget.tugas['deadline']}', style: TextStyle(fontSize: 16, color: Colors.grey.shade700)),
            const SizedBox(height: 4),
            Text('Mata Pelajaran: ${widget.tugas['mapel'] ?? widget.tugas['kelas']}', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            // Menampilkan Deskripsi bila ada
            if ((widget.tugas['deskripsi'] ?? '').toString().isNotEmpty) ...[
              const Text('Deskripsi:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(
                widget.tugas['deskripsi'],
                style: const TextStyle(fontSize: 16, height: 1.5),
              ),
              const SizedBox(height: 24),
            ],

            // Menampilkan Link bila ada
            if ((widget.tugas['link'] ?? '').toString().isNotEmpty) ...[
              const Text('Link Pendukung:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SelectableText(
                widget.tugas['link'],
                style: const TextStyle(fontSize: 16, color: Colors.blue, decoration: TextDecoration.underline),
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
            ],

            const Text('My work', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            if (_attachments.isNotEmpty)
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _attachments.length,
                itemBuilder: (context, index) {
                  return Card(
                    elevation: 0,
                    color: Colors.grey.shade100,
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: const Icon(Icons.insert_drive_file, color: Colors.blue),
                      title: Text(_attachments[index]),
                      trailing: _isTurnedIn
                          ? null
                          : IconButton(icon: const Icon(Icons.close), onPressed: () => _removeFile(index)),
                    ),
                  );
                },
              ),
            if (!_isTurnedIn)
              InkWell(
                onTap: _pickFiles,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  child: Row(
                    children: [
                      Icon(Icons.add, color: primaryColor),
                      const SizedBox(width: 8),
                      Text('Add work', style: TextStyle(color: primaryColor, fontSize: 16, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}