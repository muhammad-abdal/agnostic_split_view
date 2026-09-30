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
