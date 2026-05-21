import 'package:flutter/material.dart';
import '../config/theme.dart';

const kNeoAsymmetricRadius = BorderRadius.zero;

class NeoCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final EdgeInsets? margin;
  final Color? color;
  final Color? borderColor;
  final BorderRadius? borderRadius;
  final VoidCallback? onTap;

  const NeoCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24),
    this.margin,
    this.color,
    this.borderColor,
    this.borderRadius,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bColor = borderColor ?? Theme.of(context).dividerColor;
    final bg = color ?? Theme.of(context).scaffoldBackgroundColor;

    final content = Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: borderRadius ?? kNeoAsymmetricRadius,
        border: Border.all(color: bColor),
        boxShadow: [
          BoxShadow(
            color: bColor.withAlpha(isDark ? 120 : 80),
            offset: const Offset(4, 4),
            blurRadius: 0,
          )
        ],
      ),
      child: child,
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: content);
    }
    return content;
  }
}

class NeoButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  final Color? color;
  final Color? textColor;
  final EdgeInsets padding;

  const NeoButton({
    super.key,
    required this.text,
    required this.onTap,
    this.color,
    this.textColor,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = color ?? AppTheme.primary;
    final tColor = textColor ?? Colors.white;
    final bColor = Theme.of(context).colorScheme.onSurface;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding,
        constraints: const BoxConstraints(minHeight: 40),
        decoration: BoxDecoration(
          color: bgColor,
          border: Border.all(color: bColor),
          boxShadow: [BoxShadow(color: bColor, offset: const Offset(3, 3))],
        ),
        child: Center(
          child: Text(
            text,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: tColor,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}

class NeoIconBox extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final Color? backgroundColor;
  final Color? borderColor;
  final double size;

  const NeoIconBox({
    super.key,
    required this.icon,
    this.iconColor,
    this.backgroundColor,
    this.borderColor,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    final cIcon = iconColor ?? AppTheme.primary;
    final bg = backgroundColor ?? Theme.of(context).colorScheme.primaryContainer;
    final border = borderColor ?? Theme.of(context).colorScheme.onSurface;

    return Container(
      padding: EdgeInsets.all(size / 1.5),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: border),
      ),
      child: Icon(icon, color: cIcon, size: size),
    );
  }
}

class NeoBadge extends StatelessWidget {
  final String label;
  final Color color;

  const NeoBadge({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(isDark ? 40 : 25),
        border: Border.all(color: color),
      ),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w800, color: color, letterSpacing: 0.5
        ),
      ),
    );
  }
}

class NeoSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  
  const NeoSectionHeader({super.key, required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).textTheme.titleLarge?.color;
    final mutedColor = Theme.of(context).textTheme.bodyMedium?.color;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: -0.3,
            color: textColor,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: mutedColor, fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}

class NeoStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const NeoStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return NeoCard(
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 10),
      color: color.withAlpha(isDark ? 40 : 25),
      borderColor: color,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : color,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white70 : color,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class NeoMenuCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const NeoMenuCard({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return NeoCard(
      padding: const EdgeInsets.all(16),
      color: color.withAlpha(isDark ? 40 : 25),
      borderColor: color,
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 10),
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w800, color: isDark ? Colors.white : color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class NeoSidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isChannel;
  final int? badgeCount;
  final VoidCallback? onDelete;

  const NeoSidebarItem({
    super.key,
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.isChannel = false,
    this.badgeCount,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isSelected ? AppTheme.primary : (isDark ? Colors.white70 : Colors.black87);
    final bg = isSelected ? AppTheme.primary.withAlpha(isDark ? 40 : 25) : Colors.transparent;
    final border = isSelected ? AppTheme.primary : Colors.transparent;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: EdgeInsets.symmetric(horizontal: isChannel ? 20 : 14, vertical: 12),
        decoration: BoxDecoration(
          color: bg,
          border: Border.all(color: border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: isChannel ? 16 : 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600, color: color,
                ),
              ),
            ),
            if (badgeCount != null && badgeCount! > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: AppTheme.rose, borderRadius: BorderRadius.circular(4)),
                child: Text('$badgeCount', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            if (onDelete != null)
              GestureDetector(
                onTap: onDelete,
                child: Icon(Icons.close, size: 14, color: color.withAlpha(128)),
              ),
          ],
        ),
      ),
    );
  }
}

class NeoLiveBanner extends StatelessWidget {
  final VoidCallback onJoin;
  const NeoLiveBanner({super.key, required this.onJoin});

  @override
  Widget build(BuildContext context) {
    return NeoCard(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      color: AppTheme.rose.withAlpha(30),
      borderColor: AppTheme.rose,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(color: AppTheme.rose, shape: BoxShape.circle),
            child: const Icon(Icons.videocam, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'KELAS SEDANG BERLANGSUNG',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w900, color: AppTheme.rose, letterSpacing: 0.5,
                  ),
                ),
                Text(
                  'Ketuk untuk bergabung',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.rose.withAlpha(200)),
                ),
              ],
            ),
          ),
          NeoButton(
            text: 'GABUNG',
            color: AppTheme.rose,
            onTap: onJoin,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
        ],
      ),
    );
  }
}

class NeoWelcomeBanner extends StatelessWidget {
  final String greeting;
  final String name;
  final String subtitle;

  const NeoWelcomeBanner({
    super.key,
    required this.greeting,
    required this.name,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return NeoCard(
      padding: const EdgeInsets.all(24),
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.primary,
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: Text(
              greeting.toUpperCase(),
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.8,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            name,
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : AppTheme.primary,
              letterSpacing: -0.8, height: 1.1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: isDark ? Colors.white70 : AppTheme.primary.withAlpha(200),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class NeoPillNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final int? badgeCount;

  const NeoPillNavItem({
    super.key,
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.badgeCount,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87);
    final bg = isSelected ? AppTheme.primary : Colors.transparent;
    final border = isSelected ? Theme.of(context).colorScheme.onSurface : Colors.transparent;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          border: Border.all(color: border),
          boxShadow: isSelected ? [BoxShadow(color: border, offset: const Offset(2, 2))] : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 18),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label.toUpperCase(),
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w800, color: color, letterSpacing: 0.5,
                ),
              ),
            ],
            if (badgeCount != null && badgeCount! > 0)
              Container(
                margin: const EdgeInsets.only(left: 4),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(color: AppTheme.rose, borderRadius: BorderRadius.circular(4)),
                child: Text('$badgeCount', style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
              ),
          ],
        ),
      ),
    );
  }
}
