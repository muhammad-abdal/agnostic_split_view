import 'package:agnostic_split_view/agnostic_split_view.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/test_helpers.dart';

void main() {
  group('Layout', () {
    testWidgets('renders both panes', (tester) async {
      await tester.pumpWidget(
        wrap(
          const SplitView(
            direction: SplitDirection.horizontal,
            first: SizedBox(key: kFirstKey),
            second: SizedBox(key: kSecondKey),
          ),
        ),
      );
      expect(find.byKey(kFirstKey), findsOneWidget);
      expect(find.byKey(kSecondKey), findsOneWidget);
    });

    testWidgets('default divider is present', (tester) async {
      await tester.pumpWidget(
        wrap(
          const SplitView(
            direction: SplitDirection.horizontal,
            first: SizedBox(),
            second: SizedBox(),
          ),
        ),
      );
      expect(find.byType(SplitDivider), findsOneWidget);
    });

    testWidgets('horizontal: panes are side by side', (tester) async {
      await tester.pumpWidget(
        wrap(
          const SplitView(
            direction: SplitDirection.horizontal,
            first: SizedBox(key: kFirstKey),
            second: SizedBox(key: kSecondKey),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        firstRect(tester).right,
        lessThanOrEqualTo(secondRect(tester).left),
      );
    });

    testWidgets('vertical: panes are stacked', (tester) async {
      await tester.pumpWidget(
        wrap(
          const SplitView(
            direction: SplitDirection.vertical,
            first: SizedBox(key: kFirstKey),
            second: SizedBox(key: kSecondKey),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        firstRect(tester).bottom,
        lessThanOrEqualTo(secondRect(tester).top),
      );
    });

    testWidgets('initialFraction controls initial sizes', (tester) async {
      await tester.pumpWidget(
        wrap(
          const SplitView(
            direction: SplitDirection.horizontal,
            initialFraction: 0.25,
            first: SizedBox(key: kFirstKey),
            second: SizedBox(key: kSecondKey),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(firstRect(tester).width, closeTo(97, 2));
    });

    testWidgets('custom divider replaces default', (tester) async {
      const customKey = Key('custom-divider');
      await tester.pumpWidget(
        wrap(
          SplitView(
            direction: SplitDirection.horizontal,
            dividerBuilder: (_, __) => const SizedBox(key: customKey),
            first: const SizedBox(),
            second: const SizedBox(),
          ),
        ),
      );
      expect(find.byKey(customKey), findsOneWidget);
      expect(find.byType(SplitDivider), findsNothing);
    });

    testWidgets('pane sizes sum plus divider equals total width',
        (tester) async {
      await tester.pumpWidget(
        wrap(
          const SplitView(
            direction: SplitDirection.horizontal,
            dividerThickness: 20,
            first: SizedBox(key: kFirstKey),
            second: SizedBox(key: kSecondKey),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final sum = firstRect(tester).width +
          secondRect(tester).width +
          dividerRect(tester).width;
      expect(sum, closeTo(400, 0.5));
    });
  });

  // ─── v0.2.0 — isolatePanes ───────────────────────────────────────────

  group('isolatePanes', () {
    testWidgets('false (default): panes are not wrapped in RepaintBoundary',
        (tester) async {
      await tester.pumpWidget(
        wrap(
          const SplitView(
            direction: SplitDirection.horizontal,
            first: SizedBox(key: kFirstKey),
            second: SizedBox(key: kSecondKey),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        findAncestorOfType<RepaintBoundary>(tester, kFirstKey),
        isNull,
        reason: 'Default behavior: no user-supplied RepaintBoundary.',
      );
      expect(
        findAncestorOfType<RepaintBoundary>(tester, kSecondKey),
        isNull,
      );
    });

    testWidgets('true: first pane is wrapped in RepaintBoundary',
        (tester) async {
      await tester.pumpWidget(
        wrap(
          const SplitView(
            direction: SplitDirection.horizontal,
            isolatePanes: true,
            first: SizedBox(key: kFirstKey),
            second: SizedBox(key: kSecondKey),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        findAncestorOfType<RepaintBoundary>(tester, kFirstKey),
        isNotNull,
      );
    });

    testWidgets('true: second pane is wrapped in RepaintBoundary',
        (tester) async {
      await tester.pumpWidget(
        wrap(
          const SplitView(
            direction: SplitDirection.horizontal,
            isolatePanes: true,
            first: SizedBox(key: kFirstKey),
            second: SizedBox(key: kSecondKey),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        findAncestorOfType<RepaintBoundary>(tester, kSecondKey),
        isNotNull,
      );
    });

    testWidgets('toggling isolatePanes at runtime does not throw',
        (tester) async {
      Widget build(bool isolate) => wrap(
            SplitView(
              direction: SplitDirection.horizontal,
              isolatePanes: isolate,
              first: const SizedBox(key: kFirstKey),
              second: const SizedBox(key: kSecondKey),
            ),
          );

      await tester.pumpWidget(build(false));
      await tester.pumpAndSettle();
      await tester.pumpWidget(build(true));
      await tester.pumpAndSettle();
      await tester.pumpWidget(build(false));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('layout geometry is unchanged with isolatePanes on',
        (tester) async {
      await tester.pumpWidget(
        wrap(
          const SplitView(
            direction: SplitDirection.horizontal,
            isolatePanes: true,
            initialFraction: 0.25,
            first: SizedBox(key: kFirstKey),
            second: SizedBox(key: kSecondKey),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // RepaintBoundary must be layout-transparent.
      expect(firstRect(tester).width, closeTo(97, 2));
    });
  });

  // ─── v0.2.0 — deferResize ────────────────────────────────────────────

  group('deferResize', () {
    testWidgets('false: pane width updates live during drag', (tester) async {
      final controller = SplitViewController(initialFraction: 0.5);
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        wrap(
          SplitView(
            direction: SplitDirection.horizontal,
            controller: controller,
            deferResize: false,
            first: const SizedBox(key: kFirstKey),
            second: const SizedBox(key: kSecondKey),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final before = firstRect(tester).width;
      final gesture = await startDividerDrag(tester);
      await moveDragInSteps(tester, gesture, const Offset(80, 0));

      expect(firstRect(tester).width, greaterThan(before));

      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('true: pane width stays frozen during drag, catches up after',
        (tester) async {
      final controller = SplitViewController(initialFraction: 0.5);
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        wrap(
          SplitView(
            direction: SplitDirection.horizontal,
            controller: controller,
            deferResize: true,
            first: const SizedBox(key: kFirstKey),
            second: const SizedBox(key: kSecondKey),
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
        reason: 'Pane must not resize during drag.',
      );

      await gesture.up();
      await tester.pumpAndSettle();

      expect(
        firstRect(tester).width,
        greaterThan(before),
        reason: 'Pane must catch up on release.',
      );
    });

    testWidgets('true: divider still moves at frame rate', (tester) async {
      final controller = SplitViewController(initialFraction: 0.5);
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        wrap(
          SplitView(
            direction: SplitDirection.horizontal,
            controller: controller,
            deferResize: true,
            first: const SizedBox(key: kFirstKey),
            second: const SizedBox(key: kSecondKey),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final before = dividerRect(tester).left;
      final gesture = await startDividerDrag(tester);
      await moveDragInSteps(tester, gesture, const Offset(80, 0));

      expect(
        dividerRect(tester).left,
        greaterThan(before),
        reason: 'Divider must track the drag visually.',
      );

      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('true: controller fraction still updates', (tester) async {
      final controller = SplitViewController(initialFraction: 0.5);
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        wrap(
          SplitView(
            direction: SplitDirection.horizontal,
            controller: controller,
            deferResize: true,
            first: const SizedBox(),
            second: const SizedBox(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await dragDivider(tester, const Offset(80, 0));
      expect(controller.fraction, greaterThan(0.5));
    });
  });

  // ─── v0.2.0 — shieldPlatformViews ────────────────────────────────────

  group('shieldPlatformViews', () {
    testWidgets('false: no shield during drag', (tester) async {
      await tester.pumpWidget(
        wrap(
          const SplitView(
            direction: SplitDirection.horizontal,
            shieldPlatformViews: false,
            first: SizedBox(),
            second: SizedBox(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final gesture = await startDividerDrag(tester);
      await moveDragInSteps(tester, gesture, const Offset(40, 0));

      expect(find.byType(AbsorbPointer), findsNothing);

      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('true: shield mounted only during drag', (tester) async {
      await tester.pumpWidget(
        wrap(
          const SplitView(
            direction: SplitDirection.horizontal,
            shieldPlatformViews: true,
            first: SizedBox(),
            second: SizedBox(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AbsorbPointer), findsNothing);

      final gesture = await startDividerDrag(tester);
      await moveDragInSteps(tester, gesture, const Offset(40, 0));

      expect(find.byType(AbsorbPointer), findsOneWidget);

      await gesture.up();
      await tester.pumpAndSettle();

      expect(find.byType(AbsorbPointer), findsNothing);
    });

    testWidgets('non-null shieldColor paints a ColoredBox', (tester) async {
      await tester.pumpWidget(
        wrap(
          const SplitView(
            direction: SplitDirection.horizontal,
            shieldPlatformViews: true,
            shieldColor: Color(0x88000000),
            first: SizedBox(),
            second: SizedBox(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final gesture = await startDividerDrag(tester);
      await moveDragInSteps(tester, gesture, const Offset(40, 0));

      final colored = tester.widget<ColoredBox>(find.byType(ColoredBox).last);
      expect(colored.color, const Color(0x88000000));

      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('null shieldColor paints no ColoredBox under the shield',
        (tester) async {
      await tester.pumpWidget(
        wrap(
          const SplitView(
            direction: SplitDirection.horizontal,
            shieldPlatformViews: true,
            first: SizedBox(),
            second: SizedBox(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final gesture = await startDividerDrag(tester);
      await moveDragInSteps(tester, gesture, const Offset(40, 0));

      final under = find.descendant(
        of: find.byType(AbsorbPointer),
        matching: find.byType(ColoredBox),
      );
      expect(under, findsNothing);

      await gesture.up();
      await tester.pumpAndSettle();
    });
  });
}
