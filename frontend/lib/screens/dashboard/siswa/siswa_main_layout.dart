import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'siswa_dashboard_screen.dart';
import 'siswa_nilai_view.dart';
import 'siswa_pengumuman_view.dart';
import 'siswa_profil_view.dart';
import '../../../widgets/notification_bell.dart';

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

  final List<String> _titles = [
    'Dashboard Overview',
    'Kelas Saya',
    'Pengumuman Sekolah',
    'Profil Siswa',
  ];

  @override
  void initState() {
    super.initState();
    _views = [
      SiswaDashboardScreen(userData: widget.userData, token: widget.token),
      SiswaNilaiView(userData: widget.userData, token: widget.token),
      SiswaPengumumanView(userData: widget.userData, token: widget.token),
      SiswaProfilView(userData: widget.userData),
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
              ? [const Color(0xFF0F172A), const Color(0xFF020617)]
              : [const Color(0xFFF8FAFC), const Color(0xFFE2E8F0)],
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
                            'Student\nPortal',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              color: theme.primaryColor,
                              height: 1.1,
                              fontWeight: FontWeight.w900,
                            ),
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
                              NavigationRailDestination(icon: Icon(Icons.school_outlined), selectedIcon: Icon(Icons.school), label: Text('Kelas Saya')),
                              NavigationRailDestination(icon: Icon(Icons.campaign_outlined), selectedIcon: Icon(Icons.campaign), label: Text('Pengumuman')),
                              NavigationRailDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: Text('Profil Siswa')),
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
                            NotificationBell(userData: widget.userData, token: widget.token, iconColor: theme.iconTheme.color ?? Colors.black87),
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
              ? [const Color(0xFF0F172A), const Color(0xFF020617)]
              : [const Color(0xFFF8FAFC), const Color(0xFFE2E8F0)],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // Custom Floating AppBar
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
                          Text(
                            _titles[_selectedIndex],
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900, letterSpacing: -0.5),
                          ).animate(key: ValueKey(_selectedIndex)).fade().slideX(begin: -0.1),
                          NotificationBell(userData: widget.userData, token: widget.token, iconColor: theme.iconTheme.color ?? Colors.black87),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              
              // Animated Body Content
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) {
                    return FadeTransition(opacity: animation, child: SlideTransition(position: Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero).animate(animation), child: child));
                  },
                  child: KeyedSubtree(
                    key: ValueKey(_selectedIndex),
                    child: _views[_selectedIndex],
                  ),
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
            child: NavigationBar(
              backgroundColor: Colors.transparent,
              indicatorColor: theme.primaryColor.withAlpha(40),
              elevation: 0,
              selectedIndex: _selectedIndex,
              onDestinationSelected: (int index) => setState(() => _selectedIndex = index),
              destinations: const [
                NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Dashboard'),
                NavigationDestination(icon: Icon(Icons.school_outlined), selectedIcon: Icon(Icons.school), label: 'Kelas Saya'),
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
