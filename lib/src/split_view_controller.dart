import 'package:flutter/widgets.dart';

import 'types.dart';

class _AttachedGeometry {
  const _AttachedGeometry({
    required this.direction,
    required this.reverse,
    required this.firstPaneEdge,
    required this.availableSize,
    required this.dividerThickness,
  });

  final SplitDirection direction;
  final bool reverse;
  final AxisDirection firstPaneEdge;
  final double availableSize;
  final double dividerThickness;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _AttachedGeometry &&
          direction == other.direction &&
          reverse == other.reverse &&
          firstPaneEdge == other.firstPaneEdge &&
          availableSize == other.availableSize &&
          dividerThickness == other.dividerThickness;

  @override
  int get hashCode => Object.hash(
        direction,
        reverse,
        firstPaneEdge,
        availableSize,
        dividerThickness,
      );
}

/// Controls the state of a [SplitView].
///
/// Can be created externally and reused across widget rebuilds, including
/// across orientation changes (the [fraction] is preserved).
class SplitViewController extends ChangeNotifier {
  /// Creates a controller with an [initialFraction].
  ///
  /// [initialFraction] is clamped to `[0.0, 1.0]`.
  SplitViewController({double initialFraction = 0.5})
      : _fraction = initialFraction.clamp(0.0, 1.0),
        _initialFraction = initialFraction.clamp(0.0, 1.0),
        _lastExpandedFraction = initialFraction.clamp(0.0, 1.0);

  final double _initialFraction;

  double _fraction;
  double _lastExpandedFraction;
  bool _isDragging = false;

  _AttachedGeometry? _geometry;

  // ─── Read-only state ────────────────────────────────────────────────────

  /// Fraction of available space allocated to the first pane.
  double get fraction => _fraction;

  /// Whether a drag is in progress.
  bool get isDragging => _isDragging;

  /// Whether the first pane is collapsed to zero size.
  bool get isFirstCollapsed => _fraction <= 0.0001;

  /// Whether the second pane is collapsed to zero size.
  bool get isSecondCollapsed => _fraction >= 0.9999;

  /// Pixel size of the first pane. `0` until attached and laid out.
  double get firstPaneSize {
    final g = _geometry;
    if (g == null) return 0;
    return g.availableSize * _fraction;
  }

  /// Pixel size of the second pane. `0` until attached and laid out.
  double get secondPaneSize {
    final g = _geometry;
    if (g == null) return 0;
    return g.availableSize * (1.0 - _fraction);
  }

  /// Total available size along the split axis. `0` until attached.
  double get availableSize => _geometry?.availableSize ?? 0;

  /// The attached orientation. `null` until attached.
  SplitDirection? get direction => _geometry?.direction;

  /// The attached `reverse` flag. `null` until attached.
  bool? get reverse => _geometry?.reverse;

  /// Direction from the first pane toward the divider. `null` until attached.
  AxisDirection? get firstPaneEdge => _geometry?.firstPaneEdge;

  // ─── Commands ───────────────────────────────────────────────────────────

  /// Sets the fraction allocated to the first pane.
  ///
  /// Clamped to `[0.0, 1.0]`. If the resulting fraction is strictly between
  /// 0 and 1, it is remembered as the last expanded fraction used by
  /// [expandFirst] and [expandSecond].
  ///
  /// The [animate] argument is reserved for v0.2.0 and currently has no
  /// effect.
  void setFraction(double value, {bool animate = false}) {
    final clamped = value.clamp(0.0, 1.0);
    if (clamped == _fraction) return;
    if (clamped > 0.0001 && clamped < 0.9999) {
      _lastExpandedFraction = clamped;
    }
    _fraction = clamped;
    notifyListeners();
  }

  /// Sets the pixel size of the first pane.
  void setFirstPaneSize(double pixels, {bool animate = false}) {
    final g = _geometry;
    if (g == null || g.availableSize <= 0) return;
    setFraction(pixels / g.availableSize, animate: animate);
  }

  /// Collapses the first pane.
  void collapseFirst({bool animate = true}) {
    if (_fraction > 0.0001) _lastExpandedFraction = _fraction;
    if (_fraction == 0.0) return;
    _fraction = 0.0;
    notifyListeners();
  }

  /// Collapses the second pane.
  void collapseSecond({bool animate = true}) {
    if (_fraction < 0.9999) _lastExpandedFraction = _fraction;
    if (_fraction == 1.0) return;
    _fraction = 1.0;
    notifyListeners();
  }

  /// Expands the first pane to its pre-collapse fraction.
  void expandFirst({bool animate = true}) {
    if (_fraction > 0.0001) return;
    setFraction(_lastExpandedFraction, animate: animate);
  }

  /// Expands the second pane to its pre-collapse fraction.
  void expandSecond({bool animate = true}) {
    if (_fraction < 0.9999) return;
    setFraction(_lastExpandedFraction, animate: animate);
  }

  /// Toggles the first pane between collapsed and expanded.
  void toggleFirst({bool animate = true}) {
    if (isFirstCollapsed) {
      expandFirst(animate: animate);
    } else {
      collapseFirst(animate: animate);
    }
  }

  /// Toggles the second pane between collapsed and expanded.
  void toggleSecond({bool animate = true}) {
    if (isSecondCollapsed) {
      expandSecond(animate: animate);
    } else {
      collapseSecond(animate: animate);
    }
  }

  /// Resets to the initial fraction.
  void reset({bool animate = true}) {
    setFraction(_initialFraction, animate: animate);
  }

  // ─── Internal API used by SplitView ─────────────────────────────────────

  /// @nodoc
  ///
  /// Silently updates geometry. Does **not** notify listeners, because
  /// this is called during layout and any listener that calls setState
  /// would throw.
  void attach({
    required SplitDirection direction,
    required bool reverse,
    required AxisDirection firstPaneEdge,
    required double availableSize,
    required double dividerThickness,
  }) {
    final next = _AttachedGeometry(
      direction: direction,
      reverse: reverse,
      firstPaneEdge: firstPaneEdge,
      availableSize: availableSize,
      dividerThickness: dividerThickness,
    );
    if (_geometry == next) return;
    _geometry = next;
  }

  /// @nodoc
  ///
  /// Detaches from the current [SplitView]. Silently clears geometry.
  void detach() {
    if (_geometry == null) return;
    _geometry = null;
    _isDragging = false;
  }

  /// @nodoc
  void setDragging(bool value) {
    if (_isDragging == value) return;
    _isDragging = value;
    notifyListeners();
  }
}
