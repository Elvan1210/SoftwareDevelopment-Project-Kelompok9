import 'dart:ui';
import 'package:flutter/material.dart';
import 'smooth_scroll.dart';

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
/// The main structural wrapper for most screens.
/// Features a static high-performance background and ensures responsive padding.
class AppShell extends StatelessWidget {
  final Widget child;
  final bool transparent;
  final bool useScroll;
  final List<Widget>? backgroundDecorations;

  const AppShell({
    super.key, 
    required this.child, 
    this.transparent = false,
    this.useScroll = false,
    this.backgroundDecorations,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isWide = MediaQuery.of(context).size.width >= Breakpoints.tablet;

    Widget content = child;
    if (useScroll && !isWide) {
      content = SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: child,
      );
    }

    if (transparent) return content;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      body: Stack(
        children: [
          // 1. Foundation Background
          const AppBackground(),
          
          // 2. Custom Decorations
          if (backgroundDecorations != null) ...backgroundDecorations!,

          // 3. Main Content
          SafeArea(
            bottom: !isWide,
            child: SmoothScrollWrapper(child: content),
          ),
        ],
      ),
    );
  }
}

// ─── AppBackground ──────────────────────────────────────────────────
/// Minimalist atmospheric background. No flashy blobs, just deep focus.
class AppBackground extends StatelessWidget {
  const AppBackground({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return RepaintBoundary(
      child: Container(
        color: theme.scaffoldBackgroundColor,
        child: isDark 
            ? Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(-0.8, -0.8),
                    radius: 2.0,
                    colors: [
                      Colors.white.withAlpha(8), // Very subtle top-left light
                      Colors.transparent,
                    ],
                  ),
                ),
              )
            : Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, -1.0),
                    radius: 1.5,
                    colors: [
                      Colors.black.withAlpha(2),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

// ─── GlassCard ──────────────────────────────────────────────────────────────
/// High-performance frosted-glass card with Static Dual-Layer Border.
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
    this.blurSigma = 0, // Performance: Default to 0 unless needed
    this.overrideColor,
    this.shadows,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: overrideColor ??
                  theme.colorScheme.surface.withAlpha(isDark ? 230 : 255),
              borderRadius: BorderRadius.circular(radius),
              // Pro-Static Dual Border
              border: Border.all(
                color: isDark ? Colors.white.withAlpha(20) : Colors.black.withAlpha(10),
                width: 1.5,
              ),
              boxShadow: shadows ??
                  [
                    BoxShadow(
                      color: Colors.black.withAlpha(isDark ? 100 : 20),
                      blurRadius: 30,
                      offset: const Offset(0, 15),
                    ),
                  ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

// ─── PremiumCard ────────────────────────────────────────────────────────────
/// Next-Gen spatial card with subtle hover translation (no performance-heavy blurs).
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

    return MouseRegion(
      cursor: widget.onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutBack,
        margin: widget.margin,
        transform: Matrix4.identity()
          ..setTranslationRaw(0.0, _hovered ? -6.0 : 0.0, 0.0),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withAlpha(isDark ? 200 : 255),
          borderRadius: BorderRadius.circular(widget.radius),
          // ── Minimalist Sharp Border ──
          border: Border.all(
            color: _hovered ? theme.colorScheme.onSurface.withAlpha(40) : (isDark ? Colors.white.withAlpha(12) : Colors.black.withAlpha(8)),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(isDark ? 50 : 5),
              blurRadius: _hovered ? 25 : 10,
              offset: Offset(0, _hovered ? 8 : 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(widget.radius),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.onTap,
                  splashColor: accent.withAlpha(40),
                  child: Padding(
                    padding: widget.padding ?? const EdgeInsets.all(24),
                    child: widget.child,
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

// ─── StatCard ───────────────────────────────────────────────────────────────
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
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withAlpha(isDark ? 40 : 20),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface.withAlpha(160),
                    letterSpacing: 0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: theme.colorScheme.onSurface,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── SkeletonLoader ─────────────────────────────────────────────────────────
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
    );
  }
}

// ─── AppTextField ───────────────────────────────────────────────────
class AppTextField extends StatefulWidget {
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

  const AppTextField({
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
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
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
            ? [BoxShadow(color: accent.withAlpha(60), blurRadius: 15, spreadRadius: 1)]
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
              .withAlpha(isDark ? 220 : 255),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
                color: theme.colorScheme.onSurface.withAlpha(20)),
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

// ─── AppFAB ─────────────────────────────────────────────────────────
class AppFAB extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String label;
  final Color? color;

  const AppFAB({
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
    );
  }
}

// ─── EmptyState ─────────────────────────────────────────────────────────────
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
      ),
    );
  }
}

// ─── ResponsiveLayout ───────────────────────────────────────────────────────
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
      if (c.maxWidth >= Breakpoints.desktop && desktop != null) {
        return desktop!(ctx, c);
      }
      if (c.maxWidth >= Breakpoints.tablet && tablet != null) {
        return tablet!(ctx, c);
      }
      return mobile(ctx, c);
    });
  }
}

