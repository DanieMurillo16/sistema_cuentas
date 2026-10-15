import 'package:sistema_cuentas/core/network/api_client.dart';

import 'fake_api_adapter.dart';
import 'fake_token_storage.dart';

/// Un `ApiClient` real (un solo Dio) con adaptador falso: así los repositorios
/// se prueban de punta a punta sin red.
class ApiHarness {
  ApiHarness(this.adapter, {String? token = 'tok'})
    : tokens = FakeTokenStorage(token) {
    api = ApiClient(
      baseUrl: 'https://servidor.test/api/',
      tokenStorage: tokens,
      adapter: adapter,
      onUnauthorized: () async {
        unauthorizedCalls++;
        await tokens.clear();
      },
    );
  }

  final FakeApiAdapter adapter;
  final FakeTokenStorage tokens;
  late final ApiClient api;
  int unauthorizedCalls = 0;

  RecordedRequest get single => adapter.requests.single;
}
