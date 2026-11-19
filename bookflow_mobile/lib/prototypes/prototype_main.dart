// Prototype entry point (kept separate from the real app; nothing in lib/ imports this folder).
//
//   flutter run -t lib/prototypes/prototype_main.dart
//   flutter run -d chrome -t lib/prototypes/prototype_main.dart     <- keyboard flipping works here
//
// No Clerk key or backend is needed.
import 'package:flutter/material.dart';

import '../theme.dart';
import 'tab_bar_prototype.dart';

void main() => runApp(const PrototypeApp());

class PrototypeApp extends StatelessWidget {
  const PrototypeApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'BookFlow prototypes',
    debugShowCheckedModeBanner: false,
    theme: buildTheme(Brightness.light),
    darkTheme: buildTheme(Brightness.dark),
    scrollBehavior: const AppScrollBehavior(),
    home: const TabBarPrototype(),
  );
}
