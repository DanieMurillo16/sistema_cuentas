import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_cuentas/core/errors/app_exception.dart';
import 'package:sistema_cuentas/core/models/movement_type.dart';
import 'package:sistema_cuentas/core/network/api_endpoints.dart';
import 'package:sistema_cuentas/features/catalogs/data/catalogs_repository.dart';

import '../../../helpers/auth_fixtures.dart';
import '../../../helpers/movement_fixtures.dart';
import '../../../helpers/recurring_fixtures.dart';
import '../../../support/api_harness.dart';
import '../../../support/fake_api_adapter.dart';

void main() {
  group('categories', () {
    test('trae las categorías de catalogos/categorias.php', () async {
      final h = ApiHarness(
        FakeApiAdapter.json(
          successEnvelope({
            'categorias': [
              categoryJson(id: 3, name: 'Alimentación'),
              categoryJson(id: 9, type: 'INGRESO', name: 'Salario'),
            ],
          }),
        ),
      );

      final items = await CatalogsRepository(h.api).categories();

      expect(h.single.path, ApiEndpoints.categories);
      expect(items.map((c) => c.name), ['Alimentación', 'Salario']);
      expect(items.last.type, MovementType.income);
    });

    test('lista vacía es válida', () async {
      final h = ApiHarness(
        FakeApiAdapter.json(successEnvelope({'categorias': <Object>[]})),
      );
      expect(await CatalogsRepository(h.api).categories(), isEmpty);
    });

    test('sin la clave «categorias»: error propio en español', () async {
      final h = ApiHarness(FakeApiAdapter.json(successEnvelope({'x': 1})));
      await expectLater(
        CatalogsRepository(h.api).categories(),
        throwsA(
          isA<UnexpectedException>().having(
            (e) => e.message,
            'message',
            'El servidor devolvió datos incompletos.',
          ),
        ),
      );
    });

    test('403 sin permiso: mensaje del servidor', () async {
      final h = ApiHarness(
        FakeApiAdapter.json(
          errorEnvelope('SIN_PERMISO', 'No tienes permiso para ver catálogos.'),
          status: 403,
        ),
      );
      await expectLater(
        CatalogsRepository(h.api).categories(),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            'No tienes permiso para ver catálogos.',
          ),
        ),
      );
    });
  });

  group('paymentMethods', () {
    test(
      'trae los medios de catalogos/medios.php (clave medios_pago)',
      () async {
        final h = ApiHarness(
          FakeApiAdapter.json(
            successEnvelope({
              'medios_pago': [
                methodJson(id: 2, name: 'Nequi'),
                methodJson(id: 5, name: 'Bancolombia'),
              ],
            }),
          ),
        );

        final items = await CatalogsRepository(h.api).paymentMethods();

        expect(h.single.path, ApiEndpoints.paymentMethods);
        expect(items.map((m) => m.id), [2, 5]);
      },
    );

    test('sin conexión y respuesta incompleta', () async {
      await expectLater(
        CatalogsRepository(ApiHarness(FakeApiAdapter.connectionError()).api)
            .paymentMethods(),
        throwsA(isA<NetworkException>()),
      );
      await expectLater(
        CatalogsRepository(
          ApiHarness(FakeApiAdapter.json(successEnvelope({'medios': []}))).api,
        ).paymentMethods(),
        throwsA(isA<UnexpectedException>()),
      );
    });
  });

  group('contacts', () {
    test(
      'trae los contactos de catalogos/contactos.php (clave contactos)',
      () async {
        final h = ApiHarness(
          FakeApiAdapter.json(
            successEnvelope({
              'contactos': [
                contactJson(id: 4, name: 'Oscar', phone: '3001234567'),
                contactJson(id: 5, name: 'Doña Marta', active: false),
              ],
            }),
          ),
        );

        final items = await CatalogsRepository(h.api).contacts();

        expect(h.single.method, 'GET');
        expect(h.single.path, ApiEndpoints.contacts);
        expect(h.single.authorization, 'Bearer tok');
        expect(items.map((c) => c.name), ['Oscar', 'Doña Marta']);
        expect(items.first.phone, '3001234567');
        expect(items.last.active, isFalse);
      },
    );

    test('lista vacía es válida', () async {
      final h = ApiHarness(
        FakeApiAdapter.json(successEnvelope({'contactos': <Object>[]})),
      );
      expect(await CatalogsRepository(h.api).contacts(), isEmpty);
    });

    test('sin la clave «contactos»: «datos incompletos»', () async {
      final h = ApiHarness(FakeApiAdapter.json(successEnvelope({'x': 1})));
      await expectLater(
        CatalogsRepository(h.api).contacts(),
        throwsA(
          isA<UnexpectedException>().having(
            (e) => e.message,
            'message',
            'El servidor devolvió datos incompletos.',
          ),
        ),
      );
    });

    test('un contacto sin nombre: error propio en español', () async {
      final h = ApiHarness(
        FakeApiAdapter.json(
          successEnvelope({
            'contactos': [
              {'id_contacto': 1},
            ],
          }),
        ),
      );
      await expectLater(
        CatalogsRepository(h.api).contacts(),
        throwsA(isA<UnexpectedException>()),
      );
    });

    test('403 y sin conexión', () async {
      await expectLater(
        CatalogsRepository(
          ApiHarness(
            FakeApiAdapter.json(
              errorEnvelope(
                'SIN_PERMISO',
                'No tienes permiso para ver contactos.',
              ),
              status: 403,
            ),
          ).api,
        ).contacts(),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            'No tienes permiso para ver contactos.',
          ),
        ),
      );
      await expectLater(
        CatalogsRepository(ApiHarness(FakeApiAdapter.connectionError()).api)
            .contacts(),
        throwsA(isA<NetworkException>()),
      );
    });
  });
}
