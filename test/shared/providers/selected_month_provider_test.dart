import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_cuentas/features/auth/data/auth_repository.dart';
import 'package:sistema_cuentas/shared/providers/selected_month_provider.dart';
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

DateTime get _thisMonth {
  final now = DateTime.now();
  return DateTime(now.year, now.month);
}

void main() {
  group('selectedMonthProvider', () {
    test('empieza en el mes actual (día 1)', () {
      final container = _container();
      expect(container.read(selectedMonthProvider), _thisMonth);
      expect(container.read(selectedMonthProvider).day, 1);
    });

    test('anterior retrocede de a un mes', () {
      final container = _container();
      container.read(selectedMonthProvider.notifier).previous();
      expect(
        container.read(selectedMonthProvider),
        DateTime(_thisMonth.year, _thisMonth.month - 1),
      );
    });

    test('anterior cruza el año hacia atrás sin romperse (13 meses)', () {
      final container = _container();
      for (var i = 0; i < 13; i++) {
        container.read(selectedMonthProvider.notifier).previous();
      }
      expect(
        container.read(selectedMonthProvider),
        DateTime(_thisMonth.year, _thisMonth.month - 13),
      );
      expect(container.read(selectedMonthProvider).day, 1);
    });

    test('siguiente avanza hasta el mes siguiente al actual', () {
      final container = _container();
      container.read(selectedMonthProvider.notifier).next();
      expect(
        container.read(selectedMonthProvider),
        DateTime(_thisMonth.year, _thisMonth.month + 1),
      );
    });

    test(
      'tope: no avanza más allá del mes siguiente por mucho que se insista',
      () {
        final container = _container();
        final notifier = container.read(selectedMonthProvider.notifier);
        for (var i = 0; i < 5; i++) {
          notifier.next();
        }
        expect(
          container.read(selectedMonthProvider),
          DateTime(_thisMonth.year, _thisMonth.month + 1),
        );
      },
    );

    test('desde un mes pasado se puede volver hasta el tope, no más', () {
      final container = _container();
      final notifier = container.read(selectedMonthProvider.notifier);
      for (var i = 0; i < 3; i++) {
        notifier.previous();
      }
      for (var i = 0; i < 10; i++) {
        notifier.next();
      }
      expect(
        container.read(selectedMonthProvider),
        DateTime(_thisMonth.year, _thisMonth.month + 1),
      );
    });

    test(
      'canGoNextMonthProvider: sí en el mes actual y pasados, no en el tope',
      () {
        final container = _container();
        final notifier = container.read(selectedMonthProvider.notifier);
        expect(container.read(canGoNextMonthProvider), isTrue);

        notifier.previous();
        expect(container.read(canGoNextMonthProvider), isTrue);

        notifier.next();
        notifier.next();
        expect(container.read(canGoNextMonthProvider), isFalse);
      },
    );

    test('al cambiar de cuenta vuelve al mes actual', () async {
      final container = _container();
      await container.read(sessionProvider.future);
      container.read(sessionProvider.notifier).open(buildSession(id: 1));
      container.read(selectedMonthProvider.notifier).previous();
      container.read(selectedMonthProvider.notifier).previous();
      expect(container.read(selectedMonthProvider), isNot(_thisMonth));

      container.read(sessionProvider.notifier).open(buildSession(id: 2));

      expect(container.read(selectedMonthProvider), _thisMonth);
    });

    test('cerrar sesión también reinicia el mes', () async {
      final container = _container();
      await container.read(sessionProvider.future);
      container.read(sessionProvider.notifier).open(buildSession());
      container.read(selectedMonthProvider.notifier).previous();

      await container.read(sessionProvider.notifier).signOut();

      expect(container.read(selectedMonthProvider), _thisMonth);
    });
  });
}
