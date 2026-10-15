import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_cuentas/core/errors/app_exception.dart';
import 'package:sistema_cuentas/core/models/movement_type.dart';
import 'package:sistema_cuentas/core/network/api_endpoints.dart';
import 'package:sistema_cuentas/features/catalogs/categories_screen.dart';
import 'package:sistema_cuentas/features/catalogs/data/catalogs_repository.dart';
import 'package:sistema_cuentas/features/catalogs/models/category.dart';
import 'package:sistema_cuentas/features/catalogs/providers/categories_provider.dart';
import 'package:sistema_cuentas/features/catalogs/providers/save_catalog_providers.dart';
import 'package:sistema_cuentas/features/catalogs/widgets/category_dialog.dart';
import 'package:sistema_cuentas/shared/widgets/confirm_action_dialog.dart';
import 'package:sistema_cuentas/shared/widgets/manage_tile.dart';

import '../../helpers/auth_fixtures.dart';
import '../../helpers/movement_fixtures.dart';
import '../../support/api_harness.dart';
import '../../support/container_helpers.dart';
import '../../support/expect_screen_no_overflow.dart';
import '../../support/fake_api_adapter.dart';
import '../../support/fake_catalogs_repository.dart';
import '../../support/pump_screen_app.dart';
import '../../support/session_overrides.dart';

Finder get _delete => find.widgetWithText(OutlinedButton, 'Eliminar');
Finder get _confirm => find.widgetWithText(FilledButton, 'Eliminar');

FakeCatalogsRepository _repo({Future<void> Function(int id)? delete}) =>
    FakeCatalogsRepository(
      onCategories: () async => [
        buildCategory(id: 9, type: MovementType.income, name: 'Salario'),
        buildCategory(id: 3, name: 'Alimentación'),
        buildCategory(id: 4, name: 'Vieja', active: false),
      ],
      onDeleteCategory: delete,
    );

// Sin permisos: borrar no pide ninguno.
List<Override> _overrides(FakeCatalogsRepository repo) => [
  ...sessionOverrides(permissions: const {}).overrides,
  catalogsRepositoryProvider.overrideWithValue(repo),
];

Future<void> _openEditing(
  WidgetTester tester,
  FakeCatalogsRepository repo,
) async {
  await pumpScreenApp(
    tester,
    screen: const CategoriesScreen(),
    overrides: _overrides(repo),
  );
  await tester.tap(find.text('Alimentación'));
  await tester.pumpAndSettle();
}

void main() {
  group('modelo', () {
    test('eliminada viene del servidor; por defecto no', () {
      expect(Category.fromJson(categoryJson()).deleted, isFalse);
      expect(
        Category.fromJson({...categoryJson(), 'eliminada': true}).deleted,
        isTrue,
      );
    });

    test('asDeleted conserva icono y color y la deja inactiva', () {
      final deleted = buildCategory(icon: 'food', color: '#AA0000').asDeleted();
      expect(deleted.deleted, isTrue);
      expect(deleted.active, isFalse);
      expect((deleted.icon, deleted.color), ('food', '#AA0000'));
    });
  });

  group('repositorio', () {
    test('POST con id_categoria al endpoint de eliminar', () async {
      final h = ApiHarness(
        FakeApiAdapter.json(
          successEnvelope({'eliminada': true, 'id_categoria': 3}),
        ),
      );

      await CatalogsRepository(h.api).deleteCategory(3);

      expect(h.single.method, 'POST');
      expect(h.single.path, ApiEndpoints.categoryDelete);
      expect(h.single.body, {'id_categoria': 3});
    });
  });

  group('deleteCategoryProvider', () {
    test('marca la categoría como eliminada sin recargar la lista', () async {
      final repo = _repo();
      final container = makeContainer(
        overrides: [catalogsRepositoryProvider.overrideWithValue(repo)],
      );
      keepAlive(container, [deleteCategoryProvider, categoriesProvider]);
      await container.read(categoriesProvider.future);

      await container.read(deleteCategoryProvider.notifier).delete(3);

      expect(repo.deletedCategories, [3]);
      expect(repo.categoriesCalls, 1);
      final all = container.read(categoriesProvider).requireValue;
      expect(all.firstWhere((c) => c.id == 3).deleted, isTrue);
      expect(
        container.read(visibleCategoriesProvider).requireValue.map((c) => c.id),
        [9, 4],
        reason: 'Ajustes no la lista (la inactiva sí)',
      );
      expect(
        container
            .read(categoriesForTypeProvider(MovementType.expense))
            .requireValue,
        isEmpty,
        reason: 'ya no se puede elegir para algo nuevo',
      );
      expect(
        container
            .read(categoriesOfTypeProvider(MovementType.expense))
            .requireValue
            .map((c) => c.id),
        contains(3),
        reason: 'lo registrado con ella sigue filtrable',
      );
      expect(container.read(categoryByIdProvider(3)), isNotNull);
    });

    test('si falla, la categoría sigue y el error llega como estado', () async {
      final container = makeContainer(
        overrides: [
          catalogsRepositoryProvider.overrideWithValue(
            _repo(
              delete: (_) async => throw const NetworkException('Sin red.'),
            ),
          ),
        ],
      );
      keepAlive(container, [deleteCategoryProvider, categoriesProvider]);
      await container.read(categoriesProvider.future);

      await container.read(deleteCategoryProvider.notifier).delete(3);

      expect(container.read(deleteCategoryProvider).hasError, isTrue);
      expect(
        container
            .read(categoriesProvider)
            .requireValue
            .firstWhere((c) => c.id == 3)
            .deleted,
        isFalse,
      );
    });

    test(
      'anti doble envío: con una eliminación en curso no manda otra',
      () async {
        final gate = Completer<void>();
        final repo = _repo(delete: (_) => gate.future);
        final container = makeContainer(
          overrides: [catalogsRepositoryProvider.overrideWithValue(repo)],
        );
        keepAlive(container, [deleteCategoryProvider, categoriesProvider]);
        await container.read(categoriesProvider.future);

        final notifier = container.read(deleteCategoryProvider.notifier);
        final first = notifier.delete(3);
        await notifier.delete(3);
        gate.complete();
        await first;

        expect(repo.deletedCategories, [3]);
      },
    );
  });

  group('en pantalla', () {
    testWidgets('editar muestra «Eliminar»; crear no', (tester) async {
      await _openEditing(tester, _repo());
      expect(_delete, findsOneWidget);

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Nueva categoría'));
      await tester.pumpAndSettle();
      expect(find.byType(CategoryDialog), findsOneWidget);
      expect(_delete, findsNothing);
    });

    testWidgets('pide confirmar; al aceptar elimina, avisa, cierra y la saca '
        'de la lista', (tester) async {
      final repo = _repo();
      await _openEditing(tester, repo);

      await tester.tap(_delete);
      await tester.pumpAndSettle();
      expect(find.text('Eliminar categoría'), findsOneWidget);
      expect(repo.deletedCategories, isEmpty, reason: 'aún no confirmó');

      await tester.tap(_confirm);
      await showToast(tester);

      expect(repo.deletedCategories, [3]);
      expect(find.text('Categoría eliminada'), findsOneWidget);
      await dismissToasts(tester);
      expect(find.byType(CategoryDialog), findsNothing);
      expect(find.text('Alimentación'), findsNothing);
      expect(find.byType(ManageTile), findsNWidgets(2));
    });

    testWidgets('si se cancela la confirmación no se elimina nada', (
      tester,
    ) async {
      final repo = _repo();
      await _openEditing(tester, repo);

      await tester.tap(_delete);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(OutlinedButton, 'Cancelar').last);
      await tester.pumpAndSettle();

      expect(repo.deletedCategories, isEmpty);
      expect(find.byType(CategoryDialog), findsOneWidget);
    });

    testWidgets('mientras elimina: el progreso va en «Eliminar» y todo queda '
        'bloqueado', (tester) async {
      final gate = Completer<void>();
      await _openEditing(tester, _repo(delete: (_) => gate.future));

      await tester.tap(_delete);
      await tester.pumpAndSettle();
      await tester.tap(_confirm);
      // Con el progreso girando no hay pumpAndSettle: se espera el cierre de
      // la confirmación a mano.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(
        find.descendant(
          of: _delete,
          matching: find.byType(CircularProgressIndicator),
        ),
        findsOneWidget,
      );
      final save = find.widgetWithText(FilledButton, 'Guardar');
      expect(
        find.descendant(
          of: save,
          matching: find.byType(CircularProgressIndicator),
        ),
        findsNothing,
      );
      expect(tester.widget<FilledButton>(save).onPressed, isNull);
      expect(tester.widget<OutlinedButton>(_delete).onPressed, isNull);
      expect(
        tester
            .widget<OutlinedButton>(
              find.widgetWithText(OutlinedButton, 'Cancelar'),
            )
            .onPressed,
        isNull,
      );
      gate.complete();
      await showToast(tester);
      await dismissToasts(tester);
    });

    testWidgets('si falla: error en español y el diálogo sigue abierto', (
      tester,
    ) async {
      final repo = _repo(
        delete: (_) async =>
            throw const NetworkException('Sin conexión con el servidor.'),
      );
      await _openEditing(tester, repo);

      await tester.tap(_delete);
      await tester.pumpAndSettle();
      await tester.tap(_confirm);
      await showToast(tester);

      expect(find.text('Sin conexión con el servidor.'), findsOneWidget);
      await dismissToasts(tester);
      expect(find.byType(CategoryDialog), findsOneWidget);
      expect(find.text('Alimentación'), findsWidgets);
    });
  });

  group('sin desbordes con el pie de tres botones', () {
    testWidgets('«Editar categoría» y la confirmación', (tester) async {
      await expectScreenNoOverflow(
        tester,
        screen: const CategoriesScreen(),
        overrides: () => _overrides(_repo()),
        prepare: (tester) async {
          await tester.tap(find.text('Alimentación'));
          await tester.pumpAndSettle();
          expect(_delete, findsOneWidget);
          // Se acciona sin depender de dónde cayó con teclado o texto grande.
          tester.widget<OutlinedButton>(_delete).onPressed!();
          await tester.pumpAndSettle();
          // Con teclado abierto el encabezado se oculta: se busca el diálogo.
          expect(find.byType(ConfirmActionDialog), findsOneWidget);
        },
      );
    });
  });
}
