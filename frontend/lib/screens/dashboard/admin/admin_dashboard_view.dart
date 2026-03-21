import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../widgets/stat_card.dart';
import '../../../config/api_config.dart';

class AdminDashboardView extends StatefulWidget {
  final String token;
  const AdminDashboardView({super.key, required this.token});

  @override
  State<AdminDashboardView> createState() => _AdminDashboardViewState();
}

class _AdminDashboardViewState extends State<AdminDashboardView> {
  int _totalSiswa = 0;
  int _totalGuru = 0;
  int _totalKelas = 0;
  int _totalMapel = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    try {
      final headers = {'Authorization': 'Bearer ${widget.token}'};
      final results = await Future.wait([
        http.get(Uri.parse('$baseUrl/api/users'), headers: headers),
        http.get(Uri.parse('$baseUrl/api/kelas'), headers: headers),
      ]);

      if (results[0].statusCode == 200) {
        List users = jsonDecode(results[0].body);
        _totalSiswa = users.where((u) => u['role'] == 'Siswa').length;
        
        final gurus = users.where((u) => u['role'] == 'Guru').toList();
        _totalGuru = gurus.length;
        
        // Hitung mapel unik dari kolom 'kelas' milik para Guru
        Set<String> mapels = {};
        for (var g in gurus) {
          final m = (g['kelas'] ?? '').toString().trim();
          if (m.isNotEmpty && m != '-') mapels.add(m.toUpperCase());
        }
        _totalMapel = mapels.length;
      }
      
      if (results[1].statusCode == 200) {
        List kelas = jsonDecode(results[1].body);
        _totalKelas = kelas.length;
      }
    } catch (e) {
      debugPrint("Error fetching admin stats: $e");
    }
    
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              int cols = constraints.maxWidth > 800 ? 4 : 2;
              return GridView.count(
                crossAxisCount: cols,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.5,
                children: [
                  StatCard(title: 'Total Siswa', value: '$_totalSiswa', icon: Icons.school, color: Colors.blue.shade600),
                  StatCard(title: 'Total Guru', value: '$_totalGuru', icon: Icons.person, color: Colors.purple.shade600),
                  StatCard(title: 'Total Kelas', value: '$_totalKelas', icon: Icons.class_, color: Colors.orange.shade600),
                  StatCard(title: 'Total Mapel', value: '$_totalMapel', icon: Icons.book, color: Colors.green.shade600),
                ],
              );
            },
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Text('Aktivitas Sistem', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(10)),
                child: const Text('Ilustrasi Visual', style: TextStyle(fontSize: 10, color: Colors.grey)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 300,
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    borderData: FlBorderData(show: false),
                    titlesData: FlTitlesData(
                      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (val, meta) => Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'][val.toInt()]),
                          ),
                        ),
                      ),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    barGroups: [
                      BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: 300, color: Colors.blue)]),
                      BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: 400, color: Colors.purple)]),
                      BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: 350, color: Colors.blue)]),
                      BarChartGroupData(x: 3, barRods: [BarChartRodData(toY: 450, color: Colors.purple)]),
                      BarChartGroupData(x: 4, barRods: [BarChartRodData(toY: 400, color: Colors.blue)]),
                      BarChartGroupData(x: 5, barRods: [BarChartRodData(toY: 100, color: Colors.grey)]),
                      BarChartGroupData(x: 6, barRods: [BarChartRodData(toY: 50, color: Colors.grey)]),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}