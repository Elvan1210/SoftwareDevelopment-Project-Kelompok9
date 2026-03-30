import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'guru_tugas_view.dart';
import 'guru_materi_view.dart';
import 'guru_nilai_view.dart';
import 'guru_presensi_view.dart';
import '../../../widgets/notification_bell.dart';

class GuruTeamDetailLayout extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String token;
  final dynamic teamData; // Menerima data tim yang diklik

  const GuruTeamDetailLayout({
    super.key,
    required this.userData,
    required this.token,
    required this.teamData,
  });

  @override
  State<GuruTeamDetailLayout> createState() => _GuruTeamDetailLayoutState();
}

class _GuruTeamDetailLayoutState extends State<GuruTeamDetailLayout> {
  int _selectedIndex = 0;
  late List<Widget> _views;

  final List<String> _titles = [
    'Dashboard Tim',
    'Saluran (Channels)',
    'Presensi',
    'Tugas',
    'Materi',
    'Nilai',
  ];

  @override
  void initState() {
    super.initState();
    _views = [
      // 0. Dashboard Tim (Placeholder sementara)
      Center(child: Text('Dashboard ${widget.teamData['nama_kelas']}\n(Ringkasan aktivitas akan muncul di sini)', textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
      // 1. Saluran (Placeholder sementara)
      const Center(child: Text('Fitur Chat / Saluran Sedang Dibangun...', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
      
      // Menggunakan View lama Anda (Nantinya API di dalam view ini harus difilter berdasarkan teamData['id'])
      GuruPresensiView(userData: widget.userData, token: widget.token),
      GuruTugasView(userData: widget.userData, token: widget.token, teamData: widget.teamData),
      GuruMateriView(userData: widget.userData, token: widget.token, teamData: widget.teamData),
      GuruNilaiView(userData: widget.userData, token: widget.token),
    ];
  }

  Widget _buildWebLayout(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [Colors.black, Colors.black]
                : [Colors.white, Colors.white],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Row(
            children: [
              // Sidebar Spesifik Tim
              Container(
                width: 260,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface.withAlpha(isDark ? 150 : 180),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: Colors.white.withAlpha(isDark ? 20 : 100), width: 1.5),
                  boxShadow: [BoxShadow(color: Colors.black.withAlpha(15), blurRadius: 40, offset: const Offset(0, 20))],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(32),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                          child: InkWell(
                            onTap: () => Navigator.pop(context),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: theme.primaryColor.withAlpha(20),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.arrow_back_rounded, color: theme.primaryColor),
                                  const SizedBox(width: 8),
                                  Text('Kembali ke Semua Tim', style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.bold, fontSize: 12)),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Text(
                            widget.teamData['nama_kelas'] ?? 'Ruang Kelas',
                            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900, color: theme.primaryColor, height: 1.2),
                            maxLines: 2, overflow: TextOverflow.ellipsis,
                          ).animate().fadeIn().slideX(),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                          child: Text(widget.teamData['kode_kelas'] ?? '-', style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600)),
                        ),
                        const Divider(height: 32),
                        Expanded(
                          child: NavigationRail(
                            extended: true,
                            backgroundColor: Colors.transparent,
                            minExtendedWidth: 260,
                            indicatorColor: theme.primaryColor.withAlpha(40),
                            unselectedLabelTextStyle: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                            selectedLabelTextStyle: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800, color: theme.primaryColor),
                            selectedIndex: _selectedIndex,
                            onDestinationSelected: (int index) => setState(() => _selectedIndex = index),
                            destinations: const [
                              NavigationRailDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: Text('Dashboard')),
                              NavigationRailDestination(icon: Icon(Icons.chat_bubble_outline), selectedIcon: Icon(Icons.chat_bubble), label: Text('Saluran')),
                              NavigationRailDestination(icon: Icon(Icons.how_to_reg_outlined), selectedIcon: Icon(Icons.how_to_reg), label: Text('Presensi')),
                              NavigationRailDestination(icon: Icon(Icons.assignment_outlined), selectedIcon: Icon(Icons.assignment), label: Text('Tugas')),
                              NavigationRailDestination(icon: Icon(Icons.menu_book_outlined), selectedIcon: Icon(Icons.menu_book), label: Text('Materi')),
                              NavigationRailDestination(icon: Icon(Icons.grade_outlined), selectedIcon: Icon(Icons.grade), label: Text('Nilai')),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 32),
              // Area Konten Utama
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface.withAlpha(isDark ? 200 : 220),
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(color: Colors.white.withAlpha(isDark ? 10 : 150), width: 1),
                    boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 40, offset: const Offset(0, 10))],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(32),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                      child: Scaffold(
                        backgroundColor: Colors.transparent,
                        appBar: AppBar(
                          backgroundColor: Colors.transparent,
                          title: Text(_titles[_selectedIndex]).animate(key: ValueKey(_selectedIndex)).fade(),
                          actions: [
                            NotificationBell(userData: widget.userData, token: widget.token, iconColor: theme.iconTheme.color ?? Colors.black87),
                            const SizedBox(width: 24),
                          ],
                        ),
                        body: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: KeyedSubtree(key: ValueKey(_selectedIndex), child: _views[_selectedIndex]),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface.withAlpha(isDark ? 200 : 240),
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.teamData['nama_kelas'] ?? 'Tim', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text(_titles[_selectedIndex], style: TextStyle(fontSize: 12, color: theme.primaryColor, fontWeight: FontWeight.w600)),
          ],
        ),
        actions: [
          NotificationBell(userData: widget.userData, token: widget.token, iconColor: theme.iconTheme.color ?? Colors.black87),
          const SizedBox(width: 8),
        ],
      ),
      body: Container(
        padding: const EdgeInsets.only(top: 100), // Spacing for AppBar
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark ? [Colors.black, Colors.black] : [Colors.white, Colors.white],
          ),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: KeyedSubtree(key: ValueKey(_selectedIndex), child: _views[_selectedIndex]),
        ),
      ),
      bottomNavigationBar: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: NavigationBar(
            backgroundColor: theme.colorScheme.surface.withAlpha(isDark ? 180 : 220),
            indicatorColor: theme.primaryColor.withAlpha(40),
            selectedIndex: _selectedIndex,
            onDestinationSelected: (int index) => setState(() => _selectedIndex = index),
            destinations: const [
              NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Dasbor'),
              NavigationDestination(icon: Icon(Icons.chat_bubble_outline), selectedIcon: Icon(Icons.chat_bubble), label: 'Chat'),
              NavigationDestination(icon: Icon(Icons.how_to_reg_outlined), selectedIcon: Icon(Icons.how_to_reg), label: 'Hadir'),
              NavigationDestination(icon: Icon(Icons.assignment_outlined), selectedIcon: Icon(Icons.assignment), label: 'Tugas'),
              NavigationDestination(icon: Icon(Icons.menu_book_outlined), selectedIcon: Icon(Icons.menu_book), label: 'Materi'),
              NavigationDestination(icon: Icon(Icons.grade_outlined), selectedIcon: Icon(Icons.grade), label: 'Nilai'),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      if (constraints.maxWidth > 900) return _buildWebLayout(context);
      return _buildMobileLayout(context);
    });
  }
}