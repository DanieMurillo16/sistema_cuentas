import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:sistema_cuentas/features/catalogs/data/catalogs_repository.dart';
import 'package:sistema_cuentas/features/movements/data/movements_repository.dart';
import 'package:sistema_cuentas/features/movements/models/movement.dart';
import 'package:sistema_cuentas/features/summary/data/summary_repository.dart';
import 'package:sistema_cuentas/features/summary/models/summary_totals.dart';

import '../helpers/movement_fixtures.dart';
import 'fake_catalogs_repository.dart';
import 'fake_movements_repository.dart';
import 'fake_summary_repository.dart';

/// Overrides para toda vista que pinta Inicio o el formulario: movimientos,
/// resumen y catálogos falsos (sin red ni `API_BASE_URL`).
List<Override> dataOverrides({
  FakeMovementsRepository? movements,
  FakeSummaryRepository? summary,
  FakeCatalogsRepository? catalogs,
  List<Movement> items = const [],
  SummaryTotals? totals,
}) => [
  movementsRepositoryProvider.overrideWithValue(
    movements ?? FakeMovementsRepository(onList: (_, _) async => items),
  ),
  summaryRepositoryProvider.overrideWithValue(
    summary ?? FakeSummaryRepository((_) async => totals ?? buildTotals()),
  ),
  catalogsRepositoryProvider.overrideWithValue(
    catalogs ??
        FakeCatalogsRepository(
          onCategories: () async => defaultCategories(),
          onMethods: () async => defaultMethods(),
        ),
  ),
];
