import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'admin_dashboard_view.dart';
import 'user_management_view.dart';
import 'kelas_management_view.dart';
import 'admin_materi_view.dart';
import 'admin_tugas_view.dart';
import 'admin_nilai_view.dart';
import 'admin_pengumuman_view.dart';
import 'admin_profil_view.dart';
import '../../../widgets/notification_bell.dart';
import '../../../widgets/theme_toggle.dart';

class AdminMainLayout extends StatefulWidget {
  final String token;
  const AdminMainLayout({super.key, this.token = ''});

  @override
  State<AdminMainLayout> createState() => _AdminMainLayoutState();
}

class _AdminMainLayoutState extends State<AdminMainLayout> {
  int _selectedIndex = 0;
  late List<Widget> _views;

  final List<String> _titles = [
    'Admin Dashboard',
    'User Management',
    'Kelas Management',
    'Materi',
    'Tugas',
    'Nilai Akademik',
    'Pengumuman',
    'Admin Profil',
  ];

  @override
  void initState() {
    super.initState();
    _views = [
      AdminDashboardView(token: widget.token),
      UserManagementView(token: widget.token),
      KelasManagementView(token: widget.token),
      AdminMateriView(token: widget.token),
      AdminTugasView(token: widget.token),
      AdminNilaiView(token: widget.token),
      AdminPengumumanView(token: widget.token),
      AdminProfilView(token: widget.token),
    ];
  }

  final Map<String, dynamic> _adminUserData = const {
    'id': 'admin',
    'role': 'Admin',
    'nama': 'Administrator',
    'kelas': ''
  };

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
              // Sidebar
              Container(
                width: 260,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface.withAlpha(isDark ? 150 : 180),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: Colors.white.withAlpha(isDark ? 20 : 100), width: 1.5),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withAlpha(15), blurRadius: 40, offset: const Offset(0, 20)),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(32),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(32, 40, 32, 20),
                          child: Text(
                            'Admin\nPortal',
                            style: theme.textTheme.headlineMedium?.copyWith(color: theme.primaryColor, height: 1.1, fontWeight: FontWeight.w900),
                          ).animate().fadeIn(duration: 600.ms).slideX(begin: -0.2, curve: Curves.easeOutCubic),
                        ),
                        const SizedBox(height: 20),
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
                              NavigationRailDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people), label: Text('Users')),
                              NavigationRailDestination(icon: Icon(Icons.class_outlined), selectedIcon: Icon(Icons.class_), label: Text('Kelas')),
                              NavigationRailDestination(icon: Icon(Icons.book_outlined), selectedIcon: Icon(Icons.book), label: Text('Materi')),
                              NavigationRailDestination(icon: Icon(Icons.assignment_outlined), selectedIcon: Icon(Icons.assignment), label: Text('Tugas')),
                              NavigationRailDestination(icon: Icon(Icons.grade_outlined), selectedIcon: Icon(Icons.grade), label: Text('Nilai')),
                              NavigationRailDestination(icon: Icon(Icons.campaign_outlined), selectedIcon: Icon(Icons.campaign), label: Text('Pengumuman')),
                              NavigationRailDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: Text('Profil')),
                            ],
                          ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.1),
                        ),
                      ],
                    ),
                  ),
                ),
              ).animate().fadeIn(duration: 800.ms, curve: Curves.easeOutCirc).scale(begin: const Offset(0.95, 0.95)),
              
              const SizedBox(width: 32),
              
              // Main Content
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface.withAlpha(isDark ? 200 : 220),
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(color: Colors.white.withAlpha(isDark ? 10 : 150), width: 1),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 40, offset: const Offset(0, 10)),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(32),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                      child: Scaffold(
                        backgroundColor: Colors.transparent,
                        appBar: AppBar(
                          backgroundColor: Colors.transparent,
                          title: Text(_titles[_selectedIndex]).animate(key: ValueKey(_selectedIndex)).fade().slideX(begin: -0.1),
                          actions: [
                            ThemeToggle(iconColor: theme.iconTheme.color ?? Colors.black87),
                            NotificationBell(userData: _adminUserData, token: widget.token, iconColor: theme.iconTheme.color ?? Colors.black87),
                            const SizedBox(width: 24),
                          ],
                        ),
                        body: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 400),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeInCubic,
                          transitionBuilder: (child, animation) {
                            return FadeTransition(
                              opacity: animation,
                              child: SlideTransition(
                                position: Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero).animate(animation),
                                child: child,
                              ),
                            );
                          },
                          child: KeyedSubtree(
                            key: ValueKey(_selectedIndex),
                            child: _views[_selectedIndex],
                          ),
                        ),
                      ),
                    ),
                  ),
                ).animate().fadeIn(duration: 800.ms, delay: 100.ms).slideY(begin: 0.05, curve: Curves.easeOutQuart),
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
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface.withAlpha(isDark ? 150 : 200),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white.withAlpha(isDark ? 20 : 100)),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 20, offset: const Offset(0, 10)),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              _titles[_selectedIndex],
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900, letterSpacing: -0.5),
                              overflow: TextOverflow.ellipsis,
                            ).animate(key: ValueKey(_selectedIndex)).fade().slideX(begin: -0.1),
                          ),
                          ThemeToggle(iconColor: theme.iconTheme.color ?? Colors.black87),
                          NotificationBell(userData: _adminUserData, token: widget.token, iconColor: theme.iconTheme.color ?? Colors.black87),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) {
                    return FadeTransition(opacity: animation, child: SlideTransition(position: Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero).animate(animation), child: child));
                  },
                  child: KeyedSubtree(key: ValueKey(_selectedIndex), child: _views[_selectedIndex]),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withAlpha(isDark ? 180 : 220),
              border: Border(top: BorderSide(color: Colors.white.withAlpha(isDark ? 20 : 100), width: 1)),
            ),
            // Note: NavigationBar limits to 6 items if we don't handle it carefully, 
            // but let's just use it similarly to others for simplicity.
            child: NavigationBar(
              backgroundColor: Colors.transparent,
              indicatorColor: theme.primaryColor.withAlpha(40),
              elevation: 0,
              selectedIndex: _selectedIndex,
              onDestinationSelected: (int index) => setState(() => _selectedIndex = index),
              destinations: const [
                NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Dash'),
                NavigationDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people), label: 'Users'),
                NavigationDestination(icon: Icon(Icons.class_outlined), selectedIcon: Icon(Icons.class_), label: 'Kelas'),
                NavigationDestination(icon: Icon(Icons.book_outlined), selectedIcon: Icon(Icons.book), label: 'Materi'),
                NavigationDestination(icon: Icon(Icons.assignment_outlined), selectedIcon: Icon(Icons.assignment), label: 'Tugas'),
                NavigationDestination(icon: Icon(Icons.grade_outlined), selectedIcon: Icon(Icons.grade), label: 'Nilai'),
                NavigationDestination(icon: Icon(Icons.campaign_outlined), selectedIcon: Icon(Icons.campaign), label: 'Info'),
                NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profil'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 900) {
          return _buildWebLayout(context);
        } else {
          return _buildMobileLayout(context);
        }
      },
    );
  }
}