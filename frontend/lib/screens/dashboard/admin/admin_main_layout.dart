import 'package:flutter/material.dart';
import 'admin_dashboard_view.dart';
import 'user_management_view.dart';
import 'kelas_management_view.dart';
import '../../auth/login_screen.dart';

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
      const AdminDashboardView(),
      UserManagementView(token: widget.token),
      KelasManagementView(token: widget.token),
      const Center(child: Text('Modul Materi')),
      const Center(child: Text('Modul Tugas')),
      const Center(child: Text('Modul Nilai')),
      const Center(child: Text('Modul Jadwal')),
      const Center(child: Text('Modul Pengumuman')),
      const Center(child: Text('Settings')),
    ]);
  }

  final List<NavigationDestination> _navItems = const [
    NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Dashboard'),
    NavigationDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people), label: 'Users'),
    NavigationDestination(icon: Icon(Icons.class_outlined), selectedIcon: Icon(Icons.class_), label: 'Kelas'),
    NavigationDestination(icon: Icon(Icons.book_outlined), selectedIcon: Icon(Icons.book), label: 'Materi'),
    NavigationDestination(icon: Icon(Icons.assignment_outlined), selectedIcon: Icon(Icons.assignment), label: 'Tugas'),
    NavigationDestination(icon: Icon(Icons.grade_outlined), selectedIcon: Icon(Icons.grade), label: 'Nilai'),
    NavigationDestination(icon: Icon(Icons.schedule_outlined), selectedIcon: Icon(Icons.schedule), label: 'Jadwal'),
    NavigationDestination(icon: Icon(Icons.announcement_outlined), selectedIcon: Icon(Icons.announcement), label: 'Info'),
    NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_navItems[_selectedIndex].label, style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications),
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: const Text(
                      '2',
                      style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            onPressed: () {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
            },
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: CircleAvatar(backgroundColor: Colors.blueAccent, child: Text('AD', style: TextStyle(color: Colors.white))),
          )
        ],
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
                  // FIX: labelType diatur menjadi 'none' jika sidebar dalam keadaan extended
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
              selectedIndex: _selectedIndex < 4 ? _selectedIndex : 0, 
              onDestinationSelected: (int index) => setState(() => _selectedIndex = index),
              destinations: _navItems.take(4).toList(), 
            )
          : null,
    );
  }
}