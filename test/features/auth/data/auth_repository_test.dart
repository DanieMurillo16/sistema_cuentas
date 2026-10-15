import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_cuentas/core/errors/app_exception.dart';
import 'package:sistema_cuentas/core/network/api_client.dart';
import 'package:sistema_cuentas/core/network/api_endpoints.dart';
import 'package:sistema_cuentas/features/auth/data/auth_repository.dart';

import '../../../helpers/auth_fixtures.dart';
import '../../../support/fake_api_adapter.dart';
import '../../../support/fake_token_storage.dart';

class _Harness {
  _Harness(this.adapter, {String? token}) : tokens = FakeTokenStorage(token) {
    final api = ApiClient(
      baseUrl: 'https://servidor.test/api/',
      tokenStorage: tokens,
      adapter: adapter,
      onUnauthorized: () async {
        unauthorizedCalls++;
        await tokens.clear();
      },
    );
    repository = AuthRepository(api, tokens);
  }

  final FakeApiAdapter adapter;
  final FakeTokenStorage tokens;
  late final AuthRepository repository;
  int unauthorizedCalls = 0;
}

Future<void> _expectAppException(
  Future<Object?> Function() action,
  Matcher matcher,
) async {
  await expectLater(action, throwsA(matcher));
}

void main() {
  group('login', () {
    test('envía usuario y clave a auth/login.php, guarda el token y devuelve la sesión', () async {
      final h = _Harness(
        FakeApiAdapter.json(successEnvelope(loginDataJson(token: 'tok-1'))),
      );

      final session = await h.repository.login(
        username: 'daniel',
        password: 'secreta-123',
      );

      expect(h.tokens.token, 'tok-1');
      expect(session.user.fullName, 'Daniel Murillo');
      expect(session.hasPermission('movimientos.registrar'), isTrue);
      final request = h.adapter.requests.single;
      expect(request.method, 'POST');
      expect(request.path, ApiEndpoints.login);
      expect(request.body, {'usuario': 'daniel', 'clave': 'secreta-123'});
      expect(request.authorization, isNull, reason: 'aún no hay token');
    });

    test('credenciales inválidas: mensaje del servidor en español, sin token guardado', () async {
      final h = _Harness(
        FakeApiAdapter.json(
          errorEnvelope('CREDENCIALES', 'Usuario o contraseña incorrectos.'),
          status: 401,
        ),
      );

      await _expectAppException(
        () => h.repository.login(username: 'daniel', password: 'mala'),
        isA<ApiException>()
            .having(
              (e) => e.message,
              'message',
              'Usuario o contraseña incorrectos.',
            )
            .having((e) => e.code, 'code', 'CREDENCIALES')
            .having((e) => e.statusCode, 'status', 401),
      );
      expect(h.tokens.token, isNull);
      expect(
        h.unauthorizedCalls,
        0,
        reason: 'un 401 del login (sin token enviado) no es sesión vencida',
      );
    });

    test('cuenta bloqueada (429): conserva el mensaje del servidor', () async {
      final h = _Harness(
        FakeApiAdapter.json(
          errorEnvelope('BLOQUEADO', 'Demasiados intentos. Espera 15 minutos.'),
          status: 429,
        ),
      );
      await _expectAppException(
        () => h.repository.login(username: 'daniel', password: 'x'),
        isA<ApiException>().having(
          (e) => e.message,
          'message',
          'Demasiados intentos. Espera 15 minutos.',
        ),
      );
    });

    test('sin conexión: NetworkException en español', () async {
      final h = _Harness(FakeApiAdapter.connectionError());
      await _expectAppException(
        () => h.repository.login(username: 'daniel', password: 'x'),
        isA<NetworkException>().having(
          (e) => e.message,
          'message',
          'No fue posible conectar con el servidor. Revisa tu conexión.',
        ),
      );
      expect(h.tokens.token, isNull);
    });

    test('ruta no instalada (404 sin JSON): mensaje propio', () async {
      final h = _Harness(FakeApiAdapter.json('no existe', status: 404));
      await _expectAppException(
        () => h.repository.login(username: 'daniel', password: 'x'),
        isA<ApiException>()
            .having((e) => e.code, 'code', 'RUTA_NO_INSTALADA')
            .having(
              (e) => e.message,
              'message',
              'La ruta solicitada no está instalada en el servidor.',
            ),
      );
    });

    test('respuesta sin token: UnexpectedException y nada guardado', () async {
      final data = loginDataJson()..remove('token');
      final h = _Harness(FakeApiAdapter.json(successEnvelope(data)));
      await _expectAppException(
        () => h.repository.login(username: 'daniel', password: 'x'),
        isA<UnexpectedException>().having(
          (e) => e.message,
          'message',
          'El servidor no entregó la sesión.',
        ),
      );
      expect(h.tokens.token, isNull);
    });

    test('token vacío se trata como sin token', () async {
      final h = _Harness(
        FakeApiAdapter.json(successEnvelope(loginDataJson(token: ''))),
      );
      await _expectAppException(
        () => h.repository.login(username: 'daniel', password: 'x'),
        isA<UnexpectedException>(),
      );
      expect(h.tokens.token, isNull);
    });

    test(
      'respuesta que no es un objeto JSON: UnexpectedException en español',
      () async {
        final h = _Harness(FakeApiAdapter.json('<html>'));
        await _expectAppException(
          () => h.repository.login(username: 'daniel', password: 'x'),
          isA<UnexpectedException>().having(
            (e) => e.message,
            'message',
            'El servidor devolvió una respuesta no válida.',
          ),
        );
      },
    );

    test(
      'success:false con 200 también es error con el mensaje del servidor',
      () async {
        final h = _Harness(
          FakeApiAdapter.json(errorEnvelope('X', 'Algo falló en el servidor.')),
        );
        await _expectAppException(
          () => h.repository.login(username: 'daniel', password: 'x'),
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            'Algo falló en el servidor.',
          ),
        );
      },
    );
  });

  group('fetchSession', () {
    test('GET auth/perfil.php con el Bearer del token guardado', () async {
      final h = _Harness(
        FakeApiAdapter.json(
          successEnvelope({
            'perfil': profileJson(fullName: 'Ana'),
            'permisos': ['catalogos.ver'],
          }),
        ),
        token: 'tok-guardado',
      );

      final session = await h.repository.fetchSession();

      expect(session.user.fullName, 'Ana');
      final request = h.adapter.requests.single;
      expect(request.method, 'GET');
      expect(request.path, ApiEndpoints.profile);
      expect(request.authorization, 'Bearer tok-guardado');
    });

    test('401 con token: avisa que la sesión venció (borra token) y lanza ApiException 401', () async {
      final h = _Harness(
        FakeApiAdapter.json(
          errorEnvelope('NO_AUTORIZADO', 'Sesión no válida.'),
          status: 401,
        ),
        token: 'viejo',
      );

      await _expectAppException(
        h.repository.fetchSession,
        isA<ApiException>().having((e) => e.statusCode, 'status', 401),
      );
      expect(h.unauthorizedCalls, 1);
      expect(h.tokens.token, isNull);
    });
  });

  group('logout', () {
    test('POST auth/logout.php y limpia el token', () async {
      final h = _Harness(
        FakeApiAdapter.json(successEnvelope({'mensaje': 'ok'})),
        token: 'tok',
      );

      await h.repository.logout();

      final request = h.adapter.requests.single;
      expect(request.method, 'POST');
      expect(request.path, ApiEndpoints.logout);
      expect(request.authorization, 'Bearer tok');
      expect(h.tokens.token, isNull);
    });

    test('sin red: no lanza y el token se limpia igual', () async {
      final h = _Harness(FakeApiAdapter.connectionError(), token: 'tok');

      await h.repository.logout();

      expect(h.tokens.token, isNull);
      expect(h.tokens.clearCalls, 1);
    });

    test(
      'con error del servidor (500): no lanza y el token se limpia',
      () async {
        final h = _Harness(
          FakeApiAdapter.json(
            errorEnvelope('ERROR', 'Error interno.'),
            status: 500,
          ),
          token: 'tok',
        );

        await h.repository.logout();

        expect(h.tokens.token, isNull);
      },
    );

    test('con 401 (token vencido): no lanza y el token se limpia', () async {
      final h = _Harness(
        FakeApiAdapter.json(
          errorEnvelope('NO_AUTORIZADO', 'Vencida.'),
          status: 401,
        ),
        token: 'tok',
      );

      await h.repository.logout();

      expect(h.tokens.token, isNull);
    });
  });

  group('hasStoredToken', () {
    test('false sin token y con token vacío; true con token', () async {
      expect(
        await _Harness(FakeApiAdapter.json({})).repository.hasStoredToken(),
        isFalse,
      );
      expect(
        await _Harness(
          FakeApiAdapter.json({}),
          token: '',
        ).repository.hasStoredToken(),
        isFalse,
      );
      expect(
        await _Harness(
          FakeApiAdapter.json({}),
          token: 'x',
        ).repository.hasStoredToken(),
        isTrue,
      );
    });
  });
}
