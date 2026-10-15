import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_cuentas/core/errors/app_exception.dart';
import 'package:sistema_cuentas/core/models/movement_type.dart';
import 'package:sistema_cuentas/features/dues/data/dues_repository.dart';
import 'package:sistema_cuentas/features/dues/models/dues_month.dart';
import 'package:sistema_cuentas/features/dues/providers/dues_provider.dart';
import 'package:sistema_cuentas/features/dues/utils/dues_rules.dart';
import 'package:sistema_cuentas/shared/providers/selected_month_provider.dart';

import '../../../helpers/recurring_fixtures.dart';
import '../../../support/container_helpers.dart';
import '../../../support/fake_dues_repository.dart';

ProviderContainer _container(FakeDuesRepository repository) {
  final container = makeContainer(
    overrides: [duesRepositoryProvider.overrideWithValue(repository)],
  );
  keepAlive(container, [duesProvider, visibleDuesProvider]);
  return container;
}

DateTime get _thisMonth {
  final now = DateTime.now();
  return DateTime(now.year, now.month);
}

void main() {
  group('duesProvider', () {
    test(
      'pide el mes elegido en la cabecera (el actual por defecto)',
      () async {
        final repository = FakeDuesRepository(
          (_) async => buildDuesMonth([buildDue(id: 1), buildDue(id: 2)]),
        );
        final container = _container(repository);

        final month = await container.read(duesProvider.future);

        expect(month.dues.map((d) => d.id), [1, 2]);
        expect(repository.months, [_thisMonth]);
      },
    );

    test(
      'cargando: AsyncLoading sin datos hasta que llega la respuesta',
      () async {
        final completer = Completer<DuesMonth>();
        final repository = FakeDuesRepository((_) => completer.future);
        final container = _container(repository);

        expect(container.read(duesProvider).isLoading, isTrue);
        expect(container.read(duesProvider).hasValue, isFalse);

        completer.complete(buildDuesMonth([buildDue()]));
        await container.read(duesProvider.future);
        expect(container.read(duesProvider).isLoading, isFalse);
      },
    );

    test('error: AsyncError con el mensaje en español', () async {
      final repository = FakeDuesRepository(
        (_) async =>
            throw const NetworkException('Sin conexión con el servidor.'),
      );
      final container = _container(repository);

      await expectLater(
        container.read(duesProvider.future),
        throwsA(isA<NetworkException>()),
      );

      final state = container.read(duesProvider);
      expect(state.hasError, isTrue);
      expect(userErrorMessage(state.error), 'Sin conexión con el servidor.');
    });

    test(
      'mes vacío: datos sin vencimientos (es un caso, no un error)',
      () async {
        final container = _container(FakeDuesRepository());
        final month = await container.read(duesProvider.future);
        expect(month.dues, isEmpty);
        expect(container.read(duesProvider).hasError, isFalse);
        expect(container.read(visibleDuesProvider).requireValue, isEmpty);
      },
    );

    test(
      'cambiar de mes pide ese mes y conserva los datos mientras llega',
      () async {
        final october = Completer<DuesMonth>();
        final september = Completer<DuesMonth>();
        final repository = FakeDuesRepository((month) {
          if (month == _thisMonth) return october.future;
          return september.future;
        });
        final container = _container(repository);
        october.complete(buildDuesMonth([buildDue(id: 1)]));
        await container.read(duesProvider.future);

        container.read(selectedMonthProvider.notifier).previous();
        await Future<void>.delayed(Duration.zero);

        final loading = container.read(duesProvider);
        expect(loading.isLoading, isTrue);
        expect(loading.hasValue, isTrue, reason: 'no se vacía la pantalla');
        expect(loading.requireValue.dues.single.id, 1);
        expect(
          container.read(visibleDuesProvider).requireValue.single.id,
          1,
          reason: 'la lista derivada también conserva lo que se ve',
        );

        september.complete(buildDuesMonth([buildDue(id: 2)]));
        final next = await container.read(duesProvider.future);
        expect(next.dues.single.id, 2);
        expect(repository.months, [
          _thisMonth,
          DateTime(_thisMonth.year, _thisMonth.month - 1),
        ]);
      },
    );

    test('volver al mes siguiente (tope) pide el mes que viene', () async {
      final repository = FakeDuesRepository();
      final container = _container(repository);
      await container.read(duesProvider.future);

      container.read(selectedMonthProvider.notifier).next();
      await container.read(duesProvider.future);

      expect(
        repository.months.last,
        DateTime(_thisMonth.year, _thisMonth.month + 1),
      );
    });

    test(
      'si el mes nuevo falla, queda el error (no se oculta un fallo)',
      () async {
        var fail = false;
        final repository = FakeDuesRepository((_) async {
          if (fail) throw const NetworkException('Sin conexión.');
          return buildDuesMonth([buildDue()]);
        });
        final container = _container(repository);
        await container.read(duesProvider.future);

        fail = true;
        container.read(selectedMonthProvider.notifier).previous();
        await expectLater(
          container.read(duesProvider.future),
          throwsA(isA<NetworkException>()),
        );

        final state = container.read(duesProvider);
        // En Riverpod 3 un AsyncError conserva el valor anterior: `hasValue`
        // sigue en true, así que solo `hasError` dice que falló.
        expect(state.hasError, isTrue);
        expect(state.isLoading, isFalse);
        expect(userErrorMessage(state.error), 'Sin conexión.');
      },
    );

    test('invalidate vuelve a pedir el mismo mes (reintento)', () async {
      final repository = FakeDuesRepository();
      final container = _container(repository);
      await container.read(duesProvider.future);

      container.invalidate(duesProvider);
      await container.read(duesProvider.future);

      expect(repository.calls, 2);
      expect(repository.months.toSet(), {_thisMonth});
    });
  });

  group('dueFilterProvider y visibleDuesProvider', () {
    final month = buildDuesMonth([
      buildDue(id: 1, dueDate: DateTime(2026, 10, 9)),
      buildDue(
        id: 2,
        type: MovementType.expense,
        dueDate: DateTime(2026, 10, 3),
      ),
      buildDue(id: 3, dueDate: DateTime(2026, 10, 1), balanceCents: 0),
    ]);

    test('por defecto muestra todos, abiertos primero y por fecha', () async {
      final container = _container(FakeDuesRepository((_) async => month));
      await container.read(duesProvider.future);

      expect(container.read(dueFilterProvider), DueFilter.all);
      expect(
        container.read(visibleDuesProvider).requireValue.map((d) => d.id),
        [2, 1, 3],
      );
    });

    test('Me pagan y Yo pago filtran sin volver a pedir al servidor', () async {
      final repository = FakeDuesRepository((_) async => month);
      final container = _container(repository);
      await container.read(duesProvider.future);

      container.read(dueFilterProvider.notifier).set(DueFilter.income);
      expect(
        container.read(visibleDuesProvider).requireValue.map((d) => d.id),
        [1, 3],
      );

      container.read(dueFilterProvider.notifier).set(DueFilter.expense);
      expect(
        container.read(visibleDuesProvider).requireValue.map((d) => d.id),
        [2],
      );

      expect(repository.calls, 1);
    });

    test('derivada: reenvía cargando y error del provider de origen', () async {
      final completer = Completer<DuesMonth>();
      final container = _container(FakeDuesRepository((_) => completer.future));
      expect(container.read(visibleDuesProvider).isLoading, isTrue);

      completer.completeError(const NetworkException('Sin conexión.'));
      await expectLater(
        container.read(duesProvider.future),
        throwsA(isA<NetworkException>()),
      );
      expect(container.read(visibleDuesProvider).hasError, isTrue);
    });
  });
}
