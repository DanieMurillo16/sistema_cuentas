import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_cuentas/core/models/movement_type.dart';
import 'package:sistema_cuentas/core/models/session.dart';
import 'package:sistema_cuentas/core/theme/app_colors.dart';
import 'package:sistema_cuentas/core/utils/catalog_visuals.dart';
import 'package:sistema_cuentas/features/catalogs/categories_screen.dart';
import 'package:sistema_cuentas/features/catalogs/contacts_screen.dart';
import 'package:sistema_cuentas/features/catalogs/data/catalogs_repository.dart';
import 'package:sistema_cuentas/features/catalogs/models/category.dart';
import 'package:sistema_cuentas/features/catalogs/models/contact.dart';
import 'package:sistema_cuentas/features/catalogs/widgets/category_dialog.dart';
import 'package:sistema_cuentas/features/catalogs/widgets/contact_dialog.dart';
import 'package:sistema_cuentas/shared/utils/movement_type_style.dart';
import 'package:sistema_cuentas/shared/widgets/catalog_badge.dart';
import 'package:sistema_cuentas/shared/widgets/catalog_visual_field.dart';
import 'package:sistema_cuentas/shared/widgets/catalog_visual_sheet.dart';
import 'package:sistema_cuentas/shared/widgets/manage_tile.dart';

import '../../../helpers/movement_fixtures.dart';
import '../../../helpers/recurring_fixtures.dart';
import '../../../support/expect_screen_no_overflow.dart';
import '../../../support/fake_catalogs_repository.dart';
import '../../../support/pump_screen_app.dart';
import '../../../support/session_overrides.dart';

// Un nombre de 60 caracteres: el máximo que acepta el campo de categoría.
final _name60 = 'Servicios públicos domiciliarios del hogar y otros gastos'
    .padRight(60, 'x')
    .substring(0, 60);

List<Override> _overrides(FakeCatalogsRepository repo) => [
  ...sessionOverrides(
    permissions: {Permissions.registerMovements, Permissions.manageCatalogs},
  ).overrides,
  catalogsRepositoryProvider.overrideWithValue(repo),
];

Finder get _save => find.widgetWithText(FilledButton, 'Guardar');
Finder get _visualField => find.byType(CatalogVisualField);
Finder get _apply => find.widgetWithText(FilledButton, 'Aplicar');
Finder get _clear => find.widgetWithText(OutlinedButton, 'Quitar');
Finder _name(String label) => find.widgetWithText(TextFormField, label);
Finder _iconCell(String key) => find.byKey(ValueKey('catalog-icon-$key'));
Finder _colorCell(String hex) => find.byKey(ValueKey('catalog-color-$hex'));

Future<void> _pickIconAndColor(
  WidgetTester tester, {
  String icon = 'gasolina',
  String color = '#FB923C',
}) async {
  await _openSelector(tester);
  // Se busca por su nombre: la rejilla arma solo las celdas visibles.
  await tester.enterText(
    find.descendant(
      of: find.byType(CatalogVisualSheet),
      matching: find.byType(TextField),
    ),
    CatalogVisuals.option(icon)!.label,
  );
  await tester.pumpAndSettle();
  await tester.tap(_iconCell(icon));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Color'));
  await tester.pumpAndSettle();
  await tester.tap(_colorCell(color));
  await tester.pumpAndSettle();
  await tester.tap(_apply);
  await tester.pumpAndSettle();
}

/// El campo puede quedar fuera de vista en el cuerpo con scroll del diálogo.
Future<void> _openSelector(WidgetTester tester) async {
  await tester.ensureVisible(_visualField);
  await tester.pumpAndSettle();
  await tester.tap(_visualField);
  await tester.pumpAndSettle();
}

Future<void> _saveAndSettle(WidgetTester tester) async {
  await tester.tap(_save);
  await showToast(tester);
  await dismissToasts(tester);
}

/// Un servidor que respeta el contrato: lo omitido no cambia lo guardado.
FakeCatalogsRepository _categoriesRepo({List<Category>? items}) {
  final list =
      items ??
      [
        buildCategory(id: 3, name: 'Alimentación'),
        buildCategory(
          id: 4,
          name: 'Transporte',
          icon: 'carro',
          color: '#60A5FA',
        ),
      ];
  return FakeCatalogsRepository(
    onCategories: () async => list,
    onSaveCategory: (d) async {
      final before = list.where((c) => c.id == d.id).firstOrNull;
      return Category(
        id: d.id ?? 50,
        type: d.type,
        name: d.name,
        isCapital: d.isCapital,
        active: d.active,
        icon: d.visualChanged ? d.icon : before?.icon,
        color: d.visualChanged ? d.color : before?.color,
      );
    },
  );
}

FakeCatalogsRepository _contactsRepo({List<Contact>? items}) {
  final list =
      items ??
      [
        buildContact(id: 4, name: 'Oscar'),
        buildContact(id: 5, name: 'Marta', icon: 'empresa', color: '#818CF8'),
      ];
  return FakeCatalogsRepository(
    onContacts: () async => list,
    onSaveContact: (d) async {
      final before = list.where((c) => c.id == d.id).firstOrNull;
      return Contact(
        id: d.id ?? 50,
        name: d.name,
        active: d.active,
        phone: d.phone,
        note: d.note,
        icon: d.visualChanged ? d.icon : before?.icon,
        color: d.visualChanged ? d.color : before?.color,
      );
    },
  );
}

Future<void> _pumpCategories(
  WidgetTester tester,
  FakeCatalogsRepository repo,
) => pumpScreenApp(
  tester,
  screen: const CategoriesScreen(),
  overrides: _overrides(repo),
);

Future<void> _pumpContacts(WidgetTester tester, FakeCatalogsRepository repo) =>
    pumpScreenApp(
      tester,
      screen: const ContactsScreen(),
      overrides: _overrides(repo),
    );

ManageTile _tile(WidgetTester tester, String key) =>
    tester.widget<ManageTile>(find.byKey(ValueKey(key)));

void main() {
  group('CategoryDialog: lo que se envía', () {
    testWidgets(
      'crear SIN tocar el selector: el cuerpo no lleva icono ni color',
      (tester) async {
        final repo = _categoriesRepo();
        await _pumpCategories(tester, repo);
        await tester.tap(find.byTooltip('Nueva categoría'));
        await tester.pumpAndSettle();
        await tester.enterText(_name('Nombre'), 'Mascotas');

        await _saveAndSettle(tester);

        final draft = repo.savedCategories.single;
        expect(draft.visualChanged, isFalse);
        final body = draft.toJson();
        expect(body.containsKey('icono'), isFalse);
        expect(body.containsKey('color'), isFalse);
        expect(body['nombre'], 'Mascotas');
      },
    );

    testWidgets('crear ELIGIENDO icono y color: el cuerpo los incluye', (
      tester,
    ) async {
      final repo = _categoriesRepo();
      await _pumpCategories(tester, repo);
      await tester.tap(find.byTooltip('Nueva categoría'));
      await tester.pumpAndSettle();
      await tester.enterText(_name('Nombre'), 'Combustible');
      await _pickIconAndColor(tester);

      await _saveAndSettle(tester);

      final body = repo.savedCategories.single.toJson();
      expect(body['icono'], 'gasolina');
      expect(body['color'], '#FB923C');
      expect(body['tipo'], 'GASTO');
    });

    testWidgets('el campo del diálogo refleja lo elegido antes de guardar', (
      tester,
    ) async {
      await _pumpCategories(tester, _categoriesRepo());
      await tester.tap(find.byTooltip('Nueva categoría'));
      await tester.pumpAndSettle();
      expect(find.text('Toca para elegirlos'), findsOneWidget);

      await _pickIconAndColor(tester, icon: 'casa', color: '#34D399');

      expect(find.text('Toca para cambiarlos'), findsOneWidget);
      final badge = tester.widget<CatalogBadge>(
        find.descendant(of: _visualField, matching: find.byType(CatalogBadge)),
      );
      expect(badge.icon, Icons.home_rounded);
      expect(badge.color.toARGB32(), 0xFF34D399);
    });

    testWidgets('editar una con icono SIN tocar el selector: no los reenvía', (
      tester,
    ) async {
      final repo = _categoriesRepo();
      await _pumpCategories(tester, repo);
      await tester.tap(find.text('Transporte'));
      await tester.pumpAndSettle();
      await tester.enterText(_name('Nombre'), 'Transporte público');

      await _saveAndSettle(tester);

      final draft = repo.savedCategories.single;
      expect(draft.id, 4);
      expect(draft.toJson().containsKey('icono'), isFalse);
      expect(draft.toJson().containsKey('color'), isFalse);
      // El servidor conserva lo que tenía: la fila sigue con su icono y color.
      final tile = _tile(tester, 'category-4');
      expect(tile.icon, Icons.directions_car_rounded);
      expect(tile.tint?.toARGB32(), 0xFF60A5FA);
    });

    testWidgets(
      'editar y elegir otro icono: manda el nuevo y la fila lo pinta',
      (tester) async {
        final repo = _categoriesRepo();
        await _pumpCategories(tester, repo);
        await tester.tap(find.text('Transporte'));
        await tester.pumpAndSettle();
        await _pickIconAndColor(tester, icon: 'taxi', color: '#FACC15');

        await _saveAndSettle(tester);

        final body = repo.savedCategories.single.toJson();
        expect(body['id_categoria'], 4);
        expect(body['icono'], 'taxi');
        expect(body['color'], '#FACC15');
        final tile = _tile(tester, 'category-4');
        expect(tile.icon, Icons.local_taxi_rounded);
        expect(tile.tint?.toARGB32(), 0xFFFACC15);
        expect(repo.categoriesCalls, 1, reason: 'upsert, sin recargar');
      },
    );

    testWidgets(
      'editar y «Quitar»: manda null en ambas y la fila vuelve a la flecha',
      (tester) async {
        final repo = _categoriesRepo();
        await _pumpCategories(tester, repo);
        await tester.tap(find.text('Transporte'));
        await tester.pumpAndSettle();
        await _openSelector(tester);
        await tester.tap(_clear);
        await tester.pumpAndSettle();

        await _saveAndSettle(tester);

        final body = repo.savedCategories.single.toJson();
        expect(body.containsKey('icono'), isTrue);
        expect(body.containsKey('color'), isTrue);
        expect(body['icono'], isNull);
        expect(body['color'], isNull);
      },
    );

    testWidgets(
      'abrir el selector y cerrarlo sin aplicar no cuenta como cambio',
      (tester) async {
        final repo = _categoriesRepo();
        await _pumpCategories(tester, repo);
        await tester.tap(find.text('Transporte'));
        await tester.pumpAndSettle();
        await _openSelector(tester);
        await tester.tap(_iconCell('taxi'));
        await tester.pumpAndSettle();
        await tester.tapAt(const Offset(10, 10)); // fuera de la hoja
        await tester.pumpAndSettle();

        await _saveAndSettle(tester);

        expect(repo.savedCategories.single.visualChanged, isFalse);
        expect(
          repo.savedCategories.single.toJson().containsKey('icono'),
          isFalse,
        );
      },
    );

    testWidgets('el icono de respaldo del selector sigue al tipo (ingreso)', (
      tester,
    ) async {
      await _pumpCategories(tester, _categoriesRepo());
      await tester.tap(find.byTooltip('Nueva categoría'));
      await tester.pumpAndSettle();

      Icon badgeIcon() => tester.widget<Icon>(
        find.descendant(of: _visualField, matching: find.byType(Icon)).first,
      );
      expect(badgeIcon().icon, Icons.north_east_rounded);

      await tester.tap(find.text('Ingreso').last);
      await tester.pumpAndSettle();
      expect(badgeIcon().icon, Icons.south_west_rounded);
    });
  });

  group('ContactDialog: lo que se envía', () {
    testWidgets(
      'crear SIN tocar el selector: el cuerpo no lleva icono ni color',
      (tester) async {
        final repo = _contactsRepo();
        await _pumpContacts(tester, repo);
        await tester.tap(find.byTooltip('Nuevo contacto'));
        await tester.pumpAndSettle();
        await tester.enterText(_name('Nombre'), 'Lucía');

        await _saveAndSettle(tester);

        final draft = repo.savedContacts.single;
        expect(draft.visualChanged, isFalse);
        expect(draft.toJson().containsKey('icono'), isFalse);
        expect(draft.toJson().containsKey('color'), isFalse);
      },
    );

    testWidgets('crear ELIGIENDO: el cuerpo incluye icono, color y el resto', (
      tester,
    ) async {
      final repo = _contactsRepo();
      await _pumpContacts(tester, repo);
      await tester.tap(find.byTooltip('Nuevo contacto'));
      await tester.pumpAndSettle();
      await tester.enterText(_name('Nombre'), 'Lucía');
      await tester.enterText(_name('Teléfono (opcional)'), '3001234567');
      await _pickIconAndColor(tester, icon: 'persona', color: '#818CF8');

      await _saveAndSettle(tester);

      expect(repo.savedContacts.single.toJson(), {
        'nombre': 'Lucía',
        'activo': true,
        'telefono': '3001234567',
        'icono': 'persona',
        'color': '#818CF8',
      });
    });

    testWidgets('editar con icono SIN tocar el selector: no los reenvía', (
      tester,
    ) async {
      final repo = _contactsRepo();
      await _pumpContacts(tester, repo);
      await tester.tap(find.text('Marta'));
      await tester.pumpAndSettle();

      await _saveAndSettle(tester);

      final body = repo.savedContacts.single.toJson();
      expect(body['id_contacto'], 5);
      expect(body.containsKey('icono'), isFalse);
      expect(body.containsKey('color'), isFalse);
      expect(_tile(tester, 'contact-5').icon, Icons.business_rounded);
    });

    testWidgets('editar y «Quitar»: manda null y la fila vuelve a la persona', (
      tester,
    ) async {
      final repo = _contactsRepo();
      await _pumpContacts(tester, repo);
      await tester.tap(find.text('Marta'));
      await tester.pumpAndSettle();
      await _openSelector(tester);
      await tester.tap(_clear);
      await tester.pumpAndSettle();

      await _saveAndSettle(tester);

      final body = repo.savedContacts.single.toJson();
      expect(body['icono'], isNull);
      expect(body['color'], isNull);
      expect(body.containsKey('icono'), isTrue);
    });
  });

  group('las listas pintan el icono elegido (o el de respaldo)', () {
    testWidgets(
      'categorías: icono y color elegidos; sin ellos, flecha del tipo',
      (tester) async {
        await _pumpCategories(
          tester,
          _categoriesRepo(
            items: [
              buildCategory(
                id: 4,
                name: 'Transporte',
                icon: 'carro',
                color: '#60A5FA',
              ),
              buildCategory(id: 3, name: 'Alimentación'),
              buildCategory(id: 9, type: MovementType.income, name: 'Salario'),
              buildCategory(
                id: 10,
                name: 'Del futuro',
                icon: 'icono_nuevo',
                color: 'no-es-color',
              ),
            ],
          ),
        );

        final withVisual = _tile(tester, 'category-4');
        expect(withVisual.icon, Icons.directions_car_rounded);
        expect(withVisual.tint?.toARGB32(), 0xFF60A5FA);

        final expense = _tile(tester, 'category-3');
        expect(expense.icon, Icons.north_east_rounded);
        expect(expense.tint, MovementType.expense.color);

        final income = _tile(tester, 'category-9');
        expect(income.icon, Icons.south_west_rounded);
        expect(income.tint, MovementType.income.color);

        final unknown = _tile(tester, 'category-10');
        expect(unknown.icon, Icons.north_east_rounded);
        expect(unknown.tint, MovementType.expense.color);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('categorías: la insignia usa el color, y apagada se ve gris', (
      tester,
    ) async {
      await _pumpCategories(
        tester,
        _categoriesRepo(
          items: [
            buildCategory(
              id: 4,
              name: 'Activa',
              icon: 'carro',
              color: '#60A5FA',
            ),
            buildCategory(
              id: 5,
              name: 'Apagada',
              icon: 'carro',
              color: '#60A5FA',
              active: false,
            ),
          ],
        ),
      );

      CatalogBadge badgeOf(String key) => tester.widget<CatalogBadge>(
        find.descendant(
          of: find.byKey(ValueKey(key)),
          matching: find.byType(CatalogBadge),
        ),
      );
      expect(badgeOf('category-4').color.toARGB32(), 0xFF60A5FA);
      expect(badgeOf('category-4').icon, Icons.directions_car_rounded);
      expect(badgeOf('category-5').color, AppColors.muted);
      expect(badgeOf('category-5').icon, Icons.directions_car_rounded);
    });

    testWidgets(
      'contactos: icono y color elegidos; sin ellos, persona y acento',
      (tester) async {
        await _pumpContacts(tester, _contactsRepo());

        final chosen = _tile(tester, 'contact-5');
        expect(chosen.icon, Icons.business_rounded);
        expect(chosen.tint?.toARGB32(), 0xFF818CF8);

        final plain = _tile(tester, 'contact-4');
        expect(plain.icon, Icons.person_outline_rounded);
        expect(plain.tint, AppColors.accent);
      },
    );

    testWidgets(
      'contactos: un icono desconocido cae en la persona, sin fallar',
      (tester) async {
        await _pumpContacts(
          tester,
          _contactsRepo(
            items: [
              buildContact(id: 7, name: 'Rara', icon: '???', color: '#12'),
            ],
          ),
        );

        final tile = _tile(tester, 'contact-7');
        expect(tile.icon, Icons.person_outline_rounded);
        expect(tile.tint, AppColors.accent);
        expect(tester.takeException(), isNull);
      },
    );
  });

  group('el selector muestra el nombre de lo que se cambia', () {
    Finder inSheet(String text) => find.descendant(
      of: find.byType(CatalogVisualSheet),
      matching: find.text(text),
    );

    Future<void> openNewCategory(WidgetTester tester) async {
      await _pumpCategories(tester, _categoriesRepo());
      await tester.tap(find.byTooltip('Nueva categoría'));
      await tester.pumpAndSettle();
    }

    testWidgets('categoría editada: su nombre', (tester) async {
      await _pumpCategories(tester, _categoriesRepo());
      await tester.tap(find.text('Transporte'));
      await tester.pumpAndSettle();

      await _openSelector(tester);

      expect(inSheet('Transporte'), findsOneWidget);
    });

    testWidgets('categoría nueva sin nombre: «Nueva categoría»', (
      tester,
    ) async {
      await openNewCategory(tester);

      await _openSelector(tester);

      expect(inSheet('Nueva categoría'), findsOneWidget);
    });

    testWidgets('categoría nueva con el nombre recién tecleado', (
      tester,
    ) async {
      await openNewCategory(tester);
      await tester.enterText(_name('Nombre'), 'mascotas y veterinaria');

      await _openSelector(tester);

      expect(inSheet('Mascotas y veterinaria'), findsOneWidget);
      expect(inSheet('Nueva categoría'), findsNothing);
    });

    testWidgets('categoría con el nombre borrado o solo espacios: genérico', (
      tester,
    ) async {
      await _pumpCategories(tester, _categoriesRepo());
      await tester.tap(find.text('Transporte'));
      await tester.pumpAndSettle();
      await tester.enterText(_name('Nombre'), '   ');

      await _openSelector(tester);

      expect(inSheet('Nueva categoría'), findsOneWidget);
      expect(inSheet('Transporte'), findsNothing);
    });

    testWidgets('cambiar el nombre y reabrir: muestra el nuevo', (
      tester,
    ) async {
      await openNewCategory(tester);
      await tester.enterText(_name('Nombre'), 'Salud');
      await _openSelector(tester);
      await tester.tap(_apply);
      await tester.pumpAndSettle();

      await tester.enterText(_name('Nombre'), 'Educación');
      await _openSelector(tester);

      expect(inSheet('Educación'), findsOneWidget);
      expect(inSheet('Salud'), findsNothing);
    });

    testWidgets('contacto editado: su nombre', (tester) async {
      await _pumpContacts(tester, _contactsRepo());
      await tester.tap(find.text('Marta'));
      await tester.pumpAndSettle();

      await _openSelector(tester);

      expect(inSheet('Marta'), findsOneWidget);
    });

    testWidgets('contacto nuevo: «Nuevo contacto», luego el nombre tecleado', (
      tester,
    ) async {
      await _pumpContacts(tester, _contactsRepo());
      await tester.tap(find.byTooltip('Nuevo contacto'));
      await tester.pumpAndSettle();

      await _openSelector(tester);
      expect(inSheet('Nuevo contacto'), findsOneWidget);
      await tester.tap(_apply);
      await tester.pumpAndSettle();

      await tester.enterText(_name('Nombre'), 'lucía');
      await _openSelector(tester);
      expect(inSheet('Lucía'), findsOneWidget);
      expect(inSheet('Nuevo contacto'), findsNothing);
    });
  });

  group('sin desbordes: diálogos abiertos con showDialog y nombres largos', () {
    final longCategories = [
      buildCategory(id: 1, name: _name60, icon: 'gasolina', color: '#FB923C'),
      buildCategory(id: 2, name: longCatalogName),
    ];
    final longContacts = [
      buildContact(
        id: 1,
        name: longCatalogName,
        phone: '+57 (300) 123-4567 99',
        note: longDescription,
        icon: 'persona',
        color: '#818CF8',
      ),
      buildContact(id: 2, name: longCatalogName),
    ];

    testWidgets(
      'CategoryDialog editando una de 60 caracteres con icono y color',
      (tester) async {
        await expectScreenNoOverflow(
          tester,
          screen: const CategoriesScreen(),
          overrides: () => _overrides(_categoriesRepo(items: longCategories)),
          prepare: (tester) async {
            await tester.tap(find.byKey(const ValueKey('category-1')));
            await tester.pumpAndSettle();
            expect(find.byType(CategoryDialog), findsOneWidget);
          },
        );
      },
    );

    testWidgets('CategoryDialog nueva, escribiendo 60 caracteres', (
      tester,
    ) async {
      await expectScreenNoOverflow(
        tester,
        screen: const CategoriesScreen(),
        overrides: () => _overrides(_categoriesRepo(items: longCategories)),
        prepare: (tester) async {
          await tester.tap(find.byTooltip('Nueva categoría'));
          await tester.pumpAndSettle();
          await tester.enterText(_name('Nombre'), _name60);
          await tester.pumpAndSettle();
        },
      );
    });

    testWidgets('CategoryDialog con 60 caracteres tecleados y el selector '
        'abierto (el nombre sale en la hoja)', (tester) async {
      await expectScreenNoOverflow(
        tester,
        screen: const CategoriesScreen(),
        overrides: () => _overrides(_categoriesRepo(items: longCategories)),
        prepare: (tester) async {
          await tester.tap(find.byTooltip('Nueva categoría'));
          await tester.pumpAndSettle();
          await tester.enterText(_name('Nombre'), _name60);
          await _openSelector(tester);
          expect(_apply, findsOneWidget);
        },
      );
    });

    testWidgets('CategoryDialog con el selector abierto encima', (
      tester,
    ) async {
      await expectScreenNoOverflow(
        tester,
        screen: const CategoriesScreen(),
        overrides: () => _overrides(_categoriesRepo(items: longCategories)),
        prepare: (tester) async {
          await tester.tap(find.byKey(const ValueKey('category-1')));
          await tester.pumpAndSettle();
          await _openSelector(tester);
          expect(_apply, findsOneWidget);
        },
      );
    });

    testWidgets(
      'ContactDialog editando uno de nombre, nota y teléfono largos',
      (tester) async {
        await expectScreenNoOverflow(
          tester,
          screen: const ContactsScreen(),
          overrides: () => _overrides(_contactsRepo(items: longContacts)),
          prepare: (tester) async {
            await tester.tap(find.byKey(const ValueKey('contact-1')));
            await tester.pumpAndSettle();
            expect(find.byType(ContactDialog), findsOneWidget);
          },
        );
      },
    );

    testWidgets('ContactDialog con el selector abierto encima', (tester) async {
      await expectScreenNoOverflow(
        tester,
        screen: const ContactsScreen(),
        overrides: () => _overrides(_contactsRepo(items: longContacts)),
        prepare: (tester) async {
          await tester.tap(find.byKey(const ValueKey('contact-1')));
          await tester.pumpAndSettle();
          await _openSelector(tester);
          expect(_apply, findsOneWidget);
        },
      );
    });
  });

  group('sin desbordes: listas con nombres largos e iconos', () {
    testWidgets('categorías', (tester) async {
      await expectScreenNoOverflow(
        tester,
        screen: const CategoriesScreen(),
        overrides: () => _overrides(
          _categoriesRepo(
            items: [
              for (var i = 0; i < 10; i++)
                Category(
                  id: i + 1,
                  type: i.isEven ? MovementType.income : MovementType.expense,
                  name: '$longCatalogName $i',
                  isCapital: i % 3 == 0,
                  active: i % 4 != 0,
                  icon: i.isEven ? 'gasolina' : null,
                  color: i.isEven ? '#FB923C' : null,
                ),
            ],
          ),
        ),
      );
    });

    testWidgets('contactos', (tester) async {
      await expectScreenNoOverflow(
        tester,
        screen: const ContactsScreen(),
        overrides: () => _overrides(
          _contactsRepo(
            items: [
              for (var i = 0; i < 10; i++)
                buildContact(
                  id: i + 1,
                  name: '$longCatalogName $i',
                  phone: '3001234567',
                  active: i % 4 != 0,
                  icon: i.isEven ? 'persona' : null,
                  color: i.isEven ? '#818CF8' : null,
                ),
            ],
          ),
        ),
      );
    });
  });
}
