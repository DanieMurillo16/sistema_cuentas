import 'dart:async';

import 'package:sistema_cuentas/core/models/session.dart';
import 'package:sistema_cuentas/features/auth/data/auth_repository.dart';

/// Repositorio de sesión falso: cada operación se programa con una función
/// (o un `Completer` para controlar cuándo termina) y se cuentan las llamadas.
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({
    this.storedToken = false,
    this.onLogin,
    this.onFetchSession,
    this.onLogout,
  });

  bool storedToken;
  Future<Session> Function(String username, String password)? onLogin;
  Future<Session> Function()? onFetchSession;
  Future<void> Function()? onLogout;

  int loginCalls = 0;
  int fetchSessionCalls = 0;
  int logoutCalls = 0;
  String? lastUsername;
  String? lastPassword;

  @override
  Future<Session> login({required String username, required String password}) {
    loginCalls++;
    lastUsername = username;
    lastPassword = password;
    return onLogin!(username, password);
  }

  @override
  Future<Session> fetchSession() {
    fetchSessionCalls++;
    return onFetchSession!();
  }

  @override
  Future<void> logout() async {
    logoutCalls++;
    await onLogout?.call();
  }

  @override
  Future<bool> hasStoredToken() async => storedToken;
}
