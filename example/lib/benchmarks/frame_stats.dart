part of '../benchmark.dart';

// ─── Frame statistics ──────────────────────────────────────────────────

/// Accumulates [FrameTiming] samples and exposes percentile and
/// jank statistics.
///
/// Pure data class — no Flutter widget dependencies — so it can be
/// unit-tested in isolation.
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
