import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_cuentas/core/errors/app_exception.dart';
import 'package:sistema_cuentas/core/models/movement_type.dart';
import 'package:sistema_cuentas/core/theme/design_tokens.dart';
import 'package:sistema_cuentas/features/movements/movements_list_screen.dart';
import 'package:sistema_cuentas/features/movements/models/movement.dart';
import 'package:sistema_cuentas/features/movements/widgets/movement_tile.dart';
import 'package:sistema_cuentas/features/movements/widgets/movements_total_header.dart';
import 'package:sistema_cuentas/shared/providers/balances_hidden_provider.dart';
import 'package:sistema_cuentas/shared/utils/movement_type_style.dart';
import 'package:sistema_cuentas/shared/widgets/animated_number_text.dart';
import 'package:sistema_cuentas/shared/widgets/app_form_pair.dart';

import '../../helpers/movement_fixtures.dart';
import '../../support/fake_catalogs_repository.dart';
import '../../support/fake_movements_repository.dart';
import '../../support/inicio_overrides.dart';
import '../../support/pick_catalog_card.dart';
import '../../support/pump_screen_app.dart';

const _mask = AnimatedNumberText.mask;

DateTime get _thisMonth {
  final now = DateTime.now();
  return DateTime(now.year, now.month);
}

DateTime get _lastDay => DateTime(_thisMonth.year, _thisMonth.month + 1, 0);

/// Dos gastos (Mercado/Alimentación/Nequi y Taxi/Transporte/Bancolombia) y dos
/// ingresos (Salario y Venta).
List<Movement> _items() => [
  buildMovement(
    id: 1,
    valueCents: 2500000,
    description: 'Mercado',
    date: dayOfCurrentMonth(1),
  ),
  buildMovement(
    id: 2,
    valueCents: 750000,
    description: 'Taxi',
    category: 'Transporte',
    categoryId: 4,
    method: 'Bancolombia',
    methodId: 5,
    date: dayOfCurrentMonth(1),
  ),
  buildMovement(
    id: 3,
    type: MovementType.income,
    valueCents: 40000000,
    description: 'Salario',
    category: 'Nómina',
    categoryId: 9,
    method: 'Bancolombia',
    methodId: 5,
    date: dayOfCurrentMonth(1),
  ),
  buildMovement(
    id: 4,
    type: MovementType.income,
    valueCents: 1000000,
    description: 'Venta',
    category: 'Nómina',
    categoryId: 9,
    date: dayOfCurrentMonth(1),
  ),
];

FakeMovementsRepository _repo([List<Movement>? items]) =>
    FakeMovementsRepository(onList: (_, _) async => items ?? _items());

Future<ProviderContainer> _pump(
  WidgetTester tester,
  MovementType type, {
  FakeMovementsRepository? movements,
  FakeCatalogsRepository? catalogs,
  bool settle = true,
  double width = 390,
  double textScale = 1,
}) => pumpScreenApp(
  tester,
  screen: MovementsListScreen(type: type),
  width: width,
  textScale: textScale,
  settle: settle,
  spanish: true,
  overrides: dataOverrides(movements: movements ?? _repo(), catalogs: catalogs),
);

Finder get _searchField => find.byType(TextField).first;

Future<void> _openPanel(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Filtros'));
  await tester.pumpAndSettle();
}

Future<void> _pickOption(
  WidgetTester tester, {
  required String field,
  required String option,
}) async {
  await pickCatalogOption(tester, field, option);
}

Color? _colorOf(WidgetTester tester, String text) =>
    tester.widget<Text>(find.text(text)).style?.color;

void main() {
  group('cuatro estados', () {
    testWidgets('datos: barra «Gastos», conteo, suma y solo los gastos', (
      tester,
    ) async {
      await _pump(tester, MovementType.expense);

      expect(find.widgetWithText(AppBar, 'Gastos'), findsOneWidget);
      expect(find.text('2 movimientos'), findsOneWidget);
      expect(find.text(r'$ 32.500'), findsOneWidget);
      expect(find.byType(MovementTile), findsNWidgets(2));
      expect(find.text('Mercado'), findsOneWidget);
      expect(find.text('Taxi'), findsOneWidget);
      expect(find.text('Salario'), findsNothing);
      expect(find.text('Venta'), findsNothing);
    });

    testWidgets('ingresos: barra «Ingresos», solo ingresos y su suma', (
      tester,
    ) async {
      await _pump(tester, MovementType.income);

      expect(find.widgetWithText(AppBar, 'Ingresos'), findsOneWidget);
      expect(find.text('2 movimientos'), findsOneWidget);
      expect(find.text(r'$ 410.000'), findsOneWidget);
      expect(find.text('Salario'), findsOneWidget);
      expect(find.text('Mercado'), findsNothing);
    });

    testWidgets(
      'el total lleva el color del tipo (verde ingresos, rojo gastos)',
      (tester) async {
        await _pump(tester, MovementType.income);
        expect(_colorOf(tester, r'$ 410.000'), MovementType.income.color);

        await _pump(tester, MovementType.expense);
        expect(_colorOf(tester, r'$ 32.500'), MovementType.expense.color);
      },
    );

    testWidgets('un solo movimiento: «1 movimiento» en singular', (
      tester,
    ) async {
      await _pump(
        tester,
        MovementType.income,
        movements: _repo([
          buildMovement(
            id: 3,
            type: MovementType.income,
            description: 'Salario',
            date: dayOfCurrentMonth(1),
          ),
        ]),
      );
      expect(find.text('1 movimiento'), findsOneWidget);
      expect(find.text('1 movimientos'), findsNothing);
    });

    testWidgets('cargando: cargador de página, sin total ni filas', (
      tester,
    ) async {
      final completer = Completer<List<Movement>>();
      await _pump(
        tester,
        MovementType.expense,
        settle: false,
        movements: FakeMovementsRepository(onList: (_, _) => completer.future),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(MovementsTotalHeader), findsNothing);
      expect(find.byType(MovementTile), findsNothing);
      expect(
        find.byType(TextField),
        findsOneWidget,
        reason: 'el buscador se ve',
      );

      completer.complete(_items());
      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byType(MovementTile), findsNWidgets(2));
    });

    testWidgets('error: mensaje en español y «Intentar nuevamente» recarga', (
      tester,
    ) async {
      var fail = true;
      final repository = FakeMovementsRepository(
        onList: (_, _) async {
          if (fail) {
            throw const NetworkException('Sin conexión con el servidor.');
          }
          return _items();
        },
      );
      await _pump(tester, MovementType.expense, movements: repository);

      expect(find.text('Sin conexión con el servidor.'), findsOneWidget);
      expect(find.byType(MovementTile), findsNothing);

      fail = false;
      await tester.tap(find.text('Intentar nuevamente'));
      await tester.pumpAndSettle();

      expect(repository.searchCalls, 2);
      expect(find.text('Sin conexión con el servidor.'), findsNothing);
      expect(find.byType(MovementTile), findsNWidgets(2));
    });

    testWidgets('vacío de gastos: «Sin resultados» y «No hay gastos…»', (
      tester,
    ) async {
      await _pump(tester, MovementType.expense, movements: _repo(const []));

      expect(find.text('Sin resultados'), findsOneWidget);
      expect(find.text('No hay gastos en estas fechas.'), findsOneWidget);
      expect(find.byType(MovementsTotalHeader), findsNothing);
    });

    testWidgets('vacío de ingresos: «No hay ingresos en estas fechas.»', (
      tester,
    ) async {
      await _pump(tester, MovementType.income, movements: _repo(const []));
      expect(find.text('No hay ingresos en estas fechas.'), findsOneWidget);
    });

    testWidgets(
      'el balance de otro tipo no se mezcla: sin ingresos en gastos',
      (tester) async {
        await _pump(
          tester,
          MovementType.expense,
          movements: _repo([
            buildMovement(
              id: 3,
              type: MovementType.income,
              date: dayOfCurrentMonth(1),
            ),
          ]),
        );
        expect(find.text('No hay gastos en estas fechas.'), findsOneWidget);
      },
    );

    testWidgets('«Atrás» vuelve a la pantalla anterior', (tester) async {
      await _pump(tester, MovementType.expense);
      await tester.tap(find.byTooltip('Atrás'));
      await tester.pumpAndSettle();
      expect(find.text(previousScreenText), findsOneWidget);
      expect(find.byType(MovementsListScreen), findsNothing);
    });
  });

  group('buscador local', () {
    testWidgets(
      'escribir filtra la lista y la suma sin pedir nada al servidor',
      (tester) async {
        final repository = _repo();
        await _pump(tester, MovementType.expense, movements: repository);

        await tester.enterText(_searchField, 'TRANSPORTE');
        await tester.pumpAndSettle();

        expect(find.byType(MovementTile), findsOneWidget);
        expect(find.text('Taxi'), findsOneWidget);
        expect(find.text('Mercado'), findsNothing);
        expect(find.text('1 movimiento'), findsOneWidget);
        expect(find.text(r'$ 7.500'), findsOneWidget);
        expect(repository.searchCalls, 1);
      },
    );

    testWidgets('sin coincidencias: mensaje de «búsqueda y filtros»', (
      tester,
    ) async {
      await _pump(tester, MovementType.expense);

      await tester.enterText(_searchField, 'zzz');
      await tester.pumpAndSettle();

      expect(find.text('Sin resultados'), findsOneWidget);
      expect(
        find.text('Ningún movimiento coincide con tu búsqueda y tus filtros.'),
        findsOneWidget,
      );
      expect(find.byType(MovementTile), findsNothing);
      expect(_searchField, findsOneWidget, reason: 'el buscador no desaparece');
    });

    testWidgets('al borrar el texto vuelve toda la lista', (tester) async {
      await _pump(tester, MovementType.expense);
      await tester.enterText(_searchField, 'zzz');
      await tester.pumpAndSettle();

      await tester.enterText(_searchField, '');
      await tester.pumpAndSettle();

      expect(find.byType(MovementTile), findsNWidgets(2));
    });
  });

  group('panel de filtros', () {
    testWidgets(
      'cerrado por defecto; «Filtros» lo abre y «Ocultar» lo cierra',
      (tester) async {
        await _pump(tester, MovementType.expense);
        expect(find.text('Fechas'), findsNothing);
        expect(find.text('Categoría'), findsNothing);

        await _openPanel(tester);

        expect(find.text('Fechas'), findsOneWidget);
        expect(find.text('Categoría'), findsOneWidget);
        expect(find.text('Medio de pago'), findsOneWidget);
        expect(find.text('Limpiar filtros'), findsOneWidget);
        expect(find.text('Todas'), findsOneWidget);
        expect(find.text('Todos'), findsOneWidget);

        await tester.tap(find.byTooltip('Ocultar filtros'));
        await tester.pumpAndSettle();
        expect(find.text('Categoría'), findsNothing);
      },
    );

    testWidgets('«Fechas» muestra el mes elegido completo', (tester) async {
      await _pump(tester, MovementType.expense);
      await _openPanel(tester);

      final first = _thisMonth;
      String two(int n) => n.toString().padLeft(2, '0');
      String show(DateTime d) => '${two(d.day)}/${two(d.month)}/${d.year}';
      expect(find.text('${show(first)} – ${show(_lastDay)}'), findsOneWidget);
    });

    testWidgets(
      '«Limpiar filtros» está apagado mientras no haya nada que limpiar',
      (tester) async {
        await _pump(tester, MovementType.expense);
        await _openPanel(tester);

        final button = tester.widget<TextButton>(
          find.widgetWithText(TextButton, 'Limpiar filtros'),
        );
        expect(button.onPressed, isNull, reason: 'apagado, no escondido');
      },
    );

    testWidgets('elegir una categoría vuelve a pedir con id_categoria', (
      tester,
    ) async {
      final repository = _repo();
      await _pump(tester, MovementType.expense, movements: repository);
      await _openPanel(tester);

      await _pickOption(tester, field: 'Categoría', option: 'Transporte');

      expect(repository.searchCalls, 2);
      expect(repository.searches.last.categoryId, 4);
      expect(repository.searches.last.methodId, isNull);
      expect(repository.searches.last.type, MovementType.expense);
      expect(find.byType(MovementTile), findsOneWidget);
      expect(find.text('Taxi'), findsOneWidget);
      expect(find.text('1 movimiento'), findsOneWidget);
      expect(find.byIcon(Icons.filter_alt_rounded), findsOneWidget);
    });

    testWidgets('elegir un medio de pago vuelve a pedir con id_medio', (
      tester,
    ) async {
      final repository = _repo();
      await _pump(tester, MovementType.expense, movements: repository);
      await _openPanel(tester);

      await _pickOption(tester, field: 'Medio de pago', option: 'Nequi');

      expect(repository.searches.last.methodId, 2);
      expect(repository.searches.last.categoryId, isNull);
      expect(find.text('Mercado'), findsOneWidget);
      expect(find.text('Taxi'), findsNothing);
    });

    testWidgets('categoría y medio juntos se mandan los dos', (tester) async {
      final repository = _repo();
      await _pump(tester, MovementType.expense, movements: repository);
      await _openPanel(tester);

      await _pickOption(tester, field: 'Categoría', option: 'Transporte');
      await _pickOption(tester, field: 'Medio de pago', option: 'Bancolombia');

      expect(repository.searches.last.categoryId, 4);
      expect(repository.searches.last.methodId, 5);
      expect(repository.searchCalls, 3);
    });

    for (final (field, option) in [
      ('Categoría', 'Transporte'),
      ('Medio de pago', 'Bancolombia'),
    ]) {
      testWidgets(
        'la «×» («Quitar») saca «$field» y vuelve a pedir sin ese filtro',
        (tester) async {
          final repository = _repo();
          await _pump(tester, MovementType.expense, movements: repository);
          await _openPanel(tester);
          expect(find.byTooltip('Quitar'), findsNothing);
          await _pickOption(tester, field: field, option: option);
          final picked = repository.searches.last;
          expect(
            field == 'Categoría' ? picked.categoryId : picked.methodId,
            isNotNull,
          );

          await tester.tap(find.byTooltip('Quitar'));
          await tester.pumpAndSettle();

          final search = repository.searches.last;
          expect(search.categoryId, isNull);
          expect(search.methodId, isNull);
          expect(find.byTooltip('Quitar'), findsNothing);
          expect(find.byType(MovementTile), findsNWidgets(2));
          expect(
            find.text(field == 'Categoría' ? 'Todas' : 'Todos'),
            findsOneWidget,
            reason: 'vuelve el placeholder',
          );
        },
      );
    }

    testWidgets(
      'las categorías son del tipo de la pantalla, con las inactivas',
      (tester) async {
        await _pump(
          tester,
          MovementType.expense,
          catalogs: FakeCatalogsRepository(
            onCategories: () async => [
              buildCategory(id: 3, name: 'Alimentación'),
              buildCategory(id: 7, name: 'Vieja', active: false),
              buildCategory(id: 9, type: MovementType.income, name: 'Salario'),
            ],
            onMethods: () async => defaultMethods(),
          ),
        );
        await _openPanel(tester);

        await tester.tap(catalogCardTap('Categoría'));
        await tester.pumpAndSettle();

        expect(catalogSheetOption('Alimentación'), findsOneWidget);
        expect(catalogSheetOption('Vieja'), findsOneWidget);
        expect(catalogSheetOption('Salario'), findsNothing);
        expect(
          find.widgetWithText(OutlinedButton, 'Nueva categoría'),
          findsNothing,
          reason: 'filtrar no crea categorías',
        );
      },
    );

    testWidgets('«Fechas»: elegir otro rango vuelve a pedir esas fechas', (
      tester,
    ) async {
      final repository = _repo();
      await _pump(tester, MovementType.expense, movements: repository);
      await _openPanel(tester);

      await tester.tap(find.byIcon(Icons.date_range_outlined));
      await tester.pumpAndSettle();
      expect(find.byType(DateRangePickerDialog), findsOneWidget);
      await tester.tap(find.text('10').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('20').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();

      expect(find.byType(DateRangePickerDialog), findsNothing);
      expect(repository.searchCalls, 2);
      final search = repository.searches.last;
      expect(search.from, DateTime(_thisMonth.year, _thisMonth.month, 10));
      expect(search.to, DateTime(_thisMonth.year, _thisMonth.month, 20));
      expect(find.text('Limpiar filtros'), findsOneWidget);
      final clear = tester.widget<TextButton>(
        find.widgetWithText(TextButton, 'Limpiar filtros'),
      );
      expect(clear.onPressed, isNotNull);
    });

    testWidgets('«Fechas»: cancelar el calendario no vuelve a pedir nada', (
      tester,
    ) async {
      final repository = _repo();
      await _pump(tester, MovementType.expense, movements: repository);
      await _openPanel(tester);

      await tester.tap(find.byIcon(Icons.date_range_outlined));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Cerrar'));
      await tester.pumpAndSettle();

      expect(repository.searchCalls, 1);
    });

    testWidgets('«Limpiar filtros» vacía el texto, categoría, medio y fechas', (
      tester,
    ) async {
      final repository = _repo();
      await _pump(tester, MovementType.expense, movements: repository);
      await _openPanel(tester);
      await tester.enterText(_searchField, 'taxi');
      await _pickOption(tester, field: 'Categoría', option: 'Transporte');
      await _pickOption(tester, field: 'Medio de pago', option: 'Bancolombia');
      expect(find.byType(MovementTile), findsOneWidget);

      await tester.tap(find.text('Limpiar filtros'));
      await tester.pumpAndSettle();

      expect(
        tester.widget<TextField>(_searchField).controller!.text,
        '',
        reason: 'el campo se vacía junto con el filtro',
      );
      final search = repository.searches.last;
      expect(search.categoryId, isNull);
      expect(search.methodId, isNull);
      expect(search.from, _thisMonth);
      expect(search.to, _lastDay);
      expect(find.byType(MovementTile), findsNWidgets(2));
      expect(find.byTooltip('Quitar'), findsNothing);
      expect(find.byIcon(Icons.filter_alt_rounded), findsNothing);
      final clear = tester.widget<TextButton>(
        find.widgetWithText(TextButton, 'Limpiar filtros'),
      );
      expect(clear.onPressed, isNull);
    });

    testWidgets('el texto solo ya habilita «Limpiar filtros»', (tester) async {
      await _pump(tester, MovementType.expense);
      await _openPanel(tester);

      await tester.enterText(_searchField, 'mer');
      await tester.pumpAndSettle();

      final clear = tester.widget<TextButton>(
        find.widgetWithText(TextButton, 'Limpiar filtros'),
      );
      expect(clear.onPressed, isNotNull);
    });

    testWidgets(
      'cambiar un filtro conserva la lista y no muestra el cargador de página',
      (tester) async {
        final second = Completer<List<Movement>>();
        var call = 0;
        final repository = FakeMovementsRepository(
          onList: (_, _) =>
              ++call == 1 ? Future.value(_items()) : second.future,
        );
        await _pump(tester, MovementType.expense, movements: repository);
        await _openPanel(tester);

        await tester.tap(catalogCardTap('Categoría'));
        await tester.pumpAndSettle();
        await tester.tap(catalogSheetOption('Transporte'));
        await tester.pump(const Duration(milliseconds: 100));

        // La nueva respuesta todavía no llegó: se sigue viendo la anterior.
        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(find.byType(MovementTile), findsNWidgets(2));
        expect(find.text('Mercado'), findsOneWidget);

        second.complete([_items()[1]]);
        await tester.pumpAndSettle();
        expect(find.byType(MovementTile), findsOneWidget);
      },
    );
  });

  group('cifras tapadas con el ojo', () {
    testWidgets('el total se tapa y el conteo no; destapar lo devuelve', (
      tester,
    ) async {
      final container = await _pump(tester, MovementType.expense);
      expect(find.text(r'$ 32.500'), findsOneWidget);

      container.read(balancesHiddenProvider.notifier).toggle();
      await tester.pumpAndSettle();

      expect(find.text(r'$ 32.500'), findsNothing);
      expect(find.text('2 movimientos'), findsOneWidget);
      // Total + neto del día + 2 filas.
      expect(find.text(_mask), findsNWidgets(4));
      expect(find.text('Mercado'), findsOneWidget);

      container.read(balancesHiddenProvider.notifier).toggle();
      await tester.pumpAndSettle();
      expect(find.text(r'$ 32.500'), findsOneWidget);
      expect(find.text(_mask), findsNothing);
    });
  });

  group(
    'distribución del panel (categoría y medio en pareja desde 340 útiles)',
    () {
      /// ¿Van en la misma fila? Con el ancho útil que midió el par.
      Future<(bool, double)> measure(
        WidgetTester tester, {
        required double width,
        double textScale = 1,
      }) async {
        await _pump(
          tester,
          MovementType.expense,
          width: width,
          textScale: textScale,
        );
        await _openPanel(tester);
        final category = catalogCard('Categoría');
        final method = catalogCard('Medio de pago');
        expect(tester.takeException(), isNull, reason: '$width px');
        final sameRow =
            tester.getTopLeft(category).dy == tester.getTopLeft(method).dy;
        if (sameRow) {
          expect(
            tester.getTopLeft(method).dx,
            greaterThan(tester.getTopLeft(category).dx),
          );
          expect(
            tester.getSize(category).height,
            tester.getSize(method).height,
            reason: '$width px: misma altura en pareja',
          );
        } else {
          expect(
            tester.getTopLeft(method).dx,
            tester.getTopLeft(category).dx,
            reason: '$width px: misma columna',
          );
        }
        return (sameRow, tester.getSize(find.byType(AppFormPair)).width);
      }

      testWidgets(
        'fila si y solo si el ancho útil ≥ 340 × escala (320/390/800/1300 × 1.0/1.5)',
        (tester) async {
          final results = <String, bool>{};
          for (final width in [320.0, 390.0, 800.0, 1300.0]) {
            for (final scale in [1.0, 1.5]) {
              final (sameRow, usable) = await measure(
                tester,
                width: width,
                textScale: scale,
              );
              expect(
                sameRow,
                usable >= DesignTokens.formPickPairMinWidth * scale,
                reason: '$width px · texto $scale · ancho útil $usable',
              );
              results['$width×$scale'] = sameRow;
            }
          }
          // Anclas de lo diseñado: estrecho apila, ancho con texto normal va en fila.
          expect(results['320.0×1.0'], isFalse);
          expect(results['800.0×1.0'], isTrue);
          expect(results['1300.0×1.0'], isTrue);
          expect(results['320.0×1.5'], isFalse);
        },
      );
    },
  );
}
