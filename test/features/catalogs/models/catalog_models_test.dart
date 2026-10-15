import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_cuentas/core/errors/app_exception.dart';
import 'package:sistema_cuentas/core/models/movement_type.dart';
import 'package:sistema_cuentas/core/network/api_response.dart';
import 'package:sistema_cuentas/features/catalogs/models/category.dart';
import 'package:sistema_cuentas/features/catalogs/models/payment_method.dart';

import '../../../helpers/movement_fixtures.dart';

Matcher get _incompleteData => throwsA(
  isA<UnexpectedException>().having(
    (e) => e.message,
    'message',
    'El servidor devolvió datos incompletos.',
  ),
);

void main() {
  group('Category.fromJson', () {
    test('mapea tipo, nombre, capital y activo', () {
      final c = Category.fromJson(
        categoryJson(id: 9, type: 'INGRESO', name: 'Salario', isCapital: true),
      );
      expect(c.id, 9);
      expect(c.type, MovementType.income);
      expect(c.name, 'Salario');
      expect(c.isCapital, isTrue);
      expect(c.active, isTrue);
    });

    test('activo ausente se considera activo; false lo desactiva', () {
      expect(
        Category.fromJson(categoryJson()..remove('activo')).active,
        isTrue,
      );
      expect(Category.fromJson(categoryJson(active: false)).active, isFalse);
    });

    test('sin nombre o sin id: error propio en español', () {
      expect(
        () =>
            parseApi(() => Category.fromJson(categoryJson()..remove('nombre'))),
        _incompleteData,
      );
      expect(
        () => parseApi(
          () => Category.fromJson(categoryJson()..remove('id_categoria')),
        ),
        throwsA(isA<UnexpectedException>()),
      );
    });
  });

  test(
    'Category: «tipo» ausente o desconocido da error propio, no StateError',
    () {
      // Defecto conocido de lib (MovementType.fromApi lanza StateError).
      for (final json in [
        categoryJson()..remove('tipo'),
        categoryJson(type: 'OTRO'),
      ]) {
        expect(
          () => parseApi(() => Category.fromJson(json)),
          throwsA(isA<UnexpectedException>()),
          reason: 'tipo: ${json['tipo']}',
        );
      }
    },
  );

  group('PaymentMethod.fromJson', () {
    test('mapea id, nombre y activo', () {
      final m = PaymentMethod.fromJson(methodJson(id: 5, name: 'Bancolombia'));
      expect(m.id, 5);
      expect(m.name, 'Bancolombia');
      expect(m.active, isTrue);
    });

    test('sin nombre: error propio en español', () {
      expect(
        () => parseApi(
          () => PaymentMethod.fromJson(methodJson()..remove('nombre')),
        ),
        _incompleteData,
      );
    });
  });
}
