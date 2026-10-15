import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_cuentas/core/models/movement_type.dart';
import 'package:sistema_cuentas/core/models/session.dart';
import 'package:sistema_cuentas/features/catalogs/data/catalogs_repository.dart';
import 'package:sistema_cuentas/features/catalogs/models/category.dart';
import 'package:sistema_cuentas/features/catalogs/widgets/category_dialog.dart';
import 'package:sistema_cuentas/shared/widgets/app_toggle.dart';

import '../../../helpers/movement_fixtures.dart';
import '../../../support/fake_catalogs_repository.dart';
import '../../../support/pump_screen_app.dart';
import '../../../support/session_overrides.dart';

/// Un botón que abre el diálogo como lo hace la app (`showDialog`).
class _Opener extends StatelessWidget {
  const _Opener({this.category, this.initialType});

  final Category? category;
  final MovementType? initialType;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: FilledButton(
        onPressed: () => showCategoryDialog(
          context,
          category: category,
          initialType: initialType,
        ),
        child: const Text('Abrir'),
      ),
    ),
  );
}

Future<FakeCatalogsRepository> _open(
  WidgetTester tester,
  _Opener opener,
) async {
  final repo = FakeCatalogsRepository(
    onCategories: () async => [buildCategory(id: 3, name: 'Alimentación')],
    onSaveCategory: (draft) async =>
        buildCategory(id: 50, type: draft.type, name: draft.name),
  );
  await pumpScreenApp(
    tester,
    screen: opener,
    overrides: [
      ...sessionOverrides(permissions: {Permissions.manageCatalogs}).overrides,
      catalogsRepositoryProvider.overrideWithValue(repo),
    ],
  );
  await tester.tap(find.text('Abrir'));
  await tester.pumpAndSettle();
  expect(find.byType(CategoryDialog), findsOneWidget);
  return repo;
}

MovementType _selectedType(WidgetTester tester) => tester
    .widget<AppToggle<MovementType>>(find.byType(AppToggle<MovementType>))
    .selected;

void main() {
  testWidgets('al crear arranca con el tipo pedido y lo guarda', (
    tester,
  ) async {
    final repo = await _open(
      tester,
      const _Opener(initialType: MovementType.income),
    );

    expect(_selectedType(tester), MovementType.income);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nombre'),
      'Freelance',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Guardar'));
    await showToast(tester);

    expect(repo.savedCategories.single.type, MovementType.income);
    await dismissToasts(tester);
  });

  testWidgets('al editar se ignora: el tipo de la categoría manda', (
    tester,
  ) async {
    await _open(
      tester,
      _Opener(
        category: buildCategory(id: 3, name: 'Alimentación'),
        initialType: MovementType.income,
      ),
    );

    expect(_selectedType(tester), MovementType.expense);
  });
}
