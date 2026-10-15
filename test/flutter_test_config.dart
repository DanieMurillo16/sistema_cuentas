import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_cuentas/core/theme/app_colors.dart';
import 'package:sistema_cuentas/shared/widgets/app_pulse.dart';

/// `AppColors` guarda la paleta activa en un estado estático: una prueba que
/// activa el tema claro (o arma `AppTheme.light`) la dejaría puesta para las
/// siguientes del mismo archivo. Antes y después de CADA prueba se vuelve al
/// tema oscuro, que es el de partida.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  // Un latido sin fin impediría que `pumpAndSettle` termine.
  AppPulse.debugLoopForever = false;
  setUp(() => AppColors.apply(Brightness.dark));
  tearDown(() => AppColors.apply(Brightness.dark));
  await testMain();
}
