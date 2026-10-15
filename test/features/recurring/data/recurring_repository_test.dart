import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_cuentas/core/errors/app_exception.dart';
import 'package:sistema_cuentas/core/models/movement_type.dart';
import 'package:sistema_cuentas/core/network/api_endpoints.dart';
import 'package:sistema_cuentas/features/dues/models/due.dart';
import 'package:sistema_cuentas/features/recurring/data/recurring_repository.dart';
import 'package:sistema_cuentas/features/recurring/models/finish_draft.dart';
import 'package:sistema_cuentas/features/recurring/models/recurring_draft.dart';

import '../../../helpers/auth_fixtures.dart';
import '../../../helpers/recurring_fixtures.dart';
import '../../../support/api_harness.dart';
import '../../../support/fake_api_adapter.dart';

RecurringDraft _draft({int? capital}) => RecurringDraft(
  type: MovementType.income,
  description: 'Arriendo de Oscar',
  valuePesos: 180000,
  dayOfMonth: 7,
  everyMonths: 1,
  startDate: DateTime(2026, 10, 1),
  categoryId: 9,
  capitalPesos: capital,
);

FinishDraft _finish({int? capital, int? method}) => FinishDraft(
  recurringId: 10,
  endDate: DateTime(2026, 10, 13),
  closingNote: 'Se mudó',
  capitalPesos: capital,
  methodId: method,
);

Matcher _api(String message, {int? status, String? code}) => throwsA(
  isA<ApiException>()
      .having((e) => e.message, 'message', message)
      .having((e) => e.statusCode, 'status', status ?? isNotNull)
      .having((e) => e.code, 'code', code ?? anything),
);

void main() {
  group('list', () {
    test(
      'trae los acuerdos de pagos_recurrentes/listar.php con el token',
      () async {
        final h = ApiHarness(
          FakeApiAdapter.json(
            successEnvelope({
              'pagos_recurrentes': [
                recurringJson(
                  id: 1,
                  totalPaid: '540000.00',
                  nextDue: '2026-11-07',
                ),
                recurringJson(
                  id: 2,
                  type: 'GASTO',
                  status: 'FINALIZADO',
                  endDate: '2026-09-30',
                  closingNote: 'Se mudó',
                  totalPaid: '0.00',
                ),
              ],
            }),
          ),
        );

        final items = await RecurringRepository(h.api).list();

        expect(h.single.method, 'GET');
        expect(h.single.path, ApiEndpoints.recurringList);
        expect(h.single.authorization, 'Bearer tok');
        expect(items.map((p) => p.id), [1, 2]);
        expect(items.first.totalPaidCents, 54000000);
        expect(items.first.nextDueDate, DateTime(2026, 11, 7));
        expect(items.last.active, isFalse);
        expect(items.last.nextDueDate, isNull);
      },
    );

    test('sin parámetros: trae activos y finalizados juntos', () async {
      final h = ApiHarness(
        FakeApiAdapter.json(successEnvelope({'pagos_recurrentes': <Object>[]})),
      );
      await RecurringRepository(h.api).list();
      expect(h.single.options.queryParameters, isEmpty);
    });

    test('lista vacía es válida', () async {
      final h = ApiHarness(
        FakeApiAdapter.json(successEnvelope({'pagos_recurrentes': <Object>[]})),
      );
      expect(await RecurringRepository(h.api).list(), isEmpty);
    });

    test('proximo_vencimiento ausente no rompe', () async {
      final h = ApiHarness(
        FakeApiAdapter.json(
          successEnvelope({
            'pagos_recurrentes': [recurringJson()],
          }),
        ),
      );
      final items = await RecurringRepository(h.api).list();
      expect(items.single.nextDueDate, isNull);
    });

    test('sin la clave «pagos_recurrentes»: «datos incompletos»', () async {
      final h = ApiHarness(FakeApiAdapter.json(successEnvelope({'x': 1})));
      await expectLater(
        RecurringRepository(h.api).list(),
        throwsA(
          isA<UnexpectedException>().having(
            (e) => e.message,
            'message',
            'El servidor devolvió datos incompletos.',
          ),
        ),
      );
    });

    test('valor inválido en un acuerdo: error en español', () async {
      final h = ApiHarness(
        FakeApiAdapter.json(
          successEnvelope({
            'pagos_recurrentes': [recurringJson(value: 'abc')],
          }),
        ),
      );
      await expectLater(
        RecurringRepository(h.api).list(),
        throwsA(
          isA<UnexpectedException>().having(
            (e) => e.message,
            'message',
            'El servidor devolvió datos no válidos.',
          ),
        ),
      );
    });

    test('sin conexión: NetworkException', () async {
      final h = ApiHarness(FakeApiAdapter.connectionError());
      await expectLater(
        RecurringRepository(h.api).list(),
        throwsA(isA<NetworkException>()),
      );
    });

    test('401 cierra la sesión local', () async {
      final h = ApiHarness(
        FakeApiAdapter.json(
          errorEnvelope('NO_AUTORIZADO', 'Sesión no válida.'),
          status: 401,
        ),
      );
      await expectLater(
        RecurringRepository(h.api).list(),
        _api('Sesión no válida.', status: 401),
      );
      expect(h.unauthorizedCalls, 1);
    });
  });

  group('detail', () {
    test(
      'pide id_pago_recurrente a detalle.php y arma ficha e historial',
      () async {
        final h = ApiHarness(
          FakeApiAdapter.json(
            successEnvelope({
              'pago_recurrente': recurringJson(id: 10, contact: 'Oscar'),
              'vencimientos': [
                historyJson(id: 3, period: '2026-10-01'),
                historyJson(
                  id: 2,
                  period: '2026-09-01',
                  status: 'PAGADO',
                  paid: '180000.00',
                  balance: '0.00',
                ),
              ],
            }),
          ),
        );

        final detail = await RecurringRepository(h.api).detail(10);

        expect(h.single.method, 'GET');
        expect(h.single.path, ApiEndpoints.recurringDetail);
        expect(h.single.options.queryParameters, {'id_pago_recurrente': 10});
        expect(detail.payment.id, 10);
        expect(detail.payment.contact, 'Oscar');
        expect(detail.history.map((i) => i.id), [3, 2]);
        expect(detail.history.last.status, DueStatus.paid);
      },
    );

    test('un acuerdo sin historial es válido', () async {
      final h = ApiHarness(
        FakeApiAdapter.json(
          successEnvelope({
            'pago_recurrente': recurringJson(),
            'vencimientos': <Object>[],
          }),
        ),
      );
      final detail = await RecurringRepository(h.api).detail(10);
      expect(detail.history, isEmpty);
    });

    test('404 (no existe): mensaje del servidor', () async {
      final h = ApiHarness(
        FakeApiAdapter.json(
          errorEnvelope('NO_ENCONTRADO', 'El pago recurrente no existe.'),
          status: 404,
        ),
      );
      await expectLater(
        RecurringRepository(h.api).detail(99),
        _api(
          'El pago recurrente no existe.',
          status: 404,
          code: 'NO_ENCONTRADO',
        ),
      );
    });

    test('sin «vencimientos» en la respuesta: «datos incompletos»', () async {
      final h = ApiHarness(
        FakeApiAdapter.json(
          successEnvelope({'pago_recurrente': recurringJson()}),
        ),
      );
      await expectLater(
        RecurringRepository(h.api).detail(10),
        throwsA(isA<UnexpectedException>()),
      );
    });

    test('estado de historial desconocido: error en español', () async {
      final h = ApiHarness(
        FakeApiAdapter.json(
          successEnvelope({
            'pago_recurrente': recurringJson(),
            'vencimientos': [historyJson(status: 'RARO')],
          }),
        ),
      );
      await expectLater(
        RecurringRepository(h.api).detail(10),
        throwsA(
          isA<UnexpectedException>().having(
            (e) => e.message,
            'message',
            'El servidor devolvió datos no válidos.',
          ),
        ),
      );
    });
  });

  group('create', () {
    test('envía el cuerpo con el valor como texto a crear.php', () async {
      final h = ApiHarness(
        FakeApiAdapter.json(
          successEnvelope({'pago_recurrente': recurringJson(id: 55)}),
          status: 201,
        ),
      );

      final saved = await RecurringRepository(h.api).create(_draft());

      expect(h.single.method, 'POST');
      expect(h.single.path, ApiEndpoints.recurringCreate);
      expect(h.single.body, {
        'tipo': 'INGRESO',
        'descripcion': 'Arriendo de Oscar',
        'valor': '180000',
        'dia_pago': 7,
        'cada_meses': 1,
        'fecha_inicio': '2026-10-01',
        'id_categoria': 9,
      });
      expect((h.single.body! as Map)['valor'], isA<String>());
      expect(saved.id, 55);
      expect(saved.valueCents, 18000000);
    });

    test('con capital lo manda como texto', () async {
      final h = ApiHarness(
        FakeApiAdapter.json(
          successEnvelope({'pago_recurrente': recurringJson()}),
          status: 201,
        ),
      );
      await RecurringRepository(h.api).create(_draft(capital: 5000000));
      expect((h.single.body! as Map)['capital'], '5000000');
    });

    test(
      '422 (categoría de capital): mensaje en español con su código',
      () async {
        final h = ApiHarness(
          FakeApiAdapter.json(
            errorEnvelope(
              'CATEGORIA_INVALIDA',
              'La categoría no puede ser de capital.',
            ),
            status: 422,
          ),
        );
        await expectLater(
          RecurringRepository(h.api).create(_draft()),
          _api(
            'La categoría no puede ser de capital.',
            status: 422,
            code: 'CATEGORIA_INVALIDA',
          ),
        );
        expect(h.unauthorizedCalls, 0);
      },
    );

    test('409 duplicado: mensaje del servidor', () async {
      final h = ApiHarness(
        FakeApiAdapter.json(
          errorEnvelope('DUPLICADO', 'Ya existe un acuerdo igual.'),
          status: 409,
        ),
      );
      await expectLater(
        RecurringRepository(h.api).create(_draft()),
        _api('Ya existe un acuerdo igual.', status: 409, code: 'DUPLICADO'),
      );
    });

    test('éxito sin «pago_recurrente»: error propio', () async {
      final h = ApiHarness(FakeApiAdapter.json(successEnvelope({'x': 1})));
      await expectLater(
        RecurringRepository(h.api).create(_draft()),
        throwsA(isA<UnexpectedException>()),
      );
    });

    test('sin conexión: NetworkException', () async {
      final h = ApiHarness(FakeApiAdapter.connectionError());
      await expectLater(
        RecurringRepository(h.api).create(_draft()),
        throwsA(isA<NetworkException>()),
      );
    });
  });

  group('delete', () {
    test('POST al endpoint de eliminar con solo el id', () async {
      final h = ApiHarness(
        FakeApiAdapter.json(
          successEnvelope({
            'resultado': {
              'id_pago_recurrente': 10,
              'estado': 'FINALIZADO',
              'vencimientos_anulados': 3,
            },
          }),
        ),
      );

      await RecurringRepository(h.api).delete(10);

      expect(h.single.method, 'POST');
      expect(h.single.path, ApiEndpoints.recurringDelete);
      expect(h.single.body, {'id_pago_recurrente': 10});
    });
  });

  group('finish', () {
    Map<String, dynamic> ok() => successEnvelope({
      'resultado': {
        'id_pago_recurrente': 10,
        'estado': 'FINALIZADO',
        'vencimientos_anulados': 2,
      },
    });

    test(
      'sin capital manda id, fecha y motivo; no manda capital ni medio',
      () async {
        final h = ApiHarness(FakeApiAdapter.json(ok()));

        await RecurringRepository(h.api).finish(_finish());

        expect(h.single.method, 'POST');
        expect(h.single.path, ApiEndpoints.recurringFinish);
        expect(h.single.body, {
          'id_pago_recurrente': 10,
          'fecha_fin': '2026-10-13',
          'nota_cierre': 'Se mudó',
        });
      },
    );

    test('con capital manda valor_capital (texto) e id_medio', () async {
      final h = ApiHarness(FakeApiAdapter.json(ok()));

      await RecurringRepository(h.api)
          .finish(_finish(capital: 2000000, method: 5));

      final body = h.single.body! as Map;
      expect(body['valor_capital'], '2000000');
      expect(body['valor_capital'], isA<String>());
      expect(body['id_medio'], 5);
    });

    test('un medio sin capital no viaja', () async {
      final h = ApiHarness(FakeApiAdapter.json(ok()));
      await RecurringRepository(h.api).finish(_finish(method: 5));
      final body = h.single.body! as Map;
      expect(body.containsKey('id_medio'), isFalse);
      expect(body.containsKey('valor_capital'), isFalse);
    });

    test(
      '422 (fecha futura): mensaje en español y no se traga el error',
      () async {
        final h = ApiHarness(
          FakeApiAdapter.json(
            errorEnvelope(
              'FECHA_FUTURA',
              'La fecha de cierre no puede ser futura.',
            ),
            status: 422,
          ),
        );
        await expectLater(
          RecurringRepository(h.api).finish(_finish()),
          _api(
            'La fecha de cierre no puede ser futura.',
            status: 422,
            code: 'FECHA_FUTURA',
          ),
        );
      },
    );

    test('409 (ya estaba finalizado): mensaje del servidor', () async {
      final h = ApiHarness(
        FakeApiAdapter.json(
          errorEnvelope(
            'YA_FINALIZADO',
            'Este pago recurrente ya fue finalizado.',
          ),
          status: 409,
        ),
      );
      await expectLater(
        RecurringRepository(h.api).finish(_finish()),
        _api(
          'Este pago recurrente ya fue finalizado.',
          status: 409,
          code: 'YA_FINALIZADO',
        ),
      );
    });

    test('sin conexión: NetworkException', () async {
      final h = ApiHarness(FakeApiAdapter.connectionError());
      await expectLater(
        RecurringRepository(h.api).finish(_finish()),
        throwsA(isA<NetworkException>()),
      );
    });

    test('respuesta que no es un objeto: error propio en español', () async {
      final h = ApiHarness(FakeApiAdapter.json(successEnvelope([1, 2])));
      await expectLater(
        RecurringRepository(h.api).finish(_finish()),
        throwsA(
          isA<UnexpectedException>().having(
            (e) => e.message,
            'message',
            'El servidor no devolvió el objeto esperado.',
          ),
        ),
      );
    });
  });
}
