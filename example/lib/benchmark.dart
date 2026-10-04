/// Frame-timing benchmark for `agnostic_split_view`.
///
/// Run with `flutter run --profile` for accurate numbers.
///
/// This library is split across multiple files using `part`/`part of`
/// so that private widgets (`_ModeChip`, `_AnimatedPane`, etc.) stay
/// private to the library while keeping each file focused on a single
/// concern.
///
/// Layout:
///   • `benchmarks/mode.dart`              — BenchmarkMode enum
///   • `benchmarks/frame_stats.dart`       — FrameStats (pure math)
///   • `benchmarks/benchmark_page.dart`    — BenchmarkPage + state
///   • `benchmarks/benchmark_controls.dart`— chips, toggles, buttons
///   • `benchmarks/benchmark_results.dart` — results panel + metrics
///   • `benchmarks/animated_pane.dart`     — animated test pane
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:agnostic_split_view/agnostic_split_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

part 'benchmarks/animated_pane.dart';
part 'benchmarks/benchmark_controls.dart';
part 'benchmarks/benchmark_page.dart';
part 'benchmarks/benchmark_results.dart';
part 'benchmarks/frame_stats.dart';
// ─── Parts

part 'benchmarks/mode.dart';

// ─── Palette matching demo_shell.dart

const _kBackground = Color(0xFF08090C);
const _kPanel = Color(0xFF0D0F13);
const _kPanelAlt = Color(0xFF0B0D11);
const _kAccent = Color(0xFFC8FF00);
const _kBorderSide = Color(0x0FFFFFFF);

// v0.2.0 — accent colors for the new toggles / animated panes.
const _kIsolateColor = Color(0xFF4FC3F7);
const _kShieldColor = Color(0xFFB388FF);
