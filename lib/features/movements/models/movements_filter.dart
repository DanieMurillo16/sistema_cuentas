import 'package:flutter/material.dart';
import 'package:sistema_cuentas/core/models/movement_type.dart';

/// Lo que se filtra en la lista de ingresos o de gastos: el rango de fechas, la
/// categoría y el medio (los pide el servidor) y el texto (se busca en lo ya
/// cargado). Es inmutable: cada cambio crea uno nuevo.
class MovementsFilter {
  const MovementsFilter({
    required this.type,
    required this.range,
    this.categoryId,
    this.methodId,
    this.query = '',
  });

  /// Empieza viendo el mes completo [month].
  factory MovementsFilter.forMonth(MovementType type, DateTime month) =>
      MovementsFilter(
        type: type,
        range: DateTimeRange(
          start: DateTime(month.year, month.month),
          end: DateTime(month.year, month.month + 1, 0),
        ),
      );

  final MovementType type;
  final DateTimeRange range;
  final int? categoryId;
  final int? methodId;
  final String query;

  MovementsFilter copyWith({
    DateTimeRange? range,
    String? query,
    int? categoryId,
    bool clearCategory = false,
    int? methodId,
    bool clearMethod = false,
  }) => MovementsFilter(
    type: type,
    range: range ?? this.range,
    categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
    methodId: clearMethod ? null : (methodId ?? this.methodId),
    query: query ?? this.query,
  );

  /// Lo que se pide al servidor (sin el texto).
  MovementsQuery get serverQuery => (
    from: range.start,
    to: range.end,
    type: type,
    categoryId: categoryId,
    methodId: methodId,
  );

  /// Primer día que se puede elegir (los movimientos no son anteriores).
  static final firstDate = DateTime(2000);

  /// Último día que se puede elegir: el fin del año que viene.
  static DateTime lastDate(DateTime today) => DateTime(today.year + 1, 12, 31);

  /// ¿Hay algo que limpiar frente al mes completo [month]?
  bool isModifiedFrom(DateTime month) =>
      hasExtras ||
      range !=
          DateTimeRange(
            start: DateTime(month.year, month.month),
            end: DateTime(month.year, month.month + 1, 0),
          );

  /// Hay categoría, medio o texto elegidos.
  bool get hasExtras =>
      categoryId != null || methodId != null || query.trim().isNotEmpty;
}

/// La consulta al servidor de una lista filtrada. Un `record` se compara por
/// valor, así que sirve de llave de un provider por familia.
typedef MovementsQuery = ({
  DateTime from,
  DateTime to,
  MovementType type,
  int? categoryId,
  int? methodId,
});
