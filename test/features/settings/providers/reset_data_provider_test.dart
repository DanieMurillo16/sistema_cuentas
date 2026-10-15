import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_cuentas/core/errors/app_exception.dart';
import 'package:sistema_cuentas/features/settings/providers/reset_data_provider.dart';

import '../../../support/container_helpers.dart';
import '../../../support/fake_account_repository.dart';

ProviderContainer _container(FakeAccountRepository repo) {
  final container = makeContainer(overrides: [repo.asOverride]);
  keepAlive(container, [resetDataProvider]);
  return container;
}

void main() {
  test('en reposo el estado es false y no llama al servidor', () {
    final repo = FakeAccountRepository();
    final container = _container(repo);

    expect(container.read(resetDataProvider).value, isFalse);
    expect(repo.resetCalls, 0);
  });

  test('éxito: loading → true, con una sola llamada', () async {
    final done = Completer<void>();
    final repo = FakeAccountRepository(onReset: () => done.future);
    final container = _container(repo);

    final future = container.read(resetDataProvider.notifier).reset();
    expect(container.read(resetDataProvider).isLoading, isTrue);

    done.complete();
    await future;

    expect(container.read(resetDataProvider).value, isTrue);
    expect(repo.resetCalls, 1);
  });

  test(
    'error: AsyncError con el mensaje y puede reintentar con éxito',
    () async {
      var fail = true;
      final repo = FakeAccountRepository(
        onReset: () async {
          if (fail) throw const NetworkException('Sin conexión.');
        },
      );
      final container = _container(repo);
      final notifier = container.read(resetDataProvider.notifier);

      await notifier.reset();
      final failed = container.read(resetDataProvider);
      expect(failed.hasError, isTrue);
      expect(userErrorMessage(failed.error), 'Sin conexión.');
      expect(failed.value, isNot(true), reason: 'no queda como «borrado»');

      fail = false;
      await notifier.reset();
      expect(container.read(resetDataProvider).value, isTrue);
      expect(repo.resetCalls, 2);
    },
  );

  test('anti doble envío: con una petición en curso no manda otra', () async {
    final done = Completer<void>();
    final repo = FakeAccountRepository(onReset: () => done.future);
    final container = _container(repo);
    final notifier = container.read(resetDataProvider.notifier);

    final first = notifier.reset();
    await notifier.reset();
    await notifier.reset();
    expect(repo.resetCalls, 1);

    done.complete();
    await first;
    expect(repo.resetCalls, 1);
  });

  test(
    'sigue vivo mientras borra aunque nadie lo observe (keepAlive)',
    () async {
      final done = Completer<void>();
      final repo = FakeAccountRepository(onReset: () => done.future);
      // Sin keepAlive de prueba: solo el del notifier.
      final container = makeContainer(overrides: [repo.asOverride]);
      final notifier = container.read(resetDataProvider.notifier);

      final future = notifier.reset();
      await Future<void>.delayed(Duration.zero);
      done.complete();
      await future;

      expect(container.read(resetDataProvider).value, isTrue);
    },
  );
}
