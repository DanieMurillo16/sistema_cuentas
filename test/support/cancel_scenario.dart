import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:sistema_cuentas/core/models/movement_type.dart';
import 'package:sistema_cuentas/core/models/session.dart';
import 'package:sistema_cuentas/features/movements/models/movement.dart';

import '../helpers/movement_fixtures.dart';
import 'fake_movements_repository.dart';
import 'fake_summary_repository.dart';
import 'inicio_overrides.dart';
import 'session_overrides.dart';

/// Un «servidor» en memoria para probar eliminar (anular) movimientos de punta
/// a punta: la lista que devuelve y el resumen se calculan de lo que haya
/// vigente, y `movimientos/anular.php` saca la fila (igual que el real).
class CancelScenario {
  CancelScenario({
    required List<Movement> items,
    this.failWith,
    this.canCancel = true,
  }) : served = List.of(items) {
    movements = FakeMovementsRepository(
      onList: (_, _) async => List.of(served),
      onCancel: (id, reason) async {
        if (failWith != null) throw failWith!;
        served.removeWhere((m) => m.id == id);
      },
    );
    summary = FakeSummaryRepository((_) async {
      final income = _sum(MovementType.income);
      final expense = _sum(MovementType.expense);
      return buildTotals(
        incomeCents: income,
        expenseCents: expense,
        netFlowCents: income - expense,
        count: served.length,
      );
    });
  }

  /// Lo vigente en el servidor.
  final List<Movement> served;

  /// Si no es `null`, anular falla con esto.
  Object? failWith;

  /// Si la sesión tiene `movimientos.anular`.
  final bool canCancel;

  late final FakeMovementsRepository movements;
  late final FakeSummaryRepository summary;

  int _sum(MovementType type) => served
      .where((m) => m.type == type)
      .fold(0, (sum, m) => sum + m.valueCents);

  List<Override> get overrides => [
    ...sessionOverrides(
      permissions: {
        Permissions.registerMovements,
        if (canCancel) Permissions.cancelMovements,
      },
    ).overrides,
    ...dataOverrides(movements: movements, summary: summary),
  ];
}
