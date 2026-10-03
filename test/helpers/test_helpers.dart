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

Future<void> dragDivider(
  WidgetTester tester,
  Offset totalDelta, {
  int steps = 10,
}) async {
  final gesture = await startDividerDrag(tester);
  final step = totalDelta / steps.toDouble();
  for (var i = 0; i < steps; i++) {
    await gesture.moveBy(step);
    await tester.pump();
  }
  await gesture.up();
  await tester.pumpAndSettle();
}

Rect firstRect(WidgetTester tester) => tester.getRect(find.byKey(kFirstKey));

Rect secondRect(WidgetTester tester) => tester.getRect(find.byKey(kSecondKey));

Rect dividerRect(WidgetTester tester) =>
    tester.getRect(find.byType(SplitDivider));
