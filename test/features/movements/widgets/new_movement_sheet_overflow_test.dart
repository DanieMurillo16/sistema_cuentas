import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_cuentas/core/models/movement_type.dart';
import 'package:sistema_cuentas/features/movements/widgets/movement_form.dart';
import 'package:sistema_cuentas/features/movements/widgets/movement_type_picker.dart';
import 'package:sistema_cuentas/features/movements/widgets/new_movement_sheet.dart';

import '../../../support/inicio_overrides.dart';
import '../../../support/open_movement_sheet.dart';
import '../../../support/pump_at_sizes.dart';

/// Abre la hoja con `showModalBottomSheet` en cuanto se pinta (como en la app:
/// dentro de una ruta, con el teclado visto por la hoja y no por un Scaffold).
class _SheetHost extends StatefulWidget {
  const _SheetHost();

  @override
  State<_SheetHost> createState() => _SheetHostState();
}

class _SheetHostState extends State<_SheetHost> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) => const NewMovementSheet(),
      );
    });
  }

  @override
  Widget build(BuildContext context) => const Scaffold(body: SizedBox.expand());
}

/// El campo de texto que tiene el foco ahora (o `null`).
EditableText? _focusedEditable() => FocusManager.instance.primaryFocus?.context
    ?.findAncestorWidgetOfExactType<EditableText>();

void main() {
  testWidgets(
    'la hoja «+» (paso 1: elegir tipo) abierta con showModalBottomSheet no desborda en 320/390/800/1300 × teclado × texto 1.5',
    (tester) async {
      await expectNoOverflow(tester, const _SheetHost());
      expect(find.byType(NewMovementSheet), findsOneWidget);
      expect(find.text('Nuevo movimiento'), findsOneWidget);
    },
  );

  testWidgets('en 320 con texto 1.5 las dos opciones miden lo mismo y caben', (
    tester,
  ) async {
    await expectNoOverflow(
      tester,
      const _SheetHost(),
      widths: const [320],
      keyboards: const [0],
      scales: const [1.5],
    );
    final tiles = find.byType(InkWell);
    final sizes = [for (var i = 0; i < 2; i++) tester.getSize(tiles.at(i))];
    expect(sizes[0].height, sizes[1].height);
    expect(sizes[0].width, sizes[1].width);
    expect(
      tester.getRect(find.byType(NewMovementSheet)).right,
      lessThanOrEqualTo(320),
    );
  });

  for (final (width, scale) in [(320.0, 1.5), (390.0, 1.0)]) {
    testWidgets(
      'con el teclado abierto: abrir el formulario y volver con la flecha '
      'no lanza excepciones ni deja el foco ($width px · texto $scale)',
      (tester) async {
        await openMovementSheet(
          tester,
          type: MovementType.expense,
          width: width,
          height: 700,
          keyboard: 300,
          textScale: scale,
          overrides: dataOverrides(),
        );
        expect(find.byType(MovementForm), findsOneWidget);
        expect(tester.takeException(), isNull);
        expect(
          _focusedEditable(),
          isNull,
          reason: 'el formulario ya no pide el foco: el teclado no sube solo',
        );

        // La persona toca el monto: ahí sí hay foco (y teclado).
        await tester.showKeyboard(find.byType(TextFormField).first);
        await tester.pumpAndSettle();
        expect(_focusedEditable(), isNotNull);
        expect(tester.takeException(), isNull);

        await tester.tap(find.byTooltip('Volver'));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byType(MovementTypePicker), findsOneWidget);
        expect(find.byType(MovementForm), findsNothing);
        // Sin campo enfocado: el teclado se cierra al volver.
        expect(_focusedEditable(), isNull);

        // Y se puede entrar otra vez al formulario sin problema.
        await tester.tap(find.text('Ingreso'));
        await tester.pumpAndSettle();
        expect(find.byType(MovementForm), findsOneWidget);
        expect(tester.takeException(), isNull);
        expect(_focusedEditable(), isNull);
      },
    );
  }
}
