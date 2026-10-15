import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_cuentas/core/errors/app_exception.dart';
import 'package:sistema_cuentas/features/users/data/users_repository.dart';
import 'package:sistema_cuentas/features/users/models/managed_user.dart';
import 'package:sistema_cuentas/features/users/models/user_draft.dart';
import 'package:sistema_cuentas/features/users/providers/users_provider.dart';

import '../../../helpers/user_fixtures.dart';
import '../../../support/container_helpers.dart';
import '../../../support/fake_users_repository.dart';

const _draft = UserDraft(
  fullName: 'Ana María',
  username: 'ana.maria',
  password: 'una-clave-larga',
  isAdmin: false,
);

ProviderContainer _container(FakeUsersRepository repo) {
  final container = makeContainer(
    overrides: [usersRepositoryProvider.overrideWithValue(repo)],
  );
  keepAlive(container, [
    usersProvider,
    saveUserProvider,
    setUserActiveProvider,
  ]);
  return container;
}

void main() {
  group('usersProvider (lista compartida)', () {
    test('data: trae la lista del repositorio una sola vez', () async {
      final repo = FakeUsersRepository(
        onList: () async => [buildManagedUser(id: 1), buildManagedUser(id: 2)],
      );
      final container = _container(repo);

      final users = await container.read(usersProvider.future);

      expect(users.map((u) => u.id), [1, 2]);
      expect(repo.listCalls, 1);
    });

    test('loading: mientras llega, está cargando y sin valor', () {
      final repo = FakeUsersRepository(
        onList: () => Completer<List<ManagedUser>>().future,
      );
      final container = _container(repo);

      final state = container.read(usersProvider);

      expect(state.isLoading, isTrue);
      expect(state.hasValue, isFalse);
    });

    test('vacío: lista vacía es un dato válido', () async {
      final container = _container(FakeUsersRepository());
      expect(await container.read(usersProvider.future), isEmpty);
    });

    test('error: queda en error con el mensaje en español', () async {
      final container = _container(
        FakeUsersRepository(
          onList: () async => throw const ApiException(
            'No tienes permiso para gestionar usuarios.',
            code: 'SIN_PERMISO',
            statusCode: 403,
          ),
        ),
      );

      await expectLater(
        container.read(usersProvider.future),
        throwsA(isA<ApiException>()),
      );
      expect(
        userErrorMessage(container.read(usersProvider).error),
        'No tienes permiso para gestionar usuarios.',
      );
    });

    test(
      'invalidate vuelve a pedir y conserva la lista mientras llega',
      () async {
        final second = Completer<List<ManagedUser>>();
        var call = 0;
        final repo = FakeUsersRepository(
          onList: () => ++call == 1
              ? Future.value([buildManagedUser(id: 1)])
              : second.future,
        );
        final container = _container(repo);
        await container.read(usersProvider.future);

        container.invalidate(usersProvider);
        final reloading = container.read(usersProvider);

        expect(reloading.isLoading, isTrue);
        expect(reloading.requireValue.map((u) => u.id), [1]);
        second.complete([buildManagedUser(id: 1), buildManagedUser(id: 2)]);
        expect((await container.read(usersProvider.future)).length, 2);
      },
    );

    test('upsert reemplaza si existe y agrega si no', () async {
      final container = _container(
        FakeUsersRepository(
          onList: () async => [buildManagedUser(id: 1, fullName: 'Uno')],
        ),
      );
      await container.read(usersProvider.future);
      final notifier = container.read(usersProvider.notifier);

      notifier.upsert(buildManagedUser(id: 1, fullName: 'Uno editado'));
      notifier.upsert(buildManagedUser(id: 2, fullName: 'Dos'));

      expect(
        container.read(usersProvider).requireValue.map((u) => u.fullName),
        ['Uno editado', 'Dos'],
      );
    });

    test('upsert antes de cargar no hace nada', () {
      final container = _container(
        FakeUsersRepository(
          onList: () => Completer<List<ManagedUser>>().future,
        ),
      );
      container.read(usersProvider.notifier).upsert(buildManagedUser());
      expect(container.read(usersProvider).isLoading, isTrue);
      expect(container.read(usersProvider).hasValue, isFalse);
    });
  });

  group('saveUserProvider (alta)', () {
    test(
      'éxito: manda el borrador y la lista compartida muestra al nuevo',
      () async {
        final repo = FakeUsersRepository(
          onList: () async => [buildManagedUser(id: 1)],
          onCreate: (d) async => buildManagedUser(
            id: 9,
            fullName: d.fullName,
            username: d.username,
          ),
        );
        final container = _container(repo);
        await container.read(usersProvider.future);

        await container.read(saveUserProvider.notifier).save(_draft);

        expect(container.read(saveUserProvider).hasError, isFalse);
        expect(repo.created.single.username, 'ana.maria');
        expect(container.read(usersProvider).requireValue.map((u) => u.id), [
          1,
          9,
        ]);
        expect(repo.listCalls, 1, reason: 'upsert, no recarga la lista');
      },
    );

    test('error: mensaje en español y la lista no cambia', () async {
      final repo = FakeUsersRepository(
        onList: () async => [buildManagedUser(id: 1)],
        onCreate: (_) async => throw const ApiException(
          'Ese usuario ya existe.',
          code: 'DUPLICADO',
          statusCode: 409,
        ),
      );
      final container = _container(repo);
      await container.read(usersProvider.future);

      await container.read(saveUserProvider.notifier).save(_draft);

      final state = container.read(saveUserProvider);
      expect(state.hasError, isTrue);
      expect(userErrorMessage(state.error), 'Ese usuario ya existe.');
      expect(container.read(usersProvider).requireValue, hasLength(1));
    });

    test(
      'anti doble envío: con una petición en curso ignora la segunda',
      () async {
        final completer = Completer<ManagedUser>();
        final repo = FakeUsersRepository(
          onList: () async => [buildManagedUser(id: 1)],
          onCreate: (_) => completer.future,
        );
        final container = _container(repo);
        await container.read(usersProvider.future);
        final notifier = container.read(saveUserProvider.notifier);

        final first = notifier.save(_draft);
        await Future<void>.delayed(Duration.zero);
        expect(container.read(saveUserProvider).isLoading, isTrue);
        await notifier.save(_draft);
        expect(repo.createCalls, 1);

        completer.complete(buildManagedUser(id: 9));
        await first;
        expect(container.read(saveUserProvider).isLoading, isFalse);
      },
    );

    test('keepAlive: sin nadie observando termina y deja el upsert', () async {
      final completer = Completer<ManagedUser>();
      final repo = FakeUsersRepository(
        onList: () async => [buildManagedUser(id: 1)],
        onCreate: (_) => completer.future,
      );
      final container = makeContainer(
        overrides: [usersRepositoryProvider.overrideWithValue(repo)],
      );
      keepAlive(container, [usersProvider]); // el notifier de escritura NO
      await container.read(usersProvider.future);

      final done = container.read(saveUserProvider.notifier).save(_draft);
      for (var i = 0; i < 3; i++) {
        await Future<void>.delayed(Duration.zero);
      }
      completer.complete(buildManagedUser(id: 9));
      await done;

      expect(container.read(usersProvider).requireValue.map((u) => u.id), [
        1,
        9,
      ]);
    });
  });

  group('setUserActiveProvider', () {
    test(
      'éxito: manda (id, activo) y actualiza la fila en la lista compartida',
      () async {
        final repo = FakeUsersRepository(
          onList: () async => [
            buildManagedUser(id: 1),
            buildManagedUser(id: 2, fullName: 'Ana'),
          ],
          onSetActive: (id, active) async =>
              buildManagedUser(id: id, fullName: 'Ana', active: active),
        );
        final container = _container(repo);
        await container.read(usersProvider.future);

        await container
            .read(setUserActiveProvider.notifier)
            .setActive(2, active: false);

        expect(repo.activeChanges.single, (2, false));
        final users = container.read(usersProvider).requireValue;
        expect(users.firstWhere((u) => u.id == 2).active, isFalse);
        expect(users.firstWhere((u) => u.id == 1).active, isTrue);
        expect(repo.listCalls, 1);
      },
    );

    test('error: mensaje en español y el usuario sigue como estaba', () async {
      final repo = FakeUsersRepository(
        onList: () async => [buildManagedUser(id: 2)],
        onSetActive: (_, _) async => throw const NetworkException(
          'No fue posible conectar con el servidor. Revisa tu conexión.',
        ),
      );
      final container = _container(repo);
      await container.read(usersProvider.future);

      await container
          .read(setUserActiveProvider.notifier)
          .setActive(2, active: false);

      expect(
        userErrorMessage(container.read(setUserActiveProvider).error),
        'No fue posible conectar con el servidor. Revisa tu conexión.',
      );
      expect(container.read(usersProvider).requireValue.single.active, isTrue);
    });

    test('anti doble envío: la segunda llamada en curso se ignora', () async {
      final completer = Completer<ManagedUser>();
      final repo = FakeUsersRepository(
        onList: () async => [buildManagedUser(id: 2)],
        onSetActive: (_, _) => completer.future,
      );
      final container = _container(repo);
      await container.read(usersProvider.future);
      final notifier = container.read(setUserActiveProvider.notifier);

      final first = notifier.setActive(2, active: false);
      await Future<void>.delayed(Duration.zero);
      await notifier.setActive(2, active: false);
      expect(repo.setActiveCalls, 1);

      completer.complete(buildManagedUser(id: 2, active: false));
      await first;
    });
  });
}
