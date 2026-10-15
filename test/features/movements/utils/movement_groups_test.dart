import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_cuentas/core/models/movement_type.dart';
import 'package:sistema_cuentas/features/movements/utils/movement_groups.dart';

import '../../../helpers/movement_fixtures.dart';

void main() {
  // Martes 13 de octubre de 2026.
  final today = DateTime(2026, 10, 13);

  group('sortMovements', () {
    test('más reciente primero y, en el mismo día, el id mayor primero', () {
      final sorted = sortMovements([
        buildMovement(id: 1, date: DateTime(2026, 10, 10)),
        buildMovement(id: 5, date: DateTime(2026, 10, 12)),
        buildMovement(id: 3, date: DateTime(2026, 10, 12)),
        buildMovement(id: 9, date: DateTime(2026, 10, 13)),
      ]);
      expect(sorted.map((m) => m.id), [9, 5, 3, 1]);
    });

    test('no modifica la lista original', () {
      final original = [
        buildMovement(id: 1, date: DateTime(2026, 10, 1)),
        buildMovement(id: 2, date: DateTime(2026, 10, 2)),
      ];
      sortMovements(original);
      expect(original.map((m) => m.id), [1, 2]);
    });

    test('lista vacía', () {
      expect(sortMovements(const []), isEmpty);
    });
  });

  group('filterByType', () {
    final items = [
      buildMovement(id: 1, type: MovementType.expense),
      buildMovement(id: 2, type: MovementType.income),
      buildMovement(id: 3, type: MovementType.expense),
    ];

    test('null devuelve la misma lista (todos)', () {
      expect(filterByType(items, null), same(items));
    });

    test('ingresos deja solo los ingresos, en su orden', () {
      expect(filterByType(items, MovementType.income).map((m) => m.id), [2]);
    });

    test('gastos deja solo los gastos, en su orden', () {
      expect(filterByType(items, MovementType.expense).map((m) => m.id), [
        1,
        3,
      ]);
    });

    test('un tipo que no hay da lista vacía', () {
      final onlyExpenses = [buildMovement(id: 1)];
      expect(filterByType(onlyExpenses, MovementType.income), isEmpty);
    });

    test('lista vacía', () {
      expect(filterByType(const [], MovementType.income), isEmpty);
      expect(filterByType(const [], null), isEmpty);
    });

    test('no modifica la lista original', () {
      filterByType(items, MovementType.income);
      expect(items, hasLength(3));
    });
  });

  group('sumCents', () {
    test('lista vacía suma 0', () {
      expect(sumCents(const []), 0);
    });

    test('suma los importes sin signo, sea ingreso o gasto', () {
      final items = [
        buildMovement(id: 1, valueCents: 1000),
        buildMovement(id: 2, type: MovementType.income, valueCents: 2550),
        buildMovement(id: 3, valueCents: 5),
      ];
      expect(sumCents(items), 3555);
    });

    test('importes de 12 dígitos no se desbordan (enteros de 64 bits)', () {
      final items = [
        buildMovement(id: 1, valueCents: 99999999999900),
        buildMovement(id: 2, valueCents: 99999999999900),
      ];
      expect(sumCents(items), 199999999999800);
    });

    test('combinado con filterByType da el total de un tipo', () {
      final items = [
        buildMovement(id: 1, valueCents: 1000),
        buildMovement(id: 2, type: MovementType.income, valueCents: 7000),
        buildMovement(id: 3, valueCents: 500),
      ];
      expect(sumCents(filterByType(items, MovementType.expense)), 1500);
      expect(sumCents(filterByType(items, MovementType.income)), 7000);
    });
  });

  group('filterMovements', () {
    final items = [
      buildMovement(
        id: 1,
        description: 'Mercado del mes',
        category: 'Alimentación',
        method: 'Nequi',
      ),
      buildMovement(
        id: 2,
        type: MovementType.income,
        description: 'Salario',
        category: 'Nómina',
        method: 'Bancolombia',
        contact: 'Empresa Ñandú',
        note: 'Quincena adelantada',
      ),
    ];

    test('búsqueda vacía o solo espacios devuelve todos', () {
      expect(filterMovements(items, ''), items);
      expect(filterMovements(items, '   '), items);
    });

    test('sin tildes ni mayúsculas', () {
      expect(filterMovements(items, 'alimentacion').map((m) => m.id), [1]);
      expect(filterMovements(items, 'ALIMENTACIÓN').map((m) => m.id), [1]);
      expect(filterMovements(items, 'nomina').map((m) => m.id), [2]);
    });

    test('busca en descripción, categoría, medio, contacto y nota', () {
      expect(filterMovements(items, 'mercado').map((m) => m.id), [1]);
      expect(filterMovements(items, 'nequi').map((m) => m.id), [1]);
      expect(filterMovements(items, 'bancolombia').map((m) => m.id), [2]);
      expect(filterMovements(items, 'empresa').map((m) => m.id), [2]);
      expect(filterMovements(items, 'quincena').map((m) => m.id), [2]);
    });

    test('texto parcial y con espacios alrededor', () {
      expect(filterMovements(items, '  sal ').map((m) => m.id), [2]);
    });

    test('sin coincidencias devuelve vacío', () {
      expect(filterMovements(items, 'zzz'), isEmpty);
    });

    test('contacto y nota nulos no rompen la búsqueda', () {
      expect(filterMovements([items.first], 'nada'), isEmpty);
    });
  });

  group('buildDayEntries', () {
    test('lista vacía no genera líneas', () {
      expect(buildDayEntries(const [], today: today), isEmpty);
    });

    test('un movimiento: encabezado + fila con posición only', () {
      final entries = buildDayEntries([
        buildMovement(id: 1, date: today, valueCents: 1000000),
      ], today: today);

      expect(entries, hasLength(2));
      final header = entries[0] as DayHeaderEntry;
      expect(header.label, 'Hoy');
      expect(header.totalCents, -1000000);
      expect((entries[1] as MovementRowEntry).position, RowPosition.only);
    });

    test('agrupa por día y calcula el total neto (ingresos − gastos)', () {
      final entries = buildDayEntries([
        buildMovement(
          id: 4,
          type: MovementType.income,
          valueCents: 50000000,
          date: today,
        ),
        buildMovement(id: 3, valueCents: 7500000, date: today),
        buildMovement(id: 2, valueCents: 1250000, date: DateTime(2026, 10, 12)),
        buildMovement(id: 1, valueCents: 100, date: DateTime(2026, 10, 11)),
      ], today: today);

      final headers = entries.whereType<DayHeaderEntry>().toList();
      expect(headers.map((h) => h.label), ['Hoy', 'Ayer', 'Domingo, 11 Oct.']);
      expect(headers.map((h) => h.totalCents), [42500000, -1250000, -100]);
      expect(entries.whereType<MovementRowEntry>(), hasLength(4));
    });

    test('un día cuyo neto da cero queda en cero', () {
      final entries = buildDayEntries([
        buildMovement(id: 2, type: MovementType.income, date: today),
        buildMovement(id: 1, date: today),
      ], today: today);
      expect((entries.first as DayHeaderEntry).totalCents, 0);
    });

    test('posiciones: only / first / middle / last', () {
      final entries = buildDayEntries([
        buildMovement(id: 6, date: today),
        buildMovement(id: 5, date: today),
        buildMovement(id: 4, date: today),
        buildMovement(id: 3, date: today),
        buildMovement(id: 2, date: DateTime(2026, 10, 12)),
        buildMovement(id: 1, date: DateTime(2026, 10, 11)),
      ], today: today);

      final positions = entries
          .whereType<MovementRowEntry>()
          .map((e) => e.position)
          .toList();
      expect(positions, [
        RowPosition.first,
        RowPosition.middle,
        RowPosition.middle,
        RowPosition.last,
        RowPosition.only,
        RowPosition.only,
      ]);
    });

    test('dos movimientos en un día: first y last, sin middle', () {
      final entries = buildDayEntries([
        buildMovement(id: 2, date: today),
        buildMovement(id: 1, date: today),
      ], today: today);
      expect(entries.whereType<MovementRowEntry>().map((e) => e.position), [
        RowPosition.first,
        RowPosition.last,
      ]);
    });

    test('el orden es encabezado y luego sus filas', () {
      final entries = buildDayEntries([
        buildMovement(id: 2, date: today),
        buildMovement(id: 1, date: DateTime(2026, 10, 12)),
      ], today: today);
      expect(entries.map((e) => e.runtimeType), [
        DayHeaderEntry,
        MovementRowEntry,
        DayHeaderEntry,
        MovementRowEntry,
      ]);
    });

    test('la hora de la fecha no parte un día en dos', () {
      final entries = buildDayEntries([
        buildMovement(id: 2, date: DateTime(2026, 10, 13, 22)),
        buildMovement(id: 1, date: DateTime(2026, 10, 13, 6)),
      ], today: today);
      expect(entries.whereType<DayHeaderEntry>(), hasLength(1));
    });

    test('suma en centavos sin error de punto flotante', () {
      final entries = buildDayEntries([
        for (var i = 0; i < 1000; i++)
          buildMovement(
            id: i,
            type: MovementType.income,
            valueCents: 10,
            date: today,
          ),
      ], today: today);
      expect((entries.first as DayHeaderEntry).totalCents, 10000);
    });
  });
}
