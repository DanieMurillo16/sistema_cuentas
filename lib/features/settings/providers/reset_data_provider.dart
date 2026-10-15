import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_cuentas/features/settings/data/account_repository.dart';

/// Escritura: «Eliminar mis datos» (empezar de cero). El estado es `true` cuando
/// el servidor ya borró todo; la pantalla entonces avisa y cierra la sesión (las
/// listas de la sesión se limpian solas al cambiar de sesión).
final resetDataProvider =
    AsyncNotifierProvider.autoDispose<ResetDataNotifier, bool>(
      ResetDataNotifier.new,
    );

class ResetDataNotifier extends AsyncNotifier<bool> {
  @override
  bool build() => false;

  Future<void> reset() async {
    if (state.isLoading) return; // anti doble envío (no solo el botón)
    // Si el diálogo se desmonta mientras borra, la operación termina igual.
    final keepAlive = ref.keepAlive();
    state = const AsyncLoading();
    try {
      state = await AsyncValue.guard(() async {
        await ref.read(accountRepositoryProvider).resetData();
        return true;
      });
    } finally {
      keepAlive.close();
    }
  }
}
