import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_cuentas/core/models/movement_type.dart';

void main() {
  group('routeName', () {
    test('ingreso es «income» y gasto es «expense»', () {
      expect(MovementType.income.routeName, 'income');
      expect(MovementType.expense.routeName, 'expense');
    });

    test('es distinto del valor de la API', () {
      for (final type in MovementType.values) {
        expect(type.routeName, isNot(type.apiValue));
      }
    });
  });

  group('tryFromRoute', () {
    test('reconoce los dos nombres de ruta', () {
      expect(MovementType.tryFromRoute('income'), MovementType.income);
      expect(MovementType.tryFromRoute('expense'), MovementType.expense);
    });

    test('es el inverso de routeName para todos los tipos', () {
      for (final type in MovementType.values) {
        expect(MovementType.tryFromRoute(type.routeName), type);
      }
    });

    test('null, vacío o desconocido dan null (no lanzan)', () {
      expect(MovementType.tryFromRoute(null), isNull);
      expect(MovementType.tryFromRoute(''), isNull);
      expect(MovementType.tryFromRoute('otra'), isNull);
    });

    test('distingue mayúsculas y no acepta el valor de la API', () {
      expect(MovementType.tryFromRoute('INCOME'), isNull);
      expect(MovementType.tryFromRoute('Income'), isNull);
      expect(MovementType.tryFromRoute('INGRESO'), isNull);
      expect(MovementType.tryFromRoute('GASTO'), isNull);
    });

    test('no recorta espacios', () {
      expect(MovementType.tryFromRoute(' income'), isNull);
    });
  });

  group('fromApi', () {
    test('lee INGRESO y GASTO', () {
      expect(MovementType.fromApi('INGRESO'), MovementType.income);
      expect(MovementType.fromApi('GASTO'), MovementType.expense);
    });

    test('un valor desconocido lanza FormatException', () {
      expect(() => MovementType.fromApi('X'), throwsFormatException);
      expect(() => MovementType.fromApi(null), throwsFormatException);
    });
  });
}
