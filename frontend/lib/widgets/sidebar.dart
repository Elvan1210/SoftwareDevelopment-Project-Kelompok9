import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'avatar_widget.dart';

// --- Neo-Brutalist Tokens ---
const Color _onSurface = Color(0xFF001E2B);
const Color _onSurfaceVariant = Color(0xFF414944);
const Color _primary = Color(0xFF3D6754);
const Color _primaryContainer = Color(0xFFB7E5CD);
const Color _onPrimaryContainer = Color(0xFF3E6855);
const Color _surface = Color(0xFFF4FAFF);
const Color _onBackground = Color(0xFF001E2B);
const Color _error = Color(0xFFEF4444);

// ─── Sidebar ──────────────────────────────────────────────────────────────────
class Sidebar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onDestinationSelected;
  final List<SidebarItemData> destinations;
  final String userName;
  final String userRole;
  final String photoUrl;
  final VoidCallback onLogout;

  const Sidebar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
    required this.userName,
    required this.userRole,
    required this.photoUrl,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Container(
        width: 270,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _onSurface, width: 2),
          boxShadow: const [BoxShadow(color: _onSurface, offset: Offset(6, 6))],
        ),
        child: Column(
          children: [
            // ── Brand Header ──
            const _BrandHeaderNeo(),

            // ── Divider ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Divider(height: 1, color: _onSurface.withAlpha(50), thickness: 2),
            ),
            const SizedBox(height: 16),

            // ── Profile ──
            _ProfileChipNeo(
              name: userName,
              role: userRole,
              photoUrl: photoUrl,
            ),
            const SizedBox(height: 16),

            // ── Divider ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Divider(height: 1, color: _onSurface.withAlpha(50), thickness: 2),
            ),
            const SizedBox(height: 20),

            // ── Nav Label ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'MENU',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2.0,
                    color: _onSurfaceVariant,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ── Menu Items ──
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: destinations.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final item = destinations[index];
                  final isSelected = selectedIndex == index;

                  return _SidebarItemNeo(
                    icon: isSelected ? item.selectedIcon : item.icon,
                    label: item.label,
                    isSelected: isSelected,
                    onTap: () => onDestinationSelected(index),
                    index: index,
                  )
                      .animate(delay: (200 + index * 40).ms)
                      .fadeIn(duration: 350.ms)
                      .slideX(begin: -0.05, curve: Curves.easeOutQuart);
                },
              ),
            ),

            // ── Logout ──
            _LogoutButtonNeo(onLogout: onLogout),
            const SizedBox(height: 8),
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

  SidebarItemData({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
}

// ─── Brand Header ─────────────────────────────────────────────────────────────
class _BrandHeaderNeo extends StatelessWidget {
  const _BrandHeaderNeo();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      child: Row(
        children: [
          // Logo badge
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _primary,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _onSurface, width: 2),
              boxShadow: const [BoxShadow(color: _onSurface, offset: Offset(2, 2))],
            ),
            child: const Icon(Icons.school_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'MyPSKD',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                  color: _onBackground,
                  height: 1.1,
                ),
              ),
              Text(
                'Academic Portal',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProfileChipNeo extends StatelessWidget {
  final String name, role, photoUrl;

  const _ProfileChipNeo({
    required this.name,
    required this.role,
    required this.photoUrl,
  });

  @override
  Widget build(BuildContext context) {
    final initials = name.trim().split(' ').map((e) => e[0]).take(2).join().toUpperCase();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _onSurface, width: 2),
        ),
        child: Row(
          children: [
            // Avatar
            AvatarWidget(
              initial: initials,
              photoUrl: photoUrl,
              size: 44,
              bgColor: _primaryContainer,
              textColor: _onPrimaryContainer,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: _onBackground,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _PillNeo(label: role, color: _primary, textColor: Colors.white),
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

class _PillNeo extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;
  
  const _PillNeo({required this.label, required this.color, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _onSurface, width: 1),
      ),
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
          color: textColor,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

// ─── Sidebar Item ─────────────────────────────────────────────────────────────
class _SidebarItemNeo extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final int index;

  const _SidebarItemNeo({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.index,
  });

  @override
  State<_SidebarItemNeo> createState() => _SidebarItemNeoState();
}

class _SidebarItemNeoState extends State<_SidebarItemNeo> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: widget.isSelected ? _primaryContainer : (_hovered ? _surface : Colors.transparent),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.isSelected || _hovered ? _onSurface : Colors.transparent,
              width: 2,
            ),
            boxShadow: widget.isSelected || _hovered ? const [BoxShadow(color: _onSurface, offset: Offset(2, 2))] : [],
          ),
          child: Row(
            children: [
              // Icon container
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: widget.isSelected ? _primary : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: widget.isSelected ? _onSurface : (_hovered ? _onSurface : Colors.transparent), width: 1.5),
                ),
                child: Icon(
                  widget.icon,
                  color: widget.isSelected ? Colors.white : _onSurfaceVariant,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  widget.label,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: widget.isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: widget.isSelected ? _onBackground : _onSurfaceVariant,
                  ),
                ),
              ),
              // Active dot
              if (widget.isSelected)
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _onSurface,
                    shape: BoxShape.circle,
                    border: Border.all(color: _onSurface, width: 1),
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
class _LogoutButtonNeo extends StatefulWidget {
  final VoidCallback onLogout;

  const _LogoutButtonNeo({required this.onLogout});

  @override
  State<_LogoutButtonNeo> createState() => _LogoutButtonNeoState();
}

class _LogoutButtonNeoState extends State<_LogoutButtonNeo> {
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
            duration: const Duration(milliseconds: 100),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            transform: Matrix4.translationValues(
              _hovered ? 2 : 0,
              _hovered ? 2 : 0,
              0,
            ),
            decoration: BoxDecoration(
              color: _error,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _onSurface, width: 2),
              boxShadow: _hovered ? [] : const [BoxShadow(color: _onSurface, offset: Offset(2, 2))],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  LucideIcons.logOut,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  'Keluar',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.5,
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
