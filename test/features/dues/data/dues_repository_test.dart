import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_cuentas/core/errors/app_exception.dart';
import 'package:sistema_cuentas/core/models/movement_type.dart';
import 'package:sistema_cuentas/core/network/api_endpoints.dart';
import 'package:sistema_cuentas/features/dues/data/dues_repository.dart';
import 'package:sistema_cuentas/features/dues/models/due.dart';

import '../../../helpers/auth_fixtures.dart';
import '../../../helpers/recurring_fixtures.dart';
import '../../../support/api_harness.dart';
import '../../../support/fake_api_adapter.dart';

Map<String, dynamic> _month({
  List<Map<String, dynamic>>? dues,
  List<Map<String, dynamic>>? totals,
}) => successEnvelope({
  'vencimientos': dues ?? [dueJson()],
  'totales': totals ?? [dueTotalsJson()],
});

void main() {
  group('month', () {
    test(
      'pide periodo=AAAA-MM a vencimientos/listar.php con el token',
      () async {
        final h = ApiHarness(FakeApiAdapter.json(_month()));

        final month = await DuesRepository(h.api).month(DateTime(2026, 10));

        expect(h.single.method, 'GET');
        expect(h.single.path, ApiEndpoints.duesList);
        expect(h.single.options.queryParameters, {'periodo': '2026-10'});
        expect(h.single.authorization, 'Bearer tok');
        expect(month.dues, hasLength(1));
        expect(month.dues.single.balanceCents, 18000000);
        expect(month.totals.single.type, MovementType.income);
      },
    );

    test('el periodo lleva el mes con cero a la izquierda', () async {
      final h = ApiHarness(FakeApiAdapter.json(_month()));
      await DuesRepository(h.api).month(DateTime(2026, 1, 28));
      expect(h.single.options.queryParameters, {'periodo': '2026-01'});
    });

    test(
      'cualquier día del mes da el mismo periodo (incluido el 31)',
      () async {
        final h = ApiHarness(FakeApiAdapter.json(_month()));
        final repository = DuesRepository(h.api);
        await repository.month(DateTime(2026, 12, 31, 23, 59));
        await repository.month(DateTime(2026, 12));
        expect(
          h.adapter.requests.map((r) => r.options.queryParameters['periodo']),
          ['2026-12', '2026-12'],
        );
      },
    );

    test('mes sin vencimientos ni totales: listas vacías', () async {
      final h = ApiHarness(
        FakeApiAdapter.json(_month(dues: const [], totals: const [])),
      );
      final month = await DuesRepository(h.api).month(DateTime(2026, 10));
      expect(month.dues, isEmpty);
      expect(month.totals, isEmpty);
    });

    test('mezcla de ingresos y gastos con sus totales por tipo', () async {
      final h = ApiHarness(
        FakeApiAdapter.json(
          _month(
            dues: [
              dueJson(id: 1),
              dueJson(
                id: 2,
                type: 'GASTO',
                status: 'PAGADO',
                paid: '45000.00',
                balance: '0.00',
                expected: '45000.00',
              ),
            ],
            totals: [
              dueTotalsJson(),
              dueTotalsJson(
                type: 'GASTO',
                expected: '45000.00',
                paid: '45000.00',
                balance: '0.00',
                pending: 0,
              ),
            ],
          ),
        ),
      );

      final month = await DuesRepository(h.api).month(DateTime(2026, 10));

      expect(month.dues.map((d) => d.status), [
        DueStatus.pending,
        DueStatus.paid,
      ]);
      expect(month.totalsFor(MovementType.income).balanceCents, 18000000);
      expect(month.totalsFor(MovementType.expense).balanceCents, 0);
    });

    test('sin la clave «totales»: «datos incompletos»', () async {
      final h = ApiHarness(
        FakeApiAdapter.json(
          successEnvelope({
            'vencimientos': [dueJson()],
          }),
        ),
      );
      await expectLater(
        DuesRepository(h.api).month(DateTime(2026, 10)),
        throwsA(
          isA<UnexpectedException>().having(
            (e) => e.message,
            'message',
            'El servidor devolvió datos incompletos.',
          ),
        ),
      );
    });

    test('importe inválido en un vencimiento: error en español', () async {
      final h = ApiHarness(
        FakeApiAdapter.json(_month(dues: [dueJson(balance: 'abc')])),
      );
      await expectLater(
        DuesRepository(h.api).month(DateTime(2026, 10)),
        throwsA(
          isA<UnexpectedException>().having(
            (e) => e.message,
            'message',
            'El servidor devolvió datos no válidos.',
          ),
        ),
      );
    });

    test('estado desconocido en un vencimiento: error en español', () async {
      final h = ApiHarness(
        FakeApiAdapter.json(_month(dues: [dueJson(status: 'EN_PROCESO')])),
      );
      await expectLater(
        DuesRepository(h.api).month(DateTime(2026, 10)),
        throwsA(isA<UnexpectedException>()),
      );
    });

    test(
      '422 (periodo fuera de rango): mensaje del servidor con su código',
      () async {
        final h = ApiHarness(
          FakeApiAdapter.json(
            errorEnvelope(
              'PERIODO_INVALIDO',
              'El periodo no puede pasar del mes siguiente.',
            ),
            status: 422,
          ),
        );
        await expectLater(
          DuesRepository(h.api).month(DateTime(2027, 6)),
          throwsA(
            isA<ApiException>()
                .having(
                  (e) => e.message,
                  'message',
                  'El periodo no puede pasar del mes siguiente.',
                )
                .having((e) => e.code, 'code', 'PERIODO_INVALIDO')
                .having((e) => e.statusCode, 'status', 422),
          ),
        );
        expect(h.unauthorizedCalls, 0);
      },
    );

    test('403 sin permiso: mensaje del servidor', () async {
      final h = ApiHarness(
        FakeApiAdapter.json(
          errorEnvelope(
            'SIN_PERMISO',
            'No tienes permiso para ver pagos recurrentes.',
          ),
          status: 403,
        ),
      );
      await expectLater(
        DuesRepository(h.api).month(DateTime(2026, 10)),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            'No tienes permiso para ver pagos recurrentes.',
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
        DuesRepository(h.api).month(DateTime(2026, 10)),
        throwsA(isA<ApiException>()),
      );
      expect(h.unauthorizedCalls, 1);
      expect(h.tokens.token, isNull);
    });

    test('ruta no instalada (404 sin JSON): mensaje propio', () async {
      final h = ApiHarness(FakeApiAdapter.json(null, status: 404));
      await expectLater(
        DuesRepository(h.api).month(DateTime(2026, 10)),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            'La ruta solicitada no está instalada en el servidor.',
          ),
        ),
      );
    });

    test('sin conexión: NetworkException en español', () async {
      final h = ApiHarness(FakeApiAdapter.connectionError());
      await expectLater(
        DuesRepository(h.api).month(DateTime(2026, 10)),
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
