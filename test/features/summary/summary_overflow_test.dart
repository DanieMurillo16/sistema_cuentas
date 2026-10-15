import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_cuentas/core/errors/app_exception.dart';
import 'package:sistema_cuentas/features/summary/data/summary_repository.dart';
import 'package:sistema_cuentas/features/summary/models/month_summary.dart';
import 'package:sistema_cuentas/features/summary/summary_screen.dart';
import 'package:sistema_cuentas/shared/providers/balances_hidden_provider.dart';
import 'package:sistema_cuentas/shared/providers/session_provider.dart';

import '../../helpers/movement_fixtures.dart';
import '../../helpers/summary_fixtures.dart';
import '../../support/expect_screen_no_overflow.dart';
import '../../support/fake_summary_repository.dart';

class _HiddenFigures extends BalancesHiddenNotifier {
  @override
  bool build() => true;
}

const _screen = Scaffold(body: SummaryScreen());

List<Override> _base(FakeSummaryRepository repo) => [
  sessionUserIdProvider.overrideWithValue(7),
  summaryRepositoryProvider.overrideWithValue(repo),
];

FakeSummaryRepository _repo(Future<MonthSummary> Function(DateTime) onMonth) =>
    FakeSummaryRepository(
      (_) async => throw StateError('no se usa'),
      onMonth: onMonth,
    );

void main() {
  testWidgets(
    'con nombres de 40+ caracteres, cifras de 12 dígitos, vencidos y capital '
    'no desborda en 320/390/800/1300 × teclado × texto 1.5',
    (tester) async {
      expect(longCatalogName.length, greaterThan(40));
      final repo = _repo((_) async => buildLongMonthSummary());
      await expectScreenNoOverflow(
        tester,
        screen: _screen,
        overrides: () => _base(repo),
      );
      expect(find.text('Capital'), findsOneWidget);
    },
  );

  testWidgets('con las cifras tapadas', (tester) async {
    final repo = _repo((_) async => buildLongMonthSummary());
    await expectScreenNoOverflow(
      tester,
      screen: _screen,
      overrides: () => [
        ..._base(repo),
        balancesHiddenProvider.overrideWith(_HiddenFigures.new),
      ],
    );
  });

  testWidgets('con un resumen típico', (tester) async {
    final repo = _repo((_) async => buildMonthSummary());
    await expectScreenNoOverflow(
      tester,
      screen: _screen,
      overrides: () => _base(repo),
    );
  });

  testWidgets('vacío', (tester) async {
    final repo = _repo(
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
    );
    await expectScreenNoOverflow(
      tester,
      screen: _screen,
      overrides: () => _base(repo),
    );
  });

  testWidgets('error con un mensaje largo', (tester) async {
    final repo = _repo(
      (_) async => throw NetworkException('Sin conexión con el servidor. ' * 6),
    );
    await expectScreenNoOverflow(
      tester,
      screen: _screen,
      overrides: () => _base(repo),
    );
  });

  testWidgets('cargando', (tester) async {
    final never = Completer<MonthSummary>();
    final repo = _repo((_) => never.future);
    await expectScreenNoOverflow(
      tester,
      screen: _screen,
      settle: false,
      overrides: () => _base(repo),
    );
  });
}
