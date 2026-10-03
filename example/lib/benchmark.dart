import 'dart:async';
import 'dart:math' as math;

import 'package:agnostic_split_view/agnostic_split_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

// ─── Palette matching demo_shell.dart ──────────────────────────────────

const _kBackground = Color(0xFF08090C);
const _kPanel = Color(0xFF0D0F13);
const _kPanelAlt = Color(0xFF0B0D11);
const _kAccent = Color(0xFFC8FF00);
const _kBorderSide = Color(0x0FFFFFFF);

// ─── Frame statistics ──────────────────────────────────────────────────

class FrameStats {
  final List<double> _buildMs = [];
  final List<double> _rasterMs = [];

  void add(FrameTiming t) {
    _buildMs.add(t.buildDuration.inMicroseconds / 1000.0);
    _rasterMs.add(t.rasterDuration.inMicroseconds / 1000.0);
  }

  void clear() {
    _buildMs.clear();
    _rasterMs.clear();
  }

  int get count => _buildMs.length;

  double _pct(List<double> xs, double p) {
    if (xs.isEmpty) return 0;
    final sorted = [...xs]..sort();
    final idx = ((sorted.length - 1) * p).round();
    return sorted[idx];
  }

  double get buildP50 => _pct(_buildMs, 0.50);
  double get buildP95 => _pct(_buildMs, 0.95);
  double get buildP99 => _pct(_buildMs, 0.99);
  double get buildMax => _buildMs.isEmpty ? 0 : _buildMs.reduce(math.max);

  double get rasterP50 => _pct(_rasterMs, 0.50);
  double get rasterP95 => _pct(_rasterMs, 0.95);
  double get rasterP99 => _pct(_rasterMs, 0.99);
  double get rasterMax => _rasterMs.isEmpty ? 0 : _rasterMs.reduce(math.max);

  double jankPercent60Hz() {
    if (_buildMs.isEmpty) return 0;
    var janky = 0;
    for (var i = 0; i < _buildMs.length; i++) {
      if (_buildMs[i] + _rasterMs[i] > 16.67) janky++;
    }
    return janky * 100.0 / _buildMs.length;
  }

  double jankPercent120Hz() {
    if (_buildMs.isEmpty) return 0;
    var janky = 0;
    for (var i = 0; i < _buildMs.length; i++) {
      if (_buildMs[i] + _rasterMs[i] > 8.33) janky++;
    }
    return janky * 100.0 / _buildMs.length;
  }
}

// ─── Benchmark modes ───────────────────────────────────────────────────

enum BenchmarkMode { light, heavy, extreme, tree }

// ─── Benchmark page ────────────────────────────────────────────────────

/// Frame-timing benchmark page.
///
/// Run with `flutter run --profile` for accurate numbers.
///
/// Compare `DEFER OFF` (v0.1.3 behavior) with `DEFER ON` (v0.2.0) by
/// running the same mode twice — the results panel shows which mode was
/// active when the run completed.
class BenchmarkPage extends StatefulWidget {
  const BenchmarkPage({super.key});

  @override
  State<BenchmarkPage> createState() => _BenchmarkPageState();
}

class _BenchmarkPageState extends State<BenchmarkPage> {
  final _controller = SplitViewController(initialFraction: 0.5);
  final List<SplitViewController> _treeControllers = [];

  final _stats = FrameStats();
  bool _collecting = false;
  BenchmarkMode _mode = BenchmarkMode.light;
  bool _deferResize = true;
  bool _hasResult = false;
  String _resultMode = '';
  bool _resultDefer = false;

  @override
  void initState() {
    super.initState();
    for (var i = 0; i < 7; i++) {
      _treeControllers.add(SplitViewController(initialFraction: 0.5));
    }

    SchedulerBinding.instance.addTimingsCallback((timings) {
      if (!_collecting) return;
      for (final t in timings) {
        _stats.add(t);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    for (final c in _treeControllers) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _runBenchmark() async {
    setState(() {
      _stats.clear();
      _collecting = true;
      _hasResult = false;
    });

    // Warm-up: let the engine stabilize before sampling.
    await Future<void>.delayed(const Duration(milliseconds: 300));

    const cycles = 30;
    final targetController =
        _mode == BenchmarkMode.tree ? _treeControllers.first : _controller;

    // Simulate the drag lifecycle so deferResize actually engages.
    targetController.setDragging(true);

    for (var i = 0; i < cycles; i++) {
      targetController.setFraction(i.isEven ? 0.25 : 0.75);
      await Future<void>.delayed(const Duration(milliseconds: 16));
    }

    targetController.setDragging(false);

    // Let the last frame settle.
    await Future<void>.delayed(const Duration(milliseconds: 200));

    setState(() {
      _collecting = false;
      _hasResult = true;
      _resultMode = _mode.name;
      _resultDefer = _deferResize;
    });
  }

  // ─── Content builders ────────────────────────────────────────────────

  Widget _buildHeavyContent(String label, int itemCount) {
    return Container(
      color: _kPanel,
      child: ListView.builder(
        itemCount: itemCount,
        itemBuilder: (_, i) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.02),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: _kAccent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.person_rounded,
                        size: 18,
                        color: _kAccent,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$label Doc #$i',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withValues(alpha: 0.85),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Created $i days ago',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.white.withValues(alpha: 0.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.more_vert_rounded,
                      size: 16,
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Sample document description for item $i. '
                  'Simulates real content to increase rendering complexity.',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.5),
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _TagChip(label: 'Tag ${i % 5}'),
                    _TagChip(label: 'Cat ${i % 3}'),
                    if (i % 2 == 0) const _TagChip(label: 'Priority'),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: (i % 100) / 100.0,
                  backgroundColor: Colors.white.withValues(alpha: 0.05),
                  valueColor:
                      AlwaysStoppedAnimation(_kAccent.withValues(alpha: 0.6)),
                  minHeight: 3,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Recursively builds a binary tree of SplitViews.
  /// Depth 3 = 7 SplitViews and 8 leaf panes.
  ///
  /// When `_deferResize` is true, every nested SplitView gets
  /// `deferResize: true` — this is the case v0.2.0 is designed for.
  Widget _buildBinaryTree(int depth, int maxDepth, int controllerIndex) {
    if (depth >= maxDepth) {
      return _buildHeavyContent('Leaf $controllerIndex', 500);
    }

    final direction =
        depth.isEven ? SplitDirection.horizontal : SplitDirection.vertical;

    return SplitView(
      direction: direction,
      controller: _treeControllers[controllerIndex],
      dividerThickness: 8,
      deferResize: _deferResize,
      first: _buildBinaryTree(depth + 1, maxDepth, controllerIndex * 2 + 1),
      second: _buildBinaryTree(depth + 1, maxDepth, controllerIndex * 2 + 2),
    );
  }

  Widget _buildPane(String label, {required BenchmarkMode mode}) {
    switch (mode) {
      case BenchmarkMode.light:
        return Container(
          color: _kPanel,
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.55),
              fontSize: 13,
            ),
          ),
        );
      case BenchmarkMode.heavy:
        return _buildHeavyContent(label, 2000);
      case BenchmarkMode.extreme:
        return _buildHeavyContent(label, 10000);
      case BenchmarkMode.tree:
        return _buildBinaryTree(0, 3, 0);
    }
  }

  // ─── Build ────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      body: SafeArea(
        child: Column(
          children: [
            _PaneHeader(
              title: 'BENCHMARK',
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Chips + toggle are locked while a run is in progress
                  // so the results panel always reports the config that
                  // actually produced the numbers.
                  IgnorePointer(
                    ignoring: _collecting,
                    child: Opacity(
                      opacity: _collecting ? 0.5 : 1.0,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _ModeChip(
                            label: 'LIGHT',
                            active: _mode == BenchmarkMode.light,
                            onTap: () =>
                                setState(() => _mode = BenchmarkMode.light),
                          ),
                          const SizedBox(width: 6),
                          _ModeChip(
                            label: 'HEAVY',
                            active: _mode == BenchmarkMode.heavy,
                            onTap: () =>
                                setState(() => _mode = BenchmarkMode.heavy),
                          ),
                          const SizedBox(width: 6),
                          _ModeChip(
                            label: 'EXTREME',
                            active: _mode == BenchmarkMode.extreme,
                            onTap: () =>
                                setState(() => _mode = BenchmarkMode.extreme),
                          ),
                          const SizedBox(width: 6),
                          _ModeChip(
                            label: 'TREE',
                            active: _mode == BenchmarkMode.tree,
                            onTap: () =>
                                setState(() => _mode = BenchmarkMode.tree),
                          ),
                          const SizedBox(width: 14),
                          _DeferToggle(
                            on: _deferResize,
                            onTap: () =>
                                setState(() => _deferResize = !_deferResize),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  _RunButton(
                    running: _collecting,
                    onTap: _collecting ? null : _runBenchmark,
                  ),
                ],
              ),
            ),
            Expanded(
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: _mode == BenchmarkMode.tree
                        ? _buildBinaryTree(0, 3, 0)
                        : SplitView(
                            direction: SplitDirection.horizontal,
                            controller: _controller,
                            minFirstPaneSize: 120,
                            maxFirstPaneSize: 400,
                            dividerThickness: 14,
                            deferResize: _deferResize,
                            dividerBuilder: (context, state) =>
                                _BenchmarkDivider(state: state),
                            first: _buildPane('Pane A', mode: _mode),
                            second: _buildPane('Pane B', mode: _mode),
                          ),
                  ),
                  if (_hasResult)
                    Positioned(
                      left: 12,
                      right: 12,
                      bottom: 12,
                      child: _ResultsPanel(
                        stats: _stats,
                        mode: _resultMode,
                        deferResize: _resultDefer,
                        onDismiss: () => setState(() => _hasResult = false),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── UI building blocks ────────────────────────────────────────────────

class _TagChip extends StatelessWidget {
  const _TagChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          color: Colors.white.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}

class _PaneHeader extends StatelessWidget {
  const _PaneHeader({required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: const BoxDecoration(
        color: _kPanel,
        border: Border(bottom: BorderSide(color: _kBorderSide)),
      ),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.6,
              color: Colors.white.withValues(alpha: 0.55),
            ),
          ),
          const Spacer(),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  const _ModeChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: active
              ? _kAccent.withValues(alpha: 0.12)
              : Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: active ? _kAccent.withValues(alpha: 0.35) : _kBorderSide,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: active ? _kAccent : Colors.white.withValues(alpha: 0.45),
          ),
        ),
      ),
    );
  }
}

/// v0.2.0 — a two-state toggle between `DEFER OFF` (v0.1.3) and
/// `DEFER ON` (v0.2.0's deferred-resize mode).
class _DeferToggle extends StatelessWidget {
  const _DeferToggle({required this.on, required this.onTap});

  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: on
              ? _kAccent.withValues(alpha: 0.15)
              : const Color(0xFF2A1616).withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: on
                ? _kAccent.withValues(alpha: 0.4)
                : const Color(0xFFFF6B6B).withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'DEFER',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: on
                    ? _kAccent
                    : const Color(0xFFFF6B6B).withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              width: 22,
              height: 12,
              decoration: BoxDecoration(
                color: on ? _kAccent : Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(99),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 150),
                alignment: on ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 9,
                  height: 9,
                  margin: const EdgeInsets.symmetric(horizontal: 1.5),
                  decoration: const BoxDecoration(
                    color: _kBackground,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RunButton extends StatelessWidget {
  const _RunButton({required this.running, this.onTap});

  final bool running;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        decoration: BoxDecoration(
          color: running
              ? _kAccent.withValues(alpha: 0.08)
              : _kAccent.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: _kAccent.withValues(alpha: 0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (running) ...[
              const SizedBox(
                width: 10,
                height: 10,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  valueColor: AlwaysStoppedAnimation(_kAccent),
                ),
              ),
              const SizedBox(width: 8),
            ] else ...[
              const Icon(Icons.play_arrow_rounded, size: 12, color: _kAccent),
              const SizedBox(width: 6),
            ],
            Text(
              running ? 'RUNNING' : 'RUN',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: _kAccent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BenchmarkDivider extends StatelessWidget {
  const _BenchmarkDivider({required this.state});
  final SplitViewDividerState state;

  @override
  Widget build(BuildContext context) {
    return SplitDivider(
      state: state,
      style: SplitDividerStyle.floating,
      size: SplitDividerSize.custom,
      hitAreaThickness: 14,
      lineThickness: 3,
      color: Colors.white.withValues(alpha: 0.08),
      hoverColor: _kAccent,
      dragColor: _kAccent,
      borderRadius: BorderRadius.circular(99),
      animationDuration: const Duration(milliseconds: 160),
    );
  }
}

class _ResultsPanel extends StatelessWidget {
  const _ResultsPanel({
    required this.stats,
    required this.mode,
    required this.deferResize,
    required this.onDismiss,
  });

  final FrameStats stats;
  final String mode;
  final bool deferResize;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _kPanelAlt,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorderSide),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _kAccent,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _kAccent.withValues(alpha: 0.4),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'PERFORMANCE METRICS',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.6,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _kAccent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(color: _kAccent.withValues(alpha: 0.2)),
                  ),
                  child: Text(
                    mode.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                      color: _kAccent,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: deferResize
                        ? _kAccent.withValues(alpha: 0.15)
                        : const Color(0xFFFF6B6B).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(
                      color: deferResize
                          ? _kAccent.withValues(alpha: 0.3)
                          : const Color(0xFFFF6B6B).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    deferResize ? 'DEFER ON' : 'DEFER OFF',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                      color: deferResize ? _kAccent : const Color(0xFFFF6B6B),
                    ),
                  ),
                ),
                const Spacer(),
                InkWell(
                  onTap: onDismiss,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: _kBorderSide),

          // Metrics Grid
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _MetricColumn(
                    title: 'BUILD TIME',
                    subtitle: 'Dart UI construction',
                    p50: stats.buildP50,
                    p95: stats.buildP95,
                    p99: stats.buildP99,
                    max: stats.buildMax,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MetricColumn(
                    title: 'RASTER TIME',
                    subtitle: 'GPU painting & composition',
                    p50: stats.rasterP50,
                    p95: stats.rasterP95,
                    p99: stats.rasterP99,
                    max: stats.rasterMax,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _JankColumn(
                    frames: stats.count,
                    jank60: stats.jankPercent60Hz(),
                    jank120: stats.jankPercent120Hz(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricColumn extends StatelessWidget {
  const _MetricColumn({
    required this.title,
    required this.subtitle,
    required this.p50,
    required this.p95,
    required this.p99,
    required this.max,
  });

  final String title;
  final String subtitle;
  final double p50;
  final double p95;
  final double p99;
  final double max;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kBorderSide),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 9,
                  color: Colors.white.withValues(alpha: 0.4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: _kBorderSide),
          const SizedBox(height: 10),
          _StatRow(label: 'p50', value: p50, highlight: false, isPrimary: true),
          _StatRow(label: 'p95', value: p95, highlight: p95 > 8.0),
          _StatRow(label: 'p99', value: p99, highlight: p99 > 12.0),
          _StatRow(label: 'max', value: max, highlight: max > 16.0),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.label,
    required this.value,
    required this.highlight,
    this.isPrimary = false,
  });

  final String label;
  final double value;
  final bool highlight;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    final color = highlight
        ? const Color(0xFFFF6B6B)
        : (isPrimary ? _kAccent : Colors.white.withValues(alpha: 0.7));

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              color: Colors.white.withValues(alpha: 0.4),
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: highlight
                ? BoxDecoration(
                    color: const Color(0xFFFF6B6B).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                        color: const Color(0xFFFF6B6B).withValues(alpha: 0.3)),
                  )
                : null,
            child: Text(
              '${value.toStringAsFixed(2)} ms',
              style: TextStyle(
                fontSize: 12,
                fontWeight: isPrimary ? FontWeight.w800 : FontWeight.w600,
                fontFeatures: const [FontFeature.tabularFigures()],
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _JankColumn extends StatelessWidget {
  const _JankColumn({
    required this.frames,
    required this.jank60,
    required this.jank120,
  });

  final int frames;
  final double jank60;
  final double jank120;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kBorderSide),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'FRAME JANK',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Missed frame budget',
                style: TextStyle(
                  fontSize: 9,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: _kBorderSide),
          const SizedBox(height: 10),

          // Total Frames
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              children: [
                Text(
                  'SAMPLED',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                    color: Colors.white.withValues(alpha: 0.4),
                  ),
                ),
                const Spacer(),
                Text(
                  '$frames frames',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    fontFeatures: [FontFeature.tabularFigures()],
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // 60Hz Jank with visual bar
          _JankRow(
            label: '@60Hz',
            value: jank60,
            threshold: 5.0,
            maxBarValue: 20.0,
          ),
          const SizedBox(height: 6),

          // 120Hz Jank with visual bar
          _JankRow(
            label: '@120Hz',
            value: jank120,
            threshold: 15.0,
            maxBarValue: 40.0,
          ),
        ],
      ),
    );
  }
}

class _JankRow extends StatelessWidget {
  const _JankRow({
    required this.label,
    required this.value,
    required this.threshold,
    required this.maxBarValue,
  });

  final String label;
  final double value;
  final double threshold;
  final double maxBarValue;

  @override
  Widget build(BuildContext context) {
    final isBad = value > threshold;
    final color = isBad ? const Color(0xFFFF6B6B) : _kAccent;
    final barWidth = (value / maxBarValue).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                  color: Colors.white.withValues(alpha: 0.4),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: isBad
                    ? BoxDecoration(
                        color: const Color(0xFFFF6B6B).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                            color:
                                const Color(0xFFFF6B6B).withValues(alpha: 0.3)),
                      )
                    : null,
                child: Text(
                  '${value.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Visual mini-bar
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: barWidth,
            minHeight: 4,
            backgroundColor: Colors.white.withValues(alpha: 0.05),
            valueColor: AlwaysStoppedAnimation(
              color.withValues(alpha: isBad ? 0.8 : 0.6),
            ),
          ),
        ),
      ],
    );
  }
}
