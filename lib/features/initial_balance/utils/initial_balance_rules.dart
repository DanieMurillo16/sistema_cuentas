import 'package:sistema_cuentas/core/utils/currency_formatter.dart';
import 'package:sistema_cuentas/features/catalogs/models/payment_method.dart';
import 'package:sistema_cuentas/features/initial_balance/models/initial_balance_entry.dart';

/// Cómo se reparte el saldo inicial: un valor por cada medio de pago o uno solo
/// en un medio.
enum InitialBalanceMode {
  byMethod('Por medio'),
  single('Un valor');

  const InitialBalanceMode(this.label);

  final String label;
}

/// Reglas puras del saldo inicial (sin Flutter).
abstract final class InitialBalanceRules {
  /// La categoría con la que se registra. Es de capital: es plata que ya tenías,
  /// no un ingreso del mes, así que se separa de lo operativo en el resumen y
  /// cuenta en el balance.
  static const categoryName = 'Saldo inicial';
  static const description = 'Saldo inicial';

  /// Opcional: vacío vale; si hay algo debe ser un valor mayor que cero.
  static String? validateOptionalAmount(String? text) {
    if ((text ?? '').trim().isEmpty) return null;
    final amount = parseCopInput(text);
    if (amount == null || amount <= 0) {
      return 'Escribe un valor mayor que cero.';
    }
    return null;
  }

  static String? validateAmount(String? text) {
    final amount = parseCopInput(text);
    if (amount == null || amount <= 0) return 'Escribe el valor.';
    return null;
  }

  static String? validateMethod(PaymentMethod? method) =>
      method == null ? 'Elige el medio de pago.' : null;

  /// Los medios con un valor mayor que cero, en el orden de [methods].
  static List<InitialBalanceEntry> entriesByMethod({
    required List<PaymentMethod> methods,
    required Map<int, String> texts,
  }) {
    final entries = <InitialBalanceEntry>[];
    for (final method in methods) {
      final amount = parseCopInput(texts[method.id]);
      if (amount != null && amount > 0) {
        entries.add(
          InitialBalanceEntry(methodId: method.id, pesos: amount.round()),
        );
      }
    }
    return entries;
  }

  /// Un valor en un medio; `null` si falta alguno de los dos.
  static List<InitialBalanceEntry> entriesSingle({
    required String text,
    required PaymentMethod? method,
  }) {
    final amount = parseCopInput(text);
    if (amount == null || amount <= 0 || method == null) return const [];
    return [InitialBalanceEntry(methodId: method.id, pesos: amount.round())];
  }

  /// Lo escrito en el modo de un solo valor (aunque falte elegir el medio): para
  /// mostrar el total mientras se llena.
  static int pesosOf(String text) => (parseCopInput(text) ?? 0).round();

  static int totalPesos(List<InitialBalanceEntry> entries) =>
      entries.fold(0, (sum, e) => sum + e.pesos);
}
