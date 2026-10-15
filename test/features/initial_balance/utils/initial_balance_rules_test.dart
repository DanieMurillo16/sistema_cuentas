import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_cuentas/features/initial_balance/models/initial_balance_entry.dart';
import 'package:sistema_cuentas/features/initial_balance/utils/initial_balance_rules.dart';

import '../../../helpers/movement_fixtures.dart';

final _methods = [
  buildMethod(id: 2, name: 'Nequi'),
  buildMethod(id: 5, name: 'Bancolombia'),
  buildMethod(id: 7, name: 'Efectivo'),
];

void main() {
  group('constantes y modos', () {
    test('categoría y descripción son «Saldo inicial»', () {
      expect(InitialBalanceRules.categoryName, 'Saldo inicial');
      expect(InitialBalanceRules.description, 'Saldo inicial');
    });

    test('los modos se llaman «Por medio» y «Un valor», en ese orden', () {
      expect(InitialBalanceMode.values, [
        InitialBalanceMode.byMethod,
        InitialBalanceMode.single,
      ]);
      expect(InitialBalanceMode.byMethod.label, 'Por medio');
      expect(InitialBalanceMode.single.label, 'Un valor');
    });
  });

  group('validateOptionalAmount (un campo por medio)', () {
    test('vacío o espacios valen: ese medio no se registra', () {
      for (final value in [null, '', '   ']) {
        expect(InitialBalanceRules.validateOptionalAmount(value), isNull);
      }
    });

    test('cero o sin cifras: pide un valor mayor que cero', () {
      for (final value in ['0', '000', '\$ 0', 'abc', '-']) {
        expect(
          InitialBalanceRules.validateOptionalAmount(value),
          'Escribe un valor mayor que cero.',
          reason: '«$value»',
        );
      }
    });

    test('un valor con puntos de miles vale', () {
      expect(InitialBalanceRules.validateOptionalAmount('1.500.000'), isNull);
      expect(InitialBalanceRules.validateOptionalAmount('1'), isNull);
    });
  });

  group('validateAmount (un solo valor)', () {
    test('vacío, cero o sin cifras: «Escribe el valor.»', () {
      for (final value in [null, '', ' ', '0', 'abc']) {
        expect(
          InitialBalanceRules.validateAmount(value),
          'Escribe el valor.',
          reason: '«$value»',
        );
      }
    });

    test('con un valor mayor que cero vale', () {
      expect(InitialBalanceRules.validateAmount('250.000'), isNull);
    });
  });

  group('validateMethod', () {
    test('sin medio: «Elige el medio de pago.»', () {
      expect(
        InitialBalanceRules.validateMethod(null),
        'Elige el medio de pago.',
      );
    });

    test('con medio vale', () {
      expect(InitialBalanceRules.validateMethod(_methods.first), isNull);
    });
  });

  group('entriesByMethod', () {
    test('solo los medios con valor, en el orden de los medios', () {
      final entries = InitialBalanceRules.entriesByMethod(
        methods: _methods,
        texts: {7: '10.000', 2: '1.500.000', 5: ''},
      );

      expect(
        [for (final e in entries) (e.methodId, e.pesos)],
        [(2, 1500000), (7, 10000)],
      );
    });

    test('ignora ceros, espacios, basura y medios sin campo', () {
      final entries = InitialBalanceRules.entriesByMethod(
        methods: _methods,
        texts: {2: '0', 5: '   ', 99: '5.000'},
      );

      expect(entries, isEmpty);
    });

    test('sin textos, nada', () {
      expect(
        InitialBalanceRules.entriesByMethod(methods: _methods, texts: const {}),
        isEmpty,
      );
    });

    test('sin medios, nada', () {
      expect(
        InitialBalanceRules.entriesByMethod(
          methods: const [],
          texts: {2: '1.000'},
        ),
        isEmpty,
      );
    });

    test('12 dígitos (el máximo del formulario) no se pierden', () {
      final entries = InitialBalanceRules.entriesByMethod(
        methods: _methods,
        texts: {2: '999.999.999.999'},
      );

      expect(entries.single.pesos, 999999999999);
    });
  });

  group('entriesSingle', () {
    test('un valor y un medio: una entrada', () {
      final entries = InitialBalanceRules.entriesSingle(
        text: '2.000.000',
        method: _methods[1],
      );

      expect(entries.single.methodId, 5);
      expect(entries.single.pesos, 2000000);
    });

    test('sin medio, sin valor o con cero: nada', () {
      expect(
        InitialBalanceRules.entriesSingle(text: '5.000', method: null),
        isEmpty,
      );
      expect(
        InitialBalanceRules.entriesSingle(text: '', method: _methods.first),
        isEmpty,
      );
      expect(
        InitialBalanceRules.entriesSingle(text: '0', method: _methods.first),
        isEmpty,
      );
    });
  });

  group('totalPesos', () {
    test('suma las entradas', () {
      expect(
        InitialBalanceRules.totalPesos(const [
          InitialBalanceEntry(methodId: 1, pesos: 1500000),
          InitialBalanceEntry(methodId: 2, pesos: 250000),
        ]),
        1750000,
      );
    });

    test('sin entradas es cero', () {
      expect(InitialBalanceRules.totalPesos(const []), 0);
    });
  });

  group('pesosOf (lo escrito en «Un valor»)', () {
    test('lee los pesos con puntos de miles', () {
      expect(InitialBalanceRules.pesosOf('2.000.000'), 2000000);
      expect(InitialBalanceRules.pesosOf('999.999.999.999'), 999999999999);
    });

    test('vacío, espacios o basura: 0', () {
      for (final value in ['', '   ', 'abc', r'$']) {
        expect(InitialBalanceRules.pesosOf(value), 0, reason: '«$value»');
      }
    });

    test('no exige medio: cuenta aunque falte elegirlo', () {
      expect(InitialBalanceRules.pesosOf('5.000'), 5000);
      expect(
        InitialBalanceRules.entriesSingle(text: '5.000', method: null),
        isEmpty,
        reason: 'registrar sí exige el medio',
      );
    });
  });
}
