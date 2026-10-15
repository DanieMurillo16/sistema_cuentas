import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_cuentas/core/errors/app_exception.dart';
import 'package:sistema_cuentas/core/models/movement_type.dart';
import 'package:sistema_cuentas/core/models/session.dart';
import 'package:sistema_cuentas/features/catalogs/categories_screen.dart';
import 'package:sistema_cuentas/features/catalogs/data/catalogs_repository.dart';
import 'package:sistema_cuentas/features/catalogs/models/category.dart';
import 'package:sistema_cuentas/features/catalogs/models/category_draft.dart';
import 'package:sistema_cuentas/features/catalogs/widgets/category_dialog.dart';
import 'package:sistema_cuentas/shared/widgets/app_toggle.dart';
import 'package:sistema_cuentas/shared/widgets/manage_tile.dart';

import '../../helpers/movement_fixtures.dart';
import '../../support/expect_screen_no_overflow.dart';
import '../../support/fake_catalogs_repository.dart';
import '../../support/pump_screen_app.dart';
import '../../support/session_overrides.dart';

const _screen = CategoriesScreen();

Finder get _fab => find.byTooltip('Nueva categoría');
Finder get _save => find.widgetWithText(FilledButton, 'Guardar');
Finder get _typeToggle => find.byType(AppToggle<MovementType>);
Finder get _name => find.widgetWithText(TextFormField, 'Nombre');

List<Override> _overrides(
  FakeCatalogsRepository repo, {
  bool canManage = true,
}) => [
  ...sessionOverrides(
    permissions: {
      Permissions.registerMovements,
      if (canManage) Permissions.manageCatalogs,
    },
  ).overrides,
  catalogsRepositoryProvider.overrideWithValue(repo),
];

FakeCatalogsRepository _repo({
  Future<List<Category>> Function()? list,
  Future<Category> Function(CategoryDraft draft)? save,
}) => FakeCatalogsRepository(
  onCategories:
      list ??
      () async => [
        buildCategory(id: 9, type: MovementType.income, name: 'Salario'),
        buildCategory(id: 3, name: 'Alimentación'),
        buildCategory(id: 4, name: 'Vieja', active: false),
      ],
  onSaveCategory:
      save ??
      (d) async => buildCategory(
        id: d.id ?? 50,
        type: d.type,
        name: d.name,
        active: d.active,
      ),
);

Future<void> _pump(
  WidgetTester tester,
  FakeCatalogsRepository repo, {
  bool canManage = true,
  bool settle = true,
}) async {
  await pumpScreenApp(
    tester,
    screen: _screen,
    overrides: _overrides(repo, canManage: canManage),
    settle: settle,
  );
}

void main() {
  group('cuatro estados', () {
    testWidgets('cargando', (tester) async {
      final never = Completer<List<Category>>();
      await _pump(tester, _repo(list: () => never.future), settle: false);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(ManageTile), findsNothing);
    });

    testWidgets('datos: ingresos y gastos, capital e inactivas', (
      tester,
    ) async {
      await _pump(
        tester,
        _repo(
          list: () async => [
            buildCategory(id: 9, type: MovementType.income, name: 'Salario'),
            Category(
              id: 5,
              type: MovementType.expense,
              name: 'Préstamo',
              isCapital: true,
              active: true,
            ),
            buildCategory(id: 4, name: 'Vieja', active: false),
          ],
        ),
      );

      expect(find.byType(ManageTile), findsNWidgets(3));
      expect(find.text('Ingreso'), findsOneWidget);
      expect(find.text('Gasto · Capital'), findsOneWidget);
      expect(find.text('Inactivo'), findsOneWidget);
      expect(find.text('Sin categorías'), findsNothing);
    });

    testWidgets('vacío: mensaje y botón para crear', (tester) async {
      await _pump(tester, _repo(list: () async => const []));
      expect(find.text('Sin categorías'), findsOneWidget);
      expect(
        find.text(
          'Crea las categorías con las que clasificas tus movimientos.',
        ),
        findsOneWidget,
      );
      expect(_fab, findsOneWidget);
    });

    testWidgets('error: mensaje en español y «Intentar nuevamente»', (
      tester,
    ) async {
      var fail = true;
      final repo = _repo(
        list: () async {
          if (fail) {
            throw const NetworkException('Sin conexión con el servidor.');
          }
          return [buildCategory()];
        },
      );
      await _pump(tester, repo);
      expect(find.text('Sin conexión con el servidor.'), findsOneWidget);

      fail = false;
      await tester.tap(find.text('Intentar nuevamente'));
      await tester.pumpAndSettle();

      expect(find.text('Sin conexión con el servidor.'), findsNothing);
      expect(find.byType(ManageTile), findsOneWidget);
      expect(repo.categoriesCalls, 2);
    });
  });

  group('sin permiso aparte', () {
    testWidgets('sin catalogos.gestionar igual se puede crear y editar', (
      tester,
    ) async {
      await _pump(tester, _repo(), canManage: false);

      expect(_fab, findsOneWidget);
      await tester.tap(find.text('Alimentación'));
      await tester.pumpAndSettle();
      expect(find.byType(CategoryDialog), findsOneWidget);
    });

    testWidgets('botón «+» y tocar una fila edita', (tester) async {
      await _pump(tester, _repo());
      expect(_fab, findsOneWidget);
      await tester.tap(find.text('Alimentación'));
      await tester.pumpAndSettle();
      expect(find.byType(CategoryDialog), findsOneWidget);
    });
  });

  group('crear', () {
    testWidgets('nombre vacío: error bajo el campo y no llama al servidor', (
      tester,
    ) async {
      final repo = _repo();
      await _pump(tester, repo);
      await tester.tap(_fab);
      await tester.pumpAndSettle();
      expect(find.text('Nueva categoría'), findsWidgets);

      await tester.tap(_save);
      await tester.pumpAndSettle();

      expect(
        find.text('Escribe el nombre de la categoría (mínimo 2 letras).'),
        findsOneWidget,
      );
      expect(repo.savedCategories, isEmpty);
      expect(find.byType(CategoryDialog), findsOneWidget);
    });

    testWidgets('por defecto es un gasto que no es de capital', (tester) async {
      final repo = _repo();
      await _pump(tester, repo);
      await tester.tap(_fab);
      await tester.pumpAndSettle();
      await tester.enterText(_name, '  Mascotas ');

      await tester.tap(_save);
      await showToast(tester);

      final draft = repo.savedCategories.single;
      expect(draft.id, isNull);
      expect(draft.type, MovementType.expense);
      expect(draft.name, 'Mascotas');
      expect(draft.isCapital, isFalse);
      expect(draft.active, isTrue);
      await dismissToasts(tester);
    });

    testWidgets('éxito: avisa, cierra el diálogo y la lista muestra la nueva', (
      tester,
    ) async {
      final repo = _repo();
      await _pump(tester, repo);
      await tester.tap(_fab);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ingreso').last); // el conmutador del diálogo
      await tester.pumpAndSettle();
      await tester.enterText(_name, 'Arriendos');
      await tester.tap(find.text('Es de capital'));
      await tester.pumpAndSettle();

      await tester.tap(_save);
      await showToast(tester);

      expect(repo.savedCategories.single.type, MovementType.income);
      expect(repo.savedCategories.single.isCapital, isTrue);
      expect(find.text('Categoría creada'), findsOneWidget);
      await dismissToasts(tester);
      expect(find.byType(CategoryDialog), findsNothing);
      expect(find.text('Arriendos'), findsOneWidget);
      expect(repo.categoriesCalls, 1, reason: 'upsert, sin recargar la lista');
    });

    testWidgets('al crear no aparece el interruptor «Activa»', (tester) async {
      await _pump(tester, _repo());
      await tester.tap(_fab);
      await tester.pumpAndSettle();
      expect(find.text('Activa'), findsNothing);
    });
  });

  group('editar', () {
    Future<void> openEditing(
      WidgetTester tester,
      FakeCatalogsRepository repo,
    ) async {
      await _pump(tester, repo);
      await tester.tap(find.text('Alimentación'));
      await tester.pumpAndSettle();
    }

    testWidgets('abre con los datos y el tipo bloqueado', (tester) async {
      final repo = _repo();
      await openEditing(tester, repo);

      expect(find.text('Editar categoría'), findsOneWidget);
      expect(
        tester.widget<TextFormField>(_name).controller!.text,
        'Alimentación',
      );
      expect(find.text('Activa'), findsOneWidget);
      expect(
        tester.widget<AppToggle<MovementType>>(_typeToggle).enabled,
        isFalse,
      );

      // Tocar la otra opción no cambia el tipo de la categoría.
      await tester.tap(find.text('Ingreso').last, warnIfMissed: false);
      await tester.pumpAndSettle();
      await tester.tap(_save);
      await showToast(tester);
      expect(repo.savedCategories.single.type, MovementType.expense);
      await dismissToasts(tester);
    });

    testWidgets('éxito: manda el id (no el tipo), avisa y cierra', (
      tester,
    ) async {
      final repo = _repo();
      await openEditing(tester, repo);
      await tester.enterText(_name, 'Mercado');
      await tester.tap(find.text('Activa'));
      await tester.pumpAndSettle();

      await tester.tap(_save);
      await showToast(tester);

      final draft = repo.savedCategories.single;
      expect(draft.id, 3);
      expect(draft.toJson().containsKey('tipo'), isFalse);
      expect(draft.toJson()['id_categoria'], 3);
      expect(draft.name, 'Mercado');
      expect(draft.active, isFalse);
      expect(find.text('Categoría actualizada'), findsOneWidget);
      await dismissToasts(tester);
      expect(find.byType(CategoryDialog), findsNothing);
      expect(find.text('Mercado'), findsOneWidget);
      expect(find.text('Alimentación'), findsNothing);
    });
  });

  group('errores y guardado en curso', () {
    testWidgets(
      'error: avisa con el mensaje, se queda abierto con lo escrito',
      (tester) async {
        final repo = _repo(
          save: (_) async => throw const ApiException(
            'Ya existe una categoría con ese nombre.',
            code: 'DUPLICADO',
            statusCode: 409,
          ),
        );
        await _pump(tester, repo);
        await tester.tap(_fab);
        await tester.pumpAndSettle();
        await tester.enterText(_name, 'Alimentación');

        await tester.tap(_save);
        await showToast(tester);

        expect(
          find.text('Ya existe una categoría con ese nombre.'),
          findsOneWidget,
        );
        expect(find.text('Categoría creada'), findsNothing);
        expect(find.byType(CategoryDialog), findsOneWidget);
        expect(
          tester.widget<TextFormField>(_name).controller!.text,
          'Alimentación',
        );
        expect(
          tester.widget<FilledButton>(_save).onPressed,
          isNotNull,
          reason: 'se puede reintentar',
        );
        await dismissToasts(tester);
      },
    );

    testWidgets('mientras guarda: botón con progreso, campos de solo lectura, '
        'y ni la X ni «Atrás» ni Cancelar cierran', (tester) async {
      final completer = Completer<Category>();
      final repo = _repo(save: (_) => completer.future);
      await _pump(tester, repo);
      await tester.tap(_fab);
      await tester.pumpAndSettle();
      await tester.enterText(_name, 'Mascotas');

      await tester.tap(_save);
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(tester.widget<FilledButton>(_save).onPressed, isNull);
      expect(
        tester
            .widget<EditableText>(
              find.descendant(of: _name, matching: find.byType(EditableText)),
            )
            .readOnly,
        isTrue,
      );
      // La X apagada.
      await tester.tap(find.byTooltip('Cerrar'), warnIfMissed: false);
      await tester.pump();
      expect(find.byType(CategoryDialog), findsOneWidget);
      // Atrás del sistema.
      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(find.byType(CategoryDialog), findsOneWidget);
      // Cancelar apagado.
      await tester.tap(find.text('Cancelar'), warnIfMissed: false);
      await tester.pump();
      expect(find.byType(CategoryDialog), findsOneWidget);
      // Sin doble envío.
      await tester.tap(_save, warnIfMissed: false);
      await tester.pump();
      expect(repo.savedCategories, hasLength(1));

      completer.complete(buildCategory(id: 50, name: 'Mascotas'));
      await showToast(tester);
      await dismissToasts(tester);
      expect(find.byType(CategoryDialog), findsNothing);
    });

    testWidgets('«Atrás» de la barra vuelve a la pantalla anterior', (
      tester,
    ) async {
      await _pump(tester, _repo());
      await tester.tap(find.byTooltip('Atrás'));
      await tester.pumpAndSettle();
      expect(find.text(previousScreenText), findsOneWidget);
    });
  });

  group('sin desbordes', () {
    testWidgets(
      'lista con nombres de 40+ caracteres en 320/390/800/1300 × teclado × texto 1.5',
      (tester) async {
        final repo = _repo(
          list: () async => [
            for (var i = 0; i < 12; i++)
              Category(
                id: i + 1,
                type: i.isEven ? MovementType.income : MovementType.expense,
                name: '$longCatalogName $i',
                isCapital: i % 3 == 0,
                active: i % 4 != 0,
              ),
          ],
        );
        await expectScreenNoOverflow(
          tester,
          screen: _screen,
          overrides: () => _overrides(repo),
        );
      },
    );

    testWidgets('vacío y error', (tester) async {
      await expectScreenNoOverflow(
        tester,
        screen: _screen,
        overrides: () => _overrides(_repo(list: () async => const [])),
      );
      await expectScreenNoOverflow(
        tester,
        screen: _screen,
        overrides: () => _overrides(
          _repo(
            list: () async =>
                throw NetworkException('Sin conexión con el servidor. ' * 6),
          ),
        ),
      );
    });

    testWidgets('sin permiso de catálogos (también se ve todo)', (
      tester,
    ) async {
      await expectScreenNoOverflow(
        tester,
        screen: _screen,
        overrides: () => _overrides(_repo(), canManage: false),
      );
    });

    testWidgets('diálogo «Nueva categoría» abierto con showDialog', (
      tester,
    ) async {
      await expectScreenNoOverflow(
        tester,
        screen: _screen,
        overrides: () => _overrides(_repo()),
        prepare: (tester) async {
          await tester.tap(_fab);
          await tester.pumpAndSettle();
          expect(find.byType(CategoryDialog), findsOneWidget);
        },
      );
    });

    testWidgets(
      'diálogo «Editar categoría» con nombre de 60 caracteres y error de validación',
      (tester) async {
        final repo = _repo(
          list: () async => [
            buildCategory(
              id: 3,
              name: 'x' * 59 + longCatalogName.substring(0, 1),
            ),
          ],
        );
        await expectScreenNoOverflow(
          tester,
          screen: _screen,
          overrides: () => _overrides(repo),
          prepare: (tester) async {
            await tester.tap(find.byType(ManageTile));
            await tester.pumpAndSettle();
            await tester.enterText(_name, '');
            await tester.tap(_save);
            await tester.pumpAndSettle();
            expect(find.byType(CategoryDialog), findsOneWidget);
          },
        );
      },
    );
  });
}
