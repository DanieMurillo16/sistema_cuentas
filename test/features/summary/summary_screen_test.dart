import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_cuentas/core/errors/app_exception.dart';
import 'package:sistema_cuentas/core/models/movement_type.dart';
import 'package:sistema_cuentas/features/summary/data/summary_repository.dart';
import 'package:sistema_cuentas/features/summary/models/month_summary.dart';
import 'package:sistema_cuentas/features/summary/models/summary_totals.dart';
import 'package:sistema_cuentas/features/summary/providers/month_summary_provider.dart';
import 'package:sistema_cuentas/features/summary/summary_screen.dart';
import 'package:sistema_cuentas/features/summary/widgets/summary_capital_card.dart';
import 'package:sistema_cuentas/features/summary/widgets/summary_methods_card.dart';
import 'package:sistema_cuentas/features/summary/widgets/trend_bars_chart.dart';
import 'package:sistema_cuentas/shared/providers/balances_hidden_provider.dart';
import 'package:sistema_cuentas/shared/providers/session_provider.dart';
import 'package:sistema_cuentas/shared/widgets/animated_number_text.dart';

import '../../helpers/movement_fixtures.dart';
import '../../helpers/summary_fixtures.dart';
import '../../support/fake_summary_repository.dart';
import '../../support/pump_screen_app.dart';

const _mask = AnimatedNumberText.mask;

SummaryTotals get _totals => buildTotals(
  incomeCents: 150000000,
  expenseCents: 42000000,
  netFlowCents: 108000000,
  count: 12,
);

FakeSummaryRepository _repo(
  Future<MonthSummary> Function(DateTime month) onMonth,
) => FakeSummaryRepository((_) async => _totals, onMonth: onMonth);

List<Override> _overrides(FakeSummaryRepository repo) => [
  sessionUserIdProvider.overrideWithValue(7),
  summaryRepositoryProvider.overrideWithValue(repo),
];

Future<ProviderContainer> _pump(
  WidgetTester tester,
  FakeSummaryRepository repo, {
  double width = 390,
  bool settle = true,
}) => pumpScreenApp(
  tester,
  screen: const Scaffold(body: SummaryScreen()),
  overrides: _overrides(repo),
  width: width,
  settle: settle,
);

MonthSummary _full() => buildMonthSummary(totals: _totals);

/// La barra fina de «recargando» (las barras de categoría tienen valor).
Finder get _reloadBar => find.byWidgetPredicate(
  (w) => w is LinearProgressIndicator && w.value == null,
);

/// ¿Es el mes que muestra la cabecera? (las gráficas piden además los 5
/// anteriores al mismo repositorio.)
bool _isSelectedMonth(DateTime month) {
  final now = DateTime.now();
  return month == DateTime(now.year, now.month);
}

double _top(WidgetTester tester, String text) =>
    tester.getTopLeft(find.text(text)).dy;

void main() {
  group('cuatro estados', () {
    testWidgets('cargando: solo el cargador de página', (tester) async {
      final never = Completer<MonthSummary>();
      await _pump(tester, _repo((_) => never.future), settle: false);

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('El mes'), findsNothing);
      expect(find.text('Sin movimientos este mes'), findsNothing);
    });

    testWidgets('datos: todas las tarjetas con sus cifras', (tester) async {
      await _pump(tester, _repo((_) async => _full()));

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('El mes'), findsOneWidget);
      expect(find.text('12 movimientos'), findsOneWidget);
      expect(find.text(r'$ 1.500.000'), findsWidgets);
      expect(find.text(r'$ 420.000'), findsWidgets);
      expect(find.text(r'+$ 1.080.000'), findsWidgets);
      expect(find.text('Pendiente del mes'), findsOneWidget);
      expect(find.text('Por cobrar'), findsOneWidget);
      expect(find.text('Por pagar'), findsOneWidget);
      expect(find.text('Ingresos vs gastos'), findsOneWidget);
      expect(find.text('Por categoría'), findsOneWidget);
      expect(find.text('Tendencia de gastos'), findsOneWidget);
      expect(find.text('Por dónde entra'), findsOneWidget);
      expect(find.text('Por medio de pago'), findsOneWidget);
      expect(find.text('Alimentación'), findsOneWidget);
    });

    testWidgets('error: mensaje en español y «Intentar nuevamente» recarga', (
      tester,
    ) async {
      var fail = true;
      final repo = _repo((_) async {
        if (fail) throw const NetworkException('Sin conexión con el servidor.');
        return _full();
      });
      await _pump(tester, repo);

      expect(find.text('Sin conexión con el servidor.'), findsOneWidget);
      expect(find.text('El mes'), findsNothing);

      fail = false;
      await tester.tap(find.text('Intentar nuevamente'));
      await tester.pumpAndSettle();

      expect(find.text('Sin conexión con el servidor.'), findsNothing);
      expect(find.text('El mes'), findsOneWidget);
      expect(repo.calls, greaterThanOrEqualTo(2));
    });

    testWidgets('vacío: sin movimientos y sin pendientes', (tester) async {
      await _pump(
        tester,
        _repo(
          (_) async => buildMonthSummary(
            totals: buildTotals(
              incomeCents: 0,
              expenseCents: 0,
              netFlowCents: 0,
              count: 0,
            ),
            byCategory: const [],
            byMethod: const [],
            dues: const [],
          ),
        ),
      );

      expect(find.text('Sin movimientos este mes'), findsOneWidget);
      expect(find.text('El mes'), findsNothing);
    });

    testWidgets(
      'sin movimientos pero con pendientes: SÍ muestra el resumen (no el vacío)',
      (tester) async {
        await _pump(
          tester,
          _repo(
            (_) async => buildMonthSummary(
              totals: buildTotals(
                incomeCents: 0,
                expenseCents: 0,
                netFlowCents: 0,
                count: 0,
              ),
              byCategory: const [],
              byMethod: const [],
              dues: [buildSummaryDues(balanceCents: 18000000, pendingCount: 2)],
            ),
          ),
        );

        expect(find.text('Sin movimientos este mes'), findsNothing);
        expect(find.text('Pendiente del mes'), findsOneWidget);
        expect(find.text(r'$ 180.000'), findsOneWidget);
        expect(find.text('0 movimientos'), findsOneWidget);
      },
    );

    testWidgets('pendientes en cero y sin movimientos: sigue siendo vacío', (
      tester,
    ) async {
      await _pump(
        tester,
        _repo(
          (_) async => buildMonthSummary(
            totals: buildTotals(
              incomeCents: 0,
              expenseCents: 0,
              netFlowCents: 0,
              count: 0,
            ),
            byCategory: const [],
            byMethod: const [],
            dues: [buildSummaryDues(balanceCents: 0, pendingCount: 0)],
          ),
        ),
      );
      expect(find.text('Sin movimientos este mes'), findsOneWidget);
    });
  });

  group('contenido', () {
    testWidgets('«1 movimiento» va en singular', (tester) async {
      await _pump(
        tester,
        _repo(
          (_) async => buildMonthSummary(
            totals: buildTotals(
              incomeCents: 0,
              expenseCents: 5000,
              netFlowCents: -5000,
              count: 1,
            ),
          ),
        ),
      );
      expect(find.text('1 movimiento'), findsOneWidget);
      expect(find.text('1 movimientos'), findsNothing);
    });

    testWidgets(
      'el orden en teléfono: por dónde entra, categorías, mes, pendiente, barras, gastos y medios',
      (tester) async {
        await _pump(tester, _repo((_) async => _full()));

        final tops = [
          _top(tester, 'Por dónde entra'),
          _top(tester, 'Por categoría'),
          _top(tester, 'El mes'),
          _top(tester, 'Pendiente del mes'),
          _top(tester, 'Ingresos vs gastos'),
          _top(tester, 'Tendencia de gastos'),
          _top(tester, 'Por medio de pago'),
        ];
        expect(tops, orderedEquals([...tops]..sort()));
        expect(tops.toSet(), hasLength(7));
      },
    );

    testWidgets('medios: une entró y salió y muestra el neto', (tester) async {
      await _pump(
        tester,
        _repo(
          (_) async => buildMonthSummary(
            totals: _totals,
            byMethod: [
              buildMethodTotal(
                type: MovementType.income,
                totalCents: 150000000,
              ),
              buildMethodTotal(totalCents: 42000000),
              buildMethodTotal(id: 5, name: 'Efectivo', totalCents: 1000000),
            ],
          ),
        ),
      );

      Finder inMethods(Finder f) =>
          find.descendant(of: find.byType(SummaryMethodsCard), matching: f);
      expect(
        inMethods(find.text(r'Entró $ 1.500.000 · Salió $ 420.000')),
        findsOneWidget,
      );
      expect(inMethods(find.text(r'+$ 1.080.000')), findsOneWidget);
      expect(
        inMethods(find.text(r'Entró $ 0 · Salió $ 10.000')),
        findsOneWidget,
      );
      expect(inMethods(find.text(r'-$ 10.000')), findsOneWidget);
      // Nequi (+1.080.000) va antes que Efectivo (-10.000).
      expect(
        tester.getTopLeft(inMethods(find.text('Nequi'))).dy,
        lessThan(tester.getTopLeft(inMethods(find.text('Efectivo'))).dy),
      );
    });

    testWidgets('la dona empieza en gastos y deja fuera el capital', (
      tester,
    ) async {
      await _pump(
        tester,
        _repo(
          (_) async => buildMonthSummary(
            totals: _totals,
            byCategory: [
              buildCategoryTotal(),
              buildCategoryTotal(id: 8, name: 'Préstamo', isCapital: true),
              buildCategoryTotal(
                type: MovementType.income,
                id: 9,
                name: 'Salario',
                totalCents: 150000000,
              ),
            ],
          ),
        ),
      );
      expect(find.text('Alimentación'), findsOneWidget);
      expect(find.text('Préstamo'), findsNothing);
      expect(find.text('Salario'), findsNothing, reason: 'es de ingresos');
      expect(find.text('gastado'), findsOneWidget);
    });

    testWidgets('sin categorías del tipo: «Nada este mes.» en la dona', (
      tester,
    ) async {
      await _pump(
        tester,
        _repo(
          (_) async => buildMonthSummary(totals: _totals, byCategory: const []),
        ),
      );
      expect(find.text('Nada este mes.'), findsOneWidget);
      expect(find.text('gastado'), findsNothing);
    });

    testWidgets('lo vencido se muestra solo si hay vencidos', (tester) async {
      await _pump(tester, _repo((_) async => _full()));
      // Gastos: 90.000 por pagar, 30.000 vencidos (1). Ingresos: ninguno vencido.
      expect(find.text(r'Vencido $ 30.000 (1)'), findsOneWidget);
      expect(find.textContaining('Vencido'), findsOneWidget);
    });

    testWidgets('capital: sin capital no hay tarjeta', (tester) async {
      await _pump(tester, _repo((_) async => _full()));
      expect(find.byType(SummaryCapitalCard), findsNothing);
    });

    testWidgets('capital: con capital recuperado aparece la tarjeta', (
      tester,
    ) async {
      await _pump(
        tester,
        _repo(
          (_) async => buildMonthSummary(
            totals: SummaryTotals(
              incomeTotalCents: 150000000,
              expenseTotalCents: 42000000,
              netFlowCents: 108000000,
              operatingBalanceCents: 108000000,
              capitalRecoveredCents: 5000000,
              capitalDeliveredCents: 0,
              movementCount: 12,
            ),
          ),
        ),
      );
      expect(find.byType(SummaryCapitalCard), findsOneWidget);
      expect(find.text('Recuperado'), findsOneWidget);
      expect(find.text(r'$ 50.000'), findsOneWidget);
    });

    testWidgets('balance negativo se escribe con signo menos', (tester) async {
      await _pump(
        tester,
        _repo(
          (_) async => buildMonthSummary(
            totals: buildTotals(
              incomeCents: 0,
              expenseCents: 2500000,
              netFlowCents: -2500000,
              count: 3,
            ),
          ),
        ),
      );
      expect(find.text(r'-$ 25.000'), findsOneWidget);
    });
  });

  group('distribución', () {
    testWidgets('en teléfono (390) una columna; con ancho (800) dos', (
      tester,
    ) async {
      await _pump(tester, _repo((_) async => _full()));
      expect(
        _top(tester, 'El mes'),
        lessThan(_top(tester, 'Pendiente del mes')),
        reason: 'apiladas',
      );
      expect(
        tester.getTopLeft(find.text('El mes')).dx,
        tester.getTopLeft(find.text('Pendiente del mes')).dx,
      );

      await _pump(tester, _repo((_) async => _full()), width: 800);
      expect(
        _top(tester, 'El mes'),
        _top(tester, 'Pendiente del mes'),
        reason: 'en la misma fila',
      );
      expect(
        tester.getTopLeft(find.text('El mes')).dx,
        lessThan(tester.getTopLeft(find.text('Pendiente del mes')).dx),
      );
    });
  });

  group('ocultar cifras', () {
    testWidgets('tapa todas las cifras y al destapar vuelven', (tester) async {
      final container = await _pump(tester, _repo((_) async => _full()));
      expect(find.text(r'$ 1.500.000'), findsWidgets);

      container.read(balancesHiddenProvider.notifier).toggle();
      await tester.pumpAndSettle();

      expect(find.text(_mask), findsWidgets);
      expect(find.textContaining(r'$ '), findsNothing);
      expect(find.textContaining('Entró $_mask · Salió $_mask'), findsWidgets);
      // Lo que no es dinero sigue a la vista.
      expect(find.text('12 movimientos'), findsOneWidget);
      expect(find.text('Nequi'), findsWidgets);
      expect(find.text('Vencido $_mask'), findsOneWidget);

      container.read(balancesHiddenProvider.notifier).toggle();
      await tester.pumpAndSettle();
      expect(find.text(r'$ 1.500.000'), findsWidgets);
      expect(find.text(_mask), findsNothing);
    });

    testWidgets('el balance tapado se anuncia como «Monto oculto»', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      final container = await _pump(tester, _repo((_) async => _full()));
      container.read(balancesHiddenProvider.notifier).toggle();
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel(RegExp('Monto oculto')), findsWidgets);
      semantics.dispose();
    });
  });

  group('refrescar no vacía la pantalla', () {
    testWidgets('invalidate: conserva los datos con una barra fina', (
      tester,
    ) async {
      final second = Completer<MonthSummary>();
      var call = 0;
      final container = await _pump(
        tester,
        _repo((month) {
          if (!_isSelectedMonth(month)) return Future.value(_full());
          return ++call == 1 ? Future.value(_full()) : second.future;
        }),
      );

      container.invalidate(monthSummaryProvider);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('El mes'), findsOneWidget);
      expect(_reloadBar, findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);

      second.complete(
        buildMonthSummary(
          totals: buildTotals(
            incomeCents: 777700,
            expenseCents: 0,
            netFlowCents: 777700,
            count: 1,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(_reloadBar, findsNothing);
      expect(find.text('1 movimiento'), findsOneWidget);
    });

    testWidgets('un refresco que falla conserva los datos y avisa', (
      tester,
    ) async {
      var call = 0;
      final container = await _pump(
        tester,
        _repo((month) async {
          if (!_isSelectedMonth(month) || ++call == 1) return _full();
          throw const NetworkException('Sin conexión con el servidor.');
        }),
      );

      container.invalidate(monthSummaryProvider);
      await tester.pumpAndSettle();

      expect(find.text('El mes'), findsOneWidget);
      expect(find.text('Reintentar'), findsOneWidget);
      expect(find.text('Sin conexión con el servidor.'), findsWidgets);
    });

    testWidgets(
      'un refresco que falla NO cambia las barras de la tendencia por un error '
      '(architecture.md §8: conservar lo que se ve)',
      (tester) async {
        var call = 0;
        final container = await _pump(
          tester,
          _repo((month) async {
            if (!_isSelectedMonth(month) || ++call == 1) return _full();
            throw const NetworkException('Sin conexión con el servidor.');
          }),
        );
        expect(find.byType(TrendBarsChart), findsOneWidget);

        container.invalidate(monthSummaryProvider);
        await tester.pumpAndSettle();

        expect(find.byType(TrendBarsChart), findsOneWidget);
      },
    );
  });
}
