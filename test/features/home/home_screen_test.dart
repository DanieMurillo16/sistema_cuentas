import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_cuentas/core/errors/app_exception.dart';
import 'package:sistema_cuentas/core/models/movement_type.dart';
import 'package:sistema_cuentas/core/router/app_routes.dart';
import 'package:sistema_cuentas/features/home/widgets/balance_stat_main.dart';
import 'package:sistema_cuentas/features/home/widgets/balance_stat_tile.dart';
import 'package:sistema_cuentas/features/home/widgets/home_type_toggle.dart';
import 'package:sistema_cuentas/features/movements/movements_list_screen.dart';
import 'package:sistema_cuentas/features/movements/models/movement.dart';
import 'package:sistema_cuentas/features/movements/providers/movements_provider.dart';
import 'package:sistema_cuentas/features/movements/widgets/movement_tile.dart';
import 'package:sistema_cuentas/features/summary/models/summary_totals.dart';
import 'package:sistema_cuentas/features/summary/providers/month_summary_provider.dart';
import 'package:sistema_cuentas/shared/providers/balances_hidden_provider.dart';
import 'package:sistema_cuentas/shared/utils/movement_type_style.dart';
import 'package:sistema_cuentas/shared/widgets/app_toggle.dart';
import 'package:sistema_cuentas/shared/widgets/animated_number_text.dart';

import '../../helpers/movement_fixtures.dart';
import '../../support/fake_movements_repository.dart';
import '../../support/fake_summary_repository.dart';
import '../../support/inicio_overrides.dart';
import '../../support/pump_router_app.dart';

SummaryTotals get _totals => buildTotals(
  incomeCents: 150000000,
  expenseCents: 42000000,
  netFlowCents: 108000000,
);

List<Movement> _items() {
  final today = DateTime.now();
  return [
    buildMovement(id: 3, valueCents: 2500000, date: today),
    buildMovement(
      id: 2,
      type: MovementType.income,
      valueCents: 40000000,
      description: 'Salario',
      category: 'Nómina',
      method: 'Bancolombia',
      date: today,
    ),
    buildMovement(
      id: 1,
      valueCents: 750000,
      description: 'Taxi',
      category: 'Transporte',
      method: 'Efectivo',
      date: today.subtract(const Duration(days: 1)),
    ),
  ];
}

/// El conmutador Todos / Ingresos / Gastos de Inicio.
Finder get _toggle => find.byType(HomeTypeToggle);

/// Una opción del conmutador (se toca por su `InkWell`).
Finder _option(String label) => find.descendant(
  of: _toggle,
  matching: find.ancestor(of: find.text(label), matching: find.byType(InkWell)),
);

Future<void> _choose(WidgetTester tester, String label) async {
  await tester.tap(_option(label));
  await tester.pumpAndSettle();
}

/// El color de la pastilla elegida del conmutador.
Color? _selectedColor(WidgetTester tester) {
  final box = tester
      .widgetList<AnimatedContainer>(
        find.descendant(
          of: find.byType(AppToggle<MovementType?>),
          matching: find.byType(AnimatedContainer),
        ),
      )
      .map((c) => c.decoration)
      .whereType<BoxDecoration>()
      .where((d) => d.boxShadow != null && d.boxShadow!.isNotEmpty)
      .single;
  return box.color;
}

void main() {
  group('cuatro estados', () {
    testWidgets('cargando: cargador de página, sin balance ni lista', (
      tester,
    ) async {
      final completer = Completer<List<Movement>>();
      await pumpRouterApp(
        tester,
        settle: false,
        overrides: dataOverrides(
          movements: FakeMovementsRepository(
            onList: (_, _) => completer.future,
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Balance disponible'), findsNothing);
      expect(find.byType(MovementTile), findsNothing);
      expect(find.byTooltip('Nuevo movimiento'), findsOneWidget);

      completer.complete(const []);
      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets(
      'error: mensaje en español y «Intentar nuevamente» recarga todo',
      (tester) async {
        var fail = true;
        final movements = FakeMovementsRepository(
          onList: (_, _) async {
            if (fail) {
              throw const NetworkException('Sin conexión con el servidor.');
            }
            return _items();
          },
        );
        final summary = FakeSummaryRepository((_) async => _totals);
        await pumpRouterApp(
          tester,
          overrides: dataOverrides(movements: movements, summary: summary),
        );

        expect(find.text('Sin conexión con el servidor.'), findsOneWidget);
        expect(find.text('Intentar nuevamente'), findsOneWidget);
        expect(find.byType(MovementTile), findsNothing);

        fail = false;
        await tester.tap(find.text('Intentar nuevamente'));
        await tester.pumpAndSettle();

        expect(movements.listCalls, 2);
        expect(find.text('Sin conexión con el servidor.'), findsNothing);
        expect(find.byType(MovementTile), findsNWidgets(3));
        expect(find.text('Balance disponible'), findsOneWidget);
      },
    );

    testWidgets(
      'datos: balance del servidor, días y movimientos con su signo',
      (tester) async {
        await pumpRouterApp(
          tester,
          overrides: dataOverrides(items: _items(), totals: _totals),
        );

        expect(find.text('Balance disponible'), findsOneWidget);
        expect(find.text(r'$ 1.080.000'), findsOneWidget);
        expect(find.text(r'+$ 1.500.000'), findsOneWidget);
        expect(find.text(r'-$ 420.000'), findsOneWidget);

        expect(find.text('Hoy'), findsOneWidget);
        expect(find.text('Ayer'), findsOneWidget);
        expect(find.byType(MovementTile), findsNWidgets(3));
        expect(find.text('Mercado'), findsOneWidget);
        expect(find.text(r'-$ 25.000'), findsOneWidget);
        expect(find.text(r'+$ 400.000'), findsOneWidget);
        // El taxi de ayer: su fila y el neto del día «Ayer» valen lo mismo.
        expect(find.text(r'-$ 7.500'), findsNWidgets(2));
        // Neto de hoy = +400.000 − 25.000 (el encabezado del día) y Ayer = −7.500.
        expect(find.text(r'+$ 375.000'), findsOneWidget);
        // Cada dato de la fila es un Text aparte (DotSeparatedText).
        expect(find.text('Nómina ·'), findsOneWidget);
        expect(find.text('Bancolombia'), findsOneWidget);
      },
    );

    testWidgets('mes vacío: mensaje con «+» y el balance sigue visible', (
      tester,
    ) async {
      await pumpRouterApp(tester, overrides: dataOverrides(totals: _totals));

      expect(find.text('Sin movimientos este mes'), findsOneWidget);
      expect(find.textContaining('Toca «+»'), findsOneWidget);
      expect(find.text('Balance disponible'), findsOneWidget);
      expect(find.text(r'$ 1.080.000'), findsOneWidget);
      expect(_toggle, findsOneWidget, reason: 'el conmutador sigue visible');
      expect(
        find.byType(TextField),
        findsNothing,
        reason: 'ya no hay buscador',
      );
      expect(find.byType(MovementTile), findsNothing);
    });
  });

  group('conmutador Todos / Ingresos / Gastos', () {
    testWidgets('ya no hay buscador en Inicio', (tester) async {
      await pumpRouterApp(
        tester,
        overrides: dataOverrides(items: _items(), totals: _totals),
      );

      expect(find.byType(TextField), findsNothing);
      expect(find.byTooltip('Borrar búsqueda'), findsNothing);
      expect(_toggle, findsOneWidget);
      expect(find.text('Todos'), findsOneWidget);
    });

    testWidgets('empieza en «Todos» con las tres filas', (tester) async {
      await pumpRouterApp(
        tester,
        overrides: dataOverrides(items: _items(), totals: _totals),
      );

      expect(find.byType(MovementTile), findsNWidgets(3));
      expect(find.text('Hoy'), findsOneWidget);
      expect(find.text('Ayer'), findsOneWidget);
      expect(_selectedColor(tester), isNotNull);
    });

    testWidgets('Ingresos deja solo los ingresos y Todos los devuelve', (
      tester,
    ) async {
      final movements = FakeMovementsRepository(
        onList: (_, _) async => _items(),
      );
      await pumpRouterApp(
        tester,
        overrides: dataOverrides(movements: movements, totals: _totals),
      );

      await _choose(tester, 'Ingresos');

      expect(find.byType(MovementTile), findsOneWidget);
      expect(find.text('Salario'), findsOneWidget);
      expect(find.text('Mercado'), findsNothing);
      expect(find.text('Taxi'), findsNothing);
      expect(
        find.text('Ayer'),
        findsNothing,
        reason: 'el día sin ingresos sale',
      );
      expect(find.text('Balance disponible'), findsOneWidget);

      await _choose(tester, 'Todos');

      expect(find.byType(MovementTile), findsNWidgets(3));
      expect(find.text('Ayer'), findsOneWidget);
      expect(movements.listCalls, 1, reason: 'filtrar no pide nada a la red');
      expect(movements.searchCalls, 0);
    });

    testWidgets('Gastos deja solo los gastos y el neto del día se recalcula', (
      tester,
    ) async {
      await pumpRouterApp(
        tester,
        overrides: dataOverrides(items: _items(), totals: _totals),
      );

      await _choose(tester, 'Gastos');

      expect(find.byType(MovementTile), findsNWidgets(2));
      expect(find.text('Mercado'), findsOneWidget);
      expect(find.text('Taxi'), findsOneWidget);
      expect(find.text('Salario'), findsNothing);
      expect(find.text(r'+$ 400.000'), findsNothing);
      // Hoy: solo el mercado, así su fila y el neto del día valen lo mismo.
      expect(find.text(r'-$ 25.000'), findsNWidgets(2));
      expect(find.text(r'+$ 375.000'), findsNothing);
    });

    testWidgets('la pastilla elegida es verde en Ingresos y roja en Gastos', (
      tester,
    ) async {
      await pumpRouterApp(
        tester,
        overrides: dataOverrides(items: _items(), totals: _totals),
      );

      await _choose(tester, 'Ingresos');
      expect(_selectedColor(tester), MovementType.income.fill);

      await _choose(tester, 'Gastos');
      expect(_selectedColor(tester), MovementType.expense.fill);

      await _choose(tester, 'Todos');
      expect(_selectedColor(tester), isNot(MovementType.income.fill));
      expect(_selectedColor(tester), isNot(MovementType.expense.fill));
    });

    testWidgets('sin ingresos: «Sin ingresos este mes» y el conmutador sigue', (
      tester,
    ) async {
      await pumpRouterApp(
        tester,
        overrides: dataOverrides(
          items: [buildMovement(id: 1, date: DateTime.now())],
          totals: _totals,
        ),
      );

      await _choose(tester, 'Ingresos');

      expect(find.text('Sin ingresos este mes'), findsOneWidget);
      expect(find.text('Sin movimientos este mes'), findsNothing);
      expect(find.byType(MovementTile), findsNothing);
      expect(_toggle, findsOneWidget);
      expect(find.text('Balance disponible'), findsOneWidget);

      await _choose(tester, 'Todos');
      expect(find.byType(MovementTile), findsOneWidget);
    });

    testWidgets('sin gastos: «Sin gastos este mes»', (tester) async {
      await pumpRouterApp(
        tester,
        overrides: dataOverrides(
          items: [
            buildMovement(
              id: 1,
              type: MovementType.income,
              date: DateTime.now(),
            ),
          ],
          totals: _totals,
        ),
      );

      await _choose(tester, 'Gastos');

      expect(find.text('Sin gastos este mes'), findsOneWidget);
      expect(find.byType(MovementTile), findsNothing);
    });

    testWidgets('mes vacío: el mensaje general, en cualquiera de los tres', (
      tester,
    ) async {
      await pumpRouterApp(tester, overrides: dataOverrides(totals: _totals));
      expect(find.text('Sin movimientos este mes'), findsOneWidget);

      await _choose(tester, 'Ingresos');
      expect(find.text('Sin ingresos este mes'), findsOneWidget);

      await _choose(tester, 'Gastos');
      expect(find.text('Sin gastos este mes'), findsOneWidget);

      await _choose(tester, 'Todos');
      expect(find.text('Sin movimientos este mes'), findsOneWidget);
    });

    testWidgets('un movimiento nuevo del tipo filtrado aparece sin recargar', (
      tester,
    ) async {
      final movements = FakeMovementsRepository(
        onList: (_, _) async => _items(),
      );
      final container = await pumpRouterApp(
        tester,
        overrides: dataOverrides(movements: movements, totals: _totals),
      );
      await _choose(tester, 'Ingresos');
      expect(find.byType(MovementTile), findsOneWidget);

      container
          .read(movementsProvider.notifier)
          .upsert(
            buildMovement(
              id: 60,
              type: MovementType.income,
              description: 'Venta nueva',
              date: DateTime.now(),
            ),
          );
      container
          .read(movementsProvider.notifier)
          .upsert(
            buildMovement(
              id: 61,
              description: 'Gasto nuevo',
              date: DateTime.now(),
            ),
          );
      await tester.pumpAndSettle();

      expect(find.text('Venta nueva'), findsOneWidget);
      expect(find.text('Gasto nuevo'), findsNothing);
      expect(find.byType(MovementTile), findsNWidgets(2));
      expect(movements.listCalls, 1);
    });

    testWidgets('el filtro sobrevive a refrescar la lista', (tester) async {
      final container = await pumpRouterApp(
        tester,
        overrides: dataOverrides(items: _items(), totals: _totals),
      );
      await _choose(tester, 'Gastos');

      container.invalidate(movementsProvider);
      await tester.pumpAndSettle();

      expect(find.byType(MovementTile), findsNWidgets(2));
      expect(find.text('Salario'), findsNothing);
    });

    testWidgets('con cifras tapadas el filtro sigue funcionando', (
      tester,
    ) async {
      final container = await pumpRouterApp(
        tester,
        overrides: dataOverrides(items: _items(), totals: _totals),
      );
      container.read(balancesHiddenProvider.notifier).toggle();
      await tester.pumpAndSettle();

      await _choose(tester, 'Ingresos');

      expect(find.byType(MovementTile), findsOneWidget);
      expect(find.text(r'+$ 400.000'), findsNothing);
    });
  });

  group('tarjetas de Ingresos y Gastos del balance', () {
    Finder tile(MovementType type) =>
        find.byWidgetPredicate((w) => w is BalanceStatTile && w.type == type);

    testWidgets('cada tarjeta lleva su etiqueta, su cifra y su flecha', (
      tester,
    ) async {
      await pumpRouterApp(
        tester,
        overrides: dataOverrides(items: _items(), totals: _totals),
      );

      expect(tile(MovementType.income), findsOneWidget);
      expect(tile(MovementType.expense), findsOneWidget);
      expect(
        find.descendant(
          of: tile(MovementType.income),
          matching: find.text('Ingresos'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: tile(MovementType.expense),
          matching: find.text(r'-$ 420.000'),
        ),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.chevron_right_rounded), findsNWidgets(2));
    });

    testWidgets('tocar Ingresos abre /movements/income con solo ingresos', (
      tester,
    ) async {
      await pumpRouterApp(
        tester,
        overrides: dataOverrides(items: _items(), totals: _totals),
      );

      await tester.tap(tile(MovementType.income));
      await tester.pumpAndSettle();

      expect(currentLocation(tester), '/movements/income');
      expect(find.byType(MovementsListScreen), findsOneWidget);
      expect(find.widgetWithText(AppBar, 'Ingresos'), findsOneWidget);
      expect(find.text('Salario'), findsOneWidget);
      expect(find.text('Mercado'), findsNothing);
    });

    testWidgets('tocar Gastos abre /movements/expense con solo gastos', (
      tester,
    ) async {
      await pumpRouterApp(
        tester,
        overrides: dataOverrides(items: _items(), totals: _totals),
      );

      await tester.tap(tile(MovementType.expense));
      await tester.pumpAndSettle();

      expect(currentLocation(tester), '/movements/expense');
      expect(find.widgetWithText(AppBar, 'Gastos'), findsOneWidget);
      expect(find.text('Mercado'), findsOneWidget);
      expect(find.text('Taxi'), findsOneWidget);
      expect(find.text('Salario'), findsNothing);
    });

    testWidgets('«Atrás» vuelve a Inicio con su filtro y su lista', (
      tester,
    ) async {
      await pumpRouterApp(
        tester,
        overrides: dataOverrides(items: _items(), totals: _totals),
      );
      await _choose(tester, 'Gastos');

      await tester.tap(tile(MovementType.income));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Atrás'));
      await tester.pumpAndSettle();

      expect(currentLocation(tester), AppRoutes.home);
      expect(find.byType(MovementsListScreen), findsNothing);
      expect(find.byType(MovementTile), findsNWidgets(2));
    });

    testWidgets('con cifras tapadas se puede abrir la lista igual', (
      tester,
    ) async {
      final container = await pumpRouterApp(
        tester,
        overrides: dataOverrides(items: _items(), totals: _totals),
      );
      container.read(balancesHiddenProvider.notifier).toggle();
      await tester.pumpAndSettle();

      await tester.tap(tile(MovementType.expense));
      await tester.pumpAndSettle();

      expect(find.byType(MovementsListScreen), findsOneWidget);
    });

    testWidgets('una ruta inválida redirige a Inicio', (tester) async {
      await pumpRouterApp(
        tester,
        initialLocation: '/movements/otra',
        overrides: dataOverrides(items: _items(), totals: _totals),
      );

      expect(find.byType(MovementsListScreen), findsNothing);
      expect(currentLocation(tester), AppRoutes.home);
      expect(find.text('Balance disponible'), findsOneWidget);
    });

    testWidgets('la voz de la tarjeta dice el tipo, el monto y el destino', (
      tester,
    ) async {
      await pumpRouterApp(
        tester,
        overrides: dataOverrides(items: _items(), totals: _totals),
      );
      final handle = tester.ensureSemantics();

      expect(
        find.bySemanticsLabel(RegExp(r'^Ingresos, \+\$ 1\.500\.000')),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(RegExp(r'^Gastos, -\$ 420\.000')),
        findsOneWidget,
      );
      // La voz es de la parte tocable de la tarjeta (el despegable «Por medio»
      // tiene su propia semántica).
      final node = tester.getSemantics(
        find.descendant(
          of: tile(MovementType.income),
          matching: find.byType(BalanceStatMain),
        ),
      );
      expect(node.label, r'Ingresos, +$ 1.500.000');
      expect(node.hint, 'Abre la lista de ingresos');
      expect(node.flagsCollection.isButton, isTrue);
      handle.dispose();
    });
  });

  group('cifras tapadas con el ojo', () {
    testWidgets(
      'tapar oculta balance, totales y montos; destapar los devuelve',
      (tester) async {
        final container = await pumpRouterApp(
          tester,
          overrides: dataOverrides(items: _items(), totals: _totals),
        );
        expect(find.text(r'$ 1.080.000'), findsOneWidget);

        container.read(balancesHiddenProvider.notifier).toggle();
        await tester.pumpAndSettle();

        expect(find.text(r'$ 1.080.000'), findsNothing);
        expect(find.text(r'+$ 1.500.000'), findsNothing);
        expect(find.text(r'-$ 25.000'), findsNothing);
        expect(find.text(r'+$ 400.000'), findsNothing);
        expect(find.text(r'+$ 375.000'), findsNothing);
        // Balance + 2 tarjetas + 2 netos de día + 3 filas.
        expect(find.text(AnimatedNumberText.mask), findsNWidgets(8));
        // La descripción no se tapa; solo el dinero.
        expect(find.text('Mercado'), findsOneWidget);

        container.read(balancesHiddenProvider.notifier).toggle();
        await tester.pumpAndSettle();
        expect(find.text(r'$ 1.080.000'), findsOneWidget);
        expect(find.text(AnimatedNumberText.mask), findsNothing);
      },
    );

    testWidgets('la voz de la fila no dice el monto cuando está tapado', (
      tester,
    ) async {
      final container = await pumpRouterApp(
        tester,
        overrides: dataOverrides(items: _items(), totals: _totals),
      );
      final handle = tester.ensureSemantics();

      expect(
        find.bySemanticsLabel(
          RegExp(r'Gasto, Mercado, Alimentación, Nequi, -\$ 25\.000 pesos'),
        ),
        findsOneWidget,
      );

      container.read(balancesHiddenProvider.notifier).toggle();
      await tester.pumpAndSettle();

      expect(
        find.bySemanticsLabel('Gasto, Mercado, monto oculto'),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel('Monto oculto'), findsWidgets);
      handle.dispose();
    });
  });

  group('balance con sus propios estados', () {
    testWidgets(
      'resumen con error: mensaje y reintento propios; la lista se ve',
      (tester) async {
        var fail = true;
        final summary = FakeSummaryRepository((_) async {
          if (fail) throw const ApiException('No se pudo calcular el balance.');
          return _totals;
        });
        await pumpRouterApp(
          tester,
          overrides: dataOverrides(items: _items(), summary: summary),
        );

        expect(find.text('No se pudo calcular el balance.'), findsOneWidget);
        expect(find.byType(MovementTile), findsNWidgets(3));
        expect(find.text('Balance disponible'), findsNothing);

        fail = false;
        await tester.tap(find.text('Intentar nuevamente'));
        await tester.pumpAndSettle();

        expect(summary.calls, 2);
        expect(find.text('Balance disponible'), findsOneWidget);
        expect(find.text('No se pudo calcular el balance.'), findsNothing);
      },
    );

    testWidgets(
      'resumen cargando: progreso solo en el balance y la lista ya está',
      (tester) async {
        final completer = Completer<SummaryTotals>();
        await pumpRouterApp(
          tester,
          settle: false,
          overrides: dataOverrides(
            items: _items(),
            summary: FakeSummaryRepository((_) => completer.future),
          ),
        );

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.byType(MovementTile), findsNWidgets(3));

        completer.complete(_totals);
        await tester.pumpAndSettle();
        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(find.text(r'$ 1.080.000'), findsOneWidget);
      },
    );

    testWidgets(
      'refrescar el resumen conserva la cifra que se ve (sin cargador)',
      (tester) async {
        var call = 0;
        final second = Completer<SummaryTotals>();
        final container = await pumpRouterApp(
          tester,
          overrides: dataOverrides(
            items: _items(),
            summary: FakeSummaryRepository(
              (_) => ++call == 1 ? Future.value(_totals) : second.future,
            ),
          ),
        );
        expect(find.text(r'$ 1.080.000'), findsOneWidget);

        container.invalidate(monthSummaryProvider);
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text(r'$ 1.080.000'), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsNothing);

        second.complete(
          buildTotals(
            incomeCents: 150000000,
            expenseCents: 0,
            netFlowCents: 150000000,
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text(r'$ 1.500.000'), findsOneWidget);
        expect(find.text(r'$ 1.080.000'), findsNothing);
      },
    );
  });

  group('datos compartidos', () {
    testWidgets(
      'un upsert en movementsProvider aparece en Inicio sin recargar',
      (tester) async {
        final movements = FakeMovementsRepository(
          onList: (_, _) async => _items(),
        );
        final container = await pumpRouterApp(
          tester,
          overrides: dataOverrides(movements: movements, totals: _totals),
        );
        expect(find.byType(MovementTile), findsNWidgets(3));

        container
            .read(movementsProvider.notifier)
            .upsert(
              buildMovement(
                id: 50,
                description: 'Café nuevo',
                date: DateTime.now(),
              ),
            );
        await tester.pumpAndSettle();

        expect(find.byType(MovementTile), findsNWidgets(4));
        expect(find.text('Café nuevo'), findsOneWidget);
        expect(movements.listCalls, 1);

        container.read(movementsProvider.notifier).remove(50);
        await tester.pumpAndSettle();
        expect(find.text('Café nuevo'), findsNothing);
      },
    );

    testWidgets(
      'refrescar la lista conserva lo que se ve y muestra la barra fina',
      (tester) async {
        var call = 0;
        final second = Completer<List<Movement>>();
        final container = await pumpRouterApp(
          tester,
          overrides: dataOverrides(
            totals: _totals,
            movements: FakeMovementsRepository(
              onList: (_, _) =>
                  ++call == 1 ? Future.value(_items()) : second.future,
            ),
          ),
        );

        container.invalidate(movementsProvider);
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.byType(MovementTile), findsNWidgets(3));
        expect(find.byType(LinearProgressIndicator), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsNothing);

        second.complete(_items().take(1).toList());
        await tester.pumpAndSettle();
        expect(find.byType(MovementTile), findsOneWidget);
        expect(find.byType(LinearProgressIndicator), findsNothing);
      },
    );
  });

  group('conmutador fijo al hacer scroll', () {
    testWidgets(
      '40 movimientos: al desplazar el conmutador queda arriba y sigue funcionando',
      (tester) async {
        final today = DateTime.now();
        final many = [
          for (var i = 1; i <= 40; i++)
            buildMovement(
              id: i,
              type: i.isEven ? MovementType.income : MovementType.expense,
              description: 'Movimiento número $i',
              date: DateTime(
                today.year,
                today.month,
                today.day,
              ).subtract(Duration(days: i % 5)),
            ),
        ];
        for (final scale in [1.0, 1.5]) {
          await pumpRouterApp(
            tester,
            textScale: scale,
            overrides: dataOverrides(items: many, totals: _totals),
          );
          final before = tester.getTopLeft(_toggle).dy;
          expect(before, greaterThan(100), reason: 'bajo el balance al inicio');

          await tester.drag(
            find.byType(CustomScrollView),
            const Offset(0, -1500),
          );
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull, reason: 'texto $scale');
          expect(
            tester.getTopLeft(_toggle).dy,
            lessThan(before),
            reason: 'el conmutador sube y se queda fijado (texto $scale)',
          );
          expect(tester.getTopLeft(_toggle).dy, lessThan(40));
          expect(tester.getRect(_toggle).bottom, greaterThan(0));
          expect(find.text('Balance disponible'), findsNothing);

          // Desde abajo del todo se puede cambiar de vista sin volver arriba.
          await tester.tap(_option('Ingresos'));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(find.text('Gastos'), findsWidgets);
          expect(
            find.byWidgetPredicate(
              (w) =>
                  w is MovementTile && w.movement.type == MovementType.expense,
            ),
            findsNothing,
          );

          await tester.drag(
            find.byType(CustomScrollView),
            const Offset(0, 3000),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(find.text('Balance disponible'), findsOneWidget);
        }
      },
    );
  });
}
