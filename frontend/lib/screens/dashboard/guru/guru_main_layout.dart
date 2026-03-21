import 'package:flutter/material.dart';
import '../../auth/login_screen.dart';
import 'guru_dashboard_view.dart';
import 'guru_tugas_view.dart';
import 'guru_nilai_view.dart';
import 'guru_pengumuman_view.dart';

class GuruMainLayout extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String token;
  const GuruMainLayout({super.key, required this.userData, required this.token});

  @override
  State<GuruMainLayout> createState() => _GuruMainLayoutState();
}

class _GuruMainLayoutState extends State<GuruMainLayout> {
  int _selectedIndex = 0;
  late List<Widget> _views;

  @override
  void initState() {
    super.initState();
    _views = [
      GuruDashboardView(userData: widget.userData),
      GuruTugasView(userData: widget.userData, token: widget.token),
      GuruNilaiView(userData: widget.userData, token: widget.token),
      GuruPengumumanView(userData: widget.userData, token: widget.token),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Portal Guru - ${widget.userData['nama']}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen())),
          ),
        ],
      ),
      body: _views[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (int index) => setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.assignment_outlined), selectedIcon: Icon(Icons.assignment), label: 'Kelola Tugas'),
          NavigationDestination(icon: Icon(Icons.grade_outlined), selectedIcon: Icon(Icons.grade), label: 'Input Nilai'),
          NavigationDestination(icon: Icon(Icons.campaign_outlined), selectedIcon: Icon(Icons.campaign), label: 'Pengumuman'),
        ],
      ),
    );
  }
}