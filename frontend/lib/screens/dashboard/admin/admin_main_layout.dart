import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
import 'package:lucide_icons/lucide_icons.dart';

class AdminMainLayout extends StatefulWidget {
  final String token;
  const AdminMainLayout({super.key, this.token = ''});

  @override
  State<AdminMainLayout> createState() => _AdminMainLayoutState();
}

class _AdminMainLayoutState extends State<AdminMainLayout> {
  int _selectedIndex = 0;
  late List<Widget> _views;

  // Semua tab dan labelnya berurutan — index harus konsisten
  // 0: Dashboard, 1: Users, 2: Kelas, 3: Materi, 4: Tugas,
  // 5: Nilai, 6: Pengumuman, 7: Profil
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
      AdminDashboardView(
        token: widget.token,
        onNavigate: (index) {
          setState(() => _selectedIndex = index);
        },
      ),
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

  // ═══════════════════════════════════════════════════════════
  // WEB LAYOUT (> 1100px) — sidebar tetap dari sebelumnya
  // ═══════════════════════════════════════════════════════════
  Widget _buildWebLayout(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AppShell(
      child: Padding(
        padding: const EdgeInsets.all(28.0),
        child: Row(
          children: [
            Sidebar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) => setState(() => _selectedIndex = index),
              userName: _adminUserData['nama'] ?? 'Admin',
              userRole: 'Admin',
              onLogout: _handleLogout,
              destinations: const [
                SidebarItemData(icon: LucideIcons.layoutDashboard, selectedIcon: LucideIcons.layoutDashboard, label: 'Dashboard'),
                SidebarItemData(icon: LucideIcons.users, selectedIcon: LucideIcons.users, label: 'User Management'),
                SidebarItemData(icon: LucideIcons.library, selectedIcon: LucideIcons.library, label: 'Kelas Management'),
                SidebarItemData(icon: LucideIcons.bookOpen, selectedIcon: LucideIcons.bookOpen, label: 'Materi'),
                SidebarItemData(icon: LucideIcons.clipboardList, selectedIcon: LucideIcons.clipboardList, label: 'Tugas'),
                SidebarItemData(icon: LucideIcons.award, selectedIcon: LucideIcons.award, label: 'Nilai Akademik'),
                SidebarItemData(icon: LucideIcons.megaphone, selectedIcon: LucideIcons.megaphone, label: 'Pengumuman'),
                SidebarItemData(icon: LucideIcons.user, selectedIcon: LucideIcons.user, label: 'Profil Admin'),
              ],
            ),
            const SizedBox(width: 28),
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
                    transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
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
  // MOBILE LAYOUT (≤ 1100px) — didesain ulang total
  // ═══════════════════════════════════════════════════════════
  Widget _buildMobileLayout(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Mobile bottom nav hanya menampilkan 4 tab utama.
    // Sisanya (Materi, Tugas, Nilai, Pengumuman) diakses lewat menu "Lainnya".
    // Mapping: bottomNavIndex -> _selectedIndex
    //   0 -> 0 (Dashboard)
    //   1 -> 1 (Users)
    //   2 -> 2 (Kelas)
    //   3 -> 7 (Profil)
    const List<int> mobileTabMapping = [0, 1, 2, 7];

    // Hitung mana bottom nav yang aktif
    int bottomNavIndex = mobileTabMapping.indexOf(_selectedIndex);
    // Jika _selectedIndex tidak ada di mapping (misal 3-6 = Materi/Tugas/Nilai/Pengumuman),
    // jangan highlight satupun — biarkan -1 agar tidak ada yang selected
    if (bottomNavIndex < 0) bottomNavIndex = -1;

    return AppShell(
      child: Stack(
        children: [
          Column(
            children: [
              // ── Floating AppBar ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: GlassCard(
                  radius: 20,
                  blurSigma: 20,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _titles[_selectedIndex],
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900, letterSpacing: -0.5),
                          overflow: TextOverflow.ellipsis,
                        ).animate(key: ValueKey(_selectedIndex)).fade(duration: 300.ms),
                      ),
                      const ThemeToggle(),
                      const SizedBox(width: 4),
                      NotificationBell(
                        userData: _adminUserData,
                        token: widget.token,
                        iconColor: theme.iconTheme.color ?? (isDark ? Colors.white : Colors.black87),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Body ──
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
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

          // ── Bottom Navigation ──
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: GlassCard(
              radius: 24,
              blurSigma: 24,
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildMobileNavItem(
                    icon: LucideIcons.layoutDashboard,
                    selectedIcon: LucideIcons.layoutDashboard,
                    label: 'Dashboard',
                    isSelected: bottomNavIndex == 0,
                    onTap: () => setState(() => _selectedIndex = 0),
                    theme: theme,
                  ),
                  _buildMobileNavItem(
                    icon: LucideIcons.users,
                    selectedIcon: LucideIcons.users,
                    label: 'Users',
                    isSelected: bottomNavIndex == 1,
                    onTap: () => setState(() => _selectedIndex = 1),
                    theme: theme,
                  ),
                  _buildMobileNavItem(
                    icon: LucideIcons.library,
                    selectedIcon: LucideIcons.library,
                    label: 'Kelas',
                    isSelected: bottomNavIndex == 2,
                    onTap: () => setState(() => _selectedIndex = 2),
                    theme: theme,
                  ),
                  _buildMobileNavItem(
                    icon: LucideIcons.user,
                    selectedIcon: LucideIcons.user,
                    label: 'Profil',
                    isSelected: bottomNavIndex == 3,
                    onTap: () => setState(() => _selectedIndex = 7),
                    theme: theme,
                  ),
                  // Tombol "More" untuk menu lainnya
                  _buildMobileNavItem(
                    icon: LucideIcons.moreHorizontal,
                    selectedIcon: LucideIcons.moreHorizontal,
                    label: 'Lainnya',
                    isSelected: _selectedIndex >= 3 && _selectedIndex <= 6,
                    onTap: () => _showMobileMenu(theme, isDark),
                    theme: theme,
                  ),
                ],
              ),
            ).animate().slideY(begin: 1.0, duration: 600.ms, curve: Curves.easeOutQuart),
          ),
        ],
      ),
    );
  }

  // ── Helper: Mobile Bottom Nav Item ──
  Widget _buildMobileNavItem({
    required IconData icon,
    required IconData selectedIcon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required ThemeData theme,
  }) {
    final color = isSelected ? theme.primaryColor : theme.colorScheme.onSurface.withAlpha(100);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? theme.primaryColor.withAlpha(20) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(isSelected ? selectedIcon : icon, color: color, size: 22),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(fontSize: 9, fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600, color: color),
            ),
          ],
        ),
      ),
    );
  }

  // ── Mobile "Lainnya" BottomSheet ──
  void _showMobileMenu(ThemeData theme, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => GlassCard(
        radius: 24,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Menu Lainnya', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 20),
            _buildMenuTile(LucideIcons.bookOpen, 'Materi', 3, theme, ctx),
            _buildMenuTile(LucideIcons.clipboardList, 'Tugas', 4, theme, ctx),
            _buildMenuTile(LucideIcons.award, 'Nilai Akademik', 5, theme, ctx),
            _buildMenuTile(LucideIcons.megaphone, 'Pengumuman', 6, theme, ctx),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 4),
            _buildMenuTile(LucideIcons.logOut, 'Logout', -1, theme, ctx, isLogout: true),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuTile(IconData icon, String label, int targetIndex, ThemeData theme, BuildContext ctx, {bool isLogout = false}) {
    final isSelected = !isLogout && _selectedIndex == targetIndex;
    final color = isLogout
        ? Colors.redAccent
        : (isSelected ? theme.primaryColor : theme.colorScheme.onSurface.withAlpha(150));

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: InkWell(
        onTap: () {
          Navigator.pop(ctx);
          if (isLogout) {
            _handleLogout();
          } else {
            setState(() => _selectedIndex = targetIndex);
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? theme.primaryColor.withAlpha(15) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? theme.primaryColor.withAlpha(40) : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600, color: color),
                ),
              ),
              if (isSelected)
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(color: theme.primaryColor, shape: BoxShape.circle),
                ),
            ],
          ),
        ),
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
