import 'dart:math' as math;

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
    this.shieldColor,
    this.transitionDuration,
    this.transitionCurve,
    this.semanticLabel,
    this.isolatePanes = false,
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

  /// Whether to wrap the panes and divider in RepaintBoundary widgets.
  ///
  /// Enabling this isolates repaints when pane content is complex.
  /// However, in deeply nested SplitView trees (like IDEs), enabling
  /// this can cause a "layer explosion," increasing GPU overhead.
  final bool isolatePanes;

  /// v0.2.0
  ///  When true, panes freeze during drag and snap on release.
  ///
  /// The divider continues to move at the display's frame rate. Pane
  /// content is not laid out until the drag ends, which avoids the cost
  /// of rebuilding expensive subtrees (WebViews, MapViews, charts) on
  /// every frame.
  final bool? deferResize;

  /// v0.2.0
  ///  When true, an invisible [AbsorbPointer] sits above the
  /// panes during a drag.
  ///
  /// This prevents embedded platform views (WebView, MapView, video
  /// players) from stealing pointer events mid-drag. The shield is only
  /// present in the layout tree while a drag is in progress.
  final bool? shieldPlatformViews;

  /// v0.2.0
  ///  Tint color of the shield barrier.
  ///
  /// Null (the default) renders an invisible barrier that still absorbs
  /// pointer events. A non-null value paints the barrier with that
  /// color, useful for signalling to the user that a drag is in
  /// progress.
  final Color? shieldColor;

  /// v0.2.0
  ///  Duration of programmatic transitions.
  ///
  /// Used by `setFraction(animate: true)`, `collapseFirst(animate: true)`,
  /// `toggleFirst(animate: true)`, `reset(animate: true)`, and
  /// double-tap-to-reset. Null → theme default.
  final Duration? transitionDuration;

  /// v0.2.0
  ///  Curve of programmatic transitions.
  ///
  /// Pairs with [transitionDuration]. Null → theme default.
  final Curve? transitionCurve;

  /// Accessibility label override.
  final String? semanticLabel;

  @override
  State<SplitView> createState() => _SplitViewState();
}

class _SplitViewState extends State<SplitView>
    with SingleTickerProviderStateMixin {
  late SplitViewController _controller;
  bool _ownsController = false;
  bool _isHovered = false;
  bool _isFocused = false;

  // v0.2.0
  // Deferred resize: frozen pane fraction during drag.
  double _appliedFraction = 0.5;

  // v0.2.0
  // Animation controller for programmatic changes.
  late final AnimationController _animController;
  Animation<double>? _fractionAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this)
      ..addListener(_onAnimTick)
      ..addStatusListener(_onAnimStatus);
    _attachController();
    _appliedFraction = _controller.fraction;
  }

  @override
  void didUpdateWidget(SplitView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      _detachController();
      _attachController();
      _appliedFraction = _controller.fraction;
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    _detachController();
    super.dispose();
  }

  void _onAnimTick() {
    final anim = _fractionAnim;
    if (anim == null) return;
    _controller.setFraction(anim.value);
  }

  void _onAnimStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      widget.onFractionChanged?.call(_controller.fraction);
    }
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
    // v0.2.0
    // route controller animate:true calls through our animator.
    _controller.animationDelegate = (target, duration, curve) {
      _animateTo(target: target, duration: duration, curve: curve);
    };
  }

  void _detachController() {
    _controller.animationDelegate = null;
    if (_ownsController) {
      _controller.dispose();
    }
  }

  void _animateTo({
    required double target,
    required Duration duration,
    required Curve curve,
  }) {
    _animController.stop();
    final start = _controller.fraction;
    _fractionAnim = Tween<double>(begin: start, end: target).animate(
      CurvedAnimation(parent: _animController, curve: curve),
    );
    _animController
      ..duration = duration
      ..forward(from: 0);
  }

  //  Direction resolution (unchanged from v0.1.x)

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
    return firstIsLeading ? 1.0 : -1.0;
  }

  // v0.2.0
  // Returns the fraction panes should currently be laid out at.
  double _effectiveAppliedFraction({required bool deferring}) {
    if (deferring && _controller.isDragging) {
      return _appliedFraction;
    }
    return _controller.fraction;
  }

  //  Gesture handling

  void _onDragStart({required bool deferring}) {
    _animController.stop(); // v0.2.0 — cancel any in-flight animation
    if (deferring) {
      _appliedFraction =
          _controller.fraction; // v0.2.0 — freeze panes (if true)
    }
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

  void _onDragEnd(double collapseThreshold) {
    final fraction = _controller.fraction;
    if (widget.firstCollapsible && fraction < collapseThreshold) {
      _controller.collapseFirst(animate: false);
      widget.onFractionChanged?.call(0.0);
    } else if (widget.secondCollapsible && fraction > 1.0 - collapseThreshold) {
      _controller.collapseSecond(animate: false);
      widget.onFractionChanged?.call(1.0);
    }
    _controller.setDragging(false);
    widget.onDragEnd?.call();
  }

  //
  Widget _wrapIfIsolated(Widget child) {
    return widget.isolatePanes ? RepaintBoundary(child: child) : child;
  }

  //  Build

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

    // v0.2.0
    // resolve the five new features from widget or theme.
    final deferring = widget.deferResize ?? theme.deferResize;
    final shielding = widget.shieldPlatformViews ?? theme.shieldPlatformViews;
    final shieldColor = widget.shieldColor ?? theme.shieldColor;
    final transitionDuration =
        widget.transitionDuration ?? theme.transitionDuration;
    final transitionCurve = widget.transitionCurve ?? theme.transitionCurve;

    final controller = _controller;

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalSize = widget.direction == SplitDirection.horizontal
            ? constraints.maxWidth
            : constraints.maxHeight;
        final availableSize =
            (totalSize - dividerThickness).clamp(0.0, double.infinity);

        // final minFirstFraction =
        //     (widget.minFirstPaneSize <= 0 || availableSize <= 0)
        //         ? 0.0
        //         : (widget.minFirstPaneSize / availableSize).clamp(0.0, 1.0);
        // final maxFirstFraction =
        //     (widget.maxFirstPaneSize >= availableSize || availableSize <= 0)
        //         ? 1.0
        //         : (widget.maxFirstPaneSize / availableSize).clamp(0.0, 1.0);

        double minFirstFraction = 0.0;
        double maxFirstFraction = 1.0;

        if (availableSize > 0) {
          // Constraints from the first pane
          if (widget.minFirstPaneSize > 0) {
            minFirstFraction = math.max(
              minFirstFraction,
              widget.minFirstPaneSize / availableSize,
            );
          }
          if (widget.maxFirstPaneSize < availableSize) {
            maxFirstFraction = math.min(
              maxFirstFraction,
              widget.maxFirstPaneSize / availableSize,
            );
          }

          // Constraints from the second pane
          if (widget.minSecondPaneSize > 0) {
            maxFirstFraction = math.min(
              maxFirstFraction,
              1.0 - (widget.minSecondPaneSize / availableSize),
            );
          }
          if (widget.maxSecondPaneSize < availableSize) {
            minFirstFraction = math.max(
              minFirstFraction,
              1.0 - (widget.maxSecondPaneSize / availableSize),
            );
          }
        }

        minFirstFraction = minFirstFraction.clamp(0.0, 1.0);
        maxFirstFraction = maxFirstFraction.clamp(0.0, 1.0);

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
              final visualFraction = controller.fraction;
              final appliedFraction =
                  _effectiveAppliedFraction(deferring: deferring);
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

              // v0.2.0 - assemble children. The shield slot is only
              // present while a shielded drag is active.
              final children = <Widget>[
                LayoutId(
                  id: SplitViewSlot.first,
                  child: _wrapIfIsolated(widget.first),
                ),
                LayoutId(
                  id: SplitViewSlot.divider,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onHorizontalDragStart:
                        widget.direction == SplitDirection.horizontal && enabled
                            ? (_) => _onDragStart(deferring: deferring)
                            : null,
                    onHorizontalDragUpdate:
                        widget.direction == SplitDirection.horizontal && enabled
                            ? (d) => _onDragUpdate(
                                  d,
                                  availableSize,
                                  growSign,
                                  minFirstFraction,
                                  maxFirstFraction,
                                )
                            : null,
                    onHorizontalDragEnd:
                        widget.direction == SplitDirection.horizontal && enabled
                            ? (_) => _onDragEnd(collapseThreshold)
                            : null,
                    onVerticalDragStart:
                        widget.direction == SplitDirection.vertical && enabled
                            ? (_) => _onDragStart(deferring: deferring)
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
                            ? (_) => _onDragEnd(collapseThreshold)
                            : null,
                    onDoubleTap: resetOnDoubleTap && enabled
                        ? () => _animateTo(
                              target: controller.initialFraction,
                              duration: transitionDuration,
                              curve: transitionCurve,
                            )
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
                LayoutId(
                  id: SplitViewSlot.second,
                  child: _wrapIfIsolated(widget.second),
                ),

                // v0.2.0
                // platform-view shield, only during shielded drags.
                if (shielding && isDragging)
                  LayoutId(
                    id: SplitViewSlot.shield,
                    child: _wrapIfIsolated(
                      AbsorbPointer(
                        child: shieldColor != null
                            ? ColoredBox(color: shieldColor)
                            : const SizedBox.expand(),
                      ),
                    ),
                  ),
              ];

              return CustomMultiChildLayout(
                delegate: _SplitLayoutDelegate(
                  direction: widget.direction,
                  visualFraction: visualFraction, // v0.2.0
                  appliedFraction: appliedFraction, // v0.2.0
                  dividerThickness: dividerThickness,
                  firstIsLeading: firstIsLeading,
                  minFirstSize: widget.minFirstPaneSize,
                  maxFirstSize: widget.maxFirstPaneSize,
                  minSecondSize: widget.minSecondPaneSize,
                  maxSecondSize: widget.maxSecondPaneSize,
                ),
                children: children,
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
    required this.visualFraction,
    required this.appliedFraction,
    required this.dividerThickness,
    required this.firstIsLeading,
    required this.minFirstSize,
    required this.maxFirstSize,
    required this.minSecondSize,
    required this.maxSecondSize,
  });

  final SplitDirection direction;
  final double visualFraction;
  final double appliedFraction;
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

    // // Calculate base sizes from applied fraction
    // double firstSize = availableSize * appliedFraction;
    // double secondSize = availableSize - firstSize;

    // //  Check for explicit collapse (fraction is effectively 0 or 1)
    // final bool isFirstCollapsed = appliedFraction <= 0.0001;
    // final bool isSecondCollapsed = appliedFraction >= 0.9999;

    // //  Apply min/max constraints ONLY if the pane is NOT explicitly collapsed
    // if (!isFirstCollapsed && firstSize < minFirstSize) {
    //   firstSize = minFirstSize;
    // }
    // if (!isFirstCollapsed && firstSize > maxFirstSize) {
    //   firstSize = maxFirstSize;
    // }

    // // Recalculate second size based on adjusted first size
    // secondSize = availableSize - firstSize;

    // if (!isSecondCollapsed && secondSize < minSecondSize) {
    //   secondSize = minSecondSize;
    //   firstSize = availableSize - secondSize;
    // }
    // if (!isSecondCollapsed && secondSize > maxSecondSize) {
    //   secondSize = maxSecondSize;
    //   firstSize = availableSize - secondSize;
    // }

    // // Final hard clamp to ensure no negative sizes or overflow
    // firstSize = firstSize.clamp(0.0, availableSize);
    // secondSize = secondSize.clamp(0.0, availableSize);

    // Calculate base sizes from applied fraction
    double firstSize = availableSize * appliedFraction;
    double secondSize = availableSize - firstSize;

    //  Check for explicit collapse (fraction is effectively 0 or 1)
    final bool isFirstCollapsed = appliedFraction <= 0.0001;
    final bool isSecondCollapsed = appliedFraction >= 0.9999;

    if (isFirstCollapsed) {
      firstSize = 0.0;
      secondSize = availableSize;
    } else if (isSecondCollapsed) {
      firstSize = availableSize;
      secondSize = 0.0;
    } else {
      //  Apply min/max constraints ONLY if NEITHER pane is explicitly collapsed
      if (firstSize < minFirstSize) {
        firstSize = minFirstSize;
      }
      if (firstSize > maxFirstSize) {
        firstSize = maxFirstSize;
      }

      // Recalculate second size based on adjusted first size
      secondSize = availableSize - firstSize;

      if (secondSize < minSecondSize) {
        secondSize = minSecondSize;
        firstSize = availableSize - secondSize;
      }
      if (secondSize > maxSecondSize) {
        secondSize = maxSecondSize;
        firstSize = availableSize - secondSize;
      }
    }

    // Final hard clamp to ensure no negative sizes or overflow
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

    final double firstPanePos;
    final double secondPanePos;
    if (firstIsLeading) {
      firstPanePos = 0;
      secondPanePos = firstSize + dividerThickness;
    } else {
      secondPanePos = 0;
      firstPanePos = secondSize + dividerThickness;
    }

    // Divider position is always based on visualFraction (so it moves smoothly during deferResize)
    final visualFirstSize = availableSize * visualFraction;
    final dividerPos =
        firstIsLeading ? visualFirstSize : availableSize - visualFirstSize;

    if (isHorizontal) {
      positionChild(SplitViewSlot.first, Offset(firstPanePos, 0));
      positionChild(SplitViewSlot.divider, Offset(dividerPos, 0));
      positionChild(SplitViewSlot.second, Offset(secondPanePos, 0));
    } else {
      positionChild(SplitViewSlot.first, Offset(0, firstPanePos));
      positionChild(SplitViewSlot.divider, Offset(0, dividerPos));
      positionChild(SplitViewSlot.second, Offset(0, secondPanePos));
    }

    if (hasChild(SplitViewSlot.shield)) {
      layoutChild(
        SplitViewSlot.shield,
        BoxConstraints.tightFor(width: size.width, height: size.height),
      );
      positionChild(SplitViewSlot.shield, Offset.zero);
    }
  }

  @override
  bool shouldRelayout(_SplitLayoutDelegate oldDelegate) {
    return oldDelegate.direction != direction ||
        oldDelegate.visualFraction != visualFraction ||
        oldDelegate.appliedFraction != appliedFraction ||
        oldDelegate.dividerThickness != dividerThickness ||
        oldDelegate.firstIsLeading != firstIsLeading ||
        oldDelegate.minFirstSize != minFirstSize ||
        oldDelegate.maxFirstSize != maxFirstSize ||
        oldDelegate.minSecondSize != minSecondSize ||
        oldDelegate.maxSecondSize != maxSecondSize;
  }
}
