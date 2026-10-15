import 'package:flutter/material.dart';

/// Transición de un `AnimatedSwitcher` en dos tiempos: lo que sale se funde en
/// el primer 40 % y lo que entra aparece en el resto. Así no se ven los dos
/// montados uno sobre otro (el «fantasma» de lo anterior).
Widget fadeThroughTransition(Widget child, Animation<double> animation) {
  final fade = CurvedAnimation(
    parent: animation,
    curve: const Interval(0.4, 1),
    reverseCurve: const Interval(0.6, 1),
  );
  return FadeTransition(opacity: fade, child: child);
}
