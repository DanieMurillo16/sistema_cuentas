import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_cuentas/core/network/api_client.dart';
import 'package:sistema_cuentas/core/network/api_endpoints.dart';
import 'package:sistema_cuentas/core/network/api_response.dart';
import 'package:sistema_cuentas/core/utils/date_formatter.dart';
import 'package:sistema_cuentas/features/summary/models/category_total.dart';
import 'package:sistema_cuentas/features/summary/models/method_total.dart';
import 'package:sistema_cuentas/features/summary/models/month_summary.dart';
import 'package:sistema_cuentas/features/summary/models/summary_dues.dart';
import 'package:sistema_cuentas/features/summary/models/summary_totals.dart';

final summaryRepositoryProvider = Provider<SummaryRepository>(
  (ref) => SummaryRepository(ref.watch(apiClientProvider)),
);

/// Única puerta a los totales que calcula el servidor.
class SummaryRepository {
  const SummaryRepository(this._api);

  final ApiClient _api;

  List<T> _list<T>(Object? raw, T Function(Map<String, dynamic>) parse) => [
    for (final item in (raw as List? ?? const []))
      parse(Map<String, dynamic>.from(item as Map)),
  ];

  Future<MonthSummary> month(DateTime month) async {
    final data = await _api.get(
      ApiEndpoints.summaryMonth,
      queryParameters: {'periodo': apiPeriod(month)},
    );
    return parseApi(
      () => MonthSummary(
        totals: SummaryTotals.fromJson(
          Map<String, dynamic>.from(data['totales'] as Map),
        ),
        byCategory: _list(data['por_categoria'], CategoryTotal.fromJson),
        byMethod: _list(data['por_medio'], MethodTotal.fromJson),
        dues: _list(data['vencimientos'], SummaryDues.fromJson),
      ),
    );
  }
}
