import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_cuentas/core/errors/app_exception.dart';
import 'package:sistema_cuentas/core/models/movement_type.dart';
import 'package:sistema_cuentas/core/utils/date_formatter.dart';
import 'package:sistema_cuentas/features/catalogs/data/catalogs_repository.dart';
import 'package:sistema_cuentas/features/catalogs/models/category.dart';
import 'package:sistema_cuentas/features/catalogs/providers/categories_provider.dart';
import 'package:sistema_cuentas/features/initial_balance/models/initial_balance_entry.dart';
import 'package:sistema_cuentas/features/initial_balance/providers/save_initial_balance_provider.dart';
import 'package:sistema_cuentas/features/movements/data/movements_repository.dart';
import 'package:sistema_cuentas/features/movements/models/movement.dart';
import 'package:sistema_cuentas/features/movements/models/movement_draft.dart';
import 'package:sistema_cuentas/features/movements/providers/movements_provider.dart';
import 'package:sistema_cuentas/features/summary/data/summary_repository.dart';
import 'package:sistema_cuentas/features/summary/providers/month_summary_provider.dart';

import '../../../helpers/movement_fixtures.dart';
import '../../../support/container_helpers.dart';
import '../../../support/fake_catalogs_repository.dart';
import '../../../support/fake_movements_repository.dart';
import '../../../support/fake_summary_repository.dart';

const _two = [
  InitialBalanceEntry(methodId: 2, pesos: 1500000),
  InitialBalanceEntry(methodId: 5, pesos: 250000),
];

class _Rig {
  _Rig({
    List<Category>? categories,
    Future<Movement> Function(MovementDraft draft)? onRegister,
    Future<Category> Function()? onSaveCategory,
  }) : categories = categories ?? [buildCategory(id: 3)] {
    var nextCategoryId = 90;
    catalogs = FakeCatalogsRepository(
      onCategories: () async => List.of(this.categories),
      onSaveCategory: (draft) async {
        if (onSaveCategory != null) return onSaveCategory();
        return Category(
          id: nextCategoryId++,
          type: draft.type,
          name: draft.name,
          isCapital: draft.isCapital,
          active: draft.active,
        );
      },
    );
    movements = FakeMovementsRepository(
      onList: (_, _) async => const [],
      onRegister:
          onRegister ??
          (draft) async => buildMovement(
            id: 100 + draft.methodId,
            type: draft.type,
            valueCents: draft.amountPesos * 100,
            date: draft.date,
            description: draft.description,
            categoryId: draft.categoryId,
            methodId: draft.methodId,
          ),
    );
    summary = FakeSummaryRepository((_) async => buildTotals());
    container = makeContainer(
      overrides: [
        catalogsRepositoryProvider.overrideWithValue(catalogs),
        movementsRepositoryProvider.overrideWithValue(movements),
        summaryRepositoryProvider.overrideWithValue(summary),
      ],
    );
    keepAlive(container, [
      saveInitialBalanceProvider,
      categoriesProvider,
      movementsProvider,
      monthSummaryProvider,
    ]);
  }

  final List<Category> categories;
  late final FakeCatalogsRepository catalogs;
  late final FakeMovementsRepository movements;
  late final FakeSummaryRepository summary;
  late final ProviderContainer container;

  Future<void> open() async {
    await container.read(categoriesProvider.future);
    await container.read(movementsProvider.future);
    await container.read(monthSummaryProvider.future);
  }

  Future<void> save(List<InitialBalanceEntry> entries) =>
      container.read(saveInitialBalanceProvider.notifier).save(entries);

  AsyncValue<void> get state => container.read(saveInitialBalanceProvider);
}

void main() {
  test('estado inicial: en reposo', () async {
    final r = _Rig();
    expect(r.state.isLoading, isFalse);
    expect(r.state.hasError, isFalse);
  });

  group('la categoría «Saldo inicial»', () {
    test('si no existe, la crea de INGRESO y de capital, y la guarda en el '
        'provider compartido', () async {
      final r = _Rig();
      await r.open();

      await r.save(_two);

      final draft = r.catalogs.savedCategories.single;
      expect(draft.type, MovementType.income);
      expect(draft.name, 'Saldo inicial');
      expect(draft.isCapital, isTrue);
      expect(draft.active, isTrue);
      expect(draft.id, isNull);
      final shared = r.container.read(categoriesProvider).requireValue;
      expect(shared.map((c) => c.name), contains('Saldo inicial'));
      expect(shared.firstWhere((c) => c.name == 'Saldo inicial').id, 90);
    });

    test('si ya existe (sin distinguir mayúsculas ni espacios) la usa y no '
        'crea otra', () async {
      final r = _Rig(
        categories: [
          buildCategory(id: 3),
          buildCategory(
            id: 8,
            type: MovementType.income,
            name: '  SALDO inicial ',
          ),
        ],
      );
      await r.open();

      await r.save(_two);

      expect(r.catalogs.savedCategories, isEmpty);
      expect(r.movements.drafts.map((d) => d.categoryId), [8, 8]);
    });

    test('una de GASTO con ese nombre no vale: crea la de ingresos', () async {
      final r = _Rig(categories: [buildCategory(id: 3, name: 'Saldo inicial')]);
      await r.open();

      await r.save(_two);

      expect(r.catalogs.savedCategories, hasLength(1));
      expect(r.movements.drafts.first.categoryId, 90);
    });

    test('una inactiva con ese nombre no vale: crea otra', () async {
      final r = _Rig(
        categories: [
          buildCategory(
            id: 8,
            type: MovementType.income,
            name: 'Saldo inicial',
            active: false,
          ),
        ],
      );
      await r.open();

      await r.save(_two);

      expect(r.catalogs.savedCategories, hasLength(1));
      expect(r.movements.drafts.first.categoryId, 90);
    });

    test('se crea una sola vez aunque haya varios medios', () async {
      final r = _Rig();
      await r.open();

      await r.save(_two);

      expect(r.catalogs.savedCategories, hasLength(1));
      expect(r.movements.drafts.map((d) => d.categoryId).toSet(), {90});
    });
  });

  group('los movimientos', () {
    test('un ingreso por cada medio con valor, con descripción, fecha y '
        'categoría correctas', () async {
      final r = _Rig();
      await r.open();

      await r.save(_two);

      expect(r.state.hasError, isFalse);
      expect(r.movements.registerCalls, 2);
      final today = dateOnly(DateTime.now());
      for (final (draft, entry) in [
        (r.movements.drafts[0], _two[0]),
        (r.movements.drafts[1], _two[1]),
      ]) {
        expect(draft.type, MovementType.income);
        expect(draft.amountPesos, entry.pesos);
        expect(draft.methodId, entry.methodId);
        expect(draft.description, 'Saldo inicial');
        expect(draft.date, today);
        expect(draft.categoryId, 90);
        expect(draft.note, isNull);
      }
    });

    test('van al provider compartido sin recargar la lista', () async {
      final r = _Rig();
      await r.open();

      await r.save(_two);

      expect(
        r.container.read(movementsProvider).requireValue.map((m) => m.id),
        containsAll([102, 105]),
      );
      expect(r.movements.listCalls, 1, reason: 'la lista no se recarga');
    });

    test('el resumen del mes se vuelve a pedir', () async {
      final r = _Rig();
      await r.open();
      expect(r.summary.calls, 1);

      await r.save(_two);
      await r.container.read(monthSummaryProvider.future);

      expect(r.summary.calls, 2);
    });

    test('un solo medio: un solo movimiento', () async {
      final r = _Rig();
      await r.open();

      await r.save(const [InitialBalanceEntry(methodId: 5, pesos: 900000)]);

      expect(r.movements.registerCalls, 1);
      expect(r.movements.drafts.single.amountPesos, 900000);
    });
  });

  test('anti doble envío: un segundo save mientras guarda no registra otra '
      'vez', () async {
    final gate = Completer<Movement>();
    final r = _Rig(onRegister: (_) => gate.future);
    await r.open();
    final notifier = r.container.read(saveInitialBalanceProvider.notifier);

    final first = notifier.save(const [
      InitialBalanceEntry(methodId: 2, pesos: 1000),
    ]);
    await Future<void>.delayed(Duration.zero);
    expect(r.state.isLoading, isTrue);
    await notifier.save(_two);
    await notifier.save(_two);
    expect(r.movements.registerCalls, 1);

    gate.complete(buildMovement(id: 1));
    await first;
    expect(r.state.isLoading, isFalse);
    expect(r.movements.registerCalls, 1);
  });

  group('cuando falla', () {
    test('el error queda en estado con el mensaje en español', () async {
      final r = _Rig(
        onRegister: (_) async =>
            throw const NetworkException('Sin conexión con el servidor.'),
      );
      await r.open();

      await r.save(_two);

      expect(r.state.hasError, isTrue);
      expect(userErrorMessage(r.state.error), 'Sin conexión con el servidor.');
    });

    test('si falla la categoría, no se registra nada ni se invalida el '
        'resumen', () async {
      final r = _Rig(
        onSaveCategory: () async => throw const ApiException(
          'No tienes permiso para crear categorías.',
          statusCode: 403,
        ),
      );
      await r.open();

      await r.save(_two);
      await r.container.read(monthSummaryProvider.future);

      expect(r.state.hasError, isTrue);
      expect(r.movements.registerCalls, 0);
      expect(r.summary.calls, 1);
    });

    test('si falla a mitad, lo ya registrado se ve y NO se repite al '
        'reintentar', () async {
      var failSecond = true;
      final r = _Rig(
        onRegister: (draft) async {
          if (draft.methodId == 5 && failSecond) {
            throw const NetworkException('Sin conexión.');
          }
          return buildMovement(
            id: 100 + draft.methodId,
            date: draft.date,
            description: draft.description,
            methodId: draft.methodId,
          );
        },
      );
      await r.open();

      await r.save(_two);

      expect(r.state.hasError, isTrue);
      expect(
        r.container.read(movementsProvider).requireValue.map((m) => m.id),
        [102],
        reason: 'el primero ya quedó registrado y se ve',
      );

      failSecond = false;
      await r.save(_two);

      expect(r.state.hasError, isFalse);
      expect(r.movements.drafts.map((d) => d.methodId), [
        2,
        5,
        5,
      ], reason: 'el del medio 2 no se vuelve a registrar');
      expect(
        r.container.read(movementsProvider).requireValue.map((m) => m.id),
        containsAll([102, 105]),
      );
      expect(
        r.catalogs.savedCategories,
        hasLength(1),
        reason: 'tampoco se crea otra categoría',
      );
    });

    test(
      'la categoría creada antes del fallo se reutiliza al reintentar',
      () async {
        var fail = true;
        final r = _Rig(
          onRegister: (draft) async {
            if (fail) throw const NetworkException('Sin conexión.');
            return buildMovement(id: 1, methodId: draft.methodId);
          },
        );
        await r.open();

        await r.save(_two);
        fail = false;
        await r.save(_two);

        expect(r.catalogs.savedCategories, hasLength(1));
      },
    );
  });

  test('termina aunque nadie observe al notifier (el diálogo se cerró)', () async {
    final gate = Completer<Movement>();
    final r = _Rig(onRegister: (_) => gate.future);
    await r.open();
    final container = r.container;
    // Sin keepAlive propio del test: lo mantiene el notifier mientras escribe.
    final pending = container.read(saveInitialBalanceProvider.notifier).save(
      const [InitialBalanceEntry(methodId: 2, pesos: 1000)],
    );
    await Future<void>.delayed(Duration.zero);

    gate.complete(buildMovement(id: 7));
    await pending;

    expect(
      container.read(movementsProvider).requireValue.map((m) => m.id),
      contains(7),
    );
  });
}
