import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_cuentas/features/auth/data/auth_repository.dart';
import 'package:sistema_cuentas/shared/providers/balances_hidden_provider.dart';
import 'package:sistema_cuentas/shared/providers/hidden_sections_provider.dart';
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
  group('nombres de las secciones', () {
    test('la tarjeta de balance tiene su nombre fijo', () {
      expect(HiddenSections.balanceCard, 'balance-card');
    });

    test('un día se identifica por su fecha (AAAA-MM-DD), sin la hora', () {
      expect(HiddenSections.day(DateTime(2026, 10, 14)), 'day-2026-10-14');
      expect(
        HiddenSections.day(DateTime(2026, 10, 14, 23, 59)),
        'day-2026-10-14',
      );
      expect(
        HiddenSections.day(DateTime(2026, 10, 14)),
        isNot(HiddenSections.day(DateTime(2026, 10, 15))),
      );
    });
  });

  group('hiddenSectionsProvider', () {
    test('empieza sin nada tapado', () {
      expect(_container().read(hiddenSectionsProvider), isEmpty);
    });

    test('toggle tapa una sección y otro toggle la destapa', () {
      final container = _container();
      final notifier = container.read(hiddenSectionsProvider.notifier);

      notifier.toggle(HiddenSections.balanceCard);
      expect(container.read(hiddenSectionsProvider), {'balance-card'});

      notifier.toggle(HiddenSections.balanceCard);
      expect(container.read(hiddenSectionsProvider), isEmpty);
    });

    test('las secciones son independientes entre sí', () {
      final container = _container();
      final notifier = container.read(hiddenSectionsProvider.notifier);
      final today = HiddenSections.day(DateTime(2026, 10, 14));
      final yesterday = HiddenSections.day(DateTime(2026, 10, 13));

      notifier
        ..toggle(HiddenSections.balanceCard)
        ..toggle(today);
      expect(container.read(hiddenSectionsProvider), {'balance-card', today});

      notifier.toggle(today);
      expect(container.read(hiddenSectionsProvider), {'balance-card'});
      expect(
        container.read(hiddenSectionsProvider),
        isNot(contains(yesterday)),
      );
    });

    test('el estado es inmutable: cambiar uno no altera la lista anterior', () {
      final container = _container();
      final notifier = container.read(hiddenSectionsProvider.notifier);
      notifier.toggle('a');
      final before = container.read(hiddenSectionsProvider);

      notifier.toggle('b');

      expect(before, {'a'});
      expect(container.read(hiddenSectionsProvider), {'a', 'b'});
    });

    test('otra cuenta que inicia sesión empieza con todo visible', () async {
      final container = _container();
      await container.read(sessionProvider.future);
      container.read(sessionProvider.notifier).open(buildSession(id: 1));
      container.read(hiddenSectionsProvider.notifier).toggle('balance-card');
      expect(container.read(hiddenSectionsProvider), isNotEmpty);

      container.read(sessionProvider.notifier).open(buildSession(id: 2));

      expect(container.read(hiddenSectionsProvider), isEmpty);
    });

    test('cerrar sesión también reinicia', () async {
      final container = _container();
      await container.read(sessionProvider.future);
      container.read(sessionProvider.notifier).open(buildSession());
      container.read(hiddenSectionsProvider.notifier).toggle('balance-card');

      await container.read(sessionProvider.notifier).signOut();

      expect(container.read(hiddenSectionsProvider), isEmpty);
    });
  });

  group('sectionHiddenProvider (global || local)', () {
    test('sin nada tapado, nada está tapado', () {
      final container = _container();
      expect(
        container.read(sectionHiddenProvider(HiddenSections.balanceCard)),
        isFalse,
      );
    });

    test('tapar una sección solo tapa esa', () {
      final container = _container();
      container.read(hiddenSectionsProvider.notifier).toggle('balance-card');

      expect(container.read(sectionHiddenProvider('balance-card')), isTrue);
      expect(container.read(sectionHiddenProvider('day-2026-10-14')), isFalse);
    });

    test('el ojo global tapa todas, aunque no se hayan tapado solas', () {
      final container = _container();
      container.read(balancesHiddenProvider.notifier).toggle();

      expect(container.read(sectionHiddenProvider('balance-card')), isTrue);
      expect(container.read(sectionHiddenProvider('day-2026-10-14')), isTrue);
      expect(container.read(sectionHiddenProvider('cualquier-otra')), isTrue);
    });

    test('al destapar el global vuelve a mandar cada sección', () {
      final container = _container();
      container.read(hiddenSectionsProvider.notifier).toggle('balance-card');
      final global = container.read(balancesHiddenProvider.notifier);

      global.toggle();
      expect(container.read(sectionHiddenProvider('day-2026-10-14')), isTrue);

      global.toggle();
      expect(container.read(sectionHiddenProvider('balance-card')), isTrue);
      expect(container.read(sectionHiddenProvider('day-2026-10-14')), isFalse);
    });

    test('avisa a quien escucha cuando cambia la sección', () async {
      final container = _container();
      final seen = <bool>[];
      container.listen(
        sectionHiddenProvider('balance-card'),
        (_, next) => seen.add(next),
      );

      final notifier = container.read(hiddenSectionsProvider.notifier);
      notifier.toggle('balance-card');
      await container.pump();
      notifier.toggle('otra');
      await container.pump();
      notifier.toggle('balance-card');
      await container.pump();

      expect(seen, [true, false], reason: 'tapar otra no avisa');
    });
  });
}
