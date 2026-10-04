part of '../benchmark.dart';

// ─── Animated pane ─────────────────────────────────────────────────────

/// A continuously-animating pane, used by [BenchmarkMode.animated].
///
/// The animation is intentionally expensive (scale + rotate + glow +
/// progress bar) so toggling `isolatePanes` produces a measurable
/// difference in raster time.
class _AnimatedPane extends StatefulWidget {
  const _AnimatedPane({
    required this.label,
    required this.color,
    required this.seed,
  });

  final String label;
  final Color color;
  final int seed;

  @override
  State<_AnimatedPane> createState() => _AnimatedPaneState();
}

class _AnimatedPaneState extends State<_AnimatedPane>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1200 + widget.seed * 250),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _kPanel,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = _controller.value;
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Pulsing orb (scale + glow)
                Transform.scale(
                  scale: 0.7 + (t * 0.3),
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: widget.color.withValues(alpha: 0.25 + t * 0.35),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color:
                              widget.color.withValues(alpha: 0.15 + t * 0.25),
                          blurRadius: 16 + t * 24,
                          spreadRadius: t * 8,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Rotating icon
                Transform.rotate(
                  angle: t * math.pi * 2,
                  child: Icon(
                    Icons.settings_rounded,
                    size: 26,
                    color: widget.color,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  widget.label,
                  style: TextStyle(
                    color: widget.color,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: 10),
                // Progress bar tied to the animation
                SizedBox(
                  width: 110,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: t,
                      minHeight: 3,
                      backgroundColor: Colors.white.withValues(alpha: 0.05),
                      valueColor: AlwaysStoppedAnimation(widget.color),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${(t * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 9,
                    color: Colors.white.withValues(alpha: 0.35),
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
