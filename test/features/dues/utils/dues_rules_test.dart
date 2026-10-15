import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_cuentas/core/models/movement_type.dart';
import 'package:sistema_cuentas/features/dues/models/due.dart';
import 'package:sistema_cuentas/features/dues/utils/dues_rules.dart';

import '../../../helpers/movement_fixtures.dart';
import '../../../helpers/recurring_fixtures.dart';

DueStatusInfo _info({
  DueStatus status = DueStatus.pending,
  bool overdue = false,
  int daysToDue = 3,
  bool isIncome = true,
}) => DuesRules.statusInfoFor(
  status: status,
  overdue: overdue,
  daysToDue: daysToDue,
  isIncome: isIncome,
);

void main() {
  group('statusInfoFor', () {
    test('vence en N días (neutral), con singular para 1 día', () {
      expect(_info(daysToDue: 3).label, 'Se paga en 3 días');
      expect(_info(daysToDue: 3).tone, DueTone.neutral);
      expect(_info(daysToDue: 1).label, 'Se paga en 1 día');
      expect(_info(daysToDue: 31).label, 'Se paga en 31 días');
    });

    test('vence hoy (aviso)', () {
      final info = _info(daysToDue: 0);
      expect(info.label, 'Se paga hoy');
      expect(info.tone, DueTone.warning);
    });

    test('vencido hace 1 día, singular, y hace N días, en rojo', () {
      final one = _info(overdue: true, daysToDue: -1);
      expect(one.label, 'Vencido hace 1 día');
      expect(one.tone, DueTone.danger);

      final many = _info(overdue: true, daysToDue: -12);
      expect(many.label, 'Vencido hace 12 días');
      expect(many.tone, DueTone.danger);
    });

    test('parcial: antepone «Parcial ·» y conserva el resto del texto', () {
      expect(
        _info(status: DueStatus.partial, daysToDue: 5).label,
        'Parcial · Se paga en 5 días',
      );
      expect(
        _info(status: DueStatus.partial, daysToDue: 0).label,
        'Parcial · Se paga hoy',
      );
      expect(
        _info(status: DueStatus.partial, overdue: true, daysToDue: -2).label,
        'Parcial · Vencido hace 2 días',
      );
    });

    test('parcial no vencido es aviso; parcial vencido es rojo', () {
      expect(
        _info(status: DueStatus.partial, daysToDue: 5).tone,
        DueTone.warning,
      );
      expect(
        _info(status: DueStatus.partial, overdue: true, daysToDue: -2).tone,
        DueTone.danger,
      );
    });

    test(
      'pagado: «Cobrado» si es ingreso y «Pagado» si es gasto, en verde',
      () {
        final income = _info(status: DueStatus.paid, isIncome: true);
        expect(income.label, 'Cobrado');
        expect(income.tone, DueTone.success);
        final expense = _info(status: DueStatus.paid, isIncome: false);
        expect(expense.label, 'Pagado');
        expect(expense.tone, DueTone.success);
      },
    );

    test('pagado gana sobre vencido (un vencido ya saldado no es rojo)', () {
      final info = _info(
        status: DueStatus.paid,
        overdue: true,
        daysToDue: -9,
        isIncome: false,
      );
      expect(info.label, 'Pagado');
      expect(info.tone, DueTone.success);
    });

    test('anulado se muestra «Omitido», neutral, sin importar los días', () {
      final info = _info(
        status: DueStatus.cancelled,
        overdue: true,
        daysToDue: -40,
      );
      expect(info.label, 'Omitido');
      expect(info.tone, DueTone.neutral);
    });

    test('statusInfo(due) usa el tipo del vencimiento', () {
      expect(
        DuesRules.statusInfo(
          buildDue(status: DueStatus.paid, type: MovementType.expense),
        ).label,
        'Pagado',
      );
      expect(
        DuesRules.statusInfo(
          buildDue(status: DueStatus.paid, type: MovementType.income),
        ).label,
        'Cobrado',
      );
    });
  });

  group('textos de acción', () {
    test('Cobrar / Registrar cobro para ingresos', () {
      final due = buildDue(type: MovementType.income);
      expect(DuesRules.actionLabel(due), 'Cobrar');
      expect(DuesRules.confirmLabel(due), 'Registrar cobro');
    });

    test('Pagar / Registrar pago para gastos', () {
      final due = buildDue(type: MovementType.expense);
      expect(DuesRules.actionLabel(due), 'Pagar');
      expect(DuesRules.confirmLabel(due), 'Registrar pago');
    });
  });

  group('filterAndSort', () {
    final openLate = buildDue(
      id: 1,
      dueDate: DateTime(2026, 10, 3),
      overdue: true,
      daysToDue: -5,
    );
    final openSoon = buildDue(id: 2, dueDate: DateTime(2026, 10, 15));
    final expenseOpen = buildDue(
      id: 3,
      type: MovementType.expense,
      dueDate: DateTime(2026, 10, 9),
    );
    final partial = buildDue(
      id: 4,
      type: MovementType.expense,
      dueDate: DateTime(2026, 10, 12),
      paidCents: 5000000,
      status: DueStatus.partial,
    );
    final paid = buildDue(
      id: 5,
      dueDate: DateTime(2026, 10, 1),
      paidCents: 18000000,
      status: DueStatus.paid,
    );
    final omitted = buildDue(
      id: 6,
      type: MovementType.expense,
      dueDate: DateTime(2026, 10, 2),
      balanceCents: 18000000,
      status: DueStatus.cancelled,
    );
    final all = [paid, openSoon, omitted, expenseOpen, openLate, partial];

    test('todos: lo abierto primero por fecha; pagado y omitido al final', () {
      final ids = DuesRules.filterAndSort(all, DueFilter.all).map((d) => d.id);
      // Abiertos: 1 (3 oct), 3 (9 oct), 4 (12 oct), 2 (15 oct).
      // Cerrados: 5 (1 oct), 6 (2 oct).
      expect(ids, [1, 3, 4, 2, 5, 6]);
    });

    test('un parcial con saldo sigue entre los abiertos', () {
      final ids = DuesRules.filterAndSort([paid, partial], DueFilter.all);
      expect(ids.first.id, 4);
    });

    test('un pendiente sin saldo (nada que pagar) va con los cerrados', () {
      final zero = buildDue(
        id: 7,
        dueDate: DateTime(2026, 10, 1),
        balanceCents: 0,
      );
      final ids = DuesRules.filterAndSort([zero, openSoon], DueFilter.all);
      expect(ids.map((d) => d.id), [2, 7]);
    });

    test('Me pagan: solo ingresos', () {
      final ids = DuesRules.filterAndSort(all, DueFilter.income);
      expect(ids.map((d) => d.id), [1, 2, 5]);
      expect(ids.every((d) => d.isIncome), isTrue);
    });

    test('Yo pago: solo gastos', () {
      final ids = DuesRules.filterAndSort(all, DueFilter.expense);
      expect(ids.map((d) => d.id), [3, 4, 6]);
      expect(ids.every((d) => !d.isIncome), isTrue);
    });

    test('misma fecha: desempata por id (orden estable)', () {
      final a = buildDue(id: 9, dueDate: DateTime(2026, 10, 5));
      final b = buildDue(id: 8, dueDate: DateTime(2026, 10, 5));
      expect(DuesRules.filterAndSort([a, b], DueFilter.all).map((d) => d.id), [
        8,
        9,
      ]);
    });

    test('lista vacía y no muta la original', () {
      expect(DuesRules.filterAndSort(const [], DueFilter.all), isEmpty);
      final original = [paid, openSoon];
      DuesRules.filterAndSort(original, DueFilter.all);
      expect(original.map((d) => d.id), [5, 2]);
    });

    test('etiquetas del filtro', () {
      expect(DueFilter.values.map((f) => f.label), [
        'Todos',
        'Me pagan',
        'Yo pago',
      ]);
    });
  });

  group('validateAmount (saldo de 180.000)', () {
    final due = buildDue(); // saldo 18.000.000 centavos

    test('vacío, nulo y cero piden el valor', () {
      expect(DuesRules.validateAmount(null, due), 'Escribe el valor.');
      expect(DuesRules.validateAmount('', due), 'Escribe el valor.');
      expect(DuesRules.validateAmount('0', due), 'Escribe el valor.');
      expect(DuesRules.validateAmount(r'$ ', due), 'Escribe el valor.');
    });

    test('el saldo exacto es válido', () {
      expect(DuesRules.validateAmount('180.000', due), isNull);
    });

    test('un abono parcial es válido', () {
      expect(DuesRules.validateAmount('50.000', due), isNull);
      expect(DuesRules.validateAmount('1', due), isNull);
    });

    test('un peso por encima del saldo no pasa y dice cuánto es el saldo', () {
      expect(
        DuesRules.validateAmount('180.001', due),
        r'No puede pasar del saldo ($ 180.000).',
      );
    });

    test('mucho mayor al saldo no pasa', () {
      expect(
        DuesRules.validateAmount('999.999.999.999', due),
        r'No puede pasar del saldo ($ 180.000).',
      );
    });

    test('con un abono previo el tope es el saldo restante', () {
      final partial = buildDue(
        paidCents: 10000000,
        status: DueStatus.partial,
      ); // saldo 80.000
      expect(DuesRules.validateAmount('80.000', partial), isNull);
      expect(
        DuesRules.validateAmount('80.001', partial),
        r'No puede pasar del saldo ($ 80.000).',
      );
    });
  });

  group('validateAmount con centavos en el saldo', () {
    test('saldo de 100,50: 100 pasa y 101 (redondeado hacia arriba) no', () {
      final due = buildDue(expectedCents: 10050);
      expect(DuesRules.validateAmount('100', due), isNull);
      expect(
        DuesRules.validateAmount('101', due),
        r'No puede pasar del saldo ($ 101).',
        reason: 'la app maneja pesos enteros; el saldo se muestra redondeado',
      );
    });
  });

  group('validatePaymentMethod', () {
    test('sin medio: pide elegirlo', () {
      expect(DuesRules.validatePaymentMethod(null), 'Elige el medio de pago.');
    });

    test('con medio: válido', () {
      expect(DuesRules.validatePaymentMethod(buildMethod()), isNull);
    });
  });

  group('validateDate', () {
    final today = DateTime(2026, 10, 13, 15, 30);

    test('sin fecha pide elegirla', () {
      expect(DuesRules.validateDate(null, today: today), 'Elige la fecha.');
    });

    test('hoy (aunque con otra hora) y el pasado son válidos', () {
      expect(
        DuesRules.validateDate(DateTime(2026, 10, 13, 23, 59), today: today),
        isNull,
      );
      expect(
        DuesRules.validateDate(DateTime(2026, 1, 1), today: today),
        isNull,
      );
    });

    test('mañana es futura', () {
      expect(
        DuesRules.validateDate(DateTime(2026, 10, 14), today: today),
        'La fecha no puede ser futura.',
      );
    });
  });

  group('buildDraft', () {
    test('ingreso: tipo INGRESO, valor en pesos, fecha sin hora y ids', () {
      final due = buildDue(id: 21, recurringId: 77);
      final draft = DuesRules.buildDraft(
        due: due,
        amountText: '55.000',
        date: DateTime(2026, 10, 13, 18, 45),
        method: buildMethod(id: 5),
        note: '',
      );

      expect(draft.dueId, 21);
      expect(draft.recurringId, 77);
      expect(draft.type, MovementType.income);
      expect(draft.amountPesos, 55000);
      expect(draft.date, DateTime(2026, 10, 13));
      expect(draft.methodId, 5);
      expect(draft.note, isNull);
    });

    test('gasto: tipo GASTO', () {
      final draft = DuesRules.buildDraft(
        due: buildDue(type: MovementType.expense),
        amountText: '1',
        date: DateTime(2026, 10, 13),
        method: buildMethod(),
        note: 'x',
      );
      expect(draft.type, MovementType.expense);
      expect(draft.amountPesos, 1);
    });

    test('la nota se recorta; vacía o solo espacios queda en null', () {
      final due = buildDue();
      String? check(String note) => DuesRules.buildDraft(
        due: due,
        amountText: '1.000',
        date: DateTime(2026, 10, 13),
        method: buildMethod(),
        note: note,
      ).note;

      expect(check('  adelanto de mes  '), 'adelanto de mes');
      expect(check('   '), isNull);
      expect(check(''), isNull);
    });

    test('un importe de 12 dígitos no se pierde', () {
      final draft = DuesRules.buildDraft(
        due: buildDue(),
        amountText: '999.999.999.999',
        date: DateTime(2026, 10, 13),
        method: buildMethod(),
        note: '',
      );
      expect(draft.amountPesos, 999999999999);
    });
  });

  group('nombre primero en la fila', () {
    test('con contacto: el título es el contacto', () {
      final due = buildDue(
        description: 'Desarrollo mensual',
        contact: 'oscar fcs',
      );
      expect(DuesRules.tileTitle(due), 'Oscar fcs');
    });

    test('sin contacto: el título es la descripción', () {
      expect(DuesRules.tileTitle(buildDue(description: 'netflix')), 'Netflix');
    });

    test('subtítulo con contacto: la descripción y la fecha corta', () {
      final due = buildDue(
        description: 'Desarrollo mensual',
        contact: 'Oscar',
        dueDate: DateTime(2026, 10, 7),
      );
      expect(DuesRules.tileSubtitle(due), 'Desarrollo mensual · 7 oct.');
    });

    test('subtítulo sin contacto: la categoría y la fecha corta', () {
      final due = buildDue(
        description: 'Netflix',
        category: 'Streaming',
        dueDate: DateTime(2026, 10, 12),
      );
      expect(DuesRules.tileSubtitle(due), 'Streaming · 12 oct.');
    });

    test('el diálogo de pago: «Contacto · Descripción» (contacto primero)', () {
      expect(
        DuesRules.payDialogSubtitle(
          buildDue(description: 'Desarrollo mensual', contact: 'Oscar FCS'),
        ),
        'Oscar FCS · Desarrollo mensual',
      );
    });

    test('el diálogo de pago sin contacto: solo la descripción', () {
      expect(
        DuesRules.payDialogSubtitle(buildDue(description: 'Netflix')),
        'Netflix',
      );
    });
  });

  group('texto de estado «Se paga…»', () {
    test('ya no dice «Vence»; «Vencido hace N días» no cambia', () {
      expect(_info(daysToDue: 3).label, isNot(contains('Vence en')));
      expect(_info(daysToDue: 0).label, isNot(contains('Vence hoy')));
      expect(_info(overdue: true, daysToDue: -4).label, 'Vencido hace 4 días');
      expect(_info(overdue: true, daysToDue: -1).label, 'Vencido hace 1 día');
    });
  });
}
