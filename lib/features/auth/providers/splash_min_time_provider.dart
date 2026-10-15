import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Lo mínimo que se ve el splash al abrir la app, aunque la sesión cargue al
/// instante: sin esto parpadea y no da tiempo a leer nada. Las pruebas lo
/// ponen en cero.
final splashMinDurationProvider = Provider<Duration>(
  (ref) => const Duration(seconds: 2),
);

/// Termina cuando ya pasó el tiempo mínimo del splash.
final splashMinTimeProvider = FutureProvider<void>((ref) async {
  final duration = ref.watch(splashMinDurationProvider);
  if (duration == Duration.zero) return;
  await Future<void>.delayed(duration);
});
