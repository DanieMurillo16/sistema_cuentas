import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_cuentas/features/auth/utils/splash_tips.dart';

/// Qué mensaje de la pantalla de carga se ve: cambia cada pocos segundos y se
/// detiene solo cuando la pantalla se cierra.
final splashTipIndexProvider = StreamProvider.autoDispose<int>(
  (ref) => Stream.periodic(
    const Duration(seconds: 3),
    (count) => (count + 1) % splashTips.length,
  ),
);
