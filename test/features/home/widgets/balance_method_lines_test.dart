import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_cuentas/core/models/movement_type.dart';
import 'package:sistema_cuentas/core/theme/app_theme.dart';
import 'package:sistema_cuentas/core/theme/design_tokens.dart';
import 'package:sistema_cuentas/features/home/widgets/balance_card.dart';
import 'package:sistema_cuentas/features/home/widgets/balance_method_lines.dart';
import 'package:sistema_cuentas/features/home/widgets/balance_methods_toggle.dart';
import 'package:sistema_cuentas/features/home/widgets/balance_stat_main.dart';
import 'package:sistema_cuentas/features/home/widgets/balance_stat_tile.dart';
import 'package:sistema_cuentas/features/home/widgets/balance_stats_row.dart';
import 'package:sistema_cuentas/features/summary/models/method_total.dart';
import 'package:sistema_cuentas/shared/widgets/animated_number_text.dart';

import '../../../helpers/movement_fixtures.dart';
import '../../../helpers/summary_fixtures.dart';
import '../../../support/pump_at_sizes.dart';

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  double width = 390,
  double textScale = 1,
  bool noMotion = false,
  bool settle = true,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, 800);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.dark,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(textScale),
          disableAnimations: noMotion,
        ),
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
  if (settle) await tester.pumpAndSettle();
}

MethodTotal _income(int id, String name, int cents) => buildMethodTotal(
  type: MovementType.income,
  id: id,
  name: name,
  totalCents: cents,
);

MethodTotal _expense(int id, String name, int cents) =>
    buildMethodTotal(id: id, name: name, totalCents: cents);

Finder _line(MovementType type, int methodId) =>
    find.byKey(ValueKey('balance-method-${type.apiValue}-$methodId'));

Finder _tile(MovementType type) =>
    find.byWidgetPredicate((w) => w is BalanceStatTile && w.type == type);

Finder _in(Finder scope, Finder matching) =>
    find.descendant(of: scope, matching: matching);

Finder _toggle(MovementType type) =>
    find.byKey(ValueKey('balance-methods-toggle-${type.apiValue}'));

/// Alterna el despegable de UNA tarjeta (cada una tiene el suyo).
Future<void> _tapToggle(WidgetTester tester, MovementType type) async {
  await tester.tap(_toggle(type));
  await tester.pumpAndSettle();
}

/// Abre el despegable de las tarjetas que lo tengan (ingresos y gastos).
Future<void> _open(WidgetTester tester) async {
  for (final type in MovementType.values) {
    if (_toggle(type).evaluate().isNotEmpty) await _tapToggle(tester, type);
  }
}

bool _expanded(WidgetTester tester, MovementType type) => tester
    .widget<BalanceMethodsToggle>(
      find.ancestor(
        of: _toggle(type),
        matching: find.byType(BalanceMethodsToggle),
      ),
    )
    .expanded;

/// Seis medios para llenar la tarjeta.
List<MethodTotal> get _sixMethods => [
  for (var i = 1; i <= 6; i++) ...[
    _income(i, '$longCatalogName $i', 99999999999900 - i),
    _expense(i, '$longCatalogName $i', 99999999999900 - i),
  ],
];

void main() {
  group('BalanceMethodLines', () {
    testWidgets('una línea por medio con su nombre y su total', (tester) async {
      await _pump(
        tester,
        BalanceMethodLines(
          hidden: false,
          methods: [
            _income(1, 'nequi', 1500000),
            _income(2, 'Efectivo', 25000),
          ],
        ),
      );

      expect(_line(MovementType.income, 1), findsOneWidget);
      expect(_line(MovementType.income, 2), findsOneWidget);
      // Nombre con inicial mayúscula (formateador compartido), total en pesos.
      expect(find.text('Nequi'), findsOneWidget);
      expect(find.text(r'$ 15.000'), findsOneWidget);
      expect(find.text('Efectivo'), findsOneWidget);
      expect(find.text(r'$ 250'), findsOneWidget);
    });

    testWidgets('el orden recibido se respeta (la regla ya ordenó)', (
      tester,
    ) async {
      await _pump(
        tester,
        BalanceMethodLines(
          hidden: false,
          methods: [_income(9, 'Zeta', 900), _income(1, 'Alfa', 100)],
        ),
      );

      expect(
        tester.getTopLeft(_line(MovementType.income, 9)).dy,
        lessThan(tester.getTopLeft(_line(MovementType.income, 1)).dy),
      );
    });

    testWidgets('con el ojo cerrado cada total va enmascarado', (tester) async {
      await _pump(
        tester,
        BalanceMethodLines(
          hidden: true,
          methods: [
            _income(1, 'Nequi', 1500000),
            _income(2, 'Efectivo', 25000),
          ],
        ),
      );

      expect(find.text(AnimatedNumberText.mask), findsNWidgets(2));
      expect(find.text(r'$ 15.000'), findsNothing);
      expect(find.text(r'$ 250'), findsNothing);
      // Los nombres de los medios no son cifras: siguen visibles.
      expect(find.text('Nequi'), findsOneWidget);
    });

    testWidgets('sin medios no pinta nada', (tester) async {
      await _pump(tester, const BalanceMethodLines(hidden: false, methods: []));

      expect(find.byType(Text), findsNothing);
      expect(find.byType(Padding), findsWidgets); // solo los del Scaffold
      expect(tester.getSize(find.byType(BalanceMethodLines)).height, 0);
    });
  });

  group('BalanceStatTile con medios', () {
    testWidgets('muestra las líneas de sus medios bajo el total', (
      tester,
    ) async {
      await _pump(
        tester,
        BalanceStatTile(
          type: MovementType.income,
          cents: 150000000,
          hidden: false,
          methodsExpanded: true,
          onToggleMethods: () {},
          methods: [
            _income(2, 'Nequi', 100000000),
            _income(5, 'Bancolombia', 50000000),
          ],
        ),
      );

      expect(find.byType(BalanceMethodLines), findsOneWidget);
      expect(find.text('Nequi'), findsOneWidget);
      expect(find.text('Bancolombia'), findsOneWidget);
      final total = tester.getTopLeft(find.text(r'+$ 1.500.000')).dy;
      expect(tester.getTopLeft(find.text('Nequi')).dy, greaterThan(total));
    });

    testWidgets('sin medios no aparece BalanceMethodLines', (tester) async {
      await _pump(
        tester,
        const BalanceStatTile(
          type: MovementType.expense,
          cents: 42000000,
          hidden: false,
        ),
      );

      expect(find.byType(BalanceMethodLines), findsNothing);
      expect(find.text(r'-$ 420.000'), findsOneWidget);
    });

    testWidgets('con el ojo cerrado: total y medios enmascarados', (
      tester,
    ) async {
      await _pump(
        tester,
        BalanceStatTile(
          type: MovementType.expense,
          cents: 42000000,
          hidden: true,
          methodsExpanded: true,
          onToggleMethods: () {},
          methods: [
            _expense(2, 'Nequi', 30000000),
            _expense(5, 'Efectivo', 12000000),
          ],
        ),
      );

      expect(find.text(AnimatedNumberText.mask), findsNWidgets(3));
      expect(find.text(r'$ 300.000'), findsNothing);
      expect(find.text(r'$ 120.000'), findsNothing);
    });

    testWidgets('la semántica del tile no incluye el desglose (visible)', (
      tester,
    ) async {
      await _pump(
        tester,
        BalanceStatTile(
          type: MovementType.expense,
          cents: 42000000,
          hidden: false,
          onTap: () {},
          methodsExpanded: true,
          onToggleMethods: () {},
          methods: [_expense(2, 'Nequi', 42000000)],
        ),
      );
      final handle = tester.ensureSemantics();

      final node = tester.getSemantics(find.byType(BalanceStatMain));
      expect(node.label, r'Gastos, -$ 420.000');
      expect(node.flagsCollection.isButton, isTrue);
      handle.dispose();
    });

    testWidgets('con el ojo cerrado la semántica no filtra cifras', (
      tester,
    ) async {
      await _pump(
        tester,
        BalanceStatTile(
          type: MovementType.expense,
          cents: 42000000,
          hidden: true,
          methodsExpanded: true,
          onToggleMethods: () {},
          methods: [_expense(2, 'Nequi', 42000000)],
        ),
      );
      final handle = tester.ensureSemantics();

      expect(
        tester.getSemantics(find.byType(BalanceStatMain)).label,
        'Gastos, monto oculto',
      );
      expect(find.bySemanticsLabel(RegExp(r'\$')), findsNothing);
      handle.dispose();
    });

    testWidgets(
      'cerrado por defecto: el toggle está y las líneas no se montan',
      (tester) async {
        await _pump(
          tester,
          BalanceStatTile(
            type: MovementType.income,
            cents: 100,
            hidden: false,
            onToggleMethods: () {},
            methods: [_income(2, 'Nequi', 100)],
          ),
        );

        expect(find.byType(BalanceMethodsToggle), findsOneWidget);
        expect(find.text('Detalle'), findsOneWidget);
        expect(find.byType(BalanceMethodLines), findsNothing);
        expect(find.text('Nequi'), findsNothing);
      },
    );

    testWidgets('sin onToggleMethods no hay toggle ni líneas', (tester) async {
      await _pump(
        tester,
        BalanceStatTile(
          type: MovementType.income,
          cents: 100,
          hidden: false,
          methodsExpanded: true,
          methods: [_income(2, 'Nequi', 100)],
        ),
      );

      expect(find.byType(BalanceMethodsToggle), findsNothing);
      expect(find.byType(BalanceMethodLines), findsNothing);
    });

    testWidgets(
      'el toggle llama a onToggleMethods y no a onTap de la tarjeta',
      (tester) async {
        var toggled = 0;
        var tapped = 0;
        await _pump(
          tester,
          BalanceStatTile(
            type: MovementType.income,
            cents: 100,
            hidden: false,
            onTap: () => tapped++,
            onToggleMethods: () => toggled++,
            methods: [_income(2, 'Nequi', 100)],
          ),
        );

        await tester.tap(_toggle(MovementType.income));
        await tester.pump();

        expect(toggled, 1);
        expect(tapped, 0);
      },
    );
  });

  group('BalanceMethodsToggle', () {
    Future<void> pumpToggle(
      WidgetTester tester, {
      required bool expanded,
      MovementType type = MovementType.expense,
      VoidCallback? onTap,
      double textScale = 1,
      bool settle = true,
    }) => _pump(
      tester,
      BalanceMethodsToggle(
        type: type,
        expanded: expanded,
        onTap: onTap ?? () {},
      ),
      textScale: textScale,
      settle: settle,
    );

    testWidgets('semántica cerrado: botón, no expandido, «Ver gastos…»', (
      tester,
    ) async {
      await pumpToggle(tester, expanded: false);
      final handle = tester.ensureSemantics();

      final node = tester.getSemantics(find.byType(BalanceMethodsToggle));
      expect(node.label, 'Ver gastos por medio de pago');
      expect(node.flagsCollection.isButton, isTrue);
      expect(node.flagsCollection.isExpanded, Tristate.isFalse);
      handle.dispose();
    });

    testWidgets('semántica abierto: expandido, «Ocultar ingresos…»', (
      tester,
    ) async {
      await pumpToggle(tester, expanded: true, type: MovementType.income);
      final handle = tester.ensureSemantics();

      final node = tester.getSemantics(find.byType(BalanceMethodsToggle));
      expect(node.label, 'Ocultar ingresos por medio de pago');
      expect(node.flagsCollection.isExpanded, Tristate.isTrue);
      handle.dispose();
    });

    testWidgets('el chevron gira media vuelta al abrir', (tester) async {
      await pumpToggle(tester, expanded: false);
      expect(
        tester.widget<AnimatedRotation>(find.byType(AnimatedRotation)).turns,
        0,
      );

      await pumpToggle(tester, expanded: true);
      expect(
        tester.widget<AnimatedRotation>(find.byType(AnimatedRotation)).turns,
        0.5,
      );
    });

    testWidgets('el chevron anima el giro (no salta)', (tester) async {
      await pumpToggle(tester, expanded: false);
      await pumpToggle(tester, expanded: true, settle: false);
      await tester.pump(const Duration(milliseconds: 60));
      final rotation = tester.widget<RotationTransition>(
        find.descendant(
          of: find.byType(AnimatedRotation),
          matching: find.byType(RotationTransition),
        ),
      );
      expect(rotation.turns.value, inExclusiveRange(0, 0.5));

      await tester.pumpAndSettle();
      expect(rotation.turns.value, 0.5);
    });

    testWidgets('área táctil de al menos 40 px, también con texto 1.5', (
      tester,
    ) async {
      for (final scale in [1.0, 1.5]) {
        await pumpToggle(tester, expanded: false, textScale: scale);
        expect(
          tester.getSize(_toggle(MovementType.expense)).height,
          greaterThanOrEqualTo(DesignTokens.compactTapTarget),
        );
      }
    });

    testWidgets('tocar llama a onTap', (tester) async {
      var taps = 0;
      await pumpToggle(tester, expanded: false, onTap: () => taps++);

      await tester.tap(find.byType(BalanceMethodsToggle));
      expect(taps, 1);
    });
  });

  group('BalanceStatsRow con medios', () {
    final methods = [
      _income(2, 'Nequi', 100000000),
      _income(5, 'Bancolombia', 50000000),
      _expense(2, 'Nequi', 30000000),
      _expense(7, 'Efectivo', 0), // total 0: no sale
    ];

    Widget row({
      bool hidden = false,
      List<MethodTotal>? withMethods,
      VoidCallback? onIncomeTap,
    }) => BalanceStatsRow(
      totals: buildTotals(),
      hidden: hidden,
      methods: withMethods ?? methods,
      onIncomeTap: onIncomeTap,
    );

    testWidgets('cerrado al empezar: dos toggles «Detalle» y ninguna línea', (
      tester,
    ) async {
      await _pump(tester, row());

      expect(_toggle(MovementType.income), findsOneWidget);
      expect(_toggle(MovementType.expense), findsOneWidget);
      expect(find.text('Detalle'), findsNWidgets(2));
      expect(find.byType(BalanceMethodLines), findsNothing);
      expect(find.text('Nequi'), findsNothing);
    });

    testWidgets('se abre al tocar el toggle y se cierra al volver a tocarlo', (
      tester,
    ) async {
      await _pump(tester, row());

      await _tapToggle(tester, MovementType.income);
      expect(_expanded(tester, MovementType.income), isTrue);
      expect(
        _in(_tile(MovementType.income), find.text('Bancolombia')),
        findsOneWidget,
      );

      await _tapToggle(tester, MovementType.income);
      expect(_expanded(tester, MovementType.income), isFalse);
      expect(find.byType(BalanceMethodLines), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('abrir con animación no lanza excepciones y termina abierto', (
      tester,
    ) async {
      await _pump(tester, row());

      await tester.tap(_toggle(MovementType.income));
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.takeException(), isNull);
      await tester.pumpAndSettle();

      expect(find.text('Bancolombia'), findsOneWidget);
    });

    testWidgets('cerrar con animación no lanza excepciones', (tester) async {
      await _pump(tester, row());
      await _open(tester);

      await tester.tap(_toggle(MovementType.income));
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.takeException(), isNull);
      await tester.pumpAndSettle();

      expect(find.text('Bancolombia'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('con «reducir movimiento» abre y cierra de inmediato', (
      tester,
    ) async {
      await _pump(tester, row(), noMotion: true);

      await tester.tap(_toggle(MovementType.income));
      await tester.pump();
      expect(find.text('Bancolombia'), findsOneWidget);

      await tester.tap(_toggle(MovementType.income));
      await tester.pump();
      expect(find.text('Bancolombia'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    group('cada tarjeta tiene su despegable', () {
      testWidgets('abrir Gastos deja Ingresos cerrado', (tester) async {
        await _pump(tester, row());

        await _tapToggle(tester, MovementType.expense);

        expect(_expanded(tester, MovementType.expense), isTrue);
        expect(_expanded(tester, MovementType.income), isFalse);
        expect(
          _in(_tile(MovementType.expense), find.text('Nequi')),
          findsOneWidget,
        );
        expect(
          _in(_tile(MovementType.income), find.byType(BalanceMethodLines)),
          findsNothing,
        );
      });

      testWidgets('abrir Ingresos deja Gastos cerrado', (tester) async {
        await _pump(tester, row());

        await _tapToggle(tester, MovementType.income);

        expect(_expanded(tester, MovementType.income), isTrue);
        expect(_expanded(tester, MovementType.expense), isFalse);
        expect(
          _in(_tile(MovementType.expense), find.byType(BalanceMethodLines)),
          findsNothing,
        );
      });

      testWidgets('se pueden abrir los dos', (tester) async {
        await _pump(tester, row());

        await _tapToggle(tester, MovementType.income);
        await _tapToggle(tester, MovementType.expense);

        expect(_expanded(tester, MovementType.income), isTrue);
        expect(_expanded(tester, MovementType.expense), isTrue);
        expect(find.byType(BalanceMethodLines), findsNWidgets(2));
      });

      testWidgets('cerrar uno deja el otro abierto', (tester) async {
        await _pump(tester, row());
        await _open(tester);

        await _tapToggle(tester, MovementType.income);

        expect(_expanded(tester, MovementType.income), isFalse);
        expect(_expanded(tester, MovementType.expense), isTrue);
        expect(find.byType(BalanceMethodLines), findsOneWidget);
        expect(
          _in(_tile(MovementType.expense), find.text('Nequi')),
          findsOneWidget,
        );
        expect(find.text('Bancolombia'), findsNothing);
        expect(tester.takeException(), isNull);
      });

      testWidgets('el estado de uno sobrevive a que el otro cambie', (
        tester,
      ) async {
        await _pump(tester, row());

        await _tapToggle(tester, MovementType.expense);
        await _tapToggle(tester, MovementType.income);
        await _tapToggle(tester, MovementType.income);

        expect(_expanded(tester, MovementType.expense), isTrue);
        expect(_expanded(tester, MovementType.income), isFalse);
      });

      testWidgets('con uno abierto, la altura de cada tarjeta es la suya', (
        tester,
      ) async {
        await _pump(
          tester,
          row(
            withMethods: [
              _income(1, 'Nequi', 100),
              _income(2, 'Bancolombia', 90),
              _income(3, 'Efectivo', 80),
              _income(4, 'Daviplata', 70),
              _expense(1, 'Nequi', 100),
            ],
          ),
        );
        final closedIncome = tester.getSize(_tile(MovementType.income)).height;
        final closedExpense = tester
            .getSize(_tile(MovementType.expense))
            .height;

        await _tapToggle(tester, MovementType.income);

        final income = tester.getSize(_tile(MovementType.income)).height;
        final expense = tester.getSize(_tile(MovementType.expense)).height;
        expect(income, greaterThan(closedIncome + 60), reason: '4 líneas');
        expect(expense, closedExpense, reason: 'Gastos no se estira ni cambia');
        // Alineadas arriba.
        expect(
          tester.getTopLeft(_tile(MovementType.income)).dy,
          tester.getTopLeft(_tile(MovementType.expense)).dy,
        );
      });

      testWidgets('abiertas las dos con distinto número de medios, miden '
          'distinto', (tester) async {
        await _pump(
          tester,
          row(
            withMethods: [
              for (var i = 1; i <= 4; i++) _income(i, 'Medio $i', 100),
              _expense(1, 'Nequi', 100),
            ],
          ),
        );

        await _open(tester);

        expect(
          tester.getSize(_tile(MovementType.income)).height,
          greaterThan(tester.getSize(_tile(MovementType.expense)).height + 30),
        );
      });
    });

    testWidgets('tocar el toggle no abre la lista de movimientos', (
      tester,
    ) async {
      var taps = 0;
      await _pump(tester, row(onIncomeTap: () => taps++));

      await _open(tester);
      expect(taps, 0);

      await tester.tap(find.text('Ingresos'));
      expect(taps, 1);
    });

    testWidgets('reparte cada medio a su tarjeta según el tipo', (
      tester,
    ) async {
      await _pump(tester, row());
      await _open(tester);

      expect(
        _in(_tile(MovementType.income), find.text('Nequi')),
        findsOneWidget,
      );
      expect(
        _in(_tile(MovementType.income), find.text('Bancolombia')),
        findsOneWidget,
      );
      expect(
        _in(_tile(MovementType.expense), find.text('Nequi')),
        findsOneWidget,
      );
      expect(
        _in(_tile(MovementType.expense), find.text('Bancolombia')),
        findsNothing,
      );
    });

    testWidgets('nombre e importe de un medio van en la misma línea', (
      tester,
    ) async {
      await _pump(tester, row(), width: 800);
      await _open(tester);

      final line = _line(MovementType.income, 2);
      final name = _in(line, find.text('Nequi'));
      final amount = _in(line, find.text(r'$ 1.000.000'));
      expect(
        tester.getTopLeft(name).dy,
        tester.getTopLeft(amount).dy,
        reason: 'misma fila',
      );
      expect(
        tester.getTopLeft(name).dx,
        lessThan(tester.getTopLeft(amount).dx),
      );
      // spaceBetween: el importe queda pegado al borde derecho de la línea.
      expect(
        tester.getTopRight(amount).dx,
        closeTo(tester.getTopRight(line).dx, 0.5),
      );
    });

    testWidgets('un medio con total 0 no aparece', (tester) async {
      await _pump(tester, row());
      await _open(tester);

      expect(find.text('Efectivo'), findsNothing);
      expect(_line(MovementType.expense, 7), findsNothing);
    });

    testWidgets('dentro de cada tarjeta van de mayor a menor', (tester) async {
      await _pump(
        tester,
        row(
          withMethods: [
            _income(5, 'Bancolombia', 50000000),
            _income(2, 'Nequi', 100000000),
          ],
        ),
      );
      await _open(tester);

      expect(
        tester.getTopLeft(_line(MovementType.income, 2)).dy,
        lessThan(tester.getTopLeft(_line(MovementType.income, 5)).dy),
      );
    });

    testWidgets('sin medios: ni toggles ni líneas', (tester) async {
      await _pump(tester, row(withMethods: const []));

      expect(find.byType(BalanceMethodsToggle), findsNothing);
      expect(find.byType(BalanceMethodLines), findsNothing);
    });

    testWidgets(
      'medios solo de ingresos: gastos no tiene toggle y el estado abre ingresos',
      (tester) async {
        await _pump(tester, row(withMethods: [_income(2, 'Nequi', 100)]));

        expect(_toggle(MovementType.income), findsOneWidget);
        expect(_toggle(MovementType.expense), findsNothing);

        await _open(tester);

        expect(find.byType(BalanceMethodLines), findsOneWidget);
        expect(
          _in(_tile(MovementType.expense), find.byType(BalanceMethodLines)),
          findsNothing,
        );
      },
    );

    testWidgets(
      'cerrado con el ojo cerrado: dos totales enmascarados, sin medios',
      (tester) async {
        await _pump(tester, row(hidden: true));

        expect(find.text(AnimatedNumberText.mask), findsNWidgets(2));
      },
    );

    testWidgets('al ocultar, cada tarjeta enmascara su total y sus medios', (
      tester,
    ) async {
      await _pump(tester, row(hidden: true));
      await _open(tester);

      // 2 totales + 2 medios de ingresos + 1 de gastos.
      expect(find.text(AnimatedNumberText.mask), findsNWidgets(5));
      expect(find.textContaining(r'$'), findsNothing);
    });
  });

  group('BalanceCard con medios', () {
    testWidgets('cerrado al empezar y el balance, los totales conviven', (
      tester,
    ) async {
      await _pump(
        tester,
        BalanceCard(
          totals: buildTotals(
            incomeCents: 150000000,
            expenseCents: 42000000,
            netFlowCents: 108000000,
          ),
          hidden: false,
          methods: [
            _income(2, 'Nequi', 150000000),
            _expense(5, 'Bancolombia', 42000000),
          ],
        ),
      );

      expect(find.text(r'$ 1.080.000'), findsOneWidget);
      expect(find.byType(BalanceMethodLines), findsNothing);

      await _open(tester);

      expect(
        _in(_tile(MovementType.income), find.text('Nequi')),
        findsOneWidget,
      );
      expect(
        _in(_tile(MovementType.expense), find.text('Bancolombia')),
        findsOneWidget,
      );
      expect(find.text(r'$ 1.080.000'), findsOneWidget);
    });

    testWidgets(
      'con el ojo cerrado: 3 cifras cerrado, 5 con el desglose abierto',
      (tester) async {
        await _pump(
          tester,
          BalanceCard(
            totals: buildTotals(),
            hidden: true,
            methods: [
              _income(2, 'Nequi', 150000000),
              _expense(5, 'Efectivo', 100),
            ],
          ),
        );
        expect(find.text(AnimatedNumberText.mask), findsNWidgets(3));

        await _open(tester);

        expect(find.text(AnimatedNumberText.mask), findsNWidgets(5));
        expect(find.textContaining(r'$'), findsNothing);
      },
    );
  });

  group('desbordes con medios (320/390/800/1300 × teclado × texto 1.5)', () {
    Widget view({required List<MethodTotal> methods, bool hidden = false}) =>
        Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: BalanceCard(
              totals: buildTotals(
                incomeCents: 99999999999900,
                expenseCents: 99999999999900,
                netFlowCents: -99999999999900,
              ),
              hidden: hidden,
              methods: methods,
              onIncomeTap: () {},
              onExpenseTap: () {},
            ),
          ),
        );

    Future<void> openIncome(WidgetTester tester) =>
        _tapToggle(tester, MovementType.income);
    Future<void> openExpense(WidgetTester tester) =>
        _tapToggle(tester, MovementType.expense);

    /// Qué despegables se abren antes de comprobar que no hubo excepciones.
    final states = <String, Future<void> Function(WidgetTester)?>{
      'cerrados': null,
      'solo Ingresos abierto': openIncome,
      'solo Gastos abierto': openExpense,
      'ambos abiertos': _open,
    };

    for (final entry in states.entries) {
      final state = entry.key;
      final prepare = entry.value;

      testWidgets(
        '$state: 6 medios con nombres de 40+ caracteres y cifras de 12 dígitos',
        (tester) async {
          await expectNoOverflow(
            tester,
            view(methods: _sixMethods),
            afterPump: prepare,
            freshStateEachTime: true,
          );
        },
      );

      testWidgets('$state: los mismos 6 medios con el ojo cerrado', (
        tester,
      ) async {
        await expectNoOverflow(
          tester,
          view(methods: _sixMethods, hidden: true),
          afterPump: prepare,
          freshStateEachTime: true,
        );
      });

      for (final hidden in [false, true]) {
        testWidgets(
          '$state: BalanceStatsRow suelta, nombres largos e importes de 8 '
          'dígitos, ojo ${hidden ? 'cerrado' : 'abierto'}',
          (tester) async {
            await expectNoOverflow(
              tester,
              Scaffold(
                body: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: BalanceStatsRow(
                    totals: buildTotals(
                      incomeCents: 9999999900,
                      expenseCents: 9999999900,
                    ),
                    hidden: hidden,
                    methods: [
                      for (var i = 1; i <= 6; i++) ...[
                        _income(i, '$longCatalogName $i', 9999999900 - i),
                        _expense(i, '$longCatalogName $i', 9999999900 - i),
                      ],
                    ],
                    onIncomeTap: () {},
                    onExpenseTap: () {},
                  ),
                ),
              ),
              widths: const [320],
              scales: const [1.5],
              afterPump: prepare,
              freshStateEachTime: true,
            );
          },
        );
      }

      testWidgets('$state: solo un lado con medios (alturas distintas)', (
        tester,
      ) async {
        await expectNoOverflow(
          tester,
          view(
            methods: [
              for (var i = 1; i <= 6; i++)
                _income(i, '$longCatalogName $i', 5000),
            ],
          ),
          afterPump: prepare == openExpense ? openIncome : prepare,
          freshStateEachTime: true,
        );
      });
    }

    testWidgets('sin medios', (tester) async {
      await expectNoOverflow(tester, view(methods: const []));
    });

    testWidgets('abrir y cerrar cada despegable CON animación, fotograma a '
        'fotograma, en todos los tamaños', (tester) async {
      await expectNoOverflow(
        tester,
        view(methods: _sixMethods),
        freshStateEachTime: true,
        afterPump: (tester) async {
          for (final type in [
            MovementType.income, // abre ingresos
            MovementType.expense, // abre gastos
            MovementType.income, // cierra ingresos
            MovementType.expense, // cierra gastos
          ]) {
            await tester.tap(_toggle(type));
            for (var i = 0; i < 4; i++) {
              await tester.pump(const Duration(milliseconds: 70));
              expect(tester.takeException(), isNull, reason: 'abriendo $type');
            }
            await tester.pumpAndSettle();
          }
        },
      );
    });

    for (final both in [false, true]) {
      testWidgets(
        'tapar y destapar el ojo con ${both ? 'ambos' : 'Ingresos'} abierto'
        '${both ? 's' : ''} no desborda',
        (tester) async {
          await expectNoOverflow(
            tester,
            _HiddenHost(methods: _sixMethods),
            freshStateEachTime: true,
            afterPump: (tester) async {
              await (both ? _open(tester) : openIncome(tester));
              for (var i = 0; i < 2; i++) {
                await tester.tap(find.byKey(_HiddenHost.eyeKey));
                for (var f = 0; f < 4; f++) {
                  await tester.pump(const Duration(milliseconds: 70));
                  expect(tester.takeException(), isNull, reason: 'ojo $i');
                }
                await tester.pumpAndSettle();
              }
            },
          );
        },
      );
    }

    testWidgets('un refresco con menos medios, con el despegable abierto, no '
        'desborda', (tester) async {
      await expectNoOverflow(
        tester,
        _RefreshHost(),
        freshStateEachTime: true,
        afterPump: (tester) async {
          await _open(tester);
          await tester.tap(find.byKey(_RefreshHost.refreshKey));
          for (var f = 0; f < 4; f++) {
            await tester.pump(const Duration(milliseconds: 70));
            expect(tester.takeException(), isNull);
          }
          await tester.pumpAndSettle();
          expect(find.byType(BalanceMethodLines), findsNWidgets(2));
        },
      );
    });
  });
}

/// BalanceCard con un botón que tapa y destapa el ojo.
class _HiddenHost extends StatefulWidget {
  const _HiddenHost({required this.methods});

  static const eyeKey = ValueKey('ojo');
  final List<MethodTotal> methods;

  @override
  State<_HiddenHost> createState() => _HiddenHostState();
}

class _HiddenHostState extends State<_HiddenHost> {
  var _hidden = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextButton(
              key: _HiddenHost.eyeKey,
              onPressed: () => setState(() => _hidden = !_hidden),
              child: const Text('ojo'),
            ),
            BalanceCard(
              totals: buildTotals(
                incomeCents: 99999999999900,
                expenseCents: 99999999999900,
                netFlowCents: -99999999999900,
              ),
              hidden: _hidden,
              methods: widget.methods,
            ),
          ],
        ),
      ),
    );
  }
}

/// BalanceCard que, al refrescar, pasa de 6 medios largos a 1 corto.
class _RefreshHost extends StatefulWidget {
  static const refreshKey = ValueKey('refrescar');

  @override
  State<_RefreshHost> createState() => _RefreshHostState();
}

class _RefreshHostState extends State<_RefreshHost> {
  var _refreshed = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextButton(
              key: _RefreshHost.refreshKey,
              onPressed: () => setState(() => _refreshed = true),
              child: const Text('refrescar'),
            ),
            BalanceCard(
              totals: buildTotals(),
              hidden: false,
              methods: _refreshed
                  ? [_income(1, 'Nequi', 100), _expense(1, 'Nequi', 100)]
                  : _sixMethods,
            ),
          ],
        ),
      ),
    );
  }
}
