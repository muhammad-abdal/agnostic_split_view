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

      // Establish 0.4 as the "last expanded" fraction.
      c.setFraction(0.4);
      await tester.pumpAndSettle();

      // Use animate: false so this test isolates the fraction-restoration
      // logic from animation timing. The animated path is exercised by
      // `collapseFirst sets fraction to 0` and `toggleFirst alternates`.
      c.collapseFirst(animate: false);
      await tester.pumpAndSettle();
      c.expandFirst(animate: false);
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
      expect(c.fraction, closeTo(0.4, 0.001));
      c.dispose();
    });
  });

  // ─── v0.2.0 — collapse interaction with min/max constraints ──────────

  group('Collapse with min/max constraints (v0.2.0 fix)', () {
    testWidgets('minFirstPaneSize does not prevent controller.collapseFirst()',
        (tester) async {
      final c = SplitViewController(initialFraction: 0.5);
      await tester.pumpWidget(
        wrap(
          SizedBox(
            width: 400,
            height: 300,
            child: SplitView(
              direction: SplitDirection.horizontal,
              controller: c,
              minFirstPaneSize: 100,
              firstCollapsible: true,
              first: const SizedBox(key: kFirstKey),
              second: const SizedBox(key: kSecondKey),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Min size is enforced while expanded.
      expect(firstRect(tester).width, greaterThanOrEqualTo(100));

      c.collapseFirst(animate: false);
      await tester.pumpAndSettle();

      // Regression: collapse must win over minFirstPaneSize.
      expect(firstRect(tester).width, 0);
      expect(c.isFirstCollapsed, true);
      c.dispose();
    });

    testWidgets(
        'minSecondPaneSize does not prevent controller.collapseSecond()',
        (tester) async {
      final c = SplitViewController(initialFraction: 0.5);
      await tester.pumpWidget(
        wrap(
          SizedBox(
            width: 400,
            height: 300,
            child: SplitView(
              direction: SplitDirection.horizontal,
              controller: c,
              minSecondPaneSize: 100,
              secondCollapsible: true,
              first: const SizedBox(key: kFirstKey),
              second: const SizedBox(key: kSecondKey),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      c.collapseSecond(animate: false);
      await tester.pumpAndSettle();

      expect(secondRect(tester).width, 0);
      expect(c.isSecondCollapsed, true);
      c.dispose();
    });

    testWidgets(
        'dragging past threshold still collapses with a minFirstPaneSize',
        (tester) async {
      final c = SplitViewController(initialFraction: 0.5);
      await tester.pumpWidget(
        wrap(
          SizedBox(
            width: 400,
            height: 300,
            child: SplitView(
              direction: SplitDirection.horizontal,
              controller: c,
              // 40 / 388 ≈ 0.103, below the 0.2 threshold, so the drag
              // can reach the collapse zone. With minFirstPaneSize above
              // threshold * availableSize, the min clamp would prevent
              // the drag from ever reaching the threshold.
              minFirstPaneSize: 40,
              firstCollapsible: true,
              collapseThreshold: 0.2,
              first: const SizedBox(key: kFirstKey),
              second: const SizedBox(key: kSecondKey),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await dragDivider(tester, const Offset(-400, 0));

      expect(c.isFirstCollapsed, true);
      expect(firstRect(tester).width, 0);
      c.dispose();
    });

    testWidgets('min size still applies mid-drag when collapse is disabled',
        (tester) async {
      final c = SplitViewController(initialFraction: 0.5);
      await tester.pumpWidget(
        wrap(
          SizedBox(
            width: 400,
            height: 300,
            child: SplitView(
              direction: SplitDirection.horizontal,
              controller: c,
              minFirstPaneSize: 150,
              firstCollapsible: false,
              first: const SizedBox(key: kFirstKey),
              second: const SizedBox(key: kSecondKey),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await dragDivider(tester, const Offset(-400, 0));

      expect(firstRect(tester).width, greaterThanOrEqualTo(150));
      c.dispose();
    });

    testWidgets('explicit collapse with both min sizes set', (tester) async {
      final c = SplitViewController(initialFraction: 0.5);
      await tester.pumpWidget(
        wrap(
          SizedBox(
            width: 400,
            height: 300,
            child: SplitView(
              direction: SplitDirection.horizontal,
              controller: c,
              minFirstPaneSize: 100,
              minSecondPaneSize: 100,
              firstCollapsible: true,
              secondCollapsible: true,
              first: const SizedBox(key: kFirstKey),
              second: const SizedBox(key: kSecondKey),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      c.collapseFirst(animate: false);
      await tester.pumpAndSettle();
      expect(firstRect(tester).width, 0);

      c.collapseSecond(animate: false);
      await tester.pumpAndSettle();
      expect(secondRect(tester).width, 0);

      c.dispose();
    });
  });
}
