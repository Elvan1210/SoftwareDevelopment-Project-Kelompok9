import '../../../config/theme.dart';
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
//               userKelas: widget.userData['kelas'],
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
    'Dashboard Overview',
    'Teams / Kelas Saya',
    'Messages', // TITLE UNTUK MESSAGES
    'Pengumuman Sekolah',
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
        padding: const EdgeInsets.fromLTRB(0, 24.0, 16.0, 24.0),
        child: Row(
          children: [
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
              destinations: [
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
                // MENU MESSAGES DITAMBAHKAN DI SINI
                SidebarItemData(
                  icon: Icons.forum_outlined,
                  selectedIcon: Icons.forum_rounded,
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
            ),

            const SizedBox(width: 24),

            Expanded(
              child: GlassCard(
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
                      NotificationBell(
                        userData: widget.userData, 
                        token: widget.token,
                        iconColor: AppTheme.textLight,
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
    return AppShell(
      child: Stack(
        children: [
          Column(
            children: [
              // ── Premium light-mode top bar ────────────────────────────────
              Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 16, 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(12),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'MyPSKD',
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textLight,
                        letterSpacing: -0.5,
                      ),
                    ),
                    NotificationBell(
                      userData: widget.userData,
                      token: widget.token,
                      iconColor: AppTheme.textLight,
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
                      padding: const EdgeInsets.only(bottom: 80),
                      child: _views[_selectedIndex],
                    ),
                  ),
                ),
              ),
            ],
          ),

          // ── Premium light-mode bottom nav bar ─────────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(12),
                    blurRadius: 12,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildMobileNavItem(
                    icon: Icons.grid_view_outlined,
                    selectedIcon: Icons.grid_view_rounded,
                    label: 'Home',
                    isSelected: _selectedIndex == 0,
                    onTap: () => setState(() => _selectedIndex = 0),
                  ),
                  _buildMobileNavItem(
                    icon: Icons.groups_3_outlined,
                    selectedIcon: Icons.groups_3_rounded,
                    label: 'Teams',
                    isSelected: _selectedIndex == 1,
                    onTap: () => setState(() => _selectedIndex = 1),
                  ),
                  _buildMobileNavItem(
                    icon: Icons.forum_outlined,
                    selectedIcon: Icons.forum_rounded,
                    label: 'Msg',
                    isSelected: _selectedIndex == 2,
                    onTap: () => setState(() => _selectedIndex = 2),
                  ),
                  _buildMobileNavItem(
                    icon: Icons.notifications_none_rounded,
                    selectedIcon: Icons.notifications_active_rounded,
                    label: 'Info',
                    isSelected: _selectedIndex == 3,
                    onTap: () => setState(() => _selectedIndex = 3),
                  ),
                  _buildMobileNavItem(
                    icon: Icons.person_3_outlined,
                    selectedIcon: Icons.person_3_rounded,
                    label: 'Profil',
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
    required IconData selectedIcon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    const activeColor   = AppTheme.indigoPrimary;
    const inactiveColor = AppTheme.textMutedLt;
    final bgColor       = isSelected
        ? AppTheme.indigoPrimary.withAlpha(15)
        : Colors.transparent;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 8),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isSelected ? selectedIcon : icon,
                color: isSelected ? activeColor : inactiveColor,
                size: 22,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                  color: isSelected ? activeColor : inactiveColor,
                  letterSpacing: isSelected ? 0.3 : 0),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
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