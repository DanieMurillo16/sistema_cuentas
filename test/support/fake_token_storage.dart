import 'package:sistema_cuentas/core/services/token_storage.dart';

/// Almacén de token en memoria (nunca toca `SharedPreferences`).
class FakeTokenStorage implements TokenStorage {
  FakeTokenStorage([this.token]);

  String? token;
  int clearCalls = 0;

  @override
  Future<String?> read() async => token;

  @override
  Future<void> save(String token) async => this.token = token;

  @override
  Future<void> clear() async {
    clearCalls++;
    token = null;
  }
}
