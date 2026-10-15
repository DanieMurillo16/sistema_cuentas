import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_cuentas/core/errors/app_exception.dart';
import 'package:sistema_cuentas/core/theme/design_tokens.dart';
import 'package:sistema_cuentas/features/summary/models/monthly_point.dart';
import 'package:sistema_cuentas/features/summary/providers/summary_trend_provider.dart';
import 'package:sistema_cuentas/shared/widgets/app_retry_message.dart';

/// Resuelve los estados de la serie de meses para una gráfica: cargando (con el
/// alto de la gráfica, así la tarjeta no salta), error con «Intentar
/// nuevamente» y datos. Al refrescar conserva la gráfica que ya se ve.
class TrendAsync extends ConsumerWidget {
  const TrendAsync({super.key, required this.builder});

  final Widget Function(List<MonthlyPoint> points) builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trend = ref.watch(monthlyTrendProvider);
    return trend.when(
      skipLoadingOnReload: true,
      skipLoadingOnRefresh: true,
      // Un refresco que falla conserva la gráfica que ya se ve.
      skipError: trend.hasValue,
      data: builder,
      loading: () => const SizedBox(
        height: DesignTokens.chartHeight,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => AppRetryMessage(
        text: userErrorMessage(error),
        // El mes que falló quedó guardado como error: también se suelta.
        onRetry: () {
          ref.invalidate(summaryForMonthProvider);
          ref.invalidate(monthlyTrendProvider);
        },
      ),
    );
  }
}
