import 'package:flutter/widgets.dart';

import 'split_divider.dart';
import 'split_view_controller.dart';
import 'split_view_theme.dart';
import 'types.dart';

/// A framework-agnostic split view.
class SplitView extends StatefulWidget {
  /// Creates a split view.
  const SplitView({
    super.key,
    required this.direction,
    required this.first,
    required this.second,
    this.reverse = false,
    this.controller,
    this.initialFraction = 0.5,
    this.minFirstPaneSize = 0.0,
    this.maxFirstPaneSize = double.infinity,
    this.minSecondPaneSize = 0.0,
    this.maxSecondPaneSize = double.infinity,
    this.firstCollapsible = false,
    this.secondCollapsible = false,
    this.collapseThreshold,
    this.dividerThickness,
    this.dividerBuilder,
    this.dividerStyle,
    this.dividerSize,
    this.onFractionChanged,
    this.onDragStart,
    this.onDragEnd,
    this.enabled,
    this.resetOnDoubleTap,
    this.deferResize,
    this.shieldPlatformViews,
    this.dragBarrierColor,
    this.animationDuration,
    this.animationCurve,
    this.semanticLabel,
  });

  /// Orientation of the split.
  final SplitDirection direction;

  /// Leading pane. Position depends on [direction], [reverse], and
  /// ambient [Directionality].
  final Widget first;

  /// Trailing pane.
  final Widget second;

  /// Swaps which pane occupies the leading side.
  final bool reverse;

  /// Optional controller. If null, an internal one is created.
  final SplitViewController? controller;

  /// Initial fraction given to [first]. Ignored when [controller] is set.
  final double initialFraction;

  /// Minimum pixel size of the first pane.
  final double minFirstPaneSize;

  /// Maximum pixel size of the first pane.
  final double maxFirstPaneSize;

  /// Minimum pixel size of the second pane.
  final double minSecondPaneSize;

  /// Maximum pixel size of the second pane.
  final double maxSecondPaneSize;

  /// Whether the first pane can collapse to zero size.
  final bool firstCollapsible;

  /// Whether the second pane can collapse to zero size.
  final bool secondCollapsible;

  /// Fraction below which a drag collapses a collapsible pane.
  final double? collapseThreshold;

  /// Hit area thickness of the divider.
  final double? dividerThickness;

  /// Builder for the divider visual.
  final SplitViewDividerBuilder? dividerBuilder;

  /// Divider style when using the default divider.
  final SplitDividerStyle? dividerStyle;

  /// Divider size preset when using the default divider.
  final SplitDividerSize? dividerSize;

  /// Called when the fraction changes.
  final SplitFractionCallback? onFractionChanged;

  /// Called when a drag begins.
  final SplitVoidCallback? onDragStart;

  /// Called when a drag ends.
  final SplitVoidCallback? onDragEnd;

  /// Whether the divider is interactive.
  final bool? enabled;

  /// Whether double-tap resets the split.
  final bool? resetOnDoubleTap;

  /// Whether to defer pane resize during drag. Reserved for v0.2.0.
  final bool? deferResize;

  /// Whether to shield platform views during drag. Reserved for v0.2.0.
  final bool? shieldPlatformViews;

  /// Optional barrier color rendered above panes during drag. Reserved.
  final Color? dragBarrierColor;

  /// Animation duration for programmatic changes. Reserved for v0.2.0.
  final Duration? animationDuration;

  /// Animation curve for programmatic changes. Reserved for v0.2.0.
  final Curve? animationCurve;

  /// Accessibility label override.
  final String? semanticLabel;

  @override
  State<SplitView> createState() => _SplitViewState();
}

class _SplitViewState extends State<SplitView> {
  late SplitViewController _controller;
  bool _ownsController = false;
  bool _isHovered = false;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _attachController();
  }

  @override
  void didUpdateWidget(SplitView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      _detachController();
      _attachController();
    }
  }

  @override
  void dispose() {
    _detachController();
    super.dispose();
  }

  void _attachController() {
    if (widget.controller != null) {
      _controller = widget.controller!;
      _ownsController = false;
    } else {
      _controller = SplitViewController(
        initialFraction: widget.initialFraction,
      );
      _ownsController = true;
    }
  }

  void _detachController() {
    if (_ownsController) {
      _controller.dispose();
    }
  }

  bool _resolveFirstIsLeading(BuildContext context) {
    if (widget.direction == SplitDirection.vertical) {
      return !widget.reverse;
    }
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    return widget.reverse ? isRtl : !isRtl;
  }

  AxisDirection _resolveFirstPaneEdge(
    SplitDirection direction,
    bool firstIsLeading,
    bool isRtl,
  ) {
    if (direction == SplitDirection.vertical) {
      return firstIsLeading ? AxisDirection.down : AxisDirection.up;
    }
    if (firstIsLeading) {
      return isRtl ? AxisDirection.left : AxisDirection.right;
    }
    return isRtl ? AxisDirection.right : AxisDirection.left;
  }

  double _growSign(
    SplitDirection direction,
    bool firstIsLeading,
    bool isRtl,
  ) {
    if (direction == SplitDirection.vertical) {
      return firstIsLeading ? 1.0 : -1.0;
    }
    final isLtr = !isRtl;
    return (firstIsLeading == isLtr) ? 1.0 : -1.0;
  }

  void _onDragStart() {
    _controller.setDragging(true);
    widget.onDragStart?.call();
  }

  void _onDragUpdate(
    DragUpdateDetails details,
    double availableSize,
    double growSign,
    double minFirstFraction,
    double maxFirstFraction,
  ) {
    if (availableSize <= 0) return;
    final delta = widget.direction == SplitDirection.horizontal
        ? details.delta.dx
        : details.delta.dy;
    final fractionDelta = (delta * growSign) / availableSize;
    final newFraction = (_controller.fraction + fractionDelta)
        .clamp(minFirstFraction, maxFirstFraction);
    if (newFraction != _controller.fraction) {
      _controller.setFraction(newFraction);
      widget.onFractionChanged?.call(newFraction);
    }
  }

  void _onDragEnd(
    double minFirstFraction,
    double maxFirstFraction,
    double collapseThreshold,
  ) {
    final fraction = _controller.fraction;
    if (widget.firstCollapsible && fraction < collapseThreshold) {
      _controller.collapseFirst();
      widget.onFractionChanged?.call(0.0);
    } else if (widget.secondCollapsible && fraction > 1.0 - collapseThreshold) {
      _controller.collapseSecond();
      widget.onFractionChanged?.call(1.0);
    }
    _controller.setDragging(false);
    widget.onDragEnd?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = SplitViewTheme.of(context);
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final firstIsLeading = _resolveFirstIsLeading(context);
    final firstPaneEdge =
        _resolveFirstPaneEdge(widget.direction, firstIsLeading, isRtl);
    final growSign = _growSign(widget.direction, firstIsLeading, isRtl);

    final dividerThickness = widget.dividerThickness ?? theme.dividerThickness;
    final enabled = widget.enabled ?? theme.enabled;
    final resetOnDoubleTap = widget.resetOnDoubleTap ?? theme.resetOnDoubleTap;
    final collapseThreshold =
        widget.collapseThreshold ?? theme.collapseThreshold;

    final controller = _controller;

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalSize = widget.direction == SplitDirection.horizontal
            ? constraints.maxWidth
            : constraints.maxHeight;
        final availableSize =
            (totalSize - dividerThickness).clamp(0.0, double.infinity);

        final minFirstFraction =
            (widget.minFirstPaneSize <= 0 || availableSize <= 0)
                ? 0.0
                : (widget.minFirstPaneSize / availableSize).clamp(0.0, 1.0);
        final maxFirstFraction =
            (widget.maxFirstPaneSize >= availableSize || availableSize <= 0)
                ? 1.0
                : (widget.maxFirstPaneSize / availableSize).clamp(0.0, 1.0);

        controller.attach(
          direction: widget.direction,
          reverse: widget.reverse,
          firstPaneEdge: firstPaneEdge,
          availableSize: availableSize,
          dividerThickness: dividerThickness,
        );

        return Semantics(
          label: widget.semanticLabel,
          container: true,
          child: AnimatedBuilder(
            animation: controller,
            builder: (context, _) {
              final fraction = controller.fraction;
              final isDragging = controller.isDragging;

              final dividerState = SplitViewDividerState(
                controller: controller,
                direction: widget.direction,
                firstPaneEdge: firstPaneEdge,
                thickness: dividerThickness,
                isDragging: isDragging,
                isHovered: _isHovered,
                isFocused: _isFocused,
                enabled: enabled,
              );

              final dividerChild =
                  widget.dividerBuilder?.call(context, dividerState) ??
                      SplitDivider(
                        state: dividerState,
                        style: widget.dividerStyle ?? theme.defaultDividerStyle,
                        size: widget.dividerSize ?? theme.defaultDividerSize,
                        hitAreaThickness: dividerThickness,
                        color: theme.defaultDividerColor,
                        hoverColor: theme.defaultDividerHoverColor,
                        dragColor: theme.defaultDividerDragColor,
                        borderRadius: theme.defaultDividerBorderRadius,
                        boxShadow: theme.defaultDividerBoxShadow,
                      );

              return CustomMultiChildLayout(
                delegate: _SplitLayoutDelegate(
                  direction: widget.direction,
                  fraction: fraction,
                  dividerThickness: dividerThickness,
                  firstIsLeading: firstIsLeading,
                  minFirstSize: widget.minFirstPaneSize,
                  maxFirstSize: widget.maxFirstPaneSize,
                  minSecondSize: widget.minSecondPaneSize,
                  maxSecondSize: widget.maxSecondPaneSize,
                ),
                children: [
                  LayoutId(id: SplitViewSlot.first, child: widget.first),
                  LayoutId(
                    id: SplitViewSlot.divider,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onHorizontalDragStart:
                          widget.direction == SplitDirection.horizontal &&
                                  enabled
                              ? (_) => _onDragStart()
                              : null,
                      onHorizontalDragUpdate:
                          widget.direction == SplitDirection.horizontal &&
                                  enabled
                              ? (d) => _onDragUpdate(
                                    d,
                                    availableSize,
                                    growSign,
                                    minFirstFraction,
                                    maxFirstFraction,
                                  )
                              : null,
                      onHorizontalDragEnd:
                          widget.direction == SplitDirection.horizontal &&
                                  enabled
                              ? (_) => _onDragEnd(
                                    minFirstFraction,
                                    maxFirstFraction,
                                    collapseThreshold,
                                  )
                              : null,
                      onVerticalDragStart:
                          widget.direction == SplitDirection.vertical && enabled
                              ? (_) => _onDragStart()
                              : null,
                      onVerticalDragUpdate:
                          widget.direction == SplitDirection.vertical && enabled
                              ? (d) => _onDragUpdate(
                                    d,
                                    availableSize,
                                    growSign,
                                    minFirstFraction,
                                    maxFirstFraction,
                                  )
                              : null,
                      onVerticalDragEnd:
                          widget.direction == SplitDirection.vertical && enabled
                              ? (_) => _onDragEnd(
                                    minFirstFraction,
                                    maxFirstFraction,
                                    collapseThreshold,
                                  )
                              : null,
                      onDoubleTap: resetOnDoubleTap && enabled
                          ? () => controller.reset()
                          : null,
                      child: MouseRegion(
                        cursor: enabled
                            ? (widget.direction == SplitDirection.horizontal
                                ? SystemMouseCursors.resizeColumn
                                : SystemMouseCursors.resizeRow)
                            : MouseCursor.defer,
                        onEnter: enabled
                            ? (_) => setState(() => _isHovered = true)
                            : null,
                        onExit: enabled
                            ? (_) => setState(() => _isHovered = false)
                            : null,
                        child: Focus(
                          onFocusChange: (v) => setState(() => _isFocused = v),
                          child: dividerChild,
                        ),
                      ),
                    ),
                  ),
                  LayoutId(id: SplitViewSlot.second, child: widget.second),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

class _SplitLayoutDelegate extends MultiChildLayoutDelegate {
  _SplitLayoutDelegate({
    required this.direction,
    required this.fraction,
    required this.dividerThickness,
    required this.firstIsLeading,
    required this.minFirstSize,
    required this.maxFirstSize,
    required this.minSecondSize,
    required this.maxSecondSize,
  });

  final SplitDirection direction;
  final double fraction;
  final double dividerThickness;
  final bool firstIsLeading;
  final double minFirstSize;
  final double maxFirstSize;
  final double minSecondSize;
  final double maxSecondSize;

  @override
  void performLayout(Size size) {
    final isHorizontal = direction == SplitDirection.horizontal;
    final totalSize = isHorizontal ? size.width : size.height;
    final crossSize = isHorizontal ? size.height : size.width;
    final availableSize =
        (totalSize - dividerThickness).clamp(0.0, double.infinity);

    double firstSize = availableSize * fraction;
    double secondSize = availableSize - firstSize;

    if (firstSize < minFirstSize) firstSize = minFirstSize;
    if (firstSize > maxFirstSize) firstSize = maxFirstSize;
    if (firstSize > availableSize) firstSize = availableSize;
    secondSize = availableSize - firstSize;
    if (secondSize < minSecondSize) {
      secondSize = minSecondSize;
      firstSize = availableSize - secondSize;
    }
    if (secondSize > maxSecondSize) {
      secondSize = maxSecondSize;
      firstSize = availableSize - secondSize;
    }
    firstSize = firstSize.clamp(0.0, availableSize);
    secondSize = secondSize.clamp(0.0, availableSize);

    final firstConstraints = isHorizontal
        ? BoxConstraints.tightFor(width: firstSize, height: crossSize)
        : BoxConstraints.tightFor(width: crossSize, height: firstSize);
    final secondConstraints = isHorizontal
        ? BoxConstraints.tightFor(width: secondSize, height: crossSize)
        : BoxConstraints.tightFor(width: crossSize, height: secondSize);
    final dividerConstraints = isHorizontal
        ? BoxConstraints.tightFor(width: dividerThickness, height: crossSize)
        : BoxConstraints.tightFor(width: crossSize, height: dividerThickness);

    layoutChild(SplitViewSlot.first, firstConstraints);
    layoutChild(SplitViewSlot.divider, dividerConstraints);
    layoutChild(SplitViewSlot.second, secondConstraints);

    final double firstPos;
    final double dividerPos;
    final double secondPos;

    if (firstIsLeading) {
      firstPos = 0;
      dividerPos = firstSize;
      secondPos = firstSize + dividerThickness;
    } else {
      secondPos = 0;
      dividerPos = secondSize;
      firstPos = secondSize + dividerThickness;
    }

    if (isHorizontal) {
      positionChild(SplitViewSlot.first, Offset(firstPos, 0));
      positionChild(SplitViewSlot.divider, Offset(dividerPos, 0));
      positionChild(SplitViewSlot.second, Offset(secondPos, 0));
    } else {
      positionChild(SplitViewSlot.first, Offset(0, firstPos));
      positionChild(SplitViewSlot.divider, Offset(0, dividerPos));
      positionChild(SplitViewSlot.second, Offset(0, secondPos));
    }
  }

  @override
  bool shouldRelayout(_SplitLayoutDelegate oldDelegate) {
    return oldDelegate.direction != direction ||
        oldDelegate.fraction != fraction ||
        oldDelegate.dividerThickness != dividerThickness ||
        oldDelegate.firstIsLeading != firstIsLeading ||
        oldDelegate.minFirstSize != minFirstSize ||
        oldDelegate.maxFirstSize != maxFirstSize ||
        oldDelegate.minSecondSize != minSecondSize ||
        oldDelegate.maxSecondSize != maxSecondSize;
  }
}
