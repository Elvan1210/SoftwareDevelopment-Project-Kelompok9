import 'package:flutter/material.dart';
import '../../auth/login_screen.dart';
import 'guru_dashboard_view.dart';
import 'guru_tugas_view.dart';
import 'guru_materi_view.dart';
import 'guru_nilai_view.dart';
import 'guru_pengumuman_view.dart';
import 'guru_profil_view.dart';

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
      GuruDashboardView(userData: widget.userData, token: widget.token),
      GuruTugasView(userData: widget.userData, token: widget.token),
      GuruMateriView(userData: widget.userData, token: widget.token),
      GuruNilaiView(userData: widget.userData, token: widget.token),
      GuruPengumumanView(userData: widget.userData, token: widget.token),
      GuruProfilView(userData: widget.userData),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final List<String> titles = [
      'Dashboard',
      'Kelola Tugas',
      'Kelola Materi',
      'Input Nilai',
      'Pengumuman',
      'Profil',
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(titles[_selectedIndex], style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black87,
      ),
      body: _views[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (int index) => setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.assignment_outlined), selectedIcon: Icon(Icons.assignment), label: 'Tugas'),
          NavigationDestination(icon: Icon(Icons.menu_book_outlined), selectedIcon: Icon(Icons.menu_book), label: 'Materi'),
          NavigationDestination(icon: Icon(Icons.grade_outlined), selectedIcon: Icon(Icons.grade), label: 'Nilai'),
          NavigationDestination(icon: Icon(Icons.campaign_outlined), selectedIcon: Icon(Icons.campaign), label: 'Pengumuman'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }
}