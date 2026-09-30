import 'package:flutter/widgets.dart';

import 'split_view_controller.dart';
import 'split_view_theme.dart';
import 'types.dart';

/// Immutable state passed to a divider builder.
class SplitViewDividerState {
  /// Creates a divider state.
  const SplitViewDividerState({
    required this.controller,
    required this.direction,
    required this.firstPaneEdge,
    required this.thickness,
    required this.isDragging,
    required this.isHovered,
    required this.isFocused,
    required this.enabled,
  });

  /// The parent controller.
  final SplitViewController controller;

  /// The resolved direction.
  final SplitDirection direction;

  /// Direction from the first pane toward the divider.
  final AxisDirection firstPaneEdge;

  /// The parent's divider thickness (hit area).
  final double thickness;

  /// Whether the divider is currently being dragged.
  final bool isDragging;

  /// Whether the pointer is hovering over the divider.
  final bool isHovered;

  /// Whether the divider has keyboard focus.
  final bool isFocused;

  /// Whether the parent is enabled.
  final bool enabled;

  /// Whether the divider is vertical on screen (horizontal split).
  bool get isVerticalDivider => direction == SplitDirection.horizontal;

  /// Whether the divider is horizontal on screen (vertical split).
  bool get isHorizontalDivider => direction == SplitDirection.vertical;
}

/// A neutral divider visual, styled by [SplitDividerStyle] and
/// [SplitDividerSize].
class SplitDivider extends StatelessWidget {
  /// Creates a divider visual.
  const SplitDivider({
    super.key,
    required this.state,
    this.style = SplitDividerStyle.line,
    this.size = SplitDividerSize.medium,
    this.hitAreaThickness,
    this.lineThickness,
    this.color,
    this.hoverColor,
    this.dragColor,
    this.focusColor,
    this.borderRadius,
    this.border,
    this.boxShadow,
    this.handleBuilder,
    this.cursor,
    this.animationDuration = const Duration(milliseconds: 150),
    this.animationCurve = Curves.easeOut,
  });

  /// The divider state from the parent builder.
  final SplitViewDividerState state;

  /// Visual style.
  final SplitDividerStyle style;

  /// Size preset.
  final SplitDividerSize size;

  /// Hit area thickness override (used when [size] is
  /// [SplitDividerSize.custom]).
  final double? hitAreaThickness;

  /// Visual thickness override (used when [size] is
  /// [SplitDividerSize.custom]).
  final double? lineThickness;

  /// Idle color.
  final Color? color;

  /// Hover color.
  final Color? hoverColor;

  /// Drag color.
  final Color? dragColor;

  /// Focus color.
  final Color? focusColor;

  /// Border radius of the visual.
  final BorderRadius? borderRadius;

  /// Border of the visual.
  final BoxBorder? border;

  /// Box shadow of the visual.
  final List<BoxShadow>? boxShadow;

  /// Optional handle overlay.
  final WidgetBuilder? handleBuilder;

  /// Mouse cursor. Defaults based on direction.
  final MouseCursor? cursor;

  /// Hover/drag transition duration.
  final Duration animationDuration;

  /// Hover/drag transition curve.
  final Curve animationCurve;

  @override
  Widget build(BuildContext context) {
    if (style == SplitDividerStyle.none) {
      return const SizedBox.shrink();
    }

    final theme = SplitViewTheme.of(context);
    final resolvedLineThickness = _resolveLineThickness();
    final resolvedColor = _resolveColor(theme);
    final resolvedRadius = borderRadius ?? _defaultRadius();
    final resolvedBorder = border ?? _defaultBorder();
    final resolvedShadow = boxShadow ?? _defaultShadow();

    final isHorizontal = state.direction == SplitDirection.horizontal;

    final visual = AnimatedContainer(
      duration: animationDuration,
      curve: animationCurve,
      width: isHorizontal ? resolvedLineThickness : double.infinity,
      height: isHorizontal ? double.infinity : resolvedLineThickness,
      decoration: BoxDecoration(
        color: resolvedColor,
        borderRadius: resolvedRadius,
        border: resolvedBorder,
        boxShadow: resolvedShadow,
      ),
    );

    final withHandle = handleBuilder != null
        ? Stack(
            alignment: Alignment.center,
            children: [
              visual,
              handleBuilder!(context),
            ],
          )
        : visual;

    return MouseRegion(
      cursor: cursor ??
          (isHorizontal
              ? SystemMouseCursors.resizeColumn
              : SystemMouseCursors.resizeRow),
      child: Center(child: withHandle),
    );
  }

  double _resolveLineThickness() {
    if (size == SplitDividerSize.custom) {
      return lineThickness ?? 2.0;
    }
    switch (size) {
      case SplitDividerSize.small:
        return 1.0;
      case SplitDividerSize.medium:
        return 2.0;
      case SplitDividerSize.large:
        return 4.0;
      case SplitDividerSize.custom:
        return lineThickness ?? 2.0;
    }
  }

  Color? _resolveColor(SplitViewTheme theme) {
    if (style == SplitDividerStyle.bordered) return null;
    if (state.isDragging && dragColor != null) return dragColor;
    if (state.isHovered && hoverColor != null) return hoverColor;
    if (state.isFocused && focusColor != null) return focusColor;
    return color ?? theme.defaultDividerColor;
  }

  BorderRadius? _defaultRadius() {
    if (style == SplitDividerStyle.rounded ||
        style == SplitDividerStyle.floating ||
        style == SplitDividerStyle.bordered) {
      return const BorderRadius.all(Radius.circular(2));
    }
    return null;
  }

  BoxBorder? _defaultBorder() {
    if (style == SplitDividerStyle.bordered) {
      return Border.all(color: const Color(0x33000000));
    }
    return null;
  }

  List<BoxShadow>? _defaultShadow() {
    if (style == SplitDividerStyle.floating) {
      return const [
        BoxShadow(
          color: Color(0x33000000),
          blurRadius: 4,
          offset: Offset(0, 2),
        ),
      ];
    }
    return null;
  }
}
