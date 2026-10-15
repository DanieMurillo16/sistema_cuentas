import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_cuentas/core/errors/app_exception.dart';
import 'package:sistema_cuentas/core/network/api_endpoints.dart';
import 'package:sistema_cuentas/features/settings/data/account_repository.dart';

import '../../../helpers/auth_fixtures.dart';
import '../../../support/api_harness.dart';
import '../../../support/fake_api_adapter.dart';

void main() {
  group('resetData', () {
    test(
      'POST cuenta/reiniciar_datos.php con el token y {confirmar: true}',
      () async {
        final h = ApiHarness(
          FakeApiAdapter.json(successEnvelope({'reiniciado': true})),
        );

        await AccountRepository(h.api).resetData();

        expect(ApiEndpoints.accountReset, 'cuenta/reiniciar_datos.php');
        expect(h.single.method, 'POST');
        expect(h.single.path, ApiEndpoints.accountReset);
        expect(h.single.authorization, 'Bearer tok');
        expect(h.single.body, {'confirmar': true});
      },
    );

    final failures = <(String, FakeApiAdapter, Matcher)>[
      (
        'sin permiso (403)',
        FakeApiAdapter.json(
          errorEnvelope('SIN_PERMISO', 'No tienes permiso para esta acción.'),
          status: 403,
        ),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'status', 403)
              .having(
                (e) => e.message,
                'message',
                'No tienes permiso para esta acción.',
              ),
        ),
      ),
      (
        'error de negocio (422)',
        FakeApiAdapter.json(
          errorEnvelope('VALIDACION', 'Falta la confirmación.'),
          status: 422,
        ),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            'Falta la confirmación.',
          ),
        ),
      ),
      (
        'sin conexión',
        FakeApiAdapter.connectionError(),
        throwsA(
          isA<NetworkException>().having(
            (e) => e.message,
            'message',
            contains('conect'),
          ),
        ),
      ),
    ];
    for (final (name, adapter, matcher) in failures) {
      test('propaga como AppException en español: $name', () async {
        final h = ApiHarness(adapter);
        await expectLater(AccountRepository(h.api).resetData(), matcher);
      });
    }
  });
}
