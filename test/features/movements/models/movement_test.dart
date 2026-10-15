import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_cuentas/core/errors/app_exception.dart';
import 'package:sistema_cuentas/core/models/movement_type.dart';
import 'package:sistema_cuentas/core/network/api_response.dart';
import 'package:sistema_cuentas/features/movements/models/movement.dart';
import 'package:sistema_cuentas/features/movements/models/movement_draft.dart';

import '../../../helpers/movement_fixtures.dart';

void main() {
  group('Movement.fromJson', () {
    test('mapea un gasto completo: dinero en centavos, fecha y textos', () {
      final m = Movement.fromJson(
        movementJson(
          id: 41,
          value: '180000.00',
          date: '2026-10-11',
          description: 'Arriendo',
          contact: 'Doña Marta',
          note: 'Octubre',
        ),
      );
      expect(m.id, 41);
      expect(m.type, MovementType.expense);
      expect(m.valueCents, 18000000);
      expect(m.date, DateTime(2026, 10, 11));
      expect(m.description, 'Arriendo');
      expect(m.categoryId, 3);
      expect(m.category, 'Alimentación');
      expect(m.methodId, 2);
      expect(m.method, 'Nequi');
      expect(m.contact, 'Doña Marta');
      expect(m.note, 'Octubre');
      expect(m.cancelled, isFalse);
      expect(m.fromRecurring, isFalse);
    });

    test('signedCents: ingreso suma, gasto resta', () {
      final income = Movement.fromJson(
        movementJson(type: 'INGRESO', value: '100.50'),
      );
      final expense = Movement.fromJson(
        movementJson(type: 'GASTO', value: '100.50'),
      );
      expect(income.isIncome, isTrue);
      expect(income.signedCents, 10050);
      expect(expense.signedCents, -10050);
    });

    test('ids como texto y origen RECURRENTE', () {
      final json = movementJson(origin: 'RECURRENTE')..['id_movimiento'] = '8';
      final m = Movement.fromJson(json);
      expect(m.id, 8);
      expect(m.fromRecurring, isTrue);
    });

    test('contacto, nota y motivo vacíos quedan en null', () {
      final json = movementJson(contact: '  ', note: '')
        ..['motivo_anulacion'] = '';
      final m = Movement.fromJson(json);
      expect(m.contact, isNull);
      expect(m.note, isNull);
      expect(m.cancelReason, isNull);
    });

    test('descripción nula se vuelve texto vacío', () {
      final json = movementJson()..['descripcion'] = null;
      expect(Movement.fromJson(json).description, '');
    });

    test('campos faltantes: parseApi da un error propio en español', () {
      for (final key in ['id_movimiento', 'valor', 'fecha']) {
        final json = movementJson()..remove(key);
        expect(
          () => parseApi(() => Movement.fromJson(json)),
          throwsA(
            isA<UnexpectedException>().having(
              (e) => e.message,
              'message',
              startsWith('El servidor devolvió datos'),
            ),
          ),
          reason: 'falta $key',
        );
      }
    });

    test('«tipo» ausente o desconocido: error propio, no StateError', () {
      // Defecto conocido de lib: MovementType.fromApi lanza StateError y
      // parseApi solo atrapa TypeError/FormatException.
      for (final json in [
        movementJson()..remove('tipo'),
        movementJson(type: 'TRANSFERENCIA'),
      ]) {
        expect(
          () => parseApi(() => Movement.fromJson(json)),
          throwsA(isA<UnexpectedException>()),
          reason: 'tipo: ${json['tipo']}',
        );
      }
    });

    test('importe o fecha inválidos: error propio, no FormatException', () {
      expect(
        () => parseApi(() => Movement.fromJson(movementJson(value: 'doce'))),
        throwsA(
          isA<UnexpectedException>().having(
            (e) => e.message,
            'message',
            'El servidor devolvió datos no válidos.',
          ),
        ),
      );
      expect(
        () =>
            parseApi(() => Movement.fromJson(movementJson(date: '13/10/2026'))),
        throwsA(isA<UnexpectedException>()),
      );
    });
  });

  group('MovementDraft.toJson', () {
    test(
      'valor como texto, fecha AAAA-MM-DD, id_medio y sin nota si es null',
      () {
        final json = MovementDraft(
          type: MovementType.income,
          amountPesos: 400000,
          date: DateTime(2026, 10, 3),
          description: 'Salario',
          categoryId: 9,
          methodId: 5,
        ).toJson();
        expect(json, {
          'tipo': 'INGRESO',
          'valor': '400000',
          'fecha': '2026-10-03',
          'descripcion': 'Salario',
          'id_categoria': 9,
          'id_medio': 5,
        });
        expect(json['valor'], isA<String>());
      },
    );

    test('con nota la incluye', () {
      final json = MovementDraft(
        type: MovementType.expense,
        amountPesos: 1,
        date: DateTime(2026, 10, 3),
        description: 'x',
        categoryId: 1,
        methodId: 1,
        note: 'ojo',
      ).toJson();
      expect(json['nota'], 'ojo');
      expect(json['tipo'], 'GASTO');
    });
  });

  group('MovementType', () {
    test('fromApi traduce el valor de la API', () {
      expect(MovementType.fromApi('INGRESO'), MovementType.income);
      expect(MovementType.fromApi('GASTO'), MovementType.expense);
    });

    test('fromApi con un tipo ausente o desconocido lanza FormatException', () {
      expect(() => MovementType.fromApi('otra'), throwsFormatException);
      expect(() => MovementType.fromApi(null), throwsFormatException);
    });
  });

  group('Movement.createdAt (creado_en)', () {
    test('con «creado_en» guarda la hora de Colombia tal cual', () {
      final m = Movement.fromJson(
        movementJson(createdAt: '2026-10-14 15:45:09'),
      );
      expect(m.createdAt, DateTime(2026, 10, 14, 15, 45, 9));
    });

    test('sin «creado_en» (API aún sin instalar) → null, sin fallar', () {
      final json = movementJson();
      expect(json.containsKey('creado_en'), isFalse);
      expect(Movement.fromJson(json).createdAt, isNull);
    });

    test('«creado_en» nulo, vacío o ilegible → null, sin fallar', () {
      for (final raw in [null, '', 'ayer', '2026-10-14', 12345]) {
        final json = movementJson()..['creado_en'] = raw;
        expect(Movement.fromJson(json).createdAt, isNull, reason: '«$raw»');
      }
    });

    test('el resto del movimiento no cambia por la hora', () {
      final m = Movement.fromJson(
        movementJson(id: 7, createdAt: '2026-10-14 00:00:00'),
      );
      expect(m.id, 7);
      expect(m.valueCents, 2500000);
      expect(m.createdAt, DateTime(2026, 10, 14));
    });

    test('el fixture buildMovement lleva createdAt', () {
      expect(buildMovement().createdAt, isNull);
      final at = DateTime(2026, 10, 14, 9, 30);
      expect(buildMovement(createdAt: at).createdAt, at);
    });
  });
}
