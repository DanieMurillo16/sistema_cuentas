import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_cuentas/features/catalogs/data/catalogs_repository.dart';
import 'package:sistema_cuentas/features/dues/data/dues_repository.dart';
import 'package:sistema_cuentas/features/dues/providers/dues_provider.dart';
import 'package:sistema_cuentas/features/movements/data/movements_repository.dart';
import 'package:sistema_cuentas/features/movements/providers/movements_provider.dart';
import 'package:sistema_cuentas/features/recurring/data/recurring_repository.dart';
import 'package:sistema_cuentas/features/recurring/providers/recurring_list_provider.dart';
import 'package:sistema_cuentas/features/summary/data/summary_repository.dart';
import 'package:sistema_cuentas/features/summary/providers/month_summary_provider.dart';

import '../helpers/movement_fixtures.dart';
import '../helpers/recurring_fixtures.dart';
import 'container_helpers.dart';
import 'fake_catalogs_repository.dart';
import 'fake_dues_repository.dart';
import 'fake_movements_repository.dart';
import 'fake_recurring_repository.dart';
import 'fake_summary_repository.dart';

/// Un `ProviderContainer` con todos los repositorios de Pagos recurrentes
/// falsos y las vistas que tendría abiertas la app (vencimientos, acuerdos,
/// movimientos, resumen) vivas, para comprobar quién se vuelve a pedir.
class RecurringHarness {
  RecurringHarness({
    FakeDuesRepository? dues,
    FakeRecurringRepository? recurring,
    FakeMovementsRepository? movements,
    FakeSummaryRepository? summary,
    FakeCatalogsRepository? catalogs,
  }) : dues =
           dues ??
           FakeDuesRepository((_) async => buildDuesMonth([buildDue()])),
       recurring =
           recurring ??
           FakeRecurringRepository(
             onList: () async => [buildRecurring()],
             onDetail: (id) async =>
                 buildDetail(payment: buildRecurring(id: id)),
           ),
       movements =
           movements ??
           FakeMovementsRepository(onList: (_, _) async => const []),
       summary = summary ?? FakeSummaryRepository((_) async => buildTotals()),
       catalogs =
           catalogs ??
           FakeCatalogsRepository(
             onCategories: () async => defaultCategories(),
             onMethods: () async => defaultMethods(),
             onContacts: () async => [buildContact()],
           ) {
    container = makeContainer(
      overrides: [
        duesRepositoryProvider.overrideWithValue(this.dues),
        recurringRepositoryProvider.overrideWithValue(this.recurring),
        movementsRepositoryProvider.overrideWithValue(this.movements),
        summaryRepositoryProvider.overrideWithValue(this.summary),
        catalogsRepositoryProvider.overrideWithValue(this.catalogs),
      ],
    );
  }

  final FakeDuesRepository dues;
  final FakeRecurringRepository recurring;
  final FakeMovementsRepository movements;
  final FakeSummaryRepository summary;
  final FakeCatalogsRepository catalogs;
  late final ProviderContainer container;

  /// Deja abiertas (y cargadas) las vistas que consume la pantalla: así una
  /// escritura que las invalida las vuelve a pedir y se puede contar.
  Future<void> openViews({int? detailId}) async {
    keepAlive(container, [
      duesProvider,
      recurringListProvider,
      movementsProvider,
      monthSummaryProvider,
      ?(detailId == null ? null : recurringDetailProvider(detailId)),
    ]);
    await Future.wait([
      container.read(duesProvider.future),
      container.read(recurringListProvider.future),
      container.read(movementsProvider.future),
      container.read(monthSummaryProvider.future),
      if (detailId != null)
        container.read(recurringDetailProvider(detailId).future),
    ]);
  }

  /// Espera a que lo invalidado vuelva a llegar y devuelve cuántas veces se
  /// pidió cada cosa: `(dues, summary, list, movements)`.
  Future<({int dues, int summary, int list, int movements, int detail})>
  settleViews({int? detailId}) async {
    await Future.wait([
      container.read(duesProvider.future),
      container.read(recurringListProvider.future),
      container.read(movementsProvider.future),
      container.read(monthSummaryProvider.future),
      if (detailId != null)
        container.read(recurringDetailProvider(detailId).future),
    ]);
    return (
      dues: dues.calls,
      summary: summary.calls,
      list: recurring.listCalls,
      movements: movements.listCalls,
      detail: recurring.detailCalls,
    );
  }
}
