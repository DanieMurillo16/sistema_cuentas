import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_cuentas/core/errors/app_exception.dart';
import 'package:sistema_cuentas/core/models/movement_type.dart';
import 'package:sistema_cuentas/core/router/app_routes.dart';
import 'package:sistema_cuentas/core/utils/date_formatter.dart';
import 'package:sistema_cuentas/features/recurring/models/finish_draft.dart';
import 'package:sistema_cuentas/features/recurring/models/recurring_payment.dart';
import 'package:sistema_cuentas/features/recurring/models/recurring_detail.dart';
import 'package:sistema_cuentas/features/recurring/widgets/finish_recurring_dialog.dart';

import '../../../helpers/recurring_fixtures.dart';
import '../../../support/fake_recurring_repository.dart';
import '../../../support/pump_recurring_app.dart';
import '../../../support/recurring_overrides.dart';
import '../../../support/pick_catalog_card.dart';

Finder get _dialog => find.byType(FinishRecurringDialog);
Finder get _confirm =>
    find.descendant(of: _dialog, matching: find.bySubtype<FilledButton>());
Finder get _cancel => find.descendant(
  of: _dialog,
  matching: find.widgetWithText(OutlinedButton, 'Cancelar'),
);
Finder get _close =>
    find.descendant(of: _dialog, matching: find.byTooltip('Cerrar'));
Finder _field(String label) => find.descendant(
  of: _dialog,
  matching: find.widgetWithText(TextFormField, label),
);
Finder get _dateField => find.descendant(
  of: _dialog,
  matching: find.widgetWithText(InputDecorator, 'Cierre'),
);
Finder _dropdown(String label) => catalogCard(label);

bool _confirmEnabled(WidgetTester tester) =>
    tester.widget<FilledButton>(_confirm).onPressed != null;

class _Scenario {
  _Scenario({
    RecurringPayment? payment,
    Future<void> Function(FinishDraft draft)? finish,
    Future<RecurringDetail> Function(int id)? detail,
  }) : payment = payment ?? buildRecurring(contact: 'Oscar') {
    recurring = FakeRecurringRepository(
      onList: () async => [this.payment],
      onDetail: detail ?? (id) async => buildDetail(payment: this.payment),
      onFinish: finish,
    );
  }

  final RecurringPayment payment;
  late final FakeRecurringRepository recurring;
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
      initialLocation: AppRoutes.recurringDetailFor(payment.id),
      overrides: recurringOverrides(recurring: recurring),
    );
    await tester.tap(
      find.descendant(
        of: find.bySubtype<OutlinedButton>(),
        matching: find.text('Finalizar'),
      ),
    );
    await tester.pumpAndSettle();
  }
}

Future<void> _pickMethod(WidgetTester tester, String option) =>
    pickCatalogOption(tester, 'Medio de pago del capital', option);

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
    testWidgets('título, aviso de que es irreversible y campos del cierre', (
      tester,
    ) async {
      await _Scenario().open(tester);

      expect(_dialog, findsOneWidget);
      expect(find.text('Finalizar'), findsWidgets);
      expect(find.text('Arriendo de Oscar'), findsWidgets);
      expect(
        find.text(
          'No se puede deshacer: los meses pendientes quedan omitidos.',
        ),
        findsOneWidget,
      );
      expect(find.text('Cierre'), findsOneWidget);
      expect(find.text(formatDate(DateTime.now())), findsOneWidget);
      expect(_field('Capital (opcional)'), findsOneWidget);
      expect(find.text('Lo que te devolvieron'), findsOneWidget);
      expect(_field('Motivo del cierre'), findsOneWidget);
    });

    testWidgets('gasto: el capital es «Lo que pagaste»', (tester) async {
      await _Scenario(payment: buildRecurring(type: MovementType.expense))
          .open(tester);
      expect(find.text('Lo que pagaste'), findsOneWidget);
    });

    testWidgets(
      'es destructivo: el botón «Finalizar» va en el color de error',
      (tester) async {
        await _Scenario().open(tester);
        final error = Theme.of(tester.element(_dialog)).colorScheme.error;
        final style = tester.widget<FilledButton>(_confirm).style!;
        expect(style.backgroundColor!.resolve(<WidgetState>{}), error);
      },
    );

    testWidgets('el medio de pago NO aparece sin capital', (tester) async {
      await _Scenario().open(tester);
      expect(_dropdown('Medio de pago del capital'), findsNothing);
    });
  });

  group('el medio de pago del capital', () {
    testWidgets('aparece al escribir un capital y se va al borrarlo', (
      tester,
    ) async {
      await _Scenario().open(tester);

      await tester.enterText(_field('Capital (opcional)'), '1000000');
      await tester.pumpAndSettle();
      expect(_dropdown('Medio de pago del capital'), findsOneWidget);

      await tester.enterText(_field('Capital (opcional)'), '');
      await tester.pumpAndSettle();
      expect(_dropdown('Medio de pago del capital'), findsNothing);
    });

    testWidgets('un capital en cero no pide medio', (tester) async {
      await _Scenario().open(tester);
      await tester.enterText(_field('Capital (opcional)'), '0');
      await tester.pumpAndSettle();
      expect(_dropdown('Medio de pago del capital'), findsNothing);
    });

    testWidgets(
      'con capital y sin medio: error bajo el campo, sin llamar al servidor',
      (tester) async {
        final s = _Scenario();
        await s.open(tester);
        await tester.enterText(_field('Capital (opcional)'), '1000000');
        await tester.enterText(_field('Motivo del cierre'), 'Me devolvió todo');
        await tester.pumpAndSettle();

        await tester.tap(_confirm);
        await tester.pumpAndSettle();

        expect(
          find.text('Elige el medio de pago del capital.'),
          findsOneWidget,
        );
        expect(s.recurring.finishCalls, 0);
        expect(_dialog, findsOneWidget);
        expect(_confirmEnabled(tester), isTrue);
      },
    );
  });

  group('validación', () {
    testWidgets('el motivo es obligatorio (vacío y de 2 letras no pasan)', (
      tester,
    ) async {
      final s = _Scenario();
      await s.open(tester);

      await tester.tap(_confirm);
      await tester.pumpAndSettle();
      const message = 'Cuenta por qué se cierra (mínimo 3 letras).';
      expect(find.text(message), findsOneWidget);

      await tester.enterText(_field('Motivo del cierre'), 'ok');
      await tester.tap(_confirm);
      await tester.pumpAndSettle();
      expect(find.text(message), findsOneWidget);
      expect(s.recurring.finishCalls, 0);
    });

    testWidgets('con 3 letras ya sirve', (tester) async {
      final s = _Scenario();
      await s.open(tester);
      await tester.enterText(_field('Motivo del cierre'), 'Fin');

      await tester.tap(_confirm);
      await _showToast(tester);
      await _dismissToasts(tester);

      expect(s.recurring.finishCalls, 1);
    });

    testWidgets(
      'un acuerdo que empieza en el futuro: el calendario abre (sin rango vacío) y cerrar hoy avisa',
      (tester) async {
        final start = DateTime.now().add(const Duration(days: 60));
        final s = _Scenario(payment: buildRecurring(startDate: start));
        await s.open(tester);

        await tester.tap(find.text('Cierre'));
        await tester.pumpAndSettle();
        expect(find.byType(DatePickerDialog), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.tap(
          find.descendant(
            of: find.byType(DatePickerDialog),
            matching: find.text('Cancelar'),
          ),
        );
        await tester.pumpAndSettle();

        await tester.enterText(_field('Motivo del cierre'), 'No arrancó');
        await tester.tap(_confirm);
        await _showToast(tester);

        expect(
          find.text('No puede ser anterior al inicio del acuerdo.'),
          findsOneWidget,
        );
        expect(s.recurring.finishCalls, 0);
        await _dismissToasts(tester);
      },
    );
  });

  group('éxito', () {
    testWidgets(
      'sin capital: manda fecha y motivo recortado, sin capital ni medio',
      (tester) async {
        final s = _Scenario();
        await s.open(tester);
        await tester.enterText(_field('Motivo del cierre'), '  Se mudó  ');

        await tester.tap(_confirm);
        await _showToast(tester);

        expect(find.text('Pago recurrente finalizado'), findsOneWidget);
        expect(_dialog, findsNothing);
        final draft = s.recurring.finished.single;
        expect(draft.recurringId, 10);
        expect(draft.closingNote, 'Se mudó');
        expect(draft.endDate, dateOnly(DateTime.now()));
        expect(draft.capitalPesos, isNull);
        expect(draft.methodId, isNull);
        expect(
          draft.toJson().keys,
          containsAll(['id_pago_recurrente', 'fecha_fin', 'nota_cierre']),
        );
        expect(draft.toJson().containsKey('valor_capital'), isFalse);
        await _dismissToasts(tester);
      },
    );

    testWidgets('con capital y medio: ambos viajan', (tester) async {
      final s = _Scenario();
      await s.open(tester);
      await tester.enterText(_field('Capital (opcional)'), '2000000');
      await tester.enterText(
        _field('Motivo del cierre'),
        'Devolvió el capital',
      );
      await tester.pumpAndSettle();
      await _pickMethod(tester, 'Bancolombia');

      await tester.tap(_confirm);
      await _showToast(tester);
      await _dismissToasts(tester);

      final draft = s.recurring.finished.single;
      expect(draft.capitalPesos, 2000000);
      expect(draft.methodId, 5);
      expect(draft.toJson()['valor_capital'], '2000000');
      expect(draft.toJson()['id_medio'], 5);
    });

    testWidgets(
      'elegir un medio y luego borrar el capital: no se manda el medio',
      (tester) async {
        final s = _Scenario();
        await s.open(tester);
        await tester.enterText(_field('Capital (opcional)'), '2000000');
        await tester.pumpAndSettle();
        await _pickMethod(tester, 'Nequi');
        await tester.enterText(_field('Capital (opcional)'), '');
        await tester.pumpAndSettle();
        await tester.enterText(_field('Motivo del cierre'), 'Cierre simple');

        await tester.tap(_confirm);
        await _showToast(tester);
        await _dismissToasts(tester);

        final draft = s.recurring.finished.single;
        expect(draft.capitalPesos, isNull);
        expect(draft.methodId, isNull);
      },
    );

    testWidgets(
      'la ficha de atrás se actualiza: finalizado, con motivo y sin botón',
      (tester) async {
        var closed = false;
        final s = _Scenario(
          finish: (_) async => closed = true,
          detail: (id) async => closed
              ? buildDetail(
                  payment: buildRecurring(
                    active: false,
                    endDate: DateTime(2026, 10, 13),
                    closingNote: 'Se mudó',
                  ),
                )
              : buildDetail(payment: buildRecurring()),
        );
        await s.open(tester);
        await tester.enterText(_field('Motivo del cierre'), 'Se mudó');

        await tester.tap(_confirm);
        await _showToast(tester);
        await _dismissToasts(tester);

        expect(_dialog, findsNothing);
        expect(
          s.recurring.detailCalls,
          2,
          reason: 'el detalle se vuelve a pedir',
        );
        expect(find.text('Finalizado'), findsOneWidget);
        expect(find.text('Se mudó'), findsOneWidget);
        expect(
          find.descendant(
            of: find.bySubtype<OutlinedButton>(),
            matching: find.text('Finalizar'),
          ),
          findsNothing,
        );
      },
    );
  });

  group('guardando', () {
    testWidgets(
      'botón con progreso y apagado; Cancelar apagado; atrás bloqueado',
      (tester) async {
        final completer = Completer<void>();
        final s = _Scenario(finish: (_) => completer.future);
        await s.open(tester);
        await tester.enterText(_field('Motivo del cierre'), 'Se mudó');

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
        expect(tester.widget<OutlinedButton>(_cancel).onPressed, isNull);

        await tester.tap(_confirm, warnIfMissed: false);
        await tester.pump();
        expect(s.recurring.finishCalls, 1, reason: 'sin doble envío');

        await tester.binding.handlePopRoute();
        // Con el progreso girando no hay reposo: avanza un tiempo fijo.
        await tester.pump(const Duration(milliseconds: 400));
        expect(_dialog, findsOneWidget, reason: 'atrás del sistema bloqueado');

        completer.complete();
        await tester.pumpAndSettle();
        await _showToast(tester);
        expect(_dialog, findsNothing);
        await _dismissToasts(tester);
      },
    );

    testWidgets('la X del encabezado NO cierra el diálogo mientras guarda', (
      tester,
    ) async {
      final completer = Completer<void>();
      final s = _Scenario(finish: (_) => completer.future);
      await s.open(tester);
      await tester.enterText(_field('Motivo del cierre'), 'Se mudó');
      await tester.tap(_confirm);
      await tester.pump();

      await tester.tap(_close, warnIfMissed: false);
      // Con el progreso girando no hay reposo: avanza un tiempo fijo.
      await tester.pump(const Duration(milliseconds: 400));

      expect(
        _dialog,
        findsOneWidget,
        reason:
            'DEFECTO en lib: DialogHeader (dialog_header.dart:58) usa '
            '`onClose ?? pop()`; el diálogo pasa onClose null al guardar y la X '
            'sigue ahí y cierra (PopScope no frena Navigator.pop)',
      );
      completer.complete();
      await tester.pumpAndSettle();
      await _showToast(tester);
      await _dismissToasts(tester);
    });

    testWidgets(
      'si el diálogo se desmonta mientras guarda, igual se invalida lo viejo',
      (tester) async {
        final completer = Completer<void>();
        final s = _Scenario(finish: (_) => completer.future);
        await s.open(tester);
        await tester.enterText(_field('Motivo del cierre'), 'Se mudó');
        await tester.tap(_confirm);
        await tester.pump();
        final detailCallsBefore = s.recurring.detailCalls;

        Navigator.of(tester.element(_dialog), rootNavigator: true).pop();
        await tester.pumpAndSettle();
        completer.complete();
        await tester.pumpAndSettle();
        await tester.pump(const Duration(seconds: 5));

        expect(tester.takeException(), isNull);
        expect(s.recurring.detailCalls, detailCallsBefore + 1);
      },
    );
  });

  group('error', () {
    testWidgets(
      'aviso en español; el diálogo se queda abierto con lo escrito',
      (tester) async {
        final s = _Scenario(
          finish: (_) async => throw const ApiException(
            'La fecha de cierre no puede ser futura.',
            code: 'FECHA_FUTURA',
            statusCode: 422,
          ),
        );
        await s.open(tester);
        await tester.enterText(_field('Motivo del cierre'), 'Se mudó');

        await tester.tap(_confirm);
        await _showToast(tester);

        expect(
          find.text('La fecha de cierre no puede ser futura.'),
          findsOneWidget,
        );
        expect(find.text('Pago recurrente finalizado'), findsNothing);
        expect(_dialog, findsOneWidget);
        expect(
          tester
              .widget<TextFormField>(_field('Motivo del cierre'))
              .controller!
              .text,
          'Se mudó',
        );
        expect(_confirmEnabled(tester), isTrue);
        expect(s.recurring.detailCalls, 1, reason: 'no refresca si falló');
        await _dismissToasts(tester);
      },
    );

    testWidgets('tras el error se puede reintentar', (tester) async {
      var attempt = 0;
      final s = _Scenario(
        finish: (_) async {
          attempt++;
          if (attempt == 1) throw const NetworkException('Sin conexión.');
        },
      );
      await s.open(tester);
      await tester.enterText(_field('Motivo del cierre'), 'Se mudó');

      await tester.tap(_confirm);
      await _showToast(tester);
      await _dismissToasts(tester);
      await tester.tap(_confirm);
      await _showToast(tester);

      expect(find.text('Pago recurrente finalizado'), findsOneWidget);
      expect(_dialog, findsNothing);
      expect(s.recurring.finishCalls, 2);
      await _dismissToasts(tester);
    });
  });

  testWidgets('Cancelar y la X cierran sin llamar al servidor', (tester) async {
    final s = _Scenario();
    await s.open(tester);
    await tester.tap(_cancel);
    await tester.pumpAndSettle();
    expect(_dialog, findsNothing);

    await tester.tap(
      find.descendant(
        of: find.bySubtype<OutlinedButton>(),
        matching: find.text('Finalizar'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(_close);
    await tester.pumpAndSettle();
    expect(_dialog, findsNothing);
    expect(s.recurring.finishCalls, 0);
  });

  group('distribución del cierre y el capital (formDatePairMinWidth 320)', () {
    Future<bool> sameRow(
      WidgetTester tester, {
      required double width,
      double scale = 1,
    }) async {
      await _Scenario().open(tester, width: width, textScale: scale);
      // Se comparan los CAMPOS (no las etiquetas, que flotan distinto).
      return tester.getTopLeft(_dateField).dy ==
          tester.getTopLeft(_field('Capital (opcional)')).dy;
    }

    testWidgets('en fila en 800 y 1300; apilados en 320 y con texto 1.5', (
      tester,
    ) async {
      expect(await sameRow(tester, width: 800), isTrue);
      expect(await sameRow(tester, width: 1300), isTrue);
      expect(await sameRow(tester, width: 320), isFalse);
      expect(await sameRow(tester, width: 800, scale: 1.5), isFalse);
    });
  });
}
