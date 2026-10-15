import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

/// Afirmaciones de layout: que no desborde no prueba que se vea bien. Con estas
/// se comprueba cuántas líneas ocupa un texto y dónde queda un elemento.

/// Cuántas líneas ocupa el primer `Text`/`RichText` que encuentra [finder]
/// (puede apuntar al `Text` o a un ancestro).
int textLines(WidgetTester tester, Finder finder) {
  final rich = find.descendant(of: finder, matching: find.byType(RichText));
  final target = rich.evaluate().isNotEmpty ? rich.first : finder.first;
  final paragraph = tester.renderObject<RenderParagraph>(target);
  final length = paragraph.text.toPlainText().length;
  if (length == 0) return 0;
  // Una línea = un valor distinto de «arriba» entre las cajas del texto.
  final boxes = paragraph.getBoxesForSelection(
    TextSelection(baseOffset: 0, extentOffset: length),
  );
  return boxes.map((box) => box.top.round()).toSet().length;
}

/// El texto cabe en una sola línea (una fecha, un monto, una hora no se parten).
void expectSingleLine(WidgetTester tester, Finder finder, {String? reason}) {
  expect(
    textLines(tester, finder),
    1,
    reason: reason ?? 'se esperaba una sola línea',
  );
}

/// El texto ocupa como mucho [max] líneas.
void expectMaxLines(
  WidgetTester tester,
  Finder finder,
  int max, {
  String? reason,
}) {
  final lines = textLines(tester, finder);
  expect(
    lines,
    lessThanOrEqualTo(max),
    reason: reason ?? 'ocupa $lines líneas (máximo $max)',
  );
}

/// El borde derecho de [child] queda pegado al de [parent] (con [tolerance]).
void expectRightEdge(
  WidgetTester tester,
  Finder child,
  Finder parent, {
  double tolerance = 24,
}) {
  final childRight = tester.getTopRight(child.first).dx;
  final parentRight = tester.getTopRight(parent.first).dx;
  expect(
    parentRight - childRight,
    lessThanOrEqualTo(tolerance),
    reason: 'a ${parentRight - childRight} px del borde derecho',
  );
}

/// [a] y [b] están en la misma fila (misma altura de arriba).
void expectSameRow(WidgetTester tester, Finder a, Finder b) {
  expect(
    tester.getTopLeft(a.first).dy,
    moreOrLessEquals(tester.getTopLeft(b.first).dy, epsilon: 2),
    reason: 'deberían ir en la misma fila',
  );
}

/// [a] queda encima de [b] (apilados).
void expectStacked(WidgetTester tester, Finder a, Finder b) {
  expect(
    tester.getTopLeft(a.first).dy,
    lessThan(tester.getTopLeft(b.first).dy),
    reason: 'deberían ir apilados',
  );
}
