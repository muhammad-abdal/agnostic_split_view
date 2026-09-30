# agnostic_split_view

A framework-agnostic split view for Flutter. **Zero Material or Cupertino
dependencies.** Works with any design system, any theme, or a bare
`WidgetsApp`.

```yaml
dependencies:
  agnostic_split_view: ^0.1.2
```

<p align="center">
<img src="https://raw.githubusercontent.com/muhammad-abdal/agnostic_split_view/main/display/example_preview.gif" alt="Agnostic Split View Demo" width="100%" />
</p>

## Why

Flutter's `widgets.dart` layer is design-neutral. `material.dart` and
`cupertino.dart` are opinionated layers on top. If you build a custom
design system, embed a split view in another package, or simply want a
layout primitive that doesn't drag Material into your dependency tree,
this package is for you.

## Features

- Two-pane split: horizontal or vertical.
- Drag-to-resize with min/max constraints.
- Collapsible panes with drag-threshold snapping.
- Four layouts: left/right, right/left, top/bottom, bottom/top.
- RTL-aware. Directionality flips horizontal layouts automatically.
- Controller with `setFraction`, `collapseFirst`/`collapseSecond`, `expandFirst`/`expandSecond`, `toggleFirst` `toggleSecond`, and `reset`.
- Six divider styles: `line`, `rounded`, `floating`, `bordered`,
  `handle`, `none`. Three size presets plus `custom`.
- Fully themable via `SplitViewTheme` (an `InheritedWidget`, not a
  `ThemeExtension`).
- Zero dependencies beyond `flutter`.

## Usage

### Minimal

```dart
SplitView(
  direction: SplitDirection.horizontal,
  first: const Sidebar(),
  second: const Content(),
)
```

### With a controller

```dart
final controller = SplitViewController(initialFraction: 0.3);

SplitView(
  direction: SplitDirection.horizontal,
  controller: controller,
  firstCollapsible: true,
  minFirstPaneSize: 200,
  maxFirstPaneSize: 400,
  first: const Sidebar(),
  second: const Content(),
)

// Later:
controller.toggleFirst();
```

_(Note: If you create the controller manually, remember to call `controller.dispose()` in your widget's `dispose` method.)_

### Vertical, reversed (bottom pane first)

```dart
SplitView(
  direction: SplitDirection.vertical,
  reverse: true,
  first: const Console(),
  second: const Editor(),
  initialFraction: 0.3,
)
```

### Custom divider

```dart
SplitView(
  direction: SplitDirection.horizontal,
  dividerThickness: 16,
  dividerBuilder: (context, state) => SplitDivider(
    state: state,
    style: SplitDividerStyle.floating,
    size: SplitDividerSize.medium,
    borderRadius: BorderRadius.circular(8),
    hoverColor: Colors.blue,
  ),
  first: const Sidebar(),
  second: const Content(),
)
```

### Theming a subtree

```dart
SplitViewTheme.overrideWith(
  data: const SplitViewTheme(
    dividerThickness: 16,
    defaultDividerStyle: SplitDividerStyle.rounded,
    defaultDividerColor: Color(0xFFDDDDDD),
  ),
  child: SplitView(...),
)
```

_(Note: `SplitViewTheme.overrideWith` completely replaces the theme for its subtree. It does not merge with parent `SplitViewTheme` values.)_

### Responsive sizing with `flutter_screenutil`

The package does not depend on `flutter_screenutil`. Pass scaled values
directly:

```dart
SplitView(
  dividerThickness: 12.w,
  dividerBuilder: (context, state) => SplitDivider(
    state: state,
    lineThickness: 2.h,
    borderRadius: BorderRadius.circular(4.r),
  ),
  first: const Sidebar(),
  second: const Content(),
)
```

### Zero Material

```dart
runApp(
  WidgetsApp(
    color: const Color(0xFFFFFFFF),
    builder: (context, _) => const SplitView(
      direction: SplitDirection.horizontal,
      first: Sidebar(),
      second: Content(),
    ),
  ),
);
```

## API

See the Dartdoc on `SplitView`, `SplitViewController`, `SplitDivider`,
`SplitViewTheme`, `SplitDirection`, `SplitDividerStyle`, and
`SplitDividerSize`.

## Performance notes

- Fraction changes rebuild only the divider subtree, not the panes.
- The layout pass is a single `CustomMultiChildLayout` traversal.
- The controller is silent during geometry updates, avoiding rebuilds
  during layout.

## ⚠️ Important: Bounded Constraints

`SplitView` requires bounded constraints to calculate pane sizes. If you place it inside a `Row` or `Column`, you **must** wrap it in an `Expanded`, `Flexible`, or `SizedBox` to avoid layout exceptions.

```dart
// ✅ Good: Wrapped in Expanded
Row(
  children: [
    Expanded(child: SplitView(...)),
  ],
)

## License

MIT — see `LICENSE`.
```
