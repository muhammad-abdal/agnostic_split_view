import 'package:agnostic_split_view/agnostic_split_view.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/test_helpers.dart';

void main() {
  group('Divider styles render without errors', () {
    for (final style in SplitDividerStyle.values) {
      testWidgets('style $style', (tester) async {
        await tester.pumpWidget(
          wrap(
            SplitView(
              direction: SplitDirection.horizontal,
              dividerStyle: style,
              first: const SizedBox(),
              second: const SizedBox(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('Divider sizes', () {
    for (final size in SplitDividerSize.values) {
      testWidgets('size $size renders', (tester) async {
        await tester.pumpWidget(
          wrap(
            SplitView(
              direction: SplitDirection.horizontal,
              dividerSize: size,
              first: const SizedBox(),
              second: const SizedBox(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(SplitDivider), findsOneWidget);
      });
    }
  });

  group('Custom divider builder', () {
    testWidgets('receives state with correct direction', (tester) async {
      SplitViewDividerState? captured;
      await tester.pumpWidget(
        wrap(
          SplitView(
            direction: SplitDirection.vertical,
            dividerBuilder: (_, state) {
              captured = state;
              return const SizedBox();
            },
            first: const SizedBox(),
            second: const SizedBox(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(captured, isNotNull);
      expect(captured!.direction, SplitDirection.vertical);
      expect(captured!.isVerticalDivider, false);
      expect(captured!.isHorizontalDivider, true);
    });

    testWidgets('state reports dragging during drag', (tester) async {
      SplitViewDividerState? captured;
      await tester.pumpWidget(
        wrap(
          SplitView(
            direction: SplitDirection.horizontal,
            dividerBuilder: (_, state) {
              captured = state;
              return const SizedBox(key: Key('custom-divider'));
            },
            first: const SizedBox(),
            second: const SizedBox(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(captured!.isDragging, false);

      final gesture = await tester.startGesture(
        tester.getCenter(find.byKey(const Key('custom-divider'))),
      );
      await tester.pump();
      await gesture.moveBy(const Offset(30, 0));
      await tester.pump();
      expect(captured!.isDragging, true);

      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('thickness matches widget config', (tester) async {
      SplitViewDividerState? captured;
      await tester.pumpWidget(
        wrap(
          SplitView(
            direction: SplitDirection.horizontal,
            dividerThickness: 24,
            dividerBuilder: (_, state) {
              captured = state;
              return const SizedBox();
            },
            first: const SizedBox(),
            second: const SizedBox(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(captured!.thickness, 24);
    });
  });
}
