import 'package:sistema_cuentas/core/models/movement_type.dart';
import 'package:sistema_cuentas/features/catalogs/models/contact.dart';
import 'package:sistema_cuentas/features/dues/models/due.dart';
import 'package:sistema_cuentas/features/dues/models/due_totals.dart';
import 'package:sistema_cuentas/features/dues/models/dues_month.dart';
import 'package:sistema_cuentas/features/recurring/models/due_history_item.dart';
import 'package:sistema_cuentas/features/recurring/models/recurring_detail.dart';
import 'package:sistema_cuentas/features/recurring/models/recurring_payment.dart';

/// Nombre de un acuerdo de 60+ caracteres para probar que nada se desborda.
const longRecurringName =
    'Arriendo del local comercial de la carrera séptima con calle 45 oficina 301';

/// Contacto de 40+ caracteres.
const longContactName =
    'Inversiones y Asesorías Hernández Castellanos y Asociados S.A.S.';

/// `vencimiento` de `backend/docs/API.md`, con el dinero como texto.
Map<String, dynamic> dueJson({
  int id = 1,
  int recurringId = 10,
  String type = 'INGRESO',
  String description = 'Arriendo de Oscar',
  String period = '2026-10-01',
  String dueDate = '2026-10-07',
  String expected = '180000.00',
  String paid = '0.00',
  String balance = '180000.00',
  String status = 'PENDIENTE',
  bool overdue = false,
  int daysToDue = 3,
  int categoryId = 9,
  String category = 'Arriendos',
  int? contactId,
  String? contact,
}) => {
  'id_vencimiento': id,
  'id_pago_recurrente': recurringId,
  'tipo': type,
  'descripcion': description,
  'periodo': period,
  'fecha_vencimiento': dueDate,
  'valor_esperado': expected,
  'pagado': paid,
  'saldo': balance,
  'estado': status,
  'vencido': overdue,
  'dias_para_vencer': daysToDue,
  'id_categoria': categoryId,
  'categoria': category,
  'id_contacto': ?contactId,
  'contacto': ?contact,
};

/// Un vencimiento ya armado. Por defecto: un ingreso pendiente de 180.000.
Due buildDue({
  int id = 1,
  int recurringId = 10,
  MovementType type = MovementType.income,
  String description = 'Arriendo de Oscar',
  DateTime? period,
  DateTime? dueDate,
  int expectedCents = 18000000,
  int paidCents = 0,
  int? balanceCents,
  DueStatus status = DueStatus.pending,
  bool overdue = false,
  int daysToDue = 3,
  String category = 'Arriendos',
  int? contactId,
  String? contact,
}) => Due(
  id: id,
  recurringId: recurringId,
  type: type,
  description: description,
  period: period ?? DateTime(2026, 10),
  dueDate: dueDate ?? DateTime(2026, 10, 7),
  expectedCents: expectedCents,
  paidCents: paidCents,
  balanceCents: balanceCents ?? expectedCents - paidCents,
  status: status,
  overdue: overdue,
  daysToDue: daysToDue,
  categoryId: 9,
  category: category,
  contactId: contactId,
  contact: contact,
);

/// `totales[]` de `vencimientos/listar.php`.
Map<String, dynamic> dueTotalsJson({
  String type = 'INGRESO',
  int count = 1,
  String expected = '180000.00',
  String paid = '0.00',
  String balance = '180000.00',
  int pending = 1,
  int overdue = 0,
}) => {
  'tipo': type,
  'cantidad': count,
  'esperado': expected,
  'pagado': paid,
  'saldo': balance,
  'cantidad_pendiente': pending,
  'cantidad_vencida': overdue,
};

DueTotals buildDueTotals({
  MovementType type = MovementType.income,
  int count = 1,
  int expectedCents = 18000000,
  int paidCents = 0,
  int balanceCents = 18000000,
  int pendingCount = 1,
  int overdueCount = 0,
}) => DueTotals(
  type: type,
  count: count,
  expectedCents: expectedCents,
  paidCents: paidCents,
  balanceCents: balanceCents,
  pendingCount: pendingCount,
  overdueCount: overdueCount,
);

/// El mes con sus totales. Si no se pasan totales, se calculan del saldo de
/// los vencimientos (solo para dejar las pruebas legibles).
DuesMonth buildDuesMonth(List<Due> dues, {List<DueTotals>? totals}) =>
    DuesMonth(
      dues: dues,
      totals:
          totals ??
          [
            for (final type in MovementType.values)
              if (dues.any((d) => d.type == type))
                buildDueTotals(
                  type: type,
                  count: dues.where((d) => d.type == type).length,
                  balanceCents: dues
                      .where((d) => d.type == type)
                      .fold(0, (sum, d) => sum + d.balanceCents),
                ),
          ],
    );

/// `pago_recurrente` de `backend/docs/API.md`.
Map<String, dynamic> recurringJson({
  int id = 10,
  String type = 'INGRESO',
  String description = 'Arriendo de Oscar',
  String value = '180000.00',
  int day = 7,
  int everyMonths = 1,
  String startDate = '2026-01-07',
  int categoryId = 9,
  String category = 'Arriendos',
  String status = 'ACTIVO',
  int? contactId,
  String? contact,
  String? capital,
  String? note,
  String? endDate,
  String? closingNote,
  String? totalPaid,
  String? nextDue,
}) => {
  'id_pago_recurrente': id,
  'tipo': type,
  'descripcion': description,
  'valor': value,
  'dia_pago': day,
  'cada_meses': everyMonths,
  'fecha_inicio': startDate,
  'id_categoria': categoryId,
  'categoria': category,
  'estado': status,
  'id_contacto': ?contactId,
  'contacto': ?contact,
  'capital': ?capital,
  'nota': ?note,
  'fecha_fin': ?endDate,
  'nota_cierre': ?closingNote,
  'total_pagado': ?totalPaid,
  'proximo_vencimiento': ?nextDue,
};

RecurringPayment buildRecurring({
  int id = 10,
  MovementType type = MovementType.income,
  String description = 'Arriendo de Oscar',
  int valueCents = 18000000,
  int day = 7,
  int everyMonths = 1,
  DateTime? startDate,
  String category = 'Arriendos',
  bool active = true,
  String? contact,
  int? capitalCents,
  String? note,
  DateTime? endDate,
  String? closingNote,
  int? totalPaidCents,
  DateTime? nextDueDate,
}) => RecurringPayment(
  id: id,
  type: type,
  description: description,
  valueCents: valueCents,
  dayOfMonth: day,
  everyMonths: everyMonths,
  startDate: startDate ?? DateTime(2026, 1, 7),
  categoryId: 9,
  category: category,
  active: active,
  contact: contact,
  capitalCents: capitalCents,
  note: note,
  endDate: endDate,
  closingNote: closingNote,
  totalPaidCents: totalPaidCents,
  nextDueDate: nextDueDate,
);

/// `vencimiento_historial` (una fila de `detalle.php → vencimientos`).
Map<String, dynamic> historyJson({
  int id = 1,
  String period = '2026-10-01',
  String dueDate = '2026-10-07',
  String expected = '180000.00',
  String paid = '0.00',
  String balance = '180000.00',
  String status = 'PENDIENTE',
  bool overdue = false,
  int daysToDue = 3,
}) => {
  'id_vencimiento': id,
  'periodo': period,
  'fecha_vencimiento': dueDate,
  'valor_esperado': expected,
  'pagado': paid,
  'saldo': balance,
  'estado': status,
  'vencido': overdue,
  'dias_para_vencer': daysToDue,
};

DueHistoryItem buildHistoryItem({
  int id = 1,
  DateTime? period,
  int expectedCents = 18000000,
  int paidCents = 0,
  DueStatus status = DueStatus.pending,
  bool overdue = false,
  int daysToDue = 3,
}) => DueHistoryItem(
  id: id,
  period: period ?? DateTime(2026, 10),
  dueDate: (period ?? DateTime(2026, 10)).add(const Duration(days: 6)),
  expectedCents: expectedCents,
  paidCents: paidCents,
  balanceCents: expectedCents - paidCents,
  status: status,
  overdue: overdue,
  daysToDue: daysToDue,
);

/// El detalle con `n` meses de historial (el más reciente primero).
RecurringDetail buildDetail({
  RecurringPayment? payment,
  List<DueHistoryItem>? history,
}) => RecurringDetail(
  payment: payment ?? buildRecurring(),
  history: history ?? [buildHistoryItem()],
);

/// Historial largo: `months` meses hacia atrás desde octubre de 2026.
List<DueHistoryItem> longHistory(int months) => [
  for (var i = 0; i < months; i++)
    buildHistoryItem(
      id: 1000 - i,
      period: DateTime(2026, 10 - i),
      paidCents: i.isEven ? 18000000 : 0,
      status: i.isEven ? DueStatus.paid : DueStatus.pending,
      overdue: i.isOdd,
      daysToDue: -30 * i,
    ),
];

Map<String, dynamic> contactJson({
  int id = 4,
  String name = 'Oscar',
  bool active = true,
  String? phone,
  String? note,
  String? icon,
  String? color,
}) => {
  'id_contacto': id,
  'nombre': name,
  'activo': active,
  'telefono': ?phone,
  'nota': ?note,
  'icono': ?icon,
  'color': ?color,
};

Contact buildContact({
  int id = 4,
  String name = 'Oscar',
  bool active = true,
  String? phone,
  String? note,
  String? icon,
  String? color,
}) => Contact(
  id: id,
  name: name,
  active: active,
  phone: phone,
  note: note,
  icon: icon,
  color: color,
);
