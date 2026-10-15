import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderListenable;
import 'package:sistema_cuentas/core/errors/app_exception.dart';
import 'package:sistema_cuentas/core/services/app_toast.dart';

/// Escucha una escritura («estaba cargando → terminó»): si salió bien muestra
/// [successMessage] y llama a [onSuccess]; si falló, el error ya en español.
/// En Riverpod 3 un `AsyncError` conserva el valor anterior, así que el error se
/// mira primero y excluye al éxito. Se llama en `initState`.
void listenSave(
  WidgetRef ref,
  ProviderListenable<AsyncValue<void>> provider, {
  required String successMessage,
  required VoidCallback onSuccess,
}) {
  ref.listenManual(provider, (previous, next) {
    if (previous?.isLoading != true) return;
    if (next.hasError) {
      AppToast.error(userErrorMessage(next.error));
    } else if (!next.isLoading) {
      AppToast.success(successMessage);
      onSuccess();
    }
  });
}
