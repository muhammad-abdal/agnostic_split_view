part of '../benchmark.dart';

// ─── Controls: chips, toggles, buttons, divider ────────────────────────

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

/// Generic two-state toggle used by the v0.2.0 feature switches.
class _FeatureToggle extends StatelessWidget {
  const _FeatureToggle({
    required this.label,
    required this.on,
    required this.onTap,
    required this.color,
  });

  final String label;
  final bool on;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: on
              ? color.withValues(alpha: 0.15)
              : Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: on ? color.withValues(alpha: 0.4) : _kBorderSide,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: on ? color : Colors.white.withValues(alpha: 0.45),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              width: 22,
              height: 12,
              decoration: BoxDecoration(
                color: on ? color : Colors.white.withValues(alpha: 0.1),
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

/// v0.2.0 — toggles `deferResize`.
/// `OFF` mimics v0.1.3 behavior; `ON` is v0.2.0's deferred-resize mode.
class _DeferToggle extends StatelessWidget {
  const _DeferToggle({required this.on, required this.onTap});

  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Uses red when OFF to visually signal "this is the old behavior".
    final color = on ? _kAccent : const Color(0xFFFF6B6B);
    return _FeatureToggle(
      label: 'DEFER',
      on: on,
      onTap: onTap,
      color: color,
    );
  }
}

/// v0.2.0 — toggles `isolatePanes`.
class _IsolateToggle extends StatelessWidget {
  const _IsolateToggle({required this.on, required this.onTap});

  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _FeatureToggle(
      label: 'ISOLATE',
      on: on,
      onTap: onTap,
      color: _kIsolateColor,
    );
  }
}

/// v0.2.0 — toggles `shieldPlatformViews`.
class _ShieldToggle extends StatelessWidget {
  const _ShieldToggle({required this.on, required this.onTap});

  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _FeatureToggle(
      label: 'SHIELD',
      on: on,
      onTap: onTap,
      color: _kShieldColor,
    );
  }
}

/// v0.2.0 — programmatically resets every controller to 0.5 with an
/// animation, exercising `transitionDuration` and `transitionCurve`.
class _ResetButton extends StatelessWidget {
  const _ResetButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: _kBorderSide),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.restart_alt_rounded,
              size: 12,
              color: Colors.white.withValues(alpha: 0.6),
            ),
            const SizedBox(width: 6),
            Text(
              'RESET',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: Colors.white.withValues(alpha: 0.6),
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

/// Custom divider used by every SplitView in the benchmark.
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
