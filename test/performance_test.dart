import 'package:agnostic_split_view/agnostic_split_view.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/test_helpers.dart';

// ─── Counters ───────────────────────────────────────────────────────────

class LayoutCounter {
  int count = 0;
  void increment() => count++;
  void reset() => count = 0;
}

class CountingRender extends SingleChildRenderObjectWidget {
  const CountingRender({
    super.key,
    required this.counter,
    required super.child,
  });

  final LayoutCounter counter;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _CountingRenderBox(counter);
}

class _CountingRenderBox extends RenderProxyBox {
  _CountingRenderBox(this.counter);
  final LayoutCounter counter;

  @override
  void performLayout() {
    counter.increment();
    super.performLayout();
  }
}

class BuildCounterWidget extends StatefulWidget {
  const BuildCounterWidget({
    super.key,
    required this.counter,
    required this.child,
  });

  final LayoutCounter counter;
  final Widget child;

  @override
  State<BuildCounterWidget> createState() => _BuildCounterWidgetState();
}

class _BuildCounterWidgetState extends State<BuildCounterWidget> {
  @override
  Widget build(BuildContext context) {
    widget.counter.increment();
    return widget.child;
  }
}

// ─── Drag helper ────────────────────────────────────────────────────────

Future<void> dragDividerBySteps(
  WidgetTester tester,
  Offset totalDelta, {
  int steps = 30,
}) async {
  final gesture =
      await tester.startGesture(tester.getCenter(find.byType(SplitDivider)));
  await tester.pump();
  final step = totalDelta / steps.toDouble();
  for (var i = 0; i < steps; i++) {
    await gesture.moveBy(step);
    await tester.pump();
  }
  await gesture.up();
  await tester.pumpAndSettle();
}

void main() {
  group('Layout count per drag — horizontal LTR (deferResize: false)', () {
    testWidgets('first pane layouts per 30-step drag', (tester) async {
      final counter = LayoutCounter();

      await tester.pumpWidget(
        wrap(
          SplitView(
            direction: SplitDirection.horizontal,
            deferResize: false,
            first: CountingRender(
              counter: counter,
              child: const SizedBox(key: kFirstKey),
            ),
            second: const SizedBox(key: kSecondKey),
          ),
        ),
      );
      await tester.pumpAndSettle();

      counter.reset();
      await dragDividerBySteps(tester, const Offset(80, 0));

      debugPrint('HORIZONTAL LTR (defer OFF) — layouts per 30-step drag: '
          '${counter.count}');
      expect(
        counter.count,
        greaterThanOrEqualTo(20),
        reason: 'Baseline should lay out on most drag frames '
            '(kTouchSlop eats the first ~7 frames)',
      );
      expect(
        counter.count,
        lessThanOrEqualTo(35),
        reason: '30 steps should produce ~30 layouts, not hundreds',
      );
    });
  });

  group('Layout count per drag — horizontal LTR (deferResize: true)', () {
    testWidgets('first pane layouts drop to ~1 per drag', (tester) async {
      final counter = LayoutCounter();

      await tester.pumpWidget(
        wrap(
          SplitView(
            direction: SplitDirection.horizontal,
            deferResize: true,
            first: CountingRender(
              counter: counter,
              child: const SizedBox(key: kFirstKey),
            ),
            second: const SizedBox(key: kSecondKey),
          ),
        ),
      );
      await tester.pumpAndSettle();

      counter.reset();
      await dragDividerBySteps(tester, const Offset(80, 0));

      debugPrint('HORIZONTAL LTR (defer ON) — layouts per 30-step drag: '
          '${counter.count}');
      // v0.2.0: deferResize freezes panes during drag, so the pane is
      // laid out once on release (catch-up).
      expect(
        counter.count,
        lessThanOrEqualTo(3),
        reason: 'deferResize: true should collapse ~30 layouts into 1-2.',
      );
    });
  });

  group('Layout count per drag — vertical (deferResize: false)', () {
    testWidgets('first pane layouts per 30-step drag', (tester) async {
      final counter = LayoutCounter();

      await tester.pumpWidget(
        wrap(
          SplitView(
            direction: SplitDirection.vertical,
            deferResize: false,
            first: CountingRender(
              counter: counter,
              child: const SizedBox(key: kFirstKey),
            ),
            second: const SizedBox(key: kSecondKey),
          ),
        ),
      );
      await tester.pumpAndSettle();

      counter.reset();
      await dragDividerBySteps(tester, const Offset(0, 80));

      debugPrint('VERTICAL (defer OFF) — layouts per 30-step drag: '
          '${counter.count}');
      expect(counter.count, greaterThanOrEqualTo(20));
      expect(counter.count, lessThanOrEqualTo(35));
    });
  });

  group('Layout count per drag — RTL horizontal (deferResize: false)', () {
    testWidgets('first pane layouts per 30-step drag', (tester) async {
      final counter = LayoutCounter();

      await tester.pumpWidget(
        wrap(
          SplitView(
            direction: SplitDirection.horizontal,
            deferResize: false,
            first: CountingRender(
              counter: counter,
              child: const SizedBox(key: kFirstKey),
            ),
            second: const SizedBox(key: kSecondKey),
          ),
          dir: TextDirection.rtl,
        ),
      );
      await tester.pumpAndSettle();

      counter.reset();
      await dragDividerBySteps(tester, const Offset(-80, 0));

      debugPrint('HORIZONTAL RTL (defer OFF) — layouts per 30-step drag: '
          '${counter.count}');
      expect(counter.count, greaterThanOrEqualTo(20));
      expect(counter.count, lessThanOrEqualTo(35));
    });
  });

  group('onFractionChanged call count per drag', () {
    testWidgets('30-step drag fires roughly once per step', (tester) async {
      var calls = 0;

      await tester.pumpWidget(
        wrap(
          SplitView(
            direction: SplitDirection.horizontal,
            onFractionChanged: (_) => calls++,
            first: const SizedBox(key: kFirstKey),
            second: const SizedBox(key: kSecondKey),
          ),
        ),
      );
      await tester.pumpAndSettle();

      calls = 0;
      await dragDividerBySteps(tester, const Offset(80, 0), steps: 30);

      debugPrint('onFractionChanged calls per 30-step drag: $calls');
      expect(calls, greaterThanOrEqualTo(20));
      expect(calls, lessThanOrEqualTo(32));
    });
  });

  group('Layout count after release', () {
    testWidgets('at most one catch-up layout after drag ends', (tester) async {
      final counter = LayoutCounter();

      await tester.pumpWidget(
        wrap(
          SplitView(
            direction: SplitDirection.horizontal,
            deferResize: true,
            first: CountingRender(
              counter: counter,
              child: const SizedBox(key: kFirstKey),
            ),
            second: const SizedBox(key: kSecondKey),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(SplitDivider)),
      );
      await tester.pump();
      for (var i = 0; i < 10; i++) {
        await gesture.moveBy(const Offset(4, 0));
        await tester.pump();
      }

      counter.reset();

      await gesture.up();
      await tester.pumpAndSettle();

      debugPrint('Layouts after release (defer ON): ${counter.count}');
      expect(
        counter.count,
        lessThanOrEqualTo(2),
        reason: 'Release should cause at most one catch-up layout.',
      );
    });
  });

  group('Build count — pane widgets are not rebuilt during drag', () {
    testWidgets('pane with stable widget identity is not rebuilt',
        (tester) async {
      final buildCounter = LayoutCounter();

      final firstChild = BuildCounterWidget(
        counter: buildCounter,
        child: const SizedBox(key: kFirstKey),
      );

      await tester.pumpWidget(
        wrap(
          SplitView(
            direction: SplitDirection.horizontal,
            first: firstChild,
            second: const SizedBox(key: kSecondKey),
          ),
        ),
      );
      await tester.pumpAndSettle();

      buildCounter.reset();
      await dragDividerBySteps(tester, const Offset(80, 0));

      debugPrint('Pane build count per 30-step drag: ${buildCounter.count}');
      expect(buildCounter.count, lessThanOrEqualTo(5));
    });
  });

  group('Nested splits — independent layout', () {
    testWidgets('dragging outer split relayouts inner panes', (tester) async {
      final innerCounter = LayoutCounter();
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
              first: CountingRender(
                counter: innerCounter,
                child: const SizedBox(),
              ),
              second: const SizedBox(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final outerDivider = find.byType(SplitDivider).first;
      innerCounter.reset();

      final gesture = await tester.startGesture(tester.getCenter(outerDivider));
      await tester.pump();
      for (var i = 0; i < 10; i++) {
        await gesture.moveBy(const Offset(6, 0));
        await tester.pump();
      }
      await gesture.up();
      await tester.pumpAndSettle();

      debugPrint('Inner pane layouts during outer drag: ${innerCounter.count}');
      expect(innerCounter.count, greaterThan(0));

      outer.dispose();
      inner.dispose();
    });

    testWidgets('deferResize on outer eliminates inner relayout',
        (tester) async {
      final innerCounter = LayoutCounter();
      final outer = SplitViewController(initialFraction: 0.4);
      final inner = SplitViewController(initialFraction: 0.5);

      await tester.pumpWidget(
        wrap(
          SplitView(
            direction: SplitDirection.horizontal,
            controller: outer,
            deferResize: true,
            first: const SizedBox(),
            second: SplitView(
              direction: SplitDirection.vertical,
              controller: inner,
              first: CountingRender(
                counter: innerCounter,
                child: const SizedBox(),
              ),
              second: const SizedBox(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final outerDivider = find.byType(SplitDivider).first;
      innerCounter.reset();

      final gesture = await tester.startGesture(tester.getCenter(outerDivider));
      await tester.pump();
      for (var i = 0; i < 10; i++) {
        await gesture.moveBy(const Offset(6, 0));
        await tester.pump();
      }
      await gesture.up();
      await tester.pumpAndSettle();

      debugPrint('Inner pane layouts (defer ON) during outer drag: '
          '${innerCounter.count}');
      expect(
        innerCounter.count,
        lessThanOrEqualTo(3),
        reason: 'deferResize on the outer split must prevent the inner '
            'panes from re-laying out during the drag.',
      );

      outer.dispose();
      inner.dispose();
    });
  });

  group('Baseline summary', () {
    testWidgets('records all key metrics for the changelog', (tester) async {
      final layoutCounter = LayoutCounter();
      var callbackCount = 0;

      await tester.pumpWidget(
        wrap(
          SplitView(
            direction: SplitDirection.horizontal,
            onFractionChanged: (_) => callbackCount++,
            first: CountingRender(
              counter: layoutCounter,
              child: const SizedBox(key: kFirstKey),
            ),
            second: const SizedBox(key: kSecondKey),
          ),
        ),
      );
      await tester.pumpAndSettle();

      layoutCounter.reset();
      callbackCount = 0;
      await dragDividerBySteps(tester, const Offset(80, 0), steps: 30);

      // ignore: avoid_print
      print('═══════════════════════════════════════════════════════════');
      // ignore: avoid_print
      print('PERFORMANCE BASELINE — deferResize: false (v0.1.3 default)');
      // ignore: avoid_print
      print('═══════════════════════════════════════════════════════════');
      // ignore: avoid_print
      print('Layouts per 30-step drag: ${layoutCounter.count}');
      // ignore: avoid_print
      print('onFractionChanged calls:  $callbackCount');
      // ignore: avoid_print
      print('═══════════════════════════════════════════════════════════');
      // ignore: avoid_print
      print('v0.2.0 target with deferResize: true → 1 layout per drag');
      // ignore: avoid_print
      print('═══════════════════════════════════════════════════════════');

      expect(layoutCounter.count, greaterThan(20));
    });
  });
}
