import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_cuentas/core/errors/app_exception.dart';
import 'package:sistema_cuentas/core/models/movement_type.dart';
import 'package:sistema_cuentas/core/network/api_response.dart';
import 'package:sistema_cuentas/features/catalogs/models/contact.dart';
import 'package:sistema_cuentas/features/dues/models/due.dart';
import 'package:sistema_cuentas/features/movements/models/due_payment_draft.dart';
import 'package:sistema_cuentas/features/recurring/models/due_history_item.dart';
import 'package:sistema_cuentas/features/recurring/models/finish_draft.dart';
import 'package:sistema_cuentas/features/recurring/models/recurring_draft.dart';
import 'package:sistema_cuentas/features/recurring/models/recurring_payment.dart';

import '../../../helpers/recurring_fixtures.dart';

Matcher _spanishError(String message) => throwsA(
  isA<UnexpectedException>().having((e) => e.message, 'message', message),
);

void main() {
  group('RecurringPayment.fromJson', () {
    test('mapea un acuerdo activo del listado completo', () {
      final p = RecurringPayment.fromJson(
        recurringJson(
          id: 10,
          contactId: 4,
          contact: 'Oscar',
          capital: '5000000.00',
          note: 'Casa 2',
          totalPaid: '540000.00',
          nextDue: '2026-11-07',
        ),
      );

      expect(p.id, 10);
      expect(p.type, MovementType.income);
      expect(p.isIncome, isTrue);
      expect(p.description, 'Arriendo de Oscar');
      expect(p.valueCents, 18000000);
      expect(p.dayOfMonth, 7);
      expect(p.everyMonths, 1);
      expect(p.startDate, DateTime(2026, 1, 7));
      expect(p.category, 'Arriendos');
      expect(p.active, isTrue);
      expect(p.contactId, 4);
      expect(p.contact, 'Oscar');
      expect(p.capitalCents, 500000000);
      expect(p.note, 'Casa 2');
      expect(p.totalPaidCents, 54000000);
      expect(p.nextDueDate, DateTime(2026, 11, 7));
      expect(p.endDate, isNull);
    });

    test('proximo_vencimiento ausente: nextDueDate es null (detalle.php)', () {
      final p = RecurringPayment.fromJson(recurringJson());
      expect(p.nextDueDate, isNull);
      expect(p.totalPaidCents, isNull);
    });

    test('proximo_vencimiento null explícito o vacío: también null', () {
      expect(
        RecurringPayment.fromJson({
          ...recurringJson(),
          'proximo_vencimiento': null,
        }).nextDueDate,
        isNull,
      );
      expect(
        RecurringPayment.fromJson({
          ...recurringJson(),
          'proximo_vencimiento': '',
        }).nextDueDate,
        isNull,
      );
    });

    test('todos los opcionales ausentes quedan en null', () {
      final p = RecurringPayment.fromJson(recurringJson());
      expect(p.contactId, isNull);
      expect(p.contact, isNull);
      expect(p.capitalCents, isNull);
      expect(p.note, isNull);
      expect(p.endDate, isNull);
      expect(p.closingNote, isNull);
    });

    test('capital en cero se conserva como 0, no como ausente', () {
      final p = RecurringPayment.fromJson(recurringJson(capital: '0.00'));
      expect(p.capitalCents, 0);
    });

    test('total pagado en cero es 0, no null', () {
      final p = RecurringPayment.fromJson(recurringJson(totalPaid: '0.00'));
      expect(p.totalPaidCents, 0);
    });

    test('finalizado: fecha de fin, motivo y active en false', () {
      final p = RecurringPayment.fromJson(
        recurringJson(
          status: 'FINALIZADO',
          endDate: '2026-09-30',
          closingNote: 'Se mudó',
        ),
      );
      expect(p.active, isFalse);
      expect(p.endDate, DateTime(2026, 9, 30));
      expect(p.closingNote, 'Se mudó');
    });

    test('un estado desconocido se trata como no activo', () {
      expect(
        RecurringPayment.fromJson(recurringJson(status: 'PAUSADO')).active,
        isFalse,
      );
    });

    test('gasto y cada 3 meses', () {
      final p = RecurringPayment.fromJson(
        recurringJson(type: 'GASTO', everyMonths: 3, day: 31),
      );
      expect(p.type, MovementType.expense);
      expect(p.isIncome, isFalse);
      expect(p.everyMonths, 3);
      expect(p.dayOfMonth, 31);
    });

    test('valor inválido vía parseApi: error propio en español', () {
      for (final bad in ['abc', '', '1,5']) {
        expect(
          () => parseApi(
            () => RecurringPayment.fromJson(recurringJson(value: bad)),
          ),
          _spanishError('El servidor devolvió datos no válidos.'),
          reason: '«$bad»',
        );
      }
    });

    test('capital o total pagado inválidos: error propio en español', () {
      expect(
        () => parseApi(
          () => RecurringPayment.fromJson(recurringJson(capital: 'x')),
        ),
        _spanishError('El servidor devolvió datos no válidos.'),
      );
      expect(
        () => parseApi(
          () => RecurringPayment.fromJson(recurringJson(totalPaid: 'x')),
        ),
        _spanishError('El servidor devolvió datos no válidos.'),
      );
    });

    test('tipo desconocido: error propio en español', () {
      expect(
        () => parseApi(
          () => RecurringPayment.fromJson(recurringJson(type: 'OTRO')),
        ),
        _spanishError('El servidor devolvió datos no válidos.'),
      );
    });

    test('sin fecha de inicio: «datos incompletos»', () {
      expect(
        () => parseApi(
          () => RecurringPayment.fromJson({
            ...recurringJson(),
            'fecha_inicio': null,
          }),
        ),
        _spanishError('El servidor devolvió datos incompletos.'),
      );
    });

    test('fecha de fin mal formada: error propio', () {
      expect(
        () => parseApi(
          () => RecurringPayment.fromJson(recurringJson(endDate: 'ayer')),
        ),
        _spanishError('El servidor devolvió datos no válidos.'),
      );
    });
  });

  group('DueHistoryItem.fromJson', () {
    test('mapea un mes del historial', () {
      final item = DueHistoryItem.fromJson(
        historyJson(
          id: 7,
          period: '2026-09-01',
          dueDate: '2026-09-07',
          paid: '180000.00',
          balance: '0.00',
          status: 'PAGADO',
          overdue: false,
          daysToDue: -36,
        ),
      );
      expect(item.id, 7);
      expect(item.period, DateTime(2026, 9));
      expect(item.dueDate, DateTime(2026, 9, 7));
      expect(item.expectedCents, 18000000);
      expect(item.paidCents, 18000000);
      expect(item.balanceCents, 0);
      expect(item.status, DueStatus.paid);
      expect(item.overdue, isFalse);
      expect(item.daysToDue, -36);
    });

    test('estado desconocido: error propio en español', () {
      expect(
        () => parseApi(
          () => DueHistoryItem.fromJson(historyJson(status: 'RARO')),
        ),
        _spanishError('El servidor devolvió datos no válidos.'),
      );
    });

    test('dinero inválido: error propio en español', () {
      expect(
        () => parseApi(() => DueHistoryItem.fromJson(historyJson(paid: 'no'))),
        _spanishError('El servidor devolvió datos no válidos.'),
      );
    });
  });

  group('Contact.fromJson', () {
    test('mapea un contacto con teléfono y nota', () {
      final c = Contact.fromJson(
        contactJson(id: 4, name: 'Oscar', phone: '3001234567', note: 'Socio'),
      );
      expect(c.id, 4);
      expect(c.name, 'Oscar');
      expect(c.active, isTrue);
      expect(c.phone, '3001234567');
      expect(c.note, 'Socio');
    });

    test('teléfono y nota ausentes o vacíos quedan en null', () {
      final c = Contact.fromJson({...contactJson(), 'telefono': '  '});
      expect(c.phone, isNull);
      expect(c.note, isNull);
    });

    test('«activo» solo es falso con false explícito', () {
      expect(Contact.fromJson(contactJson(active: false)).active, isFalse);
      expect(
        Contact.fromJson({'id_contacto': 1, 'nombre': 'Ana'}).active,
        isTrue,
      );
    });

    test('sin nombre: «datos incompletos»', () {
      expect(
        () => parseApi(
          () => Contact.fromJson({...contactJson(), 'nombre': null}),
        ),
        _spanishError('El servidor devolvió datos incompletos.'),
      );
    });
  });

  group('DuePaymentDraft.toJson', () {
    DuePaymentDraft draft({String? note}) => DuePaymentDraft(
      dueId: 21,
      recurringId: 77,
      type: MovementType.income,
      amountPesos: 180000,
      date: DateTime(2026, 10, 13, 22),
      methodId: 5,
      note: note,
    );

    test('lleva tipo, valor como texto, fecha, id_medio e id_vencimiento', () {
      expect(draft().toJson(), {
        'tipo': 'INGRESO',
        'valor': '180000',
        'fecha': '2026-10-13',
        'id_medio': 5,
        'id_vencimiento': 21,
      });
    });

    test('NO envía el recurringId ni descripcion ni categoria', () {
      final json = draft(note: 'x').toJson();
      expect(json.containsKey('recurringId'), isFalse);
      expect(json.containsKey('id_pago_recurrente'), isFalse);
      expect(json.containsKey('descripcion'), isFalse);
      expect(json.containsKey('id_categoria'), isFalse);
      expect(json.values.contains(77), isFalse);
    });

    test('el valor viaja como String y la nota solo si existe', () {
      expect(draft().toJson()['valor'], isA<String>());
      expect(draft().toJson().containsKey('nota'), isFalse);
      expect(draft(note: 'abono').toJson()['nota'], 'abono');
    });
  });

  group('RecurringDraft.toJson', () {
    test('con todos los campos', () {
      final json = RecurringDraft(
        type: MovementType.expense,
        description: 'Netflix',
        valuePesos: 45000,
        dayOfMonth: 12,
        everyMonths: 3,
        startDate: DateTime(2026, 10, 1),
        categoryId: 8,
        contactId: 4,
        capitalPesos: 1000000,
        note: 'plan',
      ).toJson();

      expect(json, {
        'tipo': 'GASTO',
        'descripcion': 'Netflix',
        'valor': '45000',
        'dia_pago': 12,
        'cada_meses': 3,
        'fecha_inicio': '2026-10-01',
        'id_categoria': 8,
        'id_contacto': 4,
        'capital': '1000000',
        'nota': 'plan',
      });
    });

    test('sin contacto, capital ni nota no manda esas llaves', () {
      final json = RecurringDraft(
        type: MovementType.income,
        description: 'Arriendo',
        valuePesos: 180000,
        dayOfMonth: 7,
        everyMonths: 1,
        startDate: DateTime(2026, 10, 1),
        categoryId: 9,
      ).toJson();
      expect(json.containsKey('id_contacto'), isFalse);
      expect(json.containsKey('capital'), isFalse);
      expect(json.containsKey('nota'), isFalse);
      expect(json['valor'], isA<String>());
    });
  });

  group('FinishDraft.toJson', () {
    test('sin capital: solo id, fecha y motivo', () {
      final json = FinishDraft(
        recurringId: 10,
        endDate: DateTime(2026, 10, 13),
        closingNote: 'Se mudó',
      ).toJson();
      expect(json, {
        'id_pago_recurrente': 10,
        'fecha_fin': '2026-10-13',
        'nota_cierre': 'Se mudó',
      });
    });

    test('con capital y medio: valor_capital como texto e id_medio', () {
      final json = FinishDraft(
        recurringId: 10,
        endDate: DateTime(2026, 10, 13),
        closingNote: 'Devolvió',
        capitalPesos: 2000000,
        methodId: 5,
      ).toJson();
      expect(json['valor_capital'], '2000000');
      expect(json['id_medio'], 5);
    });

    test('un medio sin capital no se envía', () {
      final json = FinishDraft(
        recurringId: 10,
        endDate: DateTime(2026, 10, 13),
        closingNote: 'Fin',
        methodId: 5,
      ).toJson();
      expect(json.containsKey('id_medio'), isFalse);
      expect(json.containsKey('valor_capital'), isFalse);
    });
  });
}
