import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_cuentas/core/network/api_client.dart';
import 'package:sistema_cuentas/core/network/api_endpoints.dart';

final accountRepositoryProvider = Provider<AccountRepository>(
  (ref) => AccountRepository(ref.watch(apiClientProvider)),
);

/// Única puerta a las operaciones de la cuenta de quien tiene la sesión.
class AccountRepository {
  const AccountRepository(this._api);

  final ApiClient _api;

  /// Borra de verdad todos los datos de la persona (movimientos, pagos
  /// recurrentes, contactos, categorías y medios) y deja los catálogos iniciales
  /// de un usuario nuevo. Su usuario y su contraseña se conservan. Irreversible.
  Future<void> resetData() async {
    await _api.post(ApiEndpoints.accountReset, data: {'confirmar': true});
  }
}
