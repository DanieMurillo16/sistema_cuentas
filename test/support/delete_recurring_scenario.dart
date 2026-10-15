import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:sistema_cuentas/core/models/session.dart';
import 'package:sistema_cuentas/core/utils/date_formatter.dart';
import 'package:sistema_cuentas/features/dues/models/due.dart';
import 'package:sistema_cuentas/features/recurring/models/recurring_payment.dart';

import '../helpers/movement_fixtures.dart';
import '../helpers/recurring_fixtures.dart';
import 'fake_dues_repository.dart';
import 'fake_movements_repository.dart';
import 'fake_recurring_repository.dart';
import 'fake_summary_repository.dart';
import 'recurring_overrides.dart';
import 'session_overrides.dart';

/// Un «servidor» en memoria para probar eliminar pagos recurrentes de punta a
/// punta. Eliminar = `pagos_recurrentes/eliminar.php`: el acuerdo queda
/// finalizado y sus vencimientos dejan de listarse (nada se borra).
class DeleteRecurringScenario {
  DeleteRecurringScenario({
    required List<Due> dues,
    required List<RecurringPayment> payments,
    this.failWith,
    this.canManage = true,
  }) : servedDues = List.of(dues),
       servedPayments = List.of(payments) {
    this.dues = FakeDuesRepository(
      (_) async => buildDuesMonth(List.of(servedDues)),
    );
    recurring = FakeRecurringRepository(
      onList: () async => List.of(servedPayments),
      onDetail: (id) async =>
          buildDetail(payment: servedPayments.firstWhere((p) => p.id == id)),
      onDelete: (id) async {
        if (failWith != null) throw failWith!;
        final index = servedPayments.indexWhere((p) => p.id == id);
        final old = servedPayments[index];
        servedPayments[index] = buildRecurring(
          id: old.id,
          type: old.type,
          description: old.description,
          valueCents: old.valueCents,
          day: old.dayOfMonth,
          everyMonths: old.everyMonths,
          category: old.category,
          contact: old.contact,
          active: false,
          endDate: dateOnly(DateTime.now()),
          closingNote: 'Pago recurrente eliminado',
        );
        servedDues.removeWhere((d) => d.recurringId == id);
      },
    );
  }

  final List<Due> servedDues;
  final List<RecurringPayment> servedPayments;

  /// Si no es `null`, finalizar falla con esto.
  Object? failWith;

  /// Si la sesión tiene `pagos_recurrentes.gestionar`.
  final bool canManage;

  late final FakeDuesRepository dues;
  late final FakeRecurringRepository recurring;
  final movements = FakeMovementsRepository();
  final summary = FakeSummaryRepository((_) async => buildTotals());

  List<Override> get overrides => [
    ...sessionOverrides(
      permissions: {
        Permissions.registerMovements,
        if (canManage) Permissions.manageRecurring,
      },
    ).overrides,
    ...recurringOverrides(
      dues: dues,
      recurring: recurring,
      movements: movements,
      summary: summary,
    ),
  ];
}
