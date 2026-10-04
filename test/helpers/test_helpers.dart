import 'package:agnostic_split_view/agnostic_split_view.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

const kSize = Size(400, 400);
const kFirstKey = Key('first');
const kSecondKey = Key('second');

Widget wrap(
  Widget child, {
  TextDirection dir = TextDirection.ltr,
  Size size = kSize,
}) {
  return Directionality(
    textDirection: dir,
    child: MediaQuery(
      data: const MediaQueryData(),
      child: Center(
        child: SizedBox(
          width: size.width,
          height: size.height,
          child: child,
        ),
      ),
    ),
  );
}

Future<TestGesture> startDividerDrag(WidgetTester tester) async {
  final gesture = await tester.startGesture(
    tester.getCenter(find.byType(SplitDivider)),
  );
  await tester.pump();
  return gesture;
}

/// Moves [gesture] by [totalDelta] in [steps] equal moves, pumping
/// after each. Use this to test mid-drag state — a single `moveBy`
/// is consumed by `kTouchSlop` and produces no drag update.
Future<void> moveDragInSteps(
  WidgetTester tester,
  TestGesture gesture,
  Offset totalDelta, {
  int steps = 10,
}) async {
  final step = totalDelta / steps.toDouble();
  for (var i = 0; i < steps; i++) {
    await gesture.moveBy(step);
    await tester.pump();
  }
}

Future<void> dragDivider(
  WidgetTester tester,
  Offset totalDelta, {
  int steps = 10,
}) async {
  final gesture = await startDividerDrag(tester);
  await moveDragInSteps(tester, gesture, totalDelta, steps: steps);
  await gesture.up();
  await tester.pumpAndSettle();
}

Rect firstRect(WidgetTester tester) => tester.getRect(find.byKey(kFirstKey));

Rect secondRect(WidgetTester tester) => tester.getRect(find.byKey(kSecondKey));

Rect dividerRect(WidgetTester tester) =>
    tester.getRect(find.byType(SplitDivider));

/// Returns the first ancestor of [childKey] matching widget type [T],
/// or null if none exists. Useful for asserting RepaintBoundary
/// wrapping introduced by `isolatePanes`.
Finder? findAncestorOfType<T extends Widget>(
  WidgetTester tester,
  Key childKey,
) {
  final matches = find.ancestor(
    of: find.byKey(childKey),
    matching: find.byType(T),
  );
  return matches.evaluate().isEmpty ? null : matches;
}
