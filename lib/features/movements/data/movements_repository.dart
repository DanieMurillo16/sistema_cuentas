import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_cuentas/core/models/movement_type.dart';
import 'package:sistema_cuentas/core/network/api_client.dart';
import 'package:sistema_cuentas/core/network/api_endpoints.dart';
import 'package:sistema_cuentas/core/network/api_response.dart';
import 'package:sistema_cuentas/core/utils/date_formatter.dart';
import 'package:sistema_cuentas/features/movements/models/due_payment_draft.dart';
import 'package:sistema_cuentas/features/movements/models/movement.dart';
import 'package:sistema_cuentas/features/movements/models/movement_draft.dart';

final movementsRepositoryProvider = Provider<MovementsRepository>(
  (ref) => MovementsRepository(ref.watch(apiClientProvider)),
);

/// Única puerta a los movimientos (la plata real).
class MovementsRepository {
  const MovementsRepository(this._api);

  final ApiClient _api;

  static const _pageSize = 200;

  /// Todos los movimientos vigentes entre [from] y [to] (inclusive). Pide la
  /// lista por páginas y la junta: la app guarda todo para buscar localmente.
  Future<List<Movement>> listBetween({
    required DateTime from,
    required DateTime to,
  }) => search(from: from, to: to);

  /// Como [listBetween], con filtros opcionales por tipo, categoría y medio.
  Future<List<Movement>> search({
    required DateTime from,
    required DateTime to,
    MovementType? type,
    int? categoryId,
    int? methodId,
  }) async {
    final result = <Movement>[];
    var offset = 0;
    while (true) {
      final page = await _api.getWithMeta(
        ApiEndpoints.movementsList,
        queryParameters: {
          'desde': apiDate(from),
          'hasta': apiDate(to),
          'limite': _pageSize,
          'desplazamiento': offset,
          'tipo': ?type?.apiValue,
          'id_categoria': ?categoryId,
          'id_medio': ?methodId,
        },
      );
      final items = parseApi(
        () => [
          for (final item in page.data['movimientos'] as List)
            Movement.fromJson(Map<String, dynamic>.from(item as Map)),
        ],
      );
      result.addAll(items);
      offset += items.length;
      final total = page.meta['total_registros'];
      final hasMore =
          items.length == _pageSize && (total is! num || offset < total);
      if (!hasMore) return result;
    }
  }

  Future<Movement> register(MovementDraft draft) async {
    final data = await _api.post(
      ApiEndpoints.movementRegister,
      data: draft.toJson(),
    );
    return parseApi(
      () => Movement.fromJson(
        Map<String, dynamic>.from(data['movimiento'] as Map),
      ),
    );
  }

  /// Registra un pago o abono de un vencimiento.
  Future<Movement> registerDuePayment(DuePaymentDraft draft) async {
    final data = await _api.post(
      ApiEndpoints.movementRegister,
      data: draft.toJson(),
    );
    return parseApi(
      () => Movement.fromJson(
        Map<String, dynamic>.from(data['movimiento'] as Map),
      ),
    );
  }

  /// Anula un movimiento (nunca se borra: queda con su [reason] en el servidor).
  Future<void> cancel(int id, {required String reason}) async {
    final data = await _api.post(
      ApiEndpoints.movementCancel,
      data: {'id_movimiento': id, 'motivo': reason},
    );
    parseApi(() => data['movimiento'] as Map);
  }
}
