import 'package:agnostic_split_view/agnostic_split_view.dart';
import 'package:agnostic_split_view_example/widgets/custom_divider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DemoApp extends StatelessWidget {
  const DemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'agnostic_split_view',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFC8FF00),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF08090C),
        fontFamily: 'monospace',
      ),
      routes: {
        '/benchmark': (_) => const BenchmarkPagePlaceholder(),
      },
      home: const DemoShell(),
    );
  }
}

/// Placeholder so the route doesn't 404 if the benchmark file isn't wired
/// in yet. Delete this class and import the real `benchmark.dart` when
/// you want to expose the benchmark from the demo.
class BenchmarkPagePlaceholder extends StatelessWidget {
  const BenchmarkPagePlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF08090C),
      body: Center(
        child: Text(
          'Benchmark page not wired in this build.',
          style: TextStyle(color: Color(0xFFC8FF00)),
        ),
      ),
    );
  }
}

// ─── Demo shell ────────────────────────────────────────────────────────

class DemoShell extends StatefulWidget {
  const DemoShell({super.key});

  @override
  State<DemoShell> createState() => _DemoShellState();
}

class _DemoShellState extends State<DemoShell> {
  // Outer: FILES | right side
  final _outer = SplitViewController(initialFraction: 0.22);

  // Inner A: TOP | (CENTER + INSPECTOR)
  final _rightA = SplitViewController(initialFraction: 0.28);

  // Inner B: CENTER | INSPECTOR
  final _rightB = SplitViewController(initialFraction: 0.62);

  // v0.2.0 feature toggles — flip these to see the difference.
  bool _deferResize = true;
  bool _shieldPlatformViews = true;

  int selected = 0;

  // A larger file list so `deferResize` has something to skip.
  static final items = <_NavItem>[
    const _NavItem(Icons.folder_rounded, 'lib', 12),
    const _NavItem(Icons.folder_rounded, 'src', 4),
    for (var i = 0; i < 40; i++)
      _NavItem(
        Icons.description_rounded,
        'file_$i.dart',
        0,
      ),
    const _NavItem(Icons.folder_rounded, 'test', 6),
    const _NavItem(Icons.folder_rounded, 'example', 3),
    for (var i = 0; i < 20; i++)
      _NavItem(
        Icons.description_rounded,
        'spec_$i.dart',
        0,
      ),
  ];

  @override
  void dispose() {
    _outer.dispose();
    _rightA.dispose();
    _rightB.dispose();
    super.dispose();
  }

  /// Animated "reset layout" — keyboard shortcut ⌘/Ctrl+R.
  void _resetLayout() {
    // Animated changes — the widget routes these through its internal
    // AnimationController using the theme's duration and curve.
    _outer.setFraction(0.22, animate: true);
    _rightA.setFraction(0.28, animate: true);
    _rightB.setFraction(0.62, animate: true);
  }

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: const <ShortcutActivator, Intent>{
        // ⌘R / Ctrl+R — animated reset
        SingleActivator(LogicalKeyboardKey.keyR, control: true): _ResetIntent(),
        SingleActivator(LogicalKeyboardKey.keyR, meta: true): _ResetIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          _ResetIntent: CallbackAction<_ResetIntent>(
            onInvoke: (_) {
              _resetLayout();
              return null;
            },
          ),
        },
        child: Focus(
          autofocus: true,
          child: Scaffold(
            body: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth < 900) {
                    return _buildMobile();
                  }
                  return _buildIde();
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Desktop: nested split view ────────────────────────────────────────

  Widget _buildIde() {
    return SplitViewTheme.overrideWith(
      data: const SplitViewTheme(
        dividerThickness: 14,
        collapseThreshold: 0.12,
        // v0.2.0 defaults for this subtree
        deferResize: true,
        shieldPlatformViews: true,
        dragBarrierColor: Color(0x0AFFFFFF), // 4% white tint
        animationDuration: Duration(milliseconds: 260),
        animationCurve: Curves.easeOutCubic,
      ),
      child: Column(
        children: [
          Expanded(
            child: SplitView(
              // ─── Outer: FILES | right side ───
              direction: SplitDirection.horizontal,
              controller: _outer,
              firstCollapsible: true,
              minFirstPaneSize: 180,
              maxFirstPaneSize: 340,
              // v0.2.0 — opt in to deferred resize for this split.
              // Panes freeze during drag; only the divider moves.
              deferResize: _deferResize,
              shieldPlatformViews: _shieldPlatformViews,
              dividerBuilder: _divider,
              first: _files(),
              second: SplitView(
                // ─── Inner A: TOP | (CENTER + INSPECTOR) ───
                direction: SplitDirection.vertical,
                controller: _rightA,
                minFirstPaneSize: 80,
                minSecondPaneSize: 200,
                deferResize: _deferResize,
                shieldPlatformViews: _shieldPlatformViews,
                dividerBuilder: _divider,
                first: _top(),
                second: SplitView(
                  // ─── Inner B: CENTER | INSPECTOR ───
                  direction: SplitDirection.vertical,
                  controller: _rightB,
                  minFirstPaneSize: 120,
                  minSecondPaneSize: 120,
                  deferResize: _deferResize,
                  shieldPlatformViews: _shieldPlatformViews,
                  dividerBuilder: _divider,
                  first: _center(),
                  second: _inspector(),
                ),
              ),
            ),
          ),
          _FeatureBar(
            deferResize: _deferResize,
            shield: _shieldPlatformViews,
            onToggleDefer: () => setState(() => _deferResize = !_deferResize),
            onToggleShield: () =>
                setState(() => _shieldPlatformViews = !_shieldPlatformViews),
            onReset: _resetLayout,
          ),
        ],
      ),
    );
  }

  Widget _divider(BuildContext context, SplitViewDividerState state) {
    return CustomDivider(
      state: state,
      accent: const Color(0xFFC8FF00),
    );
  }

  // ─── Panes ─────────────────────────────────────────────────────────────

  Widget _files() {
    return Container(
      color: const Color(0xFF0D0F13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PaneHeader(
            title: 'FILES',
            trailing: IconButton(
              tooltip: 'Collapse sidebar',
              onPressed: () => _outer.toggleFirst(animate: true),
              icon: const Icon(
                Icons.keyboard_double_arrow_left_rounded,
                size: 18,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              itemCount: items.length,
              itemBuilder: (context, i) {
                final item = items[i];
                final active = selected == i;
                return _FileRow(
                  item: item,
                  active: active,
                  onTap: () => setState(() => selected = i),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _top() {
    return Container(
      color: const Color(0xFF0B0D11),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _PaneHeader(title: 'TOP / PREVIEW'),
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    items[selected].title,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Drag the divider to resize — panes freeze in place.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _center() {
    // Generate a realistic-looking code block.
    final codeLines = <String>[
      'import \'package:flutter/widgets.dart\';',
      '',
      'class ${_classNameFor(items[selected].title)} extends StatelessWidget {',
      '  const ${_classNameFor(items[selected].title)}({super.key});',
      '',
      '  @override',
      '  Widget build(BuildContext context) {',
      '    return SplitView(',
      '      direction: SplitDirection.horizontal,',
      '      controller: _controller,',
      '      minFirstPaneSize: 180,',
      '      maxFirstPaneSize: 340,',
      '      deferResize: true,',
      '      shieldPlatformViews: true,',
      '      first: Files(),',
      '      second: SplitView(',
      '        direction: SplitDirection.vertical,',
      '        controller: _rightA,',
      '        first: Top(),',
      '        second: SplitView(',
      '          direction: SplitDirection.vertical,',
      '          controller: _rightB,',
      '          first: Center(),',
      '          second: Inspector(),',
      '        ),',
      '      ),',
      '    );',
      '  }',
      '}',
      '',
      '// ─── Helper ───',
      '',
      '/// Normalizes a file name into a Dart class name.',
      'String _classNameFor(String fileName) {',
      '  final base = fileName.replaceAll(\'.dart\', \'\');',
      '  return base',
      '      .split(\'_\')',
      '      .map((w) => w.isEmpty',
      '          ? w',
      '          : \'\${w[0].toUpperCase()}\${w.substring(1)}\')',
      '      .join();',
      '}',
      '',
      '// ─── More content so the pane stays "heavy" ───',
      '',
      for (var i = 0; i < 20; i++)
        '// Padding line $i — keeps this pane content-heavy.',
    ];

    return Container(
      color: const Color(0xFF08090C),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PaneHeader(
            title: 'CENTER / EDITOR',
            trailing: Text(
              items[selected].title,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.45),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < codeLines.length; i++)
                    _CodeLine(
                      lineNumber: i + 1,
                      text: codeLines[i],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _inspector() {
    return Container(
      color: const Color(0xFF0B0D11),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _PaneHeader(title: 'INSPECTOR'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              children: const [
                _PropSection(title: 'LAYOUT'),
                _PropRow(label: 'direction', value: 'horizontal'),
                _PropRow(label: 'initialFraction', value: '0.22'),
                _PropRow(label: 'minFirstPaneSize', value: '180'),
                _PropRow(label: 'maxFirstPaneSize', value: '340'),
                _PropSection(title: 'v0.2.0'),
                _PropRow(label: 'deferResize', value: 'true'),
                _PropRow(label: 'shieldPlatformViews', value: 'true'),
                _PropRow(label: 'dragBarrierColor', value: '0x0AFFFFFF'),
                _PropRow(label: 'animationDuration', value: '260ms'),
                _PropRow(label: 'animationCurve', value: 'easeOutCubic'),
                _PropSection(title: 'COLLAPSE'),
                _PropRow(label: 'firstCollapsible', value: 'true'),
                _PropRow(label: 'collapseThreshold', value: '0.12'),
                _PropSection(title: 'DIVIDER'),
                _PropRow(label: 'thickness', value: '14'),
                _PropRow(label: 'style', value: 'floating'),
                _PropRow(label: 'radius', value: '99'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobile() {
    return Column(
      children: [
        Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          color: const Color(0xFF0D0F13),
          child: const Row(
            children: [
              Icon(Icons.view_sidebar_rounded, color: Color(0xFFC8FF00)),
              SizedBox(width: 12),
              Text(
                'AGNOSTIC',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.4,
                ),
              ),
              Spacer(),
              Text(
                'RESIZE WINDOW →',
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 1.2,
                  color: Colors.white54,
                ),
              ),
            ],
          ),
        ),
        Expanded(child: _files()),
      ],
    );
  }
}

// ─── Feature bar ───────────────────────────────────────────────────────

class _FeatureBar extends StatelessWidget {
  const _FeatureBar({
    required this.deferResize,
    required this.shield,
    required this.onToggleDefer,
    required this.onToggleShield,
    required this.onReset,
  });

  final bool deferResize;
  final bool shield;
  final VoidCallback onToggleDefer;
  final VoidCallback onToggleShield;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: const BoxDecoration(
        color: Color(0xFF0D0F13),
        border: Border(
          top: BorderSide(color: Color(0x14FFFFFF)),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Color(0xFFC8FF00),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'v0.2.0',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(width: 18),
          _FeatureToggle(
            label: 'DEFER RESIZE',
            on: deferResize,
            onTap: onToggleDefer,
          ),
          const SizedBox(width: 8),
          _FeatureToggle(
            label: 'SHIELD',
            on: shield,
            onTap: onToggleShield,
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: onReset,
            icon: const Icon(Icons.restart_alt_rounded, size: 14),
            label: const Text(
              'RESET LAYOUT  ⌘R',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFC8FF00),
              padding: const EdgeInsets.symmetric(horizontal: 10),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureToggle extends StatelessWidget {
  const _FeatureToggle({
    required this.label,
    required this.on,
    required this.onTap,
  });

  final String label;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: on
              ? const Color(0xFFC8FF00).withValues(alpha: 0.12)
              : Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: on
                ? const Color(0xFFC8FF00).withValues(alpha: 0.35)
                : const Color(0x14FFFFFF),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: on
                    ? const Color(0xFFC8FF00)
                    : Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
                color: on
                    ? const Color(0xFFC8FF00)
                    : Colors.white.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Small building blocks ─────────────────────────────────────────────

class _PaneHeader extends StatelessWidget {
  const _PaneHeader({required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
        ),
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

class _FileRow extends StatelessWidget {
  const _FileRow({
    required this.item,
    required this.active,
    required this.onTap,
  });

  final _NavItem item;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: active
            ? const Color(0xFFC8FF00).withValues(alpha: 0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 8,
            ),
            child: Row(
              children: [
                Icon(
                  item.icon,
                  size: 15,
                  color: active
                      ? const Color(0xFFC8FF00)
                      : Colors.white.withValues(alpha: 0.45),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item.title,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                      color: active
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.62),
                    ),
                  ),
                ),
                if (item.badge > 0)
                  Text(
                    '${item.badge}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: active
                          ? const Color(0xFFC8FF00)
                          : Colors.white.withValues(alpha: 0.25),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CodeLine extends StatelessWidget {
  const _CodeLine({required this.lineNumber, required this.text});

  final int lineNumber;
  final String text;

  @override
  Widget build(BuildContext context) {
    final isComment = text.trimLeft().startsWith('//');
    final isImport = text.startsWith('import');
    final isKeyword = text.trimLeft().startsWith('class ') ||
        text.trimLeft().startsWith('return ') ||
        text.trimLeft().startsWith('for ');

    Color color;
    if (isComment) {
      color = Colors.white.withValues(alpha: 0.28);
    } else if (isImport) {
      color = const Color(0xFF87CEEB);
    } else if (isKeyword) {
      color = const Color(0xFFFFB86C);
    } else {
      color = Colors.white.withValues(alpha: 0.75);
    }

    return SizedBox(
      height: 20,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 32,
            child: Text(
              '$lineNumber',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                height: 1.6,
                color: Colors.white.withValues(alpha: 0.2),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                height: 1.6,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PropSection extends StatelessWidget {
  const _PropSection({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 6),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.6,
          color: Colors.white.withValues(alpha: 0.3),
        ),
      ),
    );
  }
}

class _PropRow extends StatelessWidget {
  const _PropRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                color: Colors.white.withValues(alpha: 0.5),
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFFC8FF00),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem {
  const _NavItem(this.icon, this.title, this.badge);

  final IconData icon;
  final String title;
  final int badge;
}

// ─── Intent for ⌘R / Ctrl+R ────────────────────────────────────────────

class _ResetIntent extends Intent {
  const _ResetIntent();
}

// ─── Helper ────────────────────────────────────────────────────────────

/// Normalizes a file name into a Dart class name.
String _classNameFor(String fileName) {
  final base = fileName.replaceAll('.dart', '');
  return base
      .split('_')
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
      .join();
}
