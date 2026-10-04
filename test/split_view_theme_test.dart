import 'package:agnostic_split_view/agnostic_split_view.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/test_helpers.dart';

void main() {
  // ─── Theme resolution ────────────────────────────────────────────────

  group('Theme resolution', () {
    testWidgets('default theme is used when no scope', (tester) async {
      SplitViewDividerState? captured;
      await tester.pumpWidget(
        wrap(
          SplitView(
            direction: SplitDirection.horizontal,
            dividerBuilder: (_, s) {
              captured = s;
              return const SizedBox();
            },
            first: const SizedBox(),
            second: const SizedBox(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        captured!.thickness,
        SplitViewTheme.defaultTheme.dividerThickness,
      );
    });

    testWidgets('overrideWith applies to subtree', (tester) async {
      SplitViewDividerState? captured;
      await tester.pumpWidget(
        wrap(
          SplitViewTheme.overrideWith(
            data: const SplitViewTheme(dividerThickness: 30),
            child: SplitView(
              direction: SplitDirection.horizontal,
              dividerBuilder: (_, s) {
                captured = s;
                return const SizedBox();
              },
              first: const SizedBox(),
              second: const SizedBox(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(captured!.thickness, 30);
    });

    testWidgets('widget-level override beats scope', (tester) async {
      SplitViewDividerState? captured;
      await tester.pumpWidget(
        wrap(
          SplitViewTheme.overrideWith(
            data: const SplitViewTheme(dividerThickness: 30),
            child: SplitView(
              direction: SplitDirection.horizontal,
              dividerThickness: 8,
              dividerBuilder: (_, s) {
                captured = s;
                return const SizedBox();
              },
              first: const SizedBox(),
              second: const SizedBox(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(captured!.thickness, 8);
    });

    testWidgets('nearest scope wins over ancestor scope', (tester) async {
      SplitViewDividerState? captured;
      await tester.pumpWidget(
        wrap(
          SplitViewTheme.overrideWith(
            data: const SplitViewTheme(dividerThickness: 40),
            child: SplitViewTheme.overrideWith(
              data: const SplitViewTheme(dividerThickness: 20),
              child: SplitView(
                direction: SplitDirection.horizontal,
                dividerBuilder: (_, s) {
                  captured = s;
                  return const SizedBox();
                },
                first: const SizedBox(),
                second: const SizedBox(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(captured!.thickness, 20);
    });

    testWidgets('collapseThreshold falls back to theme', (tester) async {
      final controller = SplitViewController(initialFraction: 0.5);
      await tester.pumpWidget(
        wrap(
          SplitViewTheme.overrideWith(
            data: const SplitViewTheme(collapseThreshold: 0.45),
            child: SplitView(
              direction: SplitDirection.horizontal,
              controller: controller,
              firstCollapsible: true,
              first: const SizedBox(),
              second: const SizedBox(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await dragDivider(tester, const Offset(-200, 0));
      expect(controller.isFirstCollapsed, true);
      controller.dispose();
    });

    testWidgets('enabled=false from theme disables divider', (tester) async {
      final controller = SplitViewController(initialFraction: 0.5);
      await tester.pumpWidget(
        wrap(
          SplitViewTheme.overrideWith(
            data: const SplitViewTheme(enabled: false),
            child: SplitView(
              direction: SplitDirection.horizontal,
              controller: controller,
              first: const SizedBox(),
              second: const SizedBox(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await dragDivider(tester, const Offset(80, 0));
      expect(controller.fraction, 0.5);
      controller.dispose();
    });

    testWidgets('resetOnDoubleTap=false from theme blocks reset',
        (tester) async {
      final controller = SplitViewController(initialFraction: 0.4);
      await tester.pumpWidget(
        wrap(
          SplitViewTheme.overrideWith(
            data: const SplitViewTheme(resetOnDoubleTap: false),
            child: SplitView(
              direction: SplitDirection.horizontal,
              controller: controller,
              first: const SizedBox(),
              second: const SizedBox(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      controller.setFraction(0.8);
      await tester.pumpAndSettle();
      await tester.tap(find.byType(SplitDivider));
      await tester.tap(find.byType(SplitDivider));
      await tester.pumpAndSettle(const Duration(milliseconds: 400));
      expect(controller.fraction, closeTo(0.8, 0.001));
      controller.dispose();
    });

    // v0.2.0 — new theme field coverage.

    testWidgets('deferResize falls back to theme', (tester) async {
      final controller = SplitViewController(initialFraction: 0.5);
      await tester.pumpWidget(
        wrap(
          SplitViewTheme.overrideWith(
            data: const SplitViewTheme(deferResize: true),
            child: SplitView(
              direction: SplitDirection.horizontal,
              controller: controller,
              first: const SizedBox(key: kFirstKey),
              second: const SizedBox(key: kSecondKey),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final before = firstRect(tester).width;
      final gesture = await startDividerDrag(tester);
      await moveDragInSteps(tester, gesture, const Offset(80, 0));

      expect(
        firstRect(tester).width,
        equals(before),
        reason: 'Theme-level deferResize:true must freeze panes.',
      );

      await gesture.up();
      await tester.pumpAndSettle();
      controller.dispose();
    });

    testWidgets('shieldPlatformViews falls back to theme', (tester) async {
      await tester.pumpWidget(
        wrap(
          SplitViewTheme.overrideWith(
            data: const SplitViewTheme(shieldPlatformViews: false),
            child: const SplitView(
              direction: SplitDirection.horizontal,
              first: SizedBox(),
              second: SizedBox(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final gesture = await startDividerDrag(tester);
      await moveDragInSteps(tester, gesture, const Offset(40, 0));

      expect(
        find.byType(AbsorbPointer),
        findsNothing,
        reason: 'Theme-level shieldPlatformViews:false disables the shield.',
      );

      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('transitionDuration falls back to theme', (tester) async {
      final controller = SplitViewController(initialFraction: 0.5);
      await tester.pumpWidget(
        wrap(
          SplitViewTheme.overrideWith(
            data: const SplitViewTheme(
              transitionDuration: Duration(milliseconds: 100),
              transitionCurve: Curves.linear,
            ),
            child: SplitView(
              direction: SplitDirection.horizontal,
              controller: controller,
              first: const SizedBox(),
              second: const SizedBox(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      controller.setFraction(0.9, animate: true);

      // Let the theme-driven 100 ms transition run to completion.
      await tester.pumpAndSettle();

      expect(controller.fraction, closeTo(0.9, 0.001));
      controller.dispose();
    });
  });

  // ─── Equality and hashCode ───────────────────────────────────────────

  group('Theme equality', () {
    test('identical themes are ==', () {
      const a = SplitViewTheme();
      const b = SplitViewTheme();
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('differing scalar fields are !=', () {
      const a = SplitViewTheme(dividerThickness: 10);
      const b = SplitViewTheme(dividerThickness: 20);
      expect(a, isNot(b));
      expect(a.hashCode, isNot(b.hashCode));
    });

    test('differing enum fields are !=', () {
      const a = SplitViewTheme(defaultDividerStyle: SplitDividerStyle.line);
      const b = SplitViewTheme(defaultDividerStyle: SplitDividerStyle.floating);
      expect(a, isNot(b));
    });

    test('differing boolean fields are !=', () {
      const a = SplitViewTheme(deferResize: true);
      const b = SplitViewTheme(deferResize: false);
      expect(a, isNot(b));
    });

    test('differing shieldColor are !=', () {
      const a = SplitViewTheme();
      const b = SplitViewTheme(shieldColor: Color(0xFF000000));
      expect(a, isNot(b));
    });

    test('differing transitionDuration are !=', () {
      const a = SplitViewTheme();
      const b = SplitViewTheme(
        transitionDuration: Duration(milliseconds: 500),
      );
      expect(a, isNot(b));
    });

    test('differing transitionCurve are !=', () {
      const a = SplitViewTheme(transitionCurve: Curves.linear);
      const b = SplitViewTheme(transitionCurve: Curves.easeIn);
      expect(a, isNot(b));
    });

    test('differing null vs non-null color are !=', () {
      const a = SplitViewTheme();
      const b = SplitViewTheme(defaultDividerHoverColor: Color(0xFFFF0000));
      expect(a, isNot(b));
    });

    test('boxShadow list equality is structural, not identity', () {
      const shadow = BoxShadow(color: Color(0xFF000000), blurRadius: 4);
      const a = SplitViewTheme(defaultDividerBoxShadow: [shadow]);
      const b = SplitViewTheme(defaultDividerBoxShadow: [shadow]);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('different boxShadow contents are !=', () {
      const a = SplitViewTheme(
        defaultDividerBoxShadow: [
          BoxShadow(color: Color(0xFF000000), blurRadius: 4),
        ],
      );
      const b = SplitViewTheme(
        defaultDividerBoxShadow: [
          BoxShadow(color: Color(0xFF000000), blurRadius: 8),
        ],
      );
      expect(a, isNot(b));
    });

    test('semantics labels equality works', () {
      const a = SplitViewTheme();
      const b = SplitViewTheme(
        semanticsLabels: SplitViewSemanticsLabels(
          resizeHorizontal: 'Custom',
        ),
      );
      expect(a, isNot(b));
    });

    test('equal themes with all v0.2.0 fields share hashCode', () {
      const a = SplitViewTheme(
        deferResize: true,
        shieldPlatformViews: false,
        shieldColor: Color(0x88000000),
        transitionDuration: Duration(milliseconds: 300),
        transitionCurve: Curves.easeInOut,
      );
      const b = SplitViewTheme(
        deferResize: true,
        shieldPlatformViews: false,
        shieldColor: Color(0x88000000),
        transitionDuration: Duration(milliseconds: 300),
        transitionCurve: Curves.easeInOut,
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });
  });

  // ─── copyWith ────────────────────────────────────────────────────────

  group('copyWith', () {
    test('returns a new instance with the given field replaced', () {
      const original = SplitViewTheme();
      final updated = original.copyWith(dividerThickness: 42);
      expect(updated.dividerThickness, 42);
      expect(original.dividerThickness, 12.0);
      expect(updated, isNot(original));
    });

    test('unspecified fields retain original values', () {
      const original = SplitViewTheme(
        dividerThickness: 20,
        collapseThreshold: 0.25,
        deferResize: true,
      );
      final updated = original.copyWith(dividerThickness: 30);
      expect(updated.dividerThickness, 30);
      expect(updated.collapseThreshold, 0.25);
      expect(updated.deferResize, true);
    });

    test('copyWith with no args returns an equal instance', () {
      const original = SplitViewTheme(dividerThickness: 15);
      final copy = original.copyWith();
      expect(copy, original);
      expect(copy.hashCode, original.hashCode);
    });

    test('copyWith can set nullable fields', () {
      const original = SplitViewTheme();
      final updated = original.copyWith(
        defaultDividerHoverColor: const Color(0xFFFF0000),
        shieldColor: const Color(0x88000000),
      );
      expect(updated.defaultDividerHoverColor, const Color(0xFFFF0000));
      expect(updated.shieldColor, const Color(0x88000000));
    });

    test('copyWith on divider style/size', () {
      const original = SplitViewTheme();
      final updated = original.copyWith(
        defaultDividerStyle: SplitDividerStyle.floating,
        defaultDividerSize: SplitDividerSize.large,
      );
      expect(updated.defaultDividerStyle, SplitDividerStyle.floating);
      expect(updated.defaultDividerSize, SplitDividerSize.large);
    });

    test('copyWith on transition settings', () {
      const original = SplitViewTheme();
      final updated = original.copyWith(
        transitionDuration: const Duration(milliseconds: 400),
        transitionCurve: Curves.linear,
      );
      expect(updated.transitionDuration, const Duration(milliseconds: 400));
      expect(updated.transitionCurve, Curves.linear);
    });

    test('copyWith on v0.2.0 feature flags', () {
      const original = SplitViewTheme();
      final updated = original.copyWith(
        deferResize: true,
        shieldPlatformViews: false,
        shieldColor: const Color(0x88000000),
      );
      expect(updated.deferResize, true);
      expect(updated.shieldPlatformViews, false);
      expect(updated.shieldColor, const Color(0x88000000));
    });

    test('copyWith on behavior flags', () {
      const original = SplitViewTheme();
      final updated = original.copyWith(
        enabled: false,
        resetOnDoubleTap: false,
      );
      expect(updated.enabled, false);
      expect(updated.resetOnDoubleTap, false);
    });

    test('copyWith does not mutate the original', () {
      const original = SplitViewTheme(dividerThickness: 10);
      original.copyWith(dividerThickness: 99);
      expect(original.dividerThickness, 10);
    });
  });

  // ─── Defaults ────────────────────────────────────────────────────────

  group('Defaults', () {
    test('defaultTheme has the documented values', () {
      const t = SplitViewTheme.defaultTheme;
      expect(t.dividerThickness, 12.0);
      expect(t.collapseThreshold, 0.15);
      expect(t.transitionDuration, const Duration(milliseconds: 200));
      expect(t.transitionCurve, Curves.easeOutCubic);
      expect(t.defaultDividerStyle, SplitDividerStyle.line);
      expect(t.defaultDividerSize, SplitDividerSize.medium);
      expect(t.defaultDividerColor, const Color(0x1F000000));
      expect(t.enabled, true);
      expect(t.resetOnDoubleTap, true);
      expect(t.deferResize, false);
      expect(t.shieldPlatformViews, true);
      expect(t.shieldColor, isNull);
    });

    test('defaultTheme == const SplitViewTheme()', () {
      expect(SplitViewTheme.defaultTheme, const SplitViewTheme());
    });
  });

  // ─── InheritedWidget notification ────────────────────────────────────

  group('Scope notification', () {
    testWidgets('descendants rebuild when theme changes', (tester) async {
      Widget buildTheme(double thickness) {
        return wrap(
          SplitViewTheme.overrideWith(
            data: SplitViewTheme(dividerThickness: thickness),
            child: SplitView(
              direction: SplitDirection.horizontal,
              dividerBuilder: (_, s) => Text('${s.thickness}'),
              first: const SizedBox(),
              second: const SizedBox(),
            ),
          ),
        );
      }

      await tester.pumpWidget(buildTheme(20));
      expect(find.text('20.0'), findsOneWidget);

      await tester.pumpWidget(buildTheme(40));
      expect(find.text('40.0'), findsOneWidget);
      expect(find.text('20.0'), findsNothing);
    });

    testWidgets('descendants do not rebuild when theme is identical',
        (tester) async {
      Widget buildTheme() {
        return wrap(
          SplitViewTheme.overrideWith(
            data: const SplitViewTheme(dividerThickness: 20),
            child: SplitView(
              direction: SplitDirection.horizontal,
              dividerBuilder: (_, s) => Text('${s.thickness}'),
              first: const SizedBox(),
              second: const SizedBox(),
            ),
          ),
        );
      }

      await tester.pumpWidget(buildTheme());
      await tester.pumpWidget(buildTheme());
      expect(find.text('20.0'), findsOneWidget);
    });
  });
}
