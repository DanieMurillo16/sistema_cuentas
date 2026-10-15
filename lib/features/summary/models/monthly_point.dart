import 'package:sistema_cuentas/features/summary/models/month_summary.dart';

/// Un mes de la serie de las gráficas: cuál es y su resumen completo.
class MonthlyPoint {
  const MonthlyPoint({required this.month, required this.summary});

  final DateTime month;
  final MonthSummary summary;
}
