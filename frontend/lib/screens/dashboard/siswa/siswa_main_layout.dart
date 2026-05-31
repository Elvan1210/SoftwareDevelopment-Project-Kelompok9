// import 'package:flutter/material.dart';
// import 'siswa_dashboard_screen.dart';
// import 'siswa_teams_view.dart';
// import 'siswa_pengumuman_view.dart';
// import 'siswa_profil_view.dart';
// import '../../../widgets/notification_bell.dart';
// import '../../../widgets/theme_toggle.dart';
// import '../../../widgets/app_shell.dart';
// import '../../../widgets/sidebar.dart';
// import '../../auth/login_screen.dart';
// import '../../../services/auth_service.dart';

// class SiswaMainLayout extends StatefulWidget {
//   final Map<String, dynamic> userData;
//   final String token;
//   SiswaMainLayout({super.key, required this.userData, required this.token});

//   @override
//   State<SiswaMainLayout> createState() => _SiswaMainLayoutState();
// }

// class _SiswaMainLayoutState extends State<SiswaMainLayout> {
//   int _selectedIndex = 0;
//   late List<Widget> _views;

//   final List<String> _titles = [
//     'Dashboard Overview',
//     'Teams / Kelas Saya',
//     'Pengumuman Sekolah',
//     'Profil Siswa',
//   ];

//   @override
//   void initState() {
//     super.initState();
//     _views = [
//       SiswaDashboardScreen(userData: widget.userData, token: widget.token),
//       SiswaTeamsView(userData: widget.userData, token: widget.token),
//       SiswaPengumumanView(userData: widget.userData, token: widget.token),
//       SiswaProfilView(userData: widget.userData),
//     ];
//   }

//   Widget _buildWebLayout(BuildContext context) {
//     final theme = Theme.of(context);
//     final isDark = theme.brightness == Brightness.dark;

//     return AppShell(
//       child: Padding(
//         padding: EdgeInsets.all(28.0),
//         child: Row(
//           children: [
//             // ── Unified Sidebar ──
//             Sidebar(
//               selectedIndex: _selectedIndex,
//               onDestinationSelected: (index) => setState(() => _selectedIndex = index),
//               userName: widget.userData['nama'] ?? 'Siswa',
//               userRole: 'Siswa',
//               onLogout: () async {
//                 final navigator = Navigator.of(context);
//                 await AuthService.logout();
//                 navigator.pushReplacement(MaterialPageRoute(builder: (_) => LoginScreen()));
//               },
//               destinations: [
//                 SidebarItemData(
//                   icon: Icons.grid_view_rounded,
//                   selectedIcon: Icons.grid_view_sharp,
//                   label: 'Home',
//                 ),
//                 SidebarItemData(
//                   icon: Icons.groups_3_outlined,
//                   selectedIcon: Icons.groups_3_rounded,
//                   label: 'Teams',
//                 ),
//                 SidebarItemData(
//                   icon: Icons.notifications_none_rounded,
//                   selectedIcon: Icons.notifications_active_rounded,
//                   label: 'Info',
//                 ),
//                 SidebarItemData(
//                   icon: Icons.person_3_outlined,
//                   selectedIcon: Icons.person_3_rounded,
//                   label: 'Profil',
//                 ),
//               ],
//             ),

//             SizedBox(width: 28),

//             // ── Main Content Area ──
//             Expanded(
//               child: GlassCard(
//                 padding: EdgeInsets.zero,
//                 child: Scaffold(
//                   backgroundColor: Colors.transparent,
//                   appBar: AppBar(
//                     backgroundColor: Colors.transparent,
//                     elevation: 0,
//                     scrolledUnderElevation: 0,
//                     title: Text(
//                       _titles[_selectedIndex],
//                       style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: -0.5),
//                     ),
//                     actions: [
//                       ThemeToggle(),
//                       SizedBox(width: 8),
//                       NotificationBell(
//                         userData: widget.userData, 
//                         token: widget.token,
//                         iconColor: theme.iconTheme.color ?? (isDark ? Colors.white : Colors.black87),
//                       ),
//                       SizedBox(width: 28),
//                     ],
//                   ),
//                   body: AnimatedSwitcher(
//                     duration: Duration(milliseconds: 200),
//                     switchInCurve: Curves.linear,
//                     switchOutCurve: Curves.linear,
//                     transitionBuilder: (child, animation) {
//                       return FadeTransition(opacity: animation, child: child);
//                     },
//                     child: KeyedSubtree(
//                       key: ValueKey(_selectedIndex),
//                       child: _views[_selectedIndex],
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildMobileLayout(BuildContext context) {
//     final theme = Theme.of(context);
//     final isDark = theme.brightness == Brightness.dark;

//     return AppShell(
//       child: Stack(
//         children: [
//           Column(
//             children: [
//               // ── Custom Floating AppBar ──
//               Padding(
//                 padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
//                 child: GlassCard(
//                   radius: 20,
//                   padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
//                   child: Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Expanded(
//                         child: Text(
//                           _titles[_selectedIndex],
//                           style: theme.textTheme.titleMedium?.copyWith(
//                             fontWeight: FontWeight.w900, 
//                             letterSpacing: -0.5,
//                           ),
//                           overflow: TextOverflow.ellipsis,
//                         ),
//                       ),
//                       ThemeToggle(),
//                       SizedBox(width: 4),
//                       NotificationBell(
//                         userData: widget.userData, 
//                         token: widget.token,
//                         iconColor: theme.iconTheme.color ?? (isDark ? Colors.white : Colors.black87),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
              
//               // ── Animated Body Content ──
//               Expanded(
//                 child: AnimatedSwitcher(
//                   duration: Duration(milliseconds: 200),
//                   switchInCurve: Curves.linear,
//                   switchOutCurve: Curves.linear,
//                   transitionBuilder: (child, animation) {
//                     return FadeTransition(opacity: animation, child: child);
//                   },
//                   child: KeyedSubtree(
//                     key: ValueKey(_selectedIndex),
//                     child: Padding(
//                       padding: EdgeInsets.only(bottom: 80), // Space for nav bar
//                       child: _views[_selectedIndex],
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),

//           // ── Bottom Navigation Bar ──
//           Positioned(
//             left: 16,
//             right: 16,
//             bottom: 16,
//             child: GlassCard(
//               radius: 24,
//               padding: EdgeInsets.symmetric(vertical: 4),
//               child: NavigationBar(
//                 backgroundColor: Colors.transparent,
//                 indicatorColor: theme.primaryColor.withAlpha(40),
//                 elevation: 0,
//                 height: 64,
//                 selectedIndex: _selectedIndex,
//                 onDestinationSelected: (int index) => setState(() => _selectedIndex = index),
//                 destinations: [
//                   NavigationDestination(icon: Icon(Icons.grid_view_rounded), label: 'Home'),
//                   NavigationDestination(icon: Icon(Icons.groups_3_outlined), label: 'Teams'),
//                   NavigationDestination(icon: Icon(Icons.notifications_none_rounded), label: 'Info'),
//                   NavigationDestination(icon: Icon(Icons.person_3_outlined), label: 'Profil'),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return LayoutBuilder(
//       builder: (context, constraints) {
//         if (constraints.maxWidth > 900) {
//           return _buildWebLayout(context);
//         } else {
//           return _buildMobileLayout(context);
//         }
//       },
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'siswa_dashboard_screen.dart';
import 'siswa_teams_view.dart';
import '../shared/messages_screen.dart';
import 'siswa_pengumuman_view.dart';
import 'siswa_profil_view.dart';
import '../../../widgets/notification_bell.dart';
import '../../../widgets/app_shell.dart';
import '../../../widgets/sidebar.dart';
import '../../auth/login_screen.dart';
import '../../../services/auth_service.dart';



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
    'Dashboard',
    'Classes',
    'Messages',
    'Pengumuman',
    'Profil Siswa',
  ];

  @override
  void initState() {
    super.initState();
    _views = [
      SiswaDashboardScreen(userData: widget.userData, token: widget.token),
      SiswaTeamsView(userData: widget.userData, token: widget.token),
      MessagesScreen(userData: widget.userData), // VIEW MESSAGES BARU
      SiswaPengumumanView(userData: widget.userData, token: widget.token),
      SiswaProfilView(userData: widget.userData),
    ];
  }

  Widget _buildWebLayout(BuildContext context) {

    return AppShell(
      fullWidth: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 24.0),
        child: Row(
          children: [
            FutureBuilder<Map<String, dynamic>?>(
              future: AuthService.getUserData(),
              builder: (context, snapshot) {
                final currentData = snapshot.data ?? widget.userData;
                return Sidebar(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: (index) => setState(() => _selectedIndex = index),
                  userName: currentData['nama'] ?? 'Siswa',
                  userRole: currentData['role'] ?? 'Siswa',
                  photoUrl: currentData['photoUrl'] ?? '',
              onLogout: () async {
                final navigator = Navigator.of(context);
                await AuthService.logout();
                navigator.pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
              },
              destinations: [
                SidebarItemData(
                  icon: Icons.grid_view_rounded,
                  selectedIcon: Icons.grid_view_sharp,
                  label: 'Home',
                ),
                SidebarItemData(
                  icon: Icons.menu_book_outlined,
                  selectedIcon: Icons.menu_book_rounded,
                  label: 'Classes',
                ),
                SidebarItemData(
                  icon: Icons.chat_bubble_outline_rounded,
                  selectedIcon: Icons.chat_bubble_rounded,
                  label: 'Messages',
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
            );
            },
          ),
          const SizedBox(width: 24),

            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFF001E2B), width: 2),
                  boxShadow: const [BoxShadow(color: Color(0xFF001E2B), offset: Offset(6, 6))],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: Scaffold(
                    backgroundColor: Colors.transparent,
                    appBar: AppBar(
                      backgroundColor: Colors.white,
                      elevation: 0,
                      scrolledUnderElevation: 0,
                      bottom: PreferredSize(
                        preferredSize: const Size.fromHeight(1.0),
                        child: Container(
                          color: const Color(0xFF001E2B),
                          height: 2.0,
                        ),
                      ),
                      title: Text(
                        _titles[_selectedIndex],
                        style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: -0.5, color: Color(0xFF001E2B), fontFamily: 'Plus Jakarta Sans', fontSize: 24),
                      ),
                      actions: [
                        NotificationBell(
                          userData: widget.userData, 
                          token: widget.token,
                          iconColor: const Color(0xFF001E2B),
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    final bool isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    
    return AppShell(
      child: Stack(
        children: [
          Column(
            children: [
              // ── Neo-Brutalist Top Bar ────────────────────────────────
              Container(
                height: 72,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: const BoxDecoration(
                  color: Color(0xFFF4FAFF), // surface
                  border: Border(bottom: BorderSide(color: Color(0xFF073446), width: 1)), // border-inverse-surface
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        // Optional back button can go here if needed, but for root layout we just show title
                        Text(
                          _titles[_selectedIndex],
                          style: const TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontWeight: FontWeight.w700,
                            fontSize: 24,
                            color: Color(0xFF3D6754), // primary
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Text(
                          'MyPSKD',
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontWeight: FontWeight.w600,
                            fontSize: 20,
                            color: Color(0xFF3D6754), // primary
                          ),
                        ),
                        const SizedBox(width: 8),
                        NotificationBell(
                          userData: widget.userData,
                          token: widget.token,
                          iconColor: const Color(0xFF3D6754),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
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
                      padding: EdgeInsets.only(bottom: isKeyboardOpen ? 0 : 64),
                      child: _views[_selectedIndex],
                    ),
                  ),
                ),
              ),
            ],
          ),

          // ── Neo-Brutalist Bottom Nav Bar ─────────────────────────
          if (!isKeyboardOpen)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                height: 64,
                decoration: const BoxDecoration(
                  color: Color(0xFFF4FAFF), // surface
                  border: Border(top: BorderSide(color: Color(0xFF073446), width: 1)), // border-inverse-surface
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildMobileNavItem(
                      icon: Icons.grid_view_outlined,
                      label: 'Dashboard',
                      isSelected: _selectedIndex == 0,
                      onTap: () => setState(() => _selectedIndex = 0),
                    ),
                    _buildMobileNavItem(
                      icon: Icons.menu_book,
                      label: 'Classes',
                      isSelected: _selectedIndex == 1,
                      onTap: () => setState(() => _selectedIndex = 1),
                    ),
                    _buildMobileNavItem(
                      icon: Icons.chat_bubble_outline,
                      label: 'Messages',
                      isSelected: _selectedIndex == 2,
                      onTap: () => setState(() => _selectedIndex = 2),
                    ),
                    _buildMobileNavItem(
                      icon: Icons.notifications_none_outlined,
                      label: 'Info',
                      isSelected: _selectedIndex == 3,
                      onTap: () => setState(() => _selectedIndex = 3),
                    ),
                    _buildMobileNavItem(
                      icon: Icons.account_circle_outlined,
                      label: 'Profile',
                      isSelected: _selectedIndex == 4,
                      onTap: () => setState(() => _selectedIndex = 4),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMobileNavItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: isSelected
            ? BoxDecoration(
                color: const Color(0xFF3D6754), // primary
                borderRadius: BorderRadius.circular(8),
              )
            : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFFFFFFFF) : const Color(0xFF414944), // on-primary vs on-surface-variant
              size: 24,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w700,
                fontSize: 12,
                color: isSelected ? const Color(0xFFFFFFFF) : const Color(0xFF414944),
                letterSpacing: 0.6,
              ),
            ),
          ],
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