import 'package:flutter/material.dart';
import 'admin_dashboard_view.dart';
import 'user_management_view.dart';
import 'kelas_management_view.dart';
import 'admin_materi_view.dart';
import 'admin_tugas_view.dart';
import 'admin_nilai_view.dart';
import 'admin_pengumuman_view.dart';
import 'admin_profil_view.dart';

class AdminMainLayout extends StatefulWidget {
  final String token;
  const AdminMainLayout({super.key, this.token = ''});

  @override
  State<AdminMainLayout> createState() => _AdminMainLayoutState();
}

class _AdminMainLayoutState extends State<AdminMainLayout> {
  int _selectedIndex = 0;

  final List<Widget> _views = [];

  @override
  void initState() {
    super.initState();
    _views.addAll([
      AdminDashboardView(token: widget.token),
      UserManagementView(token: widget.token),
      KelasManagementView(token: widget.token),
      AdminMateriView(token: widget.token),
      AdminTugasView(token: widget.token),
      AdminNilaiView(token: widget.token),
      AdminPengumumanView(token: widget.token),
      AdminProfilView(token: widget.token),
    ]);
  }

  final List<NavigationDestination> _navItems = const [
    NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Dashboard'),
    NavigationDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people), label: 'Users'),
    NavigationDestination(icon: Icon(Icons.class_outlined), selectedIcon: Icon(Icons.class_), label: 'Kelas'),
    NavigationDestination(icon: Icon(Icons.book_outlined), selectedIcon: Icon(Icons.book), label: 'Materi'),
    NavigationDestination(icon: Icon(Icons.assignment_outlined), selectedIcon: Icon(Icons.assignment), label: 'Tugas'),
    NavigationDestination(icon: Icon(Icons.grade_outlined), selectedIcon: Icon(Icons.grade), label: 'Nilai'),
    NavigationDestination(icon: Icon(Icons.campaign_outlined), selectedIcon: Icon(Icons.campaign), label: 'Pengumuman'),
    NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profil'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_navItems[_selectedIndex].label, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black87,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 800) {
            return _views[_selectedIndex]; // Tampilan Mobile
          } else {
            // Tampilan Desktop / Tablet
            bool isExtended = constraints.maxWidth >= 1000;
            
            return Row(
              children: [
                NavigationRail(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: (int index) => setState(() => _selectedIndex = index),
                  labelType: isExtended ? NavigationRailLabelType.none : NavigationRailLabelType.all,
                  extended: isExtended,
                  destinations: _navItems.map((e) => NavigationRailDestination(
                    icon: e.icon, 
                    selectedIcon: e.selectedIcon, 
                    label: Text(e.label),
                  )).toList(),
                ),
                const VerticalDivider(thickness: 1, width: 1),
                Expanded(child: _views[_selectedIndex]),
              ],
            );
          }
        },
      ),
      bottomNavigationBar: MediaQuery.of(context).size.width < 800
          ? NavigationBar(
              selectedIndex: _selectedIndex < 5 ? _selectedIndex : 0, 
              onDestinationSelected: (int index) => setState(() => _selectedIndex = index),
              destinations: _navItems.take(5).toList(), 
            )
          : null,
    );
  }
}