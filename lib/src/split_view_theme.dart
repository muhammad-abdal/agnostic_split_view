import 'package:flutter/widgets.dart';

import 'types.dart';

/// Accessibility labels for a [SplitView].
class SplitViewSemanticsLabels {
  /// Creates a set of labels.
  const SplitViewSemanticsLabels({
    this.resizeHorizontal = 'Resize panels horizontally',
    this.resizeVertical = 'Resize panels vertically',
    this.collapseFirst = 'Collapse first pane',
    this.expandFirst = 'Expand first pane',
    this.collapseSecond = 'Collapse second pane',
    this.expandSecond = 'Expand second pane',
  });

  /// Label for the horizontal divider.
  final String resizeHorizontal;

  /// Label for the vertical divider.
  final String resizeVertical;

  /// Label for collapsing the first pane.
  final String collapseFirst;

  /// Label for expanding the first pane.
  final String expandFirst;

  /// Label for collapsing the second pane.
  final String collapseSecond;

  /// Label for expanding the second pane.
  final String expandSecond;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SplitViewSemanticsLabels &&
          resizeHorizontal == other.resizeHorizontal &&
          resizeVertical == other.resizeVertical &&
          collapseFirst == other.collapseFirst &&
          expandFirst == other.expandFirst &&
          collapseSecond == other.collapseSecond &&
          expandSecond == other.expandSecond;

  @override
  int get hashCode => Object.hash(
        resizeHorizontal,
        resizeVertical,
        collapseFirst,
        expandFirst,
        collapseSecond,
        expandSecond,
      );
}

/// Theming for [SplitView].
///
/// Plain immutable class — **not** a [ThemeExtension] — so the package
/// stays free of Material and Cupertino dependencies.
class SplitViewTheme {
  /// Creates a theme.
  const SplitViewTheme({
    this.dividerThickness = 12.0,
    this.collapseThreshold = 0.15,
    this.transitionDuration = const Duration(milliseconds: 200),
    this.transitionCurve = Curves.easeOutCubic,
    this.defaultDividerStyle = SplitDividerStyle.line,
    this.defaultDividerSize = SplitDividerSize.medium,
    this.defaultDividerColor = const Color(0x1F000000),
    this.defaultDividerHoverColor,
    this.defaultDividerDragColor,
    this.defaultDividerBorderRadius,
    this.defaultDividerBoxShadow,
    this.enabled = true,
    this.resetOnDoubleTap = true,
    this.deferResize = false,
    this.shieldPlatformViews = true,
    this.shieldColor,
    this.semanticsLabels = const SplitViewSemanticsLabels(),
  });

  /// Default hit area thickness.
  final double dividerThickness;

  /// Fraction below which a drag collapses a collapsible pane.
  final double collapseThreshold;

  /// Duration of programmatic transitions.
  ///
  /// Pairs with [transitionCurve].
  final Duration transitionDuration;

  /// Curve of programmatic transitions.
  ///
  /// Pairs with [transitionDuration].
  final Curve transitionCurve;

  /// Default divider style.
  final SplitDividerStyle defaultDividerStyle;

  /// Default divider size preset.
  final SplitDividerSize defaultDividerSize;

  /// Default divider color.
  final Color defaultDividerColor;

  /// Divider color on hover.
  final Color? defaultDividerHoverColor;

  /// Divider color during drag.
  final Color? defaultDividerDragColor;

  /// Default divider border radius.
  final BorderRadius? defaultDividerBorderRadius;

  /// Default divider box shadow.
  final List<BoxShadow>? defaultDividerBoxShadow;

  /// Whether dividers are interactive by default.
  final bool enabled;

  /// Whether double-tap resets the split by default.
  final bool resetOnDoubleTap;

  /// Whether panes freeze during drag by default.
  final bool deferResize;

  /// Whether to shield platform views during drag by default.
  final bool shieldPlatformViews;

  /// Tint color of the shield barrier. Null → invisible.
  final Color? shieldColor;

  /// Accessibility labels.
  final SplitViewSemanticsLabels semanticsLabels;

  /// The theme used when no [SplitViewThemeScope] is present.
  static const SplitViewTheme defaultTheme = SplitViewTheme();

  /// Resolves the effective theme for [context].
  static SplitViewTheme of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<SplitViewThemeScope>();
    return scope?.theme ?? defaultTheme;
  }

  /// Wraps [child] with a scoped theme override.
  static Widget overrideWith({
    required SplitViewTheme data,
    required Widget child,
  }) {
    return SplitViewThemeScope(theme: data, child: child);
  }

  /// Returns a copy of this theme with the given fields replaced.
  SplitViewTheme copyWith({
    double? dividerThickness,
    double? collapseThreshold,
    Duration? transitionDuration,
    Curve? transitionCurve,
    SplitDividerStyle? defaultDividerStyle,
    SplitDividerSize? defaultDividerSize,
    Color? defaultDividerColor,
    Color? defaultDividerHoverColor,
    Color? defaultDividerDragColor,
    BorderRadius? defaultDividerBorderRadius,
    List<BoxShadow>? defaultDividerBoxShadow,
    bool? enabled,
    bool? resetOnDoubleTap,
    bool? deferResize,
    bool? shieldPlatformViews,
    Color? shieldColor,
    SplitViewSemanticsLabels? semanticsLabels,
  }) {
    return SplitViewTheme(
      dividerThickness: dividerThickness ?? this.dividerThickness,
      collapseThreshold: collapseThreshold ?? this.collapseThreshold,
      transitionDuration: transitionDuration ?? this.transitionDuration,
      transitionCurve: transitionCurve ?? this.transitionCurve,
      defaultDividerStyle: defaultDividerStyle ?? this.defaultDividerStyle,
      defaultDividerSize: defaultDividerSize ?? this.defaultDividerSize,
      defaultDividerColor: defaultDividerColor ?? this.defaultDividerColor,
      defaultDividerHoverColor:
          defaultDividerHoverColor ?? this.defaultDividerHoverColor,
      defaultDividerDragColor:
          defaultDividerDragColor ?? this.defaultDividerDragColor,
      defaultDividerBorderRadius:
          defaultDividerBorderRadius ?? this.defaultDividerBorderRadius,
      defaultDividerBoxShadow:
          defaultDividerBoxShadow ?? this.defaultDividerBoxShadow,
      enabled: enabled ?? this.enabled,
      resetOnDoubleTap: resetOnDoubleTap ?? this.resetOnDoubleTap,
      deferResize: deferResize ?? this.deferResize,
      shieldPlatformViews: shieldPlatformViews ?? this.shieldPlatformViews,
      shieldColor: shieldColor ?? this.shieldColor,
      semanticsLabels: semanticsLabels ?? this.semanticsLabels,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SplitViewTheme &&
          dividerThickness == other.dividerThickness &&
          collapseThreshold == other.collapseThreshold &&
          transitionDuration == other.transitionDuration &&
          transitionCurve == other.transitionCurve &&
          defaultDividerStyle == other.defaultDividerStyle &&
          defaultDividerSize == other.defaultDividerSize &&
          defaultDividerColor == other.defaultDividerColor &&
          defaultDividerHoverColor == other.defaultDividerHoverColor &&
          defaultDividerDragColor == other.defaultDividerDragColor &&
          defaultDividerBorderRadius == other.defaultDividerBorderRadius &&
          _listEquals(defaultDividerBoxShadow, other.defaultDividerBoxShadow) &&
          enabled == other.enabled &&
          resetOnDoubleTap == other.resetOnDoubleTap &&
          deferResize == other.deferResize &&
          shieldPlatformViews == other.shieldPlatformViews &&
          shieldColor == other.shieldColor &&
          semanticsLabels == other.semanticsLabels;

  @override
  int get hashCode => Object.hash(
        dividerThickness,
        collapseThreshold,
        transitionDuration,
        transitionCurve,
        defaultDividerStyle,
        defaultDividerSize,
        defaultDividerColor,
        defaultDividerHoverColor,
        defaultDividerDragColor,
        defaultDividerBorderRadius,
        Object.hashAll(defaultDividerBoxShadow ?? const <BoxShadow>[]),
        enabled,
        resetOnDoubleTap,
        deferResize,
        shieldPlatformViews,
        shieldColor,
        semanticsLabels,
      );
}

/// Provides a [SplitViewTheme] to descendants.
class SplitViewThemeScope extends InheritedWidget {
  /// Creates a theme scope.
  const SplitViewThemeScope({
    super.key,
    required this.theme,
    required super.child,
  });

  /// The theme provided to descendants.
  final SplitViewTheme theme;

  @override
  bool updateShouldNotify(SplitViewThemeScope oldWidget) =>
      theme != oldWidget.theme;
}

bool _listEquals<T>(List<T>? a, List<T>? b) {
  if (identical(a, b)) return true;
  if (a == null || b == null) return false;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
