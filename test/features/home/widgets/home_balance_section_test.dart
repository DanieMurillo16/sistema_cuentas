import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_cuentas/core/errors/app_exception.dart';
import 'package:sistema_cuentas/core/models/movement_type.dart';
import 'package:sistema_cuentas/features/home/widgets/balance_method_lines.dart';
import 'package:sistema_cuentas/features/home/widgets/balance_stat_tile.dart';
import 'package:sistema_cuentas/features/home/widgets/home_balance_section.dart';
import 'package:sistema_cuentas/features/summary/data/summary_repository.dart';
import 'package:sistema_cuentas/features/summary/models/month_summary.dart';
import 'package:sistema_cuentas/features/summary/providers/month_summary_provider.dart';
import 'package:sistema_cuentas/shared/providers/balances_hidden_provider.dart';
import 'package:sistema_cuentas/shared/widgets/animated_number_text.dart';

import '../../../helpers/movement_fixtures.dart';
import '../../../helpers/summary_fixtures.dart';
import '../../../support/fake_summary_repository.dart';
import '../../../support/pump_at_sizes.dart';
import '../../../support/pump_screen_app.dart';
import '../../../support/session_overrides.dart';

const _section = Scaffold(
  body: SingleChildScrollView(
    padding: EdgeInsets.all(16),
    child: HomeBalanceSection(),
  ),
);

List<Override> _overrides(FakeSummaryRepository summary) => [
  ...sessionOverrides().overrides,
  summaryRepositoryProvider.overrideWithValue(summary),
];

FakeSummaryRepository _summaryOf(MonthSummary summary) => FakeSummaryRepository(
  (_) async => summary.totals,
  onMonth: (_) async => summary,
);

MonthSummary _withMethods() => buildMonthSummary(
  totals: buildTotals(
    incomeCents: 150000000,
    expenseCents: 42000000,
    netFlowCents: 108000000,
  ),
  byMethod: [
    buildMethodTotal(
      type: MovementType.income,
      id: 2,
      name: 'Nequi',
      totalCents: 100000000,
    ),
    buildMethodTotal(
      type: MovementType.income,
      id: 5,
      name: 'Bancolombia',
      totalCents: 50000000,
    ),
    buildMethodTotal(id: 2, name: 'Nequi', totalCents: 30000000),
    buildMethodTotal(id: 3, name: 'Efectivo', totalCents: 12000000),
  ],
);

Finder _tile(MovementType type) =>
    find.byWidgetPredicate((w) => w is BalanceStatTile && w.type == type);

Finder _in(MovementType type, Finder f) =>
    find.descendant(of: _tile(type), matching: f);

/// Abre el «Detalle» de las dos tarjetas (cada una tiene el suyo).
Future<void> _openMethods(WidgetTester tester) async {
  for (final type in ['INGRESO', 'GASTO']) {
    await tester.tap(find.byKey(ValueKey('balance-methods-toggle-$type')));
    await tester.pumpAndSettle();
  }
}

Future<ProviderContainer> _pump(
  WidgetTester tester,
  FakeSummaryRepository summary, {
  double width = 390,
  double textScale = 1,
}) => pumpScreenApp(
  tester,
  screen: _section,
  overrides: _overrides(summary),
  stubs: const ['/movements/income', '/movements/expense'],
  width: width,
  textScale: textScale,
);

void main() {
  group('HomeBalanceSection: datos con medios de pago', () {
    testWidgets('cada tarjeta muestra los medios de su tipo bajo el total', (
      tester,
    ) async {
      await _pump(tester, _summaryOf(_withMethods()));

      // Cerrado al empezar: solo los totales.
      expect(find.byType(BalanceMethodLines), findsNothing);
      expect(find.text('Nequi'), findsNothing);
      await _openMethods(tester);

      expect(find.text(r'$ 1.080.000'), findsOneWidget);
      expect(_in(MovementType.income, find.text('Nequi')), findsOneWidget);
      expect(
        _in(MovementType.income, find.text('Bancolombia')),
        findsOneWidget,
      );
      expect(_in(MovementType.income, find.text('Efectivo')), findsNothing);
      expect(_in(MovementType.expense, find.text('Nequi')), findsOneWidget);
      expect(_in(MovementType.expense, find.text('Efectivo')), findsOneWidget);
      expect(_in(MovementType.expense, find.text('Bancolombia')), findsNothing);
      // Importes de cada medio, en pesos.
      expect(find.text(r'$ 1.000.000'), findsOneWidget); // ingreso Nequi
      expect(find.text(r'$ 500.000'), findsOneWidget); // ingreso Bancolombia
      expect(find.text(r'$ 300.000'), findsOneWidget); // gasto Nequi
      expect(find.text(r'$ 120.000'), findsOneWidget); // gasto Efectivo
    });

    testWidgets('dentro de cada tarjeta, el medio mayor va primero', (
      tester,
    ) async {
      await _pump(tester, _summaryOf(_withMethods()));
      await _openMethods(tester);

      expect(
        tester
            .getTopLeft(find.byKey(const ValueKey('balance-method-GASTO-2')))
            .dy,
        lessThan(
          tester
              .getTopLeft(find.byKey(const ValueKey('balance-method-GASTO-3')))
              .dy,
        ),
      );
    });

    testWidgets(
      'el ojo cerrado enmascara el balance, los totales y los medios',
      (tester) async {
        final container = await _pump(tester, _summaryOf(_withMethods()));

        container.read(balancesHiddenProvider.notifier).toggle();
        await tester.pumpAndSettle();
        await _openMethods(tester);

        // balance + 2 totales + 2 medios de ingresos + 2 de gastos.
        expect(find.text(AnimatedNumberText.mask), findsNWidgets(7));
        expect(find.textContaining(r'$'), findsNothing);
        expect(
          find.text('Nequi'),
          findsNWidgets(2),
          reason: 'los nombres no son cifras',
        );
      },
    );

    testWidgets('al destapar vuelven los importes', (tester) async {
      final container = await _pump(tester, _summaryOf(_withMethods()));
      final notifier = container.read(balancesHiddenProvider.notifier);

      notifier.toggle();
      await tester.pumpAndSettle();
      await _openMethods(tester);
      notifier.toggle();
      await tester.pumpAndSettle();

      expect(find.text(AnimatedNumberText.mask), findsNothing);
      expect(find.text(r'$ 1.000.000'), findsOneWidget);
    });

    testWidgets('sin medios en el resumen no aparece ninguna línea', (
      tester,
    ) async {
      await _pump(tester, _summaryOf(buildMonthSummary(byMethod: const [])));

      expect(find.byType(BalanceMethodLines), findsNothing);
      expect(_tile(MovementType.income), findsOneWidget);
      expect(_tile(MovementType.expense), findsOneWidget);
    });

    testWidgets('medios con total 0 se omiten', (tester) async {
      await _pump(
        tester,
        _summaryOf(
          buildMonthSummary(
            byMethod: [
              buildMethodTotal(id: 3, name: 'Efectivo', totalCents: 0),
            ],
          ),
        ),
      );

      expect(find.byType(BalanceMethodLines), findsNothing);
      expect(find.text('Efectivo'), findsNothing);
    });

    testWidgets('tocar Ingresos o Gastos navega a su lista', (tester) async {
      await _pump(tester, _summaryOf(_withMethods()));

      await tester.tap(_tile(MovementType.income));
      await tester.pumpAndSettle();
      expect(find.text('Destino /movements/income'), findsOneWidget);
    });

    testWidgets('tocar Gastos navega a /movements/expense', (tester) async {
      await _pump(tester, _summaryOf(_withMethods()));

      await tester.tap(_tile(MovementType.expense));
      await tester.pumpAndSettle();
      expect(find.text('Destino /movements/expense'), findsOneWidget);
    });
  });

  group('HomeBalanceSection: cargando, error y refresco', () {
    testWidgets('primera carga: cargador y ninguna tarjeta', (tester) async {
      final pending = Completer<MonthSummary>();
      await pumpScreenApp(
        tester,
        screen: _section,
        overrides: _overrides(
          FakeSummaryRepository(
            (_) async => (await pending.future).totals,
            onMonth: (_) => pending.future,
          ),
        ),
        settle: false,
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(BalanceStatTile), findsNothing);

      pending.complete(_withMethods());
      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byType(BalanceStatTile), findsNWidgets(2));
      await _openMethods(tester);
      expect(find.text('Nequi'), findsNWidgets(2));
    });

    testWidgets(
      'error: mensaje en español y «Intentar nuevamente» que recarga',
      (tester) async {
        var fail = true;
        final repository = FakeSummaryRepository(
          (_) async => _withMethods().totals,
          onMonth: (_) async {
            if (fail) {
              throw const NetworkException('Sin conexión con el servidor');
            }
            return _withMethods();
          },
        );
        await _pump(tester, repository);

        expect(find.text('Sin conexión con el servidor'), findsOneWidget);
        expect(find.byType(BalanceStatTile), findsNothing);

        fail = false;
        await tester.tap(find.text('Intentar nuevamente'));
        await tester.pumpAndSettle();

        expect(find.text('Sin conexión con el servidor'), findsNothing);
        await _openMethods(tester);
        expect(_in(MovementType.income, find.text('Nequi')), findsOneWidget);
        expect(repository.calls, 2);
      },
    );

    testWidgets(
      'al refrescar conserva los medios que se ven y luego los actualiza',
      (tester) async {
        var current = _withMethods();
        Completer<MonthSummary>? gate;
        final repository = FakeSummaryRepository(
          (_) async => current.totals,
          onMonth: (_) => gate?.future ?? Future.value(current),
        );
        final container = await _pump(tester, repository);
        await _openMethods(tester);
        expect(find.text(r'$ 1.000.000'), findsOneWidget);

        gate = Completer<MonthSummary>();
        container.invalidate(monthSummaryProvider);
        await tester.pump();

        // Mientras llega la respuesta: los datos siguen, sin cargador de página.
        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(find.text(r'$ 1.000.000'), findsOneWidget);
        expect(_in(MovementType.income, find.text('Nequi')), findsOneWidget);

        // Mismo número de medios y de dígitos: solo cambian las cifras (si la
        // altura se achica con el despegable abierto hay un defecto: ver el
        // test de abajo).
        current = buildMonthSummary(
          byMethod: [
            buildMethodTotal(
              type: MovementType.income,
              id: 2,
              name: 'Nequi',
              totalCents: 777000000,
            ),
            buildMethodTotal(
              type: MovementType.income,
              id: 5,
              name: 'Bancolombia',
              totalCents: 40000000,
            ),
            buildMethodTotal(id: 2, name: 'Nequi', totalCents: 30000000),
            buildMethodTotal(id: 3, name: 'Efectivo', totalCents: 12000000),
          ],
        );
        gate.complete(current);
        await tester.pumpAndSettle();

        expect(find.text(r'$ 1.000.000'), findsNothing);
        expect(find.text(r'$ 7.770.000'), findsOneWidget);
        expect(find.text(r'$ 400.000'), findsOneWidget);
        // El despegable sigue abierto tras refrescar.
        expect(find.byType(BalanceMethodLines), findsNWidgets(2));
      },
    );

    // Antes lanzaba «RenderFlex overflowed» (IntrinsicHeight + AppCollapse):
    // con el despegable abierto, todo cambio que achica la altura debe ser
    // limpio.
    testWidgets('taparlo con el despegable abierto no lanza excepciones', (
      tester,
    ) async {
      final container = await _pump(tester, _summaryOf(_withMethods()));
      await _openMethods(tester);

      container.read(balancesHiddenProvider.notifier).toggle();
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });

  group('HomeBalanceSection: cambios con el despegable abierto', () {
    testWidgets('un refresco con menos medios y más cortos no lanza '
        'excepciones y deja el despegable abierto', (tester) async {
      var current = _withMethods();
      final repository = FakeSummaryRepository(
        (_) async => current.totals,
        onMonth: (_) async => current,
      );
      final container = await _pump(tester, repository);
      await _openMethods(tester);

      current = buildMonthSummary(
        byMethod: [
          buildMethodTotal(
            type: MovementType.income,
            id: 2,
            name: 'Nequi',
            totalCents: 100,
          ),
          buildMethodTotal(id: 2, name: 'Nequi', totalCents: 100),
        ],
      );
      container.invalidate(monthSummaryProvider);
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 60));
        expect(tester.takeException(), isNull);
      }
      await tester.pumpAndSettle();

      expect(find.text('Bancolombia'), findsNothing);
      expect(find.byType(BalanceMethodLines), findsNWidgets(2));
    });

    testWidgets('tapar y destapar el ojo con los dos abiertos, cuadro a '
        'cuadro', (tester) async {
      final container = await _pump(tester, _summaryOf(_withMethods()));
      await _openMethods(tester);
      final notifier = container.read(balancesHiddenProvider.notifier);

      for (var i = 0; i < 2; i++) {
        notifier.toggle();
        for (var f = 0; f < 6; f++) {
          await tester.pump(const Duration(milliseconds: 60));
          expect(tester.takeException(), isNull);
        }
        await tester.pumpAndSettle();
      }
      expect(find.text(r'$ 1.000.000'), findsOneWidget);
    });
  });

  group('HomeBalanceSection: desbordes', () {
    MonthSummary longSummary({int cents = 99999999999900}) => buildMonthSummary(
      totals: buildTotals(
        incomeCents: cents,
        expenseCents: cents,
        netFlowCents: -cents,
      ),
      byMethod: [
        for (var i = 1; i <= 6; i++) ...[
          buildMethodTotal(
            type: MovementType.income,
            id: i,
            name: '$longCatalogName $i',
            totalCents: cents - i,
          ),
          buildMethodTotal(
            id: i,
            name: '$longCatalogName $i',
            totalCents: cents - i,
          ),
        ],
      ],
    );

    testWidgets('6 medios de nombre largo e importes de 12 dígitos', (
      tester,
    ) async {
      await expectNoOverflow(
        tester,
        _section,
        overrides: _overrides(_summaryOf(longSummary())),
      );
    });

    testWidgets('el mismo resumen con el ojo cerrado', (tester) async {
      await expectNoOverflow(
        tester,
        _section,
        overrides: [
          ..._overrides(_summaryOf(longSummary())),
          balancesHiddenProvider.overrideWith(_HiddenNotifier.new),
        ],
      );
    });

    for (final hidden in [false, true]) {
      testWidgets(
        'importes de 8 dígitos a 320 px × texto 1.5, ojo ${hidden ? 'cerrado' : 'abierto'}',
        (tester) async {
          await expectNoOverflow(
            tester,
            _section,
            widths: const [320],
            scales: const [1.5],
            overrides: [
              ..._overrides(_summaryOf(longSummary(cents: 9999999900))),
              if (hidden)
                balancesHiddenProvider.overrideWith(_HiddenNotifier.new),
            ],
          );
        },
      );
    }

    testWidgets('sin medios y en cero', (tester) async {
      await expectNoOverflow(
        tester,
        _section,
        overrides: _overrides(
          _summaryOf(
            buildMonthSummary(
              totals: buildTotals(
                incomeCents: 0,
                expenseCents: 0,
                netFlowCents: 0,
                count: 0,
              ),
              byMethod: const [],
            ),
          ),
        ),
      );
    });

    testWidgets('error y cargando también caben', (tester) async {
      await expectNoOverflow(
        tester,
        _section,
        retry: (_, _) => null,
        overrides: _overrides(
          FakeSummaryRepository(
            (_) async => throw const NetworkException('Sin conexión'),
          ),
        ),
      );
    });
  });
}

class _HiddenNotifier extends BalancesHiddenNotifier {
  @override
  bool build() => true;
}
