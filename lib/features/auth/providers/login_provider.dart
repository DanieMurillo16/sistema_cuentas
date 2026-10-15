import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_cuentas/features/auth/data/auth_repository.dart';
import 'package:sistema_cuentas/shared/providers/session_provider.dart';

/// Escritura del login: expone cargando / error y, al terminar bien, abre la
/// sesión (el router lleva a Inicio solo).
final loginProvider = AsyncNotifierProvider.autoDispose<LoginNotifier, void>(
  LoginNotifier.new,
);

class LoginNotifier extends AsyncNotifier<void> {
  @override
  void build() {}

  Future<void> signIn({
    required String username,
    required String password,
  }) async {
    if (state.isLoading) return;
    // El login se lleva su pantalla al abrir la sesión: no soltar el ref antes.
    final keepAlive = ref.keepAlive();
    state = const AsyncLoading();
    try {
      state = await AsyncValue.guard(() async {
        final session = await ref
            .read(authRepositoryProvider)
            .login(username: username.trim(), password: password);
        ref.read(sessionProvider.notifier).open(session);
      });
    } finally {
      keepAlive.close();
    }
  }
}
