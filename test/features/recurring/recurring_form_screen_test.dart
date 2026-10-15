import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sistema_cuentas/core/errors/app_exception.dart';
import 'package:sistema_cuentas/core/router/app_routes.dart';
import 'package:sistema_cuentas/features/dues/providers/dues_provider.dart';
import 'package:sistema_cuentas/features/recurring/models/recurring_draft.dart';
import 'package:sistema_cuentas/features/recurring/models/recurring_payment.dart';
import 'package:sistema_cuentas/features/recurring/providers/recurring_list_provider.dart';
import 'package:sistema_cuentas/features/recurring/recurring_screen.dart';
import 'package:sistema_cuentas/features/recurring/widgets/recurring_form.dart';
import 'package:sistema_cuentas/shared/widgets/catalog_picker_sheet.dart';

import '../../helpers/recurring_fixtures.dart';
import '../../support/fake_dues_repository.dart';
import '../../support/fake_recurring_repository.dart';
import '../../support/expect_layout.dart';
import '../../support/pick_catalog_card.dart';
import '../../support/pump_recurring_app.dart';
import '../../support/recurring_overrides.dart';

Finder _text(String label) => find.widgetWithText(TextFormField, label);
Finder get _submit =>
    find.widgetWithText(FilledButton, 'Crear pago recurrente');

class _Scenario {
  _Scenario({Future<RecurringPayment> Function(RecurringDraft draft)? create})
    : dues = FakeDuesRepository((_) async => buildDuesMonth([buildDue()])),
      recurring = FakeRecurringRepository(
        onList: () async => [buildRecurring(id: 1)],
        onCreate: create ?? (_) async => buildRecurring(id: 55, day: 7),
      );

  final FakeDuesRepository dues;
  final FakeRecurringRepository recurring;
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
      initialLocation: AppRoutes.recurringNew,
      overrides: recurringOverrides(dues: dues, recurring: recurring),
    );
  }
}

Future<void> _fill(WidgetTester tester) async {
  await tester.enterText(_text('Nombre'), 'Arriendo de Oscar');
  await tester.enterText(_text('Valor'), '180000');
  await tester.enterText(_text('Día de pago'), '7');
  await pickCatalogOption(tester, 'Categoría', 'Salario');
}

Future<void> _showToast(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pump(const Duration(milliseconds: 500));
}

Future<void> _dismissToasts(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 5));
  await tester.pumpAndSettle();
}

void main() {
  group('validación', () {
    testWidgets('vacío: dice qué falta y no llama al servidor', (tester) async {
      final s = _Scenario();
      await s.open(tester);

      await tester.tap(_submit);
      await tester.pumpAndSettle();

      expect(find.text('Escribe el nombre (mínimo 2 letras).'), findsOneWidget);
      expect(find.text('Escribe el valor.'), findsOneWidget);
      expect(find.text('Un día del 1 al 31.'), findsOneWidget);
      expect(s.recurring.createCalls, 0);
      await _dismissToasts(tester);
    });
  });

  group('éxito', () {
    testWidgets(
      'manda el borrador, avisa, vuelve a Pagos recurrentes y la lista lo ve',
      (tester) async {
        final s = _Scenario();
        await s.open(tester);
        await s.container.read(recurringListProvider.future);
        await _fill(tester);

        await tester.tap(_submit);
        await _showToast(tester);

        expect(find.text('Pago recurrente creado'), findsOneWidget);
        final draft = s.recurring.created.single;
        expect(draft.description, 'Arriendo de Oscar');
        expect(draft.valuePesos, 180000);
        expect(draft.dayOfMonth, 7);
        expect(draft.categoryId, 9);
        await _dismissToasts(tester);

        expect(find.byType(RecurringForm), findsNothing);
        expect(find.byType(RecurringScreen), findsOneWidget);
        expect(
          s.container.read(recurringListProvider).requireValue.map((p) => p.id),
          containsAll([1, 55]),
          reason: 'otra vista ve el acuerdo nuevo sin recargar',
        );
      },
    );
  });

  group('guardando', () {
    testWidgets('botón con progreso y apagado; sin doble envío; campos de solo '
        'lectura', (tester) async {
      final completer = Completer<RecurringPayment>();
      final s = _Scenario(create: (_) => completer.future);
      await s.open(tester);
      await _fill(tester);

      await tester.tap(_submit);
      await tester.pump();

      final button = find.byType(FilledButton);
      expect(
        find.descendant(
          of: button,
          matching: find.byType(CircularProgressIndicator),
        ),
        findsOneWidget,
      );
      expect(tester.widget<FilledButton>(button).onPressed, isNull);
      expect(
        tester.widget<TextField>(find.byType(TextField).first).readOnly,
        isTrue,
      );
      await tester.tap(button, warnIfMissed: false);
      await tester.pump();
      expect(s.recurring.createCalls, 1);

      // El atrás del sistema no cierra mientras guarda.
      await tester.binding.handlePopRoute();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(RecurringForm), findsOneWidget);

      completer.complete(buildRecurring(id: 55));
      await tester.pumpAndSettle();
      await _showToast(tester);
      await _dismissToasts(tester);
      expect(find.byType(RecurringForm), findsNothing);
    });

    testWidgets(
      'si la pantalla se desmonta mientras guarda, el acuerdo entra a la lista '
      'y los vencimientos se piden de nuevo (keepAlive)',
      (tester) async {
        final completer = Completer<RecurringPayment>();
        final s = _Scenario(create: (_) => completer.future);
        await s.open(tester);
        await s.container.read(recurringListProvider.future);
        await s.container.read(duesProvider.future);
        final duesCallsBefore = s.dues.calls;
        await _fill(tester);
        await tester.tap(_submit);
        await tester.pump();

        // Algo desmonta la pantalla (p. ej. se navega a otra pestaña).
        GoRouter.of(tester.element(find.byType(RecurringForm)))
            .go(AppRoutes.home);
        await tester.pumpAndSettle();
        expect(find.byType(RecurringForm), findsNothing);

        completer.complete(buildRecurring(id: 55));
        await tester.pumpAndSettle();
        await tester.pump(const Duration(seconds: 5));

        expect(tester.takeException(), isNull);
        expect(
          s.container.read(recurringListProvider).requireValue.map((p) => p.id),
          containsAll([1, 55]),
        );
        await s.container.read(duesProvider.future);
        expect(
          s.dues.calls,
          duesCallsBefore + 1,
          reason: 'la escritura invalidó los vencimientos pese al desmonte',
        );
      },
    );
  });

  group('error', () {
    testWidgets('aviso en español; la pantalla se queda con lo escrito', (
      tester,
    ) async {
      final s = _Scenario(
        create: (_) async => throw const ApiException(
          'La categoría no puede ser de capital.',
          code: 'CATEGORIA_INVALIDA',
          statusCode: 422,
        ),
      );
      await s.open(tester);
      await _fill(tester);

      await tester.tap(_submit);
      await _showToast(tester);

      expect(
        find.text('La categoría no puede ser de capital.'),
        findsOneWidget,
      );
      expect(find.byType(RecurringForm), findsOneWidget);
      expect(
        tester.widget<TextFormField>(_text('Nombre')).controller!.text,
        'Arriendo de Oscar',
      );
      expect(tester.widget<FilledButton>(_submit).onPressed, isNotNull);
      await _dismissToasts(tester);
    });
  });

  group('campos del formulario', () {
    bool anyFieldFocused(WidgetTester tester) => tester
        .widgetList<EditableText>(find.byType(EditableText))
        .any((e) => e.focusNode.hasFocus);

    final sheet = find.byWidgetPredicate((w) => w is CatalogPickerSheet);
    Finder searchIn() =>
        find.descendant(of: sheet, matching: find.byType(TextField));

    testWidgets(
      'al abrir y asentar ningún campo tiene foco (el teclado no sube solo) '
      'y no hay campo Nota',
      (tester) async {
        await _Scenario().open(tester);
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pumpAndSettle();

        expect(anyFieldFocused(tester), isFalse);
        expect(find.text('Nota (opcional)'), findsNothing);
        expect(find.byType(TextFormField), findsNWidgets(4)); // + capital
        expect(_text('Nombre'), findsOneWidget);
        expect(_text('Valor'), findsOneWidget);
        expect(_text('Día de pago'), findsOneWidget);
      },
    );

    testWidgets(
      'categoría: hoja con buscador y solo las del tipo; elegir rellena la '
      'tarjeta y cierra',
      (tester) async {
        await _Scenario().open(tester);
        expect(
          find.text('Elegir'),
          findsOneWidget,
          reason: 'falta la categoría',
        );
        expect(
          find.text('Ninguno'),
          findsOneWidget,
          reason: 'contacto opcional',
        );

        await openCatalogSheet(tester, 'Categoría');
        expect(sheet, findsOneWidget);
        expect(searchIn(), findsOneWidget);
        expect(catalogSheetOption('Salario'), findsOneWidget);
        expect(catalogSheetOption('Alimentación'), findsNothing);

        await tester.tap(catalogSheetOption('Salario'));
        await tester.pumpAndSettle();
        expect(sheet, findsNothing);
        expect(
          find.descendant(
            of: catalogCard('Categoría'),
            matching: find.text('Salario'),
          ),
          findsOneWidget,
        );
      },
    );

    // contacto elegido / quitado → qué viaja en el borrador
    for (final (name, remove, expected) in [
      ('contacto elegido: manda su id', false, 4),
      ('contacto quitado con «Quitar»: no manda id_contacto', true, null),
    ]) {
      testWidgets(name, (tester) async {
        final s = _Scenario();
        await s.open(tester);
        await _fill(tester);
        expect(find.byTooltip('Quitar'), findsNothing);

        await pickCatalogOption(tester, 'Contacto (opcional)', 'Oscar');
        expect(find.byTooltip('Quitar'), findsOneWidget);
        expect(
          find.descendant(
            of: catalogCard('Contacto (opcional)'),
            matching: find.text('Oscar'),
          ),
          findsOneWidget,
        );
        if (remove) {
          await tester.tap(find.byTooltip('Quitar'));
          await tester.pumpAndSettle();
          expect(find.byTooltip('Quitar'), findsNothing);
          expect(find.text('Ninguno'), findsOneWidget);
        }

        await tester.tap(_submit);
        await _showToast(tester);
        expect(s.recurring.created.single.contactId, expected);
        await _dismissToasts(tester);
      });
    }

    testWidgets('«Se repite» abre una hoja sin buscador; «Cada 3 meses» manda '
        'cada_meses 3', (tester) async {
      final s = _Scenario();
      await s.open(tester);
      await _fill(tester);
      expect(
        find.descendant(
          of: catalogCard('Se repite'),
          matching: find.text('Cada mes'),
        ),
        findsOneWidget,
        reason: 'por defecto cada mes',
      );

      await openCatalogSheet(tester, 'Se repite');
      expect(sheet, findsOneWidget);
      expect(searchIn(), findsNothing, reason: 'son pocas opciones');
      for (final label in [
        'Cada mes',
        'Cada 2 meses',
        'Cada 3 meses',
        'Cada 4 meses',
        'Cada 6 meses',
        'Cada 12 meses',
      ]) {
        expect(catalogSheetOption(label), findsOneWidget, reason: label);
      }

      await tester.tap(catalogSheetOption('Cada 3 meses'));
      await tester.pumpAndSettle();
      expect(sheet, findsNothing);
      expect(
        find.descendant(
          of: catalogCard('Se repite'),
          matching: find.text('Cada 3 meses'),
        ),
        findsOneWidget,
      );

      await tester.tap(_submit);
      await _showToast(tester);
      final draft = s.recurring.created.single;
      expect(draft.everyMonths, 3);
      expect(draft.toJson()['cada_meses'], 3);
      expect(draft.note, isNull, reason: 'el formulario ya no pide nota');
      await _dismissToasts(tester);
    });
  });

  group('distribución de las parejas (según el ancho útil del formulario)', () {
    // Ancho útil = min(pantalla, formMaxWidth 560) − 2 × 16 de relleno.
    Future<({bool amountDay, bool schedule, bool catalog})> rows(
      WidgetTester tester, {
      required double width,
      double scale = 1,
    }) async {
      await _Scenario().open(tester, width: width, textScale: scale);
      double top(Finder f) => tester.getTopLeft(f).dy;
      return (
        amountDay: top(_text('Valor')) == top(_text('Día de pago')),
        schedule: top(catalogCard('Se repite')) == top(catalogCard('Desde')),
        catalog:
            top(catalogCard('Categoría')) ==
            top(catalogCard('Contacto (opcional)')),
      );
    }

    testWidgets(
      '320 (útil 288): Valor+Día en fila (min 240); tarjetas apiladas',
      (tester) async {
        final r = await rows(tester, width: 320);
        expect(r.amountDay, isTrue);
        expect(r.schedule, isFalse, reason: '288 < 320 (formDatePairMinWidth)');
        expect(r.catalog, isFalse, reason: '288 < 340 (formPickPairMinWidth)');
        expectStacked(
          tester,
          catalogCard('Categoría'),
          catalogCard('Contacto (opcional)'),
        );
      },
    );

    testWidgets(
      '390 (útil 358): las tres parejas en fila (Categoría+Contacto 358 ≥ 340)',
      (tester) async {
        final r = await rows(tester, width: 390);
        expect(r.amountDay && r.schedule && r.catalog, isTrue);
        expectSameRow(
          tester,
          catalogCard('Categoría'),
          catalogCard('Contacto (opcional)'),
        );
        expect(
          tester.getSize(catalogCard('Categoría')).height,
          tester.getSize(catalogCard('Contacto (opcional)')).height,
          reason: 'pareja de tarjetas: misma altura',
        );
      },
    );

    testWidgets('800 y 1300 (útil 528): las tres parejas en fila', (
      tester,
    ) async {
      for (final width in [800.0, 1300.0]) {
        final r = await rows(tester, width: width);
        expect(
          r.amountDay && r.schedule && r.catalog,
          isTrue,
          reason: '$width',
        );
      }
    });

    testWidgets('texto 1.5 multiplica los mínimos: en 320 y 390 todo apilado; '
        'en 800 siguen en fila Valor+Día (360), la fecha (480) y '
        'categoría+contacto (510)', (tester) async {
      for (final width in [320.0, 390.0]) {
        final r = await rows(tester, width: width, scale: 1.5);
        expect(r.amountDay, isFalse, reason: '$width: 288/358 < 360');
        expect(r.schedule, isFalse, reason: '$width: < 480');
        expect(r.catalog, isFalse, reason: '$width: < 510');
      }
      final wide = await rows(tester, width: 800, scale: 1.5);
      expect(wide.amountDay, isTrue, reason: '528 ≥ 360');
      expect(wide.schedule, isTrue, reason: '528 ≥ 480');
      expect(wide.catalog, isTrue, reason: '528 ≥ 510');
    });
  });
}
