import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_cuentas/core/models/movement_type.dart';
import 'package:sistema_cuentas/core/theme/app_theme.dart';
import 'package:sistema_cuentas/features/home/widgets/home_empty_message.dart';

Future<void> _pump(WidgetTester tester, MovementType? filter) =>
    tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(body: HomeEmptyMessage(filter: filter)),
      ),
    );

void main() {
  testWidgets('sin filtro: «Sin movimientos este mes»', (tester) async {
    await _pump(tester, null);
    expect(find.text('Sin movimientos este mes'), findsOneWidget);
    expect(find.textContaining('Toca «+»'), findsOneWidget);
  });

  testWidgets('ingresos: «Sin ingresos este mes»', (tester) async {
    await _pump(tester, MovementType.income);
    expect(find.text('Sin ingresos este mes'), findsOneWidget);
    expect(find.text('Sin movimientos este mes'), findsNothing);
  });

  testWidgets('gastos: «Sin gastos este mes»', (tester) async {
    await _pump(tester, MovementType.expense);
    expect(find.text('Sin gastos este mes'), findsOneWidget);
  });
}
