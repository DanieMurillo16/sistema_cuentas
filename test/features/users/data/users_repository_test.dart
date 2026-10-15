import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_cuentas/core/errors/app_exception.dart';
import 'package:sistema_cuentas/core/network/api_endpoints.dart';
import 'package:sistema_cuentas/features/users/data/users_repository.dart';
import 'package:sistema_cuentas/features/users/models/user_draft.dart';

import '../../../helpers/auth_fixtures.dart';
import '../../../helpers/user_fixtures.dart';
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

const _draft = UserDraft(
  fullName: 'Ana María',
  username: 'ana.maria',
  password: 'una-clave-larga',
  isAdmin: true,
);

void main() {
  group('list', () {
    test(
      'GET usuarios/listar.php con el token y la lista de «usuarios»',
      () async {
        final h = _ok({
          'usuarios': [
            managedUserJson(id: 1, role: 'ADMINISTRADOR'),
            managedUserJson(id: 2, username: 'ana', active: false),
          ],
        });

        final users = await UsersRepository(h.api).list();

        expect(h.single.method, 'GET');
        expect(h.single.path, ApiEndpoints.usersList);
        expect(h.single.authorization, 'Bearer tok');
        expect(users.map((u) => u.id), [1, 2]);
        expect(users.first.isAdmin, isTrue);
        expect(users.last.active, isFalse);
      },
    );

    test('lista vacía es válida', () async {
      expect(
        await UsersRepository(_ok({'usuarios': <Object>[]}).api).list(),
        isEmpty,
      );
    });

    test('sin «usuarios» o con un usuario sin id: error propio', () async {
      await expectLater(UsersRepository(_ok({'x': 1}).api).list(), _incomplete);
      await expectLater(
        UsersRepository(
          _ok({
            'usuarios': [
              {'nombre_completo': 'x'},
            ],
          }).api,
        ).list(),
        throwsA(isA<UnexpectedException>()),
      );
    });

    test('403 sin permiso y sin conexión', () async {
      final forbidden = ApiHarness(
        FakeApiAdapter.json(
          errorEnvelope(
            'SIN_PERMISO',
            'No tienes permiso para gestionar usuarios.',
          ),
          status: 403,
        ),
      );
      await expectLater(
        UsersRepository(forbidden.api).list(),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'status', 403)
              .having(
                (e) => e.message,
                'message',
                'No tienes permiso para gestionar usuarios.',
              ),
        ),
      );
      await expectLater(
        UsersRepository(ApiHarness(FakeApiAdapter.connectionError()).api)
            .list(),
        throwsA(isA<NetworkException>()),
      );
    });
  });

  group('create', () {
    test('POST usuarios/crear.php con nombre, usuario, clave y rol', () async {
      final h = _ok({
        'usuario': managedUserJson(
          id: 9,
          fullName: 'Ana María',
          username: 'ana.maria',
          role: 'ADMINISTRADOR',
        ),
      });

      final user = await UsersRepository(h.api).create(_draft);

      expect(h.single.method, 'POST');
      expect(h.single.path, ApiEndpoints.userCreate);
      expect(h.single.body, {
        'nombre': 'Ana María',
        'usuario': 'ana.maria',
        'clave': 'una-clave-larga',
        'rol': 'ADMINISTRADOR',
      });
      expect(user.id, 9);
      expect(user.isAdmin, isTrue);
    });

    test('sin «usuario» en la respuesta: datos incompletos', () async {
      await expectLater(
        UsersRepository(_ok({'x': 1}).api).create(_draft),
        _incomplete,
      );
    });

    test('usuario repetido (409): mensaje del servidor en español', () async {
      final h = ApiHarness(
        FakeApiAdapter.json(
          errorEnvelope('DUPLICADO', 'Ese usuario ya existe.'),
          status: 409,
        ),
      );
      await expectLater(
        UsersRepository(h.api).create(_draft),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            'Ese usuario ya existe.',
          ),
        ),
      );
    });
  });

  group('setActive', () {
    test('POST usuarios/estado.php con id_usuario y activo', () async {
      final h = _ok({'usuario': managedUserJson(id: 2, active: false)});

      final user = await UsersRepository(h.api).setActive(2, active: false);

      expect(h.single.method, 'POST');
      expect(h.single.path, ApiEndpoints.userSetStatus);
      expect(h.single.body, {'id_usuario': 2, 'activo': false});
      expect(user.id, 2);
      expect(user.active, isFalse);
    });

    test('activar manda activo: true', () async {
      final h = _ok({'usuario': managedUserJson(id: 2)});
      await UsersRepository(h.api).setActive(2, active: true);
      expect((h.single.body as Map)['activo'], true);
    });

    test('sin «usuario» y error del servidor', () async {
      await expectLater(
        UsersRepository(_ok({'x': 1}).api).setActive(2, active: true),
        _incomplete,
      );
      final h = ApiHarness(
        FakeApiAdapter.json(
          errorEnvelope('VALIDACION', 'No puedes desactivarte a ti mismo.'),
          status: 422,
        ),
      );
      await expectLater(
        UsersRepository(h.api).setActive(1, active: false),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            'No puedes desactivarte a ti mismo.',
          ),
        ),
      );
    });
  });
}
