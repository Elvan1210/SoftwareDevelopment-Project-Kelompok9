import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../config/theme.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────────────────────────────────────
// COSMIC EDU — Premium Design System
// All colors WCAG-AA checked (≥4.5:1 small text, ≥3:1 large text)
// ─────────────────────────────────────────────────────────────────────────────

class CosmicColors {
  // Backgrounds
  static const bg1 = Color(0xFF0D0B2B); // Deep space navy
  static const bg2 = Color(0xFF1A0A3D); // Deep violet
  static const bg3 = Color(0xFF0F1F4A); // Midnight blue

  // Sidebar
  static const sidebarBg   = Color(0x99080620); // 60% opaque deep
  static const sidebarBorder = Color(0x33A78BFA); // Purple border

  // Glass card
  static const glassWhite  = Color(0x1AFFFFFF); // 10% white
  static const glassBorder = Color(0x33FFFFFF);  // 20% white border
  static const glassLight  = Color(0xF5FFFFFF);  // near-white for light-bg cards

  // Accent palette
  static const violet  = Color(0xFFA855F7); // Purple-500
  static const cyan    = Color(0xFF38BDF8); // Sky-400
  static const rose    = Color(0xFFF472B6); // Pink-400
  static const amber   = Color(0xFFFBBF24); // Amber-400
  static const emerald = Color(0xFF34D399); // Emerald-400
  static const indigo  = Color(0xFF818CF8); // Indigo-400

  // Text — WCAG AA on dark backgrounds
  static const textPrimary = Color(0xFFF8F8FF);    // 21:1 vs bg1 ✅
  static const textSecondary = Color(0xFFCDD0F0);  // ~8:1 vs bg1 ✅
  static const textMuted = Color(0xFFB8BFEC);      // ~5.5:1 vs bg1 ✅ (bumped from 9EA5D4)

  // Text on glass cards (white/light)
  static const textOnLight = Color(0xFF1A1A3E);    // 18:1 vs white ✅
  static const textMutedOnLight = Color(0xFF4A4A7A); // 7:1 vs white ✅

  // Glow shadows
  static BoxShadow violetGlow = BoxShadow(color: violet.withAlpha(80), blurRadius: 24, spreadRadius: 0);
  static BoxShadow cyanGlow   = BoxShadow(color: cyan.withAlpha(80), blurRadius: 24);
  static BoxShadow roseGlow   = BoxShadow(color: rose.withAlpha(80), blurRadius: 24);
  static BoxShadow amberGlow  = BoxShadow(color: amber.withAlpha(80), blurRadius: 24);
}

// ─────────────────────────────────────────────────────────────────────────────
// Cosmic Sidebar Background (static deep-space gradient — sidebar/navbar only)
// ─────────────────────────────────────────────────────────────────────────────
class CosmicBackground extends StatelessWidget {
  final Widget child;
  const CosmicBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0D0B2B),
            Color(0xFF140C38),
            Color(0xFF0A1840),
          ],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
      child: child,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Content Surface — adaptive background for main content areas
// ─────────────────────────────────────────────────────────────────────────────
class ContentSurface extends StatelessWidget {
  final Widget child;
  const ContentSurface({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ColoredBox(
      color: isDark ? const Color(0xFF161D2B) : const Color(0xFFF8F9FC),
      child: child,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Frosted Glass Card
// ─────────────────────────────────────────────────────────────────────────────
class FrostCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final double radius;
  final double blur;
  final Color? color;
  final List<BoxShadow>? shadows;
  final Border? border;

  const FrostCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.radius = 20,
    this.blur = 16,
    this.color,
    this.shadows,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: shadows ?? [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 40 : 8),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: color ?? (isDark ? const Color(0xFF1E2538) : Colors.white),
            borderRadius: BorderRadius.circular(radius),
            border: border ?? Border.all(
              color: isDark ? const Color(0xFF252D3D) : const Color(0xFFE5E7EB),
              width: 1.0,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Premium Accent Stat Card
// ─────────────────────────────────────────────────────────────────────────────
class CosmicStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final List<Color> gradient;
  final VoidCallback? onTap;

  const CosmicStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.gradient,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryAccent = gradient.isNotEmpty ? gradient.first : const Color(0xFF6D28D9);
    final finalGradient = gradient.isNotEmpty 
        ? (gradient.length == 1 ? [gradient.first, gradient.first.withBlue(220)] : gradient)
        : [const Color(0xFF6D28D9), const Color(0xFF4F46E5)];

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: finalGradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.white.withAlpha(isDark ? 70 : 110),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: primaryAccent.withAlpha(isDark ? 90 : 50),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(30), // frosted glass shadow overlay
              borderRadius: BorderRadius.circular(19),
              border: Border.all(
                color: Colors.white.withAlpha(30),
                width: 1.0,
              ),
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(50),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.white.withAlpha(70),
                          width: 1.0,
                        ),
                      ),
                      child: Icon(icon, color: Colors.white, size: 16),
                    ),
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(35),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.trending_up_rounded,
                        color: Colors.white,
                        size: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  value,
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label.toUpperCase(),
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white.withAlpha(210),
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.12, curve: Curves.easeOutCubic);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Glowing Sidebar Item
// ─────────────────────────────────────────────────────────────────────────────
class CosmicSidebarItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final int badgeCount;
  final bool isChannel;
  final VoidCallback? onDelete;

  const CosmicSidebarItem({
    super.key,
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.badgeCount = 0,
    this.isChannel = false,
    this.onDelete,
  });

  @override
  State<CosmicSidebarItem> createState() => _CosmicSidebarItemState();
}

class _CosmicSidebarItemState extends State<CosmicSidebarItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.isSelected;
    final hovered = _hovered && !active;
    return Padding(
      padding: EdgeInsets.only(bottom: widget.isChannel ? 1 : 3),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.symmetric(
              horizontal: 12, vertical: widget.isChannel ? 8 : 10),
            decoration: BoxDecoration(
              // Double-bezel: outer glow shell when selected
              gradient: active
                ? LinearGradient(
                    colors: [CosmicColors.violet.withAlpha(55), CosmicColors.indigo.withAlpha(25)],
                  )
                : hovered
                ? LinearGradient(
                    colors: [Colors.white.withAlpha(10), Colors.white.withAlpha(5)],
                  )
                : null,
              borderRadius: BorderRadius.circular(12),
              border: active
                ? Border.all(color: CosmicColors.violet.withAlpha(90), width: 1.0)
                : hovered
                ? Border.all(color: Colors.white.withAlpha(18), width: 1.0)
                : null,
              boxShadow: active
                ? [BoxShadow(color: CosmicColors.violet.withAlpha(45), blurRadius: 14, spreadRadius: -2)]
                : null,
            ),
            child: Row(children: [
              // Left accent bar
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 3,
                height: active ? (widget.isChannel ? 14 : 18) : 0,
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  gradient: active
                    ? const LinearGradient(
                        begin: Alignment.topCenter, end: Alignment.bottomCenter,
                        colors: [CosmicColors.violet, CosmicColors.cyan])
                    : null,
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: active
                    ? [BoxShadow(color: CosmicColors.violet.withAlpha(180), blurRadius: 6)]
                    : null,
                ),
              ),
              // Icon with animated color
              AnimatedScale(
                scale: active ? 1.05 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: Icon(widget.icon,
                  color: active ? CosmicColors.violet
                    : hovered ? CosmicColors.textSecondary
                    : CosmicColors.textMuted,
                  size: widget.isChannel ? 15 : 18),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(widget.label, style: TextStyle(
                color: active ? CosmicColors.textPrimary
                  : hovered ? CosmicColors.textSecondary
                  : CosmicColors.textMuted,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                fontSize: widget.isChannel ? 12 : 13.5,
              ))),
              if (widget.badgeCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFFFF6B35), Color(0xFFFF4057)]),
                    borderRadius: BorderRadius.circular(100),
                    boxShadow: [BoxShadow(color: const Color(0xFFFF4057).withAlpha(100), blurRadius: 6)],
                  ),
                  child: Text('${widget.badgeCount}', style: const TextStyle(
                    color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900)),
                ),
              if (widget.onDelete != null)
                GestureDetector(
                  onTap: widget.onDelete,
                  child: const Icon(Icons.delete_outline, size: 14, color: CosmicColors.textMuted),
                ),
            ]),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Cosmic Pill Nav Item (mobile bottom nav)
// ─────────────────────────────────────────────────────────────────────────────
class CosmicPillNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final int badgeCount;

  const CosmicPillNavItem({
    super.key,
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(horizontal: isSelected ? 16 : 10, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? (isDark ? const Color(0xFF1E2235) : const Color(0xFFEFF1FE))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isSelected 
                ? (isDark ? const Color(0xFF3F4E9F).withAlpha(120) : const Color(0xFF7B83EB).withAlpha(80))
                : Colors.transparent,
            width: 1.2,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: const Color(0xFF7B83EB).withAlpha(isDark ? 30 : 15),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ] : null,
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  color: isSelected 
                      ? (isDark ? const Color(0xFF9EAAFF) : const Color(0xFF4C51BF))
                      : (isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt),
                  size: 18,
                ),
                if (isSelected) ...[
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: GoogleFonts.plusJakartaSans(
                      color: isDark ? Colors.white : const Color(0xFF2C318C),
                      fontWeight: FontWeight.w900,
                      fontSize: 11,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ],
            ),
            if (badgeCount > 0)
              Positioned(
                right: -6,
                top: -8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF4057),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$badgeCount',
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Premium Minimalist Welcome Banner
// ─────────────────────────────────────────────────────────────────────────────
class CosmicWelcomeBanner extends StatelessWidget {
  final String greeting;
  final String name;
  final String subtitle;
  final Widget? action;
  final List<Color>? gradientColors;

  const CosmicWelcomeBanner({
    super.key,
    required this.greeting,
    required this.name,
    required this.subtitle,
    this.action,
    this.gradientColors,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gradient = gradientColors != null && gradientColors!.isNotEmpty
        ? (gradientColors!.length == 1 
            ? [gradientColors!.first, gradientColors!.first.withBlue(220)] 
            : gradientColors!)
        : [const Color(0xFF6D28D9), const Color(0xFF4F46E5)];

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withAlpha(isDark ? 80 : 120),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: gradient.first.withAlpha(isDark ? 90 : 50),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withAlpha(30), // Frosted glass-like dark overlay for high-contrast & depth
            borderRadius: BorderRadius.circular(19),
            border: Border.all(
              color: Colors.white.withAlpha(40),
              width: 1.0,
            ),
          ),
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Eyebrow Tag
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(60),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.white.withAlpha(80),
                          width: 1.0,
                        ),
                      ),
                      child: Text(
                        greeting.toUpperCase(),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      name,
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white.withAlpha(220),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (action != null) ...[
                      const SizedBox(height: 16),
                      action!,
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Decorative icon in beautiful concentric nested circular wrapper
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(40),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withAlpha(60),
                    width: 1.0,
                  ),
                ),
                child: Center(
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(60),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.auto_awesome_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.08);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Menu Quick Card (grid)
// ─────────────────────────────────────────────────────────────────────────────
class CosmicMenuCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final List<Color> gradient;
  final VoidCallback onTap;

  const CosmicMenuCard({
    super.key,
    required this.label,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryAccent = gradient.isNotEmpty ? gradient.first : const Color(0xFF6D28D9);
    final finalGradient = gradient.isNotEmpty
        ? (gradient.length == 1 ? [gradient.first, gradient.first.withBlue(220)] : gradient)
        : [const Color(0xFF6D28D9), const Color(0xFF4F46E5)];

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: finalGradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.white.withAlpha(isDark ? 70 : 110),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: primaryAccent.withAlpha(isDark ? 80 : 40),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(25), // Elegant glass overlay
              borderRadius: BorderRadius.circular(19),
              border: Border.all(
                color: Colors.white.withAlpha(30),
                width: 1.0,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(50),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.white.withAlpha(70),
                      width: 1.0,
                    ),
                  ),
                  child: Icon(icon, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Live Class Alert Banner
// ─────────────────────────────────────────────────────────────────────────────
class CosmicLiveBanner extends StatelessWidget {
  final VoidCallback onJoin;

  const CosmicLiveBanner({super.key, required this.onJoin});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F3A2E) : const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF10B981).withAlpha(120) : const Color(0xFFA7F3D0),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withAlpha(isDark ? 30 : 10),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.circle, color: Color(0xFF10B981), size: 10)
              .animate(onPlay: (c) => c.repeat())
              .fadeOut(duration: 800.ms)
              .then()
              .fadeIn(duration: 800.ms),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'LIVE — Kelas Sedang Berlangsung',
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF065F46),
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                Text(
                  'Guru sudah memulai sesi video call.',
                  style: TextStyle(
                    color: isDark ? const Color(0xFFA7F3D0) : const Color(0xFF047857),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: onJoin,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: const Text('Gabung', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
          ),
        ],
      ),
    ).animate().slideY(begin: -0.2).fade(duration: 500.ms);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section Label
// ─────────────────────────────────────────────────────────────────────────────
class CosmicSectionLabel extends StatelessWidget {
  final String text;
  const CosmicSectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 3.5,
            height: 16,
            decoration: BoxDecoration(
              color: AppTheme.indigoPrimary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: isDark ? Colors.white : AppTheme.textLight,
              fontSize: 15,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Premium Elevated Button with Vivid Fill Color & Elegant Glowing Drop Shadow
// ─────────────────────────────────────────────────────────────────────────────
class PremiumElevatedButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final Color? color;
  final Color? textColor;
  final IconData? icon;
  final double radius;
  final EdgeInsetsGeometry padding;
  final double fontSize;
  final double iconSize;

  const PremiumElevatedButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.color,
    this.textColor,
    this.icon,
    this.radius = 14,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    this.fontSize = 13,
    this.iconSize = 16,
  });

  @override
  State<PremiumElevatedButton> createState() => _PremiumElevatedButtonState();
}

class _PremiumElevatedButtonState extends State<PremiumElevatedButton> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final baseColor = widget.color ?? AppTheme.indigoPrimary;
    final foreground = widget.textColor ?? Colors.white;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: widget.onPressed != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onPressed,
        child: AnimatedScale(
          scale: widget.onPressed == null ? 1.0 : (_pressed ? 0.96 : (_hovered ? 1.02 : 1.0)),
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: widget.padding,
            decoration: BoxDecoration(
              color: widget.onPressed == null ? baseColor.withAlpha(80) : baseColor,
              borderRadius: BorderRadius.circular(widget.radius),
              boxShadow: widget.onPressed == null
                  ? null
                  : [
                      BoxShadow(
                        color: baseColor.withAlpha(_hovered ? 130 : 90),
                        blurRadius: _hovered ? 20 : 12,
                        offset: Offset(0, _hovered ? 8 : 4),
                      ),
                    ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.icon != null) ...[
                  Icon(widget.icon, color: foreground, size: widget.iconSize),
                  const SizedBox(width: 8),
                ],
                DefaultTextStyle(
                  style: GoogleFonts.poppins(
                    color: foreground,
                    fontWeight: FontWeight.w800,
                    fontSize: widget.fontSize,
                  ),
                  child: widget.child,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Premium Outlined Button with Hover & Custom Outlined Border Styling
// ─────────────────────────────────────────────────────────────────────────────
class PremiumOutlinedButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final Color? color;
  final Color? textColor;
  final IconData? icon;
  final double radius;
  final EdgeInsetsGeometry padding;
  final double fontSize;
  final double iconSize;

  const PremiumOutlinedButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.color,
    this.textColor,
    this.icon,
    this.radius = 14,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    this.fontSize = 13,
    this.iconSize = 16,
  });

  @override
  State<PremiumOutlinedButton> createState() => _PremiumOutlinedButtonState();
}

class _PremiumOutlinedButtonState extends State<PremiumOutlinedButton> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final baseColor = widget.color ?? AppTheme.indigoPrimary;
    final foreground = widget.textColor ?? baseColor;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: widget.onPressed != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onPressed,
        child: AnimatedScale(
          scale: widget.onPressed == null ? 1.0 : (_pressed ? 0.96 : (_hovered ? 1.02 : 1.0)),
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: widget.padding,
            decoration: BoxDecoration(
              color: _hovered ? baseColor.withAlpha(20) : Colors.transparent,
              borderRadius: BorderRadius.circular(widget.radius),
              border: Border.all(
                color: widget.onPressed == null ? baseColor.withAlpha(80) : baseColor,
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.icon != null) ...[
                  Icon(widget.icon, color: foreground, size: widget.iconSize),
                  const SizedBox(width: 8),
                ],
                DefaultTextStyle(
                  style: GoogleFonts.poppins(
                    color: foreground,
                    fontWeight: FontWeight.w800,
                    fontSize: widget.fontSize,
                  ),
                  child: widget.child,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

