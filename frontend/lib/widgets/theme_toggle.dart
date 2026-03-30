import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/theme_provider.dart';

class ThemeToggle extends StatelessWidget {
  final Color iconColor;

  const ThemeToggle({super.key, required this.iconColor});

  @override
  Widget build(BuildContext context) {
    // Determine the active brightness from the framework
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Smooth custom rotation/fade transition
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return RotationTransition(
          turns: child.key == const ValueKey('icon_dark')
              ? Tween<double>(begin: 0.5, end: 1.0).animate(animation)
              : Tween<double>(begin: 0.5, end: 1.0).animate(animation),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      child: IconButton(
        // Key is vital for AnimatedSwitcher to know the widget changed
        key: isDark ? const ValueKey('icon_dark') : const ValueKey('icon_light'),
        icon: Icon(
          isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
          color: iconColor,
        ),
        tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
        onPressed: () {
          ThemeProvider().toggleTheme(isDark);
        },
      ),
    ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.8, 0.8));
  }
}
