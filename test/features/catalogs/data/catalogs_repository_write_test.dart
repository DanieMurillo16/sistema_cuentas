import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_cuentas/core/errors/app_exception.dart';
import 'package:sistema_cuentas/core/models/movement_type.dart';
import 'package:sistema_cuentas/core/network/api_endpoints.dart';
import 'package:sistema_cuentas/features/catalogs/data/catalogs_repository.dart';
import 'package:sistema_cuentas/features/catalogs/models/category_draft.dart';
import 'package:sistema_cuentas/features/catalogs/models/contact_draft.dart';
import 'package:sistema_cuentas/features/catalogs/models/payment_method_draft.dart';

import '../../../helpers/auth_fixtures.dart';
import '../../../helpers/movement_fixtures.dart';
import '../../../helpers/recurring_fixtures.dart';
import '../../../support/api_harness.dart';
import '../../../support/fake_api_adapter.dart';

ApiHarness _ok(Object? data) =>
    ApiHarness(FakeApiAdapter.json(successEnvelope(data)));

Matcher get _incomplete => throwsA(
  isA<UnexpectedException>().having(
    (e) => e.message,
    'message',
    startsWith('El servidor devolvió datos'),
  ),
);

void main() {
  group('las lecturas piden también los inactivos', () {
    test('categorías: incluir_inactivas=1', () async {
      final h = _ok({
        'categorias': [categoryJson(active: false)],
      });
      final items = await CatalogsRepository(h.api).categories();
      expect(h.single.method, 'GET');
      expect(h.single.options.queryParameters, {'incluir_inactivas': 1});
      expect(items.single.active, isFalse);
    });

    test('medios de pago: incluir_inactivos=1', () async {
      final h = _ok({
        'medios_pago': [methodJson(active: false)],
      });
      final items = await CatalogsRepository(h.api).paymentMethods();
      expect(h.single.options.queryParameters, {'incluir_inactivos': 1});
      expect(items.single.active, isFalse);
    });

    test('contactos: incluir_inactivos=1', () async {
      final h = _ok({
        'contactos': [contactJson(active: false)],
      });
      final items = await CatalogsRepository(h.api).contacts();
      expect(h.single.options.queryParameters, {'incluir_inactivos': 1});
      expect(items.single.active, isFalse);
    });
  });

  group('saveCategory', () {
    test('crear: POST con el tipo y sin id; devuelve la categoría', () async {
      final h = _ok({
        'categoria': categoryJson(id: 11, type: 'INGRESO', name: 'Salario'),
      });

      final saved = await CatalogsRepository(h.api).saveCategory(
        const CategoryDraft(
          type: MovementType.income,
          name: 'Salario',
          isCapital: false,
          active: true,
        ),
      );

      expect(h.single.method, 'POST');
      expect(h.single.path, ApiEndpoints.categorySave);
      expect(h.single.authorization, 'Bearer tok');
      expect(h.single.body, {
        'tipo': 'INGRESO',
        'nombre': 'Salario',
        'es_capital': false,
        'activo': true,
      });
      expect(saved.id, 11);
      expect(saved.type, MovementType.income);
    });

    test('editar: manda id_categoria y NO el tipo', () async {
      final h = _ok({'categoria': categoryJson(id: 3, active: false)});

      final saved = await CatalogsRepository(h.api).saveCategory(
        const CategoryDraft(
          id: 3,
          type: MovementType.expense,
          name: 'Alimentación',
          isCapital: false,
          active: false,
        ),
      );

      final body = h.single.body as Map;
      expect(body['id_categoria'], 3);
      expect(body.containsKey('tipo'), isFalse);
      expect(body['activo'], false);
      expect(saved.active, isFalse);
    });

    test('sin «categoria» en la respuesta: datos incompletos', () async {
      final h = _ok({'x': 1});
      await expectLater(
        CatalogsRepository(h.api).saveCategory(
          const CategoryDraft(
            type: MovementType.expense,
            name: 'x',
            isCapital: false,
            active: true,
          ),
        ),
        _incomplete,
      );
    });

    test('duplicado (409): mensaje del servidor en español', () async {
      final h = ApiHarness(
        FakeApiAdapter.json(
          errorEnvelope('DUPLICADO', 'Ya existe una categoría con ese nombre.'),
          status: 409,
        ),
      );
      await expectLater(
        CatalogsRepository(h.api).saveCategory(
          const CategoryDraft(
            type: MovementType.expense,
            name: 'Mercado',
            isCapital: false,
            active: true,
          ),
        ),
        throwsA(
          isA<ApiException>()
              .having((e) => e.code, 'code', 'DUPLICADO')
              .having(
                (e) => e.message,
                'message',
                'Ya existe una categoría con ese nombre.',
              ),
        ),
      );
    });
  });

  group('savePaymentMethod', () {
    test('crear: POST sin id; la respuesta viene en «medio_pago»', () async {
      final h = _ok({'medio_pago': methodJson(id: 8, name: 'Daviplata')});

      final saved = await CatalogsRepository(h.api).savePaymentMethod(
        const PaymentMethodDraft(name: 'Daviplata', active: true),
      );

      expect(h.single.method, 'POST');
      expect(h.single.path, ApiEndpoints.paymentMethodSave);
      expect(h.single.body, {'nombre': 'Daviplata', 'activo': true});
      expect(saved.id, 8);
      expect(saved.name, 'Daviplata');
    });

    test('editar: manda id_medio', () async {
      final h = _ok({'medio_pago': methodJson(id: 2, active: false)});
      await CatalogsRepository(h.api).savePaymentMethod(
        const PaymentMethodDraft(id: 2, name: 'Nequi', active: false),
      );
      expect(h.single.body, {
        'id_medio': 2,
        'nombre': 'Nequi',
        'activo': false,
      });
    });

    test('sin «medio_pago» y sin conexión', () async {
      await expectLater(
        CatalogsRepository(
          _ok({'medio': {}}).api,
        ).savePaymentMethod(const PaymentMethodDraft(name: 'x', active: true)),
        _incomplete,
      );
      await expectLater(
        CatalogsRepository(
          ApiHarness(FakeApiAdapter.connectionError()).api,
        ).savePaymentMethod(const PaymentMethodDraft(name: 'x', active: true)),
        throwsA(isA<NetworkException>()),
      );
    });
  });

  group('saveContact', () {
    test('crear sin opcionales: no manda teléfono ni nota', () async {
      final h = _ok({'contacto': contactJson(id: 6, name: 'Marta')});

      final saved = await CatalogsRepository(h.api)
          .saveContact(const ContactDraft(name: 'Marta', active: true));

      expect(h.single.method, 'POST');
      expect(h.single.path, ApiEndpoints.contactSave);
      expect(h.single.body, {'nombre': 'Marta', 'activo': true});
      expect(saved.id, 6);
    });

    test('editar con todo: id_contacto, teléfono y nota', () async {
      final h = _ok({
        'contacto': contactJson(id: 4, phone: '3001234567', note: 'ojo'),
      });

      final saved = await CatalogsRepository(h.api).saveContact(
        const ContactDraft(
          id: 4,
          name: 'Oscar',
          active: true,
          phone: '3001234567',
          note: 'ojo',
        ),
      );

      expect(h.single.body, {
        'id_contacto': 4,
        'nombre': 'Oscar',
        'activo': true,
        'telefono': '3001234567',
        'nota': 'ojo',
      });
      expect(saved.phone, '3001234567');
      expect(saved.note, 'ojo');
    });

    test('sin «contacto» y error de validación (422)', () async {
      await expectLater(
        CatalogsRepository(_ok({'x': 1}).api)
            .saveContact(const ContactDraft(name: 'x', active: true)),
        _incomplete,
      );
      final invalid = ApiHarness(
        FakeApiAdapter.json(
          errorEnvelope('VALIDACION', 'El teléfono no es válido.'),
          status: 422,
        ),
      );
      await expectLater(
        CatalogsRepository(
          invalid.api,
        ).saveContact(const ContactDraft(name: 'x', active: true, phone: '1')),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            'El teléfono no es válido.',
          ),
        ),
      );
    });
  });
}
