import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_cuentas/core/errors/app_exception.dart';
import 'package:sistema_cuentas/core/models/movement_type.dart';
import 'package:sistema_cuentas/core/theme/design_tokens.dart';
import 'package:sistema_cuentas/features/catalogs/models/category.dart';
import 'package:sistema_cuentas/features/movements/widgets/new_movement_sheet.dart';
import 'package:sistema_cuentas/shared/widgets/app_form_pair.dart';
import 'package:sistema_cuentas/shared/widgets/catalog_pick_card.dart';
import 'package:sistema_cuentas/shared/widgets/catalog_picker_row.dart';

import '../../../helpers/movement_fixtures.dart';
import '../../../support/fake_catalogs_repository.dart';
import '../../../support/inicio_overrides.dart';
import '../../../support/open_movement_sheet.dart';
import '../../../support/pump_at_sizes.dart';

/// La tarjeta de «Categoría» o «Medio de pago».
Finder _card(String label) => find.widgetWithText(CatalogPickCard, label);

/// Lo que se toca de la tarjeta: su `InkWell`.
Finder _cardTap(String label) =>
    find.descendant(of: _card(label), matching: find.byType(InkWell));

/// Elige la primera opción de la hoja de [label] (como lo hace la persona).
Future<void> _pickFirst(WidgetTester tester, String label) async {
  // Sin foco en un campo de texto: si no, al terminar de asentarse lleva su
  // cursor a la vista y deshace el desplazamiento hasta la tarjeta.
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
  await tester.ensureVisible(_card(label));
  await tester.pumpAndSettle();
  await tester.tap(_cardTap(label));
  await tester.pumpAndSettle();
  await tester.tap(find.byType(CatalogPickerRow).first);
  await tester.pumpAndSettle();
}

FakeCatalogsRepository _catalogs({
  Future<List<Category>> Function()? categories,
}) => FakeCatalogsRepository(
  onCategories: categories ?? () async => defaultCategories(),
  onMethods: () async => defaultMethods(),
);

/// Abre la hoja con el formulario de [type] en cada combinación de ancho ×
/// teclado × texto y falla ante cualquier excepción de Flutter (un
/// `RenderFlex overflowed` lo es). `expectNoOverflow` monta la vista y no puede
/// tocar nada a medias, así que la hoja se recorre aquí a mano.
Future<void> _expectFormNoOverflow(
  WidgetTester tester, {
  required MovementType type,
  required FakeCatalogsRepository catalogs,
  bool settle = true,
  List<double> widths = testWidths,
}) async {
  for (final width in widths) {
    for (final keyboard in testKeyboards) {
      for (final scale in testTextScales) {
        await openMovementSheet(
          tester,
          type: type,
          width: width,
          height: 700,
          keyboard: keyboard,
          textScale: scale,
          settle: settle,
          overrides: dataOverrides(catalogs: catalogs),
        );
        expect(
          tester.takeException(),
          isNull,
          reason: '$type · $width px · teclado $keyboard · texto $scale',
        );
        expect(find.byType(NewMovementSheet), findsOneWidget);
      }
    }
  }
}

void main() {
  for (final type in MovementType.values) {
    group('formulario en la hoja «+» (${type.apiValue})', () {
      testWidgets('no desborda en 320/390/800/1300 × teclado × texto 1.5', (
        tester,
      ) async {
        await _expectFormNoOverflow(tester, type: type, catalogs: _catalogs());
      });

      testWidgets('catálogos con error: el mensaje y el reintento caben', (
        tester,
      ) async {
        await _expectFormNoOverflow(
          tester,
          type: type,
          catalogs: _catalogs(
            categories: () async =>
                throw const NetworkException('Catálogos sin conexión.'),
          ),
        );
      });

      testWidgets('sin categorías activas del tipo', (tester) async {
        await _expectFormNoOverflow(
          tester,
          type: type,
          catalogs: _catalogs(categories: () async => const []),
        );
      });

      testWidgets('catálogos cargando', (tester) async {
        final never = Completer<List<Category>>();
        await _expectFormNoOverflow(
          tester,
          type: type,
          catalogs: _catalogs(categories: () => never.future),
          settle: false,
          widths: const [320, 390, 1300],
        );
      });
    });
  }

  testWidgets(
    'con categoría y medio de 40+ caracteres, descripción larga y 10 dígitos no desborda',
    (tester) async {
      expect(longCatalogName.length, greaterThan(40));
      final catalogs = FakeCatalogsRepository(
        onCategories: () async => [buildCategory(id: 3, name: longCatalogName)],
        onMethods: () async => [buildMethod(id: 2, name: longCatalogName)],
      );
      for (final (width, keyboard, scale) in [
        (320.0, 300.0, 1.0),
        (320.0, 0.0, 1.5),
        (390.0, 300.0, 1.0),
        (1300.0, 0.0, 1.5),
      ]) {
        await openMovementSheet(
          tester,
          type: MovementType.expense,
          width: width,
          height: 700,
          keyboard: keyboard,
          textScale: scale,
          overrides: dataOverrides(catalogs: catalogs),
        );
        final reason = '$width px · teclado $keyboard · texto $scale';

        await tester.enterText(find.byType(TextFormField).at(0), '9999999999');
        await tester.enterText(
          find.byType(TextFormField).at(1),
          longDescription * 2,
        );
        await _pickFirst(tester, 'Categoría');
        await _pickFirst(tester, 'Medio de pago');

        expect(tester.takeException(), isNull, reason: reason);
        expect(find.text('9.999.999.999'), findsOneWidget, reason: reason);
      }
    },
  );

  group('distribución: categoría y medio de pago (pareja desde 340 px útiles)', () {
    /// ¿Van en la misma fila? Devuelve también el ancho útil que midió el par.
    Future<(bool sameRow, double usable)> measure(
      WidgetTester tester, {
      required double width,
      required double scale,
      FakeCatalogsRepository? catalogs,
    }) async {
      await openMovementSheet(
        tester,
        type: MovementType.expense,
        width: width,
        textScale: scale,
        overrides: dataOverrides(catalogs: catalogs),
      );
      expect(tester.takeException(), isNull, reason: '$width px · $scale');
      final sameRow =
          tester.getTopLeft(_card('Categoría')).dy ==
          tester.getTopLeft(_card('Medio de pago')).dy;
      return (sameRow, tester.getSize(find.byType(AppFormPair)).width);
    }

    testWidgets('apiladas en 320 y 360 px (menos de 340 útiles)', (
      tester,
    ) async {
      // 320 − 2 × 16 = 288 y 360 − 2 × 16 = 328: ambas < 340.
      for (final width in [320.0, 360.0]) {
        final result = await measure(tester, width: width, scale: 1);
        expect(result.$1, isFalse, reason: '$width px (útil ${result.$2})');
        expect(
          tester.getTopLeft(_card('Categoría')).dy,
          lessThan(tester.getTopLeft(_card('Medio de pago')).dy),
          reason: 'la categoría queda sobre el medio',
        );
        expect(
          tester.getTopLeft(_card('Categoría')).dx,
          tester.getTopLeft(_card('Medio de pago')).dx,
        );
      }
    });

    testWidgets('en fila desde 390 px con texto normal (358 ≥ 340)', (
      tester,
    ) async {
      for (final width in [390.0, 800.0, 1300.0]) {
        final result = await measure(tester, width: width, scale: 1);
        expect(result.$2, greaterThanOrEqualTo(340));
        expect(result.$1, isTrue, reason: '$width px (útil ${result.$2})');
        expect(
          tester.getTopLeft(_card('Categoría')).dx,
          lessThan(tester.getTopLeft(_card('Medio de pago')).dx),
        );
      }
    });

    testWidgets(
      'en cualquier ancho y escala: fila si y solo si el ancho útil ≥ 340 × escala',
      (tester) async {
        for (final width in [...testWidths, 360.0]) {
          for (final scale in testTextScales) {
            final (sameRow, usable) = await measure(
              tester,
              width: width,
              scale: scale,
            );
            expect(
              sameRow,
              usable >= DesignTokens.formPickPairMinWidth * scale,
              reason: '$width px · texto $scale · ancho útil $usable',
            );
          }
        }
      },
    );

    testWidgets(
      'con «Desarrollo de software» y un medio de 40+ caracteres: sin '
      'desbordes, dentro de la pantalla y la pareja sigue en una fila a 390 px',
      (tester) async {
        final catalogs = FakeCatalogsRepository(
          onCategories: () async => [
            buildCategory(id: 3, name: 'Desarrollo de software'),
          ],
          onMethods: () async => [buildMethod(id: 2, name: longCatalogName)],
        );
        for (final (width, scale) in [
          (320.0, 1.0),
          (360.0, 1.0),
          (390.0, 1.0),
          (320.0, 1.5),
        ]) {
          final (sameRow, usable) = await measure(
            tester,
            width: width,
            scale: scale,
            catalogs: catalogs,
          );
          final reason = '$width px · texto $scale (útil $usable)';
          expect(
            sameRow,
            usable >= DesignTokens.formPickPairMinWidth * scale,
            reason: reason,
          );
          for (final label in ['Categoría', 'Medio de pago']) {
            final rect = tester.getRect(_card(label));
            expect(rect.left, greaterThanOrEqualTo(0), reason: reason);
            expect(rect.right, lessThanOrEqualTo(width), reason: reason);
          }
          // Elegidas, siguen sin desbordar y sin salirse de la pantalla.
          await _pickFirst(tester, 'Categoría');
          await _pickFirst(tester, 'Medio de pago');
          expect(tester.takeException(), isNull, reason: reason);
          expect(
            find.descendant(
              of: _card('Categoría'),
              matching: find.text('Desarrollo de software'),
            ),
            findsOneWidget,
            reason: reason,
          );
          expect(
            find.descendant(
              of: _card('Medio de pago'),
              matching: find.text(longCatalogName),
            ),
            findsOneWidget,
            reason: '$reason: el nombre largo crece, no se recorta',
          );
          for (final label in ['Categoría', 'Medio de pago']) {
            expect(
              tester.getRect(_card(label)).right,
              lessThanOrEqualTo(width),
              reason: reason,
            );
          }
        }
      },
    );

    testWidgets(
      'en pareja, las dos tarjetas miden lo mismo (forms.md: misma altura)',
      (tester) async {
        final catalogs = FakeCatalogsRepository(
          onCategories: () async => [
            buildCategory(id: 3, name: 'Desarrollo de software'),
          ],
          onMethods: () async => [buildMethod(id: 2, name: 'Nequi')],
        );
        final (sameRow, _) = await measure(
          tester,
          width: 390,
          scale: 1,
          catalogs: catalogs,
        );
        expect(sameRow, isTrue);
        await _pickFirst(tester, 'Categoría');
        await _pickFirst(tester, 'Medio de pago');

        expect(
          tester.getSize(_card('Categoría')).height,
          tester.getSize(_card('Medio de pago')).height,
          reason: 'bordes inferiores desiguales en la misma fila',
        );
      },
    );
  });
}
