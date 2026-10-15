import 'package:sistema_cuentas/core/models/movement_type.dart';
import 'package:sistema_cuentas/core/utils/date_formatter.dart';
import 'package:sistema_cuentas/features/movements/models/movement.dart';
import 'package:sistema_cuentas/shared/utils/search_options.dart';

/// Posición de una fila dentro de su día (para redondear solo los extremos).
enum RowPosition { only, first, middle, last }

/// Una línea del historial: encabezado de un día o un movimiento.
sealed class MovementEntry {
  const MovementEntry();
}

class DayHeaderEntry extends MovementEntry {
  const DayHeaderEntry({
    required this.date,
    required this.label,
    required this.totalCents,
  });

  final DateTime date;
  final String label;

  /// Neto del día: lo que entró menos lo que salió.
  final int totalCents;
}

class MovementRowEntry extends MovementEntry {
  const MovementRowEntry({required this.movement, required this.position});

  final Movement movement;
  final RowPosition position;
}

/// Más reciente primero: por fecha y, dentro del día, por id.
List<Movement> sortMovements(Iterable<Movement> movements) {
  final sorted = movements.toList()
    ..sort((a, b) {
      final byDate = b.date.compareTo(a.date);
      return byDate != 0 ? byDate : b.id.compareTo(a.id);
    });
  return sorted;
}

/// Solo los de un tipo (ingresos o gastos); `null` = todos.
List<Movement> filterByType(List<Movement> movements, MovementType? type) {
  if (type == null) return movements;
  return [
    for (final m in movements)
      if (m.type == type) m,
  ];
}

/// Suma de los importes (en centavos, sin signo) de una lista; sirve para el
/// total de ingresos o de gastos de un filtro.
int sumCents(List<Movement> movements) =>
    movements.fold<int>(0, (sum, m) => sum + m.valueCents);

/// Los que coinciden con [query] en descripción, categoría, medio, contacto o
/// nota (sin tildes ni mayúsculas). Búsqueda vacía = todos.
List<Movement> filterMovements(List<Movement> movements, String query) {
  final search = normalizeSearch(query);
  if (search.isEmpty) return movements;
  return [
    for (final m in movements)
      if ([
        m.description,
        m.category,
        m.method,
        m.contact ?? '',
        m.note ?? '',
      ].any((field) => normalizeSearch(field).contains(search)))
        m,
  ];
}

/// Agrupa por día (ya ordenados) y arma las líneas del historial con el total
/// de cada día, calculado en centavos con las mismas filas que se pintan.
List<MovementEntry> buildDayEntries(
  List<Movement> movements, {
  required DateTime today,
}) {
  final entries = <MovementEntry>[];
  var index = 0;
  while (index < movements.length) {
    final day = dateOnly(movements[index].date);
    var end = index;
    var total = 0;
    while (end < movements.length && dateOnly(movements[end].date) == day) {
      total += movements[end].signedCents;
      end++;
    }
    entries.add(
      DayHeaderEntry(
        date: day,
        label: formatDayHeader(day, today),
        totalCents: total,
      ),
    );
    final count = end - index;
    for (var i = 0; i < count; i++) {
      entries.add(
        MovementRowEntry(
          movement: movements[index + i],
          position: count == 1
              ? RowPosition.only
              : i == 0
              ? RowPosition.first
              : i == count - 1
              ? RowPosition.last
              : RowPosition.middle,
        ),
      );
    }
    index = end;
  }
  return entries;
}
