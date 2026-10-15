import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_cuentas/core/theme/app_theme.dart';
import 'package:sistema_cuentas/shared/widgets/app_search_dropdown.dart';

const _items = ['Nequi', 'Bancolombia', 'Efectivo'];

Future<void> _pump(
  WidgetTester tester, {
  String? value,
  required ValueChanged<String?> onChanged,
  VoidCallback? onCleared,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: AppSearchDropdown<String>(
            label: 'Medio de pago',
            value: value,
            items: _items,
            itemLabel: (item) => item,
            onChanged: onChanged,
            onCleared: onCleared,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('sin onCleared nunca hay «×», aunque haya valor', (tester) async {
    await _pump(tester, value: 'Nequi', onChanged: (_) {});
    expect(find.byTooltip('Quitar'), findsNothing);
    expect(find.byTooltip('Buscar opciones'), findsOneWidget);
  });

  testWidgets('con onCleared pero sin valor sigue la flecha', (tester) async {
    await _pump(tester, onChanged: (_) {}, onCleared: () {});
    expect(find.byTooltip('Quitar'), findsNothing);
    expect(find.byTooltip('Buscar opciones'), findsOneWidget);
    expect(find.byIcon(Icons.expand_more_rounded), findsOneWidget);
  });

  testWidgets('con onCleared y valor muestra la «×» en lugar de la flecha', (
    tester,
  ) async {
    await _pump(tester, value: 'Nequi', onChanged: (_) {}, onCleared: () {});
    expect(find.byTooltip('Quitar'), findsOneWidget);
    expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    expect(find.byTooltip('Buscar opciones'), findsNothing);
    expect(find.byIcon(Icons.expand_more_rounded), findsNothing);
  });

  testWidgets('tocar la «×» llama a onCleared y no a onChanged', (
    tester,
  ) async {
    var cleared = 0;
    final changed = <String?>[];
    await _pump(
      tester,
      value: 'Nequi',
      onChanged: changed.add,
      onCleared: () => cleared++,
    );

    await tester.tap(find.byTooltip('Quitar'));
    await tester.pumpAndSettle();

    expect(cleared, 1);
    expect(changed, isEmpty);
  });

  testWidgets('la «×» tiene un área táctil de al menos 40 px', (tester) async {
    await _pump(tester, value: 'Nequi', onChanged: (_) {}, onCleared: () {});
    final size = tester.getSize(find.byTooltip('Quitar'));
    expect(size.shortestSide, greaterThanOrEqualTo(40));
  });

  testWidgets('elegir una opción llama a onChanged con ella', (tester) async {
    final changed = <String?>[];
    await _pump(tester, onChanged: changed.add, onCleared: () {});

    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, 'Bancolombia'));
    await tester.pumpAndSettle();

    expect(changed, ['Bancolombia']);
  });
}
