import 'package:agnostic_split_view/agnostic_split_view.dart';
import 'package:flutter/widgets.dart';

/// The orientation of a [SplitView].
enum SplitDirection {
  /// Panes are side by side.
  horizontal,

  /// Panes are stacked.
  vertical,
}

/// The visual presentation of a divider.
enum SplitDividerStyle {
  /// A thin, subtle line.
  line,

  /// A thicker, rounded bar centered in the hit area.
  rounded,

  /// A divider that floats above the panes with a shadow.
  floating,

  /// A divider with a visible border/outline.
  bordered,

  /// A divider with a rounded handle (grip dots).
  handle,

  /// No visual. The hit area is invisible but still interactive.
  none,
}

/// Size presets for a divider.
enum SplitDividerSize {
  /// 8px hit area, 1px visual.
  small,

  /// 12px hit area, 2px visual.
  medium,

  /// 20px hit area, 4px visual.
  large,

  /// Use explicit values.
  custom,
}

/// Builder signature for the divider slot.
typedef SplitViewDividerBuilder = Widget Function(
  BuildContext context,
  SplitViewDividerState state,
);

/// Callback for fraction changes.
typedef SplitFractionCallback = void Function(double fraction);

/// Callback with no arguments.
typedef SplitVoidCallback = void Function();

/// Internal layout slot identifiers used by `CustomMultiChildLayout`.
///
/// Not part of the public API surface; exported only because Dart does
/// not allow private symbols to cross library boundaries without
/// `part`/`part of`.
class SplitViewSlot {
  const SplitViewSlot._();

  /// Slot for the first pane.
  static const int first = 0;

  /// Slot for the divider.
  static const int divider = 1;

  /// Slot for the second pane.
  static const int second = 2;
}
