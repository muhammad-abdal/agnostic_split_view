import 'package:agnostic_split_view/agnostic_split_view.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child, {TextDirection dir = TextDirection.ltr}) {
  return Directionality(
    textDirection: dir,
    child: MediaQuery(
      data: const MediaQueryData(),
      child: SizedBox(width: 400, height: 400, child: child),
    ),
  );
}

void main() {
  testWidgets('renders both panes', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const SplitView(
          direction: SplitDirection.horizontal,
          first: SizedBox(key: Key('first')),
          second: SizedBox(key: Key('second')),
        ),
      ),
    );
    expect(find.byKey(const Key('first')), findsOneWidget);
    expect(find.byKey(const Key('second')), findsOneWidget);
  });

  testWidgets('default divider renders', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const SplitView(
          direction: SplitDirection.horizontal,
          first: SizedBox(),
          second: SizedBox(),
        ),
      ),
    );
    expect(find.byType(SplitDivider), findsOneWidget);
  });

  testWidgets('controller setFraction updates layout', (tester) async {
    final controller = SplitViewController(initialFraction: 0.5);
    await tester.pumpWidget(
      _wrap(
        SplitView(
          direction: SplitDirection.horizontal,
          controller: controller,
          first: const SizedBox(key: Key('first')),
          second: const SizedBox(key: Key('second')),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final initialRect = tester.getRect(find.byKey(const Key('first')));

    controller.setFraction(0.25);
    await tester.pump();

    final updatedRect = tester.getRect(find.byKey(const Key('first')));
    expect(updatedRect.width, lessThan(initialRect.width));
    controller.dispose();
  });

  testWidgets('RTL flips horizontal layout', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const SplitView(
          direction: SplitDirection.horizontal,
          first: SizedBox(key: Key('first')),
          second: SizedBox(key: Key('second')),
        ),
        dir: TextDirection.rtl,
      ),
    );
    await tester.pumpAndSettle();

    final firstRect = tester.getRect(find.byKey(const Key('first')));
    final secondRect = tester.getRect(find.byKey(const Key('second')));
    expect(firstRect.left, greaterThan(secondRect.left));
  });

  testWidgets('reverse flag swaps pane positions in LTR', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const SplitView(
          direction: SplitDirection.horizontal,
          reverse: true,
          first: SizedBox(key: Key('first')),
          second: SizedBox(key: Key('second')),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final firstRect = tester.getRect(find.byKey(const Key('first')));
    final secondRect = tester.getRect(find.byKey(const Key('second')));
    expect(firstRect.left, greaterThan(secondRect.left));
  });

  testWidgets('vertical split stacks panes', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const SplitView(
          direction: SplitDirection.vertical,
          first: SizedBox(key: Key('first')),
          second: SizedBox(key: Key('second')),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final firstRect = tester.getRect(find.byKey(const Key('first')));
    final secondRect = tester.getRect(find.byKey(const Key('second')));
    expect(firstRect.top, lessThan(secondRect.top));
  });

  testWidgets('collapseFirst snaps to zero', (tester) async {
    final controller = SplitViewController(initialFraction: 0.5);
    await tester.pumpWidget(
      _wrap(
        SplitView(
          direction: SplitDirection.horizontal,
          controller: controller,
          first: const SizedBox(),
          second: const SizedBox(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    controller.collapseFirst();
    await tester.pump();
    expect(controller.fraction, 0.0);
    expect(controller.isFirstCollapsed, true);
    controller.dispose();
  });

  testWidgets('reset restores initial fraction', (tester) async {
    final controller = SplitViewController(initialFraction: 0.4);
    await tester.pumpWidget(
      _wrap(
        SplitView(
          direction: SplitDirection.horizontal,
          controller: controller,
          first: const SizedBox(),
          second: const SizedBox(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    controller.setFraction(0.8);
    await tester.pump();
    controller.reset();
    await tester.pump();
    expect(controller.fraction, 0.4);
    controller.dispose();
  });

  testWidgets('SplitViewTheme.overrideWith affects default divider',
      (tester) async {
    await tester.pumpWidget(
      _wrap(
        SplitViewTheme.overrideWith(
          data: const SplitViewTheme(
            defaultDividerStyle: SplitDividerStyle.none,
          ),
          child: const SplitView(
            direction: SplitDirection.horizontal,
            first: SizedBox(),
            second: SizedBox(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(SplitDivider), findsOneWidget);
    // The SplitDivider renders nothing when style is none.
    expect(tester.getSize(find.byType(SplitDivider)).width, 0);
  });
}
