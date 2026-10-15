import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_cuentas/core/models/movement_type.dart';
import 'package:sistema_cuentas/features/movements/models/movements_filter.dart';

MovementsFilter _filter({
  MovementType type = MovementType.income,
  int? categoryId,
  int? methodId,
  String query = '',
}) => MovementsFilter(
  type: type,
  range: DateTimeRange(start: DateTime(2026, 10), end: DateTime(2026, 10, 31)),
  categoryId: categoryId,
  methodId: methodId,
  query: query,
);

void main() {
  group('forMonth', () {
    test('va del primer al último día del mes', () {
      final filter = MovementsFilter.forMonth(
        MovementType.expense,
        DateTime(2026, 10),
      );
      expect(filter.range.start, DateTime(2026, 10, 1));
      expect(filter.range.end, DateTime(2026, 10, 31));
      expect(filter.type, MovementType.expense);
    });

    test('ignora el día del mes que reciba', () {
      final filter = MovementsFilter.forMonth(
        MovementType.income,
        DateTime(2026, 6, 17, 13, 45),
      );
      expect(filter.range.start, DateTime(2026, 6, 1));
      expect(filter.range.end, DateTime(2026, 6, 30));
    });

    test('febrero de un año bisiesto termina el 29 y uno común el 28', () {
      expect(
        MovementsFilter.forMonth(
          MovementType.income,
          DateTime(2028, 2),
        ).range.end,
        DateTime(2028, 2, 29),
      );
      expect(
        MovementsFilter.forMonth(
          MovementType.income,
          DateTime(2027, 2),
        ).range.end,
        DateTime(2027, 2, 28),
      );
    });

    test('diciembre cierra el año el 31', () {
      final filter = MovementsFilter.forMonth(
        MovementType.income,
        DateTime(2026, 12),
      );
      expect(filter.range.end, DateTime(2026, 12, 31));
    });

    test('empieza sin categoría, sin medio y sin texto', () {
      final filter = MovementsFilter.forMonth(
        MovementType.income,
        DateTime(2026, 10),
      );
      expect(filter.categoryId, isNull);
      expect(filter.methodId, isNull);
      expect(filter.query, '');
      expect(filter.hasExtras, isFalse);
    });
  });

  group('copyWith', () {
    test('sin argumentos conserva todo', () {
      final base = _filter(categoryId: 3, methodId: 2, query: 'taxi');
      final copy = base.copyWith();
      expect(copy.range, base.range);
      expect(copy.type, base.type);
      expect(copy.categoryId, 3);
      expect(copy.methodId, 2);
      expect(copy.query, 'taxi');
    });

    test('cambia solo lo indicado y nunca el tipo', () {
      final base = _filter(categoryId: 3);
      final range = DateTimeRange(
        start: DateTime(2026, 9),
        end: DateTime(2026, 9, 30),
      );
      final copy = base.copyWith(range: range, query: 'x');
      expect(copy.range, range);
      expect(copy.query, 'x');
      expect(copy.categoryId, 3);
      expect(copy.type, MovementType.income);
    });

    test('categoryId y methodId nuevos reemplazan a los anteriores', () {
      final copy = _filter(
        categoryId: 3,
        methodId: 2,
      ).copyWith(categoryId: 4, methodId: 5);
      expect(copy.categoryId, 4);
      expect(copy.methodId, 5);
    });

    test('clearCategory quita la categoría y deja el medio', () {
      final copy = _filter(
        categoryId: 3,
        methodId: 2,
      ).copyWith(clearCategory: true);
      expect(copy.categoryId, isNull);
      expect(copy.methodId, 2);
    });

    test('clearMethod quita el medio y deja la categoría', () {
      final copy = _filter(
        categoryId: 3,
        methodId: 2,
      ).copyWith(clearMethod: true);
      expect(copy.methodId, isNull);
      expect(copy.categoryId, 3);
    });

    test('clearCategory gana sobre un categoryId enviado a la vez', () {
      final copy = _filter(categoryId: 3)
          .copyWith(categoryId: 9, clearCategory: true);
      expect(copy.categoryId, isNull);
    });

    test('es inmutable: el original no cambia', () {
      final base = _filter(categoryId: 3);
      base.copyWith(clearCategory: true, query: 'z');
      expect(base.categoryId, 3);
      expect(base.query, '');
    });
  });

  group('serverQuery', () {
    test('lleva rango, tipo, categoría y medio, pero no el texto', () {
      final query = _filter(
        type: MovementType.expense,
        categoryId: 3,
        methodId: 2,
        query: 'taxi',
      ).serverQuery;
      expect(query.from, DateTime(2026, 10, 1));
      expect(query.to, DateTime(2026, 10, 31));
      expect(query.type, MovementType.expense);
      expect(query.categoryId, 3);
      expect(query.methodId, 2);
    });

    test(
      'cambiar solo el texto NO cambia la consulta (llave del provider)',
      () {
        final a = _filter(query: 'a').serverQuery;
        final b = _filter(query: 'otra cosa').serverQuery;
        expect(a, b);
        expect(a.hashCode, b.hashCode);
      },
    );

    test('cambiar categoría, medio, tipo o fechas SÍ cambia la consulta', () {
      final base = _filter().serverQuery;
      expect(_filter(categoryId: 1).serverQuery, isNot(base));
      expect(_filter(methodId: 1).serverQuery, isNot(base));
      expect(_filter(type: MovementType.expense).serverQuery, isNot(base));
      expect(
        _filter()
            .copyWith(
              range: DateTimeRange(
                start: DateTime(2026, 10),
                end: DateTime(2026, 10, 30),
              ),
            )
            .serverQuery,
        isNot(base),
      );
    });
  });

  group('hasExtras', () {
    test('sin nada extra es falso', () {
      expect(_filter().hasExtras, isFalse);
    });

    test('con categoría, con medio o con texto es verdadero', () {
      expect(_filter(categoryId: 1).hasExtras, isTrue);
      expect(_filter(methodId: 1).hasExtras, isTrue);
      expect(_filter(query: 'taxi').hasExtras, isTrue);
    });

    test('un texto de solo espacios no cuenta', () {
      expect(_filter(query: '   ').hasExtras, isFalse);
    });

    test('cambiar el rango de fechas por sí solo no es un extra', () {
      final copy = _filter().copyWith(
        range: DateTimeRange(
          start: DateTime(2026, 9),
          end: DateTime(2026, 9, 30),
        ),
      );
      expect(copy.hasExtras, isFalse);
    });
  });

  group('isModifiedFrom', () {
    final october = DateTime(2026, 10);

    test('el mes completo sin extras no está modificado', () {
      final filter = MovementsFilter.forMonth(MovementType.income, october);
      expect(filter.isModifiedFrom(october), isFalse);
    });

    test('con categoría, medio o texto sí', () {
      final base = MovementsFilter.forMonth(MovementType.income, october);
      expect(base.copyWith(categoryId: 1).isModifiedFrom(october), isTrue);
      expect(base.copyWith(methodId: 1).isModifiedFrom(october), isTrue);
      expect(base.copyWith(query: 'a').isModifiedFrom(october), isTrue);
    });

    test('un rango distinto del mes elegido sí', () {
      final base = MovementsFilter.forMonth(MovementType.income, october);
      final changed = base.copyWith(
        range: DateTimeRange(
          start: DateTime(2026, 10, 5),
          end: DateTime(2026, 10, 31),
        ),
      );
      expect(changed.isModifiedFrom(october), isTrue);
    });

    test('el mes completo de OTRO mes cuenta como modificado', () {
      final september = MovementsFilter.forMonth(
        MovementType.income,
        DateTime(2026, 9),
      );
      expect(september.isModifiedFrom(october), isTrue);
    });

    test('volver al rango original lo deja sin modificar', () {
      final base = MovementsFilter.forMonth(MovementType.income, october);
      final back = base
          .copyWith(
            range: DateTimeRange(
              start: DateTime(2026, 9),
              end: DateTime(2026, 9, 30),
            ),
          )
          .copyWith(range: base.range);
      expect(back.isModifiedFrom(october), isFalse);
    });
  });

  group('límites de fechas', () {
    test('firstDate es el 1 de enero de 2000', () {
      expect(MovementsFilter.firstDate, DateTime(2000));
    });

    test('lastDate es el 31 de diciembre del año que viene', () {
      expect(
        MovementsFilter.lastDate(DateTime(2026, 10, 14)),
        DateTime(2027, 12, 31),
      );
      expect(
        MovementsFilter.lastDate(DateTime(2026, 12, 31)),
        DateTime(2027, 12, 31),
      );
    });
  });
}
