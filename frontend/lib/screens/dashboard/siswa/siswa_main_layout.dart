import 'package:flutter/material.dart';
import '../../auth/login_screen.dart';
import 'siswa_dashboard_screen.dart';
import 'siswa_tugas_detail_screen.dart';
import 'siswa_tugas_view.dart';
import 'siswa_nilai_view.dart';
import 'siswa_pengumuman_view.dart';
import 'siswa_materi_view.dart';
import 'siswa_profil_view.dart';

class SiswaMainLayout extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String token;
  const SiswaMainLayout({super.key, required this.userData, required this.token});

  @override
  State<SiswaMainLayout> createState() => _SiswaMainLayoutState();
}

class _SiswaMainLayoutState extends State<SiswaMainLayout> {
  int _selectedIndex = 0;
  late List<Widget> _views;

  @override
  void initState() {
    super.initState();
    _views = [
      SiswaDashboardScreen(userData: widget.userData, token: widget.token),
      SiswaTugasView(userData: widget.userData, token: widget.token),
      SiswaMateriView(userData: widget.userData, token: widget.token),
      SiswaNilaiView(userData: widget.userData, token: widget.token),
      SiswaPengumumanView(userData: widget.userData, token: widget.token),
      SiswaProfilView(userData: widget.userData),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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

