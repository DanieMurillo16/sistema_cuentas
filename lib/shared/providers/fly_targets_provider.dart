import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Dónde están en pantalla las tarjetas de Ingresos y Gastos de Inicio. Una
/// animación (el monto que «vuela» hasta ellas al registrar algo) las busca por
/// estas llaves; si no están en pantalla, simplemente no hay animación.
class FlyTargets {
  final income = GlobalKey(debugLabel: 'fly-target-income');
  final expense = GlobalKey(debugLabel: 'fly-target-expense');
}

final flyTargetsProvider = Provider<FlyTargets>((ref) => FlyTargets());
