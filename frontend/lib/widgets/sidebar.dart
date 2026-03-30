import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return RepaintBoundary(
      child: Container(
        width: 280,
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          // PERFORMANCE: No BackdropFilter. Using solid high-alpha glass.
          color: theme.colorScheme.surface.withAlpha(isDark ? 245 : 255),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: isDark ? Colors.white.withAlpha(20) : Colors.black.withAlpha(10),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(isDark ? 80 : 20),
              blurRadius: 40,
              offset: const Offset(0, 20),
            ),
          ],
        ),
        child: Column(
          children: [
            // ── Profile Header ──
            _ProfileHeader(
              name: userName,
              role: userRole,
              kelas: userKelas,
              isDark: isDark,
              primaryColor: theme.primaryColor,
              secondaryColor: theme.colorScheme.secondary,
            ),
            
            const SizedBox(height: 8),
            const Divider(height: 1, indent: 24, endIndent: 24),
            const SizedBox(height: 16),
            
            // ── Menu Items ──
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: destinations.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final item = destinations[index];
                  final isSelected = selectedIndex == index;
                  
                  return _SidebarItem(
                    icon: isSelected ? item.selectedIcon : item.icon,
                    label: item.label,
                    isSelected: isSelected,
                    onTap: () => onDestinationSelected(index),
                    primaryColor: theme.primaryColor,
                  ).animate(delay: (300 + index * 50).ms).fadeIn(duration: 400.ms).slideX(begin: -0.1, curve: Curves.easeOutQuart);
                },
              ),
            ),
            
            // ── Footer Logout ──
            _SidebarFooter(
              onLogout: onLogout,
              isDark: isDark,
              primaryColor: theme.primaryColor,
            ),
          ],
        ),
      ),
    );
  }
}

class SidebarItemData {
  final IconData icon, selectedIcon;
  final String label;

  const SidebarItemData({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
}

class _ProfileHeader extends StatelessWidget {
  final String name, role;
  final String? kelas;
  final bool isDark;
  final Color primaryColor, secondaryColor;

  const _ProfileHeader({
    required this.name,
    required this.role,
    this.kelas,
    required this.isDark,
    required this.primaryColor,
    required this.secondaryColor,
  });

  @override
  Widget build(BuildContext context) {
    final initials = name.trim().split(' ').map((e) => e[0]).take(2).join().toUpperCase();
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Avatar Placeholder
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryColor, primaryColor.withAlpha(150)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withAlpha(isDark ? 30 : 60),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withAlpha(40),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _HeaderBadge(
                          label: role,
                          color: primaryColor,
                          isDark: isDark,
                        ),
                        if (kelas != null) ...[
                          const SizedBox(width: 6),
                          _HeaderBadge(
                            label: kelas!,
                            color: secondaryColor,
                            isDark: isDark,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderBadge extends StatelessWidget {
  final String label;
  final Color color;
  final bool isDark;

  const _HeaderBadge({
    required this.label,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(isDark ? 30 : 20),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withAlpha(50), width: 1),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
          color: color,
        ),
      ),
    );
  }
}

class _SidebarItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color primaryColor;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.primaryColor,
  });

  @override
  State<_SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<_SidebarItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: widget.isSelected 
                ? widget.primaryColor.withAlpha(isDark ? 20 : 10)
                : (_isHovered ? widget.primaryColor.withAlpha(8) : Colors.transparent),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              // ── Selection Indicator ──
              if (widget.isSelected)
                Container(
                  width: 4,
                  height: 20,
                  decoration: BoxDecoration(
                    color: widget.primaryColor,
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: [
                      BoxShadow(
                        color: widget.primaryColor.withAlpha(100),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
              if (widget.isSelected) const SizedBox(width: 12),
              
              Icon(
                widget.icon,
                color: widget.isSelected 
                    ? widget.primaryColor 
                    : theme.colorScheme.onSurface.withAlpha(120),
                size: 22,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: widget.isSelected ? FontWeight.w900 : FontWeight.w600,
                    color: widget.isSelected 
                        ? widget.primaryColor 
                        : theme.colorScheme.onSurface.withAlpha(150),
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SidebarFooter extends StatelessWidget {
  final VoidCallback onLogout;
  final bool isDark;
  final Color primaryColor;

  const _SidebarFooter({
    required this.onLogout,
    required this.isDark,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: InkWell(
        onTap: onLogout,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withAlpha(10) : Colors.black.withAlpha(5),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.logout_rounded, color: primaryColor, size: 20),
              const SizedBox(width: 12),
              Text(
                'LOGOUT',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: primaryColor,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

