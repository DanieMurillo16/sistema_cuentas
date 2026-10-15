import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_cuentas/core/utils/async_utils.dart';
import 'package:sistema_cuentas/features/recurring/data/recurring_repository.dart';
import 'package:sistema_cuentas/features/recurring/models/recurring_detail.dart';
import 'package:sistema_cuentas/features/recurring/models/recurring_payment.dart';
import 'package:sistema_cuentas/features/recurring/utils/recurring_rules.dart';
import 'package:sistema_cuentas/shared/providers/session_provider.dart';

/// Los pagos recurrentes de la sesión (activos y finalizados). Un solo lugar:
/// la pestaña, el detalle y los formularios lo leen de aquí.
final recurringListProvider =
    AsyncNotifierProvider<RecurringListNotifier, List<RecurringPayment>>(
      RecurringListNotifier.new,
    );

class RecurringListNotifier extends AsyncNotifier<List<RecurringPayment>> {
  @override
  Future<List<RecurringPayment>> build() {
    ref.watch(sessionUserIdProvider);
    return ref.read(recurringRepositoryProvider).list();
  }

  /// Agrega o reemplaza un acuerdo (por ejemplo, el recién creado).
  void upsert(RecurringPayment payment) {
    final current = state.value;
    if (current == null) return;
    final exists = current.any((p) => p.id == payment.id);
    state = AsyncData(
      RecurringRules.sort([
        for (final p in current)
          if (p.id == payment.id) payment else p,
        if (!exists) payment,
      ]),
    );
  }

  /// Quita un acuerdo de la lista que se ve (el servidor lo dejó finalizado;
  /// al volver a pedir la lista aparece en «Finalizados»).
  void remove(int id) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData([
      for (final p in current)
        if (p.id != id) p,
    ]);
  }
}

/// Activos o finalizados: lo que muestra la lista.
final recurringFilterProvider =
    NotifierProvider<RecurringFilterNotifier, RecurringFilter>(
      RecurringFilterNotifier.new,
    );

class RecurringFilterNotifier extends Notifier<RecurringFilter> {
  @override
  RecurringFilter build() => RecurringFilter.active;

  void set(RecurringFilter filter) => state = filter;
}

/// La lista que se pinta: derivada de la lista completa y del filtro.
final visibleRecurringProvider = Provider<AsyncValue<List<RecurringPayment>>>((
  ref,
) {
  final filter = ref.watch(recurringFilterProvider);
  return mapKeepingData(
    ref.watch(recurringListProvider),
    (list) => RecurringRules.filter(list, filter),
  );
});

/// ¿Se ve la invitación «Crear mi primer pago recurrente»? Con los activos
/// cargados y ninguno. Mientras se ve, el botón flotante sobra (hacen lo mismo).
final showRecurringInviteProvider = Provider<bool>((ref) {
  if (ref.watch(recurringFilterProvider) != RecurringFilter.active) {
    return false;
  }
  final visible = ref.watch(visibleRecurringProvider);
  return visible.hasValue && visible.requireValue.isEmpty;
});

/// El detalle con el historial de meses (siempre de la red: el historial no
/// está en la lista).
final recurringDetailProvider = FutureProvider.autoDispose
    .family<RecurringDetail, int>((ref, id) {
      ref.watch(sessionUserIdProvider);
      return ref.read(recurringRepositoryProvider).detail(id);
    });
