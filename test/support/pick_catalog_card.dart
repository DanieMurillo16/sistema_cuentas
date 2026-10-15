import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_cuentas/shared/widgets/catalog_pick_card.dart';
import 'package:sistema_cuentas/shared/widgets/catalog_picker_row.dart';

/// La tarjeta de selección con esa etiqueta («Medio de pago», «Categoría»…).
Finder catalogCard(String label) => find.widgetWithText(CatalogPickCard, label);

/// Lo que se toca de la tarjeta: su `InkWell` (el primero: el de abrir; la
/// «x» de quitar es un `IconButton` aparte).
Finder catalogCardTap(String label) => find
    .descendant(of: catalogCard(label), matching: find.byType(InkWell))
    .first;

/// La fila de la hoja con ese texto.
Finder catalogSheetOption(String option) => find.descendant(
  of: find.byType(CatalogPickerRow),
  matching: find.text(option),
);

/// Abre la hoja de la tarjeta [label] (la lleva a la vista y la toca).
Future<void> openCatalogSheet(WidgetTester tester, String label) async {
  await tester.ensureVisible(catalogCard(label));
  await tester.pumpAndSettle();
  await tester.tap(catalogCardTap(label));
  await tester.pumpAndSettle();
}

/// Toca una fila de la hoja por su esquina superior: con nombres largos, texto
/// grande y teclado la fila puede ser más alta que lo visible y su centro
/// quedar recortado; la persona la desplaza y toca donde la ve.
Future<void> _tapRow(WidgetTester tester, Finder row) async {
  await tester.ensureVisible(row);
  await tester.pumpAndSettle();
  await tester.tapAt(tester.getTopLeft(row) + const Offset(24, 16));
  await tester.pumpAndSettle();
}

/// Elige [option] como lo hace la persona: tarjeta → hoja inferior → fila.
Future<void> pickCatalogOption(
  WidgetTester tester,
  String label,
  String option,
) async {
  await openCatalogSheet(tester, label);
  // Con «Frecuentes» la fila puede ni estar construida (la lista es perezosa):
  // se desplaza la hoja hasta que aparezca.
  final text = catalogSheetOption(option);
  for (var i = 0; i < 20 && text.evaluate().isEmpty; i++) {
    await tester.drag(find.byType(Scrollable).last, const Offset(0, -150));
    await tester.pumpAndSettle();
  }
  await _tapRow(
    tester,
    find.ancestor(of: text.first, matching: find.byType(CatalogPickerRow)),
  );
}

/// Elige la primera fila de la hoja de [label].
Future<void> pickFirstCatalogOption(WidgetTester tester, String label) async {
  await openCatalogSheet(tester, label);
  final rows = find.byType(CatalogPickerRow);
  for (var i = 0; i < 20 && rows.evaluate().isEmpty; i++) {
    await tester.drag(find.byType(Scrollable).last, const Offset(0, -150));
    await tester.pumpAndSettle();
  }
  await _tapRow(tester, rows.first);
}
