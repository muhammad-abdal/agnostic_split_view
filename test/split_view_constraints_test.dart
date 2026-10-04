import 'package:agnostic_split_view/agnostic_split_view.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/test_helpers.dart';

void main() {
  group('Pixel constraints', () {
    testWidgets('minFirstPaneSize is respected', (tester) async {
      final controller = SplitViewController(initialFraction: 0.05);
      await tester.pumpWidget(
        wrap(
          SplitView(
            direction: SplitDirection.horizontal,
            controller: controller,
            minFirstPaneSize: 100,
            first: const SizedBox(key: kFirstKey),
            second: const SizedBox(key: kSecondKey),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(firstRect(tester).width, greaterThanOrEqualTo(100));
      controller.dispose();
    });

    testWidgets('maxFirstPaneSize is respected', (tester) async {
      final controller = SplitViewController(initialFraction: 0.9);
      await tester.pumpWidget(
        wrap(
          SplitView(
            direction: SplitDirection.horizontal,
            controller: controller,
            maxFirstPaneSize: 150,
            first: const SizedBox(key: kFirstKey),
            second: const SizedBox(key: kSecondKey),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(firstRect(tester).width, lessThanOrEqualTo(150));
      controller.dispose();
    });

    testWidgets('minSecondPaneSize is respected', (tester) async {
      final controller = SplitViewController(initialFraction: 0.95);
      await tester.pumpWidget(
        wrap(
          SplitView(
            direction: SplitDirection.horizontal,
            controller: controller,
            minSecondPaneSize: 200,
            first: const SizedBox(key: kFirstKey),
            second: const SizedBox(key: kSecondKey),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(secondRect(tester).width, greaterThanOrEqualTo(200));
      controller.dispose();
    });

    testWidgets('maxSecondPaneSize is respected', (tester) async {
      final controller = SplitViewController(initialFraction: 0.05);
      await tester.pumpWidget(
        wrap(
          SplitView(
            direction: SplitDirection.horizontal,
            controller: controller,
            maxSecondPaneSize: 200,
            first: const SizedBox(key: kFirstKey),
            second: const SizedBox(key: kSecondKey),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(secondRect(tester).width, lessThanOrEqualTo(200));
      controller.dispose();
    });

    testWidgets('min+max give exact range', (tester) async {
      final controller = SplitViewController(initialFraction: 0.5);
      await tester.pumpWidget(
        wrap(
          SplitView(
            direction: SplitDirection.horizontal,
            controller: controller,
            minFirstPaneSize: 120,
            maxFirstPaneSize: 180,
            first: const SizedBox(key: kFirstKey),
            second: const SizedBox(key: kSecondKey),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final w = firstRect(tester).width;
      expect(w, greaterThanOrEqualTo(120));
      expect(w, lessThanOrEqualTo(180));
      controller.dispose();
    });

    testWidgets('constraints clamp drag updates', (tester) async {
      final controller = SplitViewController(initialFraction: 0.5);
      await tester.pumpWidget(
        wrap(
          SplitView(
            direction: SplitDirection.horizontal,
            controller: controller,
            minFirstPaneSize: 100,
            maxFirstPaneSize: 150,
            first: const SizedBox(key: kFirstKey),
            second: const SizedBox(key: kSecondKey),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await dragDivider(tester, const Offset(500, 0));

      expect(firstRect(tester).width, lessThanOrEqualTo(150));
      controller.dispose();
    });

    testWidgets('vertical constraints apply to height', (tester) async {
      final controller = SplitViewController(initialFraction: 0.9);
      await tester.pumpWidget(
        wrap(
          SplitView(
            direction: SplitDirection.vertical,
            controller: controller,
            maxFirstPaneSize: 100,
            first: const SizedBox(key: kFirstKey),
            second: const SizedBox(key: kSecondKey),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(firstRect(tester).height, lessThanOrEqualTo(100));
      controller.dispose();
    });

    // v0.2.0 — interaction with collapse.

    testWidgets('minFirstPaneSize yields to explicit collapse', (tester) async {
      final controller = SplitViewController(initialFraction: 0.5);
      await tester.pumpWidget(
        wrap(
          SizedBox(
            width: 400,
            height: 300,
            child: SplitView(
              direction: SplitDirection.horizontal,
              controller: controller,
              minFirstPaneSize: 150,
              firstCollapsible: true,
              first: const SizedBox(key: kFirstKey),
              second: const SizedBox(key: kSecondKey),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      controller.collapseFirst(animate: false);
      await tester.pumpAndSettle();

      expect(
        firstRect(tester).width,
        0,
        reason: 'v0.2.0: collapse must override min size.',
      );
      controller.dispose();
    });

    testWidgets('minSecondPaneSize yields to explicit collapse',
        (tester) async {
      final controller = SplitViewController(initialFraction: 0.5);
      await tester.pumpWidget(
        wrap(
          SizedBox(
            width: 400,
            height: 300,
            child: SplitView(
              direction: SplitDirection.horizontal,
              controller: controller,
              minSecondPaneSize: 150,
              secondCollapsible: true,
              first: const SizedBox(key: kFirstKey),
              second: const SizedBox(key: kSecondKey),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      controller.collapseSecond(animate: false);
      await tester.pumpAndSettle();

      expect(secondRect(tester).width, 0);
      controller.dispose();
    });

    testWidgets('constraints still enforce when pane is not collapsed',
        (tester) async {
      final controller = SplitViewController(initialFraction: 0.5);
      await tester.pumpWidget(
        wrap(
          SizedBox(
            width: 400,
            height: 300,
            child: SplitView(
              direction: SplitDirection.horizontal,
              controller: controller,
              minFirstPaneSize: 120,
              firstCollapsible: false,
              first: const SizedBox(key: kFirstKey),
              second: const SizedBox(key: kSecondKey),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await dragDivider(tester, const Offset(-400, 0));

      expect(
        firstRect(tester).width,
        greaterThanOrEqualTo(120),
        reason: 'Without collapse, min size must still apply.',
      );
      controller.dispose();
    });

    testWidgets('expand after collapse restores the min-clamped size',
        (tester) async {
      final controller = SplitViewController(initialFraction: 0.5);
      await tester.pumpWidget(
        wrap(
          SizedBox(
            width: 400,
            height: 300,
            child: SplitView(
              direction: SplitDirection.horizontal,
              controller: controller,
              minFirstPaneSize: 100,
              firstCollapsible: true,
              first: const SizedBox(key: kFirstKey),
              second: const SizedBox(key: kSecondKey),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      controller.collapseFirst(animate: false);
      await tester.pumpAndSettle();
      controller.expandFirst(animate: false);
      await tester.pumpAndSettle();

      // Restored to 0.5 * 388 = 194, well above min.
      expect(firstRect(tester).width, greaterThanOrEqualTo(100));
      controller.dispose();
    });
  });
}
