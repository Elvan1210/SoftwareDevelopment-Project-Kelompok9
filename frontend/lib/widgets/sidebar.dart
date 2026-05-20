import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/theme.dart';

// ─── Sidebar ──────────────────────────────────────────────────────────────────
class Sidebar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onDestinationSelected;
  final List<SidebarItemData> destinations;
  final String userName;
  final String userRole;
  final String? userKelas;
  final VoidCallback onLogout;

  const Sidebar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
    required this.userName,
    required this.userRole,
    this.userKelas,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return RepaintBoundary(
      child: Container(
        width: 270,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    AppTheme.darkCard,
                    const Color(0xFF16162A),
                  ]
                : [
                    Colors.white,
                    const Color(0xFFF5F4FF),
                  ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark
                ? AppTheme.indigoPrimary.withAlpha(40)
                : AppTheme.lightBorder,
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withAlpha(160)
                  : AppTheme.indigoPrimary.withAlpha(20),
              blurRadius: 30,
              offset: const Offset(4, 0),
            ),
          ],
        ),
        child: Column(
          children: [
            // ── Brand Header ──
            _BrandHeader(isDark: isDark),

            // ── Divider ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Divider(
                height: 1,
                color: isDark
                    ? AppTheme.indigoPrimary.withAlpha(30)
                    : AppTheme.lightBorder,
              ),
            ),
            const SizedBox(height: 8),

            // ── Profile ──
            _ProfileChip(
              name: userName,
              role: userRole,
              kelas: userKelas,
              isDark: isDark,
            ),
            const SizedBox(height: 8),

            // ── Divider ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Divider(
                height: 1,
                color: isDark
                    ? AppTheme.indigoPrimary.withAlpha(30)
                    : AppTheme.lightBorder,
              ),
            ),
            const SizedBox(height: 12),

            // ── Nav Label ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'MENU',
                  style: GoogleFonts.poppins(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2.0,
                    color: isDark
                        ? AppTheme.textMutedDk
                        : AppTheme.textMutedLt,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // ── Menu Items ──
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: destinations.length,
                separatorBuilder: (_, __) => const SizedBox(height: 4),
                itemBuilder: (context, index) {
                  final item = destinations[index];
                  final isSelected = selectedIndex == index;

                  return _SidebarItem(
                    icon: isSelected ? item.selectedIcon : item.icon,
                    label: item.label,
                    isSelected: isSelected,
                    onTap: () => onDestinationSelected(index),
                    index: index,
                  )
                      .animate(delay: (200 + index * 40).ms)
                      .fadeIn(duration: 350.ms)
                      .slideX(begin: -0.08, curve: Curves.easeOutQuart);
                },
              ),
            ),

            // ── Logout ──
            _LogoutButton(onLogout: onLogout, isDark: isDark),
          ],
        ),
      ),
    );
  }
}

// ─── SidebarItemData ──────────────────────────────────────────────────────────
class SidebarItemData {
  final IconData icon, selectedIcon;
  final String label;

  const SidebarItemData({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
}

// ─── Brand Header ─────────────────────────────────────────────────────────────
class _BrandHeader extends StatelessWidget {
  final bool isDark;
  const _BrandHeader({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
      child: Row(
        children: [
          // Logo badge
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppTheme.indigoPrimary, AppTheme.purpleSecondary],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.indigoPrimary.withAlpha(100),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.school_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'MyPSKD',
                style: GoogleFonts.poppins(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: isDark ? Colors.white : AppTheme.textLight,
                ),
              ),
              Text(
                'Academic Portal',
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Profile Chip ─────────────────────────────────────────────────────────────
class _ProfileChip extends StatelessWidget {
  final String name, role;
  final String? kelas;
  final bool isDark;

  const _ProfileChip({
    required this.name,
    required this.role,
    this.kelas,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final initials = name.trim().split(' ').map((e) => e[0]).take(2).join().toUpperCase();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.indigoPrimary.withAlpha(isDark ? 35 : 20),
              AppTheme.purpleSecondary.withAlpha(isDark ? 20 : 12),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.indigoPrimary.withAlpha(isDark ? 50 : 30),
            width: 1.0,
          ),
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppTheme.indigoPrimary, AppTheme.purpleSecondary],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.indigoPrimary.withAlpha(80),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  initials,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                      color: isDark ? Colors.white : AppTheme.textLight,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      _Pill(label: role, color: AppTheme.indigoPrimary),
                      if (kelas != null) ...[
                        const SizedBox(width: 4),
                        Flexible(
                          child: _Pill(label: kelas!, color: AppTheme.purpleSecondary),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final Color color;
  const _Pill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(isDark ? 35 : 20),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withAlpha(isDark ? 70 : 50), width: 1),
      ),
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.poppins(
          fontSize: 8,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
          color: color,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

// ─── Sidebar Item ─────────────────────────────────────────────────────────────
class _SidebarItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final int index;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.index,
  });

  @override
  State<_SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<_SidebarItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            gradient: widget.isSelected
                ? LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      AppTheme.indigoPrimary.withAlpha(isDark ? 50 : 30),
                      AppTheme.purpleSecondary.withAlpha(isDark ? 25 : 15),
                    ],
                  )
                : _hovered
                    ? LinearGradient(
                        colors: [
                          AppTheme.indigoPrimary.withAlpha(isDark ? 20 : 12),
                          Colors.transparent,
                        ],
                      )
                    : const LinearGradient(colors: [Colors.transparent, Colors.transparent]),
            borderRadius: BorderRadius.circular(14),
            border: widget.isSelected
                ? Border.all(
                    color: AppTheme.indigoPrimary.withAlpha(isDark ? 80 : 50),
                    width: 1.0,
                  )
                : Border.all(color: Colors.transparent),
          ),
          child: Row(
            children: [
              // Icon container
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  gradient: widget.isSelected
                      ? const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [AppTheme.indigoPrimary, AppTheme.purpleSecondary],
                        )
                      : LinearGradient(
                          colors: [
                            (isDark ? Colors.white : AppTheme.textLight).withAlpha(_hovered ? 15 : 8),
                            Colors.transparent,
                          ],
                        ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: widget.isSelected
                      ? [
                          BoxShadow(
                            color: AppTheme.indigoPrimary.withAlpha(90),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : [],
                ),
                child: Icon(
                  widget.icon,
                  color: widget.isSelected
                      ? Colors.white
                      : (isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt),
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.label,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: widget.isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: widget.isSelected
                        ? (isDark ? Colors.white : AppTheme.indigoDark)
                        : (isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt),
                    letterSpacing: 0.1,
                  ),
                ),
              ),
              // Active dot
              if (widget.isSelected)
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppTheme.indigoPrimary,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Logout Button ────────────────────────────────────────────────────────────
class _LogoutButton extends StatefulWidget {
  final VoidCallback onLogout;
  final bool isDark;

  const _LogoutButton({required this.onLogout, required this.isDark});

  @override
  State<_LogoutButton> createState() => _LogoutButtonState();
}

class _LogoutButtonState extends State<_LogoutButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit:  (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onLogout,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: _hovered
                  ? const LinearGradient(
                      colors: [Color(0xFF7F1D1D), Color(0xFFEF4444)],
                    )
                  : LinearGradient(
                      colors: [
                        AppTheme.rose.withAlpha(widget.isDark ? 25 : 15),
                        AppTheme.rose.withAlpha(widget.isDark ? 15 : 8),
                      ],
                    ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppTheme.rose.withAlpha(_hovered ? 150 : (widget.isDark ? 50 : 30)),
                width: 1.0,
              ),
              boxShadow: _hovered
                  ? [BoxShadow(color: AppTheme.rose.withAlpha(80), blurRadius: 15, offset: const Offset(0, 4))]
                  : [],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  LucideIcons.logOut,
                  color: _hovered ? Colors.white : AppTheme.rose,
                  size: 16,
                ),
                const SizedBox(width: 10),
                Text(
                  'Keluar',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _hovered ? Colors.white : AppTheme.rose,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
