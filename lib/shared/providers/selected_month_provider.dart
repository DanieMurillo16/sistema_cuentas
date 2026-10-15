import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_cuentas/shared/providers/session_provider.dart';

/// El mes que muestran Inicio, Pagos recurrentes y Resumen (día 1 del mes).
/// Empieza en el mes actual. Como máximo se puede avanzar hasta el mes
/// siguiente: es lo que aceptan vencimientos y resumen en la API.
final selectedMonthProvider = NotifierProvider<SelectedMonthNotifier, DateTime>(
  SelectedMonthNotifier.new,
);

class SelectedMonthNotifier extends Notifier<DateTime> {
  @override
  DateTime build() {
    // Otra cuenta empieza otra vez en el mes actual.
    ref.watch(sessionUserIdProvider);
    final now = DateTime.now();
    return DateTime(now.year, now.month);
  }

  void previous() => state = DateTime(state.year, state.month - 1);

  void next() {
    if (_canGoNext(state)) state = DateTime(state.year, state.month + 1);
  }
}

bool _canGoNext(DateTime month) {
  final now = DateTime.now();
  return month.isBefore(DateTime(now.year, now.month + 1));
}

/// ¿Se puede avanzar un mes más? Lo observa la cabecera para apagar la flecha.
final canGoNextMonthProvider = Provider<bool>(
  (ref) => _canGoNext(ref.watch(selectedMonthProvider)),
);
