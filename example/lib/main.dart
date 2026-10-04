import 'package:agnostic_split_view/agnostic_split_view.dart';
import 'package:agnostic_split_view_example/benchmark.dart';
import 'package:agnostic_split_view_example/widgets/custom_divider.dart';
import 'package:flutter/material.dart';

/// A minimal, self-contained example of [SplitView].
///
/// For a full-featured, nested IDE-style layout demo with custom dividers,
/// see [demo_shell.dart] in this directory.
///
/// Tap the **Benchmark** FAB to run the frame-timing benchmark.
/// Run with `flutter run --profile` for accurate numbers.
void main() => runApp(const MinimalExampleApp());

class MinimalExampleApp extends StatelessWidget {
  const MinimalExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(brightness: Brightness.dark),
      routes: {
        '/benchmark': (_) => const BenchmarkPage(),
      },
      home: const _Home(),
    );
  }
}

class _Home extends StatelessWidget {
  const _Home();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SplitView(
        direction: SplitDirection.horizontal,
        firstCollapsible: true,
        minFirstPaneSize: 150,
        maxFirstPaneSize: 400,
        dividerBuilder: (context, state) => CustomDivider(state: state),

        // Pane 1: Sidebar
        first: Container(
          color: const Color(0xFF1E1E1E),
          child: const Center(
            child: Text(
              'Sidebar\n(Drag to resize or collapse)',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70),
            ),
          ),
        ),

        // Pane 2: Main Content
        second: Container(
          color: const Color(0xFF2D2D2D),
          child: const Center(
            child: Text(
              'Main Content Area',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).pushNamed('/benchmark'),
        icon: const Icon(Icons.speed),
        label: const Text('Benchmark'),
      ),
    );
  }
}
