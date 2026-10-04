import 'package:agnostic_split_view/agnostic_split_view.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/test_helpers.dart';

void main() {
  group('Drag lifecycle callbacks', () {
    testWidgets('onDragStart fires once', (tester) async {
      var starts = 0;
      await tester.pumpWidget(
        wrap(
          SplitView(
            direction: SplitDirection.horizontal,
            onDragStart: () => starts++,
            first: const SizedBox(),
            second: const SizedBox(),
          ),
        ),
      );
      await dragDivider(tester, const Offset(40, 0));
      expect(starts, 1);
    });

    testWidgets('onDragEnd fires once', (tester) async {
      var ends = 0;
      await tester.pumpWidget(
        wrap(
          SplitView(
            direction: SplitDirection.horizontal,
            onDragEnd: () => ends++,
            first: const SizedBox(),
            second: const SizedBox(),
          ),
        ),
      );
      await dragDivider(tester, const Offset(40, 0));
      expect(ends, 1);
    });

    testWidgets('onFractionChanged fires during drag', (tester) async {
      var changes = 0;
      await tester.pumpWidget(
        wrap(
          SplitView(
            direction: SplitDirection.horizontal,
            onFractionChanged: (_) => changes++,
            first: const SizedBox(),
            second: const SizedBox(),
          ),
        ),
      );
      await dragDivider(tester, const Offset(40, 0), steps: 10);
      expect(changes, greaterThanOrEqualTo(4));
    });

    testWidgets('dragging state is true during drag', (tester) async {
      final c = SplitViewController();
      await tester.pumpWidget(
        wrap(
          SplitView(
            direction: SplitDirection.horizontal,
            controller: c,
            first: const SizedBox(),
            second: const SizedBox(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(c.isDragging, false);

      final gesture = await startDividerDrag(tester);
      await moveDragInSteps(tester, gesture, const Offset(30, 0));
      expect(c.isDragging, true);

      await gesture.up();
      await tester.pumpAndSettle();
      expect(c.isDragging, false);
      c.dispose();
    });
  });

  group('Drag direction math', () {
    testWidgets('LTR: drag right grows first pane', (tester) async {
      final c = SplitViewController(initialFraction: 0.5);
      await tester.pumpWidget(
        wrap(
          SplitView(
            direction: SplitDirection.horizontal,
            controller: c,
            first: const SizedBox(key: kFirstKey),
            second: const SizedBox(key: kSecondKey),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final before = firstRect(tester).width;
      await dragDivider(tester, const Offset(50, 0));
      expect(firstRect(tester).width, greaterThan(before));
      c.dispose();
    });

    testWidgets('RTL: drag left grows first pane', (tester) async {
      final c = SplitViewController(initialFraction: 0.5);
      await tester.pumpWidget(
        wrap(
          SplitView(
            direction: SplitDirection.horizontal,
            controller: c,
            first: const SizedBox(key: kFirstKey),
            second: const SizedBox(key: kSecondKey),
          ),
          dir: TextDirection.rtl,
        ),
      );
      await tester.pumpAndSettle();
      final before = firstRect(tester).width;
      await dragDivider(tester, const Offset(-50, 0));
      expect(firstRect(tester).width, greaterThan(before));
      c.dispose();
    });

    testWidgets('vertical: drag down grows first pane', (tester) async {
      final c = SplitViewController(initialFraction: 0.5);
      await tester.pumpWidget(
        wrap(
          SplitView(
            direction: SplitDirection.vertical,
            controller: c,
            first: const SizedBox(key: kFirstKey),
            second: const SizedBox(key: kSecondKey),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final before = firstRect(tester).height;
      await dragDivider(tester, const Offset(0, 50));
      expect(firstRect(tester).height, greaterThan(before));
      c.dispose();
    });
  });

  group('Disabled divider', () {
    testWidgets('enabled=false blocks drag', (tester) async {
      final c = SplitViewController(initialFraction: 0.5);
      await tester.pumpWidget(
        wrap(
          SplitView(
            direction: SplitDirection.horizontal,
            controller: c,
            enabled: false,
            first: const SizedBox(),
            second: const SizedBox(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await dragDivider(tester, const Offset(80, 0));
      expect(c.fraction, 0.5);
      c.dispose();
    });
  });

  // ─── v0.2.0 — deferResize drag behavior ──────────────────────────────

  group('deferResize', () {
    testWidgets('false: pane width updates live during drag', (tester) async {
      final c = SplitViewController(initialFraction: 0.5);
      await tester.pumpWidget(
        wrap(
          SplitView(
            direction: SplitDirection.horizontal,
            controller: c,
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
      c.dispose();
    });

    testWidgets('true: pane width is frozen mid-drag', (tester) async {
      final c = SplitViewController(initialFraction: 0.5);
      await tester.pumpWidget(
        wrap(
          SplitView(
            direction: SplitDirection.horizontal,
            controller: c,
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

      expect(firstRect(tester).width, equals(before));

      await gesture.up();
      await tester.pumpAndSettle();

      expect(firstRect(tester).width, greaterThan(before));
      c.dispose();
    });

    testWidgets('true: divider moves visually during the drag', (tester) async {
      final c = SplitViewController(initialFraction: 0.5);
      await tester.pumpWidget(
        wrap(
          SplitView(
            direction: SplitDirection.horizontal,
            controller: c,
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

      expect(dividerRect(tester).left, greaterThan(before));

      await gesture.up();
      await tester.pumpAndSettle();
      c.dispose();
    });

    testWidgets('true: controller fraction keeps updating', (tester) async {
      final c = SplitViewController(initialFraction: 0.5);
      await tester.pumpWidget(
        wrap(
          SplitView(
            direction: SplitDirection.horizontal,
            controller: c,
            deferResize: true,
            first: const SizedBox(),
            second: const SizedBox(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await dragDivider(tester, const Offset(80, 0));
      expect(c.fraction, greaterThan(0.5));
      c.dispose();
    });
  });

  // ─── v0.2.0 — shieldPlatformViews lifecycle ──────────────────────────

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

    testWidgets('true: shield mounted only while dragging', (tester) async {
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
  });
}
