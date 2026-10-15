import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_cuentas/core/models/movement_type.dart';
import 'package:sistema_cuentas/features/home/home_screen.dart';
import 'package:sistema_cuentas/features/home/widgets/balance_card.dart';
import 'package:sistema_cuentas/features/home/widgets/home_type_toggle.dart';
import 'package:sistema_cuentas/features/movements/models/movement.dart';
import 'package:sistema_cuentas/features/movements/widgets/day_total_button.dart';
import 'package:sistema_cuentas/features/summary/models/summary_totals.dart';
import 'package:sistema_cuentas/shared/providers/balances_hidden_provider.dart';
import 'package:sistema_cuentas/shared/providers/hidden_sections_provider.dart';
import 'package:sistema_cuentas/shared/widgets/animated_number_text.dart';
import 'package:sistema_cuentas/shared/widgets/visibility_toggle_button.dart';

import '../../helpers/movement_fixtures.dart';
import '../../support/expect_screen_no_overflow.dart';
import '../../support/inicio_overrides.dart';
import '../../support/pump_router_app.dart';

const _mask = AnimatedNumberText.mask;

SummaryTotals get _totals => buildTotals(
  incomeCents: 150000000,
  expenseCents: 42000000,
  netFlowCents: 108000000,
);

/// Hoy: un gasto (Mercado, 25.000) y un ingreso (Salario, 400.000) → neto
/// +375.000. Ayer: un gasto (Taxi, 7.500) → neto −7.500.
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

DateTime _day(int daysAgo) {
  final d = DateTime.now().subtract(Duration(days: daysAgo));
  return DateTime(d.year, d.month, d.day);
}

Finder _dayTotal(int daysAgo) =>
    find.byKey(ValueKey('day-total-${_day(daysAgo).toIso8601String()}'));

Finder get _cardEye => find.descendant(
  of: find.byType(BalanceCard),
  matching: find.byType(VisibilityToggleButton),
);

Finder get _cardMasks =>
    find.descendant(of: find.byType(BalanceCard), matching: find.text(_mask));

Finder _masksIn(Finder scope) =>
    find.descendant(of: scope, matching: find.text(_mask));

Future<ProviderContainer> _pump(
  WidgetTester tester, {
  List<Movement>? items,
  double width = 390,
}) => pumpRouterApp(
  tester,
  width: width,
  overrides: dataOverrides(items: items ?? _items(), totals: _totals),
);

Future<void> _tap(WidgetTester tester, Finder finder) async {
  // La lista se arma por demanda: si la fila no está construida, se baja.
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      finder,
      200,
      scrollable: find.byType(Scrollable).first,
    );
  }
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  group('el ojo de la tarjeta de balance', () {
    testWidgets('tapa solo las cifras de la tarjeta, no los totales de día ni '
        'las filas', (tester) async {
      final container = await _pump(tester);
      expect(_cardMasks, findsNothing);
      expect(find.text(r'$ 1.080.000'), findsOneWidget);

      await _tap(tester, _cardEye);

      expect(container.read(hiddenSectionsProvider), {'balance-card'});
      // balance + ingresos + gastos.
      expect(_cardMasks, findsNWidgets(3));
      expect(find.text(r'$ 1.080.000'), findsNothing);
      // Lo demás sigue a la vista.
      expect(find.text(r'+$ 375.000'), findsOneWidget, reason: 'neto de hoy');
      expect(find.text(r'-$ 7.500'), findsNWidgets(2), reason: 'neto + fila');
      expect(find.text(r'-$ 25.000'), findsNWidgets(1));
    });

    testWidgets('tocarlo otra vez destapa la tarjeta', (tester) async {
      final container = await _pump(tester);

      await _tap(tester, _cardEye);
      await _tap(tester, _cardEye);

      expect(container.read(hiddenSectionsProvider), isEmpty);
      expect(_cardMasks, findsNothing);
      expect(find.text(r'$ 1.080.000'), findsOneWidget);
    });

    testWidgets('el ojo cambia de icono y de tooltip', (tester) async {
      await _pump(tester);
      expect(find.byTooltip('Ocultar cifras'), findsOneWidget);
      expect(find.byIcon(Icons.visibility_rounded), findsWidgets);

      await _tap(tester, _cardEye);

      expect(
        find.descendant(
          of: find.byType(BalanceCard),
          matching: find.byTooltip('Mostrar cifras'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('mide 40 px (área táctil) y el icono usa el color sobre la '
        'marca', (tester) async {
      await _pump(tester);

      final size = tester.getSize(
        find.descendant(of: _cardEye, matching: find.byType(IconButton)),
      );
      expect(size, const Size.square(40));
    });
  });

  group('el neto de cada día', () {
    testWidgets('tocarlo tapa solo ese día', (tester) async {
      final container = await _pump(tester);

      await _tap(tester, _dayTotal(0));

      expect(container.read(hiddenSectionsProvider), {
        'day-${_apiDay(_day(0))}',
      });
      expect(_masksIn(_dayTotal(0)), findsOneWidget);
      expect(find.text(r'+$ 375.000'), findsNothing);
      // Ayer, la tarjeta y las filas de hoy siguen visibles.
      expect(_masksIn(_dayTotal(1)), findsNothing);
      expect(find.text(r'-$ 7.500'), findsNWidgets(2));
      expect(_cardMasks, findsNothing);
      expect(find.text(r'$ 1.080.000'), findsOneWidget);
      expect(find.text(r'-$ 25.000'), findsOneWidget);
    });

    testWidgets('tapar un día no tapa otro; cada uno se destapa solo', (
      tester,
    ) async {
      final container = await _pump(tester);

      await _tap(tester, _dayTotal(0));
      await _tap(tester, _dayTotal(1));
      expect(_masksIn(_dayTotal(0)), findsOneWidget);
      expect(_masksIn(_dayTotal(1)), findsOneWidget);
      expect(container.read(hiddenSectionsProvider), hasLength(2));

      await _tap(tester, _dayTotal(0));
      expect(_masksIn(_dayTotal(0)), findsNothing);
      expect(_masksIn(_dayTotal(1)), findsOneWidget);
      expect(find.text(r'+$ 375.000'), findsOneWidget);
    });

    testWidgets('el ojo de la tarjeta y el de un día no se pisan', (
      tester,
    ) async {
      await _pump(tester);

      await _tap(tester, _dayTotal(0));
      await _tap(tester, _cardEye);
      await _tap(tester, _dayTotal(0));

      expect(_cardMasks, findsNWidgets(3), reason: 'la tarjeta sigue tapada');
      expect(find.text(r'+$ 375.000'), findsOneWidget);
    });

    testWidgets('el área táctil mide al menos 40 px de alto', (tester) async {
      await _pump(tester);

      expect(tester.getSize(_dayTotal(0)).height, greaterThanOrEqualTo(40));
      expect(find.byType(DayTotalButton), findsNWidgets(2));
    });

    testWidgets('en la vista Gastos el neto del día es el de los gastos', (
      tester,
    ) async {
      await _pump(tester);
      await tester.tap(
        find.descendant(
          of: find.byType(HomeTypeToggle),
          matching: find.ancestor(
            of: find.text('Gastos'),
            matching: find.byType(InkWell),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Hoy: solo el Mercado (−25.000); el neto y la fila valen lo mismo.
      expect(find.text(r'-$ 25.000'), findsNWidgets(2));
      expect(find.text(r'+$ 375.000'), findsNothing);

      await _tap(tester, _dayTotal(0));

      expect(_masksIn(_dayTotal(0)), findsOneWidget);
      expect(find.text(r'-$ 25.000'), findsOneWidget, reason: 'queda la fila');
    });
  });

  group('el ojo de la cabecera (global) tapa todo', () {
    testWidgets('tarjeta, netos de día y filas', (tester) async {
      final container = await _pump(tester);

      container.read(balancesHiddenProvider.notifier).toggle();
      await tester.pumpAndSettle();

      expect(_cardMasks, findsNWidgets(3));
      expect(_masksIn(_dayTotal(0)), findsOneWidget);
      expect(_masksIn(_dayTotal(1)), findsOneWidget);
      expect(find.text(r'+$ 375.000'), findsNothing);
      expect(find.text(r'-$ 25.000'), findsNothing);
      expect(find.text(r'-$ 7.500'), findsNothing);
    });

    testWidgets('al destapar vuelve cada sección a como estaba por su ojo', (
      tester,
    ) async {
      final container = await _pump(tester);
      await _tap(tester, _cardEye);
      final global = container.read(balancesHiddenProvider.notifier);

      global.toggle();
      await tester.pumpAndSettle();
      expect(_masksIn(_dayTotal(0)), findsOneWidget);

      global.toggle();
      await tester.pumpAndSettle();
      expect(
        _masksIn(_dayTotal(0)),
        findsNothing,
        reason: 'nunca se tapó solo',
      );
      expect(
        _cardMasks,
        findsNWidgets(3),
        reason: 'la tarjeta sí se tapó sola',
      );
    });
  });

  group('semántica', () {
    testWidgets('el neto del día dice qué hace y su cifra', (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(tester);

      final node = tester.getSemantics(_dayTotal(0));
      // El encabezado «Hoy» y el botón comparten nodo (van en la misma fila).
      expect(node.label, contains('Ocultar el total de Hoy'));
      expect(node.value, r'+$ 375.000');
      expect(node.flagsCollection.isButton, isTrue);
      handle.dispose();
    });

    testWidgets('tapado: «Mostrar el total de Hoy» y sin cifra', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _pump(tester);
      await _tap(tester, _dayTotal(0));

      final node = tester.getSemantics(_dayTotal(0));
      expect(node.label, contains('Mostrar el total de Hoy'));
      expect(node.value, isEmpty);
      handle.dispose();
    });

    testWidgets('el encabezado «Hoy» sigue siendo un encabezado', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _pump(tester);

      expect(
        tester.getSemantics(find.text('Hoy')).flagsCollection.isHeader,
        isTrue,
      );
      handle.dispose();
    });
  });

  group('sin desbordes', () {
    final big = [
      buildMovement(
        id: 3,
        valueCents: 99999999999900,
        description: longDescription,
        category: longCatalogName,
        date: DateTime.now(),
      ),
      buildMovement(
        id: 2,
        type: MovementType.income,
        valueCents: 99999999999900,
        description: 'Salario',
        date: DateTime.now(),
      ),
    ];

    testWidgets('todo visible, importes de 12 dígitos', (tester) async {
      await expectScreenNoOverflow(
        tester,
        screen: const HomeScreen(),
        overrides: () => dataOverrides(items: big, totals: _totals),
      );
    });

    testWidgets('tarjeta y un día tapados', (tester) async {
      await expectScreenNoOverflow(
        tester,
        screen: const HomeScreen(),
        overrides: () => dataOverrides(items: big, totals: _totals),
        prepare: (tester) async {
          await _tap(tester, _cardEye);
          await _tap(tester, _dayTotal(0));
        },
      );
    });

    testWidgets('con el ojo global tapado', (tester) async {
      await expectScreenNoOverflow(
        tester,
        screen: const HomeScreen(),
        overrides: () => [
          ...dataOverrides(items: big, totals: _totals),
          balancesHiddenProvider.overrideWith(_HiddenNotifier.new),
        ],
      );
    });
  });
}

String _apiDay(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

class _HiddenNotifier extends BalancesHiddenNotifier {
  @override
  bool build() => true;
}
