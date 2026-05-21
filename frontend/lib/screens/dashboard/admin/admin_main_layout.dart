// import 'package:flutter/material.dart';
// import 'package:flutter_animate/flutter_animate.dart';
// import '../../../widgets/app_shell.dart';
// import 'admin_dashboard_view.dart';
// import 'user_management_view.dart';
// import 'kelas_management_view.dart';
// import 'admin_materi_view.dart';
// import 'admin_tugas_view.dart';
// import 'admin_nilai_view.dart';
// import 'admin_pengumuman_view.dart';
// import 'admin_profil_view.dart';
// import '../../../widgets/notification_bell.dart';
// import '../../../widgets/theme_toggle.dart';
// import '../../../widgets/sidebar.dart';
// import '../../auth/login_screen.dart';
// import '../../../services/auth_service.dart';
// import 'package:lucide_icons_flutter/lucide_icons.dart';

// class AdminMainLayout extends StatefulWidget {
//   final String token;
//   AdminMainLayout({super.key, this.token = ''});

//   @override
//   State<AdminMainLayout> createState() => _AdminMainLayoutState();
// }

// class _AdminMainLayoutState extends State<AdminMainLayout> {
//   int _selectedIndex = 0;
//   late List<Widget> _views;

//   // Semua tab dan labelnya berurutan — index harus konsisten
//   // 0: Dashboard, 1: Users, 2: Kelas, 3: Materi, 4: Tugas,
//   // 5: Nilai, 6: Pengumuman, 7: Profil
//   final List<String> _titles = [
//     'Admin Dashboard',
//     'User Management',
//     'Kelas Management',
//     'Materi',
//     'Tugas',
//     'Nilai Akademik',
//     'Pengumuman',
//     'Admin Profil',
//   ];

//   @override
//   void initState() {
//     super.initState();
//     _views = [
//       AdminDashboardView(
//         token: widget.token,
//         onNavigate: (index) {
//           setState(() => _selectedIndex = index);
//         },
//       ),
//       UserManagementView(token: widget.token),
//       KelasManagementView(token: widget.token),
//       AdminMateriView(token: widget.token),
//       AdminTugasView(token: widget.token),
//       AdminNilaiView(token: widget.token),
//       AdminPengumumanView(token: widget.token),
//       AdminProfilView(token: widget.token),
//     ];
//   }

//   final Map<String, dynamic> _adminUserData = {
//     'id': 'admin',
//     'role': 'Admin',
//     'nama': 'Administrator',
//     'kelas': ''
//   };

//   // ═══════════════════════════════════════════════════════════
//   // WEB LAYOUT (> 1100px) — sidebar tetap dari sebelumnya
//   // ═══════════════════════════════════════════════════════════
//   Widget 
//WebLayout(BuildContext context) {
//     final theme = Theme.of(context);
//     final isDark = theme.brightness == Brightness.dark;

//     return AppShell(
//       child: Padding(
//         padding: EdgeInsets.all(28.0),
//         child: Row(
//           children: [
//             Sidebar(
//               selectedIndex: _selectedIndex,
//               onDestinationSelected: (index) => setState(() => _selectedIndex = index),
//               userName: _adminUserData['nama'] ?? 'Admin',
//               userRole: 'Admin',
//               onLogout: _handleLogout,
//               destinations: [
//                 SidebarItemData(icon: LucideIcons.layoutDashboard, selectedIcon: LucideIcons.layoutDashboard, label: 'Dashboard'),
//                 SidebarItemData(icon: LucideIcons.users, selectedIcon: LucideIcons.users, label: 'User Management'),
//                 SidebarItemData(icon: LucideIcons.library, selectedIcon: LucideIcons.library, label: 'Kelas Management'),
//                 SidebarItemData(icon: LucideIcons.bookOpen, selectedIcon: LucideIcons.bookOpen, label: 'Materi'),
//                 SidebarItemData(icon: LucideIcons.clipboardList, selectedIcon: LucideIcons.clipboardList, label: 'Tugas'),
//                 SidebarItemData(icon: LucideIcons.award, selectedIcon: LucideIcons.award, label: 'Nilai Akademik'),
//                 SidebarItemData(icon: LucideIcons.megaphone, selectedIcon: LucideIcons.megaphone, label: 'Pengumuman'),
//                 SidebarItemData(icon: LucideIcons.user, selectedIcon: LucideIcons.user, label: 'Profil Admin'),
//               ],
//             ),
//             SizedBox(width: 28),
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
//                         userData: _adminUserData,
//                         token: widget.token,
//                         iconColor: theme.iconTheme.color ?? (isDark ? Colors.white : Colors.black87),
//                       ),
//                       SizedBox(width: 28),
//                     ],
//                   ),
//                   body: AnimatedSwitcher(
//                     duration: Duration(milliseconds: 200),
//                     transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
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

//   // ═══════════════════════════════════════════════════════════
//   // MOBILE LAYOUT (≤ 1100px) — didesain ulang total
//   // ═══════════════════════════════════════════════════════════
//   Widget _buildMobileLayout(BuildContext context) {
//     final theme = Theme.of(context);
//     final isDark = theme.brightness == Brightness.dark;

//     // Mobile bottom nav hanya menampilkan 4 tab utama.
//     // Sisanya (Materi, Tugas, Nilai, Pengumuman) diakses lewat menu "Lainnya".
//     // Mapping: bottomNavIndex -> _selectedIndex
//     //   0 -> 0 (Dashboard)
//     //   1 -> 1 (Users)
//     //   2 -> 2 (Kelas)
//     //   3 -> 7 (Profil)
//     const List<int> mobileTabMapping = [0, 1, 2, 7];

//     // Hitung mana bottom nav yang aktif
//     int bottomNavIndex = mobileTabMapping.indexOf(_selectedIndex);
//     // Jika _selectedIndex tidak ada di mapping (misal 3-6 = Materi/Tugas/Nilai/Pengumuman),
//     // jangan highlight satupun — biarkan -1 agar tidak ada yang selected
//     if (bottomNavIndex < 0) bottomNavIndex = -1;

//     return AppShell(
//       child: Stack(
//         children: [
//           Column(
//             children: [
//               // ── Floating AppBar ──
//               Padding(
//                 padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
//                 child: GlassCard(
//                   radius: 20,
//                   padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
//                   child: Row(
//                     children: [
//                       Expanded(
//                         child: Text(
//                           _titles[_selectedIndex],
//                           style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900, letterSpacing: -0.5),
//                           overflow: TextOverflow.ellipsis,
//                         ).animate(key: ValueKey(_selectedIndex)).fade(duration: 300.ms),
//                       ),
//                       ThemeToggle(),
//                       SizedBox(width: 4),
//                       NotificationBell(
//                         userData: _adminUserData,
//                         token: widget.token,
//                         iconColor: theme.iconTheme.color ?? (isDark ? Colors.white : Colors.black87),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),

//               // ── Body ──
//               Expanded(
//                 child: AnimatedSwitcher(
//                   duration: Duration(milliseconds: 250),
//                   transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
//                   child: KeyedSubtree(
//                     key: ValueKey(_selectedIndex),
//                     child: Padding(
//                       padding: EdgeInsets.only(bottom: 88),
//                       child: _views[_selectedIndex],
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),

//           // ── Bottom Navigation ──
//           Positioned(
//             left: 16,
//             right: 16,
//             bottom: 16,
//             child: GlassCard(
//               radius: 24,
//               padding: EdgeInsets.symmetric(vertical: 4),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                 children: [
//                   _buildMobileNavItem(
//                     icon: LucideIcons.layoutDashboard,
//                     selectedIcon: LucideIcons.layoutDashboard,
//                     label: 'Dashboard',
//                     isSelected: bottomNavIndex == 0,
//                     onTap: () => setState(() => _selectedIndex = 0),
//                     theme: theme,
//                   ),
//                   _buildMobileNavItem(
//                     icon: LucideIcons.users,
//                     selectedIcon: LucideIcons.users,
//                     label: 'Users',
//                     isSelected: bottomNavIndex == 1,
//                     onTap: () => setState(() => _selectedIndex = 1),
//                     theme: theme,
//                   ),
//                   _buildMobileNavItem(
//                     icon: LucideIcons.library,
//                     selectedIcon: LucideIcons.library,
//                     label: 'Kelas',
//                     isSelected: bottomNavIndex == 2,
//                     onTap: () => setState(() => _selectedIndex = 2),
//                     theme: theme,
//                   ),
//                   _buildMobileNavItem(
//                     icon: LucideIcons.user,
//                     selectedIcon: LucideIcons.user,
//                     label: 'Profil',
//                     isSelected: bottomNavIndex == 3,
//                     onTap: () => setState(() => _selectedIndex = 7),
//                     theme: theme,
//                   ),
//                   // Tombol "More" untuk menu lainnya
//                   _buildMobileNavItem(
//                     icon: LucideIcons.moreHorizontal,
//                     selectedIcon: LucideIcons.moreHorizontal,
//                     label: 'Lainnya',
//                     isSelected: _selectedIndex >= 3 && _selectedIndex <= 6,
//                     onTap: () => _showMobileMenu(theme, isDark),
//                     theme: theme,
//                   ),
//                 ],
//               ),
//             ).animate().slideY(begin: 1.0, duration: 600.ms, curve: Curves.easeOutQuart),
//           ),
//         ],
//       ),
//     );
//   }

//   // ── Helper: Mobile Bottom Nav Item ──
//   Widget _buildMobileNavItem({
//     required IconData icon,
//     required IconData selectedIcon,
//     required String label,
//     required bool isSelected,
//     required VoidCallback onTap,
//     required ThemeData theme,
//   }) {
//     final color = isSelected ? theme.primaryColor : theme.colorScheme.onSurface.withAlpha(160);
//     return InkWell(
//       onTap: onTap,
//       borderRadius: BorderRadius.circular(16),
//       child: AnimatedContainer(
//         duration: Duration(milliseconds: 250),
//         padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
//         decoration: BoxDecoration(
//           color: isSelected ? theme.primaryColor.withAlpha(20) : Colors.transparent,
//           borderRadius: BorderRadius.circular(16),
//         ),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Icon(isSelected ? selectedIcon : icon, color: color, size: 22),
//             SizedBox(height: 2),
//             Text(
//               label,
//               style: TextStyle(fontSize: 9, fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600, color: color),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   // ── Mobile "Lainnya" BottomSheet ──
//   void _showMobileMenu(ThemeData theme, bool isDark) {
//     showModalBottomSheet(
//       context: context,
//       backgroundColor: Colors.transparent,
//       builder: (ctx) => GlassCard(
//         radius: 24,
//         padding: EdgeInsets.all(24),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text('Menu Lainnya', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
//             SizedBox(height: 20),
//             _buildMenuTile(LucideIcons.bookOpen, 'Materi', 3, theme, ctx),
//             _buildMenuTile(LucideIcons.clipboardList, 'Tugas', 4, theme, ctx),
//             _buildMenuTile(LucideIcons.award, 'Nilai Akademik', 5, theme, ctx),
//             _buildMenuTile(LucideIcons.megaphone, 'Pengumuman', 6, theme, ctx),
//             SizedBox(height: 12),
//             Divider(),
//             SizedBox(height: 4),
//             _buildMenuTile(LucideIcons.logOut, 'Logout', -1, theme, ctx, isLogout: true),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildMenuTile(IconData icon, String label, int targetIndex, ThemeData theme, BuildContext ctx, {bool isLogout = false}) {
//     final isSelected = !isLogout && _selectedIndex == targetIndex;
//     final color = isLogout
//         ? AppTheme.errorAccent
//         : (isSelected ? theme.primaryColor : theme.colorScheme.onSurface.withAlpha(160));

//     return Padding(
//       padding: EdgeInsets.only(bottom: 4),
//       child: InkWell(
//         onTap: () {
//           Navigator.pop(ctx);
//           if (isLogout) {
//             _handleLogout();
//           } else {
//             setState(() => _selectedIndex = targetIndex);
//           }
//         },
//         borderRadius: BorderRadius.circular(12),
//         child: AnimatedContainer(
//           duration: Duration(milliseconds: 200),
//           padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
//           decoration: BoxDecoration(
//             color: isSelected ? theme.primaryColor.withAlpha(15) : Colors.transparent,
//             borderRadius: BorderRadius.circular(12),
//             border: Border.all(
//               color: isSelected ? theme.primaryColor.withAlpha(40) : Colors.transparent,
//               width: 1.5,
//             ),
//           ),
//           child: Row(
//             children: [
//               Icon(icon, color: color, size: 22),
//               SizedBox(width: 16),
//               Expanded(
//                 child: Text(
//                   label,
//                   style: TextStyle(fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600, color: color),
//                 ),
//               ),
//               if (isSelected)
//                 Container(
//                   width: 6,
//                   height: 6,
//                   decoration: BoxDecoration(color: theme.primaryColor, shape: BoxShape.circle),
//                 ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Future<void> _handleLogout() async {
//     final navigator = Navigator.of(context);
//     await AuthService.logout();
//     navigator.pushReplacement(MaterialPageRoute(builder: (_) => LoginScreen()));
//   }

//   @override
//   Widget build(BuildContext context) {
//     return LayoutBuilder(
//       builder: (context, constraints) {
//         if (constraints.maxWidth > 1100) {
//           return _buildWebLayout(context);
//         } else {
//           return _buildMobileLayout(context);
//         }
//       },
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../config/theme.dart';
import '../../../widgets/app_shell.dart';
import '../../../widgets/sidebar.dart';

import 'admin_dashboard_view.dart';
import 'user_management_view.dart';
import 'kelas_management_view.dart';
import '../shared/messages_screen.dart';
import 'admin_materi_view.dart';
import 'admin_tugas_view.dart';
import 'admin_pengumuman_view.dart';
import 'admin_profil_view.dart';
import '../../../widgets/notification_bell.dart';
import '../../../widgets/theme_toggle.dart';
import '../../auth/login_screen.dart';
import '../../../services/auth_service.dart';
import 'package:google_fonts/google_fonts.dart';




class AdminMainLayout extends StatefulWidget {
  final String token;
  const AdminMainLayout({super.key, this.token = ''});

  @override
  State<AdminMainLayout> createState() => _AdminMainLayoutState();
}

class _AdminMainLayoutState extends State<AdminMainLayout> {
  int _selectedIndex = 0;
  late List<Widget> _views;

  // Urutan Tab: 0: Dashboard, 1: Users, 2: Kelas, 3: Messages, 4: Materi, 5: Tugas, 6: Pengumuman, 7: Profil
  final List<String> _titles = [
    'Admin Dashboard',
    'User Management',
    'Kelas Management',
    'Messages',
    'Materi',
    'Tugas',
    'Pengumuman',
    'Admin Profil',
  ];

  @override
  void initState() {
    super.initState();
    _views = [
      AdminDashboardView(
        token: widget.token,
        onNavigate: (index) {
          setState(() => _selectedIndex = index);
        },
      ),
      UserManagementView(token: widget.token),
      KelasManagementView(token: widget.token),
      MessagesScreen(userData: _adminUserData), // VIEW MESSAGES BARU
      AdminMateriView(token: widget.token),
      AdminTugasView(token: widget.token),
      AdminPengumumanView(token: widget.token),
      AdminProfilView(token: widget.token),
    ];
  }

  final Map<String, dynamic> _adminUserData = {
    'id': 'admin',
    'role': 'Admin',
    'nama': 'Administrator',
    'kelas': ''
  };

  // ═══════════════════════════════════════════════════════════
  // WEB LAYOUT (> 1100px)
  // ═══════════════════════════════════════════════════════════
  Widget _buildWebLayout(BuildContext context) {
    final theme = Theme.of(context);

    return AppShell(
      fullWidth: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 24.0, 16.0, 24.0),
        child: Row(
          children: [
            Sidebar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) =>
                  setState(() => _selectedIndex = index),
              userName: _adminUserData['nama'] ?? 'Admin',
              userRole: 'Admin',
              onLogout: _handleLogout,
              destinations: [
                SidebarItemData(
                  icon: Icons.hub_outlined,
                  selectedIcon: Icons.hub_rounded,
                  label: 'Dashboard',
                ),
                SidebarItemData(
                  icon: Icons.people_alt_outlined,
                  selectedIcon: Icons.people_alt_rounded,
                  label: 'User Management',
                ),
                SidebarItemData(
                  icon: Icons.school_outlined,
                  selectedIcon: Icons.school_rounded,
                  label: 'Kelas Management',
                ),
                SidebarItemData(
                  icon: Icons.message_outlined,
                  selectedIcon: Icons.message_rounded,
                  label: 'Messages',
                ),
                SidebarItemData(
                  icon: Icons.auto_stories_outlined,
                  selectedIcon: Icons.auto_stories_rounded,
                  label: 'Materi',
                ),
                SidebarItemData(
                  icon: Icons.assignment_outlined,
                  selectedIcon: Icons.assignment_rounded,
                  label: 'Tugas',
                ),
                SidebarItemData(
                  icon: Icons.campaign_outlined,
                  selectedIcon: Icons.campaign_rounded,
                  label: 'Pengumuman',
                ),
                SidebarItemData(
                  icon: Icons.manage_accounts_outlined,
                  selectedIcon: Icons.manage_accounts_rounded,
                  label: 'Profil Admin',
                ),
              ],
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  border: Border.all(color: Theme.of(context).colorScheme.onSurface, width: 2),
                  boxShadow: [BoxShadow(color: Theme.of(context).colorScheme.onSurface, offset: const Offset(4, 4), blurRadius: 0)],
                ),
                child: Scaffold(
                  backgroundColor: Colors.transparent,
                  appBar: AppBar(
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    scrolledUnderElevation: 0,
                    title: Text(
                      _titles[_selectedIndex],
                      style: GoogleFonts.inter(
                          fontWeight: FontWeight.w900, letterSpacing: -0.5, color: Theme.of(context).textTheme.bodyLarge!.color!),
                    ),
                    actions: [
                      const ThemeToggle(),
                      const SizedBox(width: 8),
                      NotificationBell(
                        userData: _adminUserData,
                        token: widget.token,
                        iconColor: theme.iconTheme.color ??
                            (Theme.of(context).textTheme.bodyLarge!.color!),
                      ),
                      const SizedBox(width: 28),
                    ],
                  ),
                  body: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    switchInCurve: Curves.linear,
                    switchOutCurve: Curves.linear,
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: child,
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
          ],
        ),
      ),
    );
  }


  // ═══════════════════════════════════════════════════════════
  // MOBILE LAYOUT (≤ 1100px)
  // ═══════════════════════════════════════════════════════════
  Widget _buildMobileLayout(BuildContext context) {
    const List<int> mobileTabMapping = [0, 1, 2, 7];
    int bottomNavIndex = mobileTabMapping.indexOf(_selectedIndex);
    if (bottomNavIndex < 0) bottomNavIndex = -1;

    return AppShell(
      child: ContentSurface(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Column(
            children: [
              // Mobile topbar — adaptive
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1A1040) : Colors.white,
                  border: Border(bottom: BorderSide(color: Theme.of(context).colorScheme.onSurface, width: 2)),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                    child: Row(children: [
                      Container(padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(color: AppTheme.primary, border: Border.all(color: Theme.of(context).colorScheme.onSurface, width: 1.5), boxShadow: [BoxShadow(color: Theme.of(context).colorScheme.onSurface, offset: const Offset(2, 2), blurRadius: 0)]),
                        child: const Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 18)),
                      const SizedBox(width: 10),
                      Expanded(child: Text(_titles[_selectedIndex],
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900, 
                          color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Theme.of(context).colorScheme.onSurface,
                        ))
                        .animate(key: ValueKey(_selectedIndex)).fade(duration: 250.ms)),
                      const ThemeToggle(),
                      const SizedBox(width: 4),
                      NotificationBell(
                        userData: _adminUserData, 
                        token: widget.token, 
                        iconColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF9090B0) : Theme.of(context).colorScheme.onSurface,
                      ),
                    ]),
                  ),
                ),
              ),

              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  switchInCurve: Curves.easeOutQuart,
                  child: KeyedSubtree(
                    key: ValueKey(_selectedIndex),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 88),
                      child: _views[_selectedIndex],
                    ),
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1A1040) : Colors.white,
                  border: Border.all(color: Theme.of(context).colorScheme.onSurface, width: 2),
                  boxShadow: [BoxShadow(color: Theme.of(context).colorScheme.onSurface, offset: const Offset(4, 4), blurRadius: 0)],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    CosmicPillNavItem(icon: Icons.hub_outlined, label: 'Home',
                      isSelected: _selectedIndex == 0, onTap: () => setState(() => _selectedIndex = 0)),
                    CosmicPillNavItem(icon: Icons.people_alt_outlined, label: 'Users',
                      isSelected: _selectedIndex == 1, onTap: () => setState(() => _selectedIndex = 1)),
                    CosmicPillNavItem(icon: Icons.school_outlined, label: 'Kelas',
                      isSelected: _selectedIndex == 2, onTap: () => setState(() => _selectedIndex = 2)),
                    CosmicPillNavItem(icon: Icons.manage_accounts_outlined, label: 'Profil',
                      isSelected: _selectedIndex == 7, onTap: () => setState(() => _selectedIndex = 7)),
                    CosmicPillNavItem(icon: Icons.more_horiz_rounded, label: 'Lainnya',
                      isSelected: _selectedIndex >= 3 && _selectedIndex <= 6,
                      onTap: () => _showMobileMenu()),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }




  void _showMobileMenu() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              top: BorderSide(color: Theme.of(context).colorScheme.onSurface, width: 2)
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40, height: 4, 
                margin: const EdgeInsets.only(bottom: 16), 
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onSurface, 
                )
              ),
              Text('Menu Lainnya', 
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Theme.of(context).textTheme.bodyLarge!.color!, 
                  fontWeight: FontWeight.w900)
              ),
              const SizedBox(height: 16),
              _buildMenuTile(Icons.message_outlined, 'Messages', 3, ctx, isDark),
              _buildMenuTile(Icons.auto_stories_outlined, 'Materi', 4, ctx, isDark),
              _buildMenuTile(Icons.assignment_outlined, 'Tugas', 5, ctx, isDark),
              _buildMenuTile(Icons.campaign_outlined, 'Pengumuman', 6, ctx, isDark),
              const SizedBox(height: 8),
              Divider(color: Theme.of(context).colorScheme.onSurface, thickness: 1.5),
              _buildMenuTile(Icons.logout_rounded, 'Logout', -1, ctx, isDark, isLogout: true),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildMenuTile(IconData icon, String label, int targetIndex, BuildContext ctx, bool isDark, {bool isLogout = false}) {
    final theme = Theme.of(ctx);
    final isSelected = !isLogout && _selectedIndex == targetIndex;
    final color = isLogout ? const Color(0xFFEF4444)
        : (isSelected ? theme.primaryColor : (isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt));

    return GestureDetector(
      onTap: () {
        Navigator.pop(ctx);
        if (isLogout) {
          _handleLogout();
        } else {
          setState(() => _selectedIndex = targetIndex);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : Colors.transparent,
          border: isSelected ? Border.all(color: Theme.of(context).colorScheme.onSurface, width: 1.5) : null,
          boxShadow: isSelected ? [BoxShadow(color: Theme.of(context).colorScheme.onSurface, offset: const Offset(2, 2), blurRadius: 0)] : null,
        ),
        child: Row(children: [
          Icon(icon, color: isSelected ? Colors.white : color, size: 20),
          const SizedBox(width: 14),
          Expanded(child: Text(label, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: isSelected ? Colors.white : color, fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700))),
        ]),
      ),
    );
  }




  Future<void> _handleLogout() async {
    final navigator = Navigator.of(context);
    await AuthService.logout();
    navigator.pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
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
