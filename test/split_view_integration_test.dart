import 'package:agnostic_split_view/agnostic_split_view.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/test_helpers.dart';

void main() {
  group('Nested splits', () {
    testWidgets('outer horizontal + inner vertical', (tester) async {
      final outer = SplitViewController(initialFraction: 0.4);
      final inner = SplitViewController(initialFraction: 0.5);

      await tester.pumpWidget(
        wrap(
          SplitView(
            direction: SplitDirection.horizontal,
            controller: outer,
            first: const SizedBox(key: kFirstKey),
            second: SplitView(
              direction: SplitDirection.vertical,
              controller: inner,
              first: const SizedBox(),
              second: const SizedBox(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SplitView), findsNWidgets(2));
      expect(firstRect(tester).width, closeTo(400 * 0.4 - 6, 4));

      outer.dispose();
      inner.dispose();
    });

    testWidgets('dragging outer does not change inner', (tester) async {
      final outer = SplitViewController(initialFraction: 0.4);
      final inner = SplitViewController(initialFraction: 0.5);

      await tester.pumpWidget(
        wrap(
          SplitView(
            direction: SplitDirection.horizontal,
            controller: outer,
            first: const SizedBox(),
            second: SplitView(
              direction: SplitDirection.vertical,
              controller: inner,
              first: const SizedBox(),
              second: const SizedBox(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Drag the outer divider.
      final outerDivider = find.byType(SplitDivider).first;
      final gesture = await tester.startGesture(tester.getCenter(outerDivider));
      await tester.pump();
      await gesture.moveBy(const Offset(60, 0));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      expect(inner.fraction, 0.5);
      outer.dispose();
      inner.dispose();
    });
  });

  group('Controller swap', () {
    testWidgets('swapping controllers resyncs', (tester) async {
      final c1 = SplitViewController(initialFraction: 0.3);
      final c2 = SplitViewController(initialFraction: 0.7);

      await tester.pumpWidget(
        wrap(
          SplitView(
            direction: SplitDirection.horizontal,
            controller: c1,
            first: const SizedBox(key: kFirstKey),
            second: const SizedBox(key: kSecondKey),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final w1 = firstRect(tester).width;

      await tester.pumpWidget(
        wrap(
          SplitView(
            direction: SplitDirection.horizontal,
            controller: c2,
            first: const SizedBox(key: kFirstKey),
            second: const SizedBox(key: kSecondKey),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final w2 = firstRect(tester).width;

      expect(w1, lessThan(w2));
      c1.dispose();
      c2.dispose();
    });
  });

  group('Reverse + RTL + vertical combinations', () {
    for (final dir in [TextDirection.ltr, TextDirection.rtl]) {
      for (final reverse in [false, true]) {
        for (final axis in [
          SplitDirection.horizontal,
          SplitDirection.vertical
        ]) {
          testWidgets('dir=$dir reverse=$reverse axis=$axis', (tester) async {
            await tester.pumpWidget(
              wrap(
                SplitView(
                  direction: axis,
                  reverse: reverse,
                  first: const SizedBox(key: kFirstKey),
                  second: const SizedBox(key: kSecondKey),
                ),
                dir: dir,
              ),
            );
            await tester.pumpAndSettle();
            // Just assert both panes render, no exceptions.
            expect(tester.takeException(), isNull);
            expect(find.byKey(kFirstKey), findsOneWidget);
            expect(find.byKey(kSecondKey), findsOneWidget);
          });
        }
      }
    }
  });

  group('Pane content types', () {
    testWidgets('works with ListView inside a pane', (tester) async {
      await tester.pumpWidget(
        wrap(
          SplitView(
            direction: SplitDirection.horizontal,
            first: ListView.builder(
              itemCount: 20,
              itemBuilder: (_, i) => Text('item $i'),
            ),
            second: const SizedBox(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('works inside a Column', (tester) async {
      await tester.pumpWidget(
        wrap(
          const Column(
            children: [
              Expanded(
                child: SplitView(
                  direction: SplitDirection.horizontal,
                  first: SizedBox(),
                  second: SizedBox(),
                ),
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
