import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_cuentas/core/utils/async_utils.dart';
import 'package:sistema_cuentas/features/dues/data/dues_repository.dart';
import 'package:sistema_cuentas/features/dues/models/due.dart';
import 'package:sistema_cuentas/features/dues/models/dues_month.dart';
import 'package:sistema_cuentas/features/dues/utils/dues_rules.dart';
import 'package:sistema_cuentas/shared/providers/selected_month_provider.dart';
import 'package:sistema_cuentas/shared/providers/session_provider.dart';

/// Los vencimientos del mes elegido en la cabecera, con sus totales. El
/// servidor es la fuente de los saldos: cada pago registrado lo invalida y la
/// pantalla conserva lo que muestra mientras llega la respuesta.
final duesProvider = AsyncNotifierProvider<DuesNotifier, DuesMonth>(
  DuesNotifier.new,
);

class DuesNotifier extends AsyncNotifier<DuesMonth> {
  @override
  Future<DuesMonth> build() {
    ref.watch(sessionUserIdProvider);
    final month = ref.watch(selectedMonthProvider);
    return ref.read(duesRepositoryProvider).month(month);
  }

  /// Quita de lo que se ve los vencimientos de un acuerdo que se eliminó. Los
  /// totales los vuelve a pedir quien llama (el servidor los calcula).
  void removeByRecurring(int recurringId) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(
      DuesMonth(
        dues: [
          for (final d in current.dues)
            if (d.recurringId != recurringId) d,
        ],
        totals: current.totals,
      ),
    );
  }
}

/// Qué tipo se ve en «Este mes» (todos, los que me pagan, los que yo pago).
final dueFilterProvider = NotifierProvider<DueFilterNotifier, DueFilter>(
  DueFilterNotifier.new,
);

class DueFilterNotifier extends Notifier<DueFilter> {
  @override
  DueFilter build() => DueFilter.all;

  void set(DueFilter filter) => state = filter;
}

/// Los vencimientos que se pintan: derivados del mes y del filtro.
final visibleDuesProvider = Provider<AsyncValue<List<Due>>>((ref) {
  final filter = ref.watch(dueFilterProvider);
  return mapKeepingData(
    ref.watch(duesProvider),
    (month) => DuesRules.filterAndSort(month.dues, filter),
  );
});
