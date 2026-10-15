import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_cuentas/core/models/movement_type.dart';
import 'package:sistema_cuentas/features/recurring/utils/recurring_rules.dart';

import '../../../helpers/movement_fixtures.dart';
import '../../../helpers/recurring_fixtures.dart';

void main() {
  group('filter y sort', () {
    final rent = buildRecurring(id: 1, description: 'Arriendo', day: 7);
    final netflix = buildRecurring(
      id: 2,
      type: MovementType.expense,
      description: 'Netflix',
      day: 12,
    );
    final gym = buildRecurring(
      id: 3,
      type: MovementType.expense,
      description: 'gimnasio',
      day: 12,
    );
    final old = buildRecurring(
      id: 4,
      description: 'Préstamo viejo',
      day: 1,
      active: false,
    );
    final all = [old, netflix, gym, rent];

    test('Activos: solo los activos, por día de pago y luego por nombre', () {
      final ids = RecurringRules.filter(
        all,
        RecurringFilter.active,
      ).map((p) => p.id);
      // Día 7 primero; el 12 desempata por nombre sin importar mayúsculas
      // («gimnasio» < «Netflix»).
      expect(ids, [1, 3, 2]);
    });

    test('Finalizados: solo los finalizados', () {
      final ids = RecurringRules.filter(
        all,
        RecurringFilter.finished,
      ).map((p) => p.id);
      expect(ids, [4]);
    });

    test('sin finalizados, la lista de finalizados queda vacía', () {
      expect(
        RecurringRules.filter([rent, netflix], RecurringFilter.finished),
        isEmpty,
      );
    });

    test('lista vacía', () {
      expect(RecurringRules.filter(const [], RecurringFilter.active), isEmpty);
      expect(RecurringRules.sort(const []), isEmpty);
    });

    test(
      'sort: los activos antes que los finalizados y no muta la original',
      () {
        final sorted = RecurringRules.sort(all);
        expect(sorted.map((p) => p.id), [1, 3, 2, 4]);
        expect(all.map((p) => p.id), [4, 2, 3, 1]);
      },
    );

    test('etiquetas del filtro', () {
      expect(RecurringFilter.values.map((f) => f.label), [
        'Activos',
        'Finalizados',
      ]);
    });
  });

  group('cadenceLabel y scheduleLabel', () {
    test('cada mes (singular) y cada N meses', () {
      expect(RecurringRules.cadenceLabel(1), 'Cada mes');
      expect(RecurringRules.cadenceLabel(2), 'Cada 2 meses');
      expect(RecurringRules.cadenceLabel(12), 'Cada 12 meses');
    });

    test('todas las opciones del servidor tienen etiqueta', () {
      expect(RecurringRules.everyMonthsOptions, [1, 2, 3, 4, 6, 12]);
      for (final months in RecurringRules.everyMonthsOptions) {
        expect(RecurringRules.cadenceLabel(months), isNotEmpty);
      }
    });

    test('día · cadencia', () {
      expect(
        RecurringRules.scheduleLabel(buildRecurring(day: 7)),
        'Día 7 · Cada mes',
      );
      expect(
        RecurringRules.scheduleLabel(buildRecurring(day: 31, everyMonths: 3)),
        'Día 31 · Cada 3 meses',
      );
    });
  });

  group('validateDescription', () {
    test('nulo, vacío, espacios o una sola letra: piden el nombre', () {
      const message = 'Escribe el nombre (mínimo 2 letras).';
      expect(RecurringRules.validateDescription(null), message);
      expect(RecurringRules.validateDescription(''), message);
      expect(RecurringRules.validateDescription('     '), message);
      expect(RecurringRules.validateDescription(' a '), message);
    });

    test('dos letras ya sirven (el borde)', () {
      expect(RecurringRules.validateDescription('Ab'), isNull);
      expect(RecurringRules.validateDescription('  Ab  '), isNull);
    });

    test('un nombre largo es válido (el tope lo pone el campo)', () {
      expect(RecurringRules.validateDescription(longRecurringName), isNull);
    });
  });

  group('validateValue', () {
    test('vacío, nulo, cero y solo símbolos piden el valor', () {
      for (final value in [null, '', '0', '000', r'$ ', 'abc']) {
        expect(
          RecurringRules.validateValue(value),
          'Escribe el valor.',
          reason: '$value',
        );
      }
    });

    test('con puntos de miles y en 12 dígitos es válido', () {
      expect(RecurringRules.validateValue('180.000'), isNull);
      expect(RecurringRules.validateValue('999.999.999.999'), isNull);
      expect(RecurringRules.validateValue('1'), isNull);
    });
  });

  group('validateDay', () {
    test('1 y 31 son los bordes válidos', () {
      expect(RecurringRules.validateDay('1'), isNull);
      expect(RecurringRules.validateDay('31'), isNull);
      expect(RecurringRules.validateDay(' 15 '), isNull);
    });

    test('0 y 32 no', () {
      expect(RecurringRules.validateDay('0'), 'Un día del 1 al 31.');
      expect(RecurringRules.validateDay('32'), 'Un día del 1 al 31.');
    });

    test('nulo, vacío, texto y negativos no', () {
      for (final value in [null, '', '  ', 'abc', '-1', '1.5']) {
        expect(
          RecurringRules.validateDay(value),
          'Un día del 1 al 31.',
          reason: '$value',
        );
      }
    });
  });

  group('validateCategory', () {
    test('sin categoría la pide', () {
      expect(RecurringRules.validateCategory(null), 'Elige la categoría.');
    });

    test('con categoría es válido', () {
      expect(RecurringRules.validateCategory(buildCategory()), isNull);
    });
  });

  group('buildDraft', () {
    test('arma el borrador: textos recortados, números y ids', () {
      final draft = RecurringRules.buildDraft(
        type: MovementType.expense,
        description: '  Netflix  ',
        valueText: '45.000',
        dayText: ' 12 ',
        everyMonths: 3,
        startDate: DateTime(2026, 10, 13, 20),
        category: buildCategory(id: 8),
        contact: buildContact(id: 4),
        capitalText: '1.000.000',
        note: '  plan familiar ',
      );

      expect(draft.type, MovementType.expense);
      expect(draft.description, 'Netflix');
      expect(draft.valuePesos, 45000);
      expect(draft.dayOfMonth, 12);
      expect(draft.everyMonths, 3);
      expect(draft.startDate, DateTime(2026, 10, 13));
      expect(draft.categoryId, 8);
      expect(draft.contactId, 4);
      expect(draft.capitalPesos, 1000000);
      expect(draft.note, 'plan familiar');
    });

    test('sin contacto, capital ni nota: quedan en null', () {
      final draft = RecurringRules.buildDraft(
        type: MovementType.income,
        description: 'Arriendo',
        valueText: '180.000',
        dayText: '7',
        everyMonths: 1,
        startDate: DateTime(2026, 10, 1),
        category: buildCategory(),
        contact: null,
        capitalText: '',
        note: '   ',
      );
      expect(draft.contactId, isNull);
      expect(draft.capitalPesos, isNull);
      expect(draft.note, isNull);
    });

    test('un capital en cero se trata como sin capital', () {
      final draft = RecurringRules.buildDraft(
        type: MovementType.income,
        description: 'Arriendo',
        valueText: '1',
        dayText: '7',
        everyMonths: 1,
        startDate: DateTime(2026, 10, 1),
        category: buildCategory(),
        contact: null,
        capitalText: '0',
        note: '',
      );
      expect(draft.capitalPesos, isNull);
    });
  });

  group('validateClosingNote', () {
    const message = 'Cuenta por qué se cierra (mínimo 3 letras).';

    test('nulo, vacío, 2 letras (también con espacios) no pasan', () {
      expect(RecurringRules.validateClosingNote(null), message);
      expect(RecurringRules.validateClosingNote(''), message);
      expect(RecurringRules.validateClosingNote('ok'), message);
      expect(RecurringRules.validateClosingNote('  ok  '), message);
    });

    test('3 letras es el mínimo válido', () {
      expect(RecurringRules.validateClosingNote('Fin'), isNull);
      expect(RecurringRules.validateClosingNote(' fin '), isNull);
    });

    test('un motivo largo es válido', () {
      expect(RecurringRules.validateClosingNote('x' * 255), isNull);
    });
  });

  group('validateEndDate', () {
    final today = DateTime(2026, 10, 13, 12);
    final start = DateTime(2026, 1, 7);

    String? check(DateTime? date) =>
        RecurringRules.validateEndDate(date, today: today, start: start);

    test('sin fecha la pide', () {
      expect(check(null), 'Elige la fecha.');
    });

    test('una fecha futura no es válida; hoy sí, a cualquier hora', () {
      expect(check(DateTime(2026, 10, 14)), 'La fecha no puede ser futura.');
      expect(check(DateTime(2026, 10, 13, 23, 59)), isNull);
    });

    test('anterior al inicio no es válida; el mismo día del inicio sí', () {
      expect(
        check(DateTime(2026, 1, 6)),
        'No puede ser anterior al inicio del acuerdo.',
      );
      expect(check(DateTime(2026, 1, 7, 0, 1)), isNull);
    });

    test('entre el inicio y hoy es válida', () {
      expect(check(DateTime(2026, 6, 15)), isNull);
    });

    test('un acuerdo que empieza hoy solo puede cerrarse hoy', () {
      expect(
        RecurringRules.validateEndDate(
          DateTime(2026, 10, 13),
          today: today,
          start: DateTime(2026, 10, 13),
        ),
        isNull,
      );
      expect(
        RecurringRules.validateEndDate(
          DateTime(2026, 10, 12),
          today: today,
          start: DateTime(2026, 10, 13),
        ),
        'No puede ser anterior al inicio del acuerdo.',
      );
    });
  });

  group('lastEndDate y acuerdos que aún no empiezan', () {
    final today = DateTime(2026, 10, 13, 9);

    test('es hoy cuando el acuerdo ya empezó', () {
      expect(
        RecurringRules.lastEndDate(DateTime(2026, 1, 7), today),
        DateTime(2026, 10, 13),
      );
    });

    test('es el inicio cuando el acuerdo empieza en el futuro', () {
      expect(
        RecurringRules.lastEndDate(DateTime(2026, 12, 1, 18), today),
        DateTime(2026, 12, 1),
      );
    });

    test('un acuerdo que empieza hoy: hoy', () {
      expect(
        RecurringRules.lastEndDate(DateTime(2026, 10, 13, 23), today),
        DateTime(2026, 10, 13),
      );
    });

    test(
      'el rango del calendario nunca queda vacío (firstDate <= lastDate)',
      () {
        for (final start in [
          DateTime(2000),
          DateTime(2026, 10, 13),
          DateTime(2026, 10, 14),
          DateTime(2030, 1, 1),
        ]) {
          expect(
            RecurringRules.lastEndDate(start, today).isBefore(start),
            isFalse,
            reason: '$start',
          );
        }
      },
    );

    test('inicio futuro: cerrarlo el mismo día de inicio es válido', () {
      final start = DateTime(2026, 12, 1);
      expect(
        RecurringRules.validateEndDate(start, today: today, start: start),
        isNull,
      );
    });

    test('inicio futuro: un día antes del inicio no es válido', () {
      expect(
        RecurringRules.validateEndDate(
          DateTime(2026, 11, 30),
          today: today,
          start: DateTime(2026, 12, 1),
        ),
        'No puede ser anterior al inicio del acuerdo.',
      );
    });

    test('inicio futuro: un día después del inicio es «futura»', () {
      expect(
        RecurringRules.validateEndDate(
          DateTime(2026, 12, 2),
          today: today,
          start: DateTime(2026, 12, 1),
        ),
        'La fecha no puede ser futura.',
      );
    });
  });

  group('capital al finalizar', () {
    test('hasCapital: solo con un importe mayor que cero', () {
      expect(RecurringRules.hasCapital(''), isFalse);
      expect(RecurringRules.hasCapital('0'), isFalse);
      expect(RecurringRules.hasCapital('0.000'), isFalse);
      expect(RecurringRules.hasCapital('abc'), isFalse);
      expect(RecurringRules.hasCapital('1'), isTrue);
      expect(RecurringRules.hasCapital('1.500.000'), isTrue);
    });

    test('validateCapitalMethod: con capital y sin medio pide el medio', () {
      expect(
        RecurringRules.validateCapitalMethod('500.000', null),
        'Elige el medio de pago del capital.',
      );
    });

    test('con capital y medio, o sin capital, es válido', () {
      expect(
        RecurringRules.validateCapitalMethod('500.000', buildMethod()),
        isNull,
      );
      expect(RecurringRules.validateCapitalMethod('', null), isNull);
      expect(RecurringRules.validateCapitalMethod('0', null), isNull);
    });
  });

  group('buildFinishDraft', () {
    test('sin capital: ni valor ni medio, aunque haya un medio elegido', () {
      final draft = RecurringRules.buildFinishDraft(
        recurringId: 10,
        endDate: DateTime(2026, 10, 13, 9),
        closingNote: '  Me devolvió todo  ',
        capitalText: '',
        method: buildMethod(id: 5),
      );
      expect(draft.recurringId, 10);
      expect(draft.endDate, DateTime(2026, 10, 13));
      expect(draft.closingNote, 'Me devolvió todo');
      expect(draft.capitalPesos, isNull);
      expect(draft.methodId, isNull);
    });

    test('con capital y medio: ambos van', () {
      final draft = RecurringRules.buildFinishDraft(
        recurringId: 10,
        endDate: DateTime(2026, 10, 13),
        closingNote: 'Fin',
        capitalText: '2.000.000',
        method: buildMethod(id: 5),
      );
      expect(draft.capitalPesos, 2000000);
      expect(draft.methodId, 5);
    });

    test('con capital y sin medio: el medio queda en null', () {
      final draft = RecurringRules.buildFinishDraft(
        recurringId: 10,
        endDate: DateTime(2026, 10, 13),
        closingNote: 'Fin',
        capitalText: '2.000.000',
        method: null,
      );
      expect(draft.capitalPesos, 2000000);
      expect(draft.methodId, isNull);
    });

    test('capital en cero cuenta como sin capital', () {
      final draft = RecurringRules.buildFinishDraft(
        recurringId: 10,
        endDate: DateTime(2026, 10, 13),
        closingNote: 'Fin',
        capitalText: '0',
        method: buildMethod(),
      );
      expect(draft.capitalPesos, isNull);
      expect(draft.methodId, isNull);
    });
  });

  group('nombre primero', () {
    test('título: el contacto, o la descripción si no hay', () {
      expect(
        RecurringRules.title(
          buildRecurring(contact: 'oscar', description: 'Arriendo'),
        ),
        'Oscar',
      );
      expect(
        RecurringRules.title(buildRecurring(description: 'netflix')),
        'Netflix',
      );
    });

    test('subtítulo con contacto: descripción · cadencia · próximo', () {
      final payment = buildRecurring(
        description: 'Arriendo de Oscar',
        contact: 'Oscar',
        nextDueDate: DateTime(2026, 11, 7),
      );
      expect(
        RecurringRules.subtitle(payment),
        'Arriendo de Oscar · Día 7 · Cada mes · próximo 7 nov.',
      );
    });

    test('subtítulo sin contacto: categoría · cadencia', () {
      final payment = buildRecurring(
        description: 'Netflix',
        category: 'Streaming',
        day: 12,
        everyMonths: 3,
      );
      expect(
        RecurringRules.subtitle(payment),
        'Streaming · Día 12 · Cada 3 meses',
      );
    });

    test('un acuerdo finalizado no muestra «próximo»', () {
      final payment = buildRecurring(
        contact: 'Oscar',
        active: false,
        nextDueDate: DateTime(2026, 11, 7),
      );
      expect(RecurringRules.subtitle(payment), isNot(contains('próximo')));
    });
  });

  group('eliminar', () {
    test('la consecuencia avisa que también se quitan los meses vencidos', () {
      expect(
        RecurringRules.deleteConsequence(isIncome: false),
        contains('también los vencidos'),
      );
    });

    test('la pregunta lleva el nombre con inicial mayúscula', () {
      expect(
        RecurringRules.deleteQuestion('arriendo de oscar'),
        '¿Eliminar «Arriendo de oscar»?',
      );
    });

    test('la consecuencia dice cobros (ingreso) o pagos (gasto)', () {
      expect(
        RecurringRules.deleteConsequence(isIncome: true),
        contains('cobros'),
      );
      expect(
        RecurringRules.deleteConsequence(isIncome: false),
        contains('pagos'),
      );
      expect(
        RecurringRules.deleteConsequence(isIncome: true),
        contains('se conserva'),
      );
      expect(
        RecurringRules.deleteConsequence(isIncome: true),
        contains('Finalizados'),
      );
    });
  });
}
