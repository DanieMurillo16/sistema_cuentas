import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_cuentas/core/models/movement_type.dart';
import 'package:sistema_cuentas/core/theme/app_theme.dart';
import 'package:sistema_cuentas/features/auth/data/auth_repository.dart';
import 'package:sistema_cuentas/features/auth/login_screen.dart';
import 'package:sistema_cuentas/features/home/home_screen.dart';
import 'package:sistema_cuentas/features/movements/models/movement.dart';
import 'package:sistema_cuentas/features/movements/movements_list_screen.dart';
import 'package:sistema_cuentas/features/movements/widgets/movement_cancel_dialog.dart';
import 'package:sistema_cuentas/features/recurring/recurring_screen.dart';
import 'package:sistema_cuentas/features/recurring/widgets/recurring_delete_dialog.dart';
import 'package:sistema_cuentas/features/settings/settings_screen.dart';
import 'package:sistema_cuentas/features/summary/data/summary_repository.dart';
import 'package:sistema_cuentas/features/summary/summary_screen.dart';
import 'package:sistema_cuentas/shared/providers/session_provider.dart';

import '../helpers/auth_fixtures.dart';
import '../helpers/movement_fixtures.dart';
import '../helpers/recurring_fixtures.dart';
import '../helpers/summary_fixtures.dart';
import '../support/delete_recurring_scenario.dart';
import '../support/expect_screen_no_overflow.dart';
import '../support/fake_auth_repository.dart';
import '../support/fake_summary_repository.dart';
import '../support/inicio_overrides.dart';
import '../support/session_overrides.dart';

/// Muestreo de las pantallas principales EN TEMA CLARO: mismas matrices que en
/// oscuro (320/390/800/1300 × teclado × texto 1.5). Los colores no cambian los
/// tamaños, pero el tema claro arma otro `ThemeData` (bordes, sombras,
/// interruptores) y esto lo comprueba de punta a punta.
ThemeData get _light => AppTheme.light;

List<Movement> _longMovements() {
  final today = DateTime.now();
  return [
    for (var i = 1; i <= 12; i++)
      buildMovement(
        id: i,
        type: i.isEven ? MovementType.income : MovementType.expense,
        valueCents: i % 3 == 0 ? 99999999999900 : 1234500 * i,
        description: '$longDescription $i',
        category: longCatalogName,
        method: longCatalogName,
        contact: 'Contacto con un nombre bastante largo $i',
        createdAt: DateTime(today.year, today.month, today.day, 15, 45),
        date: DateTime(
          today.year,
          today.month,
          today.day,
        ).subtract(Duration(days: i % 4)),
      ),
  ];
}

List<Override> _homeOverrides() => [
  ...sessionOverrides().overrides,
  ...dataOverrides(
    items: _longMovements(),
    totals: buildTotals(
      incomeCents: 99999999999900,
      expenseCents: 99999999999900,
      netFlowCents: -99999999999900,
    ),
  ),
];

void main() {
  testWidgets('Inicio con datos largos', (tester) async {
    await expectScreenNoOverflow(
      tester,
      screen: const HomeScreen(),
      theme: _light,
      overrides: _homeOverrides,
    );
  });

  testWidgets('Inicio con el desglose por medio abierto', (tester) async {
    await expectScreenNoOverflow(
      tester,
      screen: const HomeScreen(),
      theme: _light,
      overrides: _homeOverrides,
      prepare: (tester) async {
        for (final type in ['INGRESO', 'GASTO']) {
          final toggle = find.byKey(ValueKey('balance-methods-toggle-$type'));
          if (toggle.evaluate().isNotEmpty) {
            await tester.tap(toggle);
            await tester.pumpAndSettle();
          }
        }
      },
    );
  });

  testWidgets('Lista de Gastos', (tester) async {
    await expectScreenNoOverflow(
      tester,
      screen: const MovementsListScreen(type: MovementType.expense),
      theme: _light,
      overrides: _homeOverrides,
    );
  });

  testWidgets('Resumen', (tester) async {
    await expectScreenNoOverflow(
      tester,
      screen: const Scaffold(body: SummaryScreen()),
      theme: _light,
      overrides: () => [
        sessionUserIdProvider.overrideWithValue(7),
        summaryRepositoryProvider.overrideWithValue(
          FakeSummaryRepository(
            (_) async => throw StateError('no se usa'),
            onMonth: (_) async => buildLongMonthSummary(),
          ),
        ),
      ],
    );
  });

  testWidgets('Pagos recurrentes', (tester) async {
    await expectScreenNoOverflow(
      tester,
      screen: const RecurringScreen(),
      theme: _light,
      overrides: () => DeleteRecurringScenario(
        dues: [
          for (var i = 1; i <= 6; i++)
            buildDue(
              id: i,
              recurringId: i,
              description: '$longRecurringName $i',
              contact: '$longContactName $i',
              category: longCatalogName,
              expectedCents: i.isEven ? 99999999999900 : 1234500,
            ),
        ],
        payments: [
          for (var i = 1; i <= 6; i++)
            buildRecurring(
              id: i,
              description: '$longRecurringName $i',
              contact: '$longContactName $i',
              category: longCatalogName,
              nextDueDate: DateTime(2026, 11, 7),
            ),
        ],
      ).overrides,
    );
  });

  testWidgets('Ajustes', (tester) async {
    await expectScreenNoOverflow(
      tester,
      screen: const Scaffold(body: SettingsScreen()),
      theme: _light,
      overrides: () => adminSession(fullName: longFullName).overrides,
    );
  });

  testWidgets('Inicio de sesión', (tester) async {
    await expectScreenNoOverflow(
      tester,
      screen: const LoginScreen(),
      theme: _light,
      overrides: () => [
        authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
      ],
    );
  });

  group('diálogos de eliminar (abiertos con showDialog)', () {
    testWidgets('eliminar movimiento', (tester) async {
      await expectScreenNoOverflow(
        tester,
        screen: const _MovementDialogHost(),
        theme: _light,
        overrides: () => sessionOverrides().overrides,
        prepare: (tester) async {
          await tester.tap(find.text('Abrir'));
          await tester.pumpAndSettle();
          expect(find.byType(MovementCancelDialog), findsOneWidget);
        },
      );
    });

    testWidgets('eliminar pago recurrente con un nombre larguísimo', (
      tester,
    ) async {
      await expectScreenNoOverflow(
        tester,
        screen: const _RecurringDialogHost(),
        theme: _light,
        overrides: () => sessionOverrides().overrides,
        prepare: (tester) async {
          await tester.tap(find.text('Abrir'));
          await tester.pumpAndSettle();
          expect(find.byType(RecurringDeleteDialog), findsOneWidget);
        },
      );
    });
  });
}

class _MovementDialogHost extends StatelessWidget {
  const _MovementDialogHost();

  @override
  Widget build(BuildContext context) => Scaffold(
    body: TextButton(
      onPressed: () => confirmCancelMovement(
        context,
        buildMovement(description: longDescription, valueCents: 99999999999900),
      ),
      child: const Text('Abrir'),
    ),
  );
}

class _RecurringDialogHost extends StatelessWidget {
  const _RecurringDialogHost();

  @override
  Widget build(BuildContext context) => Scaffold(
    body: TextButton(
      onPressed: () => confirmDeleteRecurring(
        context,
        recurringId: 1,
        name: longRecurringName,
        isIncome: false,
      ),
      child: const Text('Abrir'),
    ),
  );
}
