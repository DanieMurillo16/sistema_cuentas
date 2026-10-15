import 'package:sistema_cuentas/features/recurring/models/due_history_item.dart';
import 'package:sistema_cuentas/features/recurring/models/recurring_payment.dart';

/// Un pago recurrente con su historial de meses (el más reciente primero).
class RecurringDetail {
  const RecurringDetail({required this.payment, required this.history});

  final RecurringPayment payment;
  final List<DueHistoryItem> history;
}
