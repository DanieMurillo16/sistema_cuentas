import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_cuentas/core/errors/app_exception.dart';
import 'package:sistema_cuentas/features/recurring/widgets/recurring_delete_dialog.dart';

import '../../../helpers/recurring_fixtures.dart';
import '../../../support/delete_recurring_scenario.dart';
import '../../../support/expect_screen_no_overflow.dart';
import '../../../support/pump_screen_app.dart';

/// Un botón que abre el diálogo con `showDialog` (como en la app: así ve el
/// teclado) y escribe lo que devolvió.
class _Host extends StatefulWidget {
  const _Host({this.name = 'Oscar', this.isIncome = true});

  final String name;
  final bool isIncome;

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
              final done = await confirmDeleteRecurring(
                context,
                recurringId: 10,
                name: widget.name,
                isIncome: widget.isIncome,
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

DeleteRecurringScenario _scenario({Object? failWith}) =>
    DeleteRecurringScenario(
      dues: [buildDue(id: 1, recurringId: 10)],
      payments: [buildRecurring(id: 10, contact: 'Oscar')],
      failWith: failWith,
    );

Finder get _dialog => find.byType(RecurringDeleteDialog);
Finder get _confirm =>
    find.descendant(of: _dialog, matching: find.bySubtype<FilledButton>());
Finder get _decline => find.descendant(
  of: _dialog,
  matching: find.widgetWithText(OutlinedButton, 'Cancelar'),
);
Finder get _close =>
    find.descendant(of: _dialog, matching: find.byTooltip('Cerrar'));

Future<void> _open(
  WidgetTester tester,
  DeleteRecurringScenario s, {
  _Host host = const _Host(),
}) async {
  await pumpScreenApp(tester, screen: host, overrides: s.overrides);
  await tester.tap(find.text('Abrir'));
  await tester.pumpAndSettle();
}

bool _confirmEnabled(WidgetTester tester) =>
    tester.widget<FilledButton>(_confirm).onPressed != null;

void main() {
  group('apertura', () {
    testWidgets('título, nombre, pregunta y consecuencia de un cobro', (
      tester,
    ) async {
      await _open(tester, _scenario());

      expect(find.text('Eliminar pago recurrente'), findsOneWidget);
      expect(find.text('Oscar'), findsOneWidget, reason: 'subtítulo');
      expect(find.textContaining('¿Eliminar «Oscar»?'), findsOneWidget);
      expect(find.textContaining('Dejará de generar cobros'), findsOneWidget);
      expect(find.textContaining('Finalizados'), findsOneWidget);
      expect(find.byType(TextField), findsNothing, reason: 'no pide motivo');
    });

    testWidgets('de un gasto habla de pagos', (tester) async {
      await _open(
        tester,
        _scenario(),
        host: const _Host(name: 'netflix', isIncome: false),
      );

      expect(find.textContaining('¿Eliminar «Netflix»?'), findsOneWidget);
      expect(find.textContaining('Dejará de generar pagos'), findsOneWidget);
    });

    testWidgets('«Eliminar» es destructivo, está habilitado y hay «Cancelar»', (
      tester,
    ) async {
      await _open(tester, _scenario());

      expect(_confirmEnabled(tester), isTrue);
      expect(
        tester
            .widget<FilledButton>(_confirm)
            .style!
            .backgroundColor!
            .resolve({}),
        Theme.of(tester.element(_dialog)).colorScheme.error,
      );
      expect(
        find.descendant(of: _confirm, matching: find.text('Eliminar')),
        findsOneWidget,
      );
      expect(_decline, findsOneWidget);
    });
  });

  group('eliminar', () {
    testWidgets('finaliza el acuerdo con la nota fija y sin capital', (
      tester,
    ) async {
      final s = _scenario();
      await _open(tester, s);

      await tester.tap(_confirm);
      await showToast(tester);
      await dismissToasts(tester);

      expect(s.recurring.deleted, [10]);
      expect(s.recurring.finishCalls, 0);
    });

    testWidgets('éxito: avisa «Pago recurrente eliminado», cierra y devuelve '
        'true', (tester) async {
      await _open(tester, _scenario());

      await tester.tap(_confirm);
      await showToast(tester);

      expect(find.text('Pago recurrente eliminado'), findsOneWidget);
      expect(_dialog, findsNothing);
      expect(find.text('devolvió true'), findsOneWidget);
      await dismissToasts(tester);
    });

    testWidgets('mientras elimina: progreso, botones apagados y no se puede '
        'cerrar', (tester) async {
      final gate = Completer<void>();
      final s = _scenario();
      final original = s.recurring.onDelete!;
      s.recurring.onDelete = (id) async {
        await gate.future;
        await original(id);
      };
      await _open(tester, s);

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
      expect(tester.widget<OutlinedButton>(_decline).onPressed, isNull);
      await tester.tap(_close, warnIfMissed: false);
      await tester.pump();
      await tester.tapAt(const Offset(2, 2));
      await tester.pump();
      await tester
          .state<NavigatorState>(find.byType(Navigator).last)
          .maybePop();
      await tester.pump();
      expect(_dialog, findsOneWidget);

      gate.complete();
      await showToast(tester);
      expect(_dialog, findsNothing);
      await dismissToasts(tester);
    });

    testWidgets('anti doble envío: dos toques, una sola llamada', (
      tester,
    ) async {
      final gate = Completer<void>();
      final s = _scenario();
      s.recurring.onDelete = (_) => gate.future;
      await _open(tester, s);

      await tester.tap(_confirm);
      await tester.pump();
      await tester.tap(_confirm, warnIfMissed: false);
      await tester.pump();

      expect(s.recurring.deleteCalls, 1);
      gate.complete();
      await showToast(tester);
      await dismissToasts(tester);
      expect(s.recurring.deleteCalls, 1);
    });
  });

  group('error del servidor', () {
    const failure = ApiException(
      'Este pago recurrente ya está finalizado.',
      code: 'YA_FINALIZADO',
      statusCode: 422,
    );

    testWidgets('toast con el mensaje en español y el diálogo sigue', (
      tester,
    ) async {
      await _open(tester, _scenario(failWith: failure));

      await tester.tap(_confirm);
      await showToast(tester);

      expect(
        find.text('Este pago recurrente ya está finalizado.'),
        findsOneWidget,
      );
      expect(find.text('Pago recurrente eliminado'), findsNothing);
      expect(_dialog, findsOneWidget);
      expect(_confirmEnabled(tester), isTrue);
      expect(find.text('devolvió true'), findsNothing);
      await dismissToasts(tester);
    });

    testWidgets('tras el error, cerrar devuelve false', (tester) async {
      await _open(tester, _scenario(failWith: failure));
      await tester.tap(_confirm);
      await showToast(tester);
      await dismissToasts(tester);

      await tester.tap(_close);
      await tester.pumpAndSettle();

      expect(find.text('devolvió false'), findsOneWidget);
    });

    testWidgets('reintentar después de un error sí elimina', (tester) async {
      final s = _scenario(failWith: const NetworkException('Sin conexión.'));
      await _open(tester, s);
      await tester.tap(_confirm);
      await showToast(tester);
      await dismissToasts(tester);

      s.failWith = null;
      await tester.tap(_confirm);
      await showToast(tester);

      expect(find.text('devolvió true'), findsOneWidget);
      expect(s.recurring.deleteCalls, 2);
      await dismissToasts(tester);
    });
  });

  group('cancelar', () {
    testWidgets('«Cancelar» y la X devuelven false sin llamar al servidor', (
      tester,
    ) async {
      final s = _scenario();
      await _open(tester, s);
      await tester.tap(_decline);
      await tester.pumpAndSettle();
      expect(find.text('devolvió false'), findsOneWidget);

      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();
      await tester.tap(_close);
      await tester.pumpAndSettle();

      expect(find.text('devolvió false'), findsOneWidget);
      expect(s.recurring.deleteCalls, 0);
    });

    testWidgets('tocar fuera cierra y devuelve false', (tester) async {
      await _open(tester, _scenario());

      await tester.tapAt(const Offset(2, 2));
      await tester.pumpAndSettle();

      expect(_dialog, findsNothing);
      expect(find.text('devolvió false'), findsOneWidget);
    });
  });

  group('sin desbordes (320/390/800/1300 × teclado × texto 1.5)', () {
    final longName =
        'Servicios públicos domiciliarios y otros conceptos varios del hogar '
        'de la casa de campo familiar';

    Future<void> open(WidgetTester tester) async {
      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();
      expect(_dialog, findsOneWidget);
    }

    testWidgets('ingreso con nombre corto', (tester) async {
      await expectScreenNoOverflow(
        tester,
        screen: const _Host(),
        overrides: () => _scenario().overrides,
        prepare: open,
      );
    });

    testWidgets('gasto con nombre de 80+ caracteres', (tester) async {
      await expectScreenNoOverflow(
        tester,
        screen: _Host(name: longName, isIncome: false),
        overrides: () => _scenario().overrides,
        prepare: open,
      );
    });

    testWidgets('eliminando (progreso en el botón)', (tester) async {
      await expectScreenNoOverflow(
        tester,
        screen: _Host(name: longName),
        overrides: () {
          final s = _scenario();
          s.recurring.onDelete = (_) => Completer<void>().future;
          return s.overrides;
        },
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
    });
  });
}
