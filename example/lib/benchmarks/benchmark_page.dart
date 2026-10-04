part of '../benchmark.dart';

// ─── Benchmark page ────────────────────────────────────────────────────

/// Frame-timing benchmark page.
///
/// Run with `flutter run --profile` for accurate numbers.
///
/// Compares v0.1.3 (`DEFER OFF`) with v0.2.0 (`DEFER ON`) and also
/// exercises `isolatePanes`, `shieldPlatformViews`, and the new
/// programmatic `transitionDuration` / `transitionCurve` path.
class BenchmarkPage extends StatefulWidget {
  const BenchmarkPage({super.key});

  @override
  State<BenchmarkPage> createState() => _BenchmarkPageState();
}

class _BenchmarkPageState extends State<BenchmarkPage> {
  // Controllers — one per split, one per tree node, two for animated.
  final _controller = SplitViewController(initialFraction: 0.5);
  final List<SplitViewController> _treeControllers = [];
  final List<SplitViewController> _animControllers = [];

  final _stats = FrameStats();
  bool _collecting = false;
  BenchmarkMode _mode = BenchmarkMode.light;

  // v0.2.0 feature flags (live, controlled by toggles).
  bool _deferResize = true;
  bool _isolatePanes = false;
  bool _shieldViews = false;

  // Result snapshot (frozen when a run finishes).
  bool _hasResult = false;
  String _resultMode = '';
  bool _resultDefer = false;
  bool _resultIsolate = false;
  bool _resultShield = false;

  @override
  void initState() {
    super.initState();
    for (var i = 0; i < 7; i++) {
      _treeControllers.add(SplitViewController(initialFraction: 0.5));
    }
    for (var i = 0; i < 2; i++) {
      _animControllers.add(SplitViewController(initialFraction: 0.5));
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
    for (final c in _animControllers) {
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
    final targetController = switch (_mode) {
      BenchmarkMode.tree => _treeControllers.first,
      BenchmarkMode.animated => _animControllers.first,
      _ => _controller,
    };

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
      _resultIsolate = _isolatePanes;
      _resultShield = _shieldViews;
    });
  }

  /// v0.2.0 — animates every controller back to 0.5 to exercise the
  /// new `transitionDuration` / `transitionCurve` path.
  void _resetControllers() {
    for (final c in [
      _controller,
      ..._treeControllers,
      ..._animControllers,
    ]) {
      c.setFraction(0.5, animate: true);
    }
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
  /// Every level inherits `deferResize`, `isolatePanes`, and
  /// `shieldPlatformViews` so the tree stresses the same configuration
  /// throughout.
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
      isolatePanes: _isolatePanes,
      shieldPlatformViews: _shieldViews,
      shieldColor: _shieldViews ? _kAccent.withValues(alpha: 0.06) : null,
      transitionDuration: const Duration(milliseconds: 320),
      transitionCurve: Curves.easeOutCubic,
      first: _buildBinaryTree(depth + 1, maxDepth, controllerIndex * 2 + 1),
      second: _buildBinaryTree(depth + 1, maxDepth, controllerIndex * 2 + 2),
    );
  }

  /// v0.2.0 — 3 panes (via 2 nested SplitViews), each with a
  /// continuously-animating child.
  ///
  /// This is the cleanest test for `isolatePanes`: with isolation
  /// off, all three animations share a raster layer; with isolation
  /// on, each pane repaints on its own layer.
  Widget _buildAnimatedPanes() {
    return SplitView(
      direction: SplitDirection.horizontal,
      controller: _animControllers[0],
      dividerThickness: 8,
      deferResize: _deferResize,
      isolatePanes: _isolatePanes,
      shieldPlatformViews: _shieldViews,
      shieldColor: _shieldViews ? _kAccent.withValues(alpha: 0.06) : null,
      transitionDuration: const Duration(milliseconds: 320),
      transitionCurve: Curves.easeOutCubic,
      dividerBuilder: (context, state) => _BenchmarkDivider(state: state),
      first: const _AnimatedPane(
        label: 'PANE A',
        color: _kAccent,
        seed: 0,
      ),
      second: SplitView(
        direction: SplitDirection.vertical,
        controller: _animControllers[1],
        dividerThickness: 8,
        deferResize: _deferResize,
        isolatePanes: _isolatePanes,
        shieldPlatformViews: _shieldViews,
        shieldColor: _shieldViews ? _kAccent.withValues(alpha: 0.06) : null,
        transitionDuration: const Duration(milliseconds: 320),
        transitionCurve: Curves.easeOutCubic,
        dividerBuilder: (context, state) => _BenchmarkDivider(state: state),
        first: const _AnimatedPane(
          label: 'PANE B',
          color: _kIsolateColor,
          seed: 1,
        ),
        second: const _AnimatedPane(
          label: 'PANE C',
          color: Color(0xFFFF6B6B),
          seed: 2,
        ),
      ),
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
      case BenchmarkMode.animated:
        // Not reached — animated mode renders its own tree.
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
                  // Chips + toggles are locked while a run is in
                  // progress so the results panel always reports the
                  // config that actually produced the numbers.
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
                          const SizedBox(width: 6),
                          _ModeChip(
                            label: 'ANIMATED',
                            active: _mode == BenchmarkMode.animated,
                            onTap: () =>
                                setState(() => _mode = BenchmarkMode.animated),
                          ),
                          const SizedBox(width: 14),
                          _DeferToggle(
                            on: _deferResize,
                            onTap: () =>
                                setState(() => _deferResize = !_deferResize),
                          ),
                          const SizedBox(width: 6),
                          _IsolateToggle(
                            on: _isolatePanes,
                            onTap: () =>
                                setState(() => _isolatePanes = !_isolatePanes),
                          ),
                          const SizedBox(width: 6),
                          _ShieldToggle(
                            on: _shieldViews,
                            onTap: () =>
                                setState(() => _shieldViews = !_shieldViews),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  _ResetButton(onTap: _resetControllers),
                  const SizedBox(width: 6),
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
                    child: switch (_mode) {
                      BenchmarkMode.tree => _buildBinaryTree(0, 3, 0),
                      BenchmarkMode.animated => _buildAnimatedPanes(),
                      _ => SplitView(
                          direction: SplitDirection.horizontal,
                          controller: _controller,
                          minFirstPaneSize: 120,
                          maxFirstPaneSize: 400,
                          dividerThickness: 14,
                          deferResize: _deferResize,
                          isolatePanes: _isolatePanes,
                          shieldPlatformViews: _shieldViews,
                          shieldColor: _shieldViews
                              ? _kAccent.withValues(alpha: 0.06)
                              : null,
                          transitionDuration: const Duration(milliseconds: 320),
                          transitionCurve: Curves.easeOutCubic,
                          dividerBuilder: (context, state) =>
                              _BenchmarkDivider(state: state),
                          first: _buildPane('Pane A', mode: _mode),
                          second: _buildPane('Pane B', mode: _mode),
                        ),
                    },
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
                        isolatePanes: _resultIsolate,
                        shieldViews: _resultShield,
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
