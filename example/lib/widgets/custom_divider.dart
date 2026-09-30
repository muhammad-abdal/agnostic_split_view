import 'package:agnostic_split_view/agnostic_split_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomDivider extends StatefulWidget {
  const CustomDivider({
    super.key,
    required this.state,
    this.accent = const Color(0xFFC8FF00),
    this.enableHaptics = true,
  });

  /// State provided by [SplitView]'s divider builder.
  final SplitViewDividerState state;

  /// Accent color for the grip, glow, and drag track.
  final Color accent;

  /// Whether to fire haptics on drag start/end.
  final bool enableHaptics;

  @override
  State<CustomDivider> createState() => _CustomDividerState();
}

class _CustomDividerState extends State<CustomDivider> {
  @override
  void didUpdateWidget(covariant CustomDivider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.enableHaptics) return;
    final was = oldWidget.state.isDragging;
    final isNow = widget.state.isDragging;
    if (!was && isNow) {
      HapticFeedback.selectionClick();
    } else if (was && !isNow) {
      HapticFeedback.lightImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    final accent = widget.accent;
    final isVertical = s.isVerticalDivider;
    final active = s.isHovered || s.isDragging || s.isFocused;

    // Grip size — grows through idle → hover → drag.
    final gripCross = s.isDragging ? 10.0 : (active ? 8.0 : 4.0);
    final gripMain = s.isDragging ? 34.0 : (active ? 26.0 : 14.0);
    final gripWidth = isVertical ? gripCross : gripMain;
    final gripHeight = isVertical ? gripMain : gripCross;

    // Full-length track: hidden when idle-hovered, accent on drag.
    final trackColor = s.isDragging
        ? accent.withValues(alpha: 0.45)
        : Colors.white.withValues(alpha: active ? 0.0 : 0.06);

    // Centered pill.
    final pillColor = accent.withValues(
      alpha: s.isDragging ? 0.22 : (active ? 0.14 : 0.06),
    );
    final borderColor = accent.withValues(
      alpha: s.isDragging ? 0.6 : (active ? 0.35 : 0.08),
    );

    // Glow.
    final glowAlpha =
        s.isDragging ? 0.5 : (s.isHovered ? 0.22 : (s.isFocused ? 0.30 : 0.0));

    const duration = Duration(milliseconds: 180);
    const curve = Curves.easeOutCubic;

    return Stack(
      fit: StackFit.expand,
      alignment: Alignment.center,
      children: [
        // ─── Layer 1: full-length track ───────────────────────────────
        Center(
          child: AnimatedContainer(
            duration: duration,
            curve: curve,
            width: isVertical ? 1.5 : double.infinity,
            height: isVertical ? double.infinity : 1.5,
            decoration: BoxDecoration(
              color: trackColor,
              boxShadow: s.isDragging
                  ? [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.35),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
          ),
        ),

        // ─── Layer 2: centered grip pill ──────────────────────────────
        Center(
          child: AnimatedContainer(
            duration: duration,
            curve: curve,
            width: gripWidth,
            height: gripHeight,
            decoration: BoxDecoration(
              color: pillColor,
              borderRadius: BorderRadius.circular(99),
              border: Border.all(color: borderColor, width: 0.8),
              boxShadow: glowAlpha > 0
                  ? [
                      BoxShadow(
                        color: accent.withValues(alpha: glowAlpha),
                        blurRadius: s.isDragging ? 20 : 12,
                        spreadRadius: s.isDragging ? 1.5 : 0.0,
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: _GripDots(
                isVertical: isVertical,
                color: accent,
                active: active,
                dragging: s.isDragging,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _GripDots extends StatelessWidget {
  const _GripDots({
    required this.isVertical,
    required this.color,
    required this.active,
    required this.dragging,
  });

  final bool isVertical;
  final Color color;
  final bool active;
  final bool dragging;

  @override
  Widget build(BuildContext context) {
    const dotSize = 2.2;
    final opacity = dragging ? 1.0 : (active ? 0.9 : 0.35);

    final dot = Container(
      width: dotSize,
      height: dotSize,
      decoration: BoxDecoration(
        color: color.withValues(alpha: opacity),
        shape: BoxShape.circle,
      ),
    );

    if (isVertical) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          dot,
          const SizedBox(height: 2.5),
          dot,
          const SizedBox(height: 2.5),
          dot,
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        dot,
        const SizedBox(width: 2.5),
        dot,
        const SizedBox(width: 2.5),
        dot,
      ],
    );
  }
}
