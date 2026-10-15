import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_cuentas/core/utils/json_helpers.dart';

void main() {
  group('moneyToCents', () {
    test('casos normales: el dinero llega como texto con dos decimales', () {
      expect(moneyToCents('0.00'), 0);
      expect(moneyToCents('12500.00'), 1250000);
      expect(moneyToCents('180000.00'), 18000000);
      expect(moneyToCents('0.05'), 5);
      expect(moneyToCents('999999999999.00'), 99999999999900);
    });

    test('un solo decimal se completa: "1.5" son 150 centavos', () {
      expect(moneyToCents('1.5'), 150);
      expect(moneyToCents('0.5'), 50);
    });

    test('sin decimales y con espacios alrededor', () {
      expect(moneyToCents('12500'), 1250000);
      expect(moneyToCents('  12.30 '), 1230);
    });

    test('también acepta un número ya decodificado (int) o decimal', () {
      expect(moneyToCents(12500), 1250000);
      expect(moneyToCents(12.5), 1250);
    });

    test('negativos conservan el signo en los centavos', () {
      expect(moneyToCents('-3.10'), -310);
      expect(moneyToCents('-0.01'), -1);
      expect(moneyToCents('-0.00'), 0);
    });

    test('inválidos lanzan FormatException', () {
      for (final bad in [
        '',
        '   ',
        'abc',
        '1,5',
        '1.234',
        '.5',
        '5.',
        '--3',
        '+5',
        '1e3',
        '12 500',
        null,
      ]) {
        expect(
          () => moneyToCents(bad),
          throwsFormatException,
          reason: 'entrada: "$bad"',
        );
      }
    });

    test('sumar centavos no acumula error de punto flotante', () {
      // Con double, 0.1 + 0.2 != 0.3 y mil veces 0.10 no da 100.
      expect(0.1 + 0.2 == 0.3, isFalse);
      expect(moneyToCents('0.10') + moneyToCents('0.20'), moneyToCents('0.30'));

      var cents = 0;
      for (var i = 0; i < 1000; i++) {
        cents += moneyToCents('0.10');
      }
      expect(cents, 10000);

      var pesos = 0.0;
      for (var i = 0; i < 1000; i++) {
        pesos += 0.1;
      }
      expect(pesos == 100, isFalse, reason: 'el double sí se desvía');
    });
  });

  test('centsToPesos convierte para mostrar', () {
    expect(centsToPesos(1250000), 12500);
    expect(centsToPesos(-310), -3.1);
    expect(centsToPesos(0), 0);
  });

  group('asInt', () {
    test('número o texto', () {
      expect(asInt(7), 7);
      expect(asInt('7'), 7);
      expect(asInt(7.0), 7);
    });

    test('texto que no es número lanza FormatException', () {
      expect(() => asInt('x'), throwsFormatException);
    });
  });

  group('asOptionalText', () {
    test('vacío, espacios o ausente es null', () {
      expect(asOptionalText(null), isNull);
      expect(asOptionalText(''), isNull);
      expect(asOptionalText('   '), isNull);
    });

    test('recorta el texto', () {
      expect(asOptionalText('  hola '), 'hola');
    });
  });
}
