import 'package:flutter/material.dart';
import 'siswa_dashboard_screen.dart';
import 'siswa_teams_view.dart';
import 'siswa_pengumuman_view.dart';
import 'siswa_profil_view.dart';
import '../../../widgets/notification_bell.dart';
import '../../../widgets/theme_toggle.dart';
import '../../../widgets/app_shell.dart';
import '../../../widgets/sidebar.dart';
import '../../auth/login_screen.dart';
import '../../../services/auth_service.dart';

// Catatan: Import untuk Tugas, Materi, dan Nilai sudah dihapus 
// karena nanti akan dimasukkan ke dalam modul Teams.

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

  // Judul disesuaikan menjadi 4 menu
  final List<String> _titles = [
    'Dashboard Overview',
    'Teams / Kelas Saya',
    'Pengumuman Sekolah',
    'Profil Siswa',
  ];

  @override
  void initState() {
    super.initState();
    _views = [
      SiswaDashboardScreen(userData: widget.userData, token: widget.token),
      // Memanggil halaman SiswaTeamsView yang baru dibuat
      SiswaTeamsView(userData: widget.userData, token: widget.token),
      SiswaPengumumanView(userData: widget.userData, token: widget.token),
      SiswaProfilView(userData: widget.userData),
    ];
  }

  Widget _buildWebLayout(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AppShell(
      child: Padding(
        padding: const EdgeInsets.all(28.0),
        child: Row(
          children: [
            // ── Unified Sidebar ──
            Sidebar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) => setState(() => _selectedIndex = index),
              userName: widget.userData['nama'] ?? 'Siswa',
              userRole: 'Siswa',
              userKelas: widget.userData['kelas'],
              onLogout: () async {
                final navigator = Navigator.of(context);
                await AuthService.logout();
                navigator.pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
              },
              destinations: const [
                SidebarItemData(
                  icon: Icons.grid_view_rounded,
                  selectedIcon: Icons.grid_view_sharp,
                  label: 'Home',
                ),
                SidebarItemData(
                  icon: Icons.groups_3_outlined,
                  selectedIcon: Icons.groups_3_rounded,
                  label: 'Teams',
                ),
                SidebarItemData(
                  icon: Icons.notifications_none_rounded,
                  selectedIcon: Icons.notifications_active_rounded,
                  label: 'Info',
                ),
                SidebarItemData(
                  icon: Icons.person_3_outlined,
                  selectedIcon: Icons.person_3_rounded,
                  label: 'Profil',
                ),
              ],
            ),

            const SizedBox(width: 28),

            // ── Main Content Area ──
            Expanded(
              child: GlassCard(
                blurSigma: 16,
                padding: EdgeInsets.zero,
                child: Scaffold(
                  backgroundColor: Colors.transparent,
                  appBar: AppBar(
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    scrolledUnderElevation: 0,
                    title: Text(
                      _titles[_selectedIndex],
                      style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: -0.5),
                    ),
                    actions: [
                      const ThemeToggle(),
                      const SizedBox(width: 8),
                      NotificationBell(
                        userData: widget.userData, 
                        token: widget.token,
                        iconColor: theme.iconTheme.color ?? (isDark ? Colors.white : Colors.black87),
                      ),
                      const SizedBox(width: 28),
                    ],
                  ),
                  body: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    switchInCurve: Curves.linear,
                    switchOutCurve: Curves.linear,
                    transitionBuilder: (child, animation) {
                      return FadeTransition(opacity: animation, child: child);
                    },
                    child: KeyedSubtree(
                      key: ValueKey(_selectedIndex),
                      child: _views[_selectedIndex],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AppShell(
      child: Stack(
        children: [
          Column(
            children: [
              // ── Custom Floating AppBar ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: GlassCard(
                  radius: 20,
                  blurSigma: 20,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          _titles[_selectedIndex],
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900, 
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                      NotificationBell(
                        userData: widget.userData, 
                        token: widget.token,
                        iconColor: theme.iconTheme.color ?? (isDark ? Colors.white : Colors.black87),
                      ),
                    ],
                  ),
                ),
              ),
              
              // ── Animated Body Content ──
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  switchInCurve: Curves.linear,
                  switchOutCurve: Curves.linear,
                  transitionBuilder: (child, animation) {
                    return FadeTransition(opacity: animation, child: child);
                  },
                  child: KeyedSubtree(
                    key: ValueKey(_selectedIndex),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 80), // Space for nav bar
                      child: _views[_selectedIndex],
                    ),
                  ),
                ),
              ),
            ],
          ),

          // ── Bottom Navigation Bar ──
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: GlassCard(
              radius: 24,
              blurSigma: 24,
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: NavigationBar(
                backgroundColor: Colors.transparent,
                indicatorColor: theme.primaryColor.withAlpha(40),
                elevation: 0,
                height: 64,
                selectedIndex: _selectedIndex,
                onDestinationSelected: (int index) => setState(() => _selectedIndex = index),
                destinations: const [
                  NavigationDestination(icon: Icon(Icons.grid_view_rounded), label: 'Home'),
                  NavigationDestination(icon: Icon(Icons.groups_3_outlined), label: 'Teams'),
                  NavigationDestination(icon: Icon(Icons.notifications_none_rounded), label: 'Info'),
                  NavigationDestination(icon: Icon(Icons.person_3_outlined), label: 'Profil'),
                ],
              ),
            ),
          ),
        ],
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
