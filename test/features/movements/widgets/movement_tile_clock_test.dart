import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_cuentas/core/models/movement_type.dart';
import 'package:sistema_cuentas/core/theme/app_theme.dart';
import 'package:sistema_cuentas/features/catalogs/data/catalogs_repository.dart';
import 'package:sistema_cuentas/features/movements/models/movement.dart';
import 'package:sistema_cuentas/features/movements/utils/movement_groups.dart';
import 'package:sistema_cuentas/features/movements/widgets/movement_tile_detail.dart';
import 'package:sistema_cuentas/features/movements/widgets/movement_tile_title.dart';
import 'package:sistema_cuentas/features/movements/widgets/movement_tile.dart';
import 'package:sistema_cuentas/shared/widgets/animated_number_text.dart';

import '../../../helpers/movement_fixtures.dart';
import '../../../support/fake_catalogs_repository.dart';
import '../../../support/pump_at_sizes.dart';

final _overrides = [
  catalogsRepositoryProvider.overrideWithValue(
    FakeCatalogsRepository(onCategories: () async => []),
  ),
];

Future<void> _pump(
  WidgetTester tester,
  Movement movement, {
  bool hidden = false,
  double width = 390,
  double textScale = 1,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, 700);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      overrides: _overrides,
      child: MaterialApp(
        theme: AppTheme.dark,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: Scaffold(
          body: SingleChildScrollView(
            child: MovementTile(
              movement: movement,
              position: RowPosition.only,
              hidden: hidden,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Finder get _tile => find.byType(MovementTile);
Finder get _amount => find.text(r'-$ 25.000');

void main() {
  group('la hora bajo el monto', () {
    testWidgets('con createdAt: «3:45 p. m.» en la esquina, bajo el monto', (
      tester,
    ) async {
      await _pump(
        tester,
        buildMovement(createdAt: DateTime(2026, 10, 14, 15, 45)),
      );

      expect(find.text('3:45 p. m.'), findsOneWidget);
      final amount = tester.getRect(_amount);
      final clock = tester.getRect(find.text('3:45 p. m.'));
      expect(clock.top, greaterThanOrEqualTo(amount.bottom - 0.5));
      expect(clock.right, closeTo(390 - 16, 1), reason: 'pegada a la esquina');
    });

    testWidgets('monto y hora comparten el borde derecho', (tester) async {
      await _pump(
        tester,
        buildMovement(createdAt: DateTime(2026, 10, 14, 15, 45)),
      );

      final amount = tester.getRect(_amount);
      final clock = tester.getRect(find.text('3:45 p. m.'));
      expect(amount.right, closeTo(clock.right, 1));
      expect(amount.right, closeTo(390 - 16, 1));
    });

    testWidgets('las horas bordes: a. m. / p. m. y 12', (tester) async {
      for (final (at, text) in [
        (DateTime(2026, 10, 14, 0, 5), '12:05 a. m.'),
        (DateTime(2026, 10, 14, 9, 30), '9:30 a. m.'),
        (DateTime(2026, 10, 14, 12, 30), '12:30 p. m.'),
        (DateTime(2026, 10, 14, 23, 59), '11:59 p. m.'),
      ]) {
        await _pump(tester, buildMovement(createdAt: at));
        expect(find.text(text), findsOneWidget, reason: text);
      }
    });

    testWidgets('sin createdAt: no hay hora ni línea extra', (tester) async {
      await _pump(tester, buildMovement());

      expect(
        find.byWidgetPredicate(
          (w) => w is Text && RegExp(r'[ap]\. m\.').hasMatch(w.data ?? ''),
        ),
        findsNothing,
      );
    });

    testWidgets('la hora va en la línea de categoría · medio: la fila no '
        'crece por tenerla', (tester) async {
      // En ancho (800 px) todo cabe en una línea.
      await _pump(tester, buildMovement(), width: 800);
      final without = tester.getSize(_tile).height;
      await _pump(
        tester,
        buildMovement(createdAt: DateTime(2026, 10, 14, 8)),
        width: 800,
      );
      final withClock = tester.getSize(_tile).height;

      expect(withClock, closeTo(without, 0.5));
    });

    testWidgets('con el ojo cerrado: monto enmascarado, la hora sigue', (
      tester,
    ) async {
      await _pump(
        tester,
        buildMovement(createdAt: DateTime(2026, 10, 14, 15, 45)),
        hidden: true,
      );

      expect(find.text(AnimatedNumberText.mask), findsOneWidget);
      expect(_amount, findsNothing);
      expect(find.text('3:45 p. m.'), findsOneWidget);
    });

    testWidgets('un ingreso lleva su hora igual', (tester) async {
      await _pump(
        tester,
        buildMovement(
          type: MovementType.income,
          createdAt: DateTime(2026, 10, 14, 18, 2),
        ),
      );

      expect(find.text('6:02 p. m.'), findsOneWidget);
    });
  });

  group('MovementTileDetail (segunda línea)', () {
    Future<void> pumpDetail(
      WidgetTester tester,
      Movement movement, {
      double width = 390,
      double textScale = 1,
    }) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 700);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
          home: Scaffold(body: MovementTileDetail(movement: movement)),
        ),
      );
    }

    testWidgets('categoría · medio a la izquierda y la hora en la esquina '
        'derecha, en la misma línea', (tester) async {
      await pumpDetail(
        tester,
        buildMovement(createdAt: DateTime(2026, 10, 14, 8, 5)),
      );

      final category = tester.getRect(find.text('Alimentación ·'));
      final clock = tester.getRect(find.text('8:05 a. m.'));
      expect(clock.top, closeTo(category.top, 1));
      expect(clock.left, greaterThan(category.right));
      expect(clock.right, closeTo(390, 1));
    });

    testWidgets('sin hora, solo categoría · medio', (tester) async {
      await pumpDetail(tester, buildMovement());

      expect(find.text('Alimentación ·'), findsOneWidget);
      expect(find.text('Nequi'), findsOneWidget);
      expect(find.byType(Text), findsNWidgets(2));
    });

    testWidgets('categoría y medio de 40+ caracteres con hora a 320 px × '
        'texto 1.5: la hora no se corta ni desborda', (tester) async {
      await pumpDetail(
        tester,
        buildMovement(
          category: longCatalogName,
          method: longCatalogName,
          createdAt: DateTime(2026, 10, 14, 23, 59),
        ),
        width: 320,
        textScale: 1.5,
      );

      expect(tester.takeException(), isNull);
      final clock = tester.getRect(find.text('11:59 p. m.'));
      expect(clock.right, lessThanOrEqualTo(320));
      expect(clock.left, greaterThanOrEqualTo(0));
    });
  });

  group('distribución de la fila (posiciones a 320/390 × texto 1.0/1.5)', () {
    for (final width in [320.0, 390.0]) {
      for (final scale in [1.0, 1.5]) {
        testWidgets('$width px · texto $scale: monto pegado a la derecha, '
            'título con todo el ancho restante y la hora en la línea 2', (
          tester,
        ) async {
          await _pump(
            tester,
            buildMovement(
              description: 'Mercado',
              createdAt: DateTime(2026, 10, 14, 15, 45),
            ),
            width: width,
            textScale: scale,
          );

          final row = width - 16; // padding de la fila
          final amount = tester.getRect(_amount);
          final clock = tester.getRect(find.text('3:45 p. m.'));
          final title = tester.getRect(find.byType(MovementTileTitle));
          final icon = tester.getRect(find.byType(Icon).first);

          expect(amount.right, closeTo(row, 1), reason: 'monto en la esquina');
          expect(clock.right, closeTo(row, 1), reason: 'hora en la esquina');
          expect(
            clock.top,
            greaterThanOrEqualTo(amount.bottom - 1),
            reason: 'la hora va en la línea 2',
          );
          expect(title.left, closeTo(icon.right + 16, 1));
          // El título es todo lo que queda entre el icono y el monto.
          expect(
            title.right,
            closeTo(amount.left - 8, 1.5),
            reason: 'título con casi todo el ancho restante',
          );
          expect(tester.takeException(), isNull);
        });

        testWidgets('$width px · texto $scale: con 12 dígitos el monto se '
            'encoge pero sigue en la esquina (tope del 50 %)', (tester) async {
          await _pump(
            tester,
            buildMovement(
              valueCents: 99999999999900,
              description: longDescription,
              createdAt: DateTime(2026, 10, 14, 23, 59),
            ),
            width: width,
            textScale: scale,
          );

          final row = width - 16;
          final amount = tester.getRect(
            find.byWidgetPredicate(
              (w) => w is Text && (w.data ?? '').startsWith(r'-$ 999.999'),
            ),
          );
          final clock = tester.getRect(find.text('11:59 p. m.'));
          expect(amount.right, closeTo(row, 1));
          expect(clock.right, closeTo(row, 1));
          // El monto no se come más de la mitad de la fila de texto.
          final textRow = row - 16 - 44 /* icono */;
          expect(amount.width, lessThanOrEqualTo(textRow * 0.5 + 1));
          expect(tester.takeException(), isNull);
        });
      }
    }

    testWidgets('caso típico a 390 px: dos líneas (descripción y detalle)', (
      tester,
    ) async {
      await _pump(
        tester,
        buildMovement(createdAt: DateTime(2026, 10, 14, 15, 45)),
      );

      final line1 = tester.getRect(find.text('Mercado')).top;
      final line2 = tester.getRect(find.text('Alimentación ·')).top;
      expect(line2, greaterThan(line1));
      // La hora va en la línea 2, la de categoría · medio.
      final clock = tester.getRect(find.text('3:45 p. m.'));
      expect(clock.top, closeTo(line2, 1));
      // En ancho (800 px) la fila entera son solo dos renglones.
      await _pump(
        tester,
        buildMovement(createdAt: DateTime(2026, 10, 14, 15, 45)),
        width: 800,
      );
      expect(tester.getSize(_tile).height, lessThan(80));
    });

    testWidgets('con contacto el título es solo el contacto: la fila sigue '
        'midiendo lo mismo que sin contacto', (tester) async {
      await _pump(tester, buildMovement(description: 'Desarrollo'), width: 800);
      final without = tester.getSize(_tile).height;

      await _pump(
        tester,
        buildMovement(description: 'Desarrollo', contact: 'Pedro'),
        width: 800,
      );
      expect(find.text('Pedro'), findsOneWidget);
      expect(find.textContaining('Desarrollo'), findsNothing);
      expect(tester.getSize(_tile).height, closeTo(without, 0.5));
    });
  });

  group('semántica', () {
    testWidgets('la etiqueta incluye «, a las 3:45 p. m.» si hay hora', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _pump(
        tester,
        buildMovement(createdAt: DateTime(2026, 10, 14, 15, 45)),
      );

      final label = tester.getSemantics(_tile).label;
      expect(label, endsWith(r'-$ 25.000 pesos, a las 3:45 p. m.'));
      expect(label, startsWith('Gasto, Mercado, '));
      handle.dispose();
    });

    testWidgets('sin hora, la etiqueta es la de siempre', (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(tester, buildMovement());

      final label = tester.getSemantics(_tile).label;
      expect(label, endsWith(r'-$ 25.000 pesos'));
      expect(label, isNot(contains('a las')));
      handle.dispose();
    });

    testWidgets('con el ojo cerrado no dice ni el monto ni la hora', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _pump(
        tester,
        buildMovement(createdAt: DateTime(2026, 10, 14, 15, 45)),
        hidden: true,
      );

      expect(tester.getSemantics(_tile).label, 'Gasto, Mercado, monto oculto');
      handle.dispose();
    });
  });

  group('sin cortes ni desbordes', () {
    final twelveDigits = buildMovement(
      valueCents: 99999999999900,
      description: longDescription,
      category: longCatalogName,
      method: longCatalogName,
    );

    for (final (name, at) in [
      ('a. m.', DateTime(2026, 10, 14, 11, 59)),
      ('p. m.', DateTime(2026, 10, 14, 23, 59)),
    ]) {
      testWidgets('320 px × texto 1.5, 12 dígitos y hora $name: la hora cabe '
          'dentro de la fila', (tester) async {
        await _pump(
          tester,
          buildMovement(
            valueCents: 99999999999900,
            description: longDescription,
            category: longCatalogName,
            method: longCatalogName,
            createdAt: at,
          ),
          width: 320,
          textScale: 1.5,
        );

        expect(tester.takeException(), isNull);
        final tile = tester.getRect(_tile);
        final clock = tester.getRect(
          find.text(name == 'a. m.' ? '11:59 a. m.' : '11:59 p. m.'),
        );
        expect(clock.left, greaterThanOrEqualTo(tile.left));
        expect(clock.right, lessThanOrEqualTo(tile.right));
        expect(clock.width, greaterThan(0));
        final amount = tester.getRect(
          find.byWidgetPredicate(
            (w) => w is Text && (w.data ?? '').startsWith(r'-$ 999.999'),
          ),
        );
        expect(amount.right, lessThanOrEqualTo(tile.right));
        expect(clock.right, closeTo(amount.right, 2));
      });
    }

    testWidgets('matriz 320/390/800/1300 × teclado × texto 1.5 con hora', (
      tester,
    ) async {
      await expectNoOverflow(
        tester,
        Scaffold(
          body: SingleChildScrollView(
            child: MovementTile(
              movement: Movement(
                id: twelveDigits.id,
                type: twelveDigits.type,
                valueCents: twelveDigits.valueCents,
                date: twelveDigits.date,
                description: twelveDigits.description,
                categoryId: twelveDigits.categoryId,
                category: twelveDigits.category,
                methodId: twelveDigits.methodId,
                method: twelveDigits.method,
                isCapital: false,
                fromRecurring: false,
                cancelled: false,
                createdAt: DateTime(2026, 10, 14, 12, 5),
              ),
              position: RowPosition.only,
              hidden: false,
            ),
          ),
        ),
        overrides: _overrides,
      );
    });

    testWidgets('con el ojo cerrado también cabe', (tester) async {
      await expectNoOverflow(
        tester,
        Scaffold(
          body: SingleChildScrollView(
            child: MovementTile(
              movement: buildMovement(
                valueCents: 99999999999900,
                createdAt: DateTime(2026, 10, 14, 12, 5),
              ),
              position: RowPosition.only,
              hidden: true,
            ),
          ),
        ),
        overrides: _overrides,
      );
    });
  });
}
