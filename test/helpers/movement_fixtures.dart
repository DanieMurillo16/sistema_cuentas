import 'package:sistema_cuentas/core/models/movement_type.dart';
import 'package:sistema_cuentas/features/catalogs/models/category.dart';
import 'package:sistema_cuentas/features/catalogs/models/payment_method.dart';
import 'package:sistema_cuentas/features/movements/models/movement.dart';
import 'package:sistema_cuentas/features/summary/models/summary_totals.dart';

/// Descripción de 60+ caracteres para probar que nada se desborda.
const longDescription =
    'Pago de la cuota extraordinaria de administración del conjunto residencial '
    'torre norte apartamento 1204 incluye intereses de mora';

/// Nombre de categoría o medio de 40+ caracteres.
const longCatalogName =
    'Servicios públicos domiciliarios y otros conceptos varios del hogar';

/// Importe de 12 dígitos (el máximo del formulario), como lo manda la API.
const twelveDigitsAmount = '999999999999.00';

/// `movimiento_lista` de `backend/docs/API.md`, con el dinero como texto.
Map<String, dynamic> movementJson({
  int id = 1,
  String type = 'GASTO',
  String value = '25000.00',
  String date = '2026-10-13',
  String description = 'Mercado',
  int categoryId = 3,
  String category = 'Alimentación',
  int methodId = 2,
  String method = 'Nequi',
  bool isCapital = false,
  String origin = 'PUNTUAL',
  bool cancelled = false,
  String? contact,
  String? note,
  String? createdAt,
}) => {
  'id_movimiento': id,
  'tipo': type,
  'valor': value,
  'fecha': date,
  'descripcion': description,
  'id_categoria': categoryId,
  'categoria': category,
  'id_medio': methodId,
  'medio': method,
  'es_capital': isCapital,
  'origen': origin,
  'anulado': cancelled,
  'contacto': ?contact,
  'nota': ?note,
  'creado_en': ?createdAt,
};

Movement buildMovement({
  int id = 1,
  MovementType type = MovementType.expense,
  int valueCents = 2500000,
  DateTime? date,
  String description = 'Mercado',
  String category = 'Alimentación',
  String method = 'Nequi',
  String? contact,
  String? note,
  int categoryId = 3,
  int methodId = 2,
  bool fromRecurring = false,
  DateTime? createdAt,
}) => Movement(
  id: id,
  type: type,
  valueCents: valueCents,
  date: date ?? DateTime(2026, 10, 13),
  description: description,
  categoryId: categoryId,
  category: category,
  methodId: methodId,
  method: method,
  isCapital: false,
  fromRecurring: fromRecurring,
  cancelled: false,
  contact: contact,
  note: note,
  createdAt: createdAt,
);

Map<String, dynamic> categoryJson({
  int id = 3,
  String type = 'GASTO',
  String name = 'Alimentación',
  bool isCapital = false,
  bool active = true,
  String? icon,
  String? color,
}) => {
  'id_categoria': id,
  'tipo': type,
  'nombre': name,
  'es_capital': isCapital,
  'activo': active,
  'icono': ?icon,
  'color': ?color,
};

Category buildCategory({
  int id = 3,
  MovementType type = MovementType.expense,
  String name = 'Alimentación',
  bool active = true,
  bool deleted = false,
  String? icon,
  String? color,
}) => Category(
  id: id,
  type: type,
  name: name,
  isCapital: false,
  active: active,
  deleted: deleted,
  icon: icon,
  color: color,
);

Map<String, dynamic> methodJson({
  int id = 2,
  String name = 'Nequi',
  bool active = true,
}) => {'id_medio': id, 'nombre': name, 'activo': active};

PaymentMethod buildMethod({
  int id = 2,
  String name = 'Nequi',
  bool active = true,
}) => PaymentMethod(id: id, name: name, active: active);

/// `resumen.totales` de la API.
Map<String, dynamic> summaryTotalsJson({
  String income = '1500000.00',
  String expense = '420000.50',
  String netFlow = '1079999.50',
  int count = 12,
}) => {
  'ingresos_total': income,
  'ingresos_operativos': income,
  'capital_recuperado': '0.00',
  'gastos_total': expense,
  'gastos_operativos': expense,
  'capital_entregado': '0.00',
  'balance_operativo': netFlow,
  'flujo_neto': netFlow,
  'movimientos': count,
};

SummaryTotals buildTotals({
  int incomeCents = 150000000,
  int expenseCents = 42000050,
  int netFlowCents = 107999950,
  int count = 12,
}) => SummaryTotals(
  incomeTotalCents: incomeCents,
  expenseTotalCents: expenseCents,
  netFlowCents: netFlowCents,
  operatingBalanceCents: netFlowCents,
  capitalRecoveredCents: 0,
  capitalDeliveredCents: 0,
  movementCount: count,
);

/// Categorías y medios típicos para el formulario.
List<Category> defaultCategories() => [
  buildCategory(id: 3, name: 'Alimentación'),
  buildCategory(id: 4, name: 'Transporte'),
  buildCategory(id: 9, type: MovementType.income, name: 'Salario'),
];

List<PaymentMethod> defaultMethods() => [
  buildMethod(id: 2, name: 'Nequi'),
  buildMethod(id: 5, name: 'Bancolombia'),
];

/// Un día del mes actual (para que `upsert` y los encabezados «Hoy» sirvan
/// sin importar cuándo se corra la prueba).
DateTime dayOfCurrentMonth(int day) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, day);
}

String apiDay(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
