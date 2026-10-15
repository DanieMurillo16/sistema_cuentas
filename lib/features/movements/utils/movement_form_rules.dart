import 'package:sistema_cuentas/core/models/movement_type.dart';
import 'package:sistema_cuentas/core/utils/currency_formatter.dart';
import 'package:sistema_cuentas/core/utils/date_formatter.dart';
import 'package:sistema_cuentas/features/catalogs/models/category.dart';
import 'package:sistema_cuentas/features/catalogs/models/payment_method.dart';
import 'package:sistema_cuentas/features/movements/models/movement_draft.dart';

/// Reglas del formulario de ingreso/gasto (puras, sin Flutter).
abstract final class MovementFormRules {
  static const maxAmountDigits = 10;
  // Dígitos + puntos de miles que admite el campo del monto.
  static const maxAmountChars = 13;
  static final firstDate = DateTime(2000);

  /// Último día elegible: hoy (no se registran movimientos futuros).
  static DateTime lastDate(DateTime today) => dateOnly(today);
  static const descriptionMaxLength = 120;
  static const noteMaxLength = 255;

  static String? validateAmount(String? text) {
    final amount = parseCopInput(text);
    if (amount == null || amount <= 0) return 'Escribe el valor.';
    return null;
  }

  static String? validateDate(DateTime? date, {required DateTime today}) {
    if (date == null) return 'Elige la fecha.';
    if (dateOnly(date).isAfter(dateOnly(today))) {
      return 'La fecha no puede ser futura.';
    }
    return null;
  }

  static String? validateCategory(Category? category) =>
      category == null ? 'Elige la categoría.' : null;

  static String? validatePaymentMethod(PaymentMethod? method) =>
      method == null ? 'Elige el medio de pago.' : null;

  /// Arma lo que se envía. Sin descripción, el movimiento se llama como su
  /// categoría (el servidor exige un nombre para un movimiento suelto).
  static MovementDraft buildDraft({
    required MovementType type,
    required String amountText,
    required DateTime date,
    required String description,
    required Category category,
    required PaymentMethod method,
    String note = '',
  }) {
    final trimmed = description.trim();
    final trimmedNote = note.trim();
    return MovementDraft(
      type: type,
      amountPesos: int.parse(normalizeCopInput(amountText)),
      date: dateOnly(date),
      description: trimmed.isEmpty ? category.name : trimmed,
      categoryId: category.id,
      methodId: method.id,
      note: trimmedNote.isEmpty ? null : trimmedNote,
    );
  }
}
