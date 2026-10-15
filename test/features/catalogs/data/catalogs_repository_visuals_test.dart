import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_cuentas/core/models/movement_type.dart';
import 'package:sistema_cuentas/core/network/api_endpoints.dart';
import 'package:sistema_cuentas/features/catalogs/data/catalogs_repository.dart';
import 'package:sistema_cuentas/features/catalogs/models/category_draft.dart';
import 'package:sistema_cuentas/features/catalogs/models/contact_draft.dart';

import '../../../helpers/auth_fixtures.dart';
import '../../../helpers/movement_fixtures.dart';
import '../../../helpers/recurring_fixtures.dart';
import '../../../support/api_harness.dart';
import '../../../support/fake_api_adapter.dart';

ApiHarness _ok(Object? data) =>
    ApiHarness(FakeApiAdapter.json(successEnvelope(data)));

CategoryDraft _category({
  String? icon,
  String? color,
  bool visualChanged = false,
}) => CategoryDraft(
  id: 3,
  type: MovementType.expense,
  name: 'Gasolina',
  isCapital: false,
  active: true,
  icon: icon,
  color: color,
  visualChanged: visualChanged,
);

ContactDraft _contact({
  String? icon,
  String? color,
  bool visualChanged = false,
}) => ContactDraft(
  id: 4,
  name: 'Oscar',
  active: true,
  icon: icon,
  color: color,
  visualChanged: visualChanged,
);

void main() {
  group('saveCategory: lo que viaja por la red', () {
    test('sin tocar el selector: el cuerpo no tiene icono ni color', () async {
      final h = _ok({'categoria': categoryJson(id: 3)});

      await CatalogsRepository(h.api)
          .saveCategory(_category(icon: 'gasolina', color: '#FB923C'));

      final body = h.single.body as Map;
      expect(h.single.path, ApiEndpoints.categorySave);
      expect(body.containsKey('icono'), isFalse);
      expect(body.containsKey('color'), isFalse);
    });

    test('al elegir: manda icono y color', () async {
      final h = _ok({
        'categoria': categoryJson(id: 3, icon: 'gasolina', color: '#FB923C'),
      });

      final saved = await CatalogsRepository(h.api).saveCategory(
        _category(icon: 'gasolina', color: '#FB923C', visualChanged: true),
      );

      final body = h.single.body as Map;
      expect(body['icono'], 'gasolina');
      expect(body['color'], '#FB923C');
      expect(saved.icon, 'gasolina');
      expect(saved.color, '#FB923C');
    });

    test('al quitar: manda null en ambas llaves', () async {
      final h = _ok({'categoria': categoryJson(id: 3)});

      final saved = await CatalogsRepository(h.api)
          .saveCategory(_category(visualChanged: true));

      final body = h.single.body as Map;
      expect(body.containsKey('icono'), isTrue);
      expect(body.containsKey('color'), isTrue);
      expect(body['icono'], isNull);
      expect(body['color'], isNull);
      expect(saved.icon, isNull);
    });

    test(
      'la respuesta de una versión vieja (sin icono) se lee igual',
      () async {
        final h = _ok({'categoria': categoryJson(id: 3)});

        final saved = await CatalogsRepository(h.api).saveCategory(_category());

        expect(saved.icon, isNull);
        expect(saved.color, isNull);
      },
    );
  });

  group('saveContact: lo que viaja por la red', () {
    test('sin tocar el selector: el cuerpo no tiene icono ni color', () async {
      final h = _ok({'contacto': contactJson(id: 4)});

      await CatalogsRepository(h.api)
          .saveContact(_contact(icon: 'persona', color: '#818CF8'));

      final body = h.single.body as Map;
      expect(h.single.path, ApiEndpoints.contactSave);
      expect(body.containsKey('icono'), isFalse);
      expect(body.containsKey('color'), isFalse);
    });

    test('al elegir: manda icono y color y devuelve lo guardado', () async {
      final h = _ok({
        'contacto': contactJson(id: 4, icon: 'persona', color: '#818CF8'),
      });

      final saved = await CatalogsRepository(h.api).saveContact(
        _contact(icon: 'persona', color: '#818CF8', visualChanged: true),
      );

      final body = h.single.body as Map;
      expect(body['icono'], 'persona');
      expect(body['color'], '#818CF8');
      expect(saved.icon, 'persona');
    });

    test('al quitar: manda null', () async {
      final h = _ok({'contacto': contactJson(id: 4)});

      await CatalogsRepository(h.api)
          .saveContact(_contact(visualChanged: true));

      final body = h.single.body as Map;
      expect(body['icono'], isNull);
      expect(body['color'], isNull);
      expect(body.containsKey('icono'), isTrue);
    });
  });

  group('lecturas con icono y color', () {
    test('categorías: los trae del servidor', () async {
      final h = _ok({
        'categorias': [
          categoryJson(id: 3, icon: 'comida', color: '#34D399'),
          categoryJson(id: 4, name: 'Transporte'),
        ],
      });

      final items = await CatalogsRepository(h.api).categories();

      expect(items.first.icon, 'comida');
      expect(items.first.color, '#34D399');
      expect(items.last.icon, isNull);
    });

    test('contactos: los trae del servidor', () async {
      final h = _ok({
        'contactos': [contactJson(icon: 'empresa', color: '#60A5FA')],
      });

      final items = await CatalogsRepository(h.api).contacts();

      expect(items.single.icon, 'empresa');
      expect(items.single.color, '#60A5FA');
    });
  });
}
