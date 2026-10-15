import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_cuentas/core/theme/app_theme.dart';
import 'package:sistema_cuentas/features/catalogs/data/catalogs_repository.dart';
import 'package:sistema_cuentas/features/movements/models/movement.dart';
import 'package:sistema_cuentas/features/movements/utils/movement_groups.dart';
import 'package:sistema_cuentas/features/movements/widgets/movement_tile.dart';
import 'package:sistema_cuentas/features/movements/widgets/movement_tile_title.dart';

import '../../../helpers/movement_fixtures.dart';
import '../../../support/expect_layout.dart';
import '../../../support/fake_catalogs_repository.dart';

Future<void> _pump(
  WidgetTester tester,
  Movement movement, {
  double textScale = 1,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      overrides: [
        catalogsRepositoryProvider.overrideWithValue(
          FakeCatalogsRepository(onCategories: () async => []),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.dark,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        // Dentro de un scroll, como en la lista: una fila con nombre largo
        // crece hacia abajo (con el alto fijo del `Scaffold` se vería cortada).
        home: Scaffold(
          body: SingleChildScrollView(
            child: MovementTile(
              movement: movement,
              position: RowPosition.only,
              hidden: false,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void _useSize(WidgetTester tester, double width) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, 700);
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets('con contacto, el título es SOLO el contacto (sin descripción)', (
    tester,
  ) async {
    await _pump(
      tester,
      buildMovement(description: 'Desarrollo mensual', contact: 'oscar fcs'),
    );

    expect(find.text('Oscar fcs'), findsOneWidget);
    expect(find.textContaining('Desarrollo'), findsNothing);
    expect(find.textContaining('·'), findsNWidgets(1)); // solo «Alimentación ·»
    expect(find.text('Alimentación ·'), findsOneWidget);
    expect(find.text('Nequi'), findsOneWidget);
  });

  testWidgets('sin contacto, el título es la descripción', (tester) async {
    await _pump(tester, buildMovement(description: 'Mercado'));

    expect(find.text('Mercado'), findsOneWidget);
    expect(find.text('Alimentación ·'), findsOneWidget);
    expect(find.text('Nequi'), findsOneWidget);
    // descripción, categoría ·, medio y monto (sin hora: no hay createdAt).
    expect(find.byType(Text), findsNWidgets(4));
  });

  testWidgets('caso típico a 390 px: título y detalle, 2 líneas en total', (
    tester,
  ) async {
    _useSize(tester, 390);
    await _pump(
      tester,
      buildMovement(description: 'Desarrollo mensual', contact: 'Santo cafe'),
    );

    final title = find.byType(MovementTileTitle);
    expectSingleLine(tester, title);
    expect(
      tester.getRect(find.text('Alimentación ·')).top,
      greaterThan(tester.getRect(title).top),
      reason: 'el detalle va debajo del título',
    );
    expect(tester.getSize(find.byType(MovementTile)).height, lessThan(80));
  });

  group('un contacto muy largo crece, no se recorta', () {
    const contact =
        'Comercializadora Internacional de Servicios Integrales SAS';

    for (final (width, scale) in [(320.0, 1.5), (390.0, 1.0)]) {
      testWidgets('$width px · texto $scale', (tester) async {
        _useSize(tester, width);
        await _pump(
          tester,
          buildMovement(
            description: 'Desarrollo mensual de la plataforma de cobros',
            contact: contact,
          ),
          textScale: scale,
        );

        expect(tester.takeException(), isNull);
        // El nombre entero está en pantalla, sin «…» ni límite de líneas.
        final text = tester.widget<Text>(
          find.descendant(
            of: find.byType(MovementTileTitle),
            matching: find.byType(Text),
          ),
        );
        expect(text.data, contact);
        expect(text.maxLines, isNull);
        expect(text.overflow, isNot(TextOverflow.ellipsis));
        // Y el monto sigue pegado a la esquina derecha, aunque el título crezca.
        expectRightEdge(
          tester,
          find.text(r'-$ 25.000'),
          find.byType(MovementTile),
        );
        expect(
          textLines(tester, find.byType(MovementTileTitle)),
          greaterThan(1),
        );
        expect(find.textContaining('Desarrollo'), findsNothing);
      });
    }
  });
}
