import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_cuentas/core/errors/app_exception.dart';
import 'package:sistema_cuentas/core/models/session.dart';
import 'package:sistema_cuentas/core/services/session_expiration.dart';
import 'package:sistema_cuentas/features/auth/data/auth_repository.dart';

/// La sesión abierta (`null` = sin sesión). Al arrancar recupera el perfil con
/// el token guardado; un 401 (en cualquier petición) la cierra.
final sessionProvider = AsyncNotifierProvider<SessionNotifier, Session?>(
  SessionNotifier.new,
);

/// Id de quien tiene la sesión. Los providers de datos lo observan en `build`
/// para no mezclar datos de una cuenta con los de otra.
final sessionUserIdProvider = Provider<int?>(
  (ref) => ref.watch(sessionProvider.select((s) => s.value?.user.id)),
);

class SessionNotifier extends AsyncNotifier<Session?> {
  @override
  Future<Session?> build() async {
    ref.listen(sessionExpirationProvider, (_, _) {
      state = const AsyncData(null);
    });
    final repository = ref.read(authRepositoryProvider);
    if (!await repository.hasStoredToken()) return null;
    try {
      return await repository.fetchSession();
    } on AppException catch (error) {
      if (error.statusCode == 401) return null;
      rethrow;
    }
  }

  /// Solo se llama con la sesión ya resuelta (el router muestra el login
  /// únicamente cuando `build` terminó con `null`).
  void open(Session session) => state = AsyncData(session);

  Future<void> signOut() async {
    await ref.read(authRepositoryProvider).logout();
    state = const AsyncData(null);
  }
}
