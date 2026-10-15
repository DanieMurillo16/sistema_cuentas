import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_cuentas/core/errors/app_exception.dart';
import 'package:sistema_cuentas/core/models/session.dart';
import 'package:sistema_cuentas/core/services/session_expiration.dart';
import 'package:sistema_cuentas/features/auth/data/auth_repository.dart';
import 'package:sistema_cuentas/shared/providers/session_provider.dart';

import '../../helpers/auth_fixtures.dart';
import '../../support/fake_auth_repository.dart';

ProviderContainer _container(
  FakeAuthRepository repository, {
  bool retry = false,
}) {
  final container = ProviderContainer(
    // Sin reintentos automáticos de Riverpod 3: el estado de error es
    // determinista. El caso con reintento por defecto se prueba aparte.
    retry: retry ? null : (_, _) => null,
    overrides: <Override>[authRepositoryProvider.overrideWithValue(repository)],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  group('arranque', () {
    test('sin token guardado: sesión null y no consulta el perfil', () async {
      final repository = FakeAuthRepository(storedToken: false);
      final container = _container(repository);

      expect(await container.read(sessionProvider.future), isNull);
      expect(repository.fetchSessionCalls, 0);
      expect(container.read(sessionUserIdProvider), isNull);
    });

    test('mientras recupera la sesión está cargando', () async {
      final repository = FakeAuthRepository(
        storedToken: true,
        onFetchSession: () async => buildSession(),
      );
      final container = _container(repository);

      expect(container.read(sessionProvider).isLoading, isTrue);
      await container.read(sessionProvider.future);
    });

    test('token válido: abre la sesión con perfil y permisos', () async {
      final session = buildSession(permissions: {'catalogos.ver'});
      final repository = FakeAuthRepository(
        storedToken: true,
        onFetchSession: () async => session,
      );
      final container = _container(repository);

      expect(await container.read(sessionProvider.future), same(session));
      expect(container.read(sessionUserIdProvider), 7);
      expect(repository.fetchSessionCalls, 1);
    });

    test('401 (token vencido): sesión null, no error', () async {
      final repository = FakeAuthRepository(
        storedToken: true,
        onFetchSession: () async => throw const ApiException(
          'Sesión no válida.',
          code: 'NO_AUTORIZADO',
          statusCode: 401,
        ),
      );
      final container = _container(repository);

      expect(await container.read(sessionProvider.future), isNull);
      expect(container.read(sessionProvider).hasError, isFalse);
    });

    test('error de red: estado de error con el mensaje, sin cerrar sesión ni limpiar el token', () async {
      final repository = FakeAuthRepository(
        storedToken: true,
        onFetchSession: () async =>
            throw const NetworkException('No fue posible conectar.'),
      );
      final container = _container(repository);

      await expectLater(
        container.read(sessionProvider.future),
        throwsA(isA<NetworkException>()),
      );

      final state = container.read(sessionProvider);
      expect(state.hasError, isTrue);
      expect(userErrorMessage(state.error), 'No fue posible conectar.');
      expect(repository.logoutCalls, 0, reason: 'no se cierra la sesión');
      expect(repository.storedToken, isTrue, reason: 'el token sigue guardado');
    });

    test(
      'error 500 del servidor también es error (no se confunde con 401)',
      () async {
        final repository = FakeAuthRepository(
          storedToken: true,
          onFetchSession: () async =>
              throw const ApiException('Error interno.', statusCode: 500),
        );
        final container = _container(repository);

        await expectLater(
          container.read(sessionProvider.future),
          throwsA(isA<ApiException>()),
        );
        expect(container.read(sessionProvider).hasError, isTrue);
      },
    );

    test('tras un error de red, invalidar (Intentar nuevamente) recupera la sesión', () async {
      var online = false;
      final repository = FakeAuthRepository(
        storedToken: true,
        onFetchSession: () async {
          if (!online) throw const NetworkException('sin red');
          return buildSession();
        },
      );
      final container = _container(repository);
      await expectLater(
        container.read(sessionProvider.future),
        throwsA(isA<NetworkException>()),
      );

      online = true;
      container.invalidate(sessionProvider);
      final session = await container.read(sessionProvider.future);

      expect(session?.user.id, 7);
      expect(container.read(sessionProvider).hasError, isFalse);
    });

    test('con el reintento por defecto de Riverpod el error sigue visible (hasError) para el splash', () async {
      final repository = FakeAuthRepository(
        storedToken: true,
        onFetchSession: () async => throw const NetworkException('sin red'),
      );
      final container = _container(repository, retry: true);
      container.listen(sessionProvider, (_, _) {});

      await Future<void>.delayed(const Duration(milliseconds: 50));

      final state = container.read(sessionProvider);
      expect(state.hasError, isTrue);
      expect(userErrorMessage(state.error), 'sin red');
    });
  });

  group('open / signOut / expiración', () {
    Future<ProviderContainer> signedIn(FakeAuthRepository repository) async {
      final container = _container(repository);
      await container.read(sessionProvider.future);
      container.read(sessionProvider.notifier).open(buildSession());
      return container;
    }

    test('open deja la sesión disponible para toda la app', () async {
      final container = await signedIn(FakeAuthRepository());

      expect(
        container.read(sessionProvider).value?.user.fullName,
        'Daniel Murillo',
      );
      expect(container.read(sessionUserIdProvider), 7);
    });

    test(
      'signOut cierra en el servidor/equipo y deja la sesión en null',
      () async {
        final repository = FakeAuthRepository();
        final container = await signedIn(repository);

        await container.read(sessionProvider.notifier).signOut();

        expect(repository.logoutCalls, 1);
        expect(container.read(sessionProvider).value, isNull);
        expect(container.read(sessionProvider).hasError, isFalse);
        expect(container.read(sessionUserIdProvider), isNull);
      },
    );

    test('sessionExpirationProvider.notify() cierra la sesión', () async {
      final repository = FakeAuthRepository();
      final container = await signedIn(repository);
      expect(container.read(sessionProvider).value, isA<Session>());

      container.read(sessionExpirationProvider.notifier).notify();

      expect(container.read(sessionProvider).value, isNull);
      expect(container.read(sessionProvider).hasError, isFalse);
      expect(
        repository.logoutCalls,
        0,
        reason: 'el token ya lo limpió el ApiClient',
      );
    });

    test('la caducidad del catálogo NO cierra la sesión', () async {
      final container = await signedIn(FakeAuthRepository());

      container.read(catalogExpirationProvider.notifier).notify();

      expect(container.read(sessionProvider).value, isNotNull);
    });

    test('sessionUserIdProvider solo notifica cuando cambia el id', () async {
      final container = await signedIn(FakeAuthRepository());
      final ids = <int?>[];
      container.listen(sessionUserIdProvider, (_, next) => ids.add(next));

      // Misma persona, otro objeto Session (p. ej. se refrescan permisos).
      container
          .read(sessionProvider.notifier)
          .open(buildSession(permissions: {'x.y'}));
      await container.read(sessionProvider.notifier).signOut();
      await Future<void>.delayed(Duration.zero);

      expect(ids, [null]);
    });
  });
}
