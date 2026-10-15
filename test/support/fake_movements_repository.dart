import 'package:sistema_cuentas/core/models/movement_type.dart';
import 'package:sistema_cuentas/features/movements/data/movements_repository.dart';
import 'package:sistema_cuentas/features/movements/models/due_payment_draft.dart';
import 'package:sistema_cuentas/features/movements/models/movement.dart';
import 'package:sistema_cuentas/features/movements/models/movement_draft.dart';

/// Repositorio de movimientos falso: se programa con funciones (o `Completer`)
/// y se cuentan las llamadas. Por defecto devuelve una lista vacía.
class FakeMovementsRepository implements MovementsRepository {
  FakeMovementsRepository({
    this.onList,
    this.onRegister,
    this.onRegisterDue,
    this.onCancel,
  });

  Future<List<Movement>> Function(DateTime from, DateTime to)? onList;
  Future<Movement> Function(MovementDraft draft)? onRegister;
  Future<Movement> Function(DuePaymentDraft draft)? onRegisterDue;
  Future<void> Function(int id, String reason)? onCancel;

  int listCalls = 0;
  int searchCalls = 0;
  int registerCalls = 0;
  int registerDueCalls = 0;
  int cancelCalls = 0;
  final cancelled = <({int id, String reason})>[];
  final listedRanges = <(DateTime, DateTime)>[];

  /// Cada consulta de `search`, con todos sus filtros, en orden.
  final searches =
      <
        ({
          DateTime from,
          DateTime to,
          MovementType? type,
          int? categoryId,
          int? methodId,
        })
      >[];
  final drafts = <MovementDraft>[];
  final dueDrafts = <DuePaymentDraft>[];

  @override
  Future<List<Movement>> listBetween({
    required DateTime from,
    required DateTime to,
  }) async {
    listCalls++;
    listedRanges.add((from, to));
    return onList == null ? const [] : onList!(from, to);
  }

  @override
  Future<List<Movement>> search({
    required DateTime from,
    required DateTime to,
    MovementType? type,
    int? categoryId,
    int? methodId,
  }) async {
    searchCalls++;
    searches.add((
      from: from,
      to: to,
      type: type,
      categoryId: categoryId,
      methodId: methodId,
    ));
    final all = await listBetween(from: from, to: to);
    return [
      for (final m in all)
        if ((type == null || m.type == type) &&
            (categoryId == null || m.categoryId == categoryId) &&
            (methodId == null || m.methodId == methodId))
          m,
    ];
  }

  @override
  Future<Movement> register(MovementDraft draft) {
    registerCalls++;
    drafts.add(draft);
    return onRegister!(draft);
  }

  @override
  Future<Movement> registerDuePayment(DuePaymentDraft draft) {
    registerDueCalls++;
    dueDrafts.add(draft);
    return onRegisterDue!(draft);
  }

  @override
  Future<void> cancel(int id, {required String reason}) async {
    cancelCalls++;
    cancelled.add((id: id, reason: reason));
    await onCancel?.call(id, reason);
  }
}
