import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_cuentas/core/errors/app_exception.dart';
import 'package:sistema_cuentas/features/auth/widgets/splash_content.dart';
import 'package:sistema_cuentas/shared/providers/session_provider.dart';
import 'package:sistema_cuentas/shared/widgets/app_error_view.dart';

/// Pantalla de arranque: la marca, «Cargando…» y unos mensajes con iconos
/// mientras se recupera la sesión guardada. Es la misma imagen que muestra el
/// sistema al abrir (fondo oscuro, logo y nombre), así no hay un salto. Si
/// falla por red se queda aquí con "Intentar nuevamente" (la sesión no se
/// pierde).
class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    // Mientras reintenta, el error anterior sigue en el estado: se ve la carga.
    final failed = session.hasError && !session.isLoading;
    return Scaffold(
      body: failed
          ? AppErrorView(
              message: userErrorMessage(session.error),
              onRetry: () => ref.invalidate(sessionProvider),
            )
          : const SplashContent(),
    );
  }
}
