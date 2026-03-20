import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class GuruDashboardView extends StatefulWidget {
  final Map<String, dynamic> userData;
  const GuruDashboardView({super.key, required this.userData});

  @override
  State<GuruDashboardView> createState() => _GuruDashboardViewState();
}

class _GuruDashboardViewState extends State<GuruDashboardView> {
  int _totalTugas = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    try {
      final response = await http.get(Uri.parse('http://localhost:3000/api/tugas'));
      if (response.statusCode == 200) {
        List data = jsonDecode(response.body);
        int myTugas = data.where((t) => t['guru_id'] == widget.userData['id']).length;
        setState(() => _totalTugas = myTugas);
      }
    } catch (e) {
      debugPrint("Error: $e");
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Mata Pelajaran: ${widget.userData['kelas']}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Card(
            color: Colors.blue.shade50,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  const Icon(Icons.assignment, size: 40, color: Colors.blue),
                  const SizedBox(height: 10),
                  Text('Tugas Aktif yang Dibuat', style: TextStyle(color: Colors.grey.shade700)),
                  Text(_totalTugas.toString(), style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.blue)),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}