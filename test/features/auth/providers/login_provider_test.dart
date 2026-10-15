import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_cuentas/core/errors/app_exception.dart';
import 'package:sistema_cuentas/core/models/session.dart';
import 'package:sistema_cuentas/features/auth/data/auth_repository.dart';
import 'package:sistema_cuentas/features/auth/providers/login_provider.dart';
import 'package:sistema_cuentas/shared/providers/session_provider.dart';

import '../../../helpers/auth_fixtures.dart';
import '../../../support/fake_auth_repository.dart';

ProviderContainer _container(FakeAuthRepository repository) {
  final container = ProviderContainer(
    retry: (_, _) => null,
    overrides: [authRepositoryProvider.overrideWithValue(repository)],
  );
  addTearDown(container.dispose);
  return container;
}

/// `LoginNotifier.build` es `async`: el estado inicial es "cargando" hasta el
/// siguiente microtask. La pantalla toca el botón mucho después; aquí se espera.
Future<void> _ready(ProviderContainer container) =>
    container.read(loginProvider.future);

void main() {
  test('estado inicial: sin cargar y sin error', () async {
    final container = _container(FakeAuthRepository());
    container.listen(loginProvider, (_, _) {});
    await _ready(container);

    final state = container.read(loginProvider);
    expect(state.isLoading, isFalse);
    expect(state.hasError, isFalse);
  });

  test(
    'éxito: pasa por cargando, abre la sesión y termina sin error',
    () async {
      final completer = Completer<Session>();
      final repository = FakeAuthRepository(
        onLogin: (_, _) => completer.future,
      );
      final container = _container(repository);
      container.listen(loginProvider, (_, _) {});
      await _ready(container);
      await container.read(sessionProvider.future); // sin token → null
      expect(container.read(sessionProvider).value, isNull);

      final future = container
          .read(loginProvider.notifier)
          .signIn(username: 'daniel', password: 'secreta');
      expect(container.read(loginProvider).isLoading, isTrue);
      expect(container.read(sessionProvider).value, isNull, reason: 'aún no');

      completer.complete(buildSession());
      await future;

      expect(container.read(loginProvider).hasError, isFalse);
      expect(container.read(loginProvider).isLoading, isFalse);
      expect(container.read(sessionProvider).value?.user.username, 'daniel');
      expect(container.read(sessionUserIdProvider), 7);
    },
  );

  test(
    'el usuario se recorta (trim) y la contraseña se envía tal cual',
    () async {
      final repository = FakeAuthRepository(
        onLogin: (_, _) async => buildSession(),
      );
      final container = _container(repository);
      container.listen(loginProvider, (_, _) {});
      await _ready(container);

      await container
          .read(loginProvider.notifier)
          .signIn(username: '  daniel  ', password: ' con espacios ');

      expect(repository.lastUsername, 'daniel');
      expect(repository.lastPassword, ' con espacios ');
    },
  );

  test(
    'error: queda en AsyncError con el mensaje en español y NO abre sesión',
    () async {
      final repository = FakeAuthRepository(
        onLogin: (_, _) async => throw const ApiException(
          'Usuario o contraseña incorrectos.',
          code: 'CREDENCIALES',
          statusCode: 401,
        ),
      );
      final container = _container(repository);
      container.listen(loginProvider, (_, _) {});
      await _ready(container);
      await container.read(sessionProvider.future);

      await container
          .read(loginProvider.notifier)
          .signIn(username: 'daniel', password: 'mala');

      final state = container.read(loginProvider);
      expect(state.hasError, isTrue);
      expect(state.isLoading, isFalse);
      expect(
        userErrorMessage(state.error),
        'Usuario o contraseña incorrectos.',
      );
      expect(container.read(sessionProvider).value, isNull);
    },
  );

  test('error de red: mensaje de conexión', () async {
    final repository = FakeAuthRepository(
      onLogin: (_, _) async => throw const NetworkException(
        'No fue posible conectar con el servidor. Revisa tu conexión.',
      ),
    );
    final container = _container(repository);
    container.listen(loginProvider, (_, _) {});
    await _ready(container);

    await container
        .read(loginProvider.notifier)
        .signIn(username: 'daniel', password: 'x');

    expect(
      userErrorMessage(container.read(loginProvider).error),
      'No fue posible conectar con el servidor. Revisa tu conexión.',
    );
  });

  test(
    'anti doble envío: con una petición en curso la segunda se ignora',
    () async {
      final completer = Completer<Session>();
      final repository = FakeAuthRepository(
        onLogin: (_, _) => completer.future,
      );
      final container = _container(repository);
      container.listen(loginProvider, (_, _) {});
      await _ready(container);
      final notifier = container.read(loginProvider.notifier);

      final first = notifier.signIn(username: 'daniel', password: 'a');
      final second = notifier.signIn(username: 'daniel', password: 'a');
      await second;

      expect(repository.loginCalls, 1);
      completer.complete(buildSession());
      await first;
      expect(repository.loginCalls, 1);
      expect(container.read(sessionProvider).value, isNotNull);
    },
  );

  test('tras un error se puede reintentar y entrar', () async {
    var attempts = 0;
    final repository = FakeAuthRepository(
      onLogin: (_, _) async {
        attempts++;
        if (attempts == 1) throw const NetworkException('sin red');
        return buildSession();
      },
    );
    final container = _container(repository);
    container.listen(loginProvider, (_, _) {});
    await _ready(container);
    final notifier = container.read(loginProvider.notifier);

    await notifier.signIn(username: 'daniel', password: 'a');
    expect(container.read(loginProvider).hasError, isTrue);

    await notifier.signIn(username: 'daniel', password: 'a');

    expect(container.read(loginProvider).hasError, isFalse);
    expect(repository.loginCalls, 2);
    expect(container.read(sessionProvider).value, isNotNull);
  });

  test('sin nadie escuchando (la pantalla se va al abrir sesión) no falla por ref liberado', () async {
    final repository = FakeAuthRepository(
      onLogin: (_, _) async {
        await Future<void>.delayed(const Duration(milliseconds: 20));
        return buildSession();
      },
    );
    final container = _container(repository);
    await container.read(sessionProvider.future);
    await _ready(container);

    // Sin container.listen: el provider es autoDispose; keepAlive lo protege.
    await container
        .read(loginProvider.notifier)
        .signIn(username: 'daniel', password: 'a');

    expect(container.read(sessionProvider).value?.user.id, 7);
  });
}
