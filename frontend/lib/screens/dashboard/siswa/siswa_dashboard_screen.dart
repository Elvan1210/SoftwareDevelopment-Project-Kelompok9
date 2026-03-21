import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../auth/login_screen.dart';
import 'siswa_tugas_detail_screen.dart';

class SiswaDashboardScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String token;
  const SiswaDashboardScreen({super.key, required this.userData, required this.token});

  @override
  State<SiswaDashboardScreen> createState() => _SiswaDashboardScreenState();
}

class _SiswaDashboardScreenState extends State<SiswaDashboardScreen> {
  int _selectedIndex = 0;
  bool _isLoading = true;
  List<dynamic> _tugasList = [];
  List<dynamic> _pengumumanList = [];
  int _pendingTasks = 0;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final headers = {'Authorization': 'Bearer ${widget.token}'};
      final resTugas = await http.get(Uri.parse('http://localhost:3000/api/tugas'), headers: headers);
      final resPengumuman = await http.get(Uri.parse('http://localhost:3000/api/pengumuman'), headers: headers);

      if (resTugas.statusCode == 200) {
        List allTugas = jsonDecode(resTugas.body);
        _tugasList = allTugas.where((t) => t['mapel'] == widget.userData['kelas'] || t['kelas'] == widget.userData['kelas']).toList();
        _pendingTasks = _tugasList.length;
      }

      if (resPengumuman.statusCode == 200) {
        _pengumumanList = jsonDecode(resPengumuman.body);
      }
    } catch (e) {
      debugPrint(e.toString());
    }
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Colors.blue.shade800;
    final Color secondaryColor = Colors.purple.shade600;
    final Color cardBackgroundColor = Colors.white;
    final Color shadowColor = Colors.grey.withOpacity(0.1);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: _buildAppBar(primaryColor, context),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildOverviewSection(primaryColor, secondaryColor),
                  const SizedBox(height: 24),
                  _buildSectionTitle(context, "Tugas Kelas", Icons.assignment),
                  const SizedBox(height: 12),
                  _buildAssignmentsSection(cardBackgroundColor, shadowColor),
                  const SizedBox(height: 24),
                  _buildSectionTitle(context, "Pengumuman", Icons.announcement),
                  const SizedBox(height: 12),
                  _buildAnnouncementsSection(cardBackgroundColor, shadowColor),
                ],
              ),
            ),
      bottomNavigationBar: _buildBottomNavigationBar(primaryColor),
    );
  }

  PreferredSizeWidget _buildAppBar(Color primaryColor, BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          CircleAvatar(
            backgroundColor: primaryColor,
            radius: 20,
            child: const Icon(Icons.person, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Selamat Datang,", style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
              Text(widget.userData['nama'] ?? 'Siswa', style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.logout, color: Colors.red.shade400),
          onPressed: () {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildOverviewSection(Color primaryColor, Color secondaryColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildOverviewCard("Tugas Kelas", _pendingTasks.toString(), Icons.pending_actions, primaryColor),
        _buildOverviewCard("Pengumuman", _pengumumanList.length.toString(), Icons.campaign, Colors.orange.shade600),
        _buildOverviewCard("Kelas", widget.userData['kelas'] ?? '-', Icons.class_, secondaryColor),
      ],
    );
  }

  Widget _buildOverviewCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        elevation: 0,
        color: color.withOpacity(0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
              Text(title, style: TextStyle(fontSize: 12, color: color.withOpacity(0.8)), overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey.shade600, size: 20),
        const SizedBox(width: 8),
        Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, fontSize: 18)),
      ],
    );
  }

  Widget _buildAssignmentsSection(Color cardColor, Color shadowColor) {
    if (_tugasList.isEmpty) {
      return const Center(child: Padding(padding: EdgeInsets.all(16.0), child: Text("Belum ada tugas untuk kelas ini.")));
    }
    return Card(
      elevation: 2,
      color: cardColor,
      shadowColor: shadowColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: _tugasList.map((task) {
          return ListTile(
            leading: const Icon(Icons.radio_button_unchecked, color: Colors.orange),
            title: Text(task["judul"] ?? '-', style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text("Deadline: ${task['deadline'] ?? '-'}"),
            trailing: ElevatedButton(
              onPressed: () async {
                await Navigator.push(context, MaterialPageRoute(builder: (context) => SiswaTugasDetailScreen(tugas: task, userData: widget.userData, token: widget.token)));
                _fetchData();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade800,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text("Detail", style: TextStyle(color: Colors.white)),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAnnouncementsSection(Color cardColor, Color shadowColor) {
    if (_pengumumanList.isEmpty) {
      return const Center(child: Padding(padding: EdgeInsets.all(16.0), child: Text("Belum ada pengumuman.")));
    }
    return Column(
      children: _pengumumanList.map((pengumuman) {
        return Card(
          elevation: 2,
          color: cardColor,
          shadowColor: shadowColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: const Icon(Icons.campaign_outlined, color: Colors.orange),
            title: Text(pengumuman["judul"] ?? '-', style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(pengumuman["isi"] ?? '-'),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBottomNavigationBar(Color primaryColor) {
    return BottomNavigationBar(
      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
        BottomNavigationBarItem(icon: Icon(Icons.assignment), label: 'Tugas'),
        BottomNavigationBarItem(icon: Icon(Icons.book), label: 'Materi'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
      ],
      currentIndex: _selectedIndex,
      selectedItemColor: primaryColor,
      unselectedItemColor: Colors.grey.shade600,
      onTap: _onItemTapped,
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
    );
  }
}