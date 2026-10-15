import 'package:sistema_cuentas/core/models/movement_type.dart';
import 'package:sistema_cuentas/core/utils/currency_formatter.dart';
import 'package:sistema_cuentas/core/utils/date_formatter.dart';
import 'package:sistema_cuentas/core/utils/text_formatter.dart';
import 'package:sistema_cuentas/features/catalogs/models/payment_method.dart';
import 'package:sistema_cuentas/features/dues/models/due.dart';
import 'package:sistema_cuentas/features/movements/models/due_payment_draft.dart';

/// Qué vencimientos se ven en «Este mes».
enum DueFilter {
  all('Todos'),
  income('Me pagan'),
  expense('Yo pago');

  const DueFilter(this.label);

  final String label;
}

/// Cómo se pinta el estado de un vencimiento.
enum DueTone { neutral, success, warning, danger }

class DueStatusInfo {
  const DueStatusInfo(this.label, this.tone);

  final String label;
  final DueTone tone;
}

/// Reglas puras de los vencimientos (sin Flutter).
abstract final class DuesRules {
  static const noteMaxLength = 255;

  /// Filtra por tipo y ordena: primero lo abierto (lo vencido arriba, luego por
  /// fecha) y al final lo pagado u omitido.
  static List<Due> filterAndSort(List<Due> dues, DueFilter filter) {
    final visible = [
      for (final due in dues)
        if (filter == DueFilter.all ||
            (filter == DueFilter.income) == due.isIncome)
          due,
    ];
    visible.sort((a, b) {
      final byOpen = (a.canPay ? 0 : 1).compareTo(b.canPay ? 0 : 1);
      if (byOpen != 0) return byOpen;
      final byDate = a.dueDate.compareTo(b.dueDate);
      return byDate != 0 ? byDate : a.id.compareTo(b.id);
    });
    return visible;
  }

  static DueStatusInfo statusInfo(Due due) => statusInfoFor(
    status: due.status,
    overdue: due.overdue,
    daysToDue: due.daysToDue,
    isIncome: due.isIncome,
  );

  /// El estado como texto y tono. Sirve igual para un vencimiento de «Este mes»
  /// que para un mes del historial de un acuerdo.
  static DueStatusInfo statusInfoFor({
    required DueStatus status,
    required bool overdue,
    required int daysToDue,
    required bool isIncome,
  }) {
    switch (status) {
      case DueStatus.cancelled:
        return const DueStatusInfo('Omitido', DueTone.neutral);
      case DueStatus.paid:
        return DueStatusInfo(isIncome ? 'Cobrado' : 'Pagado', DueTone.success);
      case DueStatus.pending:
      case DueStatus.partial:
        break;
    }
    final prefix = status == DueStatus.partial ? 'Parcial · ' : '';
    if (overdue) {
      return DueStatusInfo(
        '${prefix}Vencido hace ${_days(daysToDue.abs())}',
        DueTone.danger,
      );
    }
    if (daysToDue == 0) {
      return DueStatusInfo('${prefix}Se paga hoy', DueTone.warning);
    }
    return DueStatusInfo(
      '${prefix}Se paga en ${_days(daysToDue)}',
      status == DueStatus.partial ? DueTone.warning : DueTone.neutral,
    );
  }

  static String _days(int days) => days == 1 ? '1 día' : '$days días';

  /// Lo que dice el botón de la fila: «Cobrar» (me pagan) o «Pagar» (yo pago).
  static String actionLabel(Due due) => due.isIncome ? 'Cobrar' : 'Pagar';

  /// Lo que dice el botón del diálogo.
  static String confirmLabel(Due due) =>
      due.isIncome ? 'Registrar cobro' : 'Registrar pago';

  /// El nombre de la fila: con quién es (el contacto) y, si no tiene, qué es.
  /// Así dos «Desarrollo mensual» de clientes distintos no se ven iguales.
  static String tileTitle(Due due) =>
      formatDisplayText(due.contact ?? due.description);

  /// Bajo el nombre, por datos: qué es (o su categoría si no hay contacto) y la
  /// fecha. Cada dato va entero en una línea (ver `DotSeparatedText`).
  static List<String> tileSubtitleParts(Due due) => [
    formatDisplayText(due.contact != null ? due.description : due.category),
    formatShortDate(due.dueDate),
  ];

  static String tileSubtitle(Due due) => tileSubtitleParts(due).join(' · ');

  /// Bajo el título del diálogo: con quién y de qué es («Oscar FCS · Desarrollo
  /// mensual»); sin contacto, solo la descripción.
  static String payDialogSubtitle(Due due) => [
    if (due.contact != null) formatDisplayText(due.contact!),
    formatDisplayText(due.description),
  ].join(' · ');

  static String? validateAmount(String? text, Due due) {
    final amount = parseCopInput(text);
    if (amount == null || amount <= 0) return 'Escribe el valor.';
    if (amount * 100 > due.balanceCents) {
      return 'No puede pasar del saldo (${formatCents(due.balanceCents)}).';
    }
    return null;
  }

  static String? validatePaymentMethod(PaymentMethod? method) =>
      method == null ? 'Elige el medio de pago.' : null;

  static String? validateDate(DateTime? date, {required DateTime today}) {
    if (date == null) return 'Elige la fecha.';
    if (dateOnly(date).isAfter(dateOnly(today))) {
      return 'La fecha no puede ser futura.';
    }
    return null;
  }

  static DuePaymentDraft buildDraft({
    required Due due,
    required String amountText,
    required DateTime date,
    required PaymentMethod method,
    required String note,
  }) {
    final trimmed = note.trim();
    return DuePaymentDraft(
      dueId: due.id,
      recurringId: due.recurringId,
      type: due.isIncome ? MovementType.income : MovementType.expense,
      amountPesos: int.parse(normalizeCopInput(amountText)),
      date: dateOnly(date),
      methodId: method.id,
      note: trimmed.isEmpty ? null : trimmed,
    );
  }
}
