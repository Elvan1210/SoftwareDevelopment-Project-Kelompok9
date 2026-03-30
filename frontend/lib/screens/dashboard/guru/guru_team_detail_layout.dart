import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'guru_tugas_view.dart';
import 'guru_materi_view.dart';
import 'guru_presensi_view.dart';
import '../../../widgets/notification_bell.dart';
import '../../../widgets/app_shell.dart';
import '../../../widgets/theme_toggle.dart';

class GuruTeamDetailLayout extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String token;
  final dynamic teamData;

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
  // Views are now initialized in _getViews() to prevent context-related lifecycle errors.

  final List<String> _titles = [
    'Dashboard Tim',
    'Saluran (Channels)',
    'Presensi Kelas',
    'Tugas & Nilai',
    'Materi ajar',
  ];

  @override
  void initState() {
    super.initState();
  }

  List<Widget> _getViews() {
    return [
      _buildDashboardView(),
      const Center(child: Text('Fitur Saluran Sedang Dibangun...', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
      GuruPresensiView(userData: widget.userData, token: widget.token),
      GuruTugasView(userData: widget.userData, token: widget.token, teamData: widget.teamData),
      GuruMateriView(userData: widget.userData, token: widget.token, teamData: widget.teamData),
    ];
  }

  Widget _buildDashboardView() {
    return Center(
      child: GlassCard(
        blurSigma: 24,
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.hub_rounded, size: 64, color: Theme.of(context).primaryColor),
            const SizedBox(height: 24),
            Text(
              'Ruang Guru: ${widget.teamData['nama_kelas']}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5),
            ),
            const SizedBox(height: 8),
            Text(
              'Kelola materi, tugas, dan kehadiran siswa di sini.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWebLayout(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AppShell(
      child: Padding(
        padding: const EdgeInsets.all(28.0),
        child: Row(
          children: [
            // ── Sidebar ──
            SizedBox(
              width: 280,
              child: GlassCard(
                blurSigma: 24,
                padding: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSidebarHeader(context, theme),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        children: [
                          _buildSidebarItem(0, Icons.hub_outlined, 'Dashboard'),
                          _buildSidebarItem(1, Icons.forum_outlined, 'Saluran'),
                          _buildSidebarItem(2, Icons.how_to_reg_outlined, 'Presensi'),
                          _buildSidebarItem(3, Icons.assignment_outlined, 'Tugas & Nilai'),
                          _buildSidebarItem(4, Icons.auto_stories_outlined, 'Materi'),
                        ],
                      ),
                    ),
                    _buildSidebarFooter(theme),
                  ],
                ),
              ),
            ).animate().fadeIn(duration: 800.ms).slideX(begin: -0.05),

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
                    leading: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                    ),
                    title: Text(
                      _titles[_selectedIndex],
                      style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: -0.5),
                    ).animate(key: ValueKey(_selectedIndex)).fade(duration: 400.ms).slideX(begin: -0.05),
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
                    duration: const Duration(milliseconds: 500),
                    switchInCurve: Curves.easeOutQuart,
                    switchOutCurve: Curves.easeInQuart,
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(begin: const Offset(0, 0.02), end: Offset.zero).animate(animation),
                          child: child,
                        ),
                      );
                    },
                    child: KeyedSubtree(
                      key: ValueKey(_selectedIndex),
                      child: _getViews()[_selectedIndex],
                    ),
                  ),
                ),
              ),
            ).animate().fadeIn(duration: 800.ms, delay: 150.ms).slideX(begin: 0.02),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebarHeader(BuildContext context, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.primaryColor.withAlpha(20),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.psychology_rounded, color: theme.primaryColor, size: 28),
          ).animate().scale(delay: 200.ms, curve: Curves.easeOutBack),
          const SizedBox(height: 24),
          Text(
            widget.teamData['nama_kelas'] ?? 'Ruang Kelas',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.primaryColor,
              fontWeight: FontWeight.w900,
              height: 1.1,
              letterSpacing: -0.8,
            ),
          ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.2),
          const SizedBox(height: 8),
          Text(
            widget.teamData['kode_kelas'] ?? 'GURU-CORE',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(int index, IconData icon, String label) {
    final theme = Theme.of(context);
    final isSelected = _selectedIndex == index;
    final color = isSelected ? theme.primaryColor : theme.colorScheme.onSurface.withAlpha(120);

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: InkWell(
        onTap: () => setState(() => _selectedIndex = index),
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? theme.primaryColor.withAlpha(isSelected ? 30 : 0) : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? theme.primaryColor.withAlpha(60) : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 16),
              Text(
                label, 
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: color, 
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
              if (isSelected) const Spacer(),
              if (isSelected) 
                Container(
                  width: 6, height: 6, 
                  decoration: BoxDecoration(color: theme.primaryColor, shape: BoxShape.circle),
                ).animate().scale(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSidebarFooter(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: GlassCard(
        radius: 16,
        blurSigma: 0, 
        padding: const EdgeInsets.all(12),
        overrideColor: theme.primaryColor.withAlpha(15),
        child: Row(
          children: [
            Icon(Icons.workspace_premium_rounded, color: theme.primaryColor, size: 20),
            const SizedBox(width: 12),
            Text(
              'Guru Premium', 
              style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.w900, fontSize: 12),
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
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                        visualDensity: VisualDensity.compact,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _titles[_selectedIndex],
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900, 
                            letterSpacing: -0.5,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ).animate(key: ValueKey(_selectedIndex)).fade().slideX(begin: -0.1),
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
                  duration: const Duration(milliseconds: 400),
                    child: KeyedSubtree(
                      key: ValueKey(_selectedIndex),
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 80),
                        child: _getViews()[_selectedIndex],
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildMobileNavItem(0, Icons.hub_outlined),
                  _buildMobileNavItem(1, Icons.forum_outlined),
                  _buildMobileNavItem(2, Icons.how_to_reg_outlined),
                  _buildMobileNavItem(3, Icons.assignment_outlined),
                  _buildMobileNavItem(4, Icons.auto_stories_outlined),
                ],
              ),
            ),
          ).animate().slideY(begin: 1.0, duration: 600.ms, curve: Curves.easeOutQuart),
        ],
      ),
    );
  }

  Widget _buildMobileNavItem(int index, IconData icon) {
    final theme = Theme.of(context);
    final isSelected = _selectedIndex == index;
    final color = isSelected ? theme.primaryColor : theme.colorScheme.onSurface.withAlpha(100);

    return InkWell(
      onTap: () => setState(() => _selectedIndex = index),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? theme.primaryColor.withAlpha(20) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(icon, color: color, size: 24),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      if (constraints.maxWidth > 1100) return _buildWebLayout(context);
      return _buildMobileLayout(context);
    });
  }
}
