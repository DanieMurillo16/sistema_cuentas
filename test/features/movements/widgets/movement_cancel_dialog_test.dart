import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_cuentas/core/errors/app_exception.dart';
import 'package:sistema_cuentas/core/models/movement_type.dart';
import 'package:sistema_cuentas/features/movements/data/movements_repository.dart';
import 'package:sistema_cuentas/features/movements/models/movement.dart';
import 'package:sistema_cuentas/features/movements/widgets/movement_cancel_dialog.dart';
import 'package:sistema_cuentas/features/summary/data/summary_repository.dart';

import '../../../helpers/movement_fixtures.dart';
import '../../../support/expect_screen_no_overflow.dart';
import '../../../support/fake_movements_repository.dart';
import '../../../support/fake_summary_repository.dart';
import '../../../support/pump_screen_app.dart';
import '../../../support/session_overrides.dart';

/// Una pantalla con un botón que abre el diálogo con `showDialog` (como en la
/// app: así ve el teclado) y escribe lo que devolvió.
class _Host extends StatefulWidget {
  const _Host({required this.movement});

  final Movement movement;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  var _result = 'sin abrir';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          TextButton(
            onPressed: () async {
              final done = await confirmCancelMovement(
                context,
                widget.movement,
              );
              if (mounted) setState(() => _result = 'devolvió $done');
            },
            child: const Text('Abrir'),
          ),
          Text(_result),
        ],
      ),
    );
  }
}

List<Override> _overrides(FakeMovementsRepository movements) => [
  ...sessionOverrides().overrides,
  movementsRepositoryProvider.overrideWithValue(movements),
  summaryRepositoryProvider.overrideWithValue(
    FakeSummaryRepository((_) async => buildTotals()),
  ),
];

Finder get _dialog => find.byType(MovementCancelDialog);
Finder get _confirm =>
    find.descendant(of: _dialog, matching: find.bySubtype<FilledButton>());
Finder get _cancelButton => find.descendant(
  of: _dialog,
  matching: find.widgetWithText(OutlinedButton, 'Cancelar'),
);
Finder get _close =>
    find.descendant(of: _dialog, matching: find.byTooltip('Cerrar'));
Future<void> _open(
  WidgetTester tester,
  FakeMovementsRepository movements, {
  Movement? movement,
}) async {
  await pumpScreenApp(
    tester,
    screen: _Host(movement: movement ?? buildMovement(id: 9)),
    overrides: _overrides(movements),
  );
  await tester.tap(find.text('Abrir'));
  await tester.pumpAndSettle();
}

Future<void> _openAt(
  WidgetTester tester,
  FakeMovementsRepository movements, {
  required double width,
  required double keyboard,
  required double textScale,
  Movement? movement,
}) async {
  await pumpScreenApp(
    tester,
    screen: _Host(movement: movement ?? buildMovement(id: 9)),
    overrides: _overrides(movements),
    width: width,
    keyboard: keyboard,
    textScale: textScale,
  );
  await tester.tap(find.text('Abrir'));
  await tester.pumpAndSettle();
}

bool _confirmEnabled(WidgetTester tester) =>
    tester.widget<FilledButton>(_confirm).onPressed != null;

void main() {
  group('apertura', () {
    testWidgets('gasto: título, a qué fila corresponde y la pregunta', (
      tester,
    ) async {
      await _open(
        tester,
        FakeMovementsRepository(),
        movement: buildMovement(id: 9, description: 'mercado del mes'),
      );

      expect(find.text('Eliminar gasto'), findsOneWidget);
      expect(find.text(r'Mercado del mes · -$ 25.000'), findsOneWidget);
      expect(
        find.text('¿Eliminar este gasto? Dejará de contar en tus saldos.'),
        findsOneWidget,
      );
      expect(find.byType(TextField), findsNothing, reason: 'no pide motivo');
      expect(find.text('Motivo'), findsNothing);
      expect(_confirm, findsOneWidget);
      expect(
        find.descendant(of: _confirm, matching: find.text('Eliminar')),
        findsOneWidget,
      );
      expect(_cancelButton, findsOneWidget);
    });

    testWidgets('ingreso: «Eliminar ingreso» con monto positivo', (
      tester,
    ) async {
      await _open(
        tester,
        FakeMovementsRepository(),
        movement: buildMovement(
          id: 9,
          type: MovementType.income,
          description: 'Salario',
          valueCents: 150000000,
        ),
      );

      expect(find.text('Eliminar ingreso'), findsOneWidget);
      expect(find.text(r'Salario · +$ 1.500.000'), findsOneWidget);
      expect(
        find.text('¿Eliminar este ingreso? Dejará de contar en tus saldos.'),
        findsOneWidget,
      );
    });

    testWidgets('«Eliminar» es destructivo (rojo) y está habilitado', (
      tester,
    ) async {
      await _open(tester, FakeMovementsRepository());

      expect(_confirmEnabled(tester), isTrue);
      final style = tester.widget<FilledButton>(_confirm).style!;
      expect(
        style.backgroundColor!.resolve({}),
        Theme.of(tester.element(_dialog)).colorScheme.error,
      );
    });
  });

  group('eliminar', () {
    testWidgets('envía el id y exactamente «Eliminado desde la app»', (
      tester,
    ) async {
      final movements = FakeMovementsRepository();
      await _open(tester, movements, movement: buildMovement(id: 42));

      await tester.tap(_confirm);
      await showToast(tester);
      await dismissToasts(tester);

      expect(movements.cancelled.single, (
        id: 42,
        reason: 'Eliminado desde la app',
      ));
    });

    testWidgets('éxito: avisa «Movimiento eliminado», se cierra y devuelve '
        'true', (tester) async {
      await _open(tester, FakeMovementsRepository());

      await tester.tap(_confirm);
      await showToast(tester);

      expect(find.text('Movimiento eliminado'), findsOneWidget);
      expect(_dialog, findsNothing);
      expect(find.text('devolvió true'), findsOneWidget);
      await dismissToasts(tester);
    });

    testWidgets('mientras elimina: progreso, todo bloqueado y no se puede '
        'cerrar', (tester) async {
      final completer = Completer<void>();
      final movements = FakeMovementsRepository(
        onCancel: (_, _) => completer.future,
      );
      await _open(tester, movements);

      await tester.tap(_confirm);
      await tester.pump(const Duration(milliseconds: 50));

      expect(
        find.descendant(
          of: _confirm,
          matching: find.byType(CircularProgressIndicator),
        ),
        findsOneWidget,
      );
      expect(_confirmEnabled(tester), isFalse);
      expect(tester.widget<OutlinedButton>(_cancelButton).onPressed, isNull);
      // La X apagada, «atrás» y tocar fuera no cierran.
      await tester.tap(_close, warnIfMissed: false);
      await tester.pump();
      await tester.tapAt(const Offset(2, 2));
      await tester.pump();
      await tester
          .state<NavigatorState>(find.byType(Navigator).last)
          .maybePop();
      await tester.pump();
      expect(_dialog, findsOneWidget);

      completer.complete();
      await showToast(tester);
      expect(_dialog, findsNothing);
      await dismissToasts(tester);
    });

    testWidgets('anti doble envío: dos toques seguidos, una sola llamada', (
      tester,
    ) async {
      final completer = Completer<void>();
      final movements = FakeMovementsRepository(
        onCancel: (_, _) => completer.future,
      );
      await _open(tester, movements);

      await tester.tap(_confirm);
      await tester.pump();
      await tester.tap(_confirm, warnIfMissed: false);
      await tester.pump();

      expect(movements.cancelCalls, 1);
      completer.complete();
      await showToast(tester);
      await dismissToasts(tester);
      expect(movements.cancelCalls, 1);
    });
  });

  group('error del servidor', () {
    FakeMovementsRepository failing() => FakeMovementsRepository(
      onCancel: (_, _) async => throw const ApiException(
        'El movimiento ya está anulado.',
        code: 'YA_ANULADO',
        statusCode: 422,
      ),
    );

    testWidgets('toast con el mensaje en español y el diálogo sigue abierto', (
      tester,
    ) async {
      await _open(tester, failing());

      await tester.tap(_confirm);
      await showToast(tester);

      expect(find.text('El movimiento ya está anulado.'), findsOneWidget);
      expect(find.text('Movimiento eliminado'), findsNothing);
      expect(_dialog, findsOneWidget);
      expect(find.text('devolvió true'), findsNothing);
      expect(_confirmEnabled(tester), isTrue, reason: 'se puede reintentar');
      await dismissToasts(tester);
    });

    testWidgets('tras el error, cerrar devuelve false', (tester) async {
      await _open(tester, failing());
      await tester.tap(_confirm);
      await showToast(tester);
      await dismissToasts(tester);

      await tester.tap(_close);
      await tester.pumpAndSettle();

      expect(_dialog, findsNothing);
      expect(find.text('devolvió false'), findsOneWidget);
    });

    testWidgets('reintentar después de un error sí elimina', (tester) async {
      var attempt = 0;
      final movements = FakeMovementsRepository(
        onCancel: (_, _) async {
          attempt++;
          if (attempt == 1) throw const NetworkException('Sin conexión.');
        },
      );
      await _open(tester, movements);

      await tester.tap(_confirm);
      await showToast(tester);
      await dismissToasts(tester);
      await tester.tap(_confirm);
      await showToast(tester);

      expect(movements.cancelCalls, 2);
      expect(find.text('devolvió true'), findsOneWidget);
      await dismissToasts(tester);
    });
  });

  group('cancelar', () {
    testWidgets('«Cancelar» cierra y devuelve false sin llamar al servidor', (
      tester,
    ) async {
      final movements = FakeMovementsRepository();
      await _open(tester, movements);

      await tester.tap(_cancelButton);
      await tester.pumpAndSettle();

      expect(_dialog, findsNothing);
      expect(find.text('devolvió false'), findsOneWidget);
      expect(movements.cancelCalls, 0);
    });

    testWidgets('la X cierra y devuelve false', (tester) async {
      final movements = FakeMovementsRepository();
      await _open(tester, movements);

      await tester.tap(_close);
      await tester.pumpAndSettle();

      expect(find.text('devolvió false'), findsOneWidget);
      expect(movements.cancelCalls, 0);
    });

    testWidgets('tocar fuera (sin eliminar) cierra y devuelve false', (
      tester,
    ) async {
      await _open(tester, FakeMovementsRepository());

      await tester.tapAt(const Offset(2, 2));
      await tester.pumpAndSettle();

      expect(_dialog, findsNothing);
      expect(find.text('devolvió false'), findsOneWidget);
    });
  });

  group('sin desbordes (320/390/800/1300 × teclado × texto 1.5), abierto con '
      'showDialog', () {
    final longMovement = buildMovement(
      id: 9,
      description: longDescription,
      category: longCatalogName,
      valueCents: 99999999999900,
    );
    Future<void> open(WidgetTester tester) async {
      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();
      expect(_dialog, findsOneWidget);
    }

    testWidgets('gasto con descripción corta', (tester) async {
      await expectScreenNoOverflow(
        tester,
        screen: _Host(movement: buildMovement(id: 9)),
        overrides: () => _overrides(FakeMovementsRepository()),
        prepare: open,
      );
    });

    testWidgets('descripción de 60+ caracteres e importe de 12 dígitos', (
      tester,
    ) async {
      await expectScreenNoOverflow(
        tester,
        screen: _Host(movement: longMovement),
        overrides: () => _overrides(FakeMovementsRepository()),
        prepare: open,
      );
    });

    testWidgets('eliminando (progreso en el botón)', (tester) async {
      final completer = Completer<void>();
      await expectScreenNoOverflow(
        tester,
        screen: _Host(movement: longMovement),
        overrides: () => _overrides(
          FakeMovementsRepository(onCancel: (_, _) => completer.future),
        ),
        settle: false,
        prepare: (tester) async {
          await tester.tap(find.text('Abrir'));
          await tester.pump(const Duration(milliseconds: 400));
          await tester.tap(_confirm);
          await tester.pump(const Duration(milliseconds: 100));
          expect(
            find.descendant(
              of: _confirm,
              matching: find.byType(CircularProgressIndicator),
            ),
            findsOneWidget,
          );
        },
      );
      // La petición queda pendiente a propósito: al desmontar la app entre
      // tamaños no debe llegar una respuesta a un contenedor ya liberado.
    });

    testWidgets('con teclado abierto y texto 1.5 los botones siguen a la '
        'vista (320 px)', (tester) async {
      await _openAt(
        tester,
        FakeMovementsRepository(),
        width: 320,
        keyboard: 300,
        textScale: 1.5,
        movement: longMovement,
      );

      expect(tester.takeException(), isNull);
      final view = tester.view.physicalSize.height - 300;
      expect(tester.getRect(_confirm).bottom, lessThanOrEqualTo(view));
      expect(tester.getRect(_confirm).top, greaterThanOrEqualTo(0));
    });
  });
}
