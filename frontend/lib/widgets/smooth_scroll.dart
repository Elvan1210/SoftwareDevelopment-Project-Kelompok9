import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// A wrapper that transforms discrete mouse wheel ticks into smooth animations.
/// This addresses the "jumpy" scrolling feel on Windows/Desktop.
class SmoothScrollWrapper extends StatelessWidget {
  final Widget child;
  final double scrollSpeed;
  final Duration animationDuration;
  final Curve curve;

  const SmoothScrollWrapper({
    super.key,
    required this.child,
    this.scrollSpeed = 1.0,
    this.animationDuration = const Duration(milliseconds: 300),
    this.curve = Curves.easeOutQuart,
  });

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerSignal: (pointerSignal) {
        if (pointerSignal is PointerScrollEvent) {
          final scrollController = _findScrollController(context);
          if (scrollController != null && scrollController.hasClients) {
            final double delta = pointerSignal.scrollDelta.dy * scrollSpeed;
            final double newOffset = (scrollController.offset + delta)
                .clamp(0.0, scrollController.position.maxScrollExtent);

            scrollController.animateTo(
              newOffset,
              duration: animationDuration,
              curve: curve,
            );
          }
        }
      },
      child: child,
    );
  }

  /// Finds the nearest ScrollController. 
  /// Usually the PrimaryScrollController provided by the AppShell or Scaffold.
  ScrollController? _findScrollController(BuildContext context) {
    return PrimaryScrollController.of(context);
  }
}

/// Custom ScrollBehavior to enable refined scroll physics without drag-to-scroll.
class AppScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.trackpad,
        // Mouse is explicitly OMITTED here per user request "no need drag to scroll"
      };

  @override
  Widget buildScrollbar(BuildContext context, Widget child, ScrollableDetails details) {
    // Keep standard scrollbar behavior
    return super.buildScrollbar(context, child, details);
  }
}

