## 0.2.0

Performance-focused release. Adds three opt-in features for expensive
pane content, plus a fix for collapsed panes being blocked by min/max
size constraints.

### Added

- **`deferResize`** — freeze pane layout during drag; only the divider
  moves at frame rate. Panes snap into place on release. Cuts UI-thread
  cost by ~20× on heavy content. See `example/BENCHMARKS.md` for the
  data behind this default.
- **`isolatePanes`** — wrap each pane in a `RepaintBoundary`. Recommended
  for panes with continuous animations or expensive repaints. Defaults to
  `false` because layer explosion can hurt deeply nested layouts.
- **`shieldPlatformViews`** — mount an invisible `AbsorbPointer` over the
  panes during drag. Prevents embedded `WebView`, `MapView`, or video
  players from stealing pointer events mid-drag.
- **`shieldColor`** — optional tint on the shield, for user feedback that
  a drag is in progress.
- **`transitionDuration` / `transitionCurve`** — control programmatic
  transitions triggered by `setFraction(animate: true)`,
  `collapseFirst(animate: true)`, `toggleFirst(animate: true)`,
  `reset(animate: true)`, and double-tap-to-reset.

### Fixed

- Collapsed panes no longer silently enforce `minFirstPaneSize` or
  `minSecondPaneSize`. Explicit `collapseFirst()` / `collapseSecond()`
  calls now short-circuit to zero regardless of min constraints. Mid-drag
  constraints are unchanged when collapse is disabled.

### Changed

- `SplitViewTheme.copyWith`, `operator ==`, and `hashCode` now include
  the new fields. Existing theme configurations continue to compile and
  behave identically.

### Notes

- `isolatePanes` defaults to `false`. Flip it on for animated or heavy
  panes; leave it off for deeply nested `SplitView` trees.
- `deferResize` changes drag UX: panes stay frozen and snap on release
  rather than resizing live. This is the trade-off for ~20× lower UI
  cost during the drag. See `example/BENCHMARKS.md` for details.
- No breaking changes. Existing `0.1.x` code compiles and runs unchanged.

## 0.1.2

- Fixed README image path to correctly render the demo GIF on pub.dev.

## 0.1.1

- Improved `example/lib/main.dart` with a clean, minimal, self-contained starting point.
- Added demo GIF to `README.md` for better visual documentation.

## 0.1.0

Initial release.

- `SplitView` with horizontal and vertical orientation.
- `reverse` flag for all four visual arrangements.
- RTL-aware directionality.
- Min/max pixel constraints on both panes.
- Collapsible panes with drag-threshold snapping.
- `SplitViewController` with `setFraction`, `collapseFirst`,
  `collapseSecond`, `expandFirst`, `expandSecond`, `toggleFirst`,
  `toggleSecond`, `reset`.
- `SplitDivider` with six styles (`line`, `rounded`, `floating`,
  `bordered`, `handle`, `none`) and four size presets (`small`,
  `medium`, `large`, `custom`).
- `SplitViewTheme` (an `InheritedWidget` scope, not a `ThemeExtension`)
  with full `==`/`hashCode`.
- Zero dependencies beyond `flutter`.
