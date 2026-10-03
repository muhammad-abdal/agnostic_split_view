import 'package:agnostic_split_view/agnostic_split_view.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // ─── Construction ────────────────────────────────────────────────────

  group('Construction', () {
    test('default initialFraction is 0.5', () {
      final c = SplitViewController();
      expect(c.fraction, 0.5);
      c.dispose();
    });

    test('initialFraction is stored as-is when in range', () {
      expect(SplitViewController(initialFraction: 0.0).fraction, 0.0);
      expect(SplitViewController(initialFraction: 0.25).fraction, 0.25);
      expect(SplitViewController(initialFraction: 0.5).fraction, 0.5);
      expect(SplitViewController(initialFraction: 0.75).fraction, 0.75);
      expect(SplitViewController(initialFraction: 1.0).fraction, 1.0);
    });

    test('initialFraction is clamped low', () {
      expect(SplitViewController(initialFraction: -0.5).fraction, 0.0);
      expect(SplitViewController(initialFraction: -100).fraction, 0.0);
    });

    test('initialFraction is clamped high', () {
      expect(SplitViewController(initialFraction: 1.5).fraction, 1.0);
      expect(SplitViewController(initialFraction: 100).fraction, 1.0);
    });

    test('initial state is not dragging', () {
      expect(SplitViewController().isDragging, false);
    });

    test('initial state is not collapsed', () {
      final c = SplitViewController(initialFraction: 0.5);
      expect(c.isFirstCollapsed, false);
      expect(c.isSecondCollapsed, false);
      c.dispose();
    });
  });

  // ─── setFraction ─────────────────────────────────────────────────────

  group('setFraction', () {
    test('updates the fraction', () {
      final c = SplitViewController(initialFraction: 0.5);
      c.setFraction(0.7);
      expect(c.fraction, 0.7);
      c.dispose();
    });

    test('clamps values above 1', () {
      final c = SplitViewController(initialFraction: 0.5);
      c.setFraction(1.5);
      expect(c.fraction, 1.0);
      c.dispose();
    });

    test('clamps values below 0', () {
      final c = SplitViewController(initialFraction: 0.5);
      c.setFraction(-0.5);
      expect(c.fraction, 0.0);
      c.dispose();
    });

    test('no-op when value is unchanged', () {
      final c = SplitViewController(initialFraction: 0.5);
      var notifications = 0;
      c.addListener(() => notifications++);
      c.setFraction(0.5);
      expect(notifications, 0);
      c.dispose();
    });

    test('no-op when unchanged value is out of range but clamps to same', () {
      final c = SplitViewController(initialFraction: 1.0);
      var notifications = 0;
      c.addListener(() => notifications++);
      c.setFraction(2.0); // clamps to 1.0, same as current
      expect(notifications, 0);
      c.dispose();
    });

    test('notifies on every distinct change', () {
      final c = SplitViewController(initialFraction: 0.5);
      var notifications = 0;
      c.addListener(() => notifications++);
      c.setFraction(0.6);
      c.setFraction(0.7);
      c.setFraction(0.8);
      expect(notifications, 3);
      c.dispose();
    });

    test('animates flag is accepted but is a no-op in v0.1.2', () {
      final c = SplitViewController(initialFraction: 0.5);
      c.setFraction(0.8, animate: true);
      expect(c.fraction, 0.8);
      c.dispose();
    });
  });

  // ─── setFirstPaneSize ────────────────────────────────────────────────

  group('setFirstPaneSize', () {
    test('no-op before attach (no geometry)', () {
      final c = SplitViewController(initialFraction: 0.5);
      c.setFirstPaneSize(200);
      expect(c.fraction, 0.5);
      c.dispose();
    });

    test('no-op when availableSize is 0', () {
      final c = SplitViewController(initialFraction: 0.5);
      c.attach(
        direction: SplitDirection.horizontal,
        reverse: false,
        firstPaneEdge: AxisDirection.right,
        availableSize: 0,
        dividerThickness: 12,
      );
      c.setFirstPaneSize(200);
      expect(c.fraction, 0.5);
      c.dispose();
    });

    test('converts pixels to fraction using attached geometry', () {
      final c = SplitViewController(initialFraction: 0.5);
      c.attach(
        direction: SplitDirection.horizontal,
        reverse: false,
        firstPaneEdge: AxisDirection.right,
        availableSize: 400,
        dividerThickness: 12,
      );
      c.setFirstPaneSize(100);
      expect(c.fraction, closeTo(0.25, 0.0001));
      c.dispose();
    });
  });

  // ─── collapseFirst / collapseSecond ──────────────────────────────────

  group('collapseFirst', () {
    test('sets fraction to 0', () {
      final c = SplitViewController(initialFraction: 0.5);
      c.collapseFirst();
      expect(c.fraction, 0.0);
      expect(c.isFirstCollapsed, true);
      c.dispose();
    });

    test('notifies listeners', () {
      final c = SplitViewController(initialFraction: 0.5);
      var notifications = 0;
      c.addListener(() => notifications++);
      c.collapseFirst();
      expect(notifications, 1);
      c.dispose();
    });

    test('no-op when already collapsed', () {
      final c = SplitViewController(initialFraction: 0.5);
      c.collapseFirst();
      var notifications = 0;
      c.addListener(() => notifications++);
      c.collapseFirst();
      expect(notifications, 0);
      c.dispose();
    });
  });

  group('collapseSecond', () {
    test('sets fraction to 1', () {
      final c = SplitViewController(initialFraction: 0.5);
      c.collapseSecond();
      expect(c.fraction, 1.0);
      expect(c.isSecondCollapsed, true);
      c.dispose();
    });

    test('notifies listeners', () {
      final c = SplitViewController(initialFraction: 0.5);
      var notifications = 0;
      c.addListener(() => notifications++);
      c.collapseSecond();
      expect(notifications, 1);
      c.dispose();
    });

    test('no-op when already collapsed', () {
      final c = SplitViewController(initialFraction: 0.5);
      c.collapseSecond();
      var notifications = 0;
      c.addListener(() => notifications++);
      c.collapseSecond();
      expect(notifications, 0);
      c.dispose();
    });
  });

  // ─── expandFirst / expandSecond ──────────────────────────────────────

  group('expandFirst', () {
    test('restores the last expanded fraction', () {
      final c = SplitViewController(initialFraction: 0.5);
      c.setFraction(0.7);
      c.collapseFirst();
      expect(c.fraction, 0.0);
      c.expandFirst();
      expect(c.fraction, 0.7);
      c.dispose();
    });

    test('no-op when not collapsed', () {
      final c = SplitViewController(initialFraction: 0.5);
      var notifications = 0;
      c.addListener(() => notifications++);
      c.expandFirst();
      expect(notifications, 0);
      expect(c.fraction, 0.5);
      c.dispose();
    });

    test('falls back to initial fraction when never expanded', () {
      final c = SplitViewController(initialFraction: 0.4);
      c.collapseFirst(); // captures 0.4 as last expanded
      c.expandFirst();
      expect(c.fraction, 0.4);
      c.dispose();
    });
  });

  group('expandSecond', () {
    test('restores the last expanded fraction', () {
      final c = SplitViewController(initialFraction: 0.5);
      c.setFraction(0.3);
      c.collapseSecond();
      c.expandSecond();
      expect(c.fraction, 0.3);
      c.dispose();
    });

    test('no-op when not collapsed', () {
      final c = SplitViewController(initialFraction: 0.5);
      var notifications = 0;
      c.addListener(() => notifications++);
      c.expandSecond();
      expect(notifications, 0);
      c.dispose();
    });
  });

  // ─── toggleFirst / toggleSecond ──────────────────────────────────────

  group('toggleFirst', () {
    test('collapses when expanded', () {
      final c = SplitViewController(initialFraction: 0.5);
      c.toggleFirst();
      expect(c.isFirstCollapsed, true);
      c.dispose();
    });

    test('expands when collapsed', () {
      final c = SplitViewController(initialFraction: 0.5);
      c.collapseFirst();
      c.toggleFirst();
      expect(c.isFirstCollapsed, false);
      expect(c.fraction, 0.5);
      c.dispose();
    });

    test('alternates on repeated calls', () {
      final c = SplitViewController(initialFraction: 0.5);
      c.toggleFirst();
      expect(c.isFirstCollapsed, true);
      c.toggleFirst();
      expect(c.isFirstCollapsed, false);
      c.toggleFirst();
      expect(c.isFirstCollapsed, true);
      c.dispose();
    });
  });

  group('toggleSecond', () {
    test('collapses when expanded', () {
      final c = SplitViewController(initialFraction: 0.5);
      c.toggleSecond();
      expect(c.isSecondCollapsed, true);
      c.dispose();
    });

    test('expands when collapsed', () {
      final c = SplitViewController(initialFraction: 0.5);
      c.collapseSecond();
      c.toggleSecond();
      expect(c.isSecondCollapsed, false);
      c.dispose();
    });
  });

  // ─── reset ───────────────────────────────────────────────────────────

  group('reset', () {
    test('restores the initial fraction', () {
      final c = SplitViewController(initialFraction: 0.3);
      c.setFraction(0.9);
      c.reset();
      expect(c.fraction, 0.3);
      c.dispose();
    });

    test('restores the initial fraction after collapse', () {
      final c = SplitViewController(initialFraction: 0.4);
      c.collapseFirst();
      c.reset();
      expect(c.fraction, 0.4);
      c.dispose();
    });

    test('no-op when already at initial fraction', () {
      final c = SplitViewController(initialFraction: 0.5);
      var notifications = 0;
      c.addListener(() => notifications++);
      c.reset();
      expect(notifications, 0);
      c.dispose();
    });
  });

  // ─── Collapsed flags ─────────────────────────────────────────────────

  group('isFirstCollapsed / isSecondCollapsed', () {
    test('both false at initial 0.5', () {
      final c = SplitViewController(initialFraction: 0.5);
      expect(c.isFirstCollapsed, false);
      expect(c.isSecondCollapsed, false);
      c.dispose();
    });

    test('isFirstCollapsed true when fraction <= 0.0001', () {
      final c = SplitViewController(initialFraction: 0.5);
      c.setFraction(0.00005);
      expect(c.isFirstCollapsed, true);
      c.dispose();
    });

    test('isSecondCollapsed true when fraction >= 0.9999', () {
      final c = SplitViewController(initialFraction: 0.5);
      c.setFraction(0.99995);
      expect(c.isSecondCollapsed, true);
      c.dispose();
    });

    test('mutually exclusive at extremes', () {
      final c = SplitViewController(initialFraction: 0.5);
      c.collapseFirst();
      expect(c.isFirstCollapsed, true);
      expect(c.isSecondCollapsed, false);
      c.collapseSecond();
      expect(c.isFirstCollapsed, false);
      expect(c.isSecondCollapsed, true);
      c.dispose();
    });
  });

  // ─── Geometry ────────────────────────────────────────────────────────

  group('Geometry before attach', () {
    test('firstPaneSize is 0', () {
      expect(SplitViewController().firstPaneSize, 0);
    });

    test('secondPaneSize is 0', () {
      expect(SplitViewController().secondPaneSize, 0);
    });

    test('availableSize is 0', () {
      expect(SplitViewController().availableSize, 0);
    });

    test('direction is null', () {
      expect(SplitViewController().direction, null);
    });

    test('reverse is null', () {
      expect(SplitViewController().reverse, null);
    });

    test('firstPaneEdge is null', () {
      expect(SplitViewController().firstPaneEdge, null);
    });
  });

  group('Geometry after attach', () {
    test('fraction unchanged by attach', () {
      final c = SplitViewController(initialFraction: 0.4);
      c.attach(
        direction: SplitDirection.horizontal,
        reverse: false,
        firstPaneEdge: AxisDirection.right,
        availableSize: 400,
        dividerThickness: 12,
      );
      expect(c.fraction, 0.4);
      c.dispose();
    });

    test('direction is exposed after attach', () {
      final c = SplitViewController();
      c.attach(
        direction: SplitDirection.vertical,
        reverse: false,
        firstPaneEdge: AxisDirection.down,
        availableSize: 400,
        dividerThickness: 12,
      );
      expect(c.direction, SplitDirection.vertical);
      c.dispose();
    });

    test('reverse is exposed after attach', () {
      final c = SplitViewController();
      c.attach(
        direction: SplitDirection.horizontal,
        reverse: true,
        firstPaneEdge: AxisDirection.left,
        availableSize: 400,
        dividerThickness: 12,
      );
      expect(c.reverse, true);
      c.dispose();
    });

    test('firstPaneEdge is exposed after attach', () {
      final c = SplitViewController();
      c.attach(
        direction: SplitDirection.horizontal,
        reverse: false,
        firstPaneEdge: AxisDirection.right,
        availableSize: 400,
        dividerThickness: 12,
      );
      expect(c.firstPaneEdge, AxisDirection.right);
      c.dispose();
    });

    test('firstPaneSize = availableSize * fraction', () {
      final c = SplitViewController(initialFraction: 0.25);
      c.attach(
        direction: SplitDirection.horizontal,
        reverse: false,
        firstPaneEdge: AxisDirection.right,
        availableSize: 400,
        dividerThickness: 12,
      );
      expect(c.firstPaneSize, 100);
      c.dispose();
    });

    test('secondPaneSize = availableSize * (1 - fraction)', () {
      final c = SplitViewController(initialFraction: 0.25);
      c.attach(
        direction: SplitDirection.horizontal,
        reverse: false,
        firstPaneEdge: AxisDirection.right,
        availableSize: 400,
        dividerThickness: 12,
      );
      expect(c.secondPaneSize, 300);
      c.dispose();
    });

    test('availableSize is exposed after attach', () {
      final c = SplitViewController();
      c.attach(
        direction: SplitDirection.horizontal,
        reverse: false,
        firstPaneEdge: AxisDirection.right,
        availableSize: 388,
        dividerThickness: 12,
      );
      expect(c.availableSize, 388);
      c.dispose();
    });

    test('attach does not notify listeners', () {
      final c = SplitViewController();
      var notifications = 0;
      c.addListener(() => notifications++);
      c.attach(
        direction: SplitDirection.horizontal,
        reverse: false,
        firstPaneEdge: AxisDirection.right,
        availableSize: 400,
        dividerThickness: 12,
      );
      expect(notifications, 0);
      c.dispose();
    });

    test('re-attach with same geometry is a no-op', () {
      final c = SplitViewController();
      c.attach(
        direction: SplitDirection.horizontal,
        reverse: false,
        firstPaneEdge: AxisDirection.right,
        availableSize: 400,
        dividerThickness: 12,
      );
      // Re-attach with identical values.
      c.attach(
        direction: SplitDirection.horizontal,
        reverse: false,
        firstPaneEdge: AxisDirection.right,
        availableSize: 400,
        dividerThickness: 12,
      );
      expect(c.availableSize, 400);
      c.dispose();
    });

    test('re-attach with different geometry updates', () {
      final c = SplitViewController();
      c.attach(
        direction: SplitDirection.horizontal,
        reverse: false,
        firstPaneEdge: AxisDirection.right,
        availableSize: 400,
        dividerThickness: 12,
      );
      c.attach(
        direction: SplitDirection.vertical,
        reverse: false,
        firstPaneEdge: AxisDirection.down,
        availableSize: 500,
        dividerThickness: 16,
      );
      expect(c.availableSize, 500);
      expect(c.direction, SplitDirection.vertical);
      c.dispose();
    });
  });

  // ─── detach ──────────────────────────────────────────────────────────

  group('detach', () {
    test('clears geometry', () {
      final c = SplitViewController();
      c.attach(
        direction: SplitDirection.horizontal,
        reverse: false,
        firstPaneEdge: AxisDirection.right,
        availableSize: 400,
        dividerThickness: 12,
      );
      c.detach();
      expect(c.availableSize, 0);
      expect(c.direction, null);
      expect(c.reverse, null);
      expect(c.firstPaneEdge, null);
      c.dispose();
    });

    test('no-op when never attached', () {
      final c = SplitViewController();
      c.detach();
      expect(c.availableSize, 0);
      c.dispose();
    });

    test('resets isDragging to false', () {
      final c = SplitViewController();
      c.setDragging(true);
      expect(c.isDragging, true);
      c.detach();
      expect(c.isDragging, false);
      c.dispose();
    });
  });

  // ─── setDragging ─────────────────────────────────────────────────────

  group('setDragging', () {
    test('sets the dragging state', () {
      final c = SplitViewController();
      c.setDragging(true);
      expect(c.isDragging, true);
      c.setDragging(false);
      expect(c.isDragging, false);
      c.dispose();
    });

    test('notifies on change', () {
      final c = SplitViewController();
      var notifications = 0;
      c.addListener(() => notifications++);
      c.setDragging(true);
      expect(notifications, 1);
      c.dispose();
    });

    test('no-op when value unchanged', () {
      final c = SplitViewController();
      c.setDragging(true);
      var notifications = 0;
      c.addListener(() => notifications++);
      c.setDragging(true);
      expect(notifications, 0);
      c.dispose();
    });
  });

  // ─── Post-dispose behavior ───────────────────────────────────────────

  group('Post-dispose behavior (v0.1.2)', () {
    test('fraction is still readable after dispose', () {
      final c = SplitViewController(initialFraction: 0.42);
      c.dispose();
      expect(c.fraction, 0.42);
    });

    test('same-value setFraction after dispose is safe', () {
      final c = SplitViewController(initialFraction: 0.5);
      c.dispose();
      // Same value, so no notifyListeners call, so no debug assert.
      c.setFraction(0.5);
      expect(c.fraction, 0.5);
    });

    test('isDragging is false after dispose', () {
      final c = SplitViewController();
      c.setDragging(true);
      c.dispose();
      // Can't call setDragging(false) safely after dispose, but state is
      // still readable.
      expect(c.isDragging, true);
    });
  });

  // ─── Command interactions ────────────────────────────────────────────

  group('Command interactions', () {
    test('collapse then expand preserves last user fraction', () {
      final c = SplitViewController(initialFraction: 0.5);
      c.setFraction(0.35);
      c.collapseFirst();
      c.expandFirst();
      expect(c.fraction, 0.35);
      c.dispose();
    });

    test('multiple collapse/expand cycles preserve last user fraction', () {
      final c = SplitViewController(initialFraction: 0.5);
      c.setFraction(0.7);
      c.collapseFirst();
      c.expandFirst();
      c.setFraction(0.6);
      c.collapseFirst();
      c.expandFirst();
      expect(c.fraction, 0.6);
      c.dispose();
    });

    test('collapseFirst then collapseSecond keeps last expanded', () {
      final c = SplitViewController(initialFraction: 0.5);
      c.setFraction(0.4);
      c.collapseFirst();
      c.collapseSecond();
      c.expandFirst();
      // expandFirst after collapseSecond: fraction is 1.0, not 0.
      // expandFirst is a no-op when not collapsed.
      expect(c.fraction, 1.0);
      c.dispose();
    });

    test('reset after collapse restores initial', () {
      final c = SplitViewController(initialFraction: 0.3);
      c.collapseFirst();
      c.reset();
      expect(c.fraction, 0.3);
      c.dispose();
    });

    test('setFraction to exact 0 sets isFirstCollapsed', () {
      final c = SplitViewController(initialFraction: 0.5);
      c.setFraction(0.0);
      expect(c.isFirstCollapsed, true);
      c.dispose();
    });

    test('setFraction to exact 1 sets isSecondCollapsed', () {
      final c = SplitViewController(initialFraction: 0.5);
      c.setFraction(1.0);
      expect(c.isSecondCollapsed, true);
      c.dispose();
    });
  });
}
