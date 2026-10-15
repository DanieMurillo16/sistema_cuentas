import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override, ProviderListenable;
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_cuentas/shared/providers/session_provider.dart';

/// `ProviderContainer` de prueba: sin reintentos (un error se queda como error)
/// y con una sesión fija (id 7) para que los providers de datos puedan build.
ProviderContainer makeContainer({List<Override> overrides = const []}) {
  final container = ProviderContainer(
    retry: (_, _) => null,
    overrides: [sessionUserIdProvider.overrideWithValue(7), ...overrides],
  );
  addTearDown(container.dispose);
  return container;
}

/// Mantiene vivos (y reconstruyéndose solos) los providers indicados, como
/// haría una pantalla que los observa.
void keepAlive(
  ProviderContainer container,
  List<ProviderListenable<Object?>> providers,
) {
  for (final provider in providers) {
    container.listen(provider, (_, _) {}, fireImmediately: false);
  }
}
