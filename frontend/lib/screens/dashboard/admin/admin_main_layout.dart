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
//   const AdminMainLayout({super.key, this.token = ''});

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

//   final Map<String, dynamic> _adminUserData = const {
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
//         padding: const EdgeInsets.all(28.0),
//         child: Row(
//           children: [
//             Sidebar(
//               selectedIndex: _selectedIndex,
//               onDestinationSelected: (index) => setState(() => _selectedIndex = index),
//               userName: _adminUserData['nama'] ?? 'Admin',
//               userRole: 'Admin',
//               onLogout: _handleLogout,
//               destinations: const [
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
//             const SizedBox(width: 28),
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
//                       style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: -0.5),
//                     ),
//                     actions: [
//                       const ThemeToggle(),
//                       const SizedBox(width: 8),
//                       NotificationBell(
//                         userData: _adminUserData,
//                         token: widget.token,
//                         iconColor: theme.iconTheme.color ?? (isDark ? Colors.white : Colors.black87),
//                       ),
//                       const SizedBox(width: 28),
//                     ],
//                   ),
//                   body: AnimatedSwitcher(
//                     duration: const Duration(milliseconds: 200),
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
//                 padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
//                 child: GlassCard(
//                   radius: 20,
//                   padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
//                   child: Row(
//                     children: [
//                       Expanded(
//                         child: Text(
//                           _titles[_selectedIndex],
//                           style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900, letterSpacing: -0.5),
//                           overflow: TextOverflow.ellipsis,
//                         ).animate(key: ValueKey(_selectedIndex)).fade(duration: 300.ms),
//                       ),
//                       const ThemeToggle(),
//                       const SizedBox(width: 4),
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
//                   duration: const Duration(milliseconds: 250),
//                   transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
//                   child: KeyedSubtree(
//                     key: ValueKey(_selectedIndex),
//                     child: Padding(
//                       padding: const EdgeInsets.only(bottom: 88),
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
//               padding: const EdgeInsets.symmetric(vertical: 4),
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
//         duration: const Duration(milliseconds: 250),
//         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
//         decoration: BoxDecoration(
//           color: isSelected ? theme.primaryColor.withAlpha(20) : Colors.transparent,
//           borderRadius: BorderRadius.circular(16),
//         ),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Icon(isSelected ? selectedIcon : icon, color: color, size: 22),
//             const SizedBox(height: 2),
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
//         padding: const EdgeInsets.all(24),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text('Menu Lainnya', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
//             const SizedBox(height: 20),
//             _buildMenuTile(LucideIcons.bookOpen, 'Materi', 3, theme, ctx),
//             _buildMenuTile(LucideIcons.clipboardList, 'Tugas', 4, theme, ctx),
//             _buildMenuTile(LucideIcons.award, 'Nilai Akademik', 5, theme, ctx),
//             _buildMenuTile(LucideIcons.megaphone, 'Pengumuman', 6, theme, ctx),
//             const SizedBox(height: 12),
//             const Divider(),
//             const SizedBox(height: 4),
//             _buildMenuTile(LucideIcons.logOut, 'Logout', -1, theme, ctx, isLogout: true),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildMenuTile(IconData icon, String label, int targetIndex, ThemeData theme, BuildContext ctx, {bool isLogout = false}) {
//     final isSelected = !isLogout && _selectedIndex == targetIndex;
//     final color = isLogout
//         ? Colors.redAccent
//         : (isSelected ? theme.primaryColor : theme.colorScheme.onSurface.withAlpha(160));

//     return Padding(
//       padding: const EdgeInsets.only(bottom: 4),
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
//           duration: const Duration(milliseconds: 200),
//           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
//               const SizedBox(width: 16),
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
//     navigator.pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
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

  final Map<String, dynamic> _adminUserData = const {
    'id': 'admin',
    'role': 'Admin',
    'nama': 'Administrator',
    'kelas': ''
  };

  // ═══════════════════════════════════════════════════════════
  // WEB LAYOUT (> 1100px)
  // ═══════════════════════════════════════════════════════════
  Widget _buildWebLayout(BuildContext context) {
    return AppShell(
      child: Row(
        children: [
          // ── Cosmic Admin Sidebar ──
          SizedBox(
            width: 280,
            child: CosmicBackground(
              child: SafeArea(
                right: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Container(padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: Colors.white.withAlpha(20), borderRadius: BorderRadius.circular(12)),
                            child: const Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 22)),
                          const SizedBox(width: 12),
                          const Text('MyPSKD', style: TextStyle(color: CosmicColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                        ]),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [Color(0xFFF97316), Color(0xFFEA580C)]),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text('ADMIN', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                        ),
                      ]),
                    ),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        children: [
                          // ── Main Nav ──
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 0, 0, 8),
                            child: Text('MENU UTAMA', style: TextStyle(
                              fontSize: 9.5, fontWeight: FontWeight.w800,
                              color: Colors.white.withAlpha(80), letterSpacing: 1.4)),
                          ),
                          CosmicSidebarItem(icon: Icons.hub_outlined, label: 'Dashboard',
                            isSelected: _selectedIndex == 0, onTap: () => setState(() => _selectedIndex = 0)),
                          CosmicSidebarItem(icon: Icons.people_alt_outlined, label: 'User Management',
                            isSelected: _selectedIndex == 1, onTap: () => setState(() => _selectedIndex = 1)),
                          CosmicSidebarItem(icon: Icons.school_outlined, label: 'Kelas Management',
                            isSelected: _selectedIndex == 2, onTap: () => setState(() => _selectedIndex = 2)),
                          CosmicSidebarItem(icon: Icons.message_outlined, label: 'Messages',
                            isSelected: _selectedIndex == 3, onTap: () => setState(() => _selectedIndex = 3)),
                          // ── Content ──
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 16, 0, 8),
                            child: Text('KONTEN', style: TextStyle(
                              fontSize: 9.5, fontWeight: FontWeight.w800,
                              color: Colors.white.withAlpha(80), letterSpacing: 1.4)),
                          ),
                          CosmicSidebarItem(icon: Icons.auto_stories_outlined, label: 'Materi',
                            isSelected: _selectedIndex == 4, onTap: () => setState(() => _selectedIndex = 4)),
                          CosmicSidebarItem(icon: Icons.assignment_outlined, label: 'Tugas',
                            isSelected: _selectedIndex == 5, onTap: () => setState(() => _selectedIndex = 5)),
                          CosmicSidebarItem(icon: Icons.campaign_outlined, label: 'Pengumuman',
                            isSelected: _selectedIndex == 6, onTap: () => setState(() => _selectedIndex = 6)),
                          // ── Account ──
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 16, 0, 8),
                            child: Text('AKUN', style: TextStyle(
                              fontSize: 9.5, fontWeight: FontWeight.w800,
                              color: Colors.white.withAlpha(80), letterSpacing: 1.4)),
                          ),
                          CosmicSidebarItem(icon: Icons.manage_accounts_outlined, label: 'Profil Admin',
                            isSelected: _selectedIndex == 7, onTap: () => setState(() => _selectedIndex = 7)),
                        ],
                      ),
                    ),
                    // Logout footer
                    GestureDetector(
                      onTap: _handleLogout,
                      child: Container(
                        margin: const EdgeInsets.all(14),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(10),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white.withAlpha(20)),
                        ),
                        child: Row(children: [
                          CircleAvatar(radius: 16, backgroundColor: const Color(0xFFF97316).withAlpha(80),
                            child: const Text('A', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13))),
                          const SizedBox(width: 10),
                          const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('Administrator', style: TextStyle(color: CosmicColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 12)),
                            Text('Admin', style: TextStyle(color: CosmicColors.textMuted, fontSize: 11)),
                          ])),
                          const Icon(Icons.logout_rounded, size: 16, color: CosmicColors.textMuted),
                        ]),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ).animate().fadeIn(duration: 800.ms).slideX(begin: -0.05),

          // ── Content Area ──
          Expanded(
            child: ContentSurface(
              child: Column(
                children: [
                  // Topbar — adaptive surface
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF161B27) : Colors.white,
                      border: Border(
                        bottom: BorderSide(
                          color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF252D3D) : const Color(0xFFE5E7EB), 
                          width: 1.0,
                        ),
                      ),
                    ),
                    child: Row(children: [
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(_titles[_selectedIndex],
                          style: TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 17,
                            color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppTheme.textLight, 
                            letterSpacing: -0.3))
                          .animate(key: ValueKey(_selectedIndex)).fade(duration: 250.ms).slideX(begin: -0.03),
                      ])),
                      const ThemeToggle(),
                      const SizedBox(width: 8),
                      NotificationBell(
                        userData: _adminUserData, 
                        token: widget.token, 
                        iconColor: Theme.of(context).brightness == Brightness.dark ? AppTheme.textMutedDk : AppTheme.textMutedLt
                      ),
                      const SizedBox(width: 8),
                    ]),
                  ),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      switchInCurve: Curves.easeOutQuart,
                      switchOutCurve: Curves.easeInQuart,
                      child: KeyedSubtree(key: ValueKey(_selectedIndex), child: _views[_selectedIndex]),
                    ),
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(duration: 800.ms, delay: 150.ms),
        ],
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
                  color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF161B27) : Colors.white,
                  border: Border(bottom: BorderSide(
                    color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF252D3D) : const Color(0xFFE5E7EB),
                  )),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                    child: Row(children: [
                      Container(padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(color: CosmicColors.violet.withAlpha(25), borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.admin_panel_settings_rounded, color: CosmicColors.violet, size: 18)),
                      const SizedBox(width: 10),
                      Expanded(child: Text(_titles[_selectedIndex],
                        style: TextStyle(
                          fontWeight: FontWeight.w800, 
                          fontSize: 16, 
                          color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppTheme.textLight,
                        ))
                        .animate(key: ValueKey(_selectedIndex)).fade(duration: 250.ms)),
                      const ThemeToggle(),
                      const SizedBox(width: 4),
                      NotificationBell(
                        userData: _adminUserData, 
                        token: widget.token, 
                        iconColor: Theme.of(context).brightness == Brightness.dark ? AppTheme.textMutedDk : AppTheme.textMutedLt,
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
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E2060) : Colors.white,
                  borderRadius: BorderRadius.circular(40),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF7B83EB).withAlpha(Theme.of(context).brightness == Brightness.dark ? 40 : 15), 
                      blurRadius: 20, 
                      spreadRadius: 2, 
                      offset: const Offset(0, 4)
                    )
                  ],
                ),
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
            color: isDark ? const Color(0xFF161B27) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(
              top: BorderSide(color: isDark ? const Color(0xFF252D3D) : const Color(0xFFE5E7EB), width: 1.0)
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
                  color: isDark ? const Color(0xFF252D3D) : const Color(0xFFE0E0E0), 
                  borderRadius: BorderRadius.circular(2)
                )
              ),
              Text('Menu Lainnya', 
                style: TextStyle(
                  color: isDark ? Colors.white : AppTheme.textLight, 
                  fontWeight: FontWeight.w900, 
                  fontSize: 16
                )
              ),
              const SizedBox(height: 16),
              _buildMenuTile(Icons.message_outlined, 'Messages', 3, ctx, isDark),
              _buildMenuTile(Icons.auto_stories_outlined, 'Materi', 4, ctx, isDark),
              _buildMenuTile(Icons.assignment_outlined, 'Tugas', 5, ctx, isDark),
              _buildMenuTile(Icons.campaign_outlined, 'Pengumuman', 6, ctx, isDark),
              const SizedBox(height: 8),
              Divider(color: isDark ? const Color(0xFF252D3D) : const Color(0xFFE5E7EB)),
              _buildMenuTile(Icons.logout_rounded, 'Logout', -1, ctx, isDark, isLogout: true),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildMenuTile(IconData icon, String label, int targetIndex, BuildContext ctx, bool isDark, {bool isLogout = false}) {
    final isSelected = !isLogout && _selectedIndex == targetIndex;
    final color = isLogout ? const Color(0xFFEF4444)
        : (isSelected ? CosmicColors.violet : (isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt));

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
          color: isSelected ? CosmicColors.violet.withAlpha(25) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isSelected ? Border.all(color: CosmicColors.violet.withAlpha(60)) : null,
        ),
        child: Row(children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 14),
          Expanded(child: Text(label, style: TextStyle(
            color: color, fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600, fontSize: 14))),
          if (isSelected) Container(width: 6, height: 6,
            decoration: const BoxDecoration(color: CosmicColors.violet, shape: BoxShape.circle)),
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
