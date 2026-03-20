import 'package:flutter/material.dart';
import '../../auth/login_screen.dart';
import 'guru_dashboard_view.dart';
import 'guru_tugas_view.dart';

class GuruMainLayout extends StatefulWidget {
  final Map<String, dynamic> userData;
  const GuruMainLayout({super.key, required this.userData});

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
      GuruTugasView(userData: widget.userData),
      const Center(child: Text('Modul Nilai Siswa')),
      const Center(child: Text('Modul Materi')),
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
          NavigationDestination(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.assignment), label: 'Kelola Tugas'),
          NavigationDestination(icon: Icon(Icons.grade), label: 'Input Nilai'),
          NavigationDestination(icon: Icon(Icons.book), label: 'Materi'),
        ],
      ),
    );
  }
}