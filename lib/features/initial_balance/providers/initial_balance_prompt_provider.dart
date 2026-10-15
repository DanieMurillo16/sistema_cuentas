import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_cuentas/core/models/session.dart';
import 'package:sistema_cuentas/features/movements/providers/movements_provider.dart';
import 'package:sistema_cuentas/features/summary/providers/summary_trend_provider.dart';
import 'package:sistema_cuentas/shared/providers/permission_provider.dart';
import 'package:sistema_cuentas/shared/providers/selected_month_provider.dart';

/// ¿Invitar a registrar el saldo inicial en Inicio? Solo la primera vez: se ve
/// el mes actual, está vacío y el mes anterior también (quien ya usa la app no
/// necesita el aviso). Hace falta poder registrar movimientos.
final showInitialBalancePromptProvider = Provider<bool>((ref) {
  if (!ref.watch(hasPermissionProvider(Permissions.registerMovements))) {
    return false;
  }
  final month = ref.watch(selectedMonthProvider);
  final now = DateTime.now();
  if (month.year != now.year || month.month != now.month) return false;
  final movements = ref.watch(movementsProvider);
  if (movements.hasError || !movements.hasValue) return false;
  if (movements.requireValue.isNotEmpty) return false;
  final previous = ref.watch(previousMonthSummaryProvider);
  if (previous.hasError || !previous.hasValue) return false;
  return previous.requireValue.isEmpty;
});
