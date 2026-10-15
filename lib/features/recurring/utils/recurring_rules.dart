import 'package:sistema_cuentas/core/models/movement_type.dart';
import 'package:sistema_cuentas/core/utils/currency_formatter.dart';
import 'package:sistema_cuentas/core/utils/date_formatter.dart';
import 'package:sistema_cuentas/core/utils/text_formatter.dart';
import 'package:sistema_cuentas/features/catalogs/models/category.dart';
import 'package:sistema_cuentas/features/catalogs/models/contact.dart';
import 'package:sistema_cuentas/features/catalogs/models/payment_method.dart';
import 'package:sistema_cuentas/features/recurring/models/finish_draft.dart';
import 'package:sistema_cuentas/features/recurring/models/recurring_draft.dart';
import 'package:sistema_cuentas/features/recurring/models/recurring_payment.dart';

/// Qué acuerdos se ven en la lista.
enum RecurringFilter {
  active('Activos'),
  finished('Finalizados');

  const RecurringFilter(this.label);

  final String label;
}

/// Reglas puras de los pagos recurrentes (sin Flutter).
abstract final class RecurringRules {
  static const descriptionMinLength = 2;
  static const descriptionMaxLength = 120;
  static const noteMaxLength = 255;
  static const closingNoteMinLength = 3;
  static const closingNoteMaxLength = 255;

  /// Cada cuántos meses se repite (los valores que acepta el servidor).
  static const everyMonthsOptions = [1, 2, 3, 4, 6, 12];

  static List<RecurringPayment> filter(
    List<RecurringPayment> list,
    RecurringFilter filter,
  ) => sort([
    for (final p in list)
      if (p.active == (filter == RecurringFilter.active)) p,
  ]);

  /// Por día de pago y nombre (los finalizados, por fecha de cierre).
  static List<RecurringPayment> sort(List<RecurringPayment> list) {
    final sorted = list.toList()
      ..sort((a, b) {
        final byState = (a.active ? 0 : 1).compareTo(b.active ? 0 : 1);
        if (byState != 0) return byState;
        final byDay = a.dayOfMonth.compareTo(b.dayOfMonth);
        return byDay != 0
            ? byDay
            : a.description.toLowerCase().compareTo(
                b.description.toLowerCase(),
              );
      });
    return sorted;
  }

  static String cadenceLabel(int everyMonths) =>
      everyMonths == 1 ? 'Cada mes' : 'Cada $everyMonths meses';

  /// «Día 7 · Cada mes».
  static String scheduleLabel(RecurringPayment payment) =>
      'Día ${payment.dayOfMonth} · ${cadenceLabel(payment.everyMonths)}';

  /// El nombre de la fila: con quién es (el contacto) y, si no tiene, qué es.
  static String title(RecurringPayment payment) =>
      formatDisplayText(payment.contact ?? payment.description);

  /// Bajo el nombre, por datos: qué es (o su categoría sin contacto), cuándo
  /// se repite y, si está activo, su próximo vencimiento.
  static List<String> subtitleParts(RecurringPayment payment) {
    final what = payment.contact != null
        ? payment.description
        : payment.category;
    final next = payment.nextDueDate;
    return [
      formatDisplayText(what),
      scheduleLabel(payment),
      if (payment.active && next != null) 'próximo ${formatShortDate(next)}',
    ];
  }

  static String subtitle(RecurringPayment payment) =>
      subtitleParts(payment).join(' · ');

  /// La pregunta al eliminar un acuerdo.
  static String deleteQuestion(String name) =>
      '¿Eliminar «${formatDisplayText(name)}»?';

  /// Qué pasa al eliminar, sin rodeos.
  static String deleteConsequence({required bool isIncome}) =>
      'Dejará de generar ${isIncome ? 'cobros' : 'pagos'} cada mes y se '
      'quitan todos los meses sin ${isIncome ? 'cobrar' : 'pagar'}, también '
      'los vencidos. Lo que ya registraste se conserva y el acuerdo queda en '
      '«Finalizados».';

  // --- Crear ---------------------------------------------------------------

  static String? validateDescription(String? value) {
    final text = (value ?? '').trim();
    if (text.length < descriptionMinLength) {
      return 'Escribe el nombre (mínimo $descriptionMinLength letras).';
    }
    return null;
  }

  static String? validateValue(String? text) {
    final amount = parseCopInput(text);
    if (amount == null || amount <= 0) return 'Escribe el valor.';
    return null;
  }

  static String? validateDay(String? text) {
    final day = int.tryParse((text ?? '').trim());
    if (day == null || day < 1 || day > 31) return 'Un día del 1 al 31.';
    return null;
  }

  static String? validateCategory(Category? category) =>
      category == null ? 'Elige la categoría.' : null;

  static RecurringDraft buildDraft({
    required MovementType type,
    required String description,
    required String valueText,
    required String dayText,
    required int everyMonths,
    required DateTime startDate,
    required Category category,
    required Contact? contact,
    required String capitalText,
    String note = '',
  }) {
    final capital = parseCopInput(capitalText);
    final trimmedNote = note.trim();
    return RecurringDraft(
      type: type,
      description: description.trim(),
      valuePesos: int.parse(normalizeCopInput(valueText)),
      dayOfMonth: int.parse(dayText.trim()),
      everyMonths: everyMonths,
      startDate: dateOnly(startDate),
      categoryId: category.id,
      contactId: contact?.id,
      capitalPesos: (capital == null || capital <= 0) ? null : capital.round(),
      note: trimmedNote.isEmpty ? null : trimmedNote,
    );
  }

  // --- Finalizar -----------------------------------------------------------

  static String? validateClosingNote(String? value) {
    final text = (value ?? '').trim();
    if (text.length < closingNoteMinLength) {
      return 'Cuenta por qué se cierra (mínimo $closingNoteMinLength letras).';
    }
    return null;
  }

  /// Último día elegible para cerrar: hoy, o el inicio si el acuerdo aún no
  /// empieza (así el calendario nunca queda con un rango vacío).
  static DateTime lastEndDate(DateTime start, DateTime today) {
    final a = dateOnly(start);
    final b = dateOnly(today);
    return a.isAfter(b) ? a : b;
  }

  static String? validateEndDate(
    DateTime? date, {
    required DateTime today,
    required DateTime start,
  }) {
    if (date == null) return 'Elige la fecha.';
    if (dateOnly(date).isAfter(lastEndDate(start, today))) {
      return 'La fecha no puede ser futura.';
    }
    if (dateOnly(date).isBefore(dateOnly(start))) {
      return 'No puede ser anterior al inicio del acuerdo.';
    }
    return null;
  }

  /// ¿Se escribió un capital mayor que cero?
  static bool hasCapital(String text) {
    final capital = parseCopInput(text);
    return capital != null && capital > 0;
  }

  /// Con capital hay que elegir por qué medio se movió.
  static String? validateCapitalMethod(
    String capitalText,
    PaymentMethod? method,
  ) {
    final capital = parseCopInput(capitalText);
    if (capital != null && capital > 0 && method == null) {
      return 'Elige el medio de pago del capital.';
    }
    return null;
  }

  static FinishDraft buildFinishDraft({
    required int recurringId,
    required DateTime endDate,
    required String closingNote,
    required String capitalText,
    required PaymentMethod? method,
  }) {
    final capital = parseCopInput(capitalText);
    final hasCapital = capital != null && capital > 0;
    return FinishDraft(
      recurringId: recurringId,
      endDate: dateOnly(endDate),
      closingNote: closingNote.trim(),
      capitalPesos: hasCapital ? capital.round() : null,
      methodId: hasCapital ? method?.id : null,
    );
  }
}
