import 'package:agnostic_split_view/agnostic_split_view.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/test_helpers.dart';

void main() {
  group('Layout', () {
    testWidgets('renders both panes', (tester) async {
      await tester.pumpWidget(wrap(const SplitView(
        direction: SplitDirection.horizontal,
        first: SizedBox(key: kFirstKey),
        second: SizedBox(key: kSecondKey),
      )));
      expect(find.byKey(kFirstKey), findsOneWidget);
      expect(find.byKey(kSecondKey), findsOneWidget);
    });

    testWidgets('default divider is present', (tester) async {
      await tester.pumpWidget(wrap(const SplitView(
        direction: SplitDirection.horizontal,
        first: SizedBox(),
        second: SizedBox(),
      )));
      expect(find.byType(SplitDivider), findsOneWidget);
    });

    testWidgets('horizontal: panes are side by side', (tester) async {
      await tester.pumpWidget(wrap(const SplitView(
        direction: SplitDirection.horizontal,
        first: SizedBox(key: kFirstKey),
        second: SizedBox(key: kSecondKey),
      )));
      await tester.pumpAndSettle();
      expect(
          firstRect(tester).right, lessThanOrEqualTo(secondRect(tester).left));
    });

    testWidgets('vertical: panes are stacked', (tester) async {
      await tester.pumpWidget(wrap(const SplitView(
        direction: SplitDirection.vertical,
        first: SizedBox(key: kFirstKey),
        second: SizedBox(key: kSecondKey),
      )));
      await tester.pumpAndSettle();
      expect(
          firstRect(tester).bottom, lessThanOrEqualTo(secondRect(tester).top));
    });

    testWidgets('initialFraction controls initial sizes', (tester) async {
      await tester.pumpWidget(wrap(const SplitView(
        direction: SplitDirection.horizontal,
        initialFraction: 0.25,
        first: SizedBox(key: kFirstKey),
        second: SizedBox(key: kSecondKey),
      )));
      await tester.pumpAndSettle();
      // 400px wide, 12px divider, 0.25 of 388 ≈ 97.
      expect(firstRect(tester).width, closeTo(97, 2));
    });

    testWidgets('custom divider replaces default', (tester) async {
      const customKey = Key('custom-divider');
      await tester.pumpWidget(wrap(SplitView(
        direction: SplitDirection.horizontal,
        dividerBuilder: (_, __) => const SizedBox(key: customKey),
        first: const SizedBox(),
        second: const SizedBox(),
      )));
      expect(find.byKey(customKey), findsOneWidget);
      expect(find.byType(SplitDivider), findsNothing);
    });

    testWidgets('pane sizes sum plus divider equals total width',
        (tester) async {
      await tester.pumpWidget(wrap(const SplitView(
        direction: SplitDirection.horizontal,
        dividerThickness: 20,
        first: SizedBox(key: kFirstKey),
        second: SizedBox(key: kSecondKey),
      )));
      await tester.pumpAndSettle();
      final sum = firstRect(tester).width +
          secondRect(tester).width +
          dividerRect(tester).width;
      expect(sum, closeTo(400, 0.5));
    });
  });
}
