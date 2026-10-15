import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_cuentas/core/models/movement_type.dart';
import 'package:sistema_cuentas/features/movements/models/movement_draft.dart';
import 'package:sistema_cuentas/features/movements/utils/movement_form_rules.dart';

import '../../../helpers/movement_fixtures.dart';

void main() {
  final today = DateTime(2026, 10, 13);

  group('validateAmount', () {
    test('vacío, nulo, cero o solo símbolos piden el valor', () {
      for (final bad in [null, '', '   ', '0', '000', r'$', 'abc']) {
        expect(
          MovementFormRules.validateAmount(bad),
          'Escribe el valor.',
          reason: 'entrada: "$bad"',
        );
      }
    });

    test('con puntos de miles o sin ellos es válido', () {
      expect(MovementFormRules.validateAmount('1'), isNull);
      expect(MovementFormRules.validateAmount('55.000'), isNull);
      expect(MovementFormRules.validateAmount('999.999.999.999'), isNull);
    });
  });

  group('validateDate', () {
    test('sin fecha pide elegirla', () {
      expect(
        MovementFormRules.validateDate(null, today: today),
        'Elige la fecha.',
      );
    });

    test('hoy y el pasado son válidos (aunque tenga hora)', () {
      expect(MovementFormRules.validateDate(today, today: today), isNull);
      expect(
        MovementFormRules.validateDate(
          DateTime(2026, 10, 13, 23, 59),
          today: today,
        ),
        isNull,
      );
      expect(
        MovementFormRules.validateDate(DateTime(2020, 1, 1), today: today),
        isNull,
      );
    });

    test('mañana en adelante no es válido', () {
      expect(
        MovementFormRules.validateDate(DateTime(2026, 10, 14), today: today),
        'La fecha no puede ser futura.',
      );
    });
  });

  test('categoría y medio obligatorios', () {
    expect(MovementFormRules.validateCategory(null), 'Elige la categoría.');
    expect(MovementFormRules.validateCategory(buildCategory()), isNull);
    expect(
      MovementFormRules.validatePaymentMethod(null),
      'Elige el medio de pago.',
    );
    expect(MovementFormRules.validatePaymentMethod(buildMethod()), isNull);
  });

  group('buildDraft', () {
    MovementDraft draft({
      String amount = '55.000',
      String description = 'Mercado',
      String note = '',
      MovementType type = MovementType.expense,
    }) => MovementFormRules.buildDraft(
      type: type,
      amountText: amount,
      date: DateTime(2026, 10, 13, 15, 30),
      description: description,
      category: buildCategory(id: 3, name: 'Alimentación'),
      method: buildMethod(id: 5, name: 'Bancolombia'),
      note: note,
    );

    test('arma el borrador con ids, pesos enteros y fecha sin hora', () {
      final d = draft();
      expect(d.type, MovementType.expense);
      expect(d.amountPesos, 55000);
      expect(d.date, DateTime(2026, 10, 13));
      expect(d.description, 'Mercado');
      expect(d.categoryId, 3);
      expect(d.methodId, 5);
      expect(d.note, isNull);
    });

    test('descripción vacía o en blanco = nombre de la categoría', () {
      expect(draft(description: '').description, 'Alimentación');
      expect(draft(description: '   ').description, 'Alimentación');
    });

    test('descripción y nota se recortan', () {
      final d = draft(description: '  Mercado  ', note: '  para la semana ');
      expect(d.description, 'Mercado');
      expect(d.note, 'para la semana');
    });

    test('nota vacía o en blanco = null (no se envía)', () {
      expect(draft(note: '').note, isNull);
      expect(draft(note: '   ').note, isNull);
      expect(draft(note: '').toJson().containsKey('nota'), isFalse);
    });

    test('el monto se envía como texto de pesos completos', () {
      expect(draft(amount: '1.250.000').toJson()['valor'], '1250000');
      expect(draft(amount: '999.999.999.999').amountPesos, 999999999999);
    });

    test('ingreso conserva su tipo', () {
      expect(draft(type: MovementType.income).toJson()['tipo'], 'INGRESO');
    });
  });

  group('rango de fechas del calendario', () {
    test('desde el año 2000 hasta hoy (sin hora)', () {
      expect(MovementFormRules.firstDate, DateTime(2000));
      expect(
        MovementFormRules.lastDate(DateTime(2026, 10, 13, 18, 45)),
        DateTime(2026, 10, 13),
      );
    });

    test('el tope del calendario coincide con lo que valida validateDate', () {
      final last = MovementFormRules.lastDate(today);
      expect(MovementFormRules.validateDate(last, today: today), isNull);
      expect(
        MovementFormRules.validateDate(
          last.add(const Duration(days: 1)),
          today: today,
        ),
        isNotNull,
      );
    });
  });

  test('el campo de monto admite 10 dígitos (13 caracteres con puntos)', () {
    expect(MovementFormRules.maxAmountDigits, 10);
    expect(MovementFormRules.maxAmountChars, 13);
    // 9.999.999.999 mide exactamente 13 caracteres.
    expect('9.999.999.999'.length, MovementFormRules.maxAmountChars);
  });
}
