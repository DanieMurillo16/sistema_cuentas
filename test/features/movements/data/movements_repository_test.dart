import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_cuentas/core/errors/app_exception.dart';
import 'package:sistema_cuentas/core/models/movement_type.dart';
import 'package:sistema_cuentas/core/network/api_endpoints.dart';
import 'package:sistema_cuentas/features/movements/data/movements_repository.dart';
import 'package:sistema_cuentas/features/movements/models/due_payment_draft.dart';
import 'package:sistema_cuentas/features/movements/models/movement_draft.dart';

import '../../../helpers/auth_fixtures.dart';
import '../../../helpers/movement_fixtures.dart';
import '../../../support/api_harness.dart';
import '../../../support/fake_api_adapter.dart';

MovementDraft _draft({String? note}) => MovementDraft(
  type: MovementType.expense,
  amountPesos: 25000,
  date: DateTime(2026, 10, 13),
  description: 'Mercado',
  categoryId: 3,
  methodId: 2,
  note: note,
);

Map<String, dynamic> _page(int count, {required int startId, int? total}) => {
  'success': true,
  'data': {
    'movimientos': [
      for (var i = 0; i < count; i++) movementJson(id: startId + i),
    ],
  },
  'meta': {'total_registros': ?total, 'limite': 200},
};

void main() {
  group('listBetween', () {
    test(
      'pide el rango del mes a movimientos/listar.php con el token',
      () async {
        final h = ApiHarness(
          FakeApiAdapter.json(
            successEnvelope({
              'movimientos': [movementJson(id: 1), movementJson(id: 2)],
            }),
          ),
        );

        final items = await MovementsRepository(h.api)
            .listBetween(from: DateTime(2026, 10), to: DateTime(2026, 10, 31));

        expect(items.map((m) => m.id), [1, 2]);
        expect(items.first.valueCents, 2500000);
        expect(h.single.method, 'GET');
        expect(h.single.path, ApiEndpoints.movementsList);
        expect(h.single.options.queryParameters, {
          'desde': '2026-10-01',
          'hasta': '2026-10-31',
          'limite': 200,
          'desplazamiento': 0,
        });
        expect(h.single.authorization, 'Bearer tok');
      },
    );

    test('mes vacío: lista vacía y una sola petición', () async {
      final h = ApiHarness(
        FakeApiAdapter.json(successEnvelope({'movimientos': <Object>[]})),
      );
      final items = await MovementsRepository(h.api)
          .listBetween(from: DateTime(2026, 10), to: DateTime(2026, 10, 31));
      expect(items, isEmpty);
      expect(h.adapter.requests, hasLength(1));
    });

    test('pagina con meta.total_registros hasta juntar todos', () async {
      final pages = [
        _page(200, startId: 1, total: 250),
        _page(50, startId: 201, total: 250),
      ];
      final h = ApiHarness(
        FakeApiAdapter((options) async {
          final offset = options.queryParameters['desplazamiento'] as int;
          return FakeApiAdapter.jsonResponse(pages[offset == 0 ? 0 : 1], 200);
        }),
      );

      final items = await MovementsRepository(h.api)
          .listBetween(from: DateTime(2026, 10), to: DateTime(2026, 10, 31));

      expect(items, hasLength(250));
      expect(items.last.id, 250);
      expect(
        h.adapter.requests.map(
          (r) => r.options.queryParameters['desplazamiento'],
        ),
        [0, 200],
      );
    });

    test('si el total coincide con lo recibido no pide otra página', () async {
      final h = ApiHarness(
        FakeApiAdapter.json(_page(200, startId: 1, total: 200)),
      );
      final items = await MovementsRepository(h.api)
          .listBetween(from: DateTime(2026, 10), to: DateTime(2026, 10, 31));
      expect(items, hasLength(200));
      expect(h.adapter.requests, hasLength(1));
    });

    test(
      'sin meta.total_registros sigue hasta que llega una página corta',
      () async {
        final h = ApiHarness(
          FakeApiAdapter((options) async {
            final offset = options.queryParameters['desplazamiento'] as int;
            return FakeApiAdapter.jsonResponse(
              offset == 0 ? _page(200, startId: 1) : _page(3, startId: 201),
              200,
            );
          }),
        );
        final items = await MovementsRepository(h.api)
            .listBetween(from: DateTime(2026, 10), to: DateTime(2026, 10, 31));
        expect(items, hasLength(203));
        expect(h.adapter.requests, hasLength(2));
      },
    );

    test(
      'respuesta sin la clave «movimientos»: error propio en español',
      () async {
        final h = ApiHarness(FakeApiAdapter.json(successEnvelope({'otra': 1})));
        await expectLater(
          MovementsRepository(
            h.api,
          ).listBetween(from: DateTime(2026, 10), to: DateTime(2026, 10, 31)),
          throwsA(
            isA<UnexpectedException>().having(
              (e) => e.message,
              'message',
              'El servidor devolvió datos incompletos.',
            ),
          ),
        );
      },
    );

    test(
      'un movimiento con importe inválido: error propio en español',
      () async {
        final h = ApiHarness(
          FakeApiAdapter.json(
            successEnvelope({
              'movimientos': [movementJson(value: 'abc')],
            }),
          ),
        );
        await expectLater(
          MovementsRepository(
            h.api,
          ).listBetween(from: DateTime(2026, 10), to: DateTime(2026, 10, 31)),
          throwsA(
            isA<UnexpectedException>().having(
              (e) => e.message,
              'message',
              'El servidor devolvió datos no válidos.',
            ),
          ),
        );
      },
    );

    test('sin conexión: NetworkException en español', () async {
      final h = ApiHarness(FakeApiAdapter.connectionError());
      await expectLater(
        MovementsRepository(h.api)
            .listBetween(from: DateTime(2026, 10), to: DateTime(2026, 10, 31)),
        throwsA(
          isA<NetworkException>().having(
            (e) => e.message,
            'message',
            'No fue posible conectar con el servidor. Revisa tu conexión.',
          ),
        ),
      );
    });

    test('401: cierra la sesión local y avisa en español', () async {
      final h = ApiHarness(
        FakeApiAdapter.json(
          errorEnvelope('NO_AUTORIZADO', 'Sesión no válida.'),
          status: 401,
        ),
      );
      await expectLater(
        MovementsRepository(h.api)
            .listBetween(from: DateTime(2026, 10), to: DateTime(2026, 10, 31)),
        throwsA(
          isA<ApiException>()
              .having((e) => e.message, 'message', 'Sesión no válida.')
              .having((e) => e.statusCode, 'status', 401),
        ),
      );
      expect(h.unauthorizedCalls, 1);
      expect(h.tokens.token, isNull);
    });
  });

  group('search', () {
    final from = DateTime(2026, 10);
    final to = DateTime(2026, 10, 31);

    FakeApiAdapter okAdapter() => FakeApiAdapter.json(
      successEnvelope({
        'movimientos': [movementJson(id: 1)],
      }),
    );

    test('sin filtros manda solo fechas y paginación', () async {
      final h = ApiHarness(okAdapter());
      await MovementsRepository(h.api).search(from: from, to: to);
      expect(h.single.options.queryParameters, {
        'desde': '2026-10-01',
        'hasta': '2026-10-31',
        'limite': 200,
        'desplazamiento': 0,
      });
      expect(h.single.options.queryParameters.containsKey('tipo'), isFalse);
      expect(
        h.single.options.queryParameters.containsKey('id_categoria'),
        isFalse,
      );
      expect(h.single.options.queryParameters.containsKey('id_medio'), isFalse);
    });

    test('manda tipo (valor de la API), id_categoria e id_medio', () async {
      final h = ApiHarness(okAdapter());
      await MovementsRepository(h.api).search(
        from: from,
        to: to,
        type: MovementType.income,
        categoryId: 9,
        methodId: 5,
      );
      expect(h.single.path, ApiEndpoints.movementsList);
      expect(h.single.options.queryParameters, {
        'desde': '2026-10-01',
        'hasta': '2026-10-31',
        'limite': 200,
        'desplazamiento': 0,
        'tipo': 'INGRESO',
        'id_categoria': 9,
        'id_medio': 5,
      });
      expect(h.single.authorization, 'Bearer tok');
    });

    test('solo el tipo: no manda categoría ni medio', () async {
      final h = ApiHarness(okAdapter());
      await MovementsRepository(h.api)
          .search(from: from, to: to, type: MovementType.expense);
      final query = h.single.options.queryParameters;
      expect(query['tipo'], 'GASTO');
      expect(query.containsKey('id_categoria'), isFalse);
      expect(query.containsKey('id_medio'), isFalse);
    });

    test('solo categoría: no manda tipo ni medio', () async {
      final h = ApiHarness(okAdapter());
      await MovementsRepository(h.api)
          .search(from: from, to: to, categoryId: 3);
      final query = h.single.options.queryParameters;
      expect(query['id_categoria'], 3);
      expect(query.containsKey('tipo'), isFalse);
      expect(query.containsKey('id_medio'), isFalse);
    });

    test('los filtros se repiten en cada página', () async {
      final pages = [
        _page(200, startId: 1, total: 230),
        _page(30, startId: 201, total: 230),
      ];
      final h = ApiHarness(
        FakeApiAdapter((options) async {
          final offset = options.queryParameters['desplazamiento'] as int;
          return FakeApiAdapter.jsonResponse(pages[offset == 0 ? 0 : 1], 200);
        }),
      );

      final items = await MovementsRepository(h.api).search(
        from: from,
        to: to,
        type: MovementType.expense,
        categoryId: 3,
        methodId: 2,
      );

      expect(items, hasLength(230));
      expect(h.adapter.requests, hasLength(2));
      for (final request in h.adapter.requests) {
        expect(request.options.queryParameters['tipo'], 'GASTO');
        expect(request.options.queryParameters['id_categoria'], 3);
        expect(request.options.queryParameters['id_medio'], 2);
      }
      expect(
        h.adapter.requests.map(
          (r) => r.options.queryParameters['desplazamiento'],
        ),
        [0, 200],
      );
    });

    test('sin resultados: lista vacía y una sola petición', () async {
      final h = ApiHarness(
        FakeApiAdapter.json(successEnvelope({'movimientos': <Object>[]})),
      );
      final items = await MovementsRepository(h.api)
          .search(from: from, to: to, type: MovementType.income, methodId: 1);
      expect(items, isEmpty);
      expect(h.adapter.requests, hasLength(1));
    });

    test('sin conexión: NetworkException en español', () async {
      final h = ApiHarness(FakeApiAdapter.connectionError());
      await expectLater(
        MovementsRepository(h.api)
            .search(from: from, to: to, type: MovementType.income),
        throwsA(
          isA<NetworkException>().having(
            (e) => e.message,
            'message',
            'No fue posible conectar con el servidor. Revisa tu conexión.',
          ),
        ),
      );
    });

    test('listBetween es search sin filtros', () async {
      final h = ApiHarness(okAdapter());
      await MovementsRepository(h.api).listBetween(from: from, to: to);
      expect(h.single.options.queryParameters.keys, [
        'desde',
        'hasta',
        'limite',
        'desplazamiento',
      ]);
    });
  });

  group('register', () {
    test(
      'envía el valor como texto, id_medio y la fecha a registrar.php',
      () async {
        final h = ApiHarness(
          FakeApiAdapter.json(
            successEnvelope({
              'movimiento': movementJson(id: 77, value: '25000.00'),
            }),
            status: 201,
          ),
        );

        final saved = await MovementsRepository(h.api)
            .register(_draft(note: 'ok'));

        expect(h.single.method, 'POST');
        expect(h.single.path, ApiEndpoints.movementRegister);
        expect(h.single.body, {
          'tipo': 'GASTO',
          'valor': '25000',
          'fecha': '2026-10-13',
          'descripcion': 'Mercado',
          'id_categoria': 3,
          'id_medio': 2,
          'nota': 'ok',
        });
        expect((h.single.body! as Map)['valor'], isA<String>());
        expect(saved.id, 77);
        expect(saved.valueCents, 2500000);
      },
    );

    test('sin nota no manda la llave «nota»', () async {
      final h = ApiHarness(
        FakeApiAdapter.json(
          successEnvelope({'movimiento': movementJson()}),
          status: 201,
        ),
      );
      await MovementsRepository(h.api).register(_draft());
      expect((h.single.body! as Map).containsKey('nota'), isFalse);
    });

    test(
      '422 (fecha futura): mensaje del servidor en español con su código',
      () async {
        final h = ApiHarness(
          FakeApiAdapter.json(
            errorEnvelope('FECHA_FUTURA', 'La fecha no puede ser futura.'),
            status: 422,
          ),
        );
        await expectLater(
          MovementsRepository(h.api).register(_draft()),
          throwsA(
            isA<ApiException>()
                .having(
                  (e) => e.message,
                  'message',
                  'La fecha no puede ser futura.',
                )
                .having((e) => e.code, 'code', 'FECHA_FUTURA')
                .having((e) => e.statusCode, 'status', 422),
          ),
        );
        expect(h.unauthorizedCalls, 0);
      },
    );

    test('409 DUPLICADO (gasto ya pagado): mensaje en español', () async {
      final h = ApiHarness(
        FakeApiAdapter.json(
          errorEnvelope('DUPLICADO', 'Este gasto ya fue pagado.'),
          status: 409,
        ),
      );
      await expectLater(
        MovementsRepository(h.api).register(_draft()),
        throwsA(
          isA<ApiException>()
              .having((e) => e.message, 'message', 'Este gasto ya fue pagado.')
              .having((e) => e.statusCode, 'status', 409),
        ),
      );
    });

    test('ruta no instalada (404 sin cuerpo JSON): mensaje propio', () async {
      final h = ApiHarness(FakeApiAdapter.json(null, status: 404));
      await expectLater(
        MovementsRepository(h.api).register(_draft()),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            'La ruta solicitada no está instalada en el servidor.',
          ),
        ),
      );
    });

    test('sin conexión: NetworkException', () async {
      final h = ApiHarness(FakeApiAdapter.connectionError());
      await expectLater(
        MovementsRepository(h.api).register(_draft()),
        throwsA(isA<NetworkException>()),
      );
    });

    test('éxito sin «movimiento» en la respuesta: error propio', () async {
      final h = ApiHarness(FakeApiAdapter.json(successEnvelope({'x': 1})));
      await expectLater(
        MovementsRepository(h.api).register(_draft()),
        throwsA(isA<UnexpectedException>()),
      );
    });
  });

  group('registerDuePayment', () {
    DuePaymentDraft dueDraft({String? note}) => DuePaymentDraft(
      dueId: 21,
      recurringId: 77,
      type: MovementType.income,
      amountPesos: 180000,
      date: DateTime(2026, 10, 13),
      methodId: 5,
      note: note,
    );

    Map<String, dynamic> created() => successEnvelope({
      'movimiento': movementJson(id: 88, type: 'INGRESO', value: '180000.00'),
    });

    test('el cuerpo lleva tipo, valor como texto, fecha, id_medio e id_vencimiento y NO recurringId', () async {
      final h = ApiHarness(FakeApiAdapter.json(created(), status: 201));

      final saved = await MovementsRepository(h.api)
          .registerDuePayment(dueDraft());

      expect(h.single.method, 'POST');
      expect(h.single.path, ApiEndpoints.movementRegister);
      expect(h.single.body, {
        'tipo': 'INGRESO',
        'valor': '180000',
        'fecha': '2026-10-13',
        'id_medio': 5,
        'id_vencimiento': 21,
      });
      final body = h.single.body! as Map;
      expect(body['valor'], isA<String>());
      expect(body.containsKey('recurringId'), isFalse);
      expect(body.containsKey('id_pago_recurrente'), isFalse);
      expect(saved.id, 88);
      expect(saved.valueCents, 18000000);
    });

    test(
      'no manda descripcion ni id_categoria (los toma el servidor)',
      () async {
        final h = ApiHarness(FakeApiAdapter.json(created(), status: 201));
        await MovementsRepository(h.api).registerDuePayment(dueDraft());
        final body = h.single.body! as Map;
        expect(body.containsKey('descripcion'), isFalse);
        expect(body.containsKey('id_categoria'), isFalse);
      },
    );

    test('con nota la manda; sin nota no manda la llave', () async {
      final h = ApiHarness(FakeApiAdapter.json(created(), status: 201));
      final repository = MovementsRepository(h.api);
      await repository.registerDuePayment(dueDraft());
      await repository.registerDuePayment(dueDraft(note: 'abono'));
      expect(
        (h.adapter.requests.first.body! as Map).containsKey('nota'),
        isFalse,
      );
      expect((h.adapter.requests.last.body! as Map)['nota'], 'abono');
    });

    test('422 (pasa del saldo): mensaje del servidor en español', () async {
      final h = ApiHarness(
        FakeApiAdapter.json(
          errorEnvelope(
            'VALOR_EXCEDE_SALDO',
            'El valor supera el saldo del vencimiento.',
          ),
          status: 422,
        ),
      );
      await expectLater(
        MovementsRepository(h.api).registerDuePayment(dueDraft()),
        throwsA(
          isA<ApiException>()
              .having(
                (e) => e.message,
                'message',
                'El valor supera el saldo del vencimiento.',
              )
              .having((e) => e.code, 'code', 'VALOR_EXCEDE_SALDO')
              .having((e) => e.statusCode, 'status', 422),
        ),
      );
      expect(h.unauthorizedCalls, 0);
    });

    test('409 (el vencimiento ya está pagado): mensaje en español', () async {
      final h = ApiHarness(
        FakeApiAdapter.json(
          errorEnvelope('DUPLICADO', 'Este vencimiento ya fue pagado.'),
          status: 409,
        ),
      );
      await expectLater(
        MovementsRepository(h.api).registerDuePayment(dueDraft()),
        throwsA(
          isA<ApiException>()
              .having(
                (e) => e.message,
                'message',
                'Este vencimiento ya fue pagado.',
              )
              .having((e) => e.statusCode, 'status', 409),
        ),
      );
    });

    test('éxito sin «movimiento»: error propio', () async {
      final h = ApiHarness(FakeApiAdapter.json(successEnvelope({'x': 1})));
      await expectLater(
        MovementsRepository(h.api).registerDuePayment(dueDraft()),
        throwsA(isA<UnexpectedException>()),
      );
    });

    test('sin conexión: NetworkException', () async {
      final h = ApiHarness(FakeApiAdapter.connectionError());
      await expectLater(
        MovementsRepository(h.api).registerDuePayment(dueDraft()),
        throwsA(isA<NetworkException>()),
      );
    });
  });

  group('cancel', () {
    FakeApiAdapter okAdapter() => FakeApiAdapter.json(
      successEnvelope({
        'movimiento': {
          'id_movimiento': 9,
          'tipo': 'GASTO',
          'valor': '25000.00',
          'fecha': '2026-10-13',
          'anulado': true,
          'motivo_anulacion': 'Registrado por error',
        },
      }),
    );

    test('POST a movimientos/anular.php con id_movimiento y motivo', () async {
      final h = ApiHarness(okAdapter());

      await MovementsRepository(h.api)
          .cancel(9, reason: 'Registrado por error');

      expect(h.single.method, 'POST');
      expect(h.single.path, ApiEndpoints.movementCancel);
      expect(h.single.body, {
        'id_movimiento': 9,
        'motivo': 'Registrado por error',
      });
      expect(h.single.authorization, 'Bearer tok');
    });

    test(
      'no manda ningún id de usuario (la identidad sale del token)',
      () async {
        final h = ApiHarness(okAdapter());

        await MovementsRepository(h.api).cancel(9, reason: 'Duplicado');

        expect((h.single.body! as Map).keys, ['id_movimiento', 'motivo']);
      },
    );

    test('422 «ya está anulado»: mensaje en español con su código', () async {
      final h = ApiHarness(
        FakeApiAdapter.json(
          errorEnvelope('YA_ANULADO', 'El movimiento ya está anulado.'),
          status: 422,
        ),
      );

      await expectLater(
        MovementsRepository(h.api).cancel(9, reason: 'Duplicado'),
        throwsA(
          isA<ApiException>()
              .having(
                (e) => e.message,
                'message',
                'El movimiento ya está anulado.',
              )
              .having((e) => e.code, 'code', 'YA_ANULADO')
              .having((e) => e.statusCode, 'status', 422),
        ),
      );
      expect(h.unauthorizedCalls, 0);
    });

    test(
      '403 sin permiso: mensaje del servidor, sin cerrar la sesión',
      () async {
        final h = ApiHarness(
          FakeApiAdapter.json(
            errorEnvelope('SIN_PERMISO', 'No tienes permiso para esta acción.'),
            status: 403,
          ),
        );

        await expectLater(
          MovementsRepository(h.api).cancel(9, reason: 'Duplicado'),
          throwsA(
            isA<ApiException>()
                .having(
                  (e) => e.message,
                  'message',
                  'No tienes permiso para esta acción.',
                )
                .having((e) => e.statusCode, 'status', 403),
          ),
        );
        expect(h.unauthorizedCalls, 0);
      },
    );

    test('404 no existe: mensaje del servidor', () async {
      final h = ApiHarness(
        FakeApiAdapter.json(
          errorEnvelope('NO_ENCONTRADO', 'El movimiento no existe.'),
          status: 404,
        ),
      );

      await expectLater(
        MovementsRepository(h.api).cancel(404, reason: 'Duplicado'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            'El movimiento no existe.',
          ),
        ),
      );
    });

    test('401: cierra la sesión local', () async {
      final h = ApiHarness(
        FakeApiAdapter.json(
          errorEnvelope('NO_AUTORIZADO', 'Sesión no válida.'),
          status: 401,
        ),
      );

      await expectLater(
        MovementsRepository(h.api).cancel(9, reason: 'Duplicado'),
        throwsA(isA<ApiException>()),
      );
      expect(h.unauthorizedCalls, 1);
      expect(h.tokens.token, isNull);
    });

    test('éxito sin «movimiento»: error propio en español', () async {
      final h = ApiHarness(FakeApiAdapter.json(successEnvelope({'x': 1})));

      await expectLater(
        MovementsRepository(h.api).cancel(9, reason: 'Duplicado'),
        throwsA(
          isA<UnexpectedException>().having(
            (e) => e.message,
            'message',
            'El servidor devolvió datos incompletos.',
          ),
        ),
      );
    });

    test('sin conexión: NetworkException en español', () async {
      final h = ApiHarness(FakeApiAdapter.connectionError());

      await expectLater(
        MovementsRepository(h.api).cancel(9, reason: 'Duplicado'),
        throwsA(
          isA<NetworkException>().having(
            (e) => e.message,
            'message',
            'No fue posible conectar con el servidor. Revisa tu conexión.',
          ),
        ),
      );
    });
  });
}
