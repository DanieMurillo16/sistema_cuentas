import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_cuentas/core/errors/app_exception.dart';
import 'package:sistema_cuentas/core/models/movement_type.dart';
import 'package:sistema_cuentas/core/utils/date_formatter.dart';
import 'package:sistema_cuentas/features/home/home_screen.dart';
import 'package:sistema_cuentas/features/movements/widgets/movement_form.dart';
import 'package:sistema_cuentas/shared/widgets/catalog_pick_card.dart';
import 'package:sistema_cuentas/shared/widgets/catalog_picker_row.dart';
import 'package:sistema_cuentas/shared/widgets/catalog_picker_sheet.dart';
import 'package:sistema_cuentas/features/movements/widgets/new_movement_sheet.dart';
import 'package:sistema_cuentas/features/movements/models/movement.dart';
import 'package:sistema_cuentas/features/movements/providers/movements_provider.dart';

import '../../../helpers/movement_fixtures.dart';
import '../../../support/fake_catalogs_repository.dart';
import '../../../support/fake_movements_repository.dart';
import '../../../support/fake_summary_repository.dart';
import '../../../support/inicio_overrides.dart';
import '../../../support/open_movement_sheet.dart';

Finder get _amountField => find.byType(TextFormField).at(0);
Finder get _descriptionField => find.byType(TextFormField).at(1);

/// La tarjeta de «Categoría» o «Medio de pago» (ya no son un desplegable).
Finder _card(String label) => find.widgetWithText(CatalogPickCard, label);

/// Lo que se toca de la tarjeta: su `InkWell`.
Finder _cardTap(String label) =>
    find.descendant(of: _card(label), matching: find.byType(InkWell));

/// La hoja del selector (es genérica: `byType` no la encuentra por su tipo).
final _sheet = find.byWidgetPredicate((w) => w is CatalogPickerSheet);

/// ¿Algún campo de texto tiene el foco (es decir, el teclado estaría abierto)?
bool _anyFieldFocused(WidgetTester tester) => tester
    .widgetList<EditableText>(find.byType(EditableText))
    .any((e) => e.focusNode.hasFocus);

/// ¿[a] va antes que [b] leyendo de izquierda a derecha y de arriba abajo?
bool _before(WidgetTester tester, Finder a, Finder b) {
  final p = tester.getTopLeft(a);
  final q = tester.getTopLeft(b);
  return p.dy < q.dy || (p.dy == q.dy && p.dx < q.dx);
}

/// Las opciones de la hoja del selector, por su texto.
Finder _sheetOption(String option) => find.descendant(
  of: find.byType(CatalogPickerRow),
  matching: find.text(option),
);
Finder get _saveButton => find.byType(FilledButton);

bool _saveEnabled(WidgetTester tester) =>
    tester.widget<FilledButton>(_saveButton).onPressed != null;

/// Abre el formulario como en la app: «+» → hoja → opción.
Future<ProviderContainer> _openForm(
  WidgetTester tester,
  MovementType type, {
  required FakeMovementsRepository movements,
  FakeCatalogsRepository? catalogs,
  FakeSummaryRepository? summary,
  bool settle = true,
}) async {
  return openMovementSheet(
    tester,
    type: type,
    settle: settle,
    overrides: dataOverrides(
      movements: movements,
      catalogs: catalogs,
      summary: summary,
    ),
  );
}

/// Elegir = tocar la tarjeta y luego la fila de la hoja por su texto.
Future<void> _pick(WidgetTester tester, String label, String option) async {
  await tester.tap(_cardTap(label));
  await tester.pumpAndSettle();
  await tester.tap(_sheetOption(option));
  await tester.pumpAndSettle();
}

Future<void> _fillRequired(
  WidgetTester tester, {
  String amount = '55000',
}) async {
  await tester.enterText(_amountField, amount);
  await _pick(tester, 'Categoría', 'Alimentación');
  await _pick(tester, 'Medio de pago', 'Nequi');
}

/// Deja pasar y retira los avisos (`AppToast`) para no dejar temporizadores.
Future<void> _showToast(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 100)); // llega el estado
  await tester.pump(const Duration(milliseconds: 500)); // entra el aviso
}

Future<void> _dismissToasts(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 5));
  await tester.pumpAndSettle();
}

FakeMovementsRepository _repo({Future<Movement> Function()? register}) =>
    FakeMovementsRepository(
      onRegister: (draft) => register != null
          ? register()
          : Future.value(
              buildMovement(
                id: 100,
                description: draft.description,
                valueCents: draft.amountPesos * 100,
                date: DateTime.now(),
              ),
            ),
    );

void main() {
  group('estado inicial', () {
    testWidgets(
      'gasto: título, campos, botón «Registrar gasto» y fecha de hoy',
      (tester) async {
        await _openForm(tester, MovementType.expense, movements: _repo());

        expect(find.text('Nuevo gasto'), findsOneWidget);
        expect(find.text('Registrar gasto'), findsOneWidget);
        expect(find.text('Guardar y agregar otro'), findsOneWidget);
        expect(find.text('Descripción (opcional)'), findsOneWidget);
        expect(find.text('Nota (opcional)'), findsNothing);
        expect(_card('Categoría'), findsOneWidget);
        expect(_card('Medio de pago'), findsOneWidget);
        expect(find.text('Elegir'), findsNWidgets(2));
        expect(find.text(formatLongDate(DateTime.now())), findsOneWidget);
        expect(_saveEnabled(tester), isTrue);
      },
    );

    testWidgets(
      'ingreso: textos propios del tipo y solo categorías de ingreso',
      (tester) async {
        await _openForm(tester, MovementType.income, movements: _repo());

        expect(find.text('Nuevo ingreso'), findsOneWidget);
        expect(find.text('Registrar ingreso'), findsOneWidget);
        expect(find.text('¿De dónde proviene?'), findsOneWidget);

        await tester.tap(_cardTap('Categoría'));
        await tester.pumpAndSettle();
        expect(_sheetOption('Salario'), findsOneWidget);
        expect(_sheetOption('Alimentación'), findsNothing);
      },
    );

    testWidgets(
      'el monto se escribe con puntos de miles y no pasa de 10 dígitos',
      (tester) async {
        await _openForm(tester, MovementType.expense, movements: _repo());

        await tester.enterText(_amountField, '55000');
        expect(find.text('55.000'), findsOneWidget);

        await tester.enterText(_amountField, '123456789012345');
        final text = tester
            .widget<TextFormField>(_amountField)
            .controller!
            .text;
        expect(text.replaceAll('.', '').length, lessThanOrEqualTo(10));
        expect(text.length, lessThanOrEqualTo(13));
      },
    );
  });

  group('tarjetas de categoría y medio de pago', () {
    testWidgets(
      'tocar la tarjeta abre la hoja con las opciones del tipo; elegir la '
      'rellena y cierra la hoja',
      (tester) async {
        await _openForm(tester, MovementType.expense, movements: _repo());

        await tester.tap(_cardTap('Categoría'));
        await tester.pumpAndSettle();
        expect(_sheet, findsOneWidget);
        expect(_sheetOption('Alimentación'), findsOneWidget);
        expect(_sheetOption('Transporte'), findsOneWidget);
        expect(_sheetOption('Salario'), findsNothing, reason: 'es de ingresos');

        await tester.tap(_sheetOption('Transporte'));
        await tester.pumpAndSettle();
        expect(_sheet, findsNothing);
        expect(
          find.descendant(
            of: _card('Categoría'),
            matching: find.text('Transporte'),
          ),
          findsOneWidget,
        );
        expect(find.text('Elegir'), findsOneWidget, reason: 'falta el medio');
      },
    );

    testWidgets('las frecuentes del mes salen primero, más usada primero', (
      tester,
    ) async {
      final now = DateTime.now();
      final movements = FakeMovementsRepository(
        onList: (_, _) async => [
          buildMovement(
            id: 1,
            categoryId: 4,
            category: 'Transporte',
            date: now,
          ),
          buildMovement(
            id: 2,
            categoryId: 4,
            category: 'Transporte',
            date: now,
          ),
          buildMovement(id: 3, categoryId: 3, date: now, methodId: 5),
        ],
      );
      await _openForm(tester, MovementType.expense, movements: movements);

      await tester.tap(_cardTap('Categoría'));
      await tester.pumpAndSettle();
      expect(find.text('FRECUENTES'), findsOneWidget);
      final first = find.byKey(const ValueKey('frequent-Transporte'));
      final second = find.byKey(const ValueKey('frequent-Alimentación'));
      expect(first, findsOneWidget);
      expect(_before(tester, first, second), isTrue);
      await tester.tap(first);
      await tester.pumpAndSettle();

      // El medio: Nequi (2 usos) antes que Bancolombia (1).
      await tester.tap(_cardTap('Medio de pago'));
      await tester.pumpAndSettle();
      expect(
        _before(
          tester,
          find.byKey(const ValueKey('frequent-Nequi')),
          find.byKey(const ValueKey('frequent-Bancolombia')),
        ),
        isTrue,
      );
    });
  });

  group('foco: el teclado no sube solo', () {
    // Una tabla de casos: el foco no se pide al abrir ni tras «agregar otro».
    EditableText editable(WidgetTester tester, Finder field) =>
        tester.widget<EditableText>(
          find.descendant(of: field, matching: find.byType(EditableText)),
        );

    for (final type in MovementType.values) {
      testWidgets(
        '${type.apiValue}: al abrir y asentar ningún campo tiene foco y no hay campo Nota',
        (tester) async {
          await _openForm(tester, type, movements: _repo());
          await tester.pump(const Duration(milliseconds: 300));
          await tester.pumpAndSettle();

          expect(_anyFieldFocused(tester), isFalse);
          expect(editable(tester, _amountField).focusNode.hasFocus, isFalse);
          expect(
            editable(tester, _descriptionField).focusNode.hasFocus,
            isFalse,
          );
          expect(find.byType(TextFormField), findsNWidgets(2));
          expect(find.text('Nota (opcional)'), findsNothing);
        },
      );
    }
  });

  group('validación', () {
    testWidgets(
      'vacío: errores bajo cada campo, aviso y no llama al servidor',
      (tester) async {
        final movements = _repo();
        await _openForm(tester, MovementType.expense, movements: movements);

        await tester.tap(_saveButton);
        await _showToast(tester);

        expect(find.text('Escribe el valor.'), findsOneWidget);
        // Cada error sale bajo su tarjeta; el aviso repite solo el primero.
        expect(
          find.descendant(
            of: _card('Categoría'),
            matching: find.text('Elige la categoría.'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: _card('Medio de pago'),
            matching: find.text('Elige el medio de pago.'),
          ),
          findsOneWidget,
        );
        expect(find.text('Elige la categoría.'), findsNWidgets(2));
        expect(find.text('Elige el medio de pago.'), findsOneWidget);
        expect(movements.registerCalls, 0);
        expect(_saveEnabled(tester), isTrue);
        await _dismissToasts(tester);
      },
    );

    testWidgets('monto en cero no es válido', (tester) async {
      final movements = _repo();
      await _openForm(tester, MovementType.expense, movements: movements);
      await tester.enterText(_amountField, '0');
      await _pick(tester, 'Categoría', 'Alimentación');
      await _pick(tester, 'Medio de pago', 'Nequi');

      await tester.tap(_saveButton);
      await _showToast(tester);

      expect(find.text('Escribe el valor.'), findsOneWidget);
      expect(movements.registerCalls, 0);
      await _dismissToasts(tester);
    });

    testWidgets('sin categoría: aviso «Elige la categoría.»', (tester) async {
      final movements = _repo();
      await _openForm(tester, MovementType.expense, movements: movements);
      await tester.enterText(_amountField, '1000');
      await _pick(tester, 'Medio de pago', 'Nequi');

      await tester.tap(_saveButton);
      await _showToast(tester);

      expect(find.text('Elige la categoría.'), findsWidgets);
      expect(find.text('Elige el medio de pago.'), findsNothing);
      expect(movements.registerCalls, 0);
      await _dismissToasts(tester);
    });

    testWidgets('sin medio de pago: aviso «Elige el medio de pago.»', (
      tester,
    ) async {
      final movements = _repo();
      await _openForm(tester, MovementType.expense, movements: movements);
      await tester.enterText(_amountField, '1000');
      await _pick(tester, 'Categoría', 'Alimentación');

      await tester.tap(_saveButton);
      await _showToast(tester);

      expect(find.text('Elige el medio de pago.'), findsWidgets);
      expect(movements.registerCalls, 0);
      await _dismissToasts(tester);
    });
  });

  group('guardar', () {
    testWidgets(
      'éxito: envía el borrador, avisa, vuelve a Inicio y la lista lo muestra',
      (tester) async {
        final movements = _repo();
        final summary = FakeSummaryRepository((_) async => buildTotals());
        await _openForm(
          tester,
          MovementType.expense,
          movements: movements,
          summary: summary,
        );
        await _fillRequired(tester);

        await tester.tap(_saveButton);
        await _showToast(tester);
        await tester.pump(const Duration(milliseconds: 500));

        final draft = movements.drafts.single;
        expect(draft.type, MovementType.expense);
        expect(draft.amountPesos, 55000);
        expect(draft.categoryId, 3);
        expect(draft.methodId, 2);
        expect(
          draft.description,
          'Alimentación',
          reason: 'sin descripción: la categoría',
        );
        expect(draft.note, isNull, reason: 'el formulario ya no pide nota');
        expect(draft.date, dateOnly(DateTime.now()));

        expect(find.text('Gasto registrado'), findsOneWidget);
        await _dismissToasts(tester);
        expect(find.byType(NewMovementSheet), findsNothing);
        expect(find.byType(HomeScreen), findsOneWidget);
        // La otra vista ve el dato nuevo sin recargar la lista…
        expect(find.text('Alimentación'), findsOneWidget);
        expect(movements.listCalls, 1);
        // …y el resumen (que calcula el servidor) se pidió otra vez.
        expect(summary.calls, 2);
      },
    );

    testWidgets('el ingreso se envía como INGRESO con la descripción escrita', (
      tester,
    ) async {
      final movements = _repo();
      await _openForm(tester, MovementType.income, movements: movements);
      await tester.enterText(_amountField, '1.500.000');
      await tester.enterText(_descriptionField, '  Salario de octubre ');
      await _pick(tester, 'Categoría', 'Salario');
      await _pick(tester, 'Medio de pago', 'Bancolombia');

      await tester.tap(_saveButton);
      await _showToast(tester);

      final draft = movements.drafts.single;
      expect(draft.type, MovementType.income);
      expect(draft.amountPesos, 1500000);
      expect(draft.description, 'Salario de octubre');
      expect(draft.methodId, 5);
      expect(draft.note, isNull);
      expect(find.text('Ingreso registrado'), findsOneWidget);
      await _dismissToasts(tester);
    });

    testWidgets(
      'mientras guarda: botón apagado con progreso, campos de solo lectura y sin doble envío',
      (tester) async {
        final completer = Completer<Movement>();
        final movements = _repo(register: () => completer.future);
        await _openForm(tester, MovementType.expense, movements: movements);
        await _fillRequired(tester);

        await tester.tap(_saveButton);
        await tester.pump();

        expect(_saveEnabled(tester), isFalse);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.text('Registrar gasto'), findsNothing);
        expect(
          tester.widget<TextFormField>(_amountField).enabled,
          isNot(false),
        );
        expect(
          tester
              .widget<EditableText>(
                find.descendant(
                  of: _amountField,
                  matching: find.byType(EditableText),
                ),
              )
              .readOnly,
          isTrue,
        );
        final switchTile = tester.widget<SwitchListTile>(
          find.byType(SwitchListTile),
        );
        expect(switchTile.onChanged, isNull);

        await tester.tap(_saveButton, warnIfMissed: false);
        await tester.pump();
        expect(movements.registerCalls, 1);

        completer.complete(buildMovement(id: 1, date: DateTime.now()));
        await tester.pumpAndSettle();
        await _dismissToasts(tester);
        expect(movements.registerCalls, 1);
      },
    );
  });

  group('«Guardar y agregar otro»', () {
    testWidgets(
      'se activa tocando el texto; limpia monto y descripción, no pide el foco y conserva fecha, categoría y medio',
      (tester) async {
        final movements = _repo();
        await _openForm(tester, MovementType.expense, movements: movements);
        final today = DateTime.now();

        // Cambia la fecha (día 1 del mes) para comprobar que se conserva.
        await tester.tap(find.text(formatLongDate(today)));
        await tester.pumpAndSettle();
        await tester.tap(find.text('1').first);
        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();
        final chosen = DateTime(today.year, today.month, 1);
        expect(find.text(formatLongDate(chosen)), findsOneWidget);

        await _fillRequired(tester);
        await tester.enterText(_descriptionField, 'Pan');
        await tester.tap(find.text('Guardar y agregar otro'));
        await tester.pumpAndSettle();
        expect(
          tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
          isTrue,
        );

        await tester.tap(_saveButton);
        await _showToast(tester);

        expect(movements.registerCalls, 1);
        expect(movements.drafts.single.date, chosen);
        expect(find.text('Gasto registrado'), findsOneWidget);
        expect(
          find.byType(NewMovementSheet),
          findsOneWidget,
          reason: 'la hoja no se cierra',
        );
        expect(
          tester.widget<TextFormField>(_amountField).controller!.text,
          isEmpty,
        );
        expect(
          tester.widget<TextFormField>(_descriptionField).controller!.text,
          isEmpty,
        );
        expect(
          _anyFieldFocused(tester),
          isFalse,
          reason: '«agregar otro» tampoco sube el teclado',
        );
        expect(find.text(formatLongDate(chosen)), findsOneWidget);
        // En la hoja (debajo, en la lista de Inicio, la fila nueva también
        // dice «Alimentación ·» y «Nequi»).
        final sheet = find.byType(NewMovementSheet);
        expect(
          find.descendant(of: sheet, matching: find.text('Alimentación')),
          findsOneWidget,
        );
        expect(
          find.descendant(of: sheet, matching: find.text('Nequi')),
          findsOneWidget,
        );
        expect(_saveEnabled(tester), isTrue);
        await _dismissToasts(tester);

        // Se puede registrar otro enseguida con los mismos datos fijos.
        await tester.enterText(_amountField, '2000');
        await tester.tap(_saveButton);
        await _showToast(tester);
        expect(movements.registerCalls, 2);
        expect(movements.drafts.last.categoryId, 3);
        expect(movements.drafts.last.methodId, 2);
        expect(movements.drafts.last.date, chosen);
        await _dismissToasts(tester);
      },
    );
  });

  group('catálogos', () {
    testWidgets(
      'con error: mensaje, reintento que carga y guardar no revienta',
      (tester) async {
        var fail = true;
        final catalogs = FakeCatalogsRepository(
          onCategories: () async {
            if (fail) throw const NetworkException('Catálogos sin conexión.');
            return defaultCategories();
          },
          onMethods: () async => defaultMethods(),
        );
        final movements = _repo();
        await _openForm(
          tester,
          MovementType.expense,
          movements: movements,
          catalogs: catalogs,
        );

        expect(find.text('Catálogos sin conexión.'), findsOneWidget);
        expect(_card('Categoría'), findsNothing);

        await tester.enterText(_amountField, '1000');
        await tester.tap(_saveButton);
        await _showToast(tester);
        expect(tester.takeException(), isNull);
        expect(movements.registerCalls, 0);
        expect(find.text('Elige la categoría.'), findsOneWidget);
        await _dismissToasts(tester);

        fail = false;
        await tester.tap(find.text('Intentar nuevamente'));
        await tester.pumpAndSettle();
        expect(find.text('Catálogos sin conexión.'), findsNothing);
        expect(_card('Categoría'), findsOneWidget);
        expect(_card('Medio de pago'), findsOneWidget);
      },
    );

    testWidgets('sin categorías del tipo: lo dice con «ingresos» o «gastos»', (
      tester,
    ) async {
      final onlyIncome = FakeCatalogsRepository(
        onCategories: () async => [defaultCategories().last],
        onMethods: () async => defaultMethods(),
      );
      await _openForm(
        tester,
        MovementType.expense,
        movements: _repo(),
        catalogs: onlyIncome,
      );
      expect(
        find.text('Aún no tienes categorías de gastos activas.'),
        findsOneWidget,
      );
      expect(_card('Categoría'), findsNothing);
    });

    testWidgets('sin medios de pago: lo dice', (tester) async {
      final noMethods = FakeCatalogsRepository(
        onCategories: () async => defaultCategories(),
        onMethods: () async => const [],
      );
      await _openForm(
        tester,
        MovementType.expense,
        movements: _repo(),
        catalogs: noMethods,
      );
      expect(
        find.text('Aún no tienes medios de pago activos.'),
        findsOneWidget,
      );
    });

    testWidgets('cargando: barra de progreso en lugar de los campos', (
      tester,
    ) async {
      final completer = Completer<List<dynamic>>();
      final catalogs = FakeCatalogsRepository(
        onCategories: () async => (await completer.future).cast(),
        onMethods: () async => defaultMethods(),
      );
      await _openForm(
        tester,
        MovementType.expense,
        movements: _repo(),
        catalogs: catalogs,
        settle: false,
      );
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(_card('Categoría'), findsNothing);

      completer.complete(defaultCategories());
      await tester.pumpAndSettle();
      expect(find.byType(LinearProgressIndicator), findsNothing);
      expect(_card('Categoría'), findsOneWidget);
    });
  });

  // Estos dos exponen el defecto de movement_form.dart (un error de guardado
  // también dispara el éxito). Van al final: el aviso que dejan colgado
  // (SmartDialog es global) no debe contagiar a las demás pruebas.
  group('errores al guardar', () {
    testWidgets(
      'error: aviso con el mensaje del servidor, se queda en el formulario con lo escrito y puede reintentar',
      (tester) async {
        var attempt = 0;
        final movements = _repo(
          register: () async {
            attempt++;
            if (attempt == 1) {
              throw const ApiException(
                'Este gasto ya fue pagado.',
                code: 'DUPLICADO',
                statusCode: 409,
              );
            }
            return buildMovement(id: 5, date: DateTime.now());
          },
        );
        await _openForm(tester, MovementType.expense, movements: movements);
        await _fillRequired(tester);

        await tester.tap(_saveButton);
        await _showToast(tester);

        expect(find.text('Este gasto ya fue pagado.'), findsOneWidget);
        expect(find.byType(MovementForm), findsOneWidget);
        expect(find.text('55.000'), findsOneWidget);
        expect(find.text('Alimentación'), findsOneWidget);
        expect(_saveEnabled(tester), isTrue);
        await _dismissToasts(tester);

        await tester.tap(_saveButton);
        await _showToast(tester);
        expect(movements.registerCalls, 2);
        expect(find.text('Gasto registrado'), findsOneWidget);
        await _dismissToasts(tester);
        expect(find.byType(NewMovementSheet), findsNothing);
      },
    );

    testWidgets('sin conexión: aviso en español', (tester) async {
      final movements = _repo(
        register: () async => throw const NetworkException(
          'No fue posible conectar con el servidor. Revisa tu conexión.',
        ),
      );
      await _openForm(tester, MovementType.expense, movements: movements);
      await _fillRequired(tester);

      await tester.tap(_saveButton);
      await _showToast(tester);

      expect(
        find.text(
          'No fue posible conectar con el servidor. Revisa tu conexión.',
        ),
        findsOneWidget,
      );
      // Un fallo no es un éxito: ni aviso verde ni cerrar la pantalla.
      expect(find.text('Gasto registrado'), findsNothing);
      expect(find.byType(NewMovementSheet), findsOneWidget);
      await _dismissToasts(tester);
    });
  });

  testWidgets(
    'el formulario pide los movimientos del mes una sola vez (usa el provider compartido)',
    (tester) async {
      final movements = _repo();
      final container = await _openForm(
        tester,
        MovementType.expense,
        movements: movements,
      );
      expect(container.read(movementsProvider).hasValue, isTrue);
      expect(movements.listCalls, 1);
    },
  );
}
