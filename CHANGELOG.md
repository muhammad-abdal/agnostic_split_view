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
