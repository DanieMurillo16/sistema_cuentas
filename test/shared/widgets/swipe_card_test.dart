import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_cuentas/shared/widgets/swipe_card.dart';

Future<void> _pump(WidgetTester tester, {Future<bool> Function()? onConfirm}) =>
    tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: SwipeCard(
              itemKey: 'x-1',
              onConfirm: onConfirm,
              child: const SizedBox(
                height: 72,
                child: Center(child: Text('Fila')),
              ),
            ),
          ),
        ),
      ),
    );

void main() {
  testWidgets(
    'al deslizar, lo de dentro va plano (sin Card ni esquinas propias) '
    'y el fondo rojo llena el hueco',
    (tester) async {
      await _pump(tester, onConfirm: () async => false);

      await tester.drag(find.text('Fila'), const Offset(-120, 0));
      await tester.pump();

      expect(
        find.descendant(
          of: find.byType(SwipeCard),
          matching: find.byType(Card),
        ),
        findsNothing,
        reason: 'una Card deslizada muestra sus esquinas y borde recortados',
      );
      expect(find.byIcon(Icons.delete_outline_rounded), findsOneWidget);
      // El borde y las esquinas se pintan por fuera: no se mueven con la fila.
      final shell = tester.widget<DecoratedBox>(
        find
            .descendant(
              of: find.byType(SwipeCard),
              matching: find.byType(DecoratedBox),
            )
            .first,
      );
      expect(shell.position, DecorationPosition.foreground);
      await tester.pumpAndSettle();
    },
  );

  testWidgets('sin onConfirm no se desliza', (tester) async {
    await _pump(tester);

    await tester.drag(find.text('Fila'), const Offset(-120, 0));
    await tester.pump();

    expect(find.byIcon(Icons.delete_outline_rounded), findsNothing);
  });
}
