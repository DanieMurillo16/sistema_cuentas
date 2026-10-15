import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_cuentas/core/network/api_client.dart';
import 'package:sistema_cuentas/core/network/api_endpoints.dart';
import 'package:sistema_cuentas/core/network/api_response.dart';
import 'package:sistema_cuentas/features/users/models/managed_user.dart';
import 'package:sistema_cuentas/features/users/models/user_draft.dart';

final usersRepositoryProvider = Provider<UsersRepository>(
  (ref) => UsersRepository(ref.watch(apiClientProvider)),
);

/// Única puerta a la gestión de usuarios (solo administrador).
class UsersRepository {
  const UsersRepository(this._api);

  final ApiClient _api;

  Future<List<ManagedUser>> list() async {
    final data = await _api.get(ApiEndpoints.usersList);
    return parseApi(
      () => [
        for (final item in data['usuarios'] as List)
          ManagedUser.fromJson(Map<String, dynamic>.from(item as Map)),
      ],
    );
  }

  Future<ManagedUser> create(UserDraft draft) async {
    final data = await _api.post(ApiEndpoints.userCreate, data: draft.toJson());
    return parseApi(
      () => ManagedUser.fromJson(
        Map<String, dynamic>.from(data['usuario'] as Map),
      ),
    );
  }

  /// Activa o desactiva a alguien (desactivar cierra sus sesiones).
  Future<ManagedUser> setActive(int id, {required bool active}) async {
    final data = await _api.post(
      ApiEndpoints.userSetStatus,
      data: {'id_usuario': id, 'activo': active},
    );
    return parseApi(
      () => ManagedUser.fromJson(
        Map<String, dynamic>.from(data['usuario'] as Map),
      ),
    );
  }
}
