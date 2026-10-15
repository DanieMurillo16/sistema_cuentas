import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_cuentas/features/auth/data/auth_repository.dart';
import 'package:sistema_cuentas/shared/providers/balances_hidden_provider.dart';
import 'package:sistema_cuentas/shared/providers/session_provider.dart';

import '../../helpers/auth_fixtures.dart';
import '../../support/fake_auth_repository.dart';

ProviderContainer _container() {
  final container = ProviderContainer(
    retry: (_, _) => null,
    overrides: [authRepositoryProvider.overrideWithValue(FakeAuthRepository())],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  group('balancesHiddenProvider', () {
    test('empieza con las cifras visibles', () {
      expect(_container().read(balancesHiddenProvider), isFalse);
    });

    test('toggle alterna entre tapado y visible', () {
      final container = _container();
      final notifier = container.read(balancesHiddenProvider.notifier);

      notifier.toggle();
      expect(container.read(balancesHiddenProvider), isTrue);
      notifier.toggle();
      expect(container.read(balancesHiddenProvider), isFalse);
    });

    test('es una sola preferencia: dos lectores ven el mismo valor', () {
      final container = _container();
      final seen = <bool>[];
      container.listen(balancesHiddenProvider, (_, next) => seen.add(next));

      container.read(balancesHiddenProvider.notifier).toggle();

      expect(container.read(balancesHiddenProvider), isTrue);
      expect(seen, [true]);
    });

    test('otra cuenta que inicia sesión vuelve a ver las cifras', () async {
      final container = _container();
      await container.read(sessionProvider.future);
      container.read(sessionProvider.notifier).open(buildSession(id: 1));
      container.read(balancesHiddenProvider.notifier).toggle();
      expect(container.read(balancesHiddenProvider), isTrue);

      container.read(sessionProvider.notifier).open(buildSession(id: 2));

      expect(container.read(balancesHiddenProvider), isFalse);
    });

    test('cerrar sesión también destapa las cifras', () async {
      final container = _container();
      await container.read(sessionProvider.future);
      container.read(sessionProvider.notifier).open(buildSession());
      container.read(balancesHiddenProvider.notifier).toggle();

      await container.read(sessionProvider.notifier).signOut();

      expect(container.read(balancesHiddenProvider), isFalse);
    });
  });
}
