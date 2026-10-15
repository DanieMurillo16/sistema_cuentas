import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_cuentas/features/dues/providers/dues_provider.dart';
import 'package:sistema_cuentas/features/movements/data/movements_repository.dart';
import 'package:sistema_cuentas/features/movements/models/due_payment_draft.dart';
import 'package:sistema_cuentas/features/movements/providers/movements_provider.dart';
import 'package:sistema_cuentas/features/recurring/providers/recurring_list_provider.dart';
import 'package:sistema_cuentas/features/summary/providers/month_summary_provider.dart';

/// Escritura: registrar un pago o abono de un vencimiento. Al terminar bien se
/// ve en el historial de Inicio y se vuelven a pedir lo que quedó viejo (los
/// saldos del mes, el resumen, el acuerdo y su detalle).
final payDueProvider = AsyncNotifierProvider.autoDispose<PayDueNotifier, void>(
  PayDueNotifier.new,
);

class PayDueNotifier extends AsyncNotifier<void> {
  @override
  void build() {}

  Future<void> pay(DuePaymentDraft draft) async {
    if (state.isLoading) return; // anti doble envío (no solo el botón)
    // Si se cierra la pantalla mientras guarda, la escritura termina y la app
    // se entera igual (el servidor ya la registró).
    final keepAlive = ref.keepAlive();
    state = const AsyncLoading();
    try {
      state = await AsyncValue.guard(() async {
        final movement = await ref
            .read(movementsRepositoryProvider)
            .registerDuePayment(draft);
        ref.read(movementsProvider.notifier).upsert(movement);
        ref.invalidate(duesProvider);
        ref.invalidate(monthSummaryProvider);
        ref.invalidate(recurringListProvider);
        ref.invalidate(recurringDetailProvider(draft.recurringId));
      });
    } finally {
      keepAlive.close();
    }
  }
}
