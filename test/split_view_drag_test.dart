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
      await gesture.moveBy(const Offset(30, 0));
      await tester.pump();
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
}
