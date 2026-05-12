import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'smooth_scroll.dart';
import '../config/theme.dart';

// ─── Breakpoints ─────────────────────────────────────────────────────────────
class Breakpoints {
  static const double mobile  = 600;
  static const double tablet  = 900;
  static const double desktop = 1280;

  static bool isMobile(BuildContext ctx)  => MediaQuery.of(ctx).size.width < mobile;
  static bool isTablet(BuildContext ctx)  { final w = MediaQuery.of(ctx).size.width; return w >= mobile && w < tablet; }
  static bool isDesktop(BuildContext ctx) => MediaQuery.of(ctx).size.width >= tablet;

  static int gridColumns(double width, {int max = 3}) {
    if (width >= desktop) return max;
    if (width >= tablet)  return (max).clamp(2, max);
    if (width >= mobile)  return (max).clamp(1, 2);
    return 1;
  }

  static EdgeInsets screenPadding(double width) {
    if (width >= tablet) return const EdgeInsets.symmetric(horizontal: 40, vertical: 28);
    if (width >= mobile) return const EdgeInsets.symmetric(horizontal: 24, vertical: 20);
    return const EdgeInsets.symmetric(horizontal: 16, vertical: 16);
  }
}

// ─── AppShell ─────────────────────────────────────────────────────────────────
class AppShell extends StatelessWidget {
  final Widget child;
  final bool transparent;
  final bool useScroll;
  final List<Widget>? backgroundDecorations;

  const AppShell({
    super.key,
    required this.child,
    this.transparent = false,
    this.useScroll   = false,
    this.backgroundDecorations,
  });

  @override
  Widget build(BuildContext context) {
    final theme  = Theme.of(context);
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
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
      body: Stack(
        children: [
          const AppBackground(),
          if (backgroundDecorations != null) ...backgroundDecorations!,
          SafeArea(
            bottom: !isWide,
            child: SmoothScrollWrapper(child: content),
          ),
        ],
      ),
    );
  }
}

// ─── AppBackground ────────────────────────────────────────────────────────────
/// Deep Space animated mesh background.
/// Dark: Indigo/Purple glows on near-black. Light: Soft lavender-to-white.
class AppBackground extends StatelessWidget {
  const AppBackground({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return RepaintBoundary(
      child: Stack(
        children: [
          // Base gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        const Color(0xFF0D0D1A),
                        const Color(0xFF0F0F23),
                        const Color(0xFF0D0D1A),
                      ]
                    : [
                        const Color(0xFFF0EEFF),
                        const Color(0xFFF8F7FF),
                        const Color(0xFFEEF2FF),
                      ],
              ),
            ),
          ),

          // Top-left primary indigo glow
          Positioned(
            top: -180,
            left: -120,
            child: Container(
              width: 560,
              height: 560,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.indigoPrimary.withAlpha(isDark ? 55 : 30),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Bottom-right purple glow
          Positioned(
            bottom: -220,
            right: -100,
            child: Container(
              width: 700,
              height: 700,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.purpleSecondary.withAlpha(isDark ? 40 : 20),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Center-right subtle indigo blob
          Positioned(
            top: 200,
            right: -80,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.indigoLight.withAlpha(isDark ? 20 : 12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Subtle dot grid overlay (dark only)
          if (isDark)
            Positioned.fill(
              child: CustomPaint(painter: _DotGridPainter()),
            ),

          // Noise overlay for light mode texture
          if (!isDark)
            Positioned.fill(
              child: CustomPaint(painter: _NoiseGridPainter()),
            ),
        ],
      ),
    );
  }
}

class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.indigoPrimary.withAlpha(18)
      ..strokeCap = StrokeCap.round;
    const spacing = 32.0;
    const dotR = 1.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), dotR, paint);
      }
    }
  }
  @override
  bool shouldRepaint(_DotGridPainter old) => false;
}

class _NoiseGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.indigoPrimary.withAlpha(8)
      ..strokeCap = StrokeCap.round;
    const spacing = 28.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 0.8, paint);
      }
    }
  }
  @override
  bool shouldRepaint(_NoiseGridPainter old) => false;
}

// ─── GlassCard ───────────────────────────────────────────────────────────────
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double radius;
  final Color? overrideColor;
  final List<BoxShadow>? shadows;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.radius  = 20,
    this.overrideColor,
    this.shadows,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return RepaintBoundary(
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: overrideColor ??
              (isDark
                  ? AppTheme.darkCard.withAlpha(240)
                  : AppTheme.lightSurface.withAlpha(252)),
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(
            color: isDark
                ? AppTheme.indigoPrimary.withAlpha(35)
                : AppTheme.lightBorder,
            width: 1.2,
          ),
          boxShadow: shadows ??
              [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withAlpha(120)
                      : AppTheme.indigoPrimary.withAlpha(18),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: isDark
                      ? AppTheme.indigoPrimary.withAlpha(20)
                      : AppTheme.indigoPrimary.withAlpha(8),
                  blurRadius: 60,
                  offset: const Offset(0, 20),
                ),
              ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius - 1),
          child: child,
        ),
      ),
    );
  }
}

// ─── PremiumCard ─────────────────────────────────────────────────────────────
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
    this.radius     = 20,
    this.accentColor,
  });

  @override
  State<PremiumCard> createState() => _PremiumCardState();
}

class _PremiumCardState extends State<PremiumCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark  = Theme.of(context).brightness == Brightness.dark;
    final accent  = widget.accentColor ?? AppTheme.indigoPrimary;

    return MouseRegion(
      cursor: widget.onTap != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        margin: widget.margin,
        transform: Matrix4.identity()
          ..setTranslationRaw(0, _hovered ? -8.0 : 0.0, 0),
        decoration: BoxDecoration(
          color: isDark
              ? AppTheme.darkCard
              : AppTheme.lightSurface,
          borderRadius: BorderRadius.circular(widget.radius),
          border: Border.all(
            color: _hovered
                ? accent.withAlpha(isDark ? 120 : 80)
                : (isDark
                    ? AppTheme.darkBorder
                    : AppTheme.lightBorder),
            width: _hovered ? 1.5 : 1.0,
          ),
          boxShadow: [
            // Base shadow
            BoxShadow(
              color: Colors.black.withAlpha(isDark ? 80 : 12),
              blurRadius: _hovered ? 20 : 8,
              offset: Offset(0, _hovered ? 12 : 3),
            ),
            // Colored glow on hover
            if (_hovered)
              BoxShadow(
                color: accent.withAlpha(isDark ? 70 : 40),
                blurRadius: 40,
                offset: const Offset(0, 16),
              ),
          ],
        ),
        child: Stack(
          children: [
            // Subtle gradient overlay on hover
            if (_hovered)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(widget.radius),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        accent.withAlpha(isDark ? 15 : 8),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ClipRRect(
              borderRadius: BorderRadius.circular(widget.radius - 1),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.onTap,
                  splashColor: accent.withAlpha(30),
                  highlightColor: accent.withAlpha(15),
                  child: Padding(
                    padding: widget.padding ?? const EdgeInsets.all(20),
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

// ─── StatCard ─────────────────────────────────────────────────────────────────
class StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final VoidCallback? onTap;
  final String? trend;

  const StatCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.onTap,
    this.trend,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PremiumCard(
      onTap: onTap,
      accentColor: color,
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // Icon with gradient background
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color.withAlpha(isDark ? 60 : 40),
                  color.withAlpha(isDark ? 30 : 20),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: color.withAlpha(isDark ? 80 : 50),
                width: 1.0,
              ),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
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
                    color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
                    letterSpacing: 0.2,
                    fontFamily: GoogleFonts.poppins().fontFamily,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Theme.of(context).colorScheme.onSurface,
                      letterSpacing: -1.0,
                      fontFamily: GoogleFonts.poppins().fontFamily,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (trend != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withAlpha(isDark ? 40 : 20),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(
                trend!,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: color,
                  fontFamily: GoogleFonts.poppins().fontFamily,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── SkeletonLoader ──────────────────────────────────────────────────────────
class SkeletonLoader extends StatefulWidget {
  final double width;
  final double height;
  final double radius;

  const SkeletonLoader({
    super.key,
    this.width  = double.infinity,
    this.height = 20,
    this.radius = 12,
  });

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Opacity(
        opacity: _anim.value,
        child: Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [
                      AppTheme.darkBorder,
                      AppTheme.indigoPrimary.withAlpha(30),
                    ]
                  : [
                      AppTheme.lightBorder,
                      AppTheme.indigoPrimary.withAlpha(20),
                    ],
            ),
            borderRadius: BorderRadius.circular(widget.radius),
          ),
        ),
      ),
    );
  }
}

// ─── AppTextField ─────────────────────────────────────────────────────────────
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
    _node.addListener(() => setState(() => _focused = _node.hasFocus));
  }

  @override
  void dispose() {
    if (widget.focusNode == null) _node.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const accent = AppTheme.indigoPrimary;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: _focused
            ? [BoxShadow(color: accent.withAlpha(70), blurRadius: 20, spreadRadius: 1)]
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
          fontFamily: GoogleFonts.poppins().fontFamily,
          color: isDark ? AppTheme.textDark : AppTheme.textLight,
        ),
        decoration: InputDecoration(
          hintText: widget.hintText,
          labelText: widget.labelText,
          prefixIcon: widget.prefixIcon != null
              ? Icon(widget.prefixIcon,
                  color: _focused ? accent : (isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt))
              : null,
          suffixIcon: widget.suffix,
          filled: true,
          fillColor: isDark
              ? AppTheme.darkCard.withAlpha(200)
              : AppTheme.lightSurface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppTheme.indigoPrimary, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        ),
      ),
    );
  }
}

// ─── SectionHeader ────────────────────────────────────────────────────────────
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
    final theme  = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Accent bar
        Container(
          width: 4,
          height: 22,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppTheme.indigoPrimary, AppTheme.purpleSecondary],
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                  color: isDark ? AppTheme.textDark : AppTheme.textLight,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 3),
                Text(
                  subtitle!,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (action != null) action!,
      ],
    );
  }
}

// ─── AppFAB ──────────────────────────────────────────────────────────────────
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
    final c = color ?? AppTheme.indigoPrimary;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [c, AppTheme.purpleSecondary],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(100),
        boxShadow: [
          BoxShadow(
            color: c.withAlpha(100),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        onPressed: onPressed,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
        icon: Icon(icon),
        label: Text(
          label,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

// ─── EmptyState ───────────────────────────────────────────────────────────────
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? subtitle;
  final Color? color;

  const EmptyState({
    super.key,
    required this.icon,
    required this.message,
    this.subtitle,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c      = color ?? AppTheme.indigoPrimary;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    c.withAlpha(isDark ? 40 : 25),
                    AppTheme.purpleSecondary.withAlpha(isDark ? 25 : 15),
                  ],
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: c.withAlpha(isDark ? 60 : 40),
                  width: 1.5,
                ),
              ),
              child: Icon(icon, size: 44, color: c.withAlpha(200)),
            ),
            const SizedBox(height: 24),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: (isDark ? AppTheme.textDark : AppTheme.textLight)
                    .withAlpha(180),
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── ResponsiveLayout ─────────────────────────────────────────────────────────
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
      if (c.maxWidth >= Breakpoints.desktop && desktop != null) return desktop!(ctx, c);
      if (c.maxWidth >= Breakpoints.tablet  && tablet  != null) return tablet!(ctx, c);
      return mobile(ctx, c);
    });
  }
}
