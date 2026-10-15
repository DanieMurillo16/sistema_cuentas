import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:sistema_cuentas/features/dues/data/dues_repository.dart';
import 'package:sistema_cuentas/features/dues/models/due.dart';
import 'package:sistema_cuentas/features/dues/models/dues_month.dart';
import 'package:sistema_cuentas/features/recurring/data/recurring_repository.dart';
import 'package:sistema_cuentas/features/recurring/models/recurring_payment.dart';

import '../helpers/movement_fixtures.dart';
import '../helpers/recurring_fixtures.dart';
import 'fake_catalogs_repository.dart';
import 'fake_dues_repository.dart';
import 'fake_movements_repository.dart';
import 'fake_recurring_repository.dart';
import 'fake_summary_repository.dart';
import 'inicio_overrides.dart';

/// Solo los repositorios de Pagos recurrentes (vencimientos y acuerdos) falsos.
/// Úsalo junto a `dataOverrides` cuando la vista ya los trae.
List<Override> recurringRepositoryOverrides({
  FakeDuesRepository? dues,
  FakeRecurringRepository? recurring,
  List<Due> dueItems = const [],
  List<RecurringPayment> recurringItems = const [],
}) => [
  duesRepositoryProvider.overrideWithValue(
    dues ?? FakeDuesRepository((_) async => buildDuesMonth(dueItems)),
  ),
  recurringRepositoryProvider.overrideWithValue(
    recurring ?? FakeRecurringRepository(onList: () async => recurringItems),
  ),
];

/// Overrides para toda vista de Pagos recurrentes: vencimientos, acuerdos,
/// movimientos, resumen y catálogos falsos (sin red ni `API_BASE_URL`).
///
/// Pasa [dues]/[recurring] para controlar las llamadas, o [dueItems] /
/// [recurringItems] para datos fijos.
List<Override> recurringOverrides({
  FakeDuesRepository? dues,
  FakeRecurringRepository? recurring,
  FakeMovementsRepository? movements,
  FakeSummaryRepository? summary,
  FakeCatalogsRepository? catalogs,
  List<Due> dueItems = const [],
  List<RecurringPayment> recurringItems = const [],
}) => [
  ...recurringRepositoryOverrides(
    dues: dues,
    recurring: recurring,
    dueItems: dueItems,
    recurringItems: recurringItems,
  ),
  ...dataOverrides(
    movements: movements,
    summary: summary,
    catalogs:
        catalogs ??
        FakeCatalogsRepository(
          onCategories: () async => defaultCategories(),
          onMethods: () async => defaultMethods(),
          onContacts: () async => [buildContact()],
        ),
  ),
];

/// Un mes sin vencimientos (alias legible para las pruebas).
const emptyMonth = DuesMonth(dues: [], totals: []);
