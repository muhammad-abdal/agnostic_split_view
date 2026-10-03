import 'package:agnostic_split_view/agnostic_split_view.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/test_helpers.dart';

void main() {
  group('Collapse via controller', () {
    testWidgets('collapseFirst sets fraction to 0', (tester) async {
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
      c.collapseFirst();
      await tester.pumpAndSettle();
      expect(c.fraction, 0.0);
      expect(c.isFirstCollapsed, true);
      expect(firstRect(tester).width, 0);
      c.dispose();
    });

    testWidgets('collapseSecond sets fraction to 1', (tester) async {
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
      c.collapseSecond();
      await tester.pumpAndSettle();
      expect(c.fraction, 1.0);
      expect(c.isSecondCollapsed, true);
      expect(secondRect(tester).width, 0);
      c.dispose();
    });

    testWidgets('expandFirst restores previous fraction', (tester) async {
      final c = SplitViewController(initialFraction: 0.4);
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
      c.collapseFirst();
      await tester.pumpAndSettle();
      c.expandFirst();
      await tester.pumpAndSettle();
      expect(c.fraction, closeTo(0.4, 0.001));
      c.dispose();
    });

    testWidgets('toggleFirst alternates', (tester) async {
      final c = SplitViewController(initialFraction: 0.5);
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
      c.toggleFirst();
      await tester.pumpAndSettle();
      expect(c.isFirstCollapsed, true);
      c.toggleFirst();
      await tester.pumpAndSettle();
      expect(c.isFirstCollapsed, false);
      c.dispose();
    });
  });

  group('Collapse via drag threshold', () {
    testWidgets('dragging below threshold collapses first pane',
        (tester) async {
      final c = SplitViewController(initialFraction: 0.3);
      await tester.pumpWidget(
        wrap(
          SplitView(
            direction: SplitDirection.horizontal,
            controller: c,
            firstCollapsible: true,
            collapseThreshold: 0.15,
            first: const SizedBox(key: kFirstKey),
            second: const SizedBox(key: kSecondKey),
          ),
        ),
      );
      await tester.pumpAndSettle();
      // Drag left (in LTR, negative dx shrinks first pane).
      await dragDivider(tester, const Offset(-200, 0));
      expect(c.fraction, 0.0);
      c.dispose();
    });

    testWidgets('dragging below threshold collapses second pane',
        (tester) async {
      final c = SplitViewController(initialFraction: 0.7);
      await tester.pumpWidget(
        wrap(
          SplitView(
            direction: SplitDirection.horizontal,
            controller: c,
            secondCollapsible: true,
            collapseThreshold: 0.15,
            first: const SizedBox(),
            second: const SizedBox(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await dragDivider(tester, const Offset(200, 0));
      expect(c.fraction, 1.0);
      c.dispose();
    });

    testWidgets('threshold is ignored when collapsible flag is off',
        (tester) async {
      final c = SplitViewController(initialFraction: 0.5);
      await tester.pumpWidget(
        wrap(
          SplitView(
            direction: SplitDirection.horizontal,
            controller: c,
            collapseThreshold: 0.45,
            first: const SizedBox(),
            second: const SizedBox(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await dragDivider(tester, const Offset(-190, 0));
      // Should not have collapsed because firstCollapsible is false.
      expect(c.isFirstCollapsed, false);
      c.dispose();
    });

    testWidgets('double-tap resets to initial', (tester) async {
      final c = SplitViewController(initialFraction: 0.4);
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
      c.setFraction(0.8);
      await tester.pumpAndSettle();
      await tester.tap(find.byType(SplitDivider));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.byType(SplitDivider));
      await tester.pumpAndSettle();
      // In v0.1.2, double-tap resets to initial fraction.
      expect(c.fraction, closeTo(0.4, 0.001));
      c.dispose();
    });
  });
}
