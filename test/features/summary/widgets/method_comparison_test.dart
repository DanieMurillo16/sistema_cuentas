import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_cuentas/core/errors/app_exception.dart';
import 'package:sistema_cuentas/core/models/movement_type.dart';
import 'package:sistema_cuentas/core/theme/app_colors.dart';
import 'package:sistema_cuentas/features/summary/data/summary_repository.dart';
import 'package:sistema_cuentas/features/summary/models/month_summary.dart';
import 'package:sistema_cuentas/features/summary/utils/summary_rules.dart';
import 'package:sistema_cuentas/features/summary/widgets/method_comparison_card.dart';
import 'package:sistema_cuentas/features/summary/widgets/method_comparison_tile.dart';
import 'package:sistema_cuentas/shared/widgets/animated_number_text.dart';

import '../../../helpers/movement_fixtures.dart';
import '../../../helpers/summary_fixtures.dart';
import '../../../support/fake_summary_repository.dart';
import '../../../support/pump_at_sizes.dart';
import '../../../support/pump_screen_app.dart';
import '../../../support/session_overrides.dart';

const _mask = AnimatedNumberText.mask;

DateTime get _thisMonth {
  final now = DateTime.now();
  return DateTime(now.year, now.month);
}

MethodComparison _cmp({
  int id = 2,
  String name = 'Nequi',
  int current = 2000000,
  int previous = 1000000,
}) => MethodComparison(
  methodId: id,
  name: name,
  currentCents: current,
  previousCents: previous,
);

Future<void> _pumpTile(
  WidgetTester tester,
  MethodComparison comparison, {
  bool income = true,
  bool hidden = false,
  int? highest,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: MethodComparisonTile(
          comparison: comparison,
          highest: highest ?? comparison.currentCents,
          income: income,
          hidden: hidden,
        ),
      ),
    ),
  );
}

Color? _colorOf(WidgetTester tester, String text) =>
    tester.widget<Text>(find.text(text)).style?.color;

Finder get _previousLine => find.textContaining('Mes pasado');

void main() {
  group('MethodComparisonTile', () {
    testWidgets('con mes pasado: dos líneas y la variación', (tester) async {
      await _pumpTile(tester, _cmp());

      expect(find.text('Nequi'), findsOneWidget);
      expect(find.text(r'Este mes $ 20.000'), findsOneWidget);
      expect(find.text(r'Mes pasado $ 10.000'), findsOneWidget);
      expect(find.text('▲ 100 %'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsNWidgets(2));
    });

    testWidgets(
      'mes pasado en 0: sin línea «Mes pasado», sin ▲▼ y una sola barra',
      (tester) async {
        await _pumpTile(tester, _cmp(previous: 0));

        expect(find.text(r'Este mes $ 20.000'), findsOneWidget);
        expect(_previousLine, findsNothing);
        expect(find.textContaining('▲'), findsNothing);
        expect(find.textContaining('▼'), findsNothing);
        expect(find.textContaining('%'), findsNothing);
        expect(find.byType(LinearProgressIndicator), findsOneWidget);
      },
    );

    testWidgets('mes pasado de 1 centavo cuenta como «hay mes pasado»', (
      tester,
    ) async {
      await _pumpTile(tester, _cmp(previous: 1));

      expect(_previousLine, findsOneWidget);
      expect(find.textContaining('▲'), findsOneWidget);
    });

    testWidgets('este mes en 0 y mes pasado con valor: ▼ 100 %', (
      tester,
    ) async {
      await _pumpTile(tester, _cmp(current: 0, previous: 500000));

      expect(find.text(r'Este mes $ 0'), findsOneWidget);
      expect(find.text('▼ 100 %'), findsOneWidget);
    });

    testWidgets('ambos en 0 (borde): no divide por cero ni pinta flecha', (
      tester,
    ) async {
      await _pumpTile(tester, _cmp(current: 0, previous: 0), highest: 0);

      expect(tester.takeException(), isNull);
      expect(_previousLine, findsNothing);
      expect(find.textContaining('▲'), findsNothing);
    });

    testWidgets('ingresos: sube verde, baja rojo', (tester) async {
      await _pumpTile(tester, _cmp(current: 2000000, previous: 1000000));
      expect(_colorOf(tester, '▲ 100 %'), AppColors.income);

      await _pumpTile(tester, _cmp(current: 500000, previous: 1000000));
      expect(_colorOf(tester, '▼ 50 %'), AppColors.expense);
    });

    testWidgets('gastos: sube rojo, baja verde', (tester) async {
      await _pumpTile(
        tester,
        _cmp(current: 1500000, previous: 1000000),
        income: false,
      );
      expect(_colorOf(tester, '▲ 50 %'), AppColors.expense);

      await _pumpTile(
        tester,
        _cmp(current: 500000, previous: 1000000),
        income: false,
      );
      expect(_colorOf(tester, '▼ 50 %'), AppColors.income);
    });

    testWidgets('con el ojo cerrado las cifras van enmascaradas', (
      tester,
    ) async {
      await _pumpTile(tester, _cmp(), hidden: true);

      expect(find.text('Este mes $_mask'), findsOneWidget);
      expect(find.text('Mes pasado $_mask'), findsOneWidget);
      expect(find.textContaining(r'$ '), findsNothing);
    });

    testWidgets('oculto y sin mes pasado: solo una cifra enmascarada', (
      tester,
    ) async {
      await _pumpTile(tester, _cmp(previous: 0), hidden: true);

      expect(find.text('Este mes $_mask'), findsOneWidget);
      expect(_previousLine, findsNothing);
    });
  });

  group('MethodComparisonCard: subtítulo según haya mes pasado', () {
    MonthSummary summaryOf({
      List<(MovementType, int, String, int)> rows = const [],
    }) => buildMonthSummary(
      byMethod: [
        for (final (type, id, name, cents) in rows)
          buildMethodTotal(type: type, id: id, name: name, totalCents: cents),
      ],
    );

    List<Override> overrides(
      Future<MonthSummary> Function(DateTime month) onMonth,
    ) => [
      ...sessionOverrides().overrides,
      summaryRepositoryProvider.overrideWithValue(
        FakeSummaryRepository(
          (m) async => (await onMonth(m)).totals,
          onMonth: onMonth,
        ),
      ),
    ];

    Future<void> pumpCard(
      WidgetTester tester,
      Future<MonthSummary> Function(DateTime month) onMonth, {
      bool hidden = false,
      double width = 390,
      double textScale = 1,
    }) async {
      await pumpScreenApp(
        tester,
        screen: Scaffold(
          body: SingleChildScrollView(
            child: MethodComparisonCard(
              summary: summaryOf(
                rows: [
                  (MovementType.income, 2, 'Nequi', 2000000),
                  (MovementType.expense, 2, 'Nequi', 500000),
                ],
              ),
              hidden: hidden,
            ),
          ),
        ),
        overrides: overrides(onMonth),
        width: width,
        textScale: textScale,
      );
    }

    const onlyThis = 'Cada medio de pago, este mes';
    const both = 'Cada medio de pago, este mes y el pasado';

    testWidgets('ningún medio con mes pasado: «…este mes»', (tester) async {
      await pumpCard(tester, (_) async => summaryOf());

      expect(find.text(onlyThis), findsOneWidget);
      expect(find.text(both), findsNothing);
      expect(_previousLine, findsNothing);
      expect(find.text(r'Este mes $ 20.000'), findsOneWidget);
    });

    testWidgets('algún medio con mes pasado: «…este mes y el pasado»', (
      tester,
    ) async {
      await pumpCard(
        tester,
        (_) async =>
            summaryOf(rows: [(MovementType.income, 2, 'Nequi', 1000000)]),
      );

      expect(find.text(both), findsOneWidget);
      expect(find.text(onlyThis), findsNothing);
      expect(find.text(r'Mes pasado $ 10.000'), findsOneWidget);
    });

    testWidgets(
      'el subtítulo sigue al tipo: gastos sin mes pasado vuelve a «…este mes»',
      (tester) async {
        // El mes pasado solo tuvo ingresos.
        await pumpCard(
          tester,
          (_) async =>
              summaryOf(rows: [(MovementType.income, 2, 'Nequi', 1000000)]),
        );
        expect(find.text(both), findsOneWidget);

        await tester.tap(
          find.descendant(
            of: find.byType(MethodComparisonCard),
            matching: find.text('Gastos'),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Por dónde sale'), findsOneWidget);
        expect(find.text(onlyThis), findsOneWidget);
        expect(_previousLine, findsNothing);
      },
    );

    testWidgets('si el mes pasado falla: «…este mes», sin línea del pasado', (
      tester,
    ) async {
      await pumpCard(tester, (month) {
        if (month == _thisMonth) return Future.value(summaryOf());
        return Future<MonthSummary>.error(
          const NetworkException('Sin conexión con el servidor.'),
        );
      });

      expect(find.text(onlyThis), findsOneWidget);
      expect(_previousLine, findsNothing);
      expect(find.text(r'Este mes $ 20.000'), findsOneWidget);
    });

    testWidgets('mezcla: el medio con mes pasado muestra ▲ y el otro no', (
      tester,
    ) async {
      await pumpScreenApp(
        tester,
        screen: Scaffold(
          body: SingleChildScrollView(
            child: MethodComparisonCard(
              summary: buildMonthSummary(
                byMethod: [
                  buildMethodTotal(
                    type: MovementType.income,
                    id: 2,
                    name: 'Nequi',
                    totalCents: 2000000,
                  ),
                  buildMethodTotal(
                    type: MovementType.income,
                    id: 8,
                    name: 'Daviplata',
                    totalCents: 900000,
                  ),
                ],
              ),
              hidden: false,
            ),
          ),
        ),
        overrides: overrides(
          (_) async =>
              summaryOf(rows: [(MovementType.income, 2, 'Nequi', 1000000)]),
        ),
      );

      expect(find.text(both), findsOneWidget);
      expect(find.textContaining('▲'), findsOneWidget);
      expect(_previousLine, findsOneWidget);
      expect(find.text('Daviplata'), findsOneWidget);
    });
  });

  group('desbordes de la tarjeta de comparación', () {
    MonthSummary longSummary() => buildMonthSummary(
      byMethod: [
        for (var i = 1; i <= 5; i++) ...[
          buildMethodTotal(
            type: MovementType.income,
            id: i,
            name: '$longCatalogName $i',
            totalCents: 99999999999900,
          ),
          buildMethodTotal(
            id: i,
            name: '$longCatalogName $i',
            totalCents: 99999999999900,
          ),
        ],
      ],
    );

    testWidgets('con y sin mes pasado, nombres largos y 12 dígitos', (
      tester,
    ) async {
      await expectNoOverflow(
        tester,
        Scaffold(
          body: SingleChildScrollView(
            child: MethodComparisonCard(summary: longSummary(), hidden: false),
          ),
        ),
        overrides: [
          ...sessionOverrides().overrides,
          summaryRepositoryProvider.overrideWithValue(
            FakeSummaryRepository(
              (m) async => longSummary().totals,
              onMonth: (m) async => m == _thisMonth
                  ? longSummary()
                  : buildMonthSummary(byMethod: const []),
            ),
          ),
        ],
      );
    });

    testWidgets('con mes pasado y el ojo abierto', (tester) async {
      await expectNoOverflow(
        tester,
        Scaffold(
          body: SingleChildScrollView(
            child: MethodComparisonCard(summary: longSummary(), hidden: false),
          ),
        ),
        overrides: [
          ...sessionOverrides().overrides,
          summaryRepositoryProvider.overrideWithValue(
            FakeSummaryRepository(
              (m) async => longSummary().totals,
              onMonth: (m) async => longSummary(),
            ),
          ),
        ],
      );
    });
  });
}
