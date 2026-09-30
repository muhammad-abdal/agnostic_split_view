import 'package:agnostic_split_view/agnostic_split_view.dart';
import 'package:agnostic_split_view_example/widgets/custom_divider.dart';
import 'package:flutter/material.dart';

void main() => runApp(const DemoApp());

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
      home: const DemoShell(),
    );
  }
}

class DemoShell extends StatefulWidget {
  const DemoShell({super.key});

  @override
  State<DemoShell> createState() => _DemoShellState();
}

class _DemoShellState extends State<DemoShell> {
  // Outer: FILES | rest
  final _outer = SplitViewController(initialFraction: 0.22);

  // Inner A: TOP | rest of right side
  final _rightA = SplitViewController(initialFraction: 0.28);

  // Inner B: CENTER | INSPECTOR
  final _rightB = SplitViewController(initialFraction: 0.62);

  int selected = 0;

  static const items = [
    _NavItem(Icons.folder_rounded, 'lib', 12),
    _NavItem(Icons.folder_rounded, 'src', 4),
    _NavItem(Icons.description_rounded, 'split_view.dart', 0),
    _NavItem(Icons.description_rounded, 'split_view_controller.dart', 0),
    _NavItem(Icons.description_rounded, 'split_divider.dart', 0),
    _NavItem(Icons.description_rounded, 'split_view_theme.dart', 0),
    _NavItem(Icons.description_rounded, 'types.dart', 0),
    _NavItem(Icons.description_rounded, 'agnostic_split_view.dart', 0),
  ];

  @override
  void dispose() {
    _outer.dispose();
    _rightA.dispose();
    _rightB.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
    );
  }

  // ─── Desktop: nested split view ──────────────────────────────────────────

  Widget _buildIde() {
    return SplitViewTheme.overrideWith(
      data: const SplitViewTheme(
        dividerThickness: 14,
        collapseThreshold: 0.12,
      ),
      child: SplitView(
        // ─── Outer: FILES | right side ───
        direction: SplitDirection.horizontal,
        controller: _outer,
        firstCollapsible: true,
        minFirstPaneSize: 180,
        maxFirstPaneSize: 340,
        dividerBuilder: _divider,
        first: _files(),
        second: SplitView(
          // ─── Inner A: TOP | (CENTER + INSPECTOR) ───
          direction: SplitDirection.vertical,
          controller: _rightA,
          minFirstPaneSize: 80,
          minSecondPaneSize: 200,
          dividerBuilder: _divider,
          first: _top(),
          second: SplitView(
            // ─── Inner B: CENTER | INSPECTOR ───
            direction: SplitDirection.vertical,
            controller: _rightB,
            minFirstPaneSize: 120,
            minSecondPaneSize: 120,
            dividerBuilder: _divider,
            first: _center(),
            second: _inspector(),
          ),
        ),
      ),
    );
  }

  Widget _divider(BuildContext context, SplitViewDividerState state) {
    return CustomDivider(
      state: state,
      accent: const Color(0xFFC8FF00),
    );
  }

  // ─── Panes ───────────────────────────────────────────────────────────────

  Widget _files() {
    return Container(
      color: const Color(0xFF0D0F13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PaneHeader(
            title: 'FILES',
            trailing: IconButton(
              tooltip: 'Collapse',
              onPressed: _outer.toggleFirst,
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
              child: Text(
                items[selected].title,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _center() {
    return Container(
      color: const Color(0xFF08090C),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _PaneHeader(title: 'CENTER / EDITOR'),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.06),
                  ),
                ),
                child: const SingleChildScrollView(
                  child: SelectableText(
                    '''SplitView(
  direction: SplitDirection.horizontal,
  controller: outerController,
  minFirstPaneSize: 180,
  maxFirstPaneSize: 340,
  first: Files(),
  second: SplitView(
    direction: SplitDirection.vertical,
    controller: rightA,
    first: Top(),
    second: SplitView(
      direction: SplitDirection.vertical,
      controller: rightB,
      first: Center(),
      second: Inspector(),
    ),
  ),
)''',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12.5,
                      height: 1.7,
                      color: Color(0xFFC8FF00),
                    ),
                  ),
                ),
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
                _PropRow(label: 'direction', value: 'horizontal'),
                _PropRow(label: 'initialFraction', value: '0.22'),
                _PropRow(label: 'firstCollapsible', value: 'true'),
                _PropRow(label: 'minFirstPaneSize', value: '180'),
                _PropRow(label: 'maxFirstPaneSize', value: '340'),
                _PropRow(label: 'dividerThickness', value: '14'),
                _PropRow(label: 'dividerStyle', value: 'floating'),
                _PropRow(label: 'borderRadius', value: '99'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Mobile fallback ─────────────────────────────────────────────────────

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

// ─── Small building blocks ─────────────────────────────────────────────────

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

class _PropRow extends StatelessWidget {
  const _PropRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
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
