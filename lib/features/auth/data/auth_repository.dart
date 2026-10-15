import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_cuentas/core/errors/app_exception.dart';
import 'package:sistema_cuentas/core/models/session.dart';
import 'package:sistema_cuentas/core/network/api_client.dart';
import 'package:sistema_cuentas/core/network/api_endpoints.dart';
import 'package:sistema_cuentas/core/services/token_storage.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    ref.watch(apiClientProvider),
    ref.watch(tokenStorageProvider),
  );
});

/// Única puerta a los datos de sesión: login, perfil y cierre.
class AuthRepository {
  const AuthRepository(this._api, this._tokens);

  final ApiClient _api;
  final TokenStorage _tokens;

  Future<Session> login({
    required String username,
    required String password,
  }) async {
    final data = await _api.post(
      ApiEndpoints.login,
      data: {'usuario': username, 'clave': password},
    );
    final token = data['token'];
    if (token is! String || token.isEmpty) {
      throw const UnexpectedException('El servidor no entregó la sesión.');
    }
    // Primero se comprueba que la respuesta sirva; solo entonces se guarda el
    // token (no puede quedar un token guardado sin sesión abierta).
    final session = _parseSession(data);
    await _tokens.save(token);
    return session;
  }

  /// Perfil y permisos de la sesión guardada; 401 si el token ya no sirve.
  Future<Session> fetchSession() async =>
      _parseSession(await _api.get(ApiEndpoints.profile));

  /// Cierra la sesión en el servidor (si se puede) y siempre en el equipo.
  Future<void> logout() async {
    try {
      await _api.post(ApiEndpoints.logout);
    } on AppException {
      // Sin conexión o token vencido: la sesión local se cierra igual.
    } finally {
      await _tokens.clear();
    }
  }

  Session _parseSession(Map<String, dynamic> data) {
    try {
      return Session.fromJson(data);
    } on TypeError {
      throw const UnexpectedException(
        'El servidor devolvió el perfil incompleto.',
      );
    }
  }

  Future<bool> hasStoredToken() async {
    final token = await _tokens.read();
    return token != null && token.isNotEmpty;
  }
}
