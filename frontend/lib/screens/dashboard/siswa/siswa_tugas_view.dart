import 'package:flutter/material.dart';
import '../../../config/api_config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'siswa_tugas_detail_screen.dart';

class SiswaTugasView extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String token;
  const SiswaTugasView({super.key, required this.userData, required this.token});

  @override
  State<SiswaTugasView> createState() => _SiswaTugasViewState();
}

class _SiswaTugasViewState extends State<SiswaTugasView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _allTugas = [];
  List<dynamic> _pengumpulan = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final headers = {'Authorization': 'Bearer ${widget.token}'};
      final resTugas = await http.get(Uri.parse('$baseUrl/api/tugas'), headers: headers);
      final resPengumpulan = await http.get(Uri.parse('$baseUrl/api/pengumpulan'), headers: headers);

      if (resTugas.statusCode == 200) {
        List all = jsonDecode(resTugas.body);
        setState(() {
          _allTugas = all
              .where((t) =>
                  t['kelas'] == widget.userData['kelas'] ||
                  t['mapel'] == widget.userData['kelas'])
              .toList();
        });
      }
      if (resPengumpulan.statusCode == 200) {
        List all = jsonDecode(resPengumpulan.body);
        setState(() {
          _pengumpulan = all.where((p) => p['siswa_id'] == widget.userData['id']).toList();
        });
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  bool _sudahDikumpulkan(String tugasId) {
    return _pengumpulan.any((p) => p['tugas_id'] == tugasId);
  }

  List<dynamic> get _tugasBelum =>
      _allTugas.where((t) => !_sudahDikumpulkan(t['id'])).toList();

  List<dynamic> get _tugasSelesai =>
      _allTugas.where((t) => _sudahDikumpulkan(t['id'])).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Tugas', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black87,
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.blue.shade800,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.blue.shade800,
          indicatorWeight: 3,
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Semua'),
                  const SizedBox(width: 6),
                  _badge(_allTugas.length, Colors.blue.shade800),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Belum'),
                  const SizedBox(width: 6),
                  _badge(_tugasBelum.length, Colors.orange.shade700),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Selesai'),
                  const SizedBox(width: 6),
                  _badge(_tugasSelesai.length, Colors.green.shade700),
                ],
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildList(_allTugas),
                _buildList(_tugasBelum),
                _buildList(_tugasSelesai),
              ],
            ),
    );
  }

  Widget _badge(int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$count',
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }

  Widget _buildList(List<dynamic> list) {
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_turned_in_outlined, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text('Tidak ada tugas di sini.', style: TextStyle(color: Colors.grey.shade500, fontSize: 15)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: list.length,
        itemBuilder: (context, index) {
          final t = list[index];
          final selesai = _sudahDikumpulkan(t['id']);
          return _tugasCard(t, selesai);
        },
      ),
    );
  }

  Widget _tugasCard(Map<String, dynamic> tugas, bool selesai) {
    final Color statusColor = selesai ? Colors.green.shade700 : Colors.orange.shade700;
    final String statusLabel = selesai ? 'Dikumpulkan' : 'Belum Dikumpulkan';
    final IconData statusIcon = selesai ? Icons.check_circle : Icons.radio_button_unchecked;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SiswaTugasDetailScreen(
                tugas: tugas,
                userData: widget.userData,
                token: widget.token,
              ),
            ),
          );
          _fetchData(); // refresh status setelah kembali
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: mapel + status chip
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      tugas['mapel'] ?? widget.userData['kelas'] ?? 'Mapel',
                      style: TextStyle(fontSize: 12, color: Colors.blue.shade800, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const Spacer(),
                  Icon(statusIcon, color: statusColor, size: 18),
                  const SizedBox(width: 4),
                  Text(
                    statusLabel,
                    style: TextStyle(fontSize: 12, color: statusColor, fontWeight: FontWeight.w600),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Judul tugas
              Text(
                tugas['judul'] ?? 'Tugas',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 8),

              // Footer: deadline + tombol action
              Row(
                children: [
                  Icon(Icons.schedule, size: 15, color: Colors.grey.shade500),
                  const SizedBox(width: 4),
                  Text(
                    'Deadline: ${tugas['deadline'] ?? '-'}',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                  const Spacer(),
                  selesai
                      ? OutlinedButton(
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => SiswaTugasDetailScreen(
                                  tugas: tugas,
                                  userData: widget.userData,
                                  token: widget.token,
                                ),
                              ),
                            );
                            _fetchData();
                          },
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.green.shade600),
                            foregroundColor: Colors.green.shade700,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text('Lihat', style: TextStyle(fontSize: 12)),
                        )
                      : ElevatedButton(
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => SiswaTugasDetailScreen(
                                  tugas: tugas,
                                  userData: widget.userData,
                                  token: widget.token,
                                ),
                              ),
                            );
                            _fetchData();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade800,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            elevation: 0,
                          ),
                          child: const Text('Kerjakan', style: TextStyle(fontSize: 12)),
                        ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
