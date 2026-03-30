import 'package:flutter/material.dart';
import '../../../widgets/app_shell.dart';
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
import '../../../widgets/sidebar.dart';
import '../../auth/login_screen.dart';
import '../../../services/auth_service.dart';

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

    return AppShell(
      child: Padding(
        padding: const EdgeInsets.all(28.0),
        child: Row(
          children: [
            // ── Unified Sidebar ──
            Sidebar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) => setState(() => _selectedIndex = index),
              userName: _adminUserData['nama'] ?? 'Admin',
              userRole: 'Admin',
              onLogout: () async {
                final navigator = Navigator.of(context);
                await AuthService.logout();
                navigator.pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
              },
              destinations: const [
                SidebarItemData(
                  icon: Icons.dashboard_outlined,
                  selectedIcon: Icons.dashboard_rounded,
                  label: 'Dash',
                ),
                SidebarItemData(
                  icon: Icons.people_outline_rounded,
                  selectedIcon: Icons.people_rounded,
                  label: 'Users',
                ),
                SidebarItemData(
                  icon: Icons.meeting_room_outlined,
                  selectedIcon: Icons.meeting_room_rounded,
                  label: 'Kelas',
                ),
                SidebarItemData(
                  icon: Icons.assignment_outlined,
                  selectedIcon: Icons.assignment_rounded,
                  label: 'Materi',
                ),
                SidebarItemData(
                  icon: Icons.campaign_outlined,
                  selectedIcon: Icons.campaign_rounded,
                  label: 'Info',
                ),
                SidebarItemData(
                  icon: Icons.person_outline_rounded,
                  selectedIcon: Icons.person_rounded,
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
                        userData: _adminUserData, 
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
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      NotificationBell(
                        userData: _adminUserData, 
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
                  NavigationDestination(icon: Icon(Icons.dashboard_outlined), label: 'Dash'),
                  NavigationDestination(icon: Icon(Icons.people_outline), label: 'Users'),
                  NavigationDestination(icon: Icon(Icons.class_outlined), label: 'Kelas'),
                  NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profil'),
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
        if (constraints.maxWidth > 1100) {
          return _buildWebLayout(context);
        } else {
          return _buildMobileLayout(context);
        }
      },
    );
  }
}
