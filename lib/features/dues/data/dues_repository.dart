import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_cuentas/core/network/api_client.dart';
import 'package:sistema_cuentas/core/network/api_endpoints.dart';
import 'package:sistema_cuentas/core/network/api_response.dart';
import 'package:sistema_cuentas/core/utils/date_formatter.dart';
import 'package:sistema_cuentas/features/dues/models/due.dart';
import 'package:sistema_cuentas/features/dues/models/due_totals.dart';
import 'package:sistema_cuentas/features/dues/models/dues_month.dart';

final duesRepositoryProvider = Provider<DuesRepository>(
  (ref) => DuesRepository(ref.watch(apiClientProvider)),
);

/// Única puerta a los vencimientos. El servidor los genera al consultar.
class DuesRepository {
  const DuesRepository(this._api);

  final ApiClient _api;

  Future<DuesMonth> month(DateTime month) async {
    final data = await _api.get(
      ApiEndpoints.duesList,
      queryParameters: {'periodo': apiPeriod(month)},
    );
    return parseApi(
      () => DuesMonth(
        dues: [
          for (final item in data['vencimientos'] as List)
            Due.fromJson(Map<String, dynamic>.from(item as Map)),
        ],
        totals: [
          for (final item in data['totales'] as List)
            DueTotals.fromJson(Map<String, dynamic>.from(item as Map)),
        ],
      ),
    );
  }
}
