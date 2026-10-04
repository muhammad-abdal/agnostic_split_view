part of '../benchmark.dart';

// ─── Benchmark modes ───────────────────────────────────────────────────

/// The five scenarios the benchmark can run.
///
/// `light`    — empty panes, sanity check.
/// `heavy`    — 2,000-item list per pane.
/// `extreme`  — 10,000-item list per pane.
/// `tree`     — 7 nested SplitViews, 8 heavy leaves.
/// `animated` — 3 panes with continuous animations.
enum BenchmarkMode { light, heavy, extreme, tree, animated }
