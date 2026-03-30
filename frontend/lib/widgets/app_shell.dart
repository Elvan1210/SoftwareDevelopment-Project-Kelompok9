import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

// ─── Breakpoints ────────────────────────────────────────────────────────────
/// Single source of truth for all responsive breakpoints.
class Breakpoints {
  static const double mobile = 600;
  static const double tablet = 900;
  static const double desktop = 1280;

  static bool isMobile(BuildContext ctx) =>
      MediaQuery.of(ctx).size.width < mobile;
  static bool isTablet(BuildContext ctx) {
    final w = MediaQuery.of(ctx).size.width;
    return w >= mobile && w < tablet;
  }
  static bool isDesktop(BuildContext ctx) =>
      MediaQuery.of(ctx).size.width >= tablet;

  static int gridColumns(double width, {int max = 3}) {
    if (width >= desktop) return max;
    if (width >= tablet) return (max).clamp(2, max);
    if (width >= mobile) return (max).clamp(1, 2);
    return 1;
  }

  static EdgeInsets screenPadding(double width) {
    if (width >= tablet) {
      return const EdgeInsets.symmetric(horizontal: 40, vertical: 28);
    }
    if (width >= mobile) {
      return const EdgeInsets.symmetric(horizontal: 24, vertical: 20);
    }
    return const EdgeInsets.symmetric(horizontal: 16, vertical: 16);
  }
}

// ─── AppShell ───────────────────────────────────────────────────────────────
/// Gradient background wrapper for inner screens.
/// On web (>= tablet) it passes through transparent so the parent glass card shows.
/// On mobile it paints its own gradient to match the Antigravity theme.
class AppShell extends StatelessWidget {
  final Widget child;
  final bool transparent;

  const AppShell({super.key, required this.child, this.transparent = false});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isWide = MediaQuery.of(context).size.width >= Breakpoints.tablet;

    if (transparent || isWide) return child;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF0F172A), const Color(0xFF020617)]
              : [const Color(0xFFF8FAFC), const Color(0xFFE2E8F0)],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 88),
        child: child,
      ),
    );
  }
}

// ─── ResponsiveLayout ───────────────────────────────────────────────────────
/// Convenience widget to build different layouts per breakpoint.
class ResponsiveLayout extends StatelessWidget {
  final Widget Function(BuildContext, BoxConstraints) mobile;
  final Widget Function(BuildContext, BoxConstraints)? tablet;
  final Widget Function(BuildContext, BoxConstraints)? desktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (ctx, c) {
      if (c.maxWidth >= Breakpoints.tablet && desktop != null) {
        return desktop!(ctx, c);
      }
      if (c.maxWidth >= Breakpoints.mobile && tablet != null) {
        return tablet!(ctx, c);
      }
      return mobile(ctx, c);
    });
  }
}

// ─── GlassCard ──────────────────────────────────────────────────────────────
/// Standard frosted-glass card used across the design system.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double radius;
  final double blurSigma;
  final Color? overrideColor;
  final List<BoxShadow>? shadows;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.radius = 24,
    this.blurSigma = 12,
    this.overrideColor,
    this.shadows,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: overrideColor ??
                theme.colorScheme.surface.withAlpha(isDark ? 150 : 220),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: Colors.white.withAlpha(isDark ? 25 : 100),
              width: 1.5,
            ),
            boxShadow: shadows ??
                [
                  BoxShadow(
                    color: Colors.black.withAlpha(isDark ? 30 : 10),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
          ),
          child: child,
        ),
      ),
    );
  }
}

// ─── PremiumCard ────────────────────────────────────────────────────────────
/// Hover-lift interactive card with smooth shadow/scale transition.
/// On mobile, taps provide a subtle ink ripple instead.
class PremiumCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double radius;
  final Color? accentColor;

  const PremiumCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.margin,
    this.radius = 24,
    this.accentColor,
  });

  @override
  State<PremiumCard> createState() => _PremiumCardState();
}

class _PremiumCardState extends State<PremiumCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = widget.accentColor ?? theme.primaryColor;

    return RepaintBoundary(
      child: MouseRegion(
        cursor: widget.onTap != null
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCirc,
        margin: widget.margin,
        transform: Matrix4.translationValues(0.0, _hovered ? -4.0 : 0.0, 0.0),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withAlpha(isDark ? 180 : 245),
          borderRadius: BorderRadius.circular(widget.radius),
          border: Border.all(
            color: _hovered
                ? accent.withAlpha(120)
                : Colors.white.withAlpha(isDark ? 20 : 80),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: _hovered
                  ? accent.withAlpha(isDark ? 40 : 25)
                  : Colors.black.withAlpha(isDark ? 20 : 6),
              blurRadius: _hovered ? 40 : 16,
              spreadRadius: _hovered ? 2 : 0,
              offset: const Offset(0, 10),
            ),
            if (!_hovered)
              BoxShadow(
                color: Colors.black.withAlpha(isDark ? 10 : 3),
                blurRadius: 40,
                offset: const Offset(0, 24),
              ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(widget.radius),
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(widget.radius),
            splashColor: accent.withAlpha(30),
            highlightColor: accent.withAlpha(15),
            child: Padding(
              padding: widget.padding ?? const EdgeInsets.all(20),
              child: widget.child,
            ),
          ),
        ),
      ),
    ),);
  }
}

// ─── StatCard ───────────────────────────────────────────────────────────────
/// A KPI stat card with icon, label, value and accent color.
class StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final VoidCallback? onTap;

  const StatCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return PremiumCard(
      onTap: onTap,
      accentColor: color,
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withAlpha(isDark ? 40 : 20),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface.withAlpha(150),
                      letterSpacing: 0.5,
                    )),
                const SizedBox(height: 4),
                Text(value,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: theme.colorScheme.onSurface,
                      letterSpacing: -0.5,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── SkeletonLoader ─────────────────────────────────────────────────────────
/// Shimmer-style loading placeholder. Drop-in for any content.
class SkeletonLoader extends StatelessWidget {
  final double width;
  final double height;
  final double radius;

  const SkeletonLoader({
    super.key,
    this.width = double.infinity,
    this.height = 20,
    this.radius = 12,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withAlpha(15)
            : Colors.black.withAlpha(8),
        borderRadius: BorderRadius.circular(radius),
      ),
    )
        .animate(onPlay: (c) => c.repeat())
        .shimmer(
          duration: 2000.ms,
          color: isDark
              ? Colors.white.withAlpha(20)
              : Colors.white.withAlpha(120),
        );
  }
}

// ─── AntigravityTextField ───────────────────────────────────────────────────
/// Premium input field with focus glow effect.
class AntigravityTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String? hintText;
  final String? labelText;
  final IconData? prefixIcon;
  final Widget? suffix;
  final TextInputType? keyboardType;
  final bool obscureText;
  final ValueChanged<String>? onChanged;
  final String? Function(String?)? validator;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  const AntigravityTextField({
    super.key,
    this.controller,
    this.hintText,
    this.labelText,
    this.prefixIcon,
    this.suffix,
    this.keyboardType,
    this.obscureText = false,
    this.onChanged,
    this.validator,
    this.focusNode,
    this.textInputAction,
    this.onSubmitted,
  });

  @override
  State<AntigravityTextField> createState() => _AntigravityTextFieldState();
}

class _AntigravityTextFieldState extends State<AntigravityTextField> {
  bool _focused = false;
  late FocusNode _node;

  @override
  void initState() {
    super.initState();
    _node = widget.focusNode ?? FocusNode();
    _node.addListener(() {
      setState(() => _focused = _node.hasFocus);
    });
  }

  @override
  void dispose() {
    if (widget.focusNode == null) _node.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = theme.primaryColor;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: _focused
            ? [BoxShadow(color: accent.withAlpha(80), blurRadius: 20, spreadRadius: 2)]
            : [],
      ),
      child: TextFormField(
        controller: widget.controller,
        focusNode: _node,
        obscureText: widget.obscureText,
        keyboardType: widget.keyboardType,
        onChanged: widget.onChanged,
        validator: widget.validator,
        textInputAction: widget.textInputAction,
        onFieldSubmitted: widget.onSubmitted,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSurface,
        ),
        decoration: InputDecoration(
          hintText: widget.hintText,
          labelText: widget.labelText,
          prefixIcon: widget.prefixIcon != null
              ? Icon(widget.prefixIcon,
                  color: _focused
                      ? accent
                      : theme.colorScheme.onSurface.withAlpha(120))
              : null,
          suffixIcon: widget.suffix,
          filled: true,
          fillColor: theme.colorScheme.surface
              .withAlpha(isDark ? 180 : 255),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
                color: Colors.white.withAlpha(isDark ? 20 : 80)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
                color: theme.colorScheme.onSurface.withAlpha(30)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: accent, width: 2),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }
}

// ─── SectionHeader ──────────────────────────────────────────────────────────
/// Consistent section title + optional action button.
class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? action;

  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900, letterSpacing: -0.5)),
              if (subtitle != null) ...[
                const SizedBox(height: 6),
                Text(subtitle!,
                    style: TextStyle(
                      fontSize: 15,
                      color:
                          theme.colorScheme.onSurface.withAlpha(160),
                    )),
              ],
            ],
          ),
        ),
        if (action != null) action!,
      ],
    );
  }
}

// ─── AntigravityFAB ─────────────────────────────────────────────────────────
/// Premium Floating Action Button with glow shadow.
class AntigravityFAB extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String label;
  final Color? color;

  const AntigravityFAB({
    super.key,
    required this.onPressed,
    required this.icon,
    required this.label,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).primaryColor;
    return FloatingActionButton.extended(
      onPressed: onPressed,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
      backgroundColor: c,
      foregroundColor: Colors.white,
      icon: Icon(icon),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
    )
        .animate()
        .scale(delay: 400.ms, curve: Curves.easeOutBack)
        .fadeIn();
  }
}

// ─── EmptyState ─────────────────────────────────────────────────────────────
/// Consistent empty state placeholder widget.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final Color? color;

  const EmptyState({
    super.key,
    required this.icon,
    required this.message,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).primaryColor;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: c.withAlpha(20),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 56, color: c.withAlpha(180)),
          ),
          const SizedBox(height: 24),
          Text(message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurface.withAlpha(170),
              )),
        ],
      ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.85, 0.85), curve: Curves.easeOutBack),
    );
  }
}
