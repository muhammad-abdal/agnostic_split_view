import 'package:agnostic_split_view_example/demo_shell.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const AgnosticSplitViewDemo());
}

class AgnosticSplitViewDemo extends StatelessWidget {
  const AgnosticSplitViewDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Agnostic Split View',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF08090C),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFC8FF00),
          brightness: Brightness.dark,
        ),
        fontFamily: 'Inter',
      ),
      home: const DemoShell(),
    );
  }
}
