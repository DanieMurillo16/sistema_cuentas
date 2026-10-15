import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_cuentas/core/errors/app_exception.dart';
import 'package:sistema_cuentas/features/auth/data/auth_repository.dart';
import 'package:sistema_cuentas/features/catalogs/data/catalogs_repository.dart';
import 'package:sistema_cuentas/features/dues/data/dues_repository.dart';
import 'package:sistema_cuentas/features/dues/models/dues_month.dart';
import 'package:sistema_cuentas/features/movements/data/movements_repository.dart';
import 'package:sistema_cuentas/features/recurring/data/recurring_repository.dart';
import 'package:sistema_cuentas/features/summary/data/summary_repository.dart';
import 'package:sistema_cuentas/shared/providers/app_preload_provider.dart';
import 'package:sistema_cuentas/shared/providers/session_provider.dart';

import '../../helpers/auth_fixtures.dart';
import '../../helpers/movement_fixtures.dart';
import '../../helpers/summary_fixtures.dart';
import '../../support/container_helpers.dart';
import '../../support/fake_auth_repository.dart';
import '../../support/fake_catalogs_repository.dart';
import '../../support/fake_dues_repository.dart';
import '../../support/fake_movements_repository.dart';
import '../../support/fake_recurring_repository.dart';
import '../../support/fake_summary_repository.dart';

/// Repositorios falsos que anotan en [order] cuál se pidió y en qué momento.
/// Cada uno espera a su `Completer` (si lo hay) para poder ver los turnos.
class _Rig {
  _Rig({this.failing = const {}, Set<String> gated = const {}}) {
    for (final name in gated) {
      gates[name] = Completer<void>();
    }
  }

  final Set<String> failing;
  final order = <String>[];
  final gates = <String, Completer<void>>{};

  Future<T> _run<T>(String name, T value) async {
    order.add(name);
    final gate = gates[name];
    if (gate != null) await gate.future;
    if (failing.contains(name)) {
      throw NetworkException('Falla $name.');
    }
    return value;
  }

  late final summary = FakeSummaryRepository(
    (_) async => throw StateError('no se usa'),
    onMonth: (_) => _run('resumen', buildMonthSummary()),
  );
  late final movements = FakeMovementsRepository(
    onList: (_, _) => _run('movimientos', const []),
  );
  late final catalogs = FakeCatalogsRepository(
    onCategories: () => _run('categorias', defaultCategories()),
    onMethods: () => _run('medios', defaultMethods()),
    onContacts: () => _run('contactos', const []),
  );
  late final dues = FakeDuesRepository(
    (_) => _run('vencimientos', const DuesMonth(dues: [], totals: [])),
  );
  late final recurring = FakeRecurringRepository(
    onList: () => _run('acuerdos', const []),
  );

  List<Override> get overrides => [
    summaryRepositoryProvider.overrideWithValue(summary),
    movementsRepositoryProvider.overrideWithValue(movements),
    catalogsRepositoryProvider.overrideWithValue(catalogs),
    duesRepositoryProvider.overrideWithValue(dues),
    recurringRepositoryProvider.overrideWithValue(recurring),
  ];
}

const _expectedOrder = [
  'resumen',
  'movimientos',
  'categorias',
  'medios',
  'vencimientos',
  'acuerdos',
  'contactos',
];

void main() {
  test('pide los siete datos, por turnos y en el orden previsto', () async {
    final rig = _Rig(gated: _expectedOrder.toSet());
    final container = makeContainer(overrides: rig.overrides);

    container.read(appPreloadProvider);
    await pumpEventQueue();
    expect(rig.order, ['resumen'], reason: 'el siguiente espera al anterior');

    for (var i = 0; i < _expectedOrder.length; i++) {
      rig.gates[_expectedOrder[i]]!.complete();
      await pumpEventQueue();
      expect(
        rig.order,
        _expectedOrder.take(i + 2).toList(),
        reason: 'tras terminar ${_expectedOrder[i]}',
      );
    }
    expect(rig.order, _expectedOrder);
  });

  test('cada repositorio se pide una sola vez', () async {
    final rig = _Rig();
    final container = makeContainer(overrides: rig.overrides);

    container.read(appPreloadProvider);
    await pumpEventQueue();

    expect(rig.order, _expectedOrder);
    expect(rig.summary.calls, 1);
    expect(rig.movements.listCalls, 1);
    expect(rig.catalogs.categoriesCalls, 1);
    expect(rig.catalogs.methodsCalls, 1);
    expect(rig.catalogs.contactsCalls, 1);
    expect(rig.dues.calls, 1);
    expect(rig.recurring.listCalls, 1);
  });

  test('leer el provider otra vez no repite la precarga', () async {
    final rig = _Rig();
    final container = makeContainer(overrides: rig.overrides);

    container.read(appPreloadProvider);
    await pumpEventQueue();
    container.read(appPreloadProvider);
    await pumpEventQueue();

    expect(rig.order, _expectedOrder);
  });

  test('si un repositorio lanza, no falla y sigue con los demás', () async {
    final rig = _Rig(failing: {'resumen', 'categorias', 'acuerdos'});
    final container = makeContainer(overrides: rig.overrides);

    // Un error sin atrapar en la precarga haría fallar la prueba por la zona.
    container.read(appPreloadProvider);
    await pumpEventQueue();

    expect(rig.order, _expectedOrder);
  });

  test('si todos lanzan, tampoco falla', () async {
    final rig = _Rig(failing: _expectedOrder.toSet());
    final container = makeContainer(overrides: rig.overrides);

    container.read(appPreloadProvider);
    await pumpEventQueue();

    expect(rig.order, _expectedOrder);
  });

  test(
    'si el contenedor se cierra a medio camino, no sigue pidiendo',
    () async {
      final rig = _Rig(gated: {'resumen'});
      final container = ProviderContainer(
        retry: (_, _) => null,
        overrides: [
          sessionUserIdProvider.overrideWithValue(7),
          ...rig.overrides,
        ],
      );

      container.read(appPreloadProvider);
      await pumpEventQueue();
      expect(rig.order, ['resumen']);

      container.dispose();
      rig.gates['resumen']!.complete();
      await pumpEventQueue();

      expect(rig.order, ['resumen'], reason: 'ya no quedó nadie escuchando');
    },
  );

  group('sesión', () {
    test('sin sesión no llama a ningún repositorio', () async {
      final rig = _Rig();
      final container = ProviderContainer(
        retry: (_, _) => null,
        overrides: [
          sessionUserIdProvider.overrideWithValue(null),
          ...rig.overrides,
        ],
      );
      addTearDown(container.dispose);

      container.read(appPreloadProvider);
      await pumpEventQueue();

      expect(rig.order, isEmpty);
    });

    test('abierta la sesión, el menú que se monta empieza la precarga', () async {
      final rig = _Rig();
      final container = ProviderContainer(
        retry: (_, _) => null,
        overrides: [
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
          ...rig.overrides,
        ],
      );
      addTearDown(container.dispose);
      await container.read(sessionProvider.future); // sin token: null

      container.read(appPreloadProvider);
      await pumpEventQueue();
      expect(rig.order, isEmpty, reason: 'todavía sin sesión');

      container.read(sessionProvider.notifier).open(buildSession());
      await pumpEventQueue();
      // Nadie escucha la precarga: se rehace al leerla otra vez, que es lo que
      // hace el `MainShell` nuevo tras el login.
      expect(rig.order, isEmpty);
      container.read(appPreloadProvider);
      await pumpEventQueue();

      expect(rig.order, _expectedOrder);
    });
  });
}
