import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_cuentas/core/errors/app_exception.dart';
import 'package:sistema_cuentas/core/models/movement_type.dart';
import 'package:sistema_cuentas/core/utils/date_formatter.dart';
import 'package:sistema_cuentas/features/dues/models/due.dart';
import 'package:sistema_cuentas/features/dues/widgets/pay_due_dialog.dart';
import 'package:sistema_cuentas/features/movements/models/due_payment_draft.dart';
import 'package:sistema_cuentas/features/movements/models/movement.dart';
import 'package:sistema_cuentas/features/movements/providers/movements_provider.dart';

import '../../../helpers/movement_fixtures.dart';
import '../../../helpers/recurring_fixtures.dart';
import '../../../support/fake_dues_repository.dart';
import '../../../support/fake_movements_repository.dart';
import '../../../support/pump_recurring_app.dart';
import '../../../support/pick_catalog_card.dart';
import '../../../support/recurring_overrides.dart';

Finder get _dialog => find.byType(PayDueDialog);
Finder get _confirm =>
    find.descendant(of: _dialog, matching: find.bySubtype<FilledButton>());
Finder get _cancel => find.descendant(
  of: _dialog,
  matching: find.widgetWithText(OutlinedButton, 'Cancelar'),
);
Finder get _close =>
    find.descendant(of: _dialog, matching: find.byTooltip('Cerrar'));
Finder get _amountField =>
    find.descendant(of: _dialog, matching: find.byType(TextFormField)).first;

bool _confirmEnabled(WidgetTester tester) =>
    tester.widget<FilledButton>(_confirm).onPressed != null;

String _amountText(WidgetTester tester) =>
    tester.widget<TextFormField>(_amountField).controller!.text;

Movement _paid({int id = 99}) => buildMovement(
  id: id,
  type: MovementType.income,
  valueCents: 18000000,
  date: DateTime.now(),
  description: 'Arriendo de Oscar',
);

class _Scenario {
  _Scenario({
    List<Due>? dues,
    Future<Movement> Function(DuePaymentDraft draft)? register,
  }) : duesRepository = FakeDuesRepository(
         (_) async => buildDuesMonth(dues ?? [buildDue()]),
       ) {
    movements = FakeMovementsRepository(
      onList: (_, _) async => const [],
      onRegisterDue: register ?? (_) async => _paid(),
    );
  }

  final FakeDuesRepository duesRepository;
  late final FakeMovementsRepository movements;
  late final ProviderContainer container;

  Future<void> open(
    WidgetTester tester, {
    double width = 390,
    double keyboard = 0,
    double textScale = 1,
  }) async {
    container = await pumpRecurringApp(
      tester,
      width: width,
      keyboard: keyboard,
      textScale: textScale,
      overrides: recurringOverrides(dues: duesRepository, movements: movements),
    );
    // La lista de movimientos del mes debe estar cargada para el upsert.
    await container.read(movementsProvider.future);
    await tester.tap(find.byType(FilledButton).last);
    await tester.pumpAndSettle();
  }
}

Future<void> _pickMethod(WidgetTester tester, String option) =>
    pickCatalogOption(tester, 'Medio de pago', option);

/// Deja entrar el aviso (`AppToast`).
Future<void> _showToast(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pump(const Duration(milliseconds: 500));
}

Future<void> _dismissToasts(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 5));
  await tester.pumpAndSettle();
}

void main() {
  group('apertura', () {
    testWidgets(
      'ingreso: «Registrar cobro», descripción y valor inicial = saldo (sin repetirlo debajo)',
      (tester) async {
        await _Scenario().open(tester);

        expect(_dialog, findsOneWidget);
        expect(
          find.text('Registrar cobro'),
          findsNWidgets(2),
        ); // título + botón
        expect(find.text('Arriendo de Oscar'), findsWidgets);
        expect(find.textContaining('Saldo'), findsNothing);
        expect(_amountText(tester), '180.000');
        expect(find.text(formatDate(DateTime.now())), findsOneWidget);
        expect(_confirmEnabled(tester), isTrue);
      },
    );

    testWidgets('con contacto, el subtítulo dice con quién y de qué es', (
      tester,
    ) async {
      await _Scenario(
        dues: [
          buildDue(description: 'Desarrollo mensual', contact: 'Oscar FCS'),
        ],
      ).open(tester);

      expect(find.text('Oscar FCS · Desarrollo mensual'), findsOneWidget);
    });

    testWidgets('sin contacto, el subtítulo es solo la descripción', (
      tester,
    ) async {
      await _Scenario(dues: [buildDue(description: 'Desarrollo mensual')])
          .open(tester);

      expect(find.text('Desarrollo mensual'), findsWidgets);
      expect(
        find.descendant(of: _dialog, matching: find.textContaining(' · ')),
        findsNothing,
      );
    });

    testWidgets('gasto: «Registrar pago»', (tester) async {
      await _Scenario(
        dues: [buildDue(type: MovementType.expense, description: 'Netflix')],
      ).open(tester);

      expect(find.text('Registrar pago'), findsNWidgets(2));
    });

    testWidgets('tras un abono, el valor inicial es lo que falta (el saldo)', (
      tester,
    ) async {
      await _Scenario(
        dues: [buildDue(paidCents: 9000000, status: DueStatus.partial)],
      ).open(tester);

      expect(_amountText(tester), '90.000');
      expect(find.textContaining('Saldo'), findsNothing);
    });
  });

  group('validación', () {
    testWidgets('no deja pasar del saldo y dice cuánto es', (tester) async {
      final s = _Scenario();
      await s.open(tester);
      await _pickMethod(tester, 'Nequi');

      await tester.enterText(_amountField, '180001');
      await tester.tap(_confirm);
      await tester.pumpAndSettle();

      expect(
        find.text(r'No puede pasar del saldo ($ 180.000).'),
        findsOneWidget,
      );
      expect(s.movements.registerDueCalls, 0);
      expect(_dialog, findsOneWidget);
    });

    testWidgets('el valor vacío o en cero pide el valor', (tester) async {
      final s = _Scenario();
      await s.open(tester);
      await _pickMethod(tester, 'Nequi');

      await tester.enterText(_amountField, '');
      await tester.tap(_confirm);
      await tester.pumpAndSettle();
      expect(find.text('Escribe el valor.'), findsOneWidget);

      await tester.enterText(_amountField, '0');
      await tester.tap(_confirm);
      await tester.pumpAndSettle();
      expect(find.text('Escribe el valor.'), findsOneWidget);
      expect(s.movements.registerDueCalls, 0);
    });

    testWidgets('el medio de pago es obligatorio', (tester) async {
      final s = _Scenario();
      await s.open(tester);

      await tester.tap(_confirm);
      await tester.pumpAndSettle();

      expect(find.text('Elige el medio de pago.'), findsOneWidget);
      expect(s.movements.registerDueCalls, 0);
      expect(_dialog, findsOneWidget);
      expect(
        _confirmEnabled(tester),
        isTrue,
        reason: 'apagado no: sigue activo',
      );
    });

    testWidgets(
      'el valor se escribe con puntos de miles y no pasa de 13 caracteres',
      (tester) async {
        await _Scenario().open(tester);

        await tester.enterText(_amountField, '55000');
        expect(_amountText(tester), '55.000');

        await tester.enterText(_amountField, '9999999999999999');
        expect(_amountText(tester).length, lessThanOrEqualTo(13));
      },
    );
  });

  group('éxito', () {
    testWidgets(
      'cobro completo: manda el borrador, avisa, cierra y refresca el mes y el movimiento',
      (tester) async {
        final s = _Scenario();
        await s.open(tester);
        await _pickMethod(tester, 'Nequi');

        await tester.tap(_confirm);
        await _showToast(tester);

        expect(find.text('Cobro registrado'), findsOneWidget);
        expect(_dialog, findsNothing);
        final draft = s.movements.dueDrafts.single;
        expect(draft.dueId, 1);
        expect(draft.recurringId, 10);
        expect(draft.type, MovementType.income);
        expect(draft.amountPesos, 180000);
        expect(draft.methodId, 2);
        expect(draft.note, isNull);
        expect(draft.toJson().containsKey('id_pago_recurrente'), isFalse);
        await _dismissToasts(tester);

        expect(
          s.duesRepository.calls,
          2,
          reason: 'los saldos se vuelven a pedir',
        );
        expect(
          s.container.read(movementsProvider).requireValue.map((m) => m.id),
          [99],
          reason: 'el movimiento ya está en Inicio',
        );
      },
    );

    testWidgets('abono parcial con nota recortada', (tester) async {
      final s = _Scenario();
      await s.open(tester);
      await _pickMethod(tester, 'Bancolombia');
      await tester.enterText(_amountField, '50000');
      await tester.enterText(
        find.descendant(
          of: _dialog,
          matching: find.widgetWithText(TextFormField, 'Nota (opcional)'),
        ),
        '  primer abono  ',
      );

      await tester.tap(_confirm);
      await _showToast(tester);
      await _dismissToasts(tester);

      final draft = s.movements.dueDrafts.single;
      expect(draft.amountPesos, 50000);
      expect(draft.methodId, 5);
      expect(draft.note, 'primer abono');
    });

    testWidgets('gasto: «Pago registrado»', (tester) async {
      final s = _Scenario(
        dues: [buildDue(type: MovementType.expense, description: 'Netflix')],
        register: (_) async => buildMovement(date: DateTime.now()),
      );
      await s.open(tester);
      await _pickMethod(tester, 'Nequi');

      await tester.tap(_confirm);
      await _showToast(tester);

      expect(find.text('Pago registrado'), findsOneWidget);
      expect(_dialog, findsNothing);
      await _dismissToasts(tester);
    });
  });

  group('guardando', () {
    testWidgets(
      'botón con progreso y apagado, sin doble envío; nada deja cerrar el diálogo',
      (tester) async {
        final completer = Completer<Movement>();
        final s = _Scenario(register: (_) => completer.future);
        await s.open(tester);
        await _pickMethod(tester, 'Nequi');

        await tester.tap(_confirm);
        await tester.pump();

        expect(
          find.descendant(
            of: _confirm,
            matching: find.byType(CircularProgressIndicator),
          ),
          findsOneWidget,
        );
        expect(_confirmEnabled(tester), isFalse);
        expect(
          tester.widget<OutlinedButton>(_cancel).onPressed,
          isNull,
          reason: 'Cancelar apagado mientras guarda',
        );

        await tester.tap(_confirm, warnIfMissed: false);
        await tester.pump();
        expect(s.movements.registerDueCalls, 1);

        // El atrás del sistema no cierra.
        await tester.binding.handlePopRoute();
        // Con el progreso girando no hay reposo: avanza un tiempo fijo, más que
        // la animación de salida de un diálogo.
        await tester.pump(const Duration(milliseconds: 400));
        expect(_dialog, findsOneWidget, reason: 'atrás del sistema bloqueado');

        completer.complete(_paid());
        await tester.pumpAndSettle();
        await _showToast(tester);
        expect(_dialog, findsNothing);
        expect(s.movements.registerDueCalls, 1);
        await _dismissToasts(tester);
      },
    );

    testWidgets('los campos quedan de solo lectura mientras guarda', (
      tester,
    ) async {
      final completer = Completer<Movement>();
      final s = _Scenario(register: (_) => completer.future);
      await s.open(tester);
      await _pickMethod(tester, 'Nequi');

      await tester.tap(_confirm);
      await tester.pump();

      expect(
        tester
            .widget<TextField>(
              find.descendant(
                of: _amountField,
                matching: find.byType(TextField),
              ),
            )
            .readOnly,
        isTrue,
      );
      completer.complete(_paid());
      await tester.pumpAndSettle();
      await _showToast(tester);
      await _dismissToasts(tester);
    });

    testWidgets('la X del encabezado NO cierra el diálogo mientras guarda', (
      tester,
    ) async {
      final completer = Completer<Movement>();
      final s = _Scenario(register: (_) => completer.future);
      await s.open(tester);
      await _pickMethod(tester, 'Nequi');
      await tester.tap(_confirm);
      await tester.pump();

      await tester.tap(_close, warnIfMissed: false);
      // Con el progreso girando no hay reposo: avanza un tiempo fijo.
      await tester.pump(
        const Duration(milliseconds: 400),
      ); // deja terminar la animación de salida

      expect(
        _dialog,
        findsOneWidget,
        reason:
            'DEFECTO en lib: DialogHeader (dialog_header.dart:58) usa '
            '`onClose ?? pop()`; el diálogo pasa onClose null al guardar y la X '
            'sigue ahí y cierra (PopScope no frena Navigator.pop)',
      );
      completer.complete(_paid());
      await tester.pumpAndSettle();
      await _showToast(tester);
      await _dismissToasts(tester);
    });

    testWidgets(
      'si el diálogo se desmonta mientras guarda, el movimiento y los saldos se actualizan igual',
      (tester) async {
        final completer = Completer<Movement>();
        final s = _Scenario(register: (_) => completer.future);
        await s.open(tester);
        await _pickMethod(tester, 'Nequi');
        await tester.tap(_confirm);
        await tester.pump();

        // Algo desmonta el diálogo (p. ej. se cierra la sesión de la ruta).
        Navigator.of(tester.element(_dialog), rootNavigator: true).pop();
        await tester.pumpAndSettle();
        expect(_dialog, findsNothing);

        completer.complete(_paid());
        await tester.pumpAndSettle();
        await tester.pump(const Duration(seconds: 5));

        expect(tester.takeException(), isNull);
        expect(
          s.container.read(movementsProvider).requireValue.map((m) => m.id),
          [99],
        );
        expect(s.duesRepository.calls, 2);
      },
    );
  });

  group('error', () {
    testWidgets(
      'aviso en español, el diálogo se queda abierto con sus valores',
      (tester) async {
        final s = _Scenario(
          register: (_) async => throw const ApiException(
            'El valor supera el saldo del vencimiento.',
            code: 'VALOR_EXCEDE_SALDO',
            statusCode: 422,
          ),
        );
        await s.open(tester);
        await _pickMethod(tester, 'Nequi');
        await tester.enterText(_amountField, '120000');

        await tester.tap(_confirm);
        await _showToast(tester);

        expect(
          find.text('El valor supera el saldo del vencimiento.'),
          findsOneWidget,
        );
        expect(find.text('Cobro registrado'), findsNothing);
        expect(_dialog, findsOneWidget);
        expect(_amountText(tester), '120.000');
        expect(find.text('Nequi'), findsWidgets);
        expect(_confirmEnabled(tester), isTrue);
        expect(s.duesRepository.calls, 1, reason: 'no refresca si falló');
        expect(s.container.read(movementsProvider).requireValue, isEmpty);
        await _dismissToasts(tester);
      },
    );

    testWidgets('tras el error se puede reintentar y esta vez cierra', (
      tester,
    ) async {
      var attempt = 0;
      final s = _Scenario(
        register: (_) async {
          attempt++;
          if (attempt == 1) throw const NetworkException('Sin conexión.');
          return _paid();
        },
      );
      await s.open(tester);
      await _pickMethod(tester, 'Nequi');

      await tester.tap(_confirm);
      await _showToast(tester);
      expect(find.text('Sin conexión.'), findsOneWidget);
      await _dismissToasts(tester);

      await tester.tap(_confirm);
      await _showToast(tester);
      expect(find.text('Cobro registrado'), findsOneWidget);
      expect(_dialog, findsNothing);
      expect(s.movements.registerDueCalls, 2);
      await _dismissToasts(tester);
    });
  });

  group('cancelar', () {
    testWidgets('Cancelar y la X cierran sin llamar al servidor', (
      tester,
    ) async {
      final s = _Scenario();
      await s.open(tester);
      await tester.tap(_cancel);
      await tester.pumpAndSettle();
      expect(_dialog, findsNothing);

      await tester.tap(find.byType(FilledButton).last);
      await tester.pumpAndSettle();
      await tester.tap(_close);
      await tester.pumpAndSettle();
      expect(_dialog, findsNothing);
      expect(s.movements.registerDueCalls, 0);
    });
  });

  group('distribución del valor y la fecha (formDatePairMinWidth 320)', () {
    Future<bool> sameRow(
      WidgetTester tester, {
      required double width,
      double scale = 1,
    }) async {
      await _Scenario().open(tester, width: width, textScale: scale);
      return tester.getTopLeft(_amountField).dy ==
          tester
              .getTopLeft(
                find.descendant(
                  of: _dialog,
                  matching: find.widgetWithText(InputDecorator, 'Fecha'),
                ),
              )
              .dy;
    }

    testWidgets('en 800 y 1300 van en fila', (tester) async {
      expect(await sameRow(tester, width: 800), isTrue);
      expect(await sameRow(tester, width: 1300), isTrue);
    });

    testWidgets('en 320 el diálogo es más estrecho que el mínimo: apilados', (
      tester,
    ) async {
      // 320 − 2 × 16 de margen − 2 × 24 de relleno = 224 < 320.
      expect(await sameRow(tester, width: 320), isFalse);
    });

    testWidgets(
      'con texto 1.5 el mínimo se multiplica: apilados incluso en 800',
      (tester) async {
        // 320 × 1.5 = 480 y el diálogo útil mide 520 − 48 = 472.
        expect(await sameRow(tester, width: 800, scale: 1.5), isFalse);
      },
    );
  });
}
