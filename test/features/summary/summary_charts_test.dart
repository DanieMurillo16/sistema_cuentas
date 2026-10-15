import 'dart:async';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_cuentas/core/errors/app_exception.dart';
import 'package:sistema_cuentas/core/models/movement_type.dart';
import 'package:sistema_cuentas/core/theme/app_colors.dart';
import 'package:sistema_cuentas/core/theme/design_tokens.dart';
import 'package:sistema_cuentas/core/utils/date_formatter.dart';
import 'package:sistema_cuentas/features/movements/data/movements_repository.dart';
import 'package:sistema_cuentas/features/summary/data/summary_repository.dart';
import 'package:sistema_cuentas/features/summary/models/month_summary.dart';
import 'package:sistema_cuentas/features/summary/summary_screen.dart';
import 'package:sistema_cuentas/features/summary/widgets/category_movements_sheet.dart';
import 'package:sistema_cuentas/features/summary/widgets/donut_center.dart';
import 'package:sistema_cuentas/features/summary/widgets/donut_legend_tile.dart';
import 'package:sistema_cuentas/features/summary/widgets/summary_donut_card.dart';
import 'package:sistema_cuentas/features/summary/widgets/method_comparison_card.dart';
import 'package:sistema_cuentas/features/summary/widgets/summary_expense_trend_card.dart';
import 'package:sistema_cuentas/features/summary/widgets/summary_trend_card.dart';
import 'package:sistema_cuentas/features/summary/providers/summary_trend_provider.dart';
import 'package:sistema_cuentas/shared/providers/balances_hidden_provider.dart';
import 'package:sistema_cuentas/shared/providers/session_provider.dart';
import 'package:sistema_cuentas/shared/widgets/animated_number_text.dart';

import '../../helpers/movement_fixtures.dart';
import '../../helpers/summary_fixtures.dart';
import '../../support/fake_movements_repository.dart';
import '../../support/fake_summary_repository.dart';
import '../../support/pump_screen_app.dart';

const _mask = AnimatedNumberText.mask;

DateTime get _thisMonth {
  final now = DateTime.now();
  return DateTime(now.year, now.month);
}

bool _isCurrent(DateTime month) => month == _thisMonth;

/// Ingresos y gastos de un mes distintos para cada mes (el número del mes):
/// $ 10.000 × mes de ingresos y $ 5.000 × mes de gastos.
MonthSummary _byMonth(DateTime month, {MonthSummary Function()? base}) {
  final template = (base ?? buildMonthSummary)();
  return MonthSummary(
    totals: buildTotals(
      incomeCents: month.month * 1000000,
      expenseCents: month.month * 500000,
      netFlowCents: 0,
      count: 5,
    ),
    byCategory: template.byCategory,
    byMethod: template.byMethod,
    dues: template.dues,
  );
}

/// Este mes frente al pasado, medio por medio.
///
/// Ingresos: Nequi 20.000 vs 10.000 (▲ 100 %), Bancolombia 5.000 vs 10.000
/// (▼ 50 %), Daviplata solo este mes (sin variación).
/// Gastos: Nequi 3.000 vs 6.000 (▼ 50 %), Bancolombia 9.000 vs 6.000 (▲ 50 %).
MonthSummary _comparisonSummary(DateTime month) {
  final current = _isCurrent(month);
  return MonthSummary(
    totals: buildTotals(count: 5),
    byCategory: const [],
    byMethod: [
      buildMethodTotal(
        type: MovementType.income,
        id: 1,
        name: 'Nequi',
        totalCents: current ? 2000000 : 1000000,
      ),
      buildMethodTotal(
        type: MovementType.income,
        id: 2,
        name: 'Bancolombia',
        totalCents: current ? 500000 : 1000000,
      ),
      if (current)
        buildMethodTotal(
          type: MovementType.income,
          id: 3,
          name: 'Daviplata',
          totalCents: 100000,
        ),
      buildMethodTotal(
        id: 1,
        name: 'Nequi',
        totalCents: current ? 300000 : 600000,
      ),
      buildMethodTotal(
        id: 2,
        name: 'Bancolombia',
        totalCents: current ? 900000 : 600000,
      ),
    ],
    dues: const [],
  );
}

List<Override> _overrides(
  FakeSummaryRepository summary, {
  FakeMovementsRepository? movements,
}) => [
  sessionUserIdProvider.overrideWithValue(7),
  summaryRepositoryProvider.overrideWithValue(summary),
  movementsRepositoryProvider.overrideWithValue(
    movements ?? FakeMovementsRepository(onList: (_, _) async => const []),
  ),
];

FakeSummaryRepository _repo(
  Future<MonthSummary> Function(DateTime month) onMonth,
) => FakeSummaryRepository(
  (_) async => throw StateError('no se usa'),
  onMonth: onMonth,
);

Future<ProviderContainer> _pump(
  WidgetTester tester,
  FakeSummaryRepository summary, {
  FakeMovementsRepository? movements,
  double width = 390,
  bool settle = true,
}) => pumpScreenApp(
  tester,
  screen: const Scaffold(body: SummaryScreen()),
  overrides: _overrides(summary, movements: movements),
  width: width,
  height: 900,
  settle: settle,
);

Finder _within(Type card, Finder what) =>
    find.descendant(of: find.byType(card), matching: what);

/// Lleva a la vista y toca (las tarjetas están en un scroll largo).
Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Color? _colorOf(WidgetTester tester, String text) =>
    tester.widget<Text>(find.text(text)).style?.color;

void main() {
  group('dona de categorías', () {
    MonthSummary categories() => buildMonthSummary(
      byCategory: [
        buildCategoryTotal(name: 'Alimentación', totalCents: 6000000),
        buildCategoryTotal(id: 4, name: 'Transporte', totalCents: 2000000),
        buildCategoryTotal(
          type: MovementType.income,
          id: 9,
          name: 'Salario',
          totalCents: 150000000,
        ),
      ],
    );

    testWidgets('el conmutador cambia entre gastos e ingresos', (tester) async {
      await _pump(tester, _repo((m) async => categories()));

      // Gastos (por defecto): total al centro y la leyenda con «monto · %».
      expect(_within(SummaryDonutCard, find.text('gastado')), findsOneWidget);
      expect(_within(SummaryDonutCard, find.text(r'$ 80.000')), findsOneWidget);
      expect(find.text(r'$ 60.000 · 75 %'), findsOneWidget);
      expect(find.text(r'$ 20.000 · 25 %'), findsOneWidget);
      expect(find.text('Salario'), findsNothing);

      await _tap(tester, _within(SummaryDonutCard, find.text('Ingresos')));

      expect(_within(SummaryDonutCard, find.text('ingresado')), findsOneWidget);
      expect(find.text('Salario'), findsOneWidget);
      expect(find.text(r'$ 1.500.000 · 100 %'), findsOneWidget);
      expect(find.text('Alimentación'), findsNothing);
      expect(
        find.text('De dónde viene tu dinero'),
        findsOneWidget,
        reason: 'el subtítulo acompaña al tipo',
      );

      await _tap(tester, _within(SummaryDonutCard, find.text('Gastos')));
      expect(find.text('Alimentación'), findsOneWidget);
      expect(find.text('En qué se va tu dinero'), findsOneWidget);
    });

    testWidgets('tocar un trozo de la dona muestra esa categoría al centro; '
        'tocarlo otra vez vuelve al total', (tester) async {
      await _pump(tester, _repo((m) async => categories()));
      final donut = find.byType(PieChart);
      await tester.ensureVisible(donut);
      await tester.pumpAndSettle();
      final center = tester.getCenter(donut);
      // El primer trozo (el mayor, Alimentación) arranca arriba y gira a la
      // derecha: un punto del aro justo a la derecha de las 12 en punto.
      final ring =
          DesignTokens.donutCenterRadius + DesignTokens.donutThickness / 2;
      final onFirstSlice = center + Offset(8, -ring);

      await tester.tapAt(onFirstSlice);
      await tester.pumpAndSettle();
      expect(_within(SummaryDonutCard, find.text('gastado')), findsNothing);
      expect(
        find.descendant(
          of: find.byType(DonutCenter),
          matching: find.text('Alimentación'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(DonutCenter),
          matching: find.text(r'$ 60.000'),
        ),
        findsOneWidget,
      );

      await tester.tapAt(onFirstSlice);
      await tester.pumpAndSettle();
      expect(_within(SummaryDonutCard, find.text('gastado')), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(DonutCenter),
          matching: find.text(r'$ 80.000'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('tocar fuera de un trozo (el hueco o fuera del aro) no lanza y '
        'deselecciona', (tester) async {
      await _pump(tester, _repo((m) async => categories()));
      final donut = find.byType(PieChart);
      await tester.ensureVisible(donut);
      await tester.pumpAndSettle();
      final center = tester.getCenter(donut);
      final ring =
          DesignTokens.donutCenterRadius + DesignTokens.donutThickness / 2;

      // Selecciona el primer trozo.
      await tester.tapAt(center + Offset(8, -ring));
      await tester.pumpAndSettle();
      expect(_within(SummaryDonutCard, find.text('gastado')), findsNothing);

      // Tocar el hueco, arriba del texto del centro: antes daba índice -1 y
      // RangeError.
      final inHole = center + Offset(0, -DesignTokens.donutCenterRadius * 0.9);
      await tester.tapAt(inHole);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(_within(SummaryDonutCard, find.text('gastado')), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(DonutCenter),
          matching: find.text(r'$ 80.000'),
        ),
        findsOneWidget,
      );

      // Selecciona otra vez y toca fuera del aro (la esquina del gráfico).
      await tester.tapAt(center + Offset(8, -ring));
      await tester.pumpAndSettle();
      expect(_within(SummaryDonutCard, find.text('gastado')), findsNothing);
      final corner = tester.getRect(donut).bottomRight - const Offset(2, 2);
      await tester.tapAt(corner);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(_within(SummaryDonutCard, find.text('gastado')), findsOneWidget);

      // Sin nada seleccionado, tocar fuera tampoco lanza.
      await tester.tapAt(corner);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(_within(SummaryDonutCard, find.text('gastado')), findsOneWidget);
    });

    testWidgets('el callback del gráfico con índice -1, nulo o fuera de rango '
        'no lanza y deja el total', (tester) async {
      await _pump(tester, _repo((m) async => categories()));
      final donut = find.byType(PieChart);
      await tester.ensureVisible(donut);
      await tester.pumpAndSettle();
      final callback = tester
          .widget<PieChart>(donut)
          .data
          .pieTouchData
          .touchCallback!;
      final tapUp = FlTapUpEvent(TapUpDetails(kind: PointerDeviceKind.touch));
      PieTouchResponse response(int index) => PieTouchResponse(
        touchLocation: Offset.zero,
        touchedSection: PieTouchedSection(null, index, 0, 0),
      );

      for (final touched in [response(-1), response(-5), response(99)]) {
        callback(tapUp, touched);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(
          _within(SummaryDonutCard, find.text('gastado')),
          findsOneWidget,
          reason: 'índice ${touched.touchedSection!.touchedSectionIndex}',
        );
      }
      // Sin respuesta o sin sección tocada.
      callback(tapUp, null);
      callback(
        tapUp,
        PieTouchResponse(touchLocation: Offset.zero, touchedSection: null),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(_within(SummaryDonutCard, find.text('gastado')), findsOneWidget);

      // Un índice válido sí selecciona; -1 después deselecciona.
      callback(tapUp, response(0));
      await tester.pumpAndSettle();
      expect(_within(SummaryDonutCard, find.text('gastado')), findsNothing);
      callback(tapUp, response(-1));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(_within(SummaryDonutCard, find.text('gastado')), findsOneWidget);
    });

    testWidgets('más de 6 categorías: las 5 mayores y «Otras» (sin flecha)', (
      tester,
    ) async {
      await _pump(
        tester,
        _repo(
          (m) async => buildMonthSummary(
            byCategory: [
              for (final (i, units) in [1, 2, 3, 10, 20, 30, 40, 50].indexed)
                buildCategoryTotal(
                  id: i + 1,
                  name: 'Categoría ${i + 1}',
                  totalCents: units * 100000,
                ),
            ],
          ),
        ),
      );

      expect(find.byType(DonutLegendTile), findsNWidgets(6));
      expect(find.text('Otras'), findsOneWidget);
      expect(find.text('Categoría 1'), findsNothing, reason: 'va en «Otras»');
      expect(find.text('Categoría 8'), findsOneWidget);
      // 1.000 + 2.000 + 3.000 = 6.000 de 156.000 → 4 %.
      expect(find.text(r'$ 6.000 · 4 %'), findsOneWidget);
      // Solo las 5 reales se pueden abrir.
      expect(
        _within(SummaryDonutCard, find.byIcon(Icons.chevron_right_rounded)),
        findsNWidgets(5),
      );
    });

    testWidgets('tocar «Otras» no abre nada', (tester) async {
      await _pump(
        tester,
        _repo(
          (m) async => buildMonthSummary(
            byCategory: [
              for (var i = 1; i <= 8; i++)
                buildCategoryTotal(
                  id: i,
                  name: 'Categoría $i',
                  totalCents: i * 100,
                ),
            ],
          ),
        ),
      );
      await _tap(tester, find.text('Otras'));
      expect(find.byType(CategoryMovementsSheet), findsNothing);
    });

    testWidgets(
      'tocar una categoría abre la hoja con SUS movimientos del mes',
      (tester) async {
        final movements = FakeMovementsRepository(
          onList: (_, _) async => [
            buildMovement(
              id: 1,
              description: 'mercado grande',
              valueCents: 4000000,
            ),
            buildMovement(id: 2, description: 'pan', valueCents: 250000),
            buildMovement(
              id: 3,
              description: 'taxi',
              categoryId: 4,
              category: 'Transporte',
            ),
            buildMovement(
              id: 4,
              type: MovementType.income,
              description: 'reembolso',
            ),
          ],
        );
        await _pump(
          tester,
          _repo((m) async => categories()),
          movements: movements,
        );

        await _tap(tester, find.text('Alimentación'));

        expect(find.byType(CategoryMovementsSheet), findsOneWidget);
        final sheet = find.byType(CategoryMovementsSheet);
        expect(
          find.descendant(of: sheet, matching: find.text('Alimentación')),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: sheet,
            matching: find.text(
              '2 movimientos en ${formatMonthLong(_thisMonth)}',
            ),
          ),
          findsOneWidget,
        );
        expect(find.text('Mercado grande'), findsOneWidget);
        expect(find.text('Pan'), findsOneWidget);
        expect(find.text('Taxi'), findsNothing, reason: 'otra categoría');
        expect(find.text('Reembolso'), findsNothing, reason: 'otro tipo');
        expect(find.text(r'-$ 40.000'), findsOneWidget);

        await tester.tap(find.text('Cerrar'));
        await tester.pumpAndSettle();
        expect(find.byType(CategoryMovementsSheet), findsNothing);
      },
    );

    testWidgets(
      'categoría sin movimientos en la lista: hoja vacía, sin error',
      (tester) async {
        await _pump(tester, _repo((m) async => categories()));
        await _tap(tester, find.text('Alimentación'));
        expect(find.byType(CategoryMovementsSheet), findsOneWidget);
        expect(
          find.text('0 movimientos en ${formatMonthLong(_thisMonth)}'),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('con las cifras tapadas la dona y la hoja no muestran montos', (
      tester,
    ) async {
      final movements = FakeMovementsRepository(
        onList: (_, _) async => [buildMovement(valueCents: 4000000)],
      );
      final container = await _pump(
        tester,
        _repo((m) async => categories()),
        movements: movements,
      );
      container.read(balancesHiddenProvider.notifier).toggle();
      await tester.pumpAndSettle();

      expect(_within(SummaryDonutCard, find.text(_mask)), findsWidgets);
      expect(
        _within(SummaryDonutCard, find.textContaining(r'$ ')),
        findsNothing,
      );

      await _tap(tester, find.text('Alimentación'));
      final sheet = find.byType(CategoryMovementsSheet);
      expect(
        find.descendant(of: sheet, matching: find.textContaining(r'$ ')),
        findsNothing,
      );
      expect(
        find.descendant(of: sheet, matching: find.text(_mask)),
        findsWidgets,
      );
    });
  });

  group('por dónde entra / sale', () {
    testWidgets('empieza en ingresos: ▲ verde si sube, ▼ rojo si baja', (
      tester,
    ) async {
      await _pump(tester, _repo((m) async => _comparisonSummary(m)));

      expect(find.text('Por dónde entra'), findsOneWidget);
      expect(find.text('Por dónde sale'), findsNothing);
      expect(find.text('▲ 100 %'), findsOneWidget, reason: 'Nequi');
      expect(find.text('▼ 50 %'), findsOneWidget, reason: 'Bancolombia');
      // Ingreso que sube = bueno (verde); que baja = malo (rojo).
      expect(_colorOf(tester, '▲ 100 %'), AppColors.income);
      expect(_colorOf(tester, '▼ 50 %'), AppColors.expense);
      expect(find.text(r'Este mes $ 20.000'), findsOneWidget);
      expect(find.text(r'Mes pasado $ 10.000'), findsWidgets);
    });

    testWidgets('el medio sin mes pasado no muestra flecha ni barra vacía', (
      tester,
    ) async {
      await _pump(tester, _repo((m) async => _comparisonSummary(m)));
      // Tres medios, solo dos con variación.
      expect(
        _within(MethodComparisonCard, find.textContaining(RegExp('[▲▼]'))),
        findsNWidgets(2),
      );
      expect(find.text('Daviplata'), findsWidgets);
      expect(find.text(r'Mes pasado $ 0'), findsNothing);
    });

    testWidgets('ordena por lo de este mes, de mayor a menor', (tester) async {
      await _pump(tester, _repo((m) async => _comparisonSummary(m)));
      Finder name(String n) => _within(MethodComparisonCard, find.text(n));
      final tops = [
        for (final n in ['Nequi', 'Bancolombia', 'Daviplata'])
          tester.getTopLeft(name(n)).dy,
      ];
      expect(tops, orderedEquals([...tops]..sort()));
    });

    testWidgets(
      'el conmutador pasa a gastos: ▼ verde si baja, ▲ rojo si sube',
      (tester) async {
        await _pump(tester, _repo((m) async => _comparisonSummary(m)));

        await _tap(tester, _within(MethodComparisonCard, find.text('Gastos')));

        expect(find.text('Por dónde sale'), findsOneWidget);
        expect(find.text('Por dónde entra'), findsNothing);
        // Nequi gastó menos (bueno, verde); Bancolombia gastó más (malo, rojo).
        expect(find.text('▼ 50 %'), findsOneWidget);
        expect(find.text('▲ 50 %'), findsOneWidget);
        expect(_colorOf(tester, '▼ 50 %'), AppColors.income);
        expect(_colorOf(tester, '▲ 50 %'), AppColors.expense);
        expect(
          _within(MethodComparisonCard, find.text('Daviplata')),
          findsNothing,
          reason: 'solo ingresos',
        );

        await _tap(
          tester,
          _within(MethodComparisonCard, find.text('Ingresos')),
        );
        expect(find.text('Por dónde entra'), findsOneWidget);
      },
    );

    testWidgets('sin datos de ningún mes: mensaje', (tester) async {
      await _pump(
        tester,
        _repo(
          (m) async =>
              buildMonthSummary(byCategory: const [], byMethod: const []),
        ),
      );
      expect(find.text('Nada este mes ni el pasado.'), findsOneWidget);
    });

    testWidgets('si el mes pasado no llega, se ve solo este mes', (
      tester,
    ) async {
      await _pump(
        tester,
        _repo((m) {
          if (m == _thisMonth) return Future.value(_comparisonSummary(m));
          return Future<MonthSummary>.error(
            const NetworkException('Sin conexión con el servidor.'),
          );
        }),
      );
      expect(find.text('Por dónde entra'), findsOneWidget);
      expect(find.text(r'Este mes $ 20.000'), findsOneWidget);
      expect(find.textContaining(RegExp('[▲▼]')), findsNothing);
    });

    testWidgets('con las cifras tapadas no muestra montos pero sí el cambio', (
      tester,
    ) async {
      final container = await _pump(
        tester,
        _repo((m) async => _comparisonSummary(m)),
      );
      container.read(balancesHiddenProvider.notifier).toggle();
      await tester.pumpAndSettle();

      expect(find.text('Este mes $_mask'), findsWidgets);
      expect(
        _within(MethodComparisonCard, find.textContaining(r'$ ')),
        findsNothing,
      );
    });
  });

  group('gráficas de tendencia (barras y línea)', () {
    BarChartData barData(WidgetTester tester) =>
        tester.widget<BarChart>(find.byType(BarChart)).data;
    LineChartData lineData(WidgetTester tester) =>
        tester.widget<LineChart>(find.byType(LineChart)).data;

    testWidgets(
      'barras: seis meses del más viejo al elegido, ingresos y gastos',
      (tester) async {
        await _pump(tester, _repo((m) async => _byMonth(m)));

        expect(
          _within(SummaryTrendCard, find.byType(BarChart)),
          findsOneWidget,
        );
        final groups = barData(tester).barGroups;
        expect(groups, hasLength(trendMonths));
        for (final (i, group) in groups.indexed) {
          final month = monthsBefore(_thisMonth, trendMonths - 1 - i);
          expect(group.barRods, hasLength(2), reason: 'ingresos y gastos');
          // rodIndex 0 = ingresos; 1 = gastos (cifras del servidor, en centavos).
          expect(group.barRods[0].toY, month.month * 1000000.0);
          expect(group.barRods[1].toY, month.month * 500000.0);
          expect(group.barRods[0].color, AppColors.income);
          expect(group.barRods[1].color, AppColors.expense);
        }
      },
    );

    testWidgets('línea: un punto por mes con los gastos de ese mes', (
      tester,
    ) async {
      await _pump(tester, _repo((m) async => _byMonth(m)));

      expect(find.text('Tendencia de gastos'), findsOneWidget);
      final spots = lineData(tester).lineBarsData.single.spots;
      expect(spots, hasLength(trendMonths));
      for (final (i, spot) in spots.indexed) {
        final month = monthsBefore(_thisMonth, trendMonths - 1 - i);
        expect(spot.x, i.toDouble());
        expect(spot.y, month.month * 500000.0);
      }
    });

    testWidgets('las tres gráficas existen: dona, barras y línea', (
      tester,
    ) async {
      await _pump(
        tester,
        _repo((m) async => _byMonth(m, base: () => buildMonthSummary())),
      );
      expect(find.byType(PieChart), findsOneWidget);
      expect(find.byType(BarChart), findsOneWidget);
      expect(find.byType(LineChart), findsOneWidget);
    });

    testWidgets(
      'el globo de las barras dice mes, tipo y monto (tapado con el ojo)',
      (tester) async {
        final container = await _pump(tester, _repo((m) async => _byMonth(m)));
        final last = trendMonths - 1;

        BarTooltipItem? tooltip(int rod) {
          final data = barData(tester);
          final group = data.barGroups[last];
          return data.barTouchData.touchTooltipData.getTooltipItem(
            group,
            last,
            group.barRods[rod],
            rod,
          );
        }

        final label = formatMonthShort(_thisMonth);
        expect(
          tooltip(0)!.text,
          '$label\nIngresos \$ ${_thisMonth.month * 10}.000',
        );
        expect(
          tooltip(1)!.text,
          '$label\nGastos \$ ${_thisMonth.month * 5}.000',
        );

        container.read(balancesHiddenProvider.notifier).toggle();
        await tester.pumpAndSettle();
        expect(tooltip(0)!.text, '$label\nIngresos $_mask');
        expect(tooltip(1)!.text, '$label\nGastos $_mask');
      },
    );

    testWidgets('el globo de la línea dice mes y monto (tapado con el ojo)', (
      tester,
    ) async {
      final container = await _pump(tester, _repo((m) async => _byMonth(m)));

      List<LineTooltipItem?> items() {
        final spot = lineData(tester).lineBarsData.single.spots.last;
        final line = lineData(tester).lineBarsData.single;
        return lineData(tester).lineTouchData.touchTooltipData
            .getTooltipItems([LineBarSpot(line, 0, spot)]);
      }

      final label = formatMonthShort(_thisMonth);
      expect(items().single!.text, '$label\n\$ ${_thisMonth.month * 5}.000');

      container.read(balancesHiddenProvider.notifier).toggle();
      await tester.pumpAndSettle();
      expect(items().single!.text, '$label\n$_mask');
    });

    testWidgets('con las cifras tapadas las gráficas se anuncian sin montos', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      final container = await _pump(tester, _repo((m) async => _byMonth(m)));
      container.read(balancesHiddenProvider.notifier).toggle();
      await tester.pumpAndSettle();

      expect(
        find.bySemanticsLabel(
          RegExp('Ingresos y gastos por mes, montos ocultos'),
        ),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(RegExp('Tendencia de gastos, montos ocultos')),
        findsOneWidget,
      );
      semantics.dispose();
    });

    testWidgets('mientras llegan los meses anteriores: cargador dentro de cada '
        'tarjeta y el resto de la pantalla ya se ve', (tester) async {
      final never = Completer<MonthSummary>();
      await _pump(
        tester,
        _repo((m) => _isCurrent(m) ? Future.value(_byMonth(m)) : never.future),
        settle: false,
      );

      expect(
        _within(SummaryTrendCard, find.byType(CircularProgressIndicator)),
        findsOneWidget,
      );
      expect(
        _within(
          SummaryExpenseTrendCard,
          find.byType(CircularProgressIndicator),
        ),
        findsOneWidget,
      );
      expect(find.byType(BarChart), findsNothing);
      expect(find.byType(LineChart), findsNothing);
      expect(find.text('El mes'), findsOneWidget);
    });

    testWidgets(
      'un mes anterior falla: mensaje en ambas tarjetas, sin gráficas, '
      'y el resto de la pantalla sigue',
      (tester) async {
        await _pump(
          tester,
          _repo((m) async {
            if (m == monthsBefore(_thisMonth, 3)) {
              throw const NetworkException('Sin conexión con el servidor.');
            }
            return _byMonth(m);
          }),
        );

        expect(
          _within(SummaryTrendCard, find.text('Sin conexión con el servidor.')),
          findsOneWidget,
        );
        expect(
          _within(
            SummaryExpenseTrendCard,
            find.text('Sin conexión con el servidor.'),
          ),
          findsOneWidget,
        );
        expect(find.byType(BarChart), findsNothing);
        expect(find.text('El mes'), findsOneWidget);
      },
    );

    // DEFECTO (summary_trend_card.dart / trend_async.dart): «Intentar
    // nuevamente» solo invalida monthlyTrendProvider; el mes que falló sigue
    // guardado como error en summaryForMonthProvider y la serie vuelve a
    // fallar aunque el servidor ya responda. Este caso se queda en rojo hasta
    // que el reintento invalide también summaryForMonthProvider.
    testWidgets(
      '«Intentar nuevamente» recarga la serie cuando el servidor ya responde',
      (tester) async {
        var fail = true;
        await _pump(
          tester,
          _repo((m) async {
            if (fail && m == monthsBefore(_thisMonth, 3)) {
              throw const NetworkException('Sin conexión con el servidor.');
            }
            return _byMonth(m);
          }),
        );
        expect(find.byType(BarChart), findsNothing);

        fail = false;
        await _tap(
          tester,
          _within(SummaryTrendCard, find.text('Intentar nuevamente')),
        );

        expect(find.byType(BarChart), findsOneWidget);
      },
    );
  });
}
