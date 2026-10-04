part of '../benchmark.dart';

// ─── Results panel and metric widgets ──────────────────────────────────

class _ResultsPanel extends StatelessWidget {
  const _ResultsPanel({
    required this.stats,
    required this.mode,
    required this.deferResize,
    required this.isolatePanes,
    required this.shieldViews,
    required this.onDismiss,
  });

  final FrameStats stats;
  final String mode;
  final bool deferResize;
  final bool isolatePanes;
  final bool shieldViews;
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
                _ResultChip(
                  label: mode.toUpperCase(),
                  color: _kAccent,
                  enabled: true,
                ),
                const SizedBox(width: 6),
                _ResultChip(
                  label: deferResize ? 'DEFER ON' : 'DEFER OFF',
                  color: deferResize ? _kAccent : const Color(0xFFFF6B6B),
                  enabled: true,
                ),
                const SizedBox(width: 6),
                _ResultChip(
                  label: isolatePanes ? 'ISOLATE ON' : 'ISOLATE OFF',
                  color: _kIsolateColor,
                  enabled: isolatePanes,
                ),
                const SizedBox(width: 6),
                _ResultChip(
                  label: shieldViews ? 'SHIELD ON' : 'SHIELD OFF',
                  color: _kShieldColor,
                  enabled: shieldViews,
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

class _ResultChip extends StatelessWidget {
  const _ResultChip({
    required this.label,
    required this.color,
    required this.enabled,
  });

  final String label;
  final Color color;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: enabled
            ? color.withValues(alpha: 0.15)
            : Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(
          color: enabled ? color.withValues(alpha: 0.3) : _kBorderSide,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 1,
          color: enabled ? color : Colors.white.withValues(alpha: 0.45),
        ),
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
