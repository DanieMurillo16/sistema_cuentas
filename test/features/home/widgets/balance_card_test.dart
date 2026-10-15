import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_cuentas/core/models/movement_type.dart';
import 'package:sistema_cuentas/core/theme/app_theme.dart';
import 'package:sistema_cuentas/core/theme/design_tokens.dart';
import 'package:sistema_cuentas/features/home/widgets/balance_card.dart';
import 'package:sistema_cuentas/features/home/widgets/balance_stat_main.dart';
import 'package:sistema_cuentas/features/home/widgets/balance_stat_tile.dart';
import 'package:sistema_cuentas/features/summary/models/summary_totals.dart';
import 'package:sistema_cuentas/shared/utils/movement_type_style.dart';
import 'package:sistema_cuentas/shared/widgets/animated_number_text.dart';

import '../../../helpers/movement_fixtures.dart';
import '../../../support/pump_at_sizes.dart';

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  double width = 390,
  double textScale = 1,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, 800);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.dark,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: child,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

SummaryTotals get _totals => buildTotals(
  incomeCents: 150000000,
  expenseCents: 42000000,
  netFlowCents: 108000000,
);

Finder _tile(MovementType type) =>
    find.byWidgetPredicate((w) => w is BalanceStatTile && w.type == type);

BoxDecoration _decorationOf(WidgetTester tester, MovementType type) {
  final box = tester.widget<DecoratedBox>(
    find.descendant(of: _tile(type), matching: find.byType(DecoratedBox)).first,
  );
  return box.decoration as BoxDecoration;
}

void main() {
  group('BalanceCard', () {
    testWidgets('balance disponible, ingresos con + y gastos con −', (
      tester,
    ) async {
      await _pump(tester, BalanceCard(totals: _totals, hidden: false));

      expect(find.text('Balance disponible'), findsOneWidget);
      expect(find.text(r'$ 1.080.000'), findsOneWidget);
      expect(find.text(r'+$ 1.500.000'), findsOneWidget);
      expect(find.text(r'-$ 420.000'), findsOneWidget);
      expect(find.text('Ingresos'), findsOneWidget);
      expect(find.text('Gastos'), findsOneWidget);
    });

    testWidgets('con las cifras tapadas, las tres van enmascaradas', (
      tester,
    ) async {
      await _pump(tester, BalanceCard(totals: _totals, hidden: true));

      expect(find.text(AnimatedNumberText.mask), findsNWidgets(3));
      expect(find.text(r'$ 1.080.000'), findsNothing);
      expect(find.text(r'+$ 1.500.000'), findsNothing);
      expect(find.text(r'-$ 420.000'), findsNothing);
    });

    testWidgets('tocar cada tarjeta avisa solo a la suya', (tester) async {
      final taps = <String>[];
      await _pump(
        tester,
        BalanceCard(
          totals: _totals,
          hidden: false,
          onIncomeTap: () => taps.add('income'),
          onExpenseTap: () => taps.add('expense'),
        ),
      );

      await tester.tap(_tile(MovementType.income));
      expect(taps, ['income']);
      await tester.tap(_tile(MovementType.expense));
      expect(taps, ['income', 'expense']);
    });

    testWidgets('las tarjetas conservan la llave para la animación de vuelo', (
      tester,
    ) async {
      const incomeKey = GlobalObjectKey('ingresos');
      const expenseKey = GlobalObjectKey('gastos');
      await _pump(
        tester,
        BalanceCard(
          totals: _totals,
          hidden: false,
          incomeKey: incomeKey,
          expenseKey: expenseKey,
        ),
      );

      expect(find.byKey(incomeKey), findsOneWidget);
      expect(find.byKey(expenseKey), findsOneWidget);
      expect(
        find.descendant(
          of: _tile(MovementType.income),
          matching: find.byKey(incomeKey),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: _tile(MovementType.expense),
          matching: find.byKey(expenseKey),
        ),
        findsOneWidget,
      );
    });

    testWidgets('importes de 12 dígitos en 320 px con texto 1.5 no desbordan', (
      tester,
    ) async {
      await _pump(
        tester,
        BalanceCard(
          totals: buildTotals(
            incomeCents: 99999999999900,
            expenseCents: 99999999999900,
            netFlowCents: -99999999999900,
          ),
          hidden: false,
          onIncomeTap: () {},
          onExpenseTap: () {},
        ),
        width: 320,
        textScale: 1.5,
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('BalanceStatTile', () {
    Future<void> pumpTile(
      WidgetTester tester, {
      MovementType type = MovementType.income,
      int cents = 150000000,
      bool hidden = false,
      VoidCallback? onTap,
    }) => _pump(
      tester,
      BalanceStatTile(type: type, cents: cents, hidden: hidden, onTap: onTap),
    );

    testWidgets('ingresos: fondo y borde translúcidos del verde, texto «+»', (
      tester,
    ) async {
      await pumpTile(tester, onTap: () {});

      final decoration = _decorationOf(tester, MovementType.income);
      expect(
        decoration.color,
        MovementType.income.fill.withValues(alpha: DesignTokens.tintFill),
      );
      expect(
        (decoration.border! as Border).top.color,
        MovementType.income.fill.withValues(alpha: DesignTokens.tintBorder),
      );
      expect(decoration.color!.a, lessThan(1), reason: 'translúcido');
      expect(find.text(r'+$ 1.500.000'), findsOneWidget);
      expect(find.byIcon(Icons.trending_up_rounded), findsOneWidget);
    });

    testWidgets('gastos: tinte rojo, el total positivo se muestra con «−»', (
      tester,
    ) async {
      await pumpTile(
        tester,
        type: MovementType.expense,
        cents: 42000000,
        onTap: () {},
      );

      expect(
        _decorationOf(tester, MovementType.expense).color,
        MovementType.expense.fill.withValues(alpha: DesignTokens.tintFill),
      );
      expect(find.text(r'-$ 420.000'), findsOneWidget);
      expect(find.byIcon(Icons.trending_down_rounded), findsOneWidget);
    });

    testWidgets('los tintes de ingresos y gastos son distintos', (
      tester,
    ) async {
      expect(MovementType.income.fill, isNot(MovementType.expense.fill));
    });

    testWidgets('con onTap muestra la flecha › y se puede tocar', (
      tester,
    ) async {
      var taps = 0;
      await pumpTile(tester, onTap: () => taps++);

      expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);
      await tester.tap(find.byType(BalanceStatTile));
      expect(taps, 1);
    });

    testWidgets('sin onTap no hay flecha ni acción de tocar', (tester) async {
      await pumpTile(tester);
      final handle = tester.ensureSemantics();

      expect(find.byIcon(Icons.chevron_right_rounded), findsNothing);
      final node = tester.getSemantics(find.byType(BalanceStatMain));
      expect(node.flagsCollection.isButton, isFalse);
      expect(node.hint, isEmpty);
      handle.dispose();
    });

    testWidgets('semántica: «Ingresos, monto» y pista del destino', (
      tester,
    ) async {
      await pumpTile(tester, onTap: () {});
      final handle = tester.ensureSemantics();

      final node = tester.getSemantics(find.byType(BalanceStatMain));
      expect(node.label, r'Ingresos, +$ 1.500.000');
      expect(node.hint, 'Abre la lista de ingresos');
      expect(node.flagsCollection.isButton, isTrue);
      handle.dispose();
    });

    testWidgets('semántica tapada: no dice el monto', (tester) async {
      await pumpTile(
        tester,
        type: MovementType.expense,
        hidden: true,
        onTap: () {},
      );
      final handle = tester.ensureSemantics();

      final node = tester.getSemantics(find.byType(BalanceStatMain));
      expect(node.label, 'Gastos, monto oculto');
      expect(node.hint, 'Abre la lista de gastos');
      expect(find.text(AnimatedNumberText.mask), findsOneWidget);
      handle.dispose();
    });

    testWidgets('en 320 px con texto 1.5 y 12 dígitos no desborda', (
      tester,
    ) async {
      await _pump(
        tester,
        Row(
          children: [
            Expanded(
              child: BalanceStatTile(
                type: MovementType.income,
                cents: 99999999999900,
                hidden: false,
                onTap: () {},
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: BalanceStatTile(
                type: MovementType.expense,
                cents: 99999999999900,
                hidden: false,
                onTap: () {},
              ),
            ),
          ],
        ),
        width: 320,
        textScale: 1.5,
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('desbordes (320/390/800/1300 × teclado × texto 1.5)', () {
    Widget view({required SummaryTotals totals, bool hidden = false}) =>
        Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: BalanceCard(
              totals: totals,
              hidden: hidden,
              onIncomeTap: () {},
              onExpenseTap: () {},
            ),
          ),
        );

    testWidgets('importes de 12 dígitos', (tester) async {
      await expectNoOverflow(
        tester,
        view(
          totals: buildTotals(
            incomeCents: 99999999999900,
            expenseCents: 99999999999900,
            netFlowCents: -99999999999900,
          ),
        ),
      );
    });

    testWidgets('importes de 12 dígitos tapados', (tester) async {
      await expectNoOverflow(
        tester,
        view(
          hidden: true,
          totals: buildTotals(
            incomeCents: 99999999999900,
            expenseCents: 99999999999900,
            netFlowCents: 99999999999900,
          ),
        ),
      );
    });

    testWidgets('importes normales y en cero', (tester) async {
      await expectNoOverflow(tester, view(totals: _totals));
      await expectNoOverflow(
        tester,
        view(
          totals: buildTotals(
            incomeCents: 0,
            expenseCents: 0,
            netFlowCents: 0,
            count: 0,
          ),
        ),
      );
    });
  });
}
