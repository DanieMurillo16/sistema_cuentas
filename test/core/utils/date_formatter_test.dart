import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_cuentas/core/utils/currency_formatter.dart';
import 'package:sistema_cuentas/core/utils/date_formatter.dart';

void main() {
  // Martes 13 de octubre de 2026.
  final today = DateTime(2026, 10, 13);

  group('formatDayHeader', () {
    test('hoy y ayer', () {
      expect(formatDayHeader(today, today), 'Hoy');
      expect(formatDayHeader(DateTime(2026, 10, 12), today), 'Ayer');
    });

    test('ignora la hora del día', () {
      expect(
        formatDayHeader(
          DateTime(2026, 10, 13, 23, 59),
          DateTime(2026, 10, 13, 0, 1),
        ),
        'Hoy',
      );
      expect(
        formatDayHeader(
          DateTime(2026, 10, 12, 23, 59),
          DateTime(2026, 10, 13, 0, 1),
        ),
        'Ayer',
      );
    });

    test('antes de ayer: día de la semana, número y mes abreviado', () {
      expect(
        formatDayHeader(DateTime(2026, 10, 11), today),
        'Domingo, 11 Oct.',
      );
      expect(formatDayHeader(DateTime(2026, 10, 1), today), 'Jueves, 1 Oct.');
      expect(
        formatDayHeader(DateTime(2026, 9, 30), today),
        'Miércoles, 30 Sep.',
      );
    });

    test('cambio de año', () {
      expect(
        formatDayHeader(DateTime(2025, 12, 31), DateTime(2026, 1, 1)),
        'Ayer',
      );
      expect(
        formatDayHeader(DateTime(2025, 12, 30), DateTime(2026, 1, 1)),
        'Martes, 30 Dic.',
      );
    });
  });

  group('formatLongDate', () {
    test('martes, 13 de octubre de 2026', () {
      expect(formatLongDate(today), 'martes, 13 de octubre de 2026');
    });

    test('todos los meses y días en español', () {
      expect(
        formatLongDate(DateTime(2026, 1, 1)),
        'jueves, 1 de enero de 2026',
      );
      expect(
        formatLongDate(DateTime(2026, 12, 6)),
        'domingo, 6 de diciembre de 2026',
      );
      expect(
        formatLongDate(DateTime(2024, 2, 29)),
        'jueves, 29 de febrero de 2024',
      );
    });
  });

  group('parseApiDate', () {
    test('AAAA-MM-DD a fecha sin hora', () {
      expect(parseApiDate('2026-10-13'), DateTime(2026, 10, 13));
      expect(parseApiDate('2026-01-05'), DateTime(2026, 1, 5));
    });

    test('tolera una hora después del día', () {
      expect(parseApiDate('2026-10-13 08:30:00'), DateTime(2026, 10, 13));
    });

    test('formatos inválidos lanzan FormatException', () {
      expect(() => parseApiDate('13/10/2026'), throwsFormatException);
      expect(() => parseApiDate(''), throwsFormatException);
      expect(() => parseApiDate('2026-10'), throwsFormatException);
      expect(() => parseApiDate('aaaa-bb-cc'), throwsFormatException);
    });
  });

  group('lastDayOfMonth / apiPeriod / apiDate', () {
    test('último día de cada tipo de mes', () {
      expect(lastDayOfMonth(DateTime(2026, 10)), DateTime(2026, 10, 31));
      expect(lastDayOfMonth(DateTime(2026, 4)), DateTime(2026, 4, 30));
      expect(lastDayOfMonth(DateTime(2026, 2)), DateTime(2026, 2, 28));
      expect(lastDayOfMonth(DateTime(2024, 2)), DateTime(2024, 2, 29));
      expect(lastDayOfMonth(DateTime(2026, 12)), DateTime(2026, 12, 31));
    });

    test('apiPeriod es AAAA-MM con cero a la izquierda', () {
      expect(apiPeriod(DateTime(2026, 3, 15)), '2026-03');
      expect(apiPeriod(DateTime(2026, 12)), '2026-12');
    });

    test('apiDate es AAAA-MM-DD', () {
      expect(apiDate(DateTime(2026, 3, 5)), '2026-03-05');
    });
  });

  group('formatCopSigned', () {
    test('entra con +, sale con -, cero sin signo', () {
      expect(formatCopSigned(400000), '+\$ 400.000');
      expect(formatCopSigned(-75000), '-\$ 75.000');
      expect(formatCopSigned(0), '\$ 0');
    });

    test('importes de 12 dígitos agrupan en miles', () {
      expect(formatCopSigned(999999999999), '+\$ 999.999.999.999');
      expect(formatCopSigned(-999999999999), '-\$ 999.999.999.999');
    });

    test('redondea los centavos a pesos', () {
      expect(formatCopSigned(1250.4), '+\$ 1.250');
    });
  });

  group('formatCentsSigned', () {
    test('desde centavos, con signo', () {
      expect(formatCentsSigned(40000000), '+\$ 400.000');
      expect(formatCentsSigned(-7500000), '-\$ 75.000');
      expect(formatCentsSigned(0), '\$ 0');
    });

    test('sin error de redondeo en importes grandes', () {
      expect(formatCentsSigned(99999999999900), '+\$ 999.999.999.999');
    });
  });

  group('parseApiDateTime', () {
    test(
      'AAAA-MM-DD HH:MM:SS → fecha y hora (la hora de Colombia, tal cual)',
      () {
        expect(
          parseApiDateTime('2026-10-14 15:45:09'),
          DateTime(2026, 10, 14, 15, 45, 9),
        );
      },
    );

    test('también con «T» entre la fecha y la hora', () {
      expect(
        parseApiDateTime('2026-10-14T08:05:00'),
        DateTime(2026, 10, 14, 8, 5),
      );
    });

    test('sin segundos', () {
      expect(
        parseApiDateTime('2026-10-14 08:05'),
        DateTime(2026, 10, 14, 8, 5),
      );
    });

    test('bordes del día: 00:00:00 y 23:59:59', () {
      expect(parseApiDateTime('2026-10-14 00:00:00'), DateTime(2026, 10, 14));
      expect(
        parseApiDateTime('2026-12-31 23:59:59'),
        DateTime(2026, 12, 31, 23, 59, 59),
      );
    });

    test('espacios alrededor se ignoran', () {
      expect(
        parseApiDateTime('  2026-10-14 15:45:09  '),
        DateTime(2026, 10, 14, 15, 45, 9),
      );
    });

    test('null, vacío, solo fecha o basura → null, sin fallar', () {
      for (final raw in [
        null,
        '',
        '   ',
        '2026-10-14',
        'ayer',
        '15:45:09',
        '14/10/2026 15:45',
        'xx-xx-xx yy:yy',
        12345,
        true,
        const <String>[],
      ]) {
        expect(parseApiDateTime(raw), isNull, reason: '«$raw»');
      }
    });
  });

  group('formatClock', () {
    test('tarde: «3:45 p. m.»', () {
      expect(formatClock(DateTime(2026, 10, 14, 15, 45)), '3:45 p. m.');
    });

    test('mañana: «8:05 a. m.» con minutos de dos cifras', () {
      expect(formatClock(DateTime(2026, 10, 14, 8, 5)), '8:05 a. m.');
    });

    test('medianoche: «12:05 a. m.» y 00:00 → «12:00 a. m.»', () {
      expect(formatClock(DateTime(2026, 10, 14, 0, 5)), '12:05 a. m.');
      expect(formatClock(DateTime(2026, 10, 14)), '12:00 a. m.');
    });

    test('mediodía: «12:30 p. m.» y 12:00 → «12:00 p. m.»', () {
      expect(formatClock(DateTime(2026, 10, 14, 12, 30)), '12:30 p. m.');
      expect(formatClock(DateTime(2026, 10, 14, 12)), '12:00 p. m.');
    });

    test('último minuto del día: «11:59 p. m.»', () {
      expect(formatClock(DateTime(2026, 10, 14, 23, 59)), '11:59 p. m.');
    });

    test('las 24 horas, una por una', () {
      const expected = [
        '12:00 a. m.',
        '1:00 a. m.',
        '2:00 a. m.',
        '3:00 a. m.',
        '4:00 a. m.',
        '5:00 a. m.',
        '6:00 a. m.',
        '7:00 a. m.',
        '8:00 a. m.',
        '9:00 a. m.',
        '10:00 a. m.',
        '11:00 a. m.',
        '12:00 p. m.',
        '1:00 p. m.',
        '2:00 p. m.',
        '3:00 p. m.',
        '4:00 p. m.',
        '5:00 p. m.',
        '6:00 p. m.',
        '7:00 p. m.',
        '8:00 p. m.',
        '9:00 p. m.',
        '10:00 p. m.',
        '11:00 p. m.',
      ];
      for (var hour = 0; hour < 24; hour++) {
        expect(formatClock(DateTime(2026, 1, 1, hour)), expected[hour]);
      }
    });

    test('lo que sale de parseApiDateTime se lee bien', () {
      expect(
        formatClock(parseApiDateTime('2026-10-14 15:45:09')!),
        '3:45 p. m.',
      );
    });
  });
}
