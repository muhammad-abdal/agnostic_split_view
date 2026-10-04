import 'package:agnostic_split_view/agnostic_split_view.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/test_helpers.dart';

Widget _build({required TextDirection dir, required bool reverse}) {
  return wrap(
    SplitView(
      direction: SplitDirection.horizontal,
      reverse: reverse,
      first: const SizedBox(key: kFirstKey),
      second: const SizedBox(key: kSecondKey),
    ),
    dir: dir,
  );
}

void main() {
  group('Horizontal directionality', () {
    testWidgets('LTR, reverse=false: first on left', (tester) async {
      await tester.pumpWidget(_build(dir: TextDirection.ltr, reverse: false));
      await tester.pumpAndSettle();
      expect(firstRect(tester).left, lessThan(secondRect(tester).left));
    });

    testWidgets('LTR, reverse=true: first on right', (tester) async {
      await tester.pumpWidget(_build(dir: TextDirection.ltr, reverse: true));
      await tester.pumpAndSettle();
      expect(firstRect(tester).left, greaterThan(secondRect(tester).left));
    });

    testWidgets('RTL, reverse=false: first on right', (tester) async {
      await tester.pumpWidget(_build(dir: TextDirection.rtl, reverse: false));
      await tester.pumpAndSettle();
      expect(firstRect(tester).left, greaterThan(secondRect(tester).left));
    });

    testWidgets('RTL, reverse=true: first on left', (tester) async {
      await tester.pumpWidget(_build(dir: TextDirection.rtl, reverse: true));
      await tester.pumpAndSettle();
      expect(firstRect(tester).left, lessThan(secondRect(tester).left));
    });
  });

  group('Vertical ignores RTL', () {
    testWidgets('LTR: first on top', (tester) async {
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
      expect(firstRect(tester).top, lessThan(secondRect(tester).top));
    });

    testWidgets('RTL: still first on top', (tester) async {
      await tester.pumpWidget(
        wrap(
          const SplitView(
            direction: SplitDirection.vertical,
            first: SizedBox(key: kFirstKey),
            second: SizedBox(key: kSecondKey),
          ),
          dir: TextDirection.rtl,
        ),
      );
      await tester.pumpAndSettle();
      expect(firstRect(tester).top, lessThan(secondRect(tester).top));
    });

    testWidgets('vertical reverse=true: first on bottom in both dirs',
        (tester) async {
      for (final dir in [TextDirection.ltr, TextDirection.rtl]) {
        await tester.pumpWidget(
          wrap(
            const SplitView(
              direction: SplitDirection.vertical,
              reverse: true,
              first: SizedBox(key: kFirstKey),
              second: SizedBox(key: kSecondKey),
            ),
            dir: dir,
          ),
        );
        await tester.pumpAndSettle();
        expect(
          firstRect(tester).top,
          greaterThan(secondRect(tester).top),
          reason: 'failed for dir=$dir',
        );
      }
    });
  });
}
