import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_cuentas/core/network/api_client.dart';
import 'package:sistema_cuentas/core/network/api_endpoints.dart';
import 'package:sistema_cuentas/core/network/api_response.dart';
import 'package:sistema_cuentas/features/recurring/models/due_history_item.dart';
import 'package:sistema_cuentas/features/recurring/models/finish_draft.dart';
import 'package:sistema_cuentas/features/recurring/models/recurring_detail.dart';
import 'package:sistema_cuentas/features/recurring/models/recurring_draft.dart';
import 'package:sistema_cuentas/features/recurring/models/recurring_payment.dart';

final recurringRepositoryProvider = Provider<RecurringRepository>(
  (ref) => RecurringRepository(ref.watch(apiClientProvider)),
);

/// Única puerta a los pagos recurrentes (los acuerdos).
class RecurringRepository {
  const RecurringRepository(this._api);

  final ApiClient _api;

  /// Todos: activos y finalizados.
  Future<List<RecurringPayment>> list() async {
    final data = await _api.get(ApiEndpoints.recurringList);
    return parseApi(
      () => [
        for (final item in data['pagos_recurrentes'] as List)
          RecurringPayment.fromJson(Map<String, dynamic>.from(item as Map)),
      ],
    );
  }

  Future<RecurringDetail> detail(int id) async {
    final data = await _api.get(
      ApiEndpoints.recurringDetail,
      queryParameters: {'id_pago_recurrente': id},
    );
    return parseApi(
      () => RecurringDetail(
        payment: RecurringPayment.fromJson(
          Map<String, dynamic>.from(data['pago_recurrente'] as Map),
        ),
        history: [
          for (final item in data['vencimientos'] as List)
            DueHistoryItem.fromJson(Map<String, dynamic>.from(item as Map)),
        ],
      ),
    );
  }

  Future<RecurringPayment> create(RecurringDraft draft) async {
    final data = await _api.post(
      ApiEndpoints.recurringCreate,
      data: draft.toJson(),
    );
    return parseApi(
      () => RecurringPayment.fromJson(
        Map<String, dynamic>.from(data['pago_recurrente'] as Map),
      ),
    );
  }

  /// Elimina el acuerdo («no lo quiero ver más»): en el servidor queda
  /// finalizado y se anula todo lo que no tenga pagos, también lo vencido. Lo ya
  /// pagado se conserva.
  Future<void> delete(int id) async {
    await _api.post(
      ApiEndpoints.recurringDelete,
      data: {'id_pago_recurrente': id},
    );
  }

  /// Cierra el acuerdo (con nota y, si hay, capital). Es irreversible: lo
  /// pendiente a futuro se anula en el servidor; lo vencido sigue vivo.
  Future<void> finish(FinishDraft draft) async {
    await _api.post(ApiEndpoints.recurringFinish, data: draft.toJson());
  }
}
