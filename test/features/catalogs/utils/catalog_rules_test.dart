import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_cuentas/core/models/movement_type.dart';
import 'package:sistema_cuentas/features/catalogs/utils/catalog_rules.dart';

void main() {
  group('nombres', () {
    final validators = <String, String? Function(String?)>{
      'categoría': CatalogRules.validateCategoryName,
      'medio de pago': CatalogRules.validateMethodName,
      'contacto': CatalogRules.validateContactName,
    };

    for (final entry in validators.entries) {
      test('${entry.key}: vacío, nulo o solo espacios piden el nombre', () {
        for (final value in [null, '', '   ', 'a', ' a ']) {
          expect(
            entry.value(value),
            startsWith('Escribe el nombre'),
            reason: '"$value"',
          );
        }
      });

      test('${entry.key}: dos letras ya es válido (se recorta antes)', () {
        expect(entry.value('Ab'), isNull);
        expect(entry.value('  Ab  '), isNull);
      });
    }

    test('el mensaje dice de qué es el nombre', () {
      expect(
        CatalogRules.validateCategoryName(''),
        'Escribe el nombre de la categoría (mínimo 2 letras).',
      );
      expect(
        CatalogRules.validateMethodName(''),
        'Escribe el nombre del medio de pago (mínimo 2 letras).',
      );
      expect(
        CatalogRules.validateContactName(''),
        'Escribe el nombre del contacto (mínimo 2 letras).',
      );
    });

    test('el máximo de cada uno es inclusivo', () {
      expect(
        CatalogRules.validateCategoryName('a' * CatalogRules.categoryNameMax),
        isNull,
      );
      expect(
        CatalogRules.validateCategoryName(
          'a' * (CatalogRules.categoryNameMax + 1),
        ),
        'Máximo ${CatalogRules.categoryNameMax} caracteres.',
      );
      expect(
        CatalogRules.validateMethodName('a' * CatalogRules.methodNameMax),
        isNull,
      );
      expect(
        CatalogRules.validateMethodName('a' * (CatalogRules.methodNameMax + 1)),
        'Máximo ${CatalogRules.methodNameMax} caracteres.',
      );
      expect(
        CatalogRules.validateContactName('a' * CatalogRules.contactNameMax),
        isNull,
      );
      expect(
        CatalogRules.validateContactName(
          'a' * (CatalogRules.contactNameMax + 1),
        ),
        'Máximo ${CatalogRules.contactNameMax} caracteres.',
      );
    });

    test('los espacios de los bordes no cuentan para el máximo', () {
      expect(
        CatalogRules.validateMethodName(
          ' ${'a' * CatalogRules.methodNameMax} ',
        ),
        isNull,
      );
    });
  });

  group('validatePhone (opcional)', () {
    test('vacío o nulo es válido', () {
      expect(CatalogRules.validatePhone(null), isNull);
      expect(CatalogRules.validatePhone(''), isNull);
      expect(CatalogRules.validatePhone('    '), isNull);
    });

    test('acepta dígitos, espacios, + ( ) y -', () {
      for (final phone in [
        '3001234567',
        '+57 300 123 4567',
        '(601) 234-5678',
      ]) {
        expect(CatalogRules.validatePhone(phone), isNull, reason: phone);
      }
    });

    test('rechaza letras y símbolos', () {
      for (final phone in [
        'abc12345',
        '300-123-45x',
        '300.123.4567',
        '300#12',
      ]) {
        expect(
          CatalogRules.validatePhone(phone),
          'Solo números, espacios, + ( ) y -.',
          reason: phone,
        );
      }
    });

    test('bordes de largo: 5 y 20 sí; 4 y 21 no', () {
      expect(CatalogRules.validatePhone('1' * CatalogRules.phoneMin), isNull);
      expect(CatalogRules.validatePhone('1' * CatalogRules.phoneMax), isNull);
      expect(
        CatalogRules.validatePhone('1' * (CatalogRules.phoneMin - 1)),
        'Entre 5 y 20 caracteres.',
      );
      expect(
        CatalogRules.validatePhone('1' * (CatalogRules.phoneMax + 1)),
        'Entre 5 y 20 caracteres.',
      );
    });
  });

  group('borradores', () {
    test('categoryDraft recorta el nombre y conserva el resto', () {
      final draft = CatalogRules.categoryDraft(
        type: MovementType.income,
        name: '  Salario  ',
        isCapital: true,
        active: true,
      );
      expect(draft.id, isNull);
      expect(draft.name, 'Salario');
      expect(draft.type, MovementType.income);
      expect(draft.isCapital, isTrue);
      expect(draft.active, isTrue);
    });

    test('categoryDraft al editar lleva el id', () {
      final draft = CatalogRules.categoryDraft(
        id: 9,
        type: MovementType.expense,
        name: 'x',
        isCapital: false,
        active: false,
      );
      expect(draft.id, 9);
      expect(draft.active, isFalse);
    });

    test('methodDraft recorta el nombre', () {
      final draft = CatalogRules.methodDraft(
        id: 2,
        name: ' Nequi ',
        active: false,
      );
      expect(draft.id, 2);
      expect(draft.name, 'Nequi');
      expect(draft.active, isFalse);
    });

    test('contactDraft: teléfono y nota vacíos o de espacios son null', () {
      final draft = CatalogRules.contactDraft(
        name: ' Oscar ',
        phone: '   ',
        note: '',
        active: true,
      );
      expect(draft.name, 'Oscar');
      expect(draft.phone, isNull);
      expect(draft.note, isNull);
    });

    test('contactDraft recorta teléfono y nota cuando hay algo', () {
      final draft = CatalogRules.contactDraft(
        id: 4,
        name: 'Oscar',
        phone: ' 3001234567 ',
        note: '  paga el 7  ',
        active: false,
      );
      expect(draft.id, 4);
      expect(draft.phone, '3001234567');
      expect(draft.note, 'paga el 7');
      expect(draft.active, isFalse);
    });
  });
}
