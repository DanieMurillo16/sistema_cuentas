import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_cuentas/core/errors/app_exception.dart';
import 'package:sistema_cuentas/core/models/movement_type.dart';
import 'package:sistema_cuentas/core/network/api_response.dart';
import 'package:sistema_cuentas/features/dues/models/due.dart';
import 'package:sistema_cuentas/features/dues/models/due_totals.dart';
import 'package:sistema_cuentas/features/dues/models/dues_month.dart';

import '../../../helpers/recurring_fixtures.dart';

/// Lo que ve el usuario cuando el servidor manda algo que no se puede leer:
/// `parseApi` lo traduce a un error propio en español.
Matcher _spanishError(String message) => throwsA(
  isA<UnexpectedException>().having((e) => e.message, 'message', message),
);

void main() {
  group('Due.fromJson', () {
    test('mapea un vencimiento completo: dinero en centavos y fechas', () {
      final due = Due.fromJson(
        dueJson(
          id: 21,
          recurringId: 10,
          paid: '50000.50',
          balance: '129999.50',
          status: 'PARCIAL',
          overdue: true,
          daysToDue: -4,
          contactId: 4,
          contact: 'Oscar',
        ),
      );

      expect(due.id, 21);
      expect(due.recurringId, 10);
      expect(due.type, MovementType.income);
      expect(due.isIncome, isTrue);
      expect(due.description, 'Arriendo de Oscar');
      expect(due.period, DateTime(2026, 10));
      expect(due.dueDate, DateTime(2026, 10, 7));
      expect(due.expectedCents, 18000000);
      expect(due.paidCents, 5000050);
      expect(due.balanceCents, 12999950);
      expect(due.status, DueStatus.partial);
      expect(due.overdue, isTrue);
      expect(due.daysToDue, -4);
      expect(due.category, 'Arriendos');
      expect(due.contactId, 4);
      expect(due.contact, 'Oscar');
    });

    test('sin contacto: id_contacto y contacto ausentes quedan en null', () {
      final due = Due.fromJson(dueJson());
      expect(due.contactId, isNull);
      expect(due.contact, isNull);
    });

    test('contacto vacío o solo espacios cuenta como ausente', () {
      final due = Due.fromJson({...dueJson(), 'contacto': '   '});
      expect(due.contact, isNull);
    });

    test('id_contacto explícitamente null', () {
      final due = Due.fromJson({...dueJson(), 'id_contacto': null});
      expect(due.contactId, isNull);
    });

    test('ids y días como texto (MariaDB los puede mandar así)', () {
      final due = Due.fromJson({
        ...dueJson(),
        'id_vencimiento': '21',
        'id_pago_recurrente': '10',
        'dias_para_vencer': '-3',
      });
      expect(due.id, 21);
      expect(due.recurringId, 10);
      expect(due.daysToDue, -3);
    });

    test('«vencido» solo es verdadero con true', () {
      expect(Due.fromJson({...dueJson(), 'vencido': 1}).overdue, isFalse);
      expect(Due.fromJson({...dueJson(), 'vencido': null}).overdue, isFalse);
      expect(Due.fromJson(dueJson(overdue: true)).overdue, isTrue);
    });

    test('descripción o categoría ausentes quedan vacías, no revientan', () {
      final due = Due.fromJson({
        ...dueJson(),
        'descripcion': null,
        'categoria': null,
      });
      expect(due.description, '');
      expect(due.category, '');
    });

    test('un importe de 12 dígitos se conserva exacto', () {
      final due = Due.fromJson(
        dueJson(expected: '999999999999.00', balance: '999999999999.00'),
      );
      expect(due.expectedCents, 99999999999900);
      expect(due.balanceCents, 99999999999900);
    });

    test('los cuatro estados del servidor se reconocen', () {
      expect(DueStatus.fromApi('PENDIENTE'), DueStatus.pending);
      expect(DueStatus.fromApi('PARCIAL'), DueStatus.partial);
      expect(DueStatus.fromApi('PAGADO'), DueStatus.paid);
      expect(DueStatus.fromApi('ANULADO'), DueStatus.cancelled);
    });

    test('un estado desconocido o ausente lanza FormatException', () {
      expect(
        () => Due.fromJson(dueJson(status: 'EN_PROCESO')),
        throwsFormatException,
      );
      expect(() => DueStatus.fromApi(null), throwsFormatException);
      expect(() => DueStatus.fromApi('pendiente'), throwsFormatException);
    });

    test('estado desconocido vía parseApi: error propio en español', () {
      expect(
        () => parseApi(() => Due.fromJson(dueJson(status: 'EN_PROCESO'))),
        _spanishError('El servidor devolvió datos no válidos.'),
      );
    });

    test('dinero inválido vía parseApi: error propio en español', () {
      for (final bad in ['abc', '', '12,50', '1e5', '12.345', r'$100']) {
        expect(
          () => parseApi(() => Due.fromJson(dueJson(expected: bad))),
          _spanishError('El servidor devolvió datos no válidos.'),
          reason: '«$bad»',
        );
      }
    });

    test('dinero ausente (null) vía parseApi: error propio', () {
      expect(
        () => parseApi(() => Due.fromJson({...dueJson(), 'saldo': null})),
        _spanishError('El servidor devolvió datos no válidos.'),
      );
    });

    test('tipo desconocido: error propio en español', () {
      expect(
        () => parseApi(() => Due.fromJson(dueJson(type: 'TRASPASO'))),
        _spanishError('El servidor devolvió datos no válidos.'),
      );
    });

    test('fecha mal formada: error propio en español', () {
      expect(
        () => parseApi(() => Due.fromJson(dueJson(dueDate: '07/10/2026'))),
        _spanishError('El servidor devolvió datos no válidos.'),
      );
    });

    test('fecha ausente: «datos incompletos» (TypeError traducido)', () {
      expect(
        () => parseApi(
          () => Due.fromJson({...dueJson(), 'fecha_vencimiento': null}),
        ),
        _spanishError('El servidor devolvió datos incompletos.'),
      );
    });
  });

  group('Due.canPay', () {
    test('pendiente y parcial con saldo se pueden pagar', () {
      expect(buildDue(status: DueStatus.pending).canPay, isTrue);
      expect(
        buildDue(status: DueStatus.partial, paidCents: 100).canPay,
        isTrue,
      );
    });

    test('pagado y anulado no, aunque el saldo no sea cero', () {
      expect(
        buildDue(status: DueStatus.paid, balanceCents: 500).canPay,
        isFalse,
      );
      expect(
        buildDue(status: DueStatus.cancelled, balanceCents: 500).canPay,
        isFalse,
      );
    });

    test('pendiente con saldo en cero o negativo no se puede pagar', () {
      expect(buildDue(balanceCents: 0).canPay, isFalse);
      expect(buildDue(balanceCents: -100).canPay, isFalse);
    });

    test('un vencido sigue pudiéndose pagar', () {
      expect(buildDue(overdue: true, daysToDue: -30).canPay, isTrue);
    });
  });

  group('DueTotals.fromJson', () {
    test('mapea todos los campos', () {
      final totals = DueTotals.fromJson(
        dueTotalsJson(
          type: 'GASTO',
          count: 5,
          expected: '500000.00',
          paid: '120000.00',
          balance: '380000.00',
          pending: 3,
          overdue: 2,
        ),
      );
      expect(totals.type, MovementType.expense);
      expect(totals.count, 5);
      expect(totals.expectedCents, 50000000);
      expect(totals.paidCents, 12000000);
      expect(totals.balanceCents, 38000000);
      expect(totals.pendingCount, 3);
      expect(totals.overdueCount, 2);
    });

    test('contadores como texto', () {
      final totals = DueTotals.fromJson({
        ...dueTotalsJson(),
        'cantidad': '5',
        'cantidad_vencida': '1',
      });
      expect(totals.count, 5);
      expect(totals.overdueCount, 1);
    });

    test('dinero inválido: error propio en español', () {
      expect(
        () =>
            parseApi(() => DueTotals.fromJson(dueTotalsJson(balance: 'mucho'))),
        _spanishError('El servidor devolvió datos no válidos.'),
      );
    });

    test('tipo ausente: error propio en español', () {
      expect(
        () => parseApi(
          () => DueTotals.fromJson({...dueTotalsJson(), 'tipo': null}),
        ),
        _spanishError('El servidor devolvió datos no válidos.'),
      );
    });
  });

  group('DuesMonth.totalsFor', () {
    test('devuelve los totales del tipo pedido', () {
      final month = DuesMonth(
        dues: const [],
        totals: [
          buildDueTotals(type: MovementType.income, balanceCents: 100),
          buildDueTotals(type: MovementType.expense, balanceCents: 200),
        ],
      );
      expect(month.totalsFor(MovementType.income).balanceCents, 100);
      expect(month.totalsFor(MovementType.expense).balanceCents, 200);
    });

    test('un tipo sin vencimientos en el mes da todo en cero', () {
      final month = DuesMonth(
        dues: const [],
        totals: [buildDueTotals(type: MovementType.income, balanceCents: 100)],
      );
      final expense = month.totalsFor(MovementType.expense);
      expect(expense.type, MovementType.expense);
      expect(expense.count, 0);
      expect(expense.expectedCents, 0);
      expect(expense.paidCents, 0);
      expect(expense.balanceCents, 0);
      expect(expense.pendingCount, 0);
      expect(expense.overdueCount, 0);
    });

    test('un mes sin totales tampoco revienta', () {
      expect(emptyTotals.totalsFor(MovementType.income).balanceCents, 0);
    });
  });
}

const emptyTotals = DuesMonth(dues: [], totals: []);
